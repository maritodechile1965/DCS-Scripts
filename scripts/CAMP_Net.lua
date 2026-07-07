-- ============================================================
-- CAMP_Net.lua  (renombrado desde LogNet.lua)
-- Red de nodos de campaña con visualización F10 map.
-- Dibuja bases/puntos logísticos y conexiones en el mapa F10,
-- mostrando en tiempo real quién controla cada zona.
--
-- Integrado con DATA_Core para persistencia entre sesiones:
--   - Al cargar: lee el estado de bases desde DATA_Core
--     (que ya fue restaurado por DATA_Export.RestoreBaseStates)
--   - Al capturar: notifica a DATA_Core y ZONE_State
--
-- Autor original: Zeus / Marte
-- Integración DCS-Scripts: sesión 11 (02/07/2026)
-- ============================================================

CAMP_Net = {}

-- ============================================================
-- CONFIGURACION GENERAL
-- ============================================================

CAMP_Net.COALITION_BLUE = 2
CAMP_Net.VISIBLE_TO     = CAMP_Net.COALITION_BLUE
CAMP_Net.MARK_ID_BASE   = 930000
CAMP_Net.NEXT_ID        = CAMP_Net.MARK_ID_BASE
CAMP_Net.ALL_CAPTURED_FLAG   = 8199

CAMP_Net.COLORS = {
  GREEN  = {0, 1, 0, 0.90},
  YELLOW = {1, 1, 0, 0.90},
  BLUE   = {0, 0.35, 1, 0.95},
  RED    = {1, 0, 0, 0.90},
  GREY   = {0.45, 0.45, 0.45, 0.70},
  CLEAR  = {0, 0, 0, 0}
}

-- ============================================================
-- MAPEO: ID de nodo → nombre exacto de base en DATA_Core
-- Permite sincronizar el estado visual con la persistencia.
-- nil = nodo sin base DCS asociada (FARP, punto logístico, etc.)
-- ============================================================

CAMP_Net.NODE_TO_BASE = {
  -- Rojas capturables
  INCIR    = nil,                               -- Turquía, fuera del sistema
  GAZIAN   = nil,                               -- Turquía, fuera del sistema
  MINAK    = nil,                               -- FARP / punto logístico
  KUWEIRES = "Kuweires",
  JIRAH    = "Jirah",
  TABQA    = nil,
  ERZOR    = "Deir ez-Zor",
  ABU      = "Abu al-Duhur",
  BASSEL   = "Bassel Al-Assad International",
  HAMA     = nil,
  RENE     = nil,
  QUSAYR   = nil,
  SHAYRAT  = "Shayrat Air Base",
  TIYAS    = "Tiyas Air Base",
  PALMYRA  = nil,
  SAYQAL   = nil,
  NASIRI   = nil,
  RAYAK    = nil,
  DUMAYR   = nil,
  MEZZE    = "Mezzeh Air Base",
  MARJ     = nil,
  KALK     = nil,
  TALAH    = nil,
  -- Azules fijas
  PAPHOS   = "Paphos",
  AKRO     = "Akrotiri",
  LARNA    = "Larnaca",
  KINGS    = "Lakatamia",
  GECIT    = "Gecitkale",
  ERKAN    = "Ercan",
  CVN73    = "BLUE_CVN73_GROUP",
  RAMAT    = "Ramat David",
  SHEMER   = "Eyn Shemer",
  HERZI    = "Herzliya",
  TELNOF   = "Tel Nof",
  HATZOR   = "Hatzor",
  TEYMAN   = "Teyman",
  NEVATIM  = "Nevatim",
}

-- ============================================================
-- BLOQUE 1: NODOS
-- captureFlag ya NO es un flag de DCS (no se lee con getUserFlag): es
-- solo un ID numérico para clasificar el nodo. < 8200 = capturable por
-- presencia de unidades; >= 8200 = base azul fija, nunca reconquistable.
-- ============================================================

