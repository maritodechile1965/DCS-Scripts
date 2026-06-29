--[[
================================================================================
 EVT_Dispatcher.lua
 Event Dispatcher Central del proyecto.

 Proposito:
   Punto unico de suscripcion (Pub/Sub) a eventos de DCS, construido sobre la
   clase EVENTHANDLER de MOOSE. Todos los modulos del proyecto (WH_, CSAR_,
   FTR_, ESC_, TRP_, GC_, CTLD_, etc.) deben suscribirse aqui en lugar de
   crear su propio EVENTHANDLER independiente.

 Carga:
   Debe cargarse DESPUES de Moose.lua y ANTES que cualquier modulo que
   dependa de EVT_Dispatcher.

 Convenciones del proyecto:
   - Dispatcher central: EVT_Dispatcher
   - Prefijos por modulo: WH_, CSAR_, FTR_, ESC_, TRP_, GC_, CTLD_
   - Casing: PascalCase (objetos MOOSE) / camelCase (variables locales) /
     UPPER_SNAKE_CASE (constantes y flags)
   - Handlers por modulo: <PREFIJO>_Handler

 Autor: Mario (proyecto DCS Scripting)
================================================================================
]]

-- Evita doble inicializacion si el script se carga mas de una vez
if EVT_Dispatcher ~= nil then
    env.info("EVT_Dispatcher :: ya estaba inicializado, se omite re-creacion.")
    return
end

--------------------------------------------------------------------------------
-- 1. Instancia unica del EVENTHANDLER de MOOSE
--------------------------------------------------------------------------------

EVT_Dispatcher = EVENTHANDLER:New()

-- Tabla de suscriptores: Subscribers[EVENTS.X] = { {moduleName=.., callback=..}, ... }
EVT_Dispatcher.Subscribers = {}

-- Lista de eventos que el dispatcher escucha desde el arranque.
-- Se puede ampliar sin romper nada: solo agregar la constante EVENTS.X aqui
-- y su metodo OnEventX correspondiente mas abajo.
EVT_Dispatcher.RegisteredEvents = {
    EVENTS.Birth,
    EVENTS.Dead,
    EVENTS.Crash,
    EVENTS.Land,
    EVENTS.Takeoff,
    EVENTS.Ejection,
    EVENTS.LandingAfterEjection,
    EVENTS.PilotDead,
    EVENTS.BaseCaptured,
    EVENTS.PlayerEnterUnit,
    EVENTS.PlayerLeaveUnit,
    EVENTS.Hit,
    EVENTS.Shot,
}

--------------------------------------------------------------------------------
-- 2. API publica de suscripcion
--------------------------------------------------------------------------------

--- Permite a un modulo suscribirse a un evento especifico.
-- @param eventId   Constante EVENTS.X de MOOSE (ej: EVENTS.Dead)
-- @param callback  function(EventData) -- funcion del modulo que procesa el evento
-- @param moduleName string -- nombre del modulo, solo para trazabilidad/logs (ej: "CSAR")
function EVT_Dispatcher:Subscribe(eventId, callback, moduleName)

    if eventId == nil or type(callback) ~= "function" then
        env.info("EVT_Dispatcher :: Subscribe() invalido, falta eventId o callback. Modulo: " .. tostring(moduleName))
        return false
    end

    if self.Subscribers[eventId] == nil then
        self.Subscribers[eventId] = {}
    end

    table.insert(self.Subscribers[eventId], {
        moduleName = moduleName or "DESCONOCIDO",
        callback = callback,
    })

    env.info("EVT_Dispatcher :: Modulo '" .. tostring(moduleName) .. "' suscrito a evento ID " .. tostring(eventId))
    return true
end

