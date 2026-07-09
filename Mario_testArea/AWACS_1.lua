-- ============================================================
-- HYDRA 2026 - AWACS REQUEST SYSTEM
-- Zeus / Marte
-- Version 1.1 TEST
-- Requiere MOOSE cargado antes
-- ============================================================

HYDRA_AWACS = {}

HYDRA_AWACS.BluePoints = 10000
HYDRA_AWACS.ActiveAWACS = {}

HYDRA_AWACS.Options = {
  E3 = {
    menuName = "Solicitar AWACS E-3A Lord - 300 pts",
    template = "BLUE_AWACS_E3",
    cost = 300,
    duration = 2 * 60 * 60,
    frequency = 130.0,
    name = "Lord"
  },

  E2 = {
    menuName = "Solicitar AWACS E-2D Wizard - 200 pts",
    template = "BLUE_AWACS_E2D",
    cost = 200,
    duration = 2 * 60 * 60,
    frequency = 131.1,
    name = "Wizard"
  }
}

function HYDRA_AWACS.Msg(txt, time)
  MESSAGE:New(txt, time or 10):ToBlue()
end

function HYDRA_AWACS.ShowPoints()
  HYDRA_AWACS.Msg("Puntos BLUE disponibles: " .. HYDRA_AWACS.BluePoints, 10)
end

function HYDRA_AWACS.AddPoints(points, reason)
  HYDRA_AWACS.BluePoints = HYDRA_AWACS.BluePoints + points

  local sign = ""
  if points > 0 then sign = "+" end

  HYDRA_AWACS.Msg(
    "[PUNTOS BLUE] " .. sign .. points .. " | " .. reason ..
    "\nTotal BLUE: " .. HYDRA_AWACS.BluePoints,
    12
  )
end

function HYDRA_AWACS.IsActive(key)
  return HYDRA_AWACS.ActiveAWACS[key] ~= nil
end

function HYDRA_AWACS.Request(key)

  local opt = HYDRA_AWACS.Options[key]
  if not opt then return end

  if HYDRA_AWACS.IsActive(key) then
    HYDRA_AWACS.Msg("AWACS " .. opt.name .. " ya está activo.", 10)
    return
  end

  if HYDRA_AWACS.BluePoints < opt.cost then
    HYDRA_AWACS.Msg("No hay puntos suficientes para solicitar AWACS " .. opt.name, 10)
    return
  end

  HYDRA_AWACS.AddPoints(-opt.cost, "Solicitud AWACS " .. opt.name)

  local spawner = SPAWN:New(opt.template):InitLimit(1, 0)
  local spawnedGroup = spawner:Spawn()

  if not spawnedGroup then
    HYDRA_AWACS.AddPoints(opt.cost, "Error spawn AWACS " .. opt.name .. " - puntos devueltos")
    return
  end

  HYDRA_AWACS.ActiveAWACS[key] = {
    group = spawnedGroup,
    option = opt,
    alive = true
  }

  HYDRA_AWACS.Msg(
    "AWACS " .. opt.name .. " solicitado.\n" ..
    "Frecuencia: " .. opt.frequency .. " MHz\n" ..
    "Tiempo de operación: 2 horas.",
    15
  )

  SCHEDULER:New(nil, function()
    HYDRA_AWACS.RTB(key)
  end, {}, opt.duration)
end

function HYDRA_AWACS.RTB(key)

  local data = HYDRA_AWACS.ActiveAWACS[key]
  if not data then return end

  local group = data.group
  local opt = data.option

  if not group or not group:IsAlive() then return end

  HYDRA_AWACS.Msg("AWACS " .. opt.name .. " completa 2 horas de operación. RTB.", 15)

  HYDRA_AWACS.AddPoints(50, "AWACS " .. opt.name .. " volvió exitosamente")

  group:Destroy()

  HYDRA_AWACS.ActiveAWACS[key] = nil
end

function HYDRA_AWACS.Killed(key)

  local data = HYDRA_AWACS.ActiveAWACS[key]
  if not data then return end

  local opt = data.option

  HYDRA_AWACS.AddPoints(-100, "AWACS " .. opt.name .. " derribado")

  trigger.action.outText(
    "AWACS " .. opt.name .. " fue derribado.\nBLUE -100 puntos.\nRED +300 puntos.",
    15
  )

  HYDRA_AWACS.ActiveAWACS[key] = nil
end

-- ============================================================
-- EVENTOS DEAD / CRASH
-- ============================================================

HYDRA_AWACS.EventHandler = EVENTHANDLER:New()
HYDRA_AWACS.EventHandler:HandleEvent(EVENTS.Dead)
HYDRA_AWACS.EventHandler:HandleEvent(EVENTS.Crash)

function HYDRA_AWACS.EventHandler:OnEventDead(EventData)
  HYDRA_AWACS.CheckKilled(EventData)
end

function HYDRA_AWACS.EventHandler:OnEventCrash(EventData)
  HYDRA_AWACS.CheckKilled(EventData)
end

function HYDRA_AWACS.CheckKilled(EventData)

  if not EventData then return end
  if not EventData.IniGroup then return end

  local killedGroupName = EventData.IniGroup:GetName()

  for key, data in pairs(HYDRA_AWACS.ActiveAWACS) do
    if data.group and data.group:GetName() == killedGroupName then
      HYDRA_AWACS.Killed(key)
      return
    end
  end
end

-- ============================================================
-- MENÚ F10
-- ============================================================

HYDRA_AWACS.MenuRoot = MENU_COALITION:New(coalition.side.BLUE, "AWACS")

MENU_COALITION_COMMAND:New(
  coalition.side.BLUE,
  HYDRA_AWACS.Options.E3.menuName,
  HYDRA_AWACS.MenuRoot,
  function()
    HYDRA_AWACS.Request("E3")
  end
)

MENU_COALITION_COMMAND:New(
  coalition.side.BLUE,
  HYDRA_AWACS.Options.E2.menuName,
  HYDRA_AWACS.MenuRoot,
  function()
    HYDRA_AWACS.Request("E2")
  end
)

MENU_COALITION_COMMAND:New(
  coalition.side.BLUE,
  "Consultar puntos BLUE",
  HYDRA_AWACS.MenuRoot,
  function()
    HYDRA_AWACS.ShowPoints()
  end
)

HYDRA_AWACS.Msg("HYDRA AWACS cargado. Puntos iniciales BLUE: 10000", 15)