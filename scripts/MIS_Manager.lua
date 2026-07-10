--[[
====================================================================
 MIS_Manager.lua
 Motor de misiones de la campana dinamica.

 Lee MISSIONS_Config.lua y genera automaticamente:
   - Menus F10 para cada mision activa
   - Spawn de aeronaves/grupos al activar
   - Tareas de orbita, duracion y RTB
   - Registro de misiones activas

 REGLA FUNDAMENTAL:
   NO modificar este archivo para agregar misiones.
   Solo editar MISSIONS_Config.lua.

 Dependencias (orden de carga):
   Moose.lua -> EVT_Dispatcher.lua -> DATA_Core.lua ->
   PTS_Manager.lua -> DATA_Export.lua -> ZONE_State.lua ->
   CAMP_Net.lua -> WH_Manager.lua -> MISSIONS_Config.lua ->
   MIS_Manager.lua

 Version: v1
 Creado: 09/07/2026
====================================================================
]]

MIS_Manager = {}

--------------------------------------------------------------------
-- ESTADO INTERNO
--------------------------------------------------------------------

-- Misiones actualmente en vuelo: { [id] = { mission, group, fg, spawned } }
MIS_Manager._active = {}

-- Menu raiz F10
MIS_Manager._menuRoot = nil

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------

local function _msgBlue(text, seconds)
  trigger.action.outTextForCoalition(
    coalition.side.BLUE, text, seconds or 20
  )
end

local function _getCoalitionSide(str)
  if str == "red"  then return coalition.side.RED  end
  if str == "blue" then return coalition.side.BLUE end
  return coalition.side.NEUTRAL
end

local function _getTakeoffType(str)
  if str == "hot"  then return SPAWN.Takeoff.Hot  end
  if str == "air"  then return SPAWN.Takeoff.Air  end
  return SPAWN.Takeoff.Cold  -- default
end

local function _getModulation(str)
  if str == "FM" then return radio.modulation.FM end
  return radio.modulation.AM  -- default
end

-- Convierte FL a metros: FL270 -> 27000 ft -> metros
-- 1 pie = 0.3048 metros
local function _flToMeters(fl)
  return fl * 100 * 0.3048
end

--------------------------------------------------------------------
-- VERIFICACION DE CONDICIONES
--------------------------------------------------------------------

-- Evalua si una mision esta disponible segun sus condiciones.
-- nil = siempre disponible.
local function _checkConditions(mission)
  if not mission.conditions then return true end
  local c = mission.conditions

  -- Requisito de mision previa completada
  if c.requires then
    for _, req in ipairs(c.requires) do
      local state = DATA_Core and DATA_Core.GetMissionState and
                    DATA_Core.GetMissionState(req.mission)
      if state ~= req.status then return false end
    end
  end

  -- Ventana de tiempo (hora del mundo DCS)
  if c.timeWindow then
    local t = timer.getAbsTime() % 86400
    local hh = math.floor(t / 3600)
    local mm = math.floor((t % 3600) / 60)
    local now = hh * 100 + mm  -- ej. 1430 para las 14:30

    local function _toNum(str)
      local h, m = str:match("(%d+):(%d+)")
      return tonumber(h) * 100 + tonumber(m)
    end
    local startT = _toNum(c.timeWindow.start)
    local stopT  = _toNum(c.timeWindow.stop)
    if now < startT or now > stopT then return false end
  end

  return true
end

--------------------------------------------------------------------
-- HANDLERS POR TIPO DE MISION
--------------------------------------------------------------------

-- *** AWACS via RECOVERYTANKER de MOOSE ***
-- RECOVERYTANKER:SetAWACS() convierte el tanker en AWACS:
-- spawn en carrier, despegue, orbita overhead del carrier,
-- RTB automatico cuando fuel bajo, respawn y vuelta a orbita.
-- No requiere SRS, AIRWING ni SQUADRON.
local function _handleAWACS(mission)
  if MIS_Manager._active[mission.id] then
    _msgBlue(mission.name .. " ya esta activo en el area.", 15)
    return
  end

  -- Verificar puntos si tiene costo
  if mission.cost and mission.cost > 0 then
    local pts = DATA_Core and DATA_Core.GetCoalitionPoints and
                DATA_Core.GetCoalitionPoints("blue") or 0
    if pts < mission.cost then
      _msgBlue(string.format(
        "Puntos insuficientes para %s.\nNecesitas %d pts. Tienes %d pts.",
        mission.name, mission.cost, pts
      ), 15)
      return
    end
    DATA_Core.AddCoalitionPoints("blue", -mission.cost)
  end

  -- Crear RECOVERYTANKER con modo AWACS
  -- spawnBase = nombre del grupo del carrier (ej. "BLUE_CVN73_GROUP")
  -- template  = nombre del grupo late-activated en el ME
  local ok, lord = pcall(function()
    return RECOVERYTANKER:New(mission.spawnBase, mission.template)
  end)
  if not ok or not lord then
    _msgBlue("ERROR: No se pudo crear " .. mission.name ..
      ". Verificar template y carrier en el ME.", 15)
    if mission.cost and mission.cost > 0 then
      DATA_Core.AddCoalitionPoints("blue", mission.cost)
    end
    return
  end

  -- Configurar como AWACS
  pcall(function() lord:SetAWACS() end)

  -- Radio: RECOVERYTANKER espera modulacion como string "AM" o "FM"
  pcall(function()
    lord:SetRadio(mission.frequency, mission.modulation)
  end)

  -- Altitud de orbita (FL -> metros)
  pcall(function()
    lord:SetAltitude(mission.orbitFL * 100 * 0.3048)
  end)

  -- Cold and dark en cubierta
  pcall(function() lord:SetTakeoffCold() end)

  -- Iniciar en 5 segundos
  pcall(function() lord:__Start(5) end)

  -- Registrar como activa
  MIS_Manager._active[mission.id] = {
    mission = mission,
    lord    = lord,
    spawned = timer.getTime(),
  }

  env.info("MIS_Manager :: " .. mission.id .. " LORD AWACS iniciado via RECOVERYTANKER.")

  _msgBlue(string.format(
    "%s ACTIVADO\nDespegando del CVN-73 hacia orbita.\nFrecuencia: %.1f %s | FL%d\nRTB automatico por nivel de combustible.",
    mission.name,
    mission.frequency,
    mission.modulation,
    mission.orbitFL
  ), 25)
end

-- *** TABLA DE HANDLERS POR TIPO ***
-- Para agregar un nuevo tipo de mision, agregar el handler aqui.
MIS_Manager.HANDLERS = {
  ["AWACS"]  = _handleAWACS,
  -- ["CAP"]   = _handleCAP,   -- proxima version
  -- ["SEAD"]  = _handleSEAD,  -- proxima version
  -- ["STRIKE"]= _handleSTRIKE,-- proxima version
}

--------------------------------------------------------------------
-- ACTIVAR UNA MISION
--------------------------------------------------------------------

function MIS_Manager.Activate(missionId)
  -- Buscar la mision en el config
  local mission = nil
  for _, m in ipairs(MISSIONS_Config) do
    if m.id == missionId then
      mission = m
      break
    end
  end

  if not mission then
    env.info("MIS_Manager :: Mision no encontrada: " .. tostring(missionId))
    return
  end

  if not mission.active then
    _msgBlue("Mision " .. mission.name .. " no esta disponible.", 10)
    return
  end

  -- Verificar condiciones de disponibilidad
  if not _checkConditions(mission) then
    _msgBlue("Mision " .. mission.name .. " no esta disponible en este momento.", 15)
    return
  end

  -- Llamar al handler correspondiente
  local handler = MIS_Manager.HANDLERS[mission.type]
  if not handler then
    env.info("MIS_Manager :: Tipo de mision sin handler: " .. tostring(mission.type))
    _msgBlue("ERROR: Tipo de mision '" .. mission.type .. "' no soportado.", 10)
    return
  end

  env.info("MIS_Manager :: Activando mision: " .. missionId)
  handler(mission)
end

--------------------------------------------------------------------
-- MOSTRAR ESTADO DE MISIONES
--------------------------------------------------------------------

function MIS_Manager.ShowStatus()
  local lines = {
    "================================",
    "  ESTADO DE MISIONES",
    "================================",
  }

  local countActive = 0
  for id, entry in pairs(MIS_Manager._active) do
    countActive = countActive + 1
    local elapsed = math.floor((timer.getTime() - entry.spawned) / 60)
    table.insert(lines, string.format(
      "  [ACTIVA] %s (%d min)",
      entry.mission.name, elapsed
    ))
  end

  if countActive == 0 then
    table.insert(lines, "  Sin misiones activas.")
  end

  table.insert(lines, "--------------------------------")
  table.insert(lines, "  DISPONIBLES:")

  local countAvail = 0
  for _, m in ipairs(MISSIONS_Config) do
    if m.active and not MIS_Manager._active[m.id] and _checkConditions(m) then
      countAvail = countAvail + 1
      local costStr = m.cost and m.cost > 0 and
                      string.format(" [%d pts]", m.cost) or " [gratis]"
      table.insert(lines, string.format(
        "  %s%s", m.menuText, costStr
      ))
    end
  end

  if countAvail == 0 then
    table.insert(lines, "  Sin misiones disponibles ahora.")
  end

  table.insert(lines, "================================")
  _msgBlue(table.concat(lines, "\n"), 30)
end

--------------------------------------------------------------------
-- CONSTRUCCION DEL MENU F10
--------------------------------------------------------------------

local function _buildMenu()
  MIS_Manager._menuRoot = missionCommands.addSubMenu("Misiones", nil)

  -- Item de estado general
  missionCommands.addCommandForCoalition(
    coalition.side.BLUE,
    "Ver estado de misiones",
    MIS_Manager._menuRoot,
    MIS_Manager.ShowStatus
  )

  -- Submenus por tipo de mision
  local subMenus = {}

  for _, mission in ipairs(MISSIONS_Config) do
    if mission.active then
      -- Crear submenu del tipo si no existe
      if not subMenus[mission.type] then
        subMenus[mission.type] = missionCommands.addSubMenu(
          mission.type,
          MIS_Manager._menuRoot
        )
      end

      -- Agregar item de la mision
      local m = mission  -- closure
      local costStr = mission.cost and mission.cost > 0 and
                      string.format(" [%d pts]", mission.cost) or ""

      missionCommands.addCommandForCoalition(
        coalition.side.BLUE,
        mission.menuText .. costStr,
        subMenus[mission.type],
        function() MIS_Manager.Activate(m.id) end
      )

      env.info("MIS_Manager :: Menu agregado: " .. mission.id)
    end
  end

  env.info("MIS_Manager :: Menu F10 construido.")
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------

-- Verificar dependencias
if not MISSIONS_Config then
  env.error("MIS_Manager :: MISSIONS_Config no encontrado. " ..
    "Verificar que MISSIONS_Config.lua se cargo antes que MIS_Manager.lua.")
else
  -- Construir menu F10
  _buildMenu()

  -- Contar misiones disponibles
  local total  = #MISSIONS_Config
  local active = 0
  for _, m in ipairs(MISSIONS_Config) do
    if m.active then active = active + 1 end
  end

  env.info(string.format(
    "MIS_Manager :: INICIADO. %d misiones cargadas, %d activas en menu F10.",
    total, active
  ))
end
