-- registroDeBombas_MOOSE.lua  Vers 1.07  2025-11-20  Hora 19:25

-- ####################################################
-- # CONFIGURACIÓN GENERAL
-- ####################################################
local DEBUG = true
local SCRIPT_NAME = "registroDeBombas_MOOSE.lua"
local SCRIPT_VERSION = "Vers 1.07"

function logDebug(message)
  local fullMsg = string.format("[%s][%s] %s", SCRIPT_NAME, SCRIPT_VERSION, message)
  if DEBUG then
    MESSAGE:New(fullMsg, 10):ToAll()
  end
  env.info(fullMsg)
end

-- ####################################################
-- # VARIABLES GLOBALES
-- ####################################################
local bombImpactCount = 0
local baseStaticName = "BOMB_IMPACT"
local staticTemplate = StaticObject.getByName(baseStaticName)

if not staticTemplate then
  logDebug("ERROR: Objeto estático 'BOMB_IMPACT' no encontrado en el ME.")
  return
end

-- Objetivos definidos
local knownTargets = {
  "TGT_BUILDING_1",
  "TGT_SAM_2",
  "TGT_BUNKER",
}

-- Tipos de objetos que serán ignorados en impactos
local excludedTypes = {
  ["WIRE"] = true,
  ["NEVADA_TRAFFICLIGHT_SMALL"] = true,
  ["POLE"] = true,
}

local IMPACT_RADIUS = 15

-- Ruta del archivo de log CSV
local logFilePath = lfs.writedir() .. "Logs/registroDeBombas.csv"

-- ####################################################
-- # FUNCIONES AUXILIARES GENERALES
-- ####################################################
local function feet(meters)
  return math.floor(meters * 3.28084)
end

local function getPilotName(unit)
  if unit and unit.GetPlayerName and unit:GetPlayerName() then
    return unit:GetPlayerName() or "IA"
  end
  return "Desconocido"
end

local function formatTime()
  local t = timer.getAbsTime()
  local h = math.floor(t / 3600)
  local m = math.floor((t % 3600) / 60)
  local s = math.floor(t % 60)
  return string.format("%02d:%02d:%02d", h, m, s)
end

-- Aquí está el cambio que pediste
local function initLogFile()
  -- Si el archivo existe, lo eliminamos
  local file = io.open(logFilePath, "r")
  if file then
    file:close()
    os.remove(logFilePath)
  end

  -- Creamos archivo nuevo con encabezado
  file = io.open(logFilePath, "w")
  if file then
    file:write("piloto,hora,plataforma,arma,tipo_evento,objeto_nombre,objeto_id,lat,lon,alt_ft\n")
    file:close()
  end
end

local function writeCSV(pilotName, platform, weaponName, eventType, objName, objId, lat, lon, altFt)
  local file = io.open(logFilePath, "a")
  if not file then return end

  pilotName  = pilotName  or "Desconocido"
  platform   = platform   or ""
  weaponName = weaponName or ""
  eventType  = eventType  or ""
  objName    = objName    or ""
  objId      = objId      or ""
  lat        = lat        or 0
  lon        = lon        or 0
  altFt      = altFt      or 0

  local timeStr = formatTime()

  local line = string.format(
    "%s,%s,%s,%s,%s,%s,%s,%.5f,%.5f,%d",
    pilotName, timeStr, platform, weaponName, eventType, objName, tostring(objId), lat, lon, altFt
  )

  file:write(line .. "\n")
  file:close()
end

-- ####################################################
-- # FUNCIONES AUXILIARES DE IMPACTO
-- ####################################################
local function isImpactNearObject(impactPos, radius)
  for _, groupName in ipairs(knownTargets) do
    local group = Group.getByName(groupName)
    if group then
      for _, unit in ipairs(group:getUnits()) do
        if unit and unit:isExist() then
          local pos = unit:getPoint()
          local dx = pos.x - impactPos.x
          local dz = pos.z - impactPos.z
          local dist = math.sqrt(dx * dx + dz * dz)
          if dist < radius then
            return true, groupName, dist
          end
        end
      end
    end
  end
  return false, nil, nil
end

