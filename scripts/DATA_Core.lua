--[[
====================================================================
 DATA_Core.lua
 Modulo de "base de datos" central en memoria del proyecto.
 Almacena: Pilotos, Coaliciones, Targets/Objetivos, Misiones activas.

 Dependencias:
   - Moose.lua          (cargado antes, via loadfile en Mission Editor)
   - EVT_Dispatcher.lua (cargado antes, este modulo se suscribe a el)

 Version: v1 (simple, solo en memoria, sin persistencia a disco)
 Convencion de nombres del proyecto:
   - Prefijo de modulo: DATA_
   - PascalCase para objetos/namespace, camelCase variables locales,
     UPPER_SNAKE_CASE constantes/flags
====================================================================
]]

DATA_Core = {}

--------------------------------------------------------------------
-- ESTRUCTURAS INTERNAS (privadas al modulo)
--------------------------------------------------------------------

-- Tabla de pilotos, indexada por pilotId (string, normalmente el
-- nombre de la unidad o UCID del jugador)
local _pilots = {}

-- Tabla de coaliciones, indexada por "blue" / "red"
local _coalitions = {
  blue = { side = "blue", points = 0, warehouse = { fuel = 0, weapons = {}, aircraft = {}, vehicles = {} }, iadsLevel = 0 },
  red  = { side = "red",  points = 0, warehouse = { fuel = 0, weapons = {}, aircraft = {}, vehicles = {} }, iadsLevel = 0 },
}

-- Tabla de targets/objetivos, indexada por targetId (number o string)
local _targets = {}

-- Tabla de misiones activas, indexada por missionId (string)
local _missions = {}

--------------------------------------------------------------------
-- UTILIDADES INTERNAS
--------------------------------------------------------------------

-- Devuelve la fecha actual en formato "YYYY-MM-DD" (para reset diario
-- del contador de misiones por piloto). Usa os.date de Lua estandar.
local function _today()
  return os.date("%Y-%m-%d")
end

--------------------------------------------------------------------
-- API: PILOTOS
--------------------------------------------------------------------

--- Crea un piloto si no existe, o retorna el existente.
-- @param pilotId string  Identificador unico del piloto (ej. PlayerName o UCID)
-- @param name string     Nombre visible del piloto
-- @param coalition string "blue" o "red"
-- @return table          El registro del piloto
function DATA_Core.GetOrCreatePilot(pilotId, name, coalition)
  if not _pilots[pilotId] then
    _pilots[pilotId] = {
      id              = pilotId,
      name            = name or pilotId,
      coalition       = coalition,
      points          = 0,
      missionsToday   = 0,
      lastMissionDate = _today(),
      logbook         = {},
      weaponsLog      = {},
    }
  end
  return _pilots[pilotId]
end

--- Obtiene un piloto existente (no lo crea).
-- @param pilotId string
-- @return table|nil
function DATA_Core.GetPilot(pilotId)
  return _pilots[pilotId]
end

--- Suma (o resta, con numero negativo) puntos a un piloto.
-- @param pilotId string
-- @param amount number
function DATA_Core.AddPilotPoints(pilotId, amount)
  local pilot = _pilots[pilotId]
  if not pilot then return end
  pilot.points = pilot.points + amount
end

--- Verifica si el piloto puede volar otra mision aerea hoy (maximo 2/dia).
-- Resetea automaticamente el contador si cambio el dia.
-- @param pilotId string
-- @return boolean
function DATA_Core.CanFlyMissionToday(pilotId)
  local pilot = _pilots[pilotId]
  if not pilot then return true end -- sin registro, se asume permitido

  local today = _today()
  if pilot.lastMissionDate ~= today then
    pilot.missionsToday   = 0
    pilot.lastMissionDate = today
  end

  return pilot.missionsToday < 2
end

--- Registra que el piloto voló una mision aerea hoy (incrementa contador).
-- @param pilotId string
function DATA_Core.RegisterMissionFlown(pilotId)
  local pilot = _pilots[pilotId]
  if not pilot then return end

  local today = _today()
  if pilot.lastMissionDate ~= today then
    pilot.missionsToday   = 0
    pilot.lastMissionDate = today
  end

  pilot.missionsToday = pilot.missionsToday + 1
end

--- Agrega una entrada a la bitacora de vuelo del piloto.
-- @param pilotId string
-- @param entry table  Estructura libre, ej: {event="Takeoff", timestamp=..., details=...}
function DATA_Core.AddLogbookEntry(pilotId, entry)
  local pilot = _pilots[pilotId]
  if not pilot then return end
  entry.timestamp = entry.timestamp or os.time()
  table.insert(pilot.logbook, entry)
end

--- Registra un disparo de armamento del piloto (para ranking de efectividad).
-- @param pilotId string
-- @param weapon string
-- @param targetId string|number|nil
-- @param hit boolean|nil
function DATA_Core.RegisterShot(pilotId, weapon, targetId, hit)
  local pilot = _pilots[pilotId]
  if not pilot then return end
  table.insert(pilot.weaponsLog, {
    weapon    = weapon,
    targetId  = targetId,
    hit       = hit,
    timestamp = os.time(),
  })
end

--------------------------------------------------------------------
-- API: COALICIONES
--------------------------------------------------------------------

--- Obtiene la tabla de una coalicion ("blue" o "red").
-- @param side string
-- @return table|nil
function DATA_Core.GetCoalition(side)
  return _coalitions[side]
end

--- Suma (o resta) puntos a una coalicion.
-- @param side string
-- @param amount number
function DATA_Core.AddCoalitionPoints(side, amount)
  local coalition = _coalitions[side]
  if not coalition then return end
  coalition.points = coalition.points + amount
end

--------------------------------------------------------------------
-- API: TARGETS / OBJETIVOS
--------------------------------------------------------------------

--- Registra un nuevo target/objetivo en la tabla de control.
-- @param targetData table  Debe incluir al menos: id, name, type, coalition, coords
function DATA_Core.RegisterTarget(targetData)
  targetData.alive       = true
  targetData.destroyedBy = nil
  targetData.timestamp   = targetData.timestamp or os.time()
  _targets[targetData.id] = targetData
end

--- Obtiene un target por su id.
-- @param targetId string|number
-- @return table|nil
function DATA_Core.GetTarget(targetId)
  return _targets[targetId]
end

--- Marca un target como destruido.
-- @param targetId string|number
-- @param byPilotId string|nil
function DATA_Core.SetTargetDestroyed(targetId, byPilotId)
  local target = _targets[targetId]
  if not target then return end
  target.alive       = false
  target.destroyedBy = byPilotId
end

--------------------------------------------------------------------
-- API: MISIONES
--------------------------------------------------------------------

--- Crea una nueva mision activa.
-- @param missionData table  Debe incluir al menos: id, type, minPilots
function DATA_Core.CreateMission(missionData)
  missionData.assignedPilots = missionData.assignedPilots or {}
  missionData.status         = missionData.status or "pending"
  _missions[missionData.id] = missionData
end

--- Obtiene una mision por su id.
-- @param missionId string
-- @return table|nil
function DATA_Core.GetMission(missionId)
  return _missions[missionId]
end

--- Devuelve todas las misiones activas (status ~= "success"/"failed").
-- @return table  array de misiones
function DATA_Core.GetActiveMissions()
  local result = {}
  for _, mission in pairs(_missions) do
    if mission.status == "pending" or mission.status == "active" then
      table.insert(result, mission)
    end
  end
  return result
end

--------------------------------------------------------------------
-- SUSCRIPCION A EVT_Dispatcher
--
-- Verificado contra el codigo real de EVT_Dispatcher.lua:
--   function EVT_Dispatcher:Subscribe(eventId, callback, moduleName)
-- donde eventId es una constante EVENTS.X de MOOSE (no un string), y
-- callback recibe el objeto EventData nativo que entrega MOOSE/DCS.
--
-- Campos relevantes de EventData usados aqui (segun la documentacion
-- de MOOSE Core.Event):
--   IniUnitName    -- nombre de la unidad que origina el evento
--   IniPlayerName  -- nombre del jugador, si la unidad es tripulada por humano
--   TgtUnitName    -- nombre de la unidad objetivo (cuando aplica, ej. Hit)
--   WeaponName     -- nombre del arma disparada (evento Shot)
--
-- Para pilotId usamos IniPlayerName si existe (jugador humano), y si
-- no, caemos a IniUnitName (IA u otro caso). Esto se puede refinar
-- mas adelante sin romper la firma publica de DATA_Core.
--------------------------------------------------------------------

local function _pilotIdFrom(EventData)
  if not EventData then return nil end
  return EventData.IniPlayerName or EventData.IniUnitName
end

local function _onShot(EventData)
  local pilotId = _pilotIdFrom(EventData)
  if pilotId then
    DATA_Core.RegisterShot(pilotId, EventData.WeaponName, EventData.TgtUnitName, nil)
  end
end

local function _onDeadOrCrash(EventData)
  if EventData and EventData.IniUnitName then
    -- La unidad que murio/se estrello es el "target" en nuestra tabla,
    -- si fue registrada previamente via DATA_Core.RegisterTarget()
    DATA_Core.SetTargetDestroyed(EventData.IniUnitName, nil)
  end
end

local function _onTakeoffOrLand(eventLabel)
  return function(EventData)
    local pilotId = _pilotIdFrom(EventData)
    if pilotId then
      DATA_Core.AddLogbookEntry(pilotId, { event = eventLabel })
    end
  end
end

local function _onPilotDeadOrEjection(EventData)
  local pilotId = _pilotIdFrom(EventData)
  if pilotId then
    DATA_Core.AddLogbookEntry(pilotId, { event = "PilotDownEvent" })
    -- Punto de enganche futuro: aqui se podra disparar la mision CSAR
    -- automaticamente cuando ese modulo exista.
  end
end

if EVT_Dispatcher and EVT_Dispatcher.Subscribe then
  EVT_Dispatcher:Subscribe(EVENTS.Shot,      _onShot,                       "DATA_Core")
  EVT_Dispatcher:Subscribe(EVENTS.Dead,      _onDeadOrCrash,                "DATA_Core")
  EVT_Dispatcher:Subscribe(EVENTS.Crash,     _onDeadOrCrash,                "DATA_Core")
  EVT_Dispatcher:Subscribe(EVENTS.Takeoff,   _onTakeoffOrLand("Takeoff"),   "DATA_Core")
  EVT_Dispatcher:Subscribe(EVENTS.Land,      _onTakeoffOrLand("Land"),      "DATA_Core")
  EVT_Dispatcher:Subscribe(EVENTS.PilotDead, _onPilotDeadOrEjection,        "DATA_Core")
  EVT_Dispatcher:Subscribe(EVENTS.Ejection,  _onPilotDeadOrEjection,        "DATA_Core")

  env.info("DATA_Core :: INICIADO correctamente, suscrito a EVT_Dispatcher.")
else
  env.error("DATA_Core :: EVT_Dispatcher no encontrado o sin metodo Subscribe. Verificar orden de carga (Moose.lua -> EVT_Dispatcher.lua -> DATA_Core.lua).")
end
