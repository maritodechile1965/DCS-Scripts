--[[
================================================================================
 TEST_Handler.lua
 Modulo de PRUEBA del EVT_Dispatcher.

 Proposito:
   Suscribirse a TODOS los eventos registrados en EVT_Dispatcher y, cuando
   cada uno se dispare, mostrar un mensaje en pantalla (MESSAGE) y un log en
   dcs.log con los datos clave del evento (quien, que unidad, coalicion).

   Este script es TEMPORAL, solo para validar que el Pub/Sub del
   EVT_Dispatcher funciona correctamente. No forma parte del backlog de
   modulos definitivos del proyecto.

 Requiere cargarse DESPUES de:
   1) Moose.lua
   2) EVT_Dispatcher.lua

 Convenciones del proyecto respetadas:
   - Prefijo de modulo: TEST_
   - Handler: TEST_Handler
================================================================================
]]

if EVT_Dispatcher == nil then
    env.info("TEST_Handler :: ERROR - EVT_Dispatcher no esta cargado. Abortando.")
    return
end

TEST_Handler = {}

--------------------------------------------------------------------------------
-- Funcion auxiliar: arma un texto descriptivo a partir de un EventData
--------------------------------------------------------------------------------
local function DescribeEvent(eventName, EventData)

    local unitName = "N/A"
    local groupName = "N/A"
    local playerName = "N/A"
    local coalitionText = "N/A"

    if EventData then
        if EventData.IniUnitName then
            unitName = EventData.IniUnitName
        end
        if EventData.IniGroupName then
            groupName = EventData.IniGroupName
        end
        if EventData.IniPlayerName then
            playerName = EventData.IniPlayerName
        end
        if EventData.IniCoalition then
            coalitionText = tostring(EventData.IniCoalition)
        end
    end

    local text = string.format(
        "[TEST] %s | Unidad: %s | Grupo: %s | Jugador: %s | Coalicion: %s",
        eventName, unitName, groupName, playerName, coalitionText
    )

    return text
end

--------------------------------------------------------------------------------
-- Una funcion callback por evento (mas explicito y facil de leer en dcs.log
-- que una sola funcion generica)
--------------------------------------------------------------------------------

function TEST_Handler.OnBirth(EventData)
    local msg = DescribeEvent("BIRTH", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnDead(EventData)
    local msg = DescribeEvent("DEAD", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnCrash(EventData)
    local msg = DescribeEvent("CRASH", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnLand(EventData)
    local msg = DescribeEvent("LAND", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnTakeoff(EventData)
    local msg = DescribeEvent("TAKEOFF", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnEjection(EventData)
    local msg = DescribeEvent("EJECTION", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnLandingAfterEjection(EventData)
    local msg = DescribeEvent("LANDING_AFTER_EJECTION", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnPilotDead(EventData)
    local msg = DescribeEvent("PILOT_DEAD", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnBaseCaptured(EventData)
    local msg = DescribeEvent("BASE_CAPTURED", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnPlayerEnterUnit(EventData)
    local msg = DescribeEvent("PLAYER_ENTER_UNIT", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnPlayerLeaveUnit(EventData)
    local msg = DescribeEvent("PLAYER_LEAVE_UNIT", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnHit(EventData)
    local msg = DescribeEvent("HIT", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

function TEST_Handler.OnShot(EventData)
    local msg = DescribeEvent("SHOT", EventData)
    env.info(msg)
    MESSAGE:New(msg, 10):ToAll()
end

--------------------------------------------------------------------------------
-- Suscripcion de cada callback al EVT_Dispatcher
--------------------------------------------------------------------------------

EVT_Dispatcher:Subscribe(EVENTS.Birth,                TEST_Handler.OnBirth,                "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Dead,                 TEST_Handler.OnDead,                 "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Crash,                TEST_Handler.OnCrash,                "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Land,                 TEST_Handler.OnLand,                 "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Takeoff,              TEST_Handler.OnTakeoff,              "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Ejection,              TEST_Handler.OnEjection,              "TEST")
EVT_Dispatcher:Subscribe(EVENTS.LandingAfterEjection, TEST_Handler.OnLandingAfterEjection, "TEST")
EVT_Dispatcher:Subscribe(EVENTS.PilotDead,            TEST_Handler.OnPilotDead,            "TEST")
EVT_Dispatcher:Subscribe(EVENTS.BaseCaptured,         TEST_Handler.OnBaseCaptured,         "TEST")
EVT_Dispatcher:Subscribe(EVENTS.PlayerEnterUnit,      TEST_Handler.OnPlayerEnterUnit,      "TEST")
EVT_Dispatcher:Subscribe(EVENTS.PlayerLeaveUnit,      TEST_Handler.OnPlayerLeaveUnit,      "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Hit,                  TEST_Handler.OnHit,                  "TEST")
EVT_Dispatcher:Subscribe(EVENTS.Shot,                 TEST_Handler.OnShot,                 "TEST")

env.info("================================================================")
env.info("TEST_Handler :: INICIADO. Suscrito a 13 eventos de EVT_Dispatcher.")
env.info("================================================================")