CAMP_Net.NODES = {

  INCIR = {
    zone = "LN_INCIR",
    label = "Incirlik",
    captureFlag = 8101,
    radius = 2000,
  },

  GAZIAN = {
    zone = "LN_GAZIAN",
    label = "Gaziantep",
    captureFlag = 8102,
    radius = 2000,
  },

  MINAK = {
    zone = "LN_MINAKH",
    label = "Minakh",
    captureFlag = 8103,
    radius = 2000,
  },

  KUWEIRES = {
    zone = "LN_KUWEIRES",
    label = "Kuweires",
    captureFlag = 8104,
    radius = 2000,
  },

  JIRAH = {
    zone = "LN_JIRAH",
    label = "Jirah",
    captureFlag = 8105,
    radius = 2000,
  },

  TABQA = {
    zone = "LN_TABQUA",
    label = "Tabqa",
    captureFlag = 8106,
    radius = 2000,
  },

  ERZOR = {
    zone = "LN_ERZOR",
    label = "Deir ez-Zor",
    captureFlag = 8107,
    radius = 2000,
  },

  ABU = {
    zone = "LN_ABUAL",
    label = "Abu al-Duhur",
    captureFlag = 8108,
    radius = 2000,
  },

  BASSEL = {
    zone = "LN_BASEL",
    label = "Bassel Al-Assad",
    captureFlag = 8109,
    radius = 2000,
  },

  HAMA = {
    zone = "LN_HAMA",
    label = "Hama",
    captureFlag = 8110,
    radius = 2000,
  },

  RENE = {
    zone = "LN_RENE",
    label = "Rene",
    captureFlag = 8111,
    radius = 2000,
  },

  QUSAYR = {
    zone = "LN_QUSAYR",
    label = "Al-Qusayr",
    captureFlag = 8112,
    radius = 2000,
  },

  SHAYRAT = {
    zone = "LN_SHAYRAT",
    label = "Shayrat",
    captureFlag = 8113,
    radius = 2000,
  },

  TIYAS = {
    zone = "LN_TIYAS",
    label = "Tiyas",
    captureFlag = 8114,
    radius = 2000,
  },

  PALMYRA = {
    zone = "LN_PALMYRA",
    label = "Palmyra",
    captureFlag = 8115,
    radius = 2000,
  },

  SAYQAL = {
    zone = "LN_SAYQAL",
    label = "Sayqal",
    captureFlag = 8116,
    radius = 2000,
  },

  NASIRI = {
    zone = "LN_NASIRI",
    label = "An Nasiriya",
    captureFlag = 8117,
    radius = 2000,
  },

  RAYAK = {
    zone = "LN_RAYAK",
    label = "Rayak",
    captureFlag = 8118,
    radius = 2000,
  },

  DUMAYR = {
    zone = "LN_DUMAYR",
    label = "Al-Dumayr",
    captureFlag = 8119,
    radius = 2000,
  },

  MEZZE = {
    zone = "LN_MEZZE",
    label = "Mezzeh",
    captureFlag = 8120,
    radius = 2000,
  },

  MARJ = {
    zone = "LN_MARJ",
    label = "Marj Ruhayyil",
    captureFlag = 8121,
    radius = 2000,
  },

  KALK = {
    zone = "LN_KALK",
    label = "Khalkhalah",
    captureFlag = 8122,
    radius = 2000,
  },

  TALAH = {
    zone = "LN_THALAH",
    label = "Tha'lah",
    captureFlag = 8123,
    radius = 2000,
  },

  -- ===== BLUE =====

  PAPHOS = {
    zone = "LN_PAPHOS",
    label = "Paphos",
    captureFlag = 8201,
    radius = 2000,
  },

  AKRO = {
    zone = "LN_AKRO",
    label = "Akrotiri",
    captureFlag = 8202,
    radius = 2000,
  },

  LARNA = {
    zone = "LN_LARNA",
    label = "Larnaca",
    captureFlag = 8203,
    radius = 2000,
  },

  KINGS = {
    zone = "LN_KINGS",
    label = "Lakatamia",
    captureFlag = 8204,
    radius = 2000,
  },

  GECIT = {
    zone = "LN_GECIT",
    label = "Gecitkale",
    captureFlag = 8205,
    radius = 2000,
  },

  ERKAN = {
    zone = "LN_ERKAN",
    label = "Ercan",
    captureFlag = 8206,
    radius = 2000,
  },

  CVN73 = {
    zone = "LN_CVN73",
    label = "CVN-73",
    captureFlag = 8207,
    radius = 2000,
  },

  RAMAT = {
    zone = "LN_RAMAT",
    label = "Ramat David",
    captureFlag = 8208,
    radius = 2000,
  },

  SHEMER = {
    zone = "LN_SHEMER",
    label = "Eyn Shemer",
    captureFlag = 8209,
    radius = 2000,
  },

  HERZI = {
    zone = "LN_HERZI",
    label = "Herzliya",
    captureFlag = 8210,
    radius = 2000,
  },

  TELNOF = {
    zone = "LN_TELNOF",
    label = "Tel Nof",
    captureFlag = 8211,
    radius = 2000,
  },

  HATZOR = {
    zone = "LN_HATZOR",
    label = "Hatzor",
    captureFlag = 8212,
    radius = 2000,
  },

  TEYMAN = {
    zone = "LN_TEYMAN",
    label = "Teyman",
    captureFlag = 8213,
    radius = 2000,
  },

  NEVATIM = {
    zone = "LN_NEVATIM",
    label = "Nevatim",
    captureFlag = 8214,
    radius = 2000,
  },
}