--- Permite a un modulo cancelar su suscripcion a un evento.
-- @param eventId   Constante EVENTS.X de MOOSE
-- @param callback  La misma referencia de funcion usada en Subscribe()
function EVT_Dispatcher:Unsubscribe(eventId, callback)

    local list = self.Subscribers[eventId]
    if list == nil then
        return false
    end

    for i, entry in ipairs(list) do
        if entry.callback == callback then
            table.remove(list, i)
            env.info("EVT_Dispatcher :: Modulo '" .. tostring(entry.moduleName) .. "' desuscrito de evento ID " .. tostring(eventId))
            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- 3. Despachador interno (aislado con pcall por suscriptor)
--------------------------------------------------------------------------------

--- Recorre los suscriptores de un evento y los llama de forma aislada.
-- Un error en un modulo NO debe afectar a los demas suscriptores.
-- @param eventId   Constante EVENTS.X de MOOSE
-- @param EventData Objeto EventData entregado por MOOSE
function EVT_Dispatcher:_Dispatch(eventId, EventData)

    local list = self.Subscribers[eventId]
    if list == nil or #list == 0 then
        return
    end

    for _, entry in ipairs(list) do
        local ok, err = pcall(entry.callback, EventData)
        if not ok then
            env.info("EVT_Dispatcher :: ERROR en modulo '" .. tostring(entry.moduleName) ..
                      "' procesando evento ID " .. tostring(eventId) .. " -> " .. tostring(err))
        end
    end
end

--------------------------------------------------------------------------------
-- 4. Metodos OnEventX -- uno por cada evento registrado
--    (MOOSE llama automaticamente a estos metodos cuando EVT_Dispatcher:HandleEvent
--     fue invocado para ese EVENTS.X)
--------------------------------------------------------------------------------

function EVT_Dispatcher:OnEventBirth(EventData)
    self:_Dispatch(EVENTS.Birth, EventData)
end

function EVT_Dispatcher:OnEventDead(EventData)
    self:_Dispatch(EVENTS.Dead, EventData)
end

function EVT_Dispatcher:OnEventCrash(EventData)
    self:_Dispatch(EVENTS.Crash, EventData)
end

function EVT_Dispatcher:OnEventLand(EventData)
    self:_Dispatch(EVENTS.Land, EventData)
end

function EVT_Dispatcher:OnEventTakeoff(EventData)
    self:_Dispatch(EVENTS.Takeoff, EventData)
end

function EVT_Dispatcher:OnEventEjection(EventData)
    self:_Dispatch(EVENTS.Ejection, EventData)
end

function EVT_Dispatcher:OnEventLandingAfterEjection(EventData)
    self:_Dispatch(EVENTS.LandingAfterEjection, EventData)
end

function EVT_Dispatcher:OnEventPilotDead(EventData)
    self:_Dispatch(EVENTS.PilotDead, EventData)
end

function EVT_Dispatcher:OnEventBaseCaptured(EventData)
    self:_Dispatch(EVENTS.BaseCaptured, EventData)
end

function EVT_Dispatcher:OnEventPlayerEnterUnit(EventData)
    self:_Dispatch(EVENTS.PlayerEnterUnit, EventData)
end

function EVT_Dispatcher:OnEventPlayerLeaveUnit(EventData)
    self:_Dispatch(EVENTS.PlayerLeaveUnit, EventData)
end

function EVT_Dispatcher:OnEventHit(EventData)
    self:_Dispatch(EVENTS.Hit, EventData)
end

function EVT_Dispatcher:OnEventShot(EventData)
    self:_Dispatch(EVENTS.Shot, EventData)
end

--------------------------------------------------------------------------------
-- 5. Activacion de la escucha sobre todos los eventos registrados
--------------------------------------------------------------------------------

for _, eventId in ipairs(EVT_Dispatcher.RegisteredEvents) do
    EVT_Dispatcher:HandleEvent(eventId)
end

--------------------------------------------------------------------------------
-- 6. Confirmacion de arranque en dcs.log
--------------------------------------------------------------------------------

env.info("================================================================")
env.info("EVT_Dispatcher :: INICIADO correctamente.")
env.info("EVT_Dispatcher :: Eventos escuchados: " .. tostring(#EVT_Dispatcher.RegisteredEvents))
env.info("================================================================")
