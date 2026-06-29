--[[
====================================================================
 PTS_Manager.lua
 Modulo de gestion de puntos: decide CUANDO y CUANTO otorgar o
 penalizar, segun los eventos reales del juego. No almacena estado
 propio -- toda la data persiste en DATA_Core (pilotos, coaliciones,
 ledger de puntos).

 Dependencias:
   - Moose.lua          (cargado antes)
   - EVT_Dispatcher.lua (cargado antes, este modulo se suscribe a el)
   - DATA_Core.lua      (cargado antes, aqui se escriben los puntos)

 Version: v1
 Convencion de nombres del proyecto:
   - Prefijo de modulo: PTS_
   - PascalCase para objetos/namespace, camelCase variables locales,
     UPPER_SNAKE_CASE constantes/flags
====================================================================
]]

PTS_Manager = {}

--------------------------------------------------------------------
-- CONFIGURACION DE PUNTOS (editable libremente, sin afectar la logica)
--------------------------------------------------------------------

-- Valores iniciales (placeholder) -- Mario puede ajustar cualquiera
-- de estos numeros en cualquier momento sin tocar el resto del script.
PTS_Manager.POINTS = {
  TARGET_DESTROYED =  15,  -- destruir un target oficial de mision (DATA_Core.RegisterTarget)
  ENEMY_KILL       =  10,  -- matar unidad enemiga no designada como target
  BLUE_ON_BLUE     = -20,  -- fuego amigo (penaliza a quien dispara)
  COLLATERAL       =   0,  -- dano colateral sin atribucion clara -- neutro por defecto
  OWN_LOSS         = -10,  -- penalizacion a la coalicion/piloto que pierde la unidad
}

--------------------------------------------------------------------
-- ESTRUCTURAS INTERNAS (privadas al modulo)
--------------------------------------------------------------------

-- Registro temporal de impactos por unidad objetivo, indexado por el
-- nombre de la unidad (IniUnitName de la victima). Se limpia cuando
-- la unidad muere. Estructura: _hitsLog[targetUnitName] = { {hit1}, {hit2}, ... }
local _hitsLog = {}

--------------------------------------------------------------------
-- UTILIDADES INTERNAS
--------------------------------------------------------------------

-- Mismo criterio de identificacion de piloto usado en DATA_Core:
-- preferir IniPlayerName (jugador humano), si no existe usar
-- IniUnitName (IA u otro caso). Duplicado intencionalmente aqui (bajo
-- acoplamiento entre modulos) en vez de exponerlo desde DATA_Core.
local function _pilotIdFrom(EventData)
  if not EventData then return nil end
  return EventData.IniPlayerName or EventData.IniUnitName
end

-- Convierte la constante numerica EventData.IniCoalition / TgtCoalition
-- de DCS a los strings "blue"/"red" usados en todo el proyecto.
local function _coalitionSideOf(coalitionConstant)
  if coalitionConstant == coalition.side.BLUE then
    return "blue"
  elseif coalitionConstant == coalition.side.RED then
    return "red"
  end
  return nil
end

-- Intenta obtener la posicion MGRS de una unidad en el momento del
-- impacto (mientras sigue viva). Envuelto en pcall porque TgtUnit
-- puede no existir para todo tipo de evento/objeto (ej. scenery).
local function _mgrsOf(MooseUnit)
  if not MooseUnit then return nil end
  local ok, mgrs = pcall(function()
    return MooseUnit:GetCoordinate():ToStringMGRS()
  end)
  if ok then return mgrs end
  return nil
end

-- Elimina pilotIds duplicados de un array de hits, devolviendo un
-- array de pilotIds unicos (para repartir puntos sin contar dos veces
-- al mismo piloto que impacto varias veces al mismo objetivo).
local function _uniquePilotIds(hits)
  local seen = {}
  local result = {}
  for _, hit in ipairs(hits) do
    if hit.pilotId and not seen[hit.pilotId] then
      seen[hit.pilotId] = true
      table.insert(result, hit.pilotId)
    end
  end
  return result
end

-- Hora del MUNDO de la mision (no la hora real de Windows -- esa
-- depende de "os", sandboxeado por DCS). timer.getAbsTime() es nativo
-- de DCS y da segundos desde medianoche del dia configurado en el
-- Mission Editor. La convertimos a "HH:MM:SS" con aritmetica simple,
-- sin ninguna libreria adicional.
local function _missionClockHHMMSS()
  local ok, absSeconds = pcall(timer.getAbsTime)
  if not ok or not absSeconds then return nil end

  local totalSeconds = math.floor(absSeconds) % 86400  -- por si pasa de medianoche
  local hours   = math.floor(totalSeconds / 3600)
  local minutes = math.floor((totalSeconds % 3600) / 60)
  local seconds = totalSeconds % 60

  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Determina si una unidad es "air" (avion/helicoptero) o "ground"
