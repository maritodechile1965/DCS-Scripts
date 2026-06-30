--[[
====================================================================
 PTS_Manager.lua  v3
 Modulo de gestion de puntos + tracking de armas + mensajes en
 pantalla. Decide CUANDO y CUANTO otorgar o penalizar, segun los
 eventos reales del juego. No almacena estado propio -- toda la
 data persiste en DATA_Core.

 Dependencias:
   - Moose.lua          (cargado antes)
   - EVT_Dispatcher.lua (cargado antes)
   - DATA_Core.lua      (cargado antes)

 Version: v3 (tracking armas + mensajes pantalla + MGRS DCS nativo)
 Convencion de nombres: PTS_, PascalCase, camelCase, UPPER_SNAKE
====================================================================
]]

PTS_Manager = {}

--------------------------------------------------------------------
-- CONFIGURACION DE PUNTOS (editable libremente)
--------------------------------------------------------------------
PTS_Manager.POINTS = {
  TARGET_DESTROYED =  15,
  ENEMY_KILL       =  10,
  BLUE_ON_BLUE     = -20,
  COLLATERAL       =   0,
  OWN_LOSS         = -10,
  MISS             =   0,  -- impacto en terreno sin objetivo
}

--------------------------------------------------------------------
-- ESTRUCTURAS INTERNAS
--------------------------------------------------------------------
local _hitsLog    = {}   -- [targetUnitName] = { {hit1}, {hit2}, ... }
local _weaponTrack = {}  -- [weaponKey] = { pilotId, weaponName, ... }

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------

local function _pilotIdFrom(EventData)
  if not EventData then return nil end
  return EventData.IniPlayerName or EventData.IniUnitName
end

local function _coalitionSideOf(c)
  if c == coalition.side.BLUE then return "blue"
  elseif c == coalition.side.RED then return "red" end
  return nil
end

local function _missionClockHHMMSS()
  local ok, t = pcall(timer.getAbsTime)
  if not ok or not t then return nil end
  local s = math.floor(t) % 86400
  return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), s%60)
end

local function _feet(meters)
  return math.floor((meters or 0) * 3.28084)
end

-- Convierte un Vec3 DCS a string MGRS
local function _vec3ToMGRS(vec3)
  if not vec3 then return nil end
  local ok, mgrs = pcall(function()
    return COORDINATE:NewFromVec3(vec3):ToStringMGRS()
  end)
  if ok and mgrs then return mgrs end
  return nil
end

-- Obtiene el objeto DCS nativo del arma desde EventData.
-- Prueba EventData.weapon (lowercase, raw DCS en world.addEventHandler)
-- y EventData.Weapon:GetDCSObject() (MOOSE wrapper).
-- Basado en el patron probado de BombImpact.lua de Mario.
local function _getDCSWeapon(EventData)
  if EventData.weapon then
    local ok, pt = pcall(function() return EventData.weapon:getPoint() end)
    if ok and pt then return EventData.weapon end
  end
  if EventData.Weapon then
    local ok, obj = pcall(function() return EventData.Weapon:GetDCSObject() end)
    if ok and obj then return obj end
    -- Algunos builds de MOOSE tienen Weapon como DCS nativo directo
    local ok2, pt2 = pcall(function() return EventData.Weapon:getPoint() end)
    if ok2 and pt2 then return EventData.Weapon end
  end
  return nil
end

-- MGRS del punto de impacto usando el objeto DCS del arma (mas preciso)
-- con fallbacks a la unidad objetivo.
local function _mgrsFromEvent(EventData)
  -- 1: arma DCS nativa (patron BombImpact.lua -- el mas confiable)
  local dcsWeapon = _getDCSWeapon(EventData)
  if dcsWeapon then
    local ok, vec3 = pcall(function() return dcsWeapon:getPoint() end)
    if ok and vec3 then return _vec3ToMGRS(vec3) end
  end
  -- 2: unidad objetivo DCS nativa
  if EventData.TgtUnit then
    local ok, obj = pcall(function() return EventData.TgtUnit:GetDCSObject() end)
    if ok and obj then
      local ok2, vec3 = pcall(function() return obj:getPoint() end)
      if ok2 and vec3 then return _vec3ToMGRS(vec3) end
    end
    -- 3: wrapper MOOSE
    local ok3, mgrs = pcall(function()
      return EventData.TgtUnit:GetCoordinate():ToStringMGRS()
    end)
    if ok3 and mgrs then return mgrs end
  end
  return nil
