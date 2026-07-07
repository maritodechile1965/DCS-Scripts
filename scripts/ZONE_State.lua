--[[
====================================================================
 ZONE_State.lua
 Gestiona el estado de zonas y bases del mapa durante la campaña.
 Lee el estado guardado al inicio de la misión y lo aplica en DCS.
 Actualiza DATA_Core cuando una base cambia de coalición en juego.

 Responsabilidades:
   1. Al cargar: llama DATA_Export.RestoreBaseStates() para aplicar
      el estado persistido de la sesión anterior
   2. En runtime: escucha el evento BaseCaptured y actualiza
      DATA_Core._baseStates cuando una base cambia de manos
   3. Expone ZONE_State.GetBaseCoalition() como acceso rápido

 Dependencias (orden de carga obligatorio):
   Moose.lua → EVT_Dispatcher.lua → DATA_Core.lua →
   PTS_Manager.lua → DATA_Export.lua → ZONE_State.lua

 Version: v1
====================================================================
]]

ZONE_State = {}

--------------------------------------------------------------------
-- RESTAURACIÓN AL INICIO (aplica estado de sesión anterior)
--------------------------------------------------------------------
-- Se ejecuta automáticamente al cargar el script. Si existe el CSV
-- DCS_Base_State.csv de una sesión previa, aplica los cambios de
-- coalición en DCS y en DATA_Core. Si no existe, usa el estado
-- inicial definido en DATA_Core._baseStates (todas las bases en su
-- coalición por defecto).

local function _restoreOnLoad()
  if DATA_Export and DATA_Export.RestoreBaseStates then
    local ok = DATA_Export.RestoreBaseStates()
    if not ok then
      env.info("ZONE_State :: Sin sesion previa — usando estado inicial de DATA_Core.")
    end
  else
    env.error("ZONE_State :: DATA_Export no disponible. Verificar orden de carga.")
  end
end

--------------------------------------------------------------------
-- HANDLER: BASE CAPTURADA EN JUEGO
--------------------------------------------------------------------
-- Se dispara cuando una base cambia de manos durante la sesión.
-- Actualiza DATA_Core en memoria para que el estado refleje el
-- mundo real de DCS en todo momento.

local function _onBaseCaptured(EventData)
  if not EventData or not EventData.IniCoalition then return end

  -- El nombre de la base en el evento
  local baseName = nil
  if EventData.IniUnit then
    local ok, name = pcall(function() return EventData.IniUnit:GetName() end)
    if ok and name then baseName = name end
  end
  -- Fallback: nombre del grupo que capturó
  if not baseName and EventData.IniGroup then
    local ok, name = pcall(function() return EventData.IniGroup:GetName() end)
    if ok and name then baseName = name end
  end

  -- Coalición que capturó la base
  local newCoalition = nil
  if EventData.IniCoalition == coalition.side.BLUE then
    newCoalition = "blue"
  elseif EventData.IniCoalition == coalition.side.RED then
    newCoalition = "red"
  end

  if not newCoalition then return end

  -- Intentar obtener el nombre de la base desde el Airbase más cercano
  -- (en DCS, BaseCaptured tiene TgtAirbase o similar según versión MOOSE)
  local capturedBase = nil
  if EventData.TgtAirbase then
    local ok, name = pcall(function() return EventData.TgtAirbase:GetName() end)
    if ok and name then capturedBase = name end
  end
  if not capturedBase then capturedBase = baseName end
  if not capturedBase then return end

  -- Actualizar DATA_Core
  local updated = DATA_Core.SetBaseCoalition(capturedBase, newCoalition)
  if updated then
    local msg = string.format(
      "[CAMPAÑA] Base capturada: %s → %s",
      capturedBase,
      newCoalition == "blue" and "AZUL ✈" or "ROJA ✈"
    )
    trigger.action.outText(msg, 20)
    env.info("ZONE_State :: " .. msg)
  end
end

--------------------------------------------------------------------
-- API PÚBLICA
--------------------------------------------------------------------

--- Consulta rápida del estado de una base.
-- @param baseName string  nombre exacto de la base en DCS
-- @return string|nil  "blue", "red" o nil si no existe
function ZONE_State.GetBaseCoalition(baseName)
  return DATA_Core.GetBaseCoalition(baseName)
end

--- Fuerza el cambio de coalición de una base tanto en DATA_Core
-- como en DCS (para usar desde CAMPAIGN_Manager u otros módulos).
-- @param baseName   string
-- @param coalition  string  "blue" o "red"
function ZONE_State.CaptureBase(baseName, newCoalition)
  local updated = DATA_Core.SetBaseCoalition(baseName, newCoalition)
  if not updated then return end

  -- Aplicar en DCS via API nativa
  pcall(function()
    local ab = Airbase.getByName(baseName)
    if ab then
      local side = newCoalition == "blue"
        and coalition.side.BLUE
        or  coalition.side.RED
      ab:autoCapture(false)
      coalition.addAirfield(side, baseName)
    end
  end)

  env.info("ZONE_State :: CaptureBase: " .. baseName .. " → " .. newCoalition)
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------

if EVT_Dispatcher and EVT_Dispatcher.Subscribe and DATA_Core and DATA_Export then
  -- Restaurar estado de la sesión anterior
  _restoreOnLoad()

  -- Escuchar capturas de base durante la sesión
  EVT_Dispatcher:Subscribe(EVENTS.BaseCaptured, _onBaseCaptured, "ZONE_State")

  -- Grabar automáticamente al terminar la misión (MissionEnd)
  local function _onMissionEnd(EventData)
    env.info("ZONE_State :: MissionEnd detectado — grabando estado final...")
    DATA_Export.WriteAll()
  end
  EVT_Dispatcher:Subscribe(EVENTS.MissionEnd, _onMissionEnd, "ZONE_State")

  -- Grabación periódica cada DATA_Export.SAVE_INTERVAL_SECONDS
  -- Se ejecuta en background sin interrumpir el juego.
  -- Para pruebas: cambiar DATA_Export.SAVE_INTERVAL_SECONDS = 300 (5 min)
  local function _scheduledSave()
    local interval = DATA_Export.SAVE_INTERVAL_SECONDS or 10800
    env.info(string.format(
      "ZONE_State :: Grabación automática (cada %d min)...",
      math.floor(interval / 60)
    ))
    DATA_Export.WriteAll()
  end

  local interval = DATA_Export.SAVE_INTERVAL_SECONDS or 10800
  SCHEDULER:New(nil, _scheduledSave, {}, interval, interval)
  env.info(string.format(
    "ZONE_State :: Grabación automática cada %d minutos.",
    math.floor(interval / 60)
  ))

  env.info("ZONE_State :: INICIADO correctamente.")
else
  env.error("ZONE_State :: Faltan dependencias. Verificar orden de carga: " ..
    "Moose → EVT_Dispatcher → DATA_Core → PTS_Manager → DATA_Export → ZONE_State")
end