-- ============================================================
-- BLOQUE 2: CONEXIONES
-- ============================================================

CAMP_Net.EDGES = {
  { from = "INCIR",    to = "GAZIAN"  },
  { from = "INCIR",    to = "MINAK"   },
  { from = "GAZIAN",   to = "JIRAH"   },
  { from = "MINAK",    to = "KUWEIRES"},
  { from = "KUWEIRES", to = "JIRAH"   },
  { from = "JIRAH",    to = "TABQA"   },
  { from = "TABQA",    to = "ERZOR"   },
  { from = "ERZOR",    to = "PALMYRA" },
  { from = "PALMYRA",  to = "TABQA"   },
  { from = "KUWEIRES", to = "ABU"     },
  { from = "ABU",      to = "BASSEL"  },
  { from = "BASSEL",   to = "HAMA"    },
  { from = "ABU",      to = "HAMA"    },
  { from = "HAMA",     to = "RENE"    },
  { from = "HAMA",     to = "QUSAYR"  },
  { from = "RENE",     to = "QUSAYR"  },
  { from = "SHAYRAT",  to = "QUSAYR"  },
  { from = "SHAYRAT",  to = "TIYAS"   },
  { from = "PALMYRA",  to = "TIYAS"   },
  { from = "PALMYRA",  to = "SAYQAL"  },
  { from = "NASIRI",   to = "SAYQAL"  },
  { from = "NASIRI",   to = "SHAYRAT" },
  { from = "RAYAK",    to = "SHAYRAT" },
  { from = "NASIRI",   to = "DUMAYR"  },
  { from = "SAYQAL",   to = "DUMAYR"  },
  { from = "RAYAK",    to = "MEZZE"   },
  { from = "MARJ",     to = "MEZZE"   },
  { from = "MARJ",     to = "DUMAYR"  },
  { from = "MARJ",     to = "KALK"    },
  { from = "MARJ",     to = "TALAH"   },
  { from = "KALK",     to = "TALAH"   },
  -- Blue
  { from = "NEVATIM",  to = "TEYMAN"  },
  { from = "HATZOR",   to = "TEYMAN"  },
  { from = "NEVATIM",  to = "HATZOR"  },
  { from = "TELNOF",   to = "HATZOR"  },
  { from = "TELNOF",   to = "HERZI"   },
  { from = "TELNOF",   to = "RAMAT"   },
  { from = "SHEMER",   to = "HERZI"   },
  { from = "SHEMER",   to = "RAMAT"   },
  { from = "CVN73",    to = "RAMAT"   },
  { from = "CVN73",    to = "HATZOR"  },
  { from = "CVN73",    to = "PAPHOS"  },
  { from = "CVN73",    to = "AKRO"    },
  { from = "LARNA",    to = "AKRO"    },
  { from = "KINGS",    to = "GECIT"   },
  { from = "KINGS",    to = "ERKAN"   },
  { from = "LARNA",    to = "KINGS"   },
  -- Conexiones cruzadas (blanco en el original)
  { from = "LARNA",    to = "BASSEL"  },
  { from = "LARNA",    to = "RENE"    },
  { from = "LARNA",    to = "INCIR"   },
  { from = "CVN73",    to = "RENE"    },
  { from = "CVN73",    to = "MARJ"    },
  { from = "CVN73",    to = "TALAH"   },
  { from = "RAMAT",    to = "MARJ"    },
  { from = "RAMAT",    to = "TALAH"   },
}

-- ============================================================
-- MOTOR CAMP_Net (no modificar)
-- ============================================================

function CAMP_Net.NewId()
  CAMP_Net.NEXT_ID = CAMP_Net.NEXT_ID + 1
  return CAMP_Net.NEXT_ID