end

-- Clasifica un objeto DCS en una etiqueta legible para el ledger y pantalla.
-- Retorna: etiqueta (AIRCRAFT/VEHICLE/SHIP/STRUCTURE/BUILDING/OBJECT), typeName
local function _classifyDCSTarget(dcsTarget)
  if not dcsTarget then return "UNKNOWN", nil end

  local typeName = nil
  local ok, tn = pcall(function() return dcsTarget:getTypeName() end)
  if ok then typeName = tn end

  local ok2, objCat = pcall(function() return Object.getCategory(dcsTarget) end)
  if not ok2 then return "OBJECT", typeName end

  if objCat == Object.Category.UNIT then
    local ok3, desc = pcall(function() return dcsTarget:getDesc() end)
    if ok3 and desc and desc.category ~= nil then
      local c = desc.category
      if c == Unit.Category.AIRPLANE or c == Unit.Category.HELICOPTER then
        return "AIRCRAFT", typeName
      elseif c == Unit.Category.GROUND_UNIT then
        return "VEHICLE", typeName
      elseif c == Unit.Category.SHIP then
        return "SHIP", typeName
      elseif c == Unit.Category.STRUCTURE then
        return "STRUCTURE", typeName
      end
    end
    return "UNIT", typeName
  elseif objCat == Object.Category.STATIC then
    return "BUILDING", typeName
  elseif objCat == Object.Category.SCENERY then
    return "BUILDING", typeName
  end

  return "OBJECT", typeName
end

-- Dominio "air"/"ground" con multiples fallbacks (igual que v2).
local function _domainOf(MooseUnit)
  if not MooseUnit then return nil end
  local ok, cat = pcall(function() return MooseUnit:GetCategory() end)
  if ok and cat ~= nil then
    if cat == Unit.Category.AIRPLANE or cat == Unit.Category.HELICOPTER then
      return "air"
    end
    return "ground"
  end
  local ok2, obj = pcall(function() return MooseUnit:GetDCSObject() end)
  if ok2 and obj then
    local ok3, desc = pcall(function() return obj:getDesc() end)
    if ok3 and desc and desc.category ~= nil then
      if desc.category == Unit.Category.AIRPLANE or
         desc.category == Unit.Category.HELICOPTER then
        return "air"
      end
      return "ground"
    end
    return "ground"
  end
  return nil
end

local function _typeNameOf(MooseUnit)
  if not MooseUnit then return nil end
  local ok, tn = pcall(function() return MooseUnit:GetTypeName() end)
  if ok and tn then return tn end
  local ok2, obj = pcall(function() return MooseUnit:GetDCSObject() end)
  if ok2 and obj then
    local ok3, desc = pcall(function() return obj:getDesc() end)
    if ok3 and desc and desc.typeName then return desc.typeName end
  end
  return nil
end

local function _uniquePilotIds(hits)
  local seen, result = {}, {}
  for _, hit in ipairs(hits) do
    if hit.pilotId and not seen[hit.pilotId] then
      seen[hit.pilotId] = true
      table.insert(result, hit.pilotId)
    end
  end
  return result
end

local function _pilotAircraftType(pilotId)
  local pilot = pilotId and DATA_Core.GetPilot(pilotId)
  return pilot and pilot.aircraftType or nil
end

--------------------------------------------------------------------
-- HANDLERS DE EVENTOS
--------------------------------------------------------------------

