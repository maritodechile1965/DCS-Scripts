--[[
====================================================================
 STATUS_Manager.lua  v1
 Menu Intel / Status de la campana dinamica.

 Genera el menu global "Intel / Status" visible para toda la
 coalicion azul. Muestra informacion tactica en tiempo real:
   - Control Aereo (AWACS LORD)
   - Estado de bases y combustible
   - Puntos de coalicion Blue
   - Estadisticas del piloto
   - Mision activa del piloto

 Las estadisticas personales (piloto) se muestran en un menu
 por grupo, para que cada piloto vea sus propios datos.

 Dependencias:
   Moose.lua -> EVT_Dispatcher.lua -> DATA_Core.lua ->
   WH_Manager.lua -> MIS_Manager.lua -> STATUS_Manager.lua

 Version: v1 - 10/07/2026
====================================================================
]]

STATUS_Manager = {}

-- Menu raiz global
STATUS_Manager._menuRoot = nil

-- Menus por grupo (para estadisticas personales)
STATUS_Manager._groupMenus = {}

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------

local function _msgBlue(text, seconds)
  trigger.action.outTextForCoalition(
    coalition.side.BLUE, text, seconds or 20
  )
end

local function _msgGroup(groupId, text, seconds)
  trigger.action.outTextForGroup(groupId, text, seconds or 20)
end

