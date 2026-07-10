--[[
====================================================================
 MIS_Manager.lua  v2
 Motor de misiones de la campana dinamica.

 Lee MISSIONS_Config.lua y genera menus F10 filtrados por plataforma.
 Cada piloto ve SOLO las misiones compatibles con su aeronave.

 Estructura de menus:
   F10
   Misiones                        (por grupo - filtrado por plataforma)
     Siempre disponibles
       [subtipo segun plataforma]
         Nombre mision
     Campana activa
       [zona]
         Nombre mision

 Las misiones tipo "intel" van al menu de STATUS_Manager.

 Dependencias:
   Moose.lua -> EVT_Dispatcher.lua -> DATA_Core.lua ->
   MISSIONS_Config.lua -> MIS_Manager.lua

 REGLA: NO modificar para agregar misiones. Solo editar MISSIONS_Config.lua.
 Version: v2 - 10/07/2026
====================================================================
]]

MIS_Manager = {}

--------------------------------------------------------------------
-- PLATAFORMAS
-- Mapeo de tipo DCS (aircraftType) a categoria de plataforma
--------------------------------------------------------------------

MIS_Manager.PLATFORM_GROUPS = {
  fighter   = {
    "F-16C_50", "FA-18C_hornet", "F-15C", "F-15ESE",
    "F-14A", "F-14A-95-GR", "F-14B",
    "AV8BNA", "A-10C", "A-10C_2",
  },
  heli      = {
    "AH-64D_BLK_II", "CH-47Fbl1", "OH58D",
    "UH-1H", "UH-60L", "MH-6M", "AH-6M",
  },
  transport = {
    "Hercules", "C-130", "C_130",
    "C-130J", "C-130J-30", "KC-130", "LC-130",
    "Il-76MD", "An-26B", "An-30M",
  },
}

-- Etiqueta visible por plataforma
MIS_Manager.PLATFORM_LABEL = {
  fighter   = "Caza / Multirrol",
  heli      = "Helicoptero",
  transport = "Transporte",
  all       = "General",
}

--------------------------------------------------------------------
-- ESTADO INTERNO
--------------------------------------------------------------------

-- Misiones activas: { [id] = { mission, lord/group, spawned } }
MIS_Manager._active = {}

-- Menus por grupo para poder limpiarlos al rebuild
-- { [groupName] = rootMenuPath }
MIS_Manager._groupMenus = {}

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------

local function _msgBlue(text, seconds)
  trigger.action.outTextForCoalition(
    coalition.side.BLUE, text, seconds or 20
  )
end

local function _msgGroup(groupName, text, seconds)
  local ok, grp = pcall(function() return GROUP:FindByName(groupName) end)
  if ok and grp then
    trigger.action.outTextForGroup(grp:GetID(), text, seconds or 20)
  else
    _msgBlue(text, seconds)
  end
end

local function _getModulation(str)
  if str == "FM" then return radio.modulation.FM end
  return radio.modulation.AM
end

--------------------------------------------------------------------
-- DETECCION DE PLATAFORMA
--------------------------------------------------------------------

function MIS_Manager.DetectPlatform(aircraftType)
  if not aircraftType then return "unknown" end
  for platform, types in pairs(MIS_Manager.PLATFORM_GROUPS) do
    for _, t in ipairs(types) do
      if t == aircraftType then return platform end
    end
  end
  return "unknown"
end

-- Verifica si una mision es compatible con una plataforma
local function _isCompatible(mission, platform)
  if not mission.platforms then return false end
  for _, p in ipairs(mission.platforms) do
    if p == "all" or p == platform then return true end
  end
  return false
end

--------------------------------------------------------------------
-- HANDLER AWACS (via RECOVERYTANKER de MOOSE)
--------------------------------------------------------------------