-- SHOT: filtra canones, inicia tracking del arma, muestra mensaje.
local function _onShot(EventData)
  -- Usar EventData.Weapon directamente para WEAPON:New()
  -- (patron exacto de BombImpact.lua de Mario -- NO usar GetDCSObject())
  local mooseWeaponObj = EventData.Weapon
  if not mooseWeaponObj then return end

  -- Para filtrar canones, intentar obtener el descriptor via DCS nativo
  local dcsWeapon = _getDCSWeapon(EventData)
  if dcsWeapon then
    local ok, desc = pcall(function() return dcsWeapon:getDesc() end)
    if ok and desc and desc.category == Weapon.Category.SHELL then
      return  -- ignorar proyectiles de canon
    end
  end

  local pilotId        = _pilotIdFrom(EventData)
  local pilotCoalition = _coalitionSideOf(EventData.IniCoalition)
  local pilotAircraft  = _pilotAircraftType(pilotId)

  -- Nombre del arma
  local weaponName = EventData.WeaponName or "Unknown"
  if dcsWeapon then
    local ok, desc = pcall(function() return dcsWeapon:getDesc() end)
    if ok and desc then
      weaponName = desc.displayName or desc.typeName or weaponName
    end
  end

  -- MGRS de lanzamiento (posicion del avion al disparar)
  local launchMGRS = nil
  if EventData.IniUnit then
    local ok, mgrs = pcall(function()
      return EventData.IniUnit:GetCoordinate():ToStringMGRS()
    end)
    if ok and mgrs then launchMGRS = mgrs end
  end

  -- Mensaje en pantalla al disparar
  trigger.action.outText(string.format(
    "[SHOT] %s | %s | %s | MGRS: %s",
    tostring(pilotId or "IA"),
    tostring(pilotAircraft or "?"),
    tostring(weaponName),
    tostring(launchMGRS or "N/A")
  ), 10)

  -- Crear WEAPON wrapper pasando EventData.Weapon directamente
  -- (igual que BombImpact.lua: WEAPON:New(EventData.Weapon))
  local ok, weaponWrapper = pcall(function() return WEAPON:New(mooseWeaponObj) end)
  if not ok or not weaponWrapper then
    env.info("PTS_Manager :: WEAPON:New() fallo para " .. weaponName)
    return
  end

  local key = tostring(mooseWeaponObj)  -- clave unica para este disparo
  _weaponTrack[key] = {
    pilotId       = pilotId,
    pilotAircraft = pilotAircraft,
    coalition     = pilotCoalition,
    weaponName    = weaponName,
    launchMGRS    = launchMGRS,
    hitRegistered = false,
  }

  -- Closure que captura 'key' para el callback de impacto.
  -- NOTA TECNICA: cuando MOOSE dispara este callback, el objeto DCS
  -- del arma ya fue destruido por DCS ("Object doesn't exist"), por lo
  -- que GetPointVec3()/GetCoordinate() siempre fallan aqui. El MGRS
  -- de los MISS queda nil -- decision consciente: los tiros perdidos
  -- en terreno no necesitan posicion exacta de impacto.
  -- El MGRS si se captura correctamente para hits reales via _onHit.
  local function _impactCallback(ww)
    -- Verificar MISS 0.3s despues del impacto.
    -- Si hitRegistered sigue false, el arma pego en terreno sin objetivo.
    SCHEDULER:New(nil, function()
      local i = _weaponTrack[key]
      if not i then return end

      if not i.hitRegistered then
        local msg = string.format(
          "[MISS] %s | %s | %s",
          tostring(i.pilotId or "IA"),
          tostring(i.pilotAircraft or "?"),
          tostring(i.weaponName)
        )
        trigger.action.outText(msg, 15)
        env.info("PTS_Manager :: " .. msg)

        DATA_Core.AddPointsLedgerEntry({
          clockTime     = _missionClockHHMMSS(),
          pilotId       = i.pilotId,
          pilotAircraft = i.pilotAircraft,
          coalition     = i.coalition,
          category      = "Miss",
          domain        = "ground",
          amount        = PTS_Manager.POINTS.MISS,
          weapon        = i.weaponName,
          targetName    = "TERRAIN",
          targetType    = "MISS",
          mgrs          = nil,
          reason        = "Impacto en terreno sin objetivo",
        })
      end

      _weaponTrack[key] = nil
    end, {}, 0.3, nil)
  end

  pcall(function()
    weaponWrapper:SetFuncImpact(_impactCallback)
    weaponWrapper:StartTrack()
  end)