-- (vehiculo, infanteria, barco, estructura -- todo lo no-aereo se
-- agrupa como "ground" para simplificar el filtro en Excel).
local function _domainOf(MooseUnit)
  if not MooseUnit then return nil end
  local ok, category = pcall(function() return MooseUnit:GetCategory() end)
  if not ok or category == nil then return nil end

  if category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER then
    return "air"
  end
  return "ground"
end

-- Tipo de unidad (avion o vehiculo), capturado de forma segura.
local function _typeNameOf(MooseUnit)
  if not MooseUnit then return nil end
  local ok, typeName = pcall(function() return MooseUnit:GetTypeName() end)
  if ok then return typeName end
  return nil
end

--------------------------------------------------------------------
-- HANDLERS DE EVENTOS
--------------------------------------------------------------------

-- Registra cada impacto (Hit) en el log temporal de la unidad objetivo,
-- para poder reconstruir despues quien contribuyo a su destruccion.
local function _onHit(EventData)
  if not EventData or not EventData.TgtUnitName then return end

  local shooterCoalition = _coalitionSideOf(EventData.IniCoalition)
  local targetUnitName   = EventData.TgtUnitName

  -- Nombre "legible" del objetivo: callsign si es jugador humano,
  -- nombre crudo de DCS si es IA (igual criterio que _pilotIdFrom).
  local targetDisplayName = EventData.TgtPlayerName or EventData.TgtUnitName

  _hitsLog[targetUnitName] = _hitsLog[targetUnitName] or {}
  table.insert(_hitsLog[targetUnitName], {
    pilotId      = _pilotIdFrom(EventData),
    coalition    = shooterCoalition,
    weapon       = EventData.WeaponName,
    mgrs         = _mgrsOf(EventData.TgtUnit),
    targetName   = targetDisplayName,
    targetType   = _typeNameOf(EventData.TgtUnit),
    domain       = _domainOf(EventData.TgtUnit),
    clockTime    = _missionClockHHMMSS(),
    timestamp    = timer.getTime(),
  })
end