local function _clock()
  local ok, t = pcall(timer.getAbsTime)
  if not ok or not t then return "??:??" end
  local s = math.floor(t) % 86400
  return string.format("%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60))
end

local function _elapsed(startTime)
  local secs = math.floor(timer.getTime() - startTime)
  local m = math.floor(secs / 60)
  local s = secs % 60
  return string.format("%02d:%02d", m, s)
end

--------------------------------------------------------------------
-- CONTROL AEREO (AWACS LORD)
--------------------------------------------------------------------

function STATUS_Manager.ShowAWACSStatus()
  local lordMission = nil
  for _, m in ipairs(MISSIONS_Config) do
    if m.type == "AWACS" and m.active then
      lordMission = m; break
    end
  end

  if not lordMission then
    _msgBlue("Control Aereo: Sin AWACS configurado.", 15)
    return
  end

  local activeEntry = MIS_Manager._active[lordMission.id]

  if activeEntry then
    -- LORD esta activo
    local elapsed = _elapsed(activeEntry.spawned)
    _msgBlue(string.format(
      "================================\n" ..
      "  CONTROL AEREO - LORD ACTIVO\n" ..
      "================================\n" ..
      "  Aeronave : E-2D Hawkeye\n" ..
      "  Estado   : EN VUELO\n" ..
      "  Tiempo   : %s en aire\n" ..
      "  Altitud  : FL%d\n" ..
      "  Frecuencia: %.1f %s\n" ..
      "  RTB       : automatico por fuel\n" ..
      "================================",
      elapsed,
      lordMission.orbitFL,
      lordMission.frequency,
      lordMission.modulation
    ), 25)
  else
    -- LORD no esta activo
    _msgBlue(string.format(
      "================================\n" ..
      "  CONTROL AEREO\n" ..
      "================================\n" ..
      "  LORD : NO ACTIVO\n" ..
      "  Usa el menu Intel/Status\n" ..
      "  para solicitar el AWACS.\n" ..
      "================================"
    ), 20)
  end
end

function STATUS_Manager.ActivateLORD()
  local lordMission = nil
  for _, m in ipairs(MISSIONS_Config) do
    if m.type == "AWACS" and m.active then
      lordMission = m; break
    end
  end

  if not lordMission then
    _msgBlue("AWACS no configurado.", 10)
    return
  end

  if MIS_Manager._active[lordMission.id] then
    STATUS_Manager.ShowAWACSStatus()
    return
  end

  MIS_Manager.Activate(lordMission.id, "STATUS_MGR", nil)
end

--------------------------------------------------------------------
-- PUNTOS DE COALICION
--------------------------------------------------------------------

function STATUS_Manager.ShowCoalitionPoints()
  local pts = 0
  if DATA_Core and DATA_Core.GetCoalitionPoints then
    pts = DATA_Core.GetCoalitionPoints("blue") or 0
  end

  _msgBlue(string.format(
    "================================\n" ..
    "  COALICION BLUE - PUNTOS\n" ..
    "================================\n" ..
    "  Puntos disponibles: %d pts\n" ..
    "  Hora local DCS    : %s\n" ..
    "================================",
    pts, _clock()
  ), 20)
end

--------------------------------------------------------------------
-- ESTADISTICAS DEL PILOTO (por grupo)
--------------------------------------------------------------------

local function _showPilotStats(pilotId, groupId)
  local stats = nil
  if DATA_Core and DATA_Core.GetPilot then
    stats = DATA_Core.GetPilot(pilotId)
  end

  if not stats then
    _msgGroup(groupId, string.format(
      "================================\n" ..
      "  MIS ESTADISTICAS\n" ..
      "================================\n" ..
      "  Piloto : %s\n" ..
      "  Sin datos registrados aun.\n" ..
      "================================",
      tostring(pilotId)
    ), 20)
    return
  end

  _msgGroup(groupId, string.format(
    "================================\n" ..
    "  MIS ESTADISTICAS\n" ..
    "================================\n" ..
    "  Piloto   : %s\n" ..
    "  Aeronave : %s\n" ..
    "  Puntos   : %d pts\n" ..
    "  Kills AA : %d\n" ..
    "  Kills AG : %d\n" ..
    "  Misiones : %d\n" ..
    "================================",
    tostring(pilotId),
    tostring(stats.aircraftType or "?"),
    stats.points        or 0,
    stats.killsAA       or 0,
    stats.killsAG       or 0,
    stats.missionsToday or 0
  ), 25)
end

--------------------------------------------------------------------
-- MISION ACTIVA DEL PILOTO
--------------------------------------------------------------------

local function _showActiveMission(pilotId, groupId)
  -- Por ahora muestra todas las misiones activas globales
  -- En el futuro se filtrara por piloto cuando MIS_Manager
  -- registre que piloto activo cada mision
  local lines = {
    "================================",
    "  MISIONES ACTIVAS",
    "================================",
  }

  local count = 0
  for id, entry in pairs(MIS_Manager._active) do
    count = count + 1
    local elapsed = _elapsed(entry.spawned)
    table.insert(lines, string.format(
      "  [%s] %s\n  Tiempo: %s",
      entry.mission.type,
      entry.mission.name,
      elapsed
    ))
  end

  if count == 0 then
    table.insert(lines, "  Sin misiones activas ahora.")
  end

  table.insert(lines, "================================")
  _msgGroup(groupId, table.concat(lines, "\n"), 25)
end

--------------------------------------------------------------------
-- CONSTRUCCION DEL MENU POR GRUPO (estadisticas personales)
--------------------------------------------------------------------

local function _buildGroupMenu(groupName, groupId, pilotId)
  -- Limpiar menu anterior
  if STATUS_Manager._groupMenus[groupName] then
    pcall(function()
      missionCommands.removeItemForGroup(
        groupId, STATUS_Manager._groupMenus[groupName]
      )
    end)
  end

  local root = missionCommands.addSubMenuForGroup(
    groupId, "Mis datos", STATUS_Manager._menuRoot
  )
  STATUS_Manager._groupMenus[groupName] = root

  local pId = pilotId
  local gId = groupId

  missionCommands.addCommandForGroup(
    groupId, "Mis puntos y estadisticas", root,
    function() _showPilotStats(pId, gId) end
  )

  missionCommands.addCommandForGroup(
    groupId, "Mi mision activa", root,
    function() _showActiveMission(pId, gId) end
  )
end

--------------------------------------------------------------------
-- HANDLER PlayerEnterUnit
--------------------------------------------------------------------

local function _onPlayerEnterUnit(EventData)
  if not EventData or not EventData.IniUnit then return end

  local ok1, grp = pcall(function()
    return EventData.IniUnit:GetGroup()
  end)
  if not ok1 or not grp then return end

  local ok2, groupId   = pcall(function() return grp:GetID() end)
  local ok3, groupName = pcall(function() return grp:GetName() end)
  if not ok2 or not ok3 then return end

  local pilotId = EventData.IniPlayerName or groupName

  _buildGroupMenu(groupName, groupId, pilotId)
end

--------------------------------------------------------------------
-- MENU GLOBAL "Intel / Status"
--------------------------------------------------------------------

local function _buildGlobalMenu()
  STATUS_Manager._menuRoot = missionCommands.addSubMenu(
    "Intel / Status", nil
  )

  -- Control Aereo (LORD) - con opciones segun estado
  local awacsMenu = missionCommands.addSubMenu(
    "Control Aereo", STATUS_Manager._menuRoot
  )
  missionCommands.addCommandForCoalition(
    coalition.side.BLUE,
    "Ver estado del LORD",
    awacsMenu,
    STATUS_Manager.ShowAWACSStatus
  )
  missionCommands.addCommandForCoalition(
    coalition.side.BLUE,
    "Solicitar LORD (AWACS E-2D)",
    awacsMenu,
    STATUS_Manager.ActivateLORD
  )

  -- Estado de bases y combustible
  if WH_Manager then
    local basesMenu = missionCommands.addSubMenu(
      "Estado de Bases", STATUS_Manager._menuRoot
    )
    missionCommands.addCommandForCoalition(
      coalition.side.BLUE,
      "Combustible todas las bases",
      basesMenu,
      WH_Manager.ShowAllStock
    )
    missionCommands.addCommandForCoalition(
      coalition.side.BLUE,
      "Bases disponibles con fuel",
      basesMenu,
      WH_Manager.ShowAvailableBases
    )
    missionCommands.addCommandForCoalition(
      coalition.side.BLUE,
      "Transportes en vuelo",
      basesMenu,
      WH_Manager.ShowActiveTransports
    )
  end

  -- Puntos de coalicion
  missionCommands.addCommandForCoalition(
    coalition.side.BLUE,
    "Puntos de coalicion Blue",
    STATUS_Manager._menuRoot,
    STATUS_Manager.ShowCoalitionPoints
  )

  -- "Mis datos" se agrega por grupo al hacer PlayerEnterUnit
  -- (ver _buildGroupMenu)

  env.info("STATUS_Manager :: Menu 'Intel / Status' construido.")
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------

if EVT_Dispatcher and EVT_Dispatcher.Subscribe then
  EVT_Dispatcher:Subscribe(
    EVENTS.PlayerEnterUnit, _onPlayerEnterUnit, "STATUS_Manager"
  )
end

_buildGlobalMenu()

env.info("STATUS_Manager :: INICIADO correctamente.")