end

-- HIT: registra impacto con datos enriquecidos via DCS nativo.
local function _onHit(EventData)
  if not EventData or not EventData.TgtUnitName then return end

  local targetUnitName    = EventData.TgtUnitName
  local shooterCoalition  = _coalitionSideOf(EventData.IniCoalition)
  local targetDisplayName = EventData.TgtPlayerName or EventData.TgtUnitName

  -- Clasificar el objetivo usando DCS nativo (mas confiable que MOOSE wrapper)
  local targetLabel = nil  -- VEHICLE, AIRCRAFT, BUILDING, etc.
  local targetType  = nil  -- tipo real de DCS ("T-72B", etc.)

  -- Intentar via objeto DCS nativo del target
  if EventData.TgtUnit then
    local ok, obj = pcall(function() return EventData.TgtUnit:GetDCSObject() end)
    if ok and obj then
      targetLabel, targetType = _classifyDCSTarget(obj)
    end
  end
  -- Fallback a MOOSE wrapper
  if not targetType then
    targetType = _typeNameOf(EventData.TgtUnit)
  end
  -- Si es un object_id numerico (scenery), etiquetar como BUILDING
  if not targetLabel and tonumber(targetUnitName) then
    targetLabel = "BUILDING"
  end

  -- Determinar dominio con fallbacks
  local domain = _domainOf(EventData.TgtUnit)
  if domain == nil then
    local targetRecord = DATA_Core.GetTarget(targetUnitName)
    if targetRecord then domain = targetRecord.type
    elseif tonumber(targetUnitName) then domain = "ground"
    else domain = "ground" end
  end

  -- MGRS del punto de impacto (DCS nativo primero, por BombImpact.lua)
  local mgrsImpact = _mgrsFromEvent(EventData)

  -- Altitud del impacto en pies (desde objeto DCS del arma)
  local altImpactFt = nil
  local dcsWeapon = _getDCSWeapon(EventData)
  if dcsWeapon then
    local ok, vec3 = pcall(function() return dcsWeapon:getPoint() end)
    if ok and vec3 then altImpactFt = _feet(vec3.y or 0) end
  end

  -- Nombre del objetivo: si tiene un nombre real o es scenery numerico
  local displayName = targetDisplayName
  if tonumber(targetDisplayName) and targetLabel then
    displayName = targetLabel  -- "BUILDING" mas legible que "86122733"
  end

  -- Marcar en weapon track que este arma SI impacto un objetivo (no es MISS)
  if dcsWeapon then
    local key = tostring(dcsWeapon)
    if _weaponTrack[key] then
      _weaponTrack[key].hitRegistered = true
      _weaponTrack[key].targetName    = displayName
      _weaponTrack[key].targetLabel   = targetLabel
    end
  end

  -- Mensaje en pantalla al impactar un objetivo
  local wInfo = dcsWeapon and _weaponTrack[tostring(dcsWeapon)]
  local pilotMsg = wInfo and wInfo.pilotId or _pilotIdFrom(EventData) or "IA"
  local aircraftMsg = wInfo and wInfo.pilotAircraft or "?"
  local weaponMsg = wInfo and wInfo.weaponName or EventData.WeaponName or "?"

  trigger.action.outText(string.format(
    "[IMPACT] Obj: %s | Tipo: %s | MGRS: %s | Alt: %s ft | Arma: %s | %s | %s",
    tostring(displayName),
    tostring(targetLabel or targetType or "?"),
    tostring(mgrsImpact or "N/A"),
    tostring(altImpactFt or "N/A"),
    tostring(weaponMsg),
    tostring(aircraftMsg),
    tostring(pilotMsg)
  ), 15)

  -- Guardar en _hitsLog para la logica de scoring en _onDeadOrCrash
  _hitsLog[targetUnitName] = _hitsLog[targetUnitName] or {}
  table.insert(_hitsLog[targetUnitName], {
    pilotId      = _pilotIdFrom(EventData),
    coalition    = shooterCoalition,
    weapon       = wInfo and wInfo.weaponName or EventData.WeaponName,
    mgrs         = mgrsImpact,
    altFt        = altImpactFt,
    targetName   = displayName,
    targetType   = targetLabel or targetType,
    domain       = domain,
    clockTime    = _missionClockHHMMSS(),
    timestamp    = timer.getTime(),
  })