end

-- Inicializa IDs de dibujo y sincroniza estado desde DATA_Core.
-- captured=false solo si DATA_Core no tiene estado para ese nodo
-- (primera carga sin CSV previo). Si DATA_Core ya fue restaurado
-- desde CSV, usa su estado en vez del default false.
function CAMP_Net.InitIds()
  for nodeName, node in pairs(CAMP_Net.NODES) do
    node.circleId = CAMP_Net.NewId()
    node.markId   = CAMP_Net.NewId()

    -- Sincronizar con DATA_Core si está disponible
    local baseName = CAMP_Net.NODE_TO_BASE[nodeName]
    if baseName and DATA_Core then
      local coal = DATA_Core.GetBaseCoalition(baseName)
      node.captured = (coal == "blue")
    else
      -- Nodo sin base DCS o sin DATA_Core: usar false por defecto
      -- salvo que sea un nodo blue fijo (captureFlag >= 8200)
      local flag = node.captureFlag or 0
      node.captured = (flag >= 8200)
    end
  end

  for i, edge in ipairs(CAMP_Net.EDGES) do
    edge.lineId = CAMP_Net.NewId()
  end
end

function CAMP_Net.Msg(text, seconds)
  trigger.action.outTextForCoalition(
    CAMP_Net.VISIBLE_TO,
    text,
    seconds or 10
  )
end

function CAMP_Net.RemoveMark(id)
  if id then
    pcall(function()
      trigger.action.removeMark(id)
    end)
  end
end

function CAMP_Net.GetZonePoint(zoneName)
  local z = trigger.misc.getZone(zoneName)
  if not z then
    env.info("CAMP_Net :: Trigger Zone no encontrada: " .. zoneName)
    return nil
  end
  return { x = z.point.x, y = z.point.y or 0, z = z.point.z }
end

function CAMP_Net.GetNodeColor(node)
  if node.captured then return CAMP_Net.COLORS.BLUE end
  return CAMP_Net.COLORS.RED
end

function CAMP_Net.GetEdgeColor(edge)
  local nodeA = CAMP_Net.NODES[edge.from]
  local nodeB = CAMP_Net.NODES[edge.to]
  if not nodeA or not nodeB then return CAMP_Net.COLORS.GREY end
  if nodeA.captured and nodeB.captured then return CAMP_Net.COLORS.BLUE end
  if nodeA.captured or  nodeB.captured then return CAMP_Net.COLORS.YELLOW end
  return CAMP_Net.COLORS.GREEN
end

function CAMP_Net.DrawNode(nodeName)
  local node  = CAMP_Net.NODES[nodeName]
  if not node then return end
  local point = CAMP_Net.GetZonePoint(node.zone)
  if not point then return end

  -- Eliminar marcas anteriores
  CAMP_Net.RemoveMark(node.circleId)
  CAMP_Net.RemoveMark(node.markId)

  -- Asignar IDs nuevos para evitar conflicto DCS con IDs reutilizados
  node.circleId = CAMP_Net.NewId()
  node.markId   = CAMP_Net.NewId()

  local borderColor = CAMP_Net.GetNodeColor(node)
  local fillColor   = { borderColor[1], borderColor[2], borderColor[3], 0.25 }

  trigger.action.circleToAll(
    CAMP_Net.VISIBLE_TO, node.circleId, point,
    node.radius or 2000, borderColor, fillColor, 2, true, ""
  )

  local statusText = node.captured and "CAPTURADO" or "ENEMIGO"
  trigger.action.markToCoalition(
    node.markId,
    node.label .. " — " .. statusText,
    point, CAMP_Net.VISIBLE_TO, true, ""
  )
end

function CAMP_Net.DrawEdge(index)
  local edge  = CAMP_Net.EDGES[index]
  if not edge then return end
  local nodeA = CAMP_Net.NODES[edge.from]
  local nodeB = CAMP_Net.NODES[edge.to]
  if not nodeA or not nodeB then return end
  local pointA = CAMP_Net.GetZonePoint(nodeA.zone)
  local pointB = CAMP_Net.GetZonePoint(nodeB.zone)
  if not pointA or not pointB then return end

  -- Eliminar la línea anterior
  CAMP_Net.RemoveMark(edge.lineId)

  -- Asignar un ID nuevo para evitar el problema de DCS con IDs reutilizados
  -- (DCS no siempre procesa RemoveMark antes del siguiente draw con el mismo ID)
  edge.lineId = CAMP_Net.NewId()

  trigger.action.lineToAll(
    CAMP_Net.VISIBLE_TO, edge.lineId,
    pointA, pointB, CAMP_Net.GetEdgeColor(edge), 2, true, ""
  )