-- ####################################################
-- # FUNC: REGISTRO DE IMPACTO GENERAL (OnWeaponImpact)
-- ####################################################
local function OnWeaponImpact(weapon)
  -- weapon aquí es el wrapper WEAPON de MOOSE
  local impactPos = weapon:GetPointVec3()
  local lat, lon = coord.LOtoLL(impactPos)
  local alt = feet(impactPos.y)

  local impactoEnObjeto, nombreObjeto, distancia = isImpactNearObject(impactPos, IMPACT_RADIUS)

  local textoImpacto
  if impactoEnObjeto then
    textoImpacto = string.format("Impacto cerca de: %s\nDistancia: %.1f m\n", nombreObjeto, distancia)
  else
    textoImpacto = "Impacto en área vacía\n"
  end

  textoImpacto = textoImpacto .. string.format("Lat: %.5f\nLon: %.5f\nAlt: %d ft", lat, lon, alt)

  MESSAGE:New(textoImpacto, 15):ToAll()
  logDebug(textoImpacto)

  -- Datos para CSV
  local launcher  = weapon:GetLauncher()
  local pilotName = getPilotName(launcher)
  local platform  = launcher and launcher:GetTypeName() or ""
  local arma      = weapon.ArmaNombre or weapon:GetName() or ""

  local objName = nombreObjeto or ""
  local objId   = ""

  writeCSV(pilotName, platform, arma, "IMPACTO", objName, objId, lat, lon, alt)

  bombImpactCount = bombImpactCount + 1
  local newName = string.format("BOMB_IMPACT_%d", bombImpactCount)

  local newStatic = {
    ["name"] = newName,
    ["type"] = staticTemplate:getTypeName(),
    ["position"] = {
      ["x"] = impactPos.x,
      ["y"] = impactPos.z,
    },
    ["heading"] = 0,
  }

  coalition.addStaticObject(launcher and launcher:GetCoalition() or 0, newStatic)
end

-- ####################################################
-- # HANDLER DE LANZAMIENTOS
-- ####################################################
WeaponEventHandler = EVENTHANDLER:New()
WeaponEventHandler:HandleEvent(EVENTS.Shot)

function WeaponEventHandler:OnEventShot(EventData)
  local initiator = EventData.IniUnit
  if not initiator or not initiator:IsPlayer() then return end

  local weapon = EventData.Weapon
  if not weapon then return end

  local weaponWrapper = WEAPON:New(weapon)
  if not weaponWrapper then return end

  local launchPos = initiator:GetPointVec3()
  local lat, lon  = coord.LOtoLL(launchPos)
  local alt       = feet(launchPos.y)

  local pilotName = getPilotName(initiator)
  local platform  = initiator:GetTypeName()

  local arma = "arma_desconocida"
  if weapon and weapon.getDesc then
    local d = weapon:getDesc()
    arma = d.displayName or d.typeName or arma
  end

  weaponWrapper.ArmaNombre = arma

  local textoLanzamiento = string.format(
    "Lanzamiento: %s lanzó %s desde %s\nAlt: %d ft | Lat: %.5f | Lon: %.5f",
    pilotName,
    arma,
    platform,
    alt, lat, lon
  )

  logDebug(textoLanzamiento)

  writeCSV(pilotName, platform, arma, "LANZAMIENTO", "", "", lat, lon, alt)

  weaponWrapper:SetFuncImpact(OnWeaponImpact)
  weaponWrapper:StartTrack()
end

-- ####################################################
-- # HANDLER DE IMPACTOS EN OBJETOS (S_EVENT_HIT)
-- ####################################################
HitEventHandler = {}
function HitEventHandler:onEvent(event)
  if event.id == world.event.S_EVENT_HIT and event.weapon and event.target then
    local target = event.target
    local tipo   = target:getTypeName()

    if excludedTypes[tipo] then
      return
    end

    local pos = event.weapon:getPoint()
    local alt = feet(pos.y)
    local lat, lon = coord.LOtoLL(pos)

    local rawName = target.getName and target:getName() or ""
    local objId   = target.id_ or ""

    local objName = rawName
    if not objName or objName == "" or tonumber(objName) ~= nil then
      objName = tipo
    end

    local textoHit = string.format(
      "Impacto confirmado sobre objeto:\nObjeto: %s (%s)\nLat: %.5f | Lon: %.5f | Alt: %d ft",
      objName,
      tipo,
      lat, lon, alt
    )

    trigger.action.outText(textoHit, 12)
    env.info(textoHit)

    local pilotName = "Desconocido"
    local platform  = ""
    if event.initiator and event.initiator.getTypeName then
      platform = event.initiator:getTypeName() or ""
    end
    if event.initiator and event.initiator.getPlayerName and event.initiator:getPlayerName() then
      pilotName = event.initiator:getPlayerName()
    end

    local arma = "arma_desconocida"
    if event.weapon and event.weapon.getDesc then
      local d = event.weapon:getDesc()
      arma = d.displayName or d.typeName or arma
    end

    writeCSV(pilotName, platform, arma, "IMPACTO_OBJETO", objName, objId, lat, lon, alt)
  end
end

world.addEventHandler(HitEventHandler)

-- ####################################################
-- # INICIALIZACIÓN
-- ####################################################
initLogFile()
logDebug("Script 'registroDeBombas_MOOSE' v1.07 cargado con reinicio de CSV al inicio.")