end

-- DEAD/CRASH: logica de scoring (sin cambios respecto a v2).
local function _onDeadOrCrash(EventData)
  if not EventData or not EventData.IniUnitName then return end

  local victimUnitName  = EventData.IniUnitName
  local victimCoalition = _coalitionSideOf(EventData.IniCoalition)
  local victimPilotId   = _pilotIdFrom(EventData)
  local hits            = _hitsLog[victimUnitName] or {}
  local targetRecord    = DATA_Core.GetTarget(victimUnitName)

  local category, contributors, shooterCoalition = nil, {}, nil

  if targetRecord then
    category         = "TargetDestroyed"
    contributors     = _uniquePilotIds(hits)
    shooterCoalition = hits[1] and hits[1].coalition or nil
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
      category         = "EnemyKill"
      contributors     = _uniquePilotIds(enemyHits)
      shooterCoalition = enemyHits[1].coalition
    else
      category         = "BlueOnBlue"
      contributors     = _uniquePilotIds(friendlyHits)
      shooterCoalition = friendlyHits[1].coalition
    end
  else
    category = "Collateral"
  end

  local lastHit        = hits[#hits]
  local weaponUsed     = lastHit and lastHit.weapon    or nil
  local mgrsUsed       = lastHit and lastHit.mgrs      or nil
  local targetNameUsed = lastHit and lastHit.targetName or victimUnitName
  local targetTypeUsed = lastHit and lastHit.targetType or nil
  local domainUsed     = lastHit and lastHit.domain    or nil
  local clockTimeUsed  = lastHit and lastHit.clockTime or _missionClockHHMMSS()

  -- Fallbacks de dominio
  if domainUsed == nil then
    local tr = DATA_Core.GetTarget(victimUnitName)
    if tr then domainUsed = tr.type
    elseif tonumber(victimUnitName) then domainUsed = "ground"
    else domainUsed = "ground" end
  end

  if category == "TargetDestroyed" or category == "EnemyKill" then
    local basePoints = (category == "TargetDestroyed")
                        and PTS_Manager.POINTS.TARGET_DESTROYED
                        or  PTS_Manager.POINTS.ENEMY_KILL
    local numContrib = math.max(1, #contributors)
    local pointsEach = basePoints / numContrib

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
        reason        = category == "TargetDestroyed"
                          and "Target oficial de mision destruido"
                          or  "Unidad enemiga destruida",
      })
    end
    if shooterCoalition then
      DATA_Core.AddCoalitionPoints(shooterCoalition, basePoints)
    end
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

  else  -- Collateral
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

  _hitsLog[victimUnitName] = nil
end

--------------------------------------------------------------------
-- SUSCRIPCION A EVT_Dispatcher
--------------------------------------------------------------------
if EVT_Dispatcher and EVT_Dispatcher.Subscribe and DATA_Core then
  EVT_Dispatcher:Subscribe(EVENTS.Shot,  _onShot,         "PTS_Manager")
  EVT_Dispatcher:Subscribe(EVENTS.Hit,   _onHit,          "PTS_Manager")
  EVT_Dispatcher:Subscribe(EVENTS.Dead,  _onDeadOrCrash,  "PTS_Manager")
  EVT_Dispatcher:Subscribe(EVENTS.Crash, _onDeadOrCrash,  "PTS_Manager")
  env.info("PTS_Manager :: INICIADO correctamente, suscrito a EVT_Dispatcher.")
else
  env.error("PTS_Manager :: EVT_Dispatcher o DATA_Core no encontrados.")
end