end

function CAMP_Net.DrawAll()
  for i, _ in ipairs(CAMP_Net.EDGES) do
    CAMP_Net.DrawEdge(i)
  end
  for nodeName, _ in pairs(CAMP_Net.NODES) do
    CAMP_Net.DrawNode(nodeName)
  end
end

-- Captura un nodo: rojo → azul
function CAMP_Net.CaptureNode(nodeName)
  local node = CAMP_Net.NODES[nodeName]
  if not node then return end
  if node.captured then
    CAMP_Net.Msg(node.label .. " ya está bajo control AZUL.", 10)
    return
  end

  node.captured = true
  CAMP_Net.Msg("✈ BASE CAPTURADA [AZUL]: " .. node.label, 20)
  env.info("CAMP_Net :: CaptureNode: " .. nodeName .. " → AZUL")

  -- Notificar a DATA_Core y ZONE_State para persistencia
  local baseName = CAMP_Net.NODE_TO_BASE[nodeName]
  if baseName then
    if ZONE_State and ZONE_State.CaptureBase then
      ZONE_State.CaptureBase(baseName, "blue")
    elseif DATA_Core and DATA_Core.SetBaseCoalition then
      DATA_Core.SetBaseCoalition(baseName, "blue")
    end
  end

  CAMP_Net.DrawAll()
  CAMP_Net.CheckAllCaptured()
end

-- Reconquista un nodo: azul → rojo
function CAMP_Net.ReleaseNode(nodeName)
  local node = CAMP_Net.NODES[nodeName]
  if not node then return end
  if not node.captured then
    CAMP_Net.Msg(node.label .. " ya está bajo control ROJO.", 10)
    return
  end

  -- Bases fijas azules (flag >= 8200) no se pueden reconquistar
  if node.captureFlag and node.captureFlag >= 8200 then
    env.info("CAMP_Net :: ReleaseNode: " .. nodeName .. " es base fija azul, ignorado.")
    return
  end

  node.captured = false
  CAMP_Net.Msg("⚠ BASE RECONQUISTADA [ROJO]: " .. node.label, 20)
  env.info("CAMP_Net :: ReleaseNode: " .. nodeName .. " → ROJO")

  -- Notificar a DATA_Core y ZONE_State para persistencia
  local baseName = CAMP_Net.NODE_TO_BASE[nodeName]
  if baseName then
    if ZONE_State and ZONE_State.CaptureBase then
      ZONE_State.CaptureBase(baseName, "red")
    elseif DATA_Core and DATA_Core.SetBaseCoalition then
      DATA_Core.SetBaseCoalition(baseName, "red")
    end
  end

  CAMP_Net.DrawAll()
end

-- Intervalo de chequeo de zonas en segundos
CAMP_Net.ZONE_CHECK_INTERVAL = 5

-- Tiempo mínimo de control antes de capturar (segundos)
CAMP_Net.CAPTURE_DELAY = 10

-- Tabla interna para trackear tiempo de control por zona
local _zoneControl = {}