local function _handleAWACS(mission, pilotId, groupName)
  if MIS_Manager._active[mission.id] then
    _msgGroup(groupName, mission.name .. " ya esta activo en el area.", 15)
    return
  end

  if mission.cost and mission.cost > 0 then
    local pts = DATA_Core and DATA_Core.GetCoalitionPoints and
                DATA_Core.GetCoalitionPoints("blue") or 0
    if pts < mission.cost then
      _msgGroup(groupName, string.format(
        "Puntos insuficientes.\nNecesitas %d pts. Tienes %d pts.",
        mission.cost, pts
      ), 15)
      return
    end
    DATA_Core.AddCoalitionPoints("blue", -mission.cost)
  end

  local ok, lord = pcall(function()
    return RECOVERYTANKER:New(mission.spawnBase, mission.template)
  end)
  if not ok or not lord then
    _msgGroup(groupName, "ERROR: No se pudo crear " .. mission.name, 15)
    return
  end

  pcall(function() lord:SetAWACS() end)
  pcall(function() lord:SetRadio(mission.frequency, mission.modulation) end)
  pcall(function() lord:SetAltitude(mission.orbitFL * 100 * 0.3048) end)
  pcall(function() lord:SetTakeoffCold() end)
  pcall(function() lord:__Start(5) end)

  MIS_Manager._active[mission.id] = {
    mission = mission,
    lord    = lord,
    spawned = timer.getTime(),
  }

  env.info("MIS_Manager :: " .. mission.id .. " LORD AWACS iniciado.")

  _msgBlue(string.format(
    "%s ACTIVADO\nDespegando del CVN-73.\nFrecuencia: %.1f %s | FL%d\nRTB automatico por combustible.",
    mission.name, mission.frequency, mission.modulation, mission.orbitFL
  ), 25)
end

--------------------------------------------------------------------
-- TABLA DE HANDLERS POR TIPO
--------------------------------------------------------------------

local function _handleTEST(mission, pilotId, groupName)
  local ok, grp = pcall(function()
    return GROUP:FindByName(groupName)
  end)
  local gId = ok and grp and grp:GetID() or nil
  local msg = string.format(
    "================================\n" ..
    "  MISION DE PRUEBA\n" ..
    "================================\n" ..
    "  ID      : %s\n" ..
    "  Nombre  : %s\n" ..
    "  Piloto  : %s\n" ..
    "  Plat.   : %s\n" ..
    "================================\n" ..
    "  [TEST] Sistema de menus OK",
    mission.id,
    mission.name,
    tostring(pilotId),
    table.concat(mission.platforms or {}, "/")
  )
  if gId then
    trigger.action.outTextForGroup(gId, msg, 20)
  else
    trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 20)
  end
  env.info("MIS_Manager :: TEST: " .. mission.id .. " activada por " .. tostring(pilotId))
end

MIS_Manager.HANDLERS = {
  ["AWACS"]  = _handleAWACS,
  ["TEST"]   = _handleTEST,
  -- ["CAP"]   = _handleCAP,
  -- ["SEAD"]  = _handleSEAD,
}

--------------------------------------------------------------------
-- ACTIVAR MISION
--------------------------------------------------------------------

function MIS_Manager.Activate(missionId, pilotId, groupName)
  local mission = nil
  for _, m in ipairs(MISSIONS_Config) do
    if m.id == missionId then mission = m; break end
  end

  if not mission or not mission.active then
    _msgGroup(groupName, "Mision no disponible.", 10)
    return
  end

  local handler = MIS_Manager.HANDLERS[mission.type]
  if not handler then
    env.info("MIS_Manager :: Tipo sin handler: " .. tostring(mission.type))
    return
  end

  env.info("MIS_Manager :: Activando " .. missionId ..
    " | piloto: " .. tostring(pilotId))
  handler(mission, pilotId, groupName)
end

--------------------------------------------------------------------
-- CONSTRUCCION DEL MENU POR GRUPO (filtrado por plataforma)
--------------------------------------------------------------------

