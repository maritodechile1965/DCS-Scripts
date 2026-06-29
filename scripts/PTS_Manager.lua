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

--------------------------------------------------------------------
-- HANDLERS DE EVENTOS
--------------------------------------------------------------------

-- Registra cada impacto (Hit) en el log temporal de la unidad objetivo,
-- para poder reconstruir despues quien contribuyo a su destruccion.
local function _onHit(EventData)
  if not EventData or not EventData.TgtUnitName then return end

  local shooterCoalition = _coalitionSideOf(EventData.IniCoalition)
  local targetUnitName   = EventData.TgtUnitName

  _hitsLog[targetUnitName] = _hitsLog[targetUnitName] or {}
  table.insert(_hitsLog[targetUnitName], {
    pilotId    = _pilotIdFrom(EventData),
    coalition  = shooterCoalition,
    weapon     = EventData.WeaponName,
    mgrs       = _mgrsOf(EventData.TgtUnit),
    timestamp  = timer.getTime(),
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

  -- Datos comunes para el ledger (weapon/mgrs del primer hit disponible,
  -- si existe -- representativo, no necesariamente el impacto final).
  local lastHit = hits[#hits]
  local weaponUsed = lastHit and lastHit.weapon or nil
  local mgrsUsed    = lastHit and lastHit.mgrs or nil

  if category == "TargetDestroyed" or category == "EnemyKill" then
    local basePoints  = (category == "TargetDestroyed")
                          and PTS_Manager.POINTS.TARGET_DESTROYED
                          or  PTS_Manager.POINTS.ENEMY_KILL
    local numContrib  = math.max(1, #contributors)
    local pointsEach  = basePoints / numContrib

    for _, pilotId in ipairs(contributors) do
      DATA_Core.AddPilotPoints(pilotId, pointsEach)
      DATA_Core.AddPointsLedgerEntry({
        pilotId    = pilotId,
        coalition  = shooterCoalition,
        category   = category,
        amount     = pointsEach,
        weapon     = weaponUsed,
        targetName = victimUnitName,
        mgrs       = mgrsUsed,
        reason     = (category == "TargetDestroyed")
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
        pilotId    = victimPilotId,
        coalition  = victimCoalition,
        category   = "OwnLoss",
        amount     = PTS_Manager.POINTS.OWN_LOSS,
        weapon     = weaponUsed,
        targetName = victimUnitName,
        mgrs       = mgrsUsed,
        reason     = "Perdida de unidad propia",
      })
    end

  elseif category == "BlueOnBlue" then
    local numContrib = math.max(1, #contributors)
    local pointsEach = PTS_Manager.POINTS.BLUE_ON_BLUE / numContrib

    for _, pilotId in ipairs(contributors) do
      DATA_Core.AddPilotPoints(pilotId, pointsEach)
      DATA_Core.AddPointsLedgerEntry({
        pilotId    = pilotId,
        coalition  = shooterCoalition,
        category   = "BlueOnBlue",
        amount     = pointsEach,
        weapon     = weaponUsed,
        targetName = victimUnitName,
        mgrs       = mgrsUsed,
        reason     = "Fuego amigo",
      })
    end

  else -- "Collateral"
    DATA_Core.AddPointsLedgerEntry({
      pilotId    = nil,
      coalition  = victimCoalition,
      category   = "Collateral",
      amount     = PTS_Manager.POINTS.COLLATERAL,
      weapon     = nil,
      targetName = victimUnitName,
      mgrs       = nil,
      reason     = "Sin atribucion clara de impacto",
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