-- Obtiene la posición de todas las unidades terrestres vivas de una
-- coalición de una sola vez (en vez de volver a llamar coalition.getGroups
-- por cada nodo), para no repetir el escaneo completo ~24 veces por ciclo.
local function _getGroundUnitPositions(coalitionSide)
  local positions = {}
  local groups = coalition.getGroups(coalitionSide, Group.Category.GROUND)
  for _, grp in ipairs(groups or {}) do
    if grp and grp:isExist() then
      for _, unit in ipairs(grp:getUnits() or {}) do
        if unit and unit:isExist() and unit:isActive() then
          positions[#positions + 1] = unit:getPoint()
        end
      end
    end
  end
  return positions
end

-- Cuenta cuántas posiciones caen dentro de un radio (distancia horizontal).
local function _countInRadius(positions, center, radius)
  local count = 0
  for _, upos in ipairs(positions) do
    local dx = upos.x - center.x
    local dz = upos.z - center.z
    if math.sqrt(dx*dx + dz*dz) <= radius then
      count = count + 1
    end
  end
  return count
end

local function _checkZoneControl()
  local now = timer.getTime()

  -- Un solo escaneo de unidades por bando por ciclo (no por nodo).
  local bluePositions = _getGroundUnitPositions(coalition.side.BLUE)
  local redPositions  = _getGroundUnitPositions(coalition.side.RED)

  for nodeName, node in pairs(CAMP_Net.NODES) do
    -- Solo procesar nodos capturables (flag < 8200 = no es base fija)
    if node.zone and node.captureFlag and node.captureFlag < 8200 then
      local zone = trigger.misc.getZone(node.zone)

      if zone then
        local radius    = node.radius or 2000
        local blueCount = _countInRadius(bluePositions, zone.point, radius)
        local redCount  = _countInRadius(redPositions, zone.point, radius)

        if not _zoneControl[nodeName] then
          _zoneControl[nodeName] = { side = nil, since = now }
        end
        local zc = _zoneControl[nodeName]
        local previousSide = zc.side

        if blueCount > 0 and redCount == 0 then
          -- Solo azules
          if zc.side ~= "blue" then
            zc.side  = "blue"
            zc.since = now
            env.info(string.format("CAMP_Net :: %s bajo control azul (timer iniciado)", nodeName))
          end
          local elapsed = now - zc.since
          if not node.captured and elapsed >= CAMP_Net.CAPTURE_DELAY then
            CAMP_Net.CaptureNode(nodeName)
          end

        elseif redCount > 0 and blueCount == 0 then
          -- Solo rojos
          if zc.side ~= "red" then
            zc.side  = "red"
            zc.since = now
            env.info(string.format("CAMP_Net :: %s bajo control rojo (timer iniciado)", nodeName))
          end
          local elapsed = now - zc.since
          if node.captured and elapsed >= CAMP_Net.CAPTURE_DELAY then
            CAMP_Net.ReleaseNode(nodeName)
          end

        elseif blueCount > 0 and redCount > 0 then
          -- Zona en disputa
          if zc.side ~= "contest" then
            zc.side  = "contest"
            zc.since = now
            env.info(string.format("CAMP_Net :: %s EN DISPUTA", nodeName))
          end
          -- Redibujar en amarillo
          pcall(function()
            local point = CAMP_Net.GetZonePoint(node.zone)
            if point and node.circleId then
              trigger.action.circleToAll(
                CAMP_Net.VISIBLE_TO, node.circleId, point,
                radius,
                CAMP_Net.COLORS.YELLOW,
                {1, 1, 0, 0.15}, 2, true, ""
              )
            end
          end)

        else
          -- Zona vacía: resetear timer
          if zc.side ~= nil then
            zc.side  = nil
            zc.since = now
          end
        end

        -- Si la zona deja de estar en disputa sin llegar a capturar/
        -- reconquistar (aún dentro del CAPTURE_DELAY), redibujar de
        -- inmediato para que el círculo no se quede amarillo "pegado".
        if previousSide == "contest" and zc.side ~= "contest" then
          CAMP_Net.DrawNode(nodeName)
        end
      end
    end
  end

  return now + CAMP_Net.ZONE_CHECK_INTERVAL
end

function CAMP_Net.CheckCaptureFlags()
  return _checkZoneControl()
end

function CAMP_Net.CheckAllCaptured()
  for nodeName, node in pairs(CAMP_Net.NODES) do
    if not node.captured then return false end
  end
  CAMP_Net.Msg(
    "RED COMPLETA CAPTURADA. Todas las bases bajo control BLUE.",
    25
  )
  if CAMP_Net.ALL_CAPTURED_FLAG then
    trigger.action.setUserFlag(CAMP_Net.ALL_CAPTURED_FLAG, 1)
  end
  return true
end

function CAMP_Net.Start()
  CAMP_Net.InitIds()

  timer.scheduleFunction(function()
    CAMP_Net.DrawAll()
    CAMP_Net.Msg("CAMP_Net iniciado. Red de campaña visible en F10.", 15)
    env.info("CAMP_Net :: Red dibujada en F10.")
    return nil
  end, {}, timer.getTime() + 3)

  timer.scheduleFunction(function()
    return CAMP_Net.CheckCaptureFlags()
  end, {}, timer.getTime() + 5)

  env.info("CAMP_Net :: INICIADO correctamente.")
end

CAMP_Net.Start()