-- Logica central: al morir una unidad, clasifica el evento en una de
-- las 4 categorias acordadas y reparte/penaliza puntos en consecuencia.
local function _onDeadOrCrash(EventData)
  if not EventData or not EventData.IniUnitName then return end

  local victimUnitName  = EventData.IniUnitName
  local victimCoalition = _coalitionSideOf(EventData.IniCoalition)
  local victimPilotId   = _pilotIdFrom(EventData)
  local hits             = _hitsLog[victimUnitName] or {}
  local targetRecord     = DATA_Core.GetTarget(victimUnitName)

  local category
  local contributors = {}      -- array de pilotIds que reciben el premio/penalizacion
  local shooterCoalition = nil -- coalicion de quienes dispararon (para puntos de coalicion)

  if targetRecord then
    -- Cualquier unidad registrada oficialmente como target de mision
    -- manda sobre las demas categorias.
    category = "TargetDestroyed"
    contributors = _uniquePilotIds(hits)
    if hits[1] then shooterCoalition = hits[1].coalition end

  elseif #hits > 0 then
    local enemyHits, friendlyHits = {}, {}
    for _, hit in ipairs(hits) do
      if hit.coalition == victimCoalition then
        table.insert(friendlyHits, hit)
      else
        table.insert(enemyHits, hit)
      end
    end

    if #enemyHits > 0 then
      category = "EnemyKill"
      contributors = _uniquePilotIds(enemyHits)
      shooterCoalition = enemyHits[1].coalition
    else
      category = "BlueOnBlue"
      contributors = _uniquePilotIds(friendlyHits)
      shooterCoalition = friendlyHits[1].coalition
    end

  else
    -- Sin impactos registrados (ej. murio por IA sin pasar por el
    -- evento Hit, o es un objeto/escenario no rastreado): no hay
    -- atribucion confiable, se registra neutro.
    category = "Collateral"
  end

  -- Datos comunes para el ledger (del ultimo hit disponible -- es el
  -- mas representativo del impacto que efectivamente abatio al objetivo).
  local lastHit       = hits[#hits]
  local weaponUsed     = lastHit and lastHit.weapon or nil
  local mgrsUsed        = lastHit and lastHit.mgrs or nil
  local targetNameUsed  = lastHit and lastHit.targetName or victimUnitName
  local targetTypeUsed  = lastHit and lastHit.targetType or nil
  local domainUsed      = lastHit and lastHit.domain or nil
  local clockTimeUsed   = lastHit and lastHit.clockTime or _missionClockHHMMSS()

  -- Obtiene el tipo de aeronave que vuela un piloto contribuyente,
  -- previamente capturado por DATA_Core en el evento PlayerEnterUnit.
  local function _pilotAircraftType(pilotId)
    local pilot = pilotId and DATA_Core.GetPilot(pilotId)
    return pilot and pilot.aircraftType or nil
  end

  if category == "TargetDestroyed" or category == "EnemyKill" then
    local basePoints  = (category == "TargetDestroyed")
                          and PTS_Manager.POINTS.TARGET_DESTROYED
                          or  PTS_Manager.POINTS.ENEMY_KILL
    local numContrib  = math.max(1, #contributors)
    local pointsEach  = basePoints / numContrib

    for _, pilotId in ipairs(contributors) do
      DATA_Core.AddPilotPoints(pilotId, pointsEach)
      DATA_Core.AddPointsLedgerEntry({
        clockTime     = clockTimeUsed,
        pilotId       = pilotId,
        pilotAircraft = _pilotAircraftType(pilotId),
        coalition     = shooterCoalition,
        category      = category,
        domain        = domainUsed,
        amount        = pointsEach,
        weapon        = weaponUsed,
        targetName    = targetNameUsed,
        targetType    = targetTypeUsed,
        mgrs          = mgrsUsed,
        reason        = (category == "TargetDestroyed")
                          and "Target oficial de mision destruido"
                          or  "Unidad enemiga destruida",
      })
    end

    if shooterCoalition then
      DATA_Core.AddCoalitionPoints(shooterCoalition, basePoints)
    end

    -- Penalizacion simetrica al bando que perdio la unidad (si tenia
    -- coalicion identificable). Se registra como evento separado.
    if victimCoalition then
      DATA_Core.AddCoalitionPoints(victimCoalition, PTS_Manager.POINTS.OWN_LOSS)
      if victimPilotId and DATA_Core.GetPilot(victimPilotId) then
        DATA_Core.AddPilotPoints(victimPilotId, PTS_Manager.POINTS.OWN_LOSS)
      end
      DATA_Core.AddPointsLedgerEntry({
        clockTime     = clockTimeUsed,
        pilotId       = victimPilotId,
        pilotAircraft = _pilotAircraftType(victimPilotId),
        coalition     = victimCoalition,
        category      = "OwnLoss",
        domain        = domainUsed,
        amount        = PTS_Manager.POINTS.OWN_LOSS,
        weapon        = weaponUsed,
        targetName    = targetNameUsed,
        targetType    = targetTypeUsed,
        mgrs          = mgrsUsed,
        reason        = "Perdida de unidad propia",
      })
    end

  elseif category == "BlueOnBlue" then
    local numContrib = math.max(1, #contributors)
    local pointsEach = PTS_Manager.POINTS.BLUE_ON_BLUE / numContrib

    for _, pilotId in ipairs(contributors) do
      DATA_Core.AddPilotPoints(pilotId, pointsEach)
      DATA_Core.AddPointsLedgerEntry({
        clockTime     = clockTimeUsed,
        pilotId       = pilotId,
        pilotAircraft = _pilotAircraftType(pilotId),
        coalition     = shooterCoalition,
        category      = "BlueOnBlue",
        domain        = domainUsed,
        amount        = pointsEach,
        weapon        = weaponUsed,
        targetName    = targetNameUsed,
        targetType    = targetTypeUsed,
        mgrs          = mgrsUsed,
        reason        = "Fuego amigo",
      })
    end

  else -- "Collateral"
    DATA_Core.AddPointsLedgerEntry({
      clockTime     = clockTimeUsed,
      pilotId       = nil,
      pilotAircraft = nil,
      coalition     = victimCoalition,
      category      = "Collateral",
      domain        = domainUsed,
      amount        = PTS_Manager.POINTS.COLLATERAL,
      weapon        = nil,
      targetName    = targetNameUsed,
      targetType    = targetTypeUsed,
      mgrs          = nil,
      reason        = "Sin atribucion clara de impacto",
    })
  end

  -- Limpieza: ya no se necesita el log de impactos de esta unidad.
  _hitsLog[victimUnitName] = nil
end

--------------------------------------------------------------------
-- SUSCRIPCION A EVT_Dispatcher
--------------------------------------------------------------------

if EVT_Dispatcher and EVT_Dispatcher.Subscribe and DATA_Core then
  EVT_Dispatcher:Subscribe(EVENTS.Hit,   _onHit,          "PTS_Manager")
  EVT_Dispatcher:Subscribe(EVENTS.Dead,  _onDeadOrCrash,  "PTS_Manager")
  EVT_Dispatcher:Subscribe(EVENTS.Crash, _onDeadOrCrash,  "PTS_Manager")

  env.info("PTS_Manager :: INICIADO correctamente, suscrito a EVT_Dispatcher.")
else
  env.error("PTS_Manager :: EVT_Dispatcher o DATA_Core no encontrados. Verificar orden de carga (Moose.lua -> EVT_Dispatcher.lua -> DATA_Core.lua -> PTS_Manager.lua).")
end
