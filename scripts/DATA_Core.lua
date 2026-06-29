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

-- Ledger (registro historico, append-only) de cada evento de puntos
-- otorgado o penalizado. Pensado desde el diseno para exportarse a
-- CSV/Excel mas adelante sin tocar esta estructura -- ver
-- DATA_Core.PointsLedgerToCSV() mas abajo.
local _pointsLedger = {}

--------------------------------------------------------------------
-- UTILIDADES INTERNAS
--------------------------------------------------------------------

-- NOTA IMPORTANTE (corregido tras prueba en juego, sesion 5):
-- DCS sandboxea por defecto las librerias del sistema operativo de
-- Lua (os, io, lfs) dentro del entorno de misiones, por razones de
-- seguridad. Esto se puede habilitar editando el archivo
-- MissionScripting.lua de la instalacion de DCS (ver mas abajo), pero
-- depende de configuracion externa al proyecto y afecta a todo DCS,
-- no solo a este script -- en multijugador, ademas, lo decide el
-- servidor, no cada cliente. Por eso para esta v1 evitamos toda
-- dependencia de "os" y usamos timer.getTime() (funcion nativa de
-- DCS, siempre disponible, da el tiempo en segundos desde el inicio
-- de la mision) para timestamps, y un reset MANUAL para el contador
-- de misiones diarias (ver DATA_Core.ResetDailyCounters mas abajo).
--
-- Si en el futuro se decide habilitar "os" a nivel de DCS (editando
-- C:\Program Files\Eagle Dynamics\DCS World\Scripts\MissionScripting.lua,
-- comentando las lineas que hacen os = nil / io = nil / lfs = nil),
-- se podria reintroducir aqui un reset automatico por fecha real
-- usando os.date(), sin romper la API publica de DATA_Core (solo
-- cambiaria la implementacion interna del reset).
--------------------------------------------------------------------

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
-- "Hoy" en esta v1 significa "desde el ultimo DATA_Core.ResetDailyCounters()",
-- ya que no hay acceso a la fecha real del sistema (ver nota sobre "os" arriba).
-- @param pilotId string
-- @return boolean
function DATA_Core.CanFlyMissionToday(pilotId)
  local pilot = _pilots[pilotId]
  if not pilot then return true end -- sin registro, se asume permitido
  return pilot.missionsToday < 2
end

--- Registra que el piloto voló una mision aerea hoy (incrementa contador).
-- @param pilotId string
function DATA_Core.RegisterMissionFlown(pilotId)
  local pilot = _pilots[pilotId]
  if not pilot then return end
  pilot.missionsToday = pilot.missionsToday + 1
end

--- Resetea el contador de "misiones hoy" de TODOS los pilotos.
-- Reemplaza el reset automatico por fecha real (no disponible sin
-- "os"). Llamar manualmente al inicio de cada sesion/dia de juego,
-- por ejemplo desde un trigger de tiempo o un comando de admin.
function DATA_Core.ResetDailyCounters()
  for _, pilot in pairs(_pilots) do
    pilot.missionsToday = 0
  end
end

--- Agrega una entrada a la bitacora de vuelo del piloto.
-- @param pilotId string
-- @param entry table  Estructura libre, ej: {event="Takeoff", timestamp=..., details=...}
function DATA_Core.AddLogbookEntry(pilotId, entry)
  local pilot = _pilots[pilotId]
  if not pilot then return end
  entry.timestamp = entry.timestamp or timer.getTime()
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
    timestamp = timer.getTime(),
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
  targetData.timestamp   = targetData.timestamp or timer.getTime()
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
-- API: LEDGER DE PUNTOS
--------------------------------------------------------------------

--- Agrega una entrada al ledger historico de puntos (append-only).
-- Pensado para ser generico: cualquier modulo (PTS_Manager, y a futuro
-- CSAR, logistica, etc.) puede registrar aqui sus eventos de puntos,
-- sin que DATA_Core necesite conocer la logica de negocio de cada uno.
-- @param entry table  Estructura libre, recomendado incluir al menos:
--   pilotId, coalition, category, amount, weapon, targetName, mgrs, reason
function DATA_Core.AddPointsLedgerEntry(entry)
  entry.timestamp = entry.timestamp or timer.getTime()
  table.insert(_pointsLedger, entry)
end

--- Devuelve el ledger completo de puntos (array, en orden cronologico).
-- @return table
function DATA_Core.GetPointsLedger()
  return _pointsLedger
end

--- Convierte el ledger de puntos a texto CSV (en memoria, NO escribe a
-- disco -- esta funcion no usa io/os, solo concatena strings, por lo
-- que funciona sin necesidad de modificar MissionScripting.lua). El
-- dia que se decida exportar realmente a un archivo, un modulo nuevo
-- (ej. DATA_Export.lua) puede llamar a esta funcion y hacer
-- io.open():write() con el resultado -- sin tocar nada de DATA_Core
-- ni de PTS_Manager.
-- @return string
function DATA_Core.PointsLedgerToCSV()
  local lines = { "timestamp,pilotId,coalition,category,amount,weapon,targetName,mgrs,reason" }
  for _, entry in ipairs(_pointsLedger) do
    table.insert(lines, table.concat({
      tostring(entry.timestamp or ""),
      tostring(entry.pilotId or ""),
      tostring(entry.coalition or ""),
      tostring(entry.category or ""),
      tostring(entry.amount or ""),
      tostring(entry.weapon or ""),
      tostring(entry.targetName or ""),
      tostring(entry.mgrs or ""),
      tostring(entry.reason or ""),
    }, ","))
  end
  return table.concat(lines, "\n")
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

-- Crea el registro del piloto en DATA_Core la primera vez que un
-- jugador humano entra a una unidad. Sin esto, los demas handlers
-- (Shot, Takeoff, Land, etc.) no tienen un piloto existente al cual
-- escribir, y descartan el evento silenciosamente (ver GetOrCreatePilot,
-- que solo escribe si _pilots[pilotId] ya existe).
local function _onPlayerEnterUnit(EventData)
  if not EventData or not EventData.IniPlayerName then return end

  local pilotCoalition = nil
  if EventData.IniCoalition == coalition.side.BLUE then
    pilotCoalition = "blue"
  elseif EventData.IniCoalition == coalition.side.RED then
    pilotCoalition = "red"
  end

  DATA_Core.GetOrCreatePilot(EventData.IniPlayerName, EventData.IniPlayerName, pilotCoalition)
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
  EVT_Dispatcher:Subscribe(EVENTS.PlayerEnterUnit, _onPlayerEnterUnit,        "DATA_Core")
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