local function _buildGroupMenu(groupName, groupId, platform)
  -- Limpiar menu anterior si existe
  if MIS_Manager._groupMenus[groupName] then
    pcall(function()
      missionCommands.removeItemForGroup(
        groupId, MIS_Manager._groupMenus[groupName]
      )
    end)
  end

  -- Menu raiz para este grupo
  local root = missionCommands.addSubMenuForGroup(groupId, "Misiones")
  MIS_Manager._groupMenus[groupName] = root

  -- === SIEMPRE DISPONIBLES ===
  local alwaysMenu = missionCommands.addSubMenuForGroup(
    groupId, "Siempre disponibles", root
  )

  local countAlways = 0
  for _, m in ipairs(MISSIONS_Config) do
    if m.active and m.category == "always" and _isCompatible(m, platform) then
      local mid   = m.id
      local pId   = pilotId
      local gName = groupName
      missionCommands.addCommandForGroup(
        groupId,
        m.menuText,
        alwaysMenu,
        function() MIS_Manager.Activate(mid, pId, gName) end
      )
      countAlways = countAlways + 1
    end
  end

  if countAlways == 0 then
    missionCommands.addCommandForGroup(
      groupId, "Sin misiones disponibles", alwaysMenu, function() end
    )
  end

  -- === CAMPANA ACTIVA ===
  local campaignMenu = missionCommands.addSubMenuForGroup(
    groupId, "Campana activa", root
  )

  local countCampaign = 0
  for _, m in ipairs(MISSIONS_Config) do
    if m.active and m.category == "campaign" and _isCompatible(m, platform) then
      local mid   = m.id
      local pId   = pilotId
      local gName = groupName
      -- Agrupar por zona si tiene
      local label = m.menuText
      if m.zone then label = "[" .. m.zone .. "] " .. m.menuText end
      missionCommands.addCommandForGroup(
        groupId, label, campaignMenu,
        function() MIS_Manager.Activate(mid, pId, gName) end
      )
      countCampaign = countCampaign + 1
    end
  end

  if countCampaign == 0 then
    missionCommands.addCommandForGroup(
      groupId, "Sin misiones activas", campaignMenu, function() end
    )
  end

  env.info(string.format(
    "MIS_Manager :: Menu construido para %s [%s] | %d siempre | %d campana",
    groupName, platform, countAlways, countCampaign
  ))
end

--------------------------------------------------------------------
-- HANDLER PlayerEnterUnit - rebuild menu al entrar en avion
--------------------------------------------------------------------

local function _onPlayerEnterUnit(EventData)
  if not EventData or not EventData.IniUnit then return end

  local ok1, unitName = pcall(function()
    return EventData.IniUnit:GetName()
  end)
  local ok2, aircraftType = pcall(function()
    return EventData.IniUnit:GetTypeName()
  end)
  local ok3, grp = pcall(function()
    return EventData.IniUnit:GetGroup()
  end)

  if not ok1 or not ok2 or not ok3 or not grp then return end

  local ok4, groupId = pcall(function() return grp:GetID() end)
  local ok5, groupName = pcall(function() return grp:GetName() end)
  if not ok4 or not ok5 then return end

  local pilotId = EventData.IniPlayerName or unitName
  local platform = MIS_Manager.DetectPlatform(aircraftType)

  env.info(string.format(
    "MIS_Manager :: PlayerEnterUnit: %s | %s | plataforma: %s",
    tostring(pilotId), tostring(aircraftType), platform
  ))

  -- Construir menu solo si la plataforma es conocida
  if platform ~= "unknown" then
    _buildGroupMenu(groupName, groupId, platform)
  else
    env.info("MIS_Manager :: Plataforma no reconocida: [" .. tostring(aircraftType) .. "]")
    -- Mostrar tipo al piloto para facilitar el debug
    trigger.action.outTextForGroup(groupId,
      "MIS_Manager: Aeronave no reconocida: [" .. tostring(aircraftType) .. "]\n" ..
      "Informar al admin para agregar al sistema.",
    20)
  end
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------

if not MISSIONS_Config then
  env.error("MIS_Manager :: MISSIONS_Config no encontrado. " ..
    "Verificar orden de carga.")
else
  -- Suscribir a PlayerEnterUnit para construir menu al entrar
  if EVT_Dispatcher and EVT_Dispatcher.Subscribe then
    EVT_Dispatcher:Subscribe(EVENTS.PlayerEnterUnit, _onPlayerEnterUnit, "MIS_Manager")
  end

  local total  = #MISSIONS_Config
  local active = 0
  for _, m in ipairs(MISSIONS_Config) do
    if m.active then active = active + 1 end
  end

  env.info(string.format(
    "MIS_Manager :: INICIADO. %d misiones cargadas, %d activas.",
    total, active
  ))
end
