-- ============================================================
-- LOGNET TEMPLATE v1.0
-- Red logistica dinamica por nodos y lineas F10
-- DCS Scripting Engine nativo
-- Autor: Zeus / Marte
-- ============================================================

LOGNET = {}

-- ============================================================
-- CONFIGURACION GENERAL
-- ============================================================

LOGNET.COALITION_BLUE = 2
LOGNET.VISIBLE_TO = LOGNET.COALITION_BLUE

-- ID base para dibujos F10.
-- Cambiar si tienes otros scripts usando marcas cercanas a este rango.
LOGNET.MARK_ID_BASE = 930000
LOGNET.NEXT_ID = LOGNET.MARK_ID_BASE

-- Cada cuantos segundos revisa flags de captura.
LOGNET.FLAG_CHECK_INTERVAL = 2

-- Flag que se activa cuando todos los nodos estan capturados.
-- Puedes cambiarla o dejarla en nil si no la quieres usar.
LOGNET.ALL_CAPTURED_FLAG = 8199

LOGNET.COLORS = {
  GREEN  = {0, 1, 0, 0.90},       -- Linea activa
  YELLOW = {1, 1, 0, 0.90},       -- Linea parcialmente capturada
  BLUE   = {0, 0.35, 1, 0.95},    -- Nodo/linea capturada
  RED    = {1, 0, 0, 0.90},       -- Nodo enemigo
  GREY   = {0.45, 0.45, 0.45, 0.70},
  CLEAR  = {0, 0, 0, 0}
}

-- ============================================================
-- BLOQUE 1: NODOS
-- AQUI RELLENAS TUS BASES / PUNTOS LOGISTICOS
-- ============================================================
--
-- Formato:
--
-- ID_DEL_NODO = {
--   zone = "NOMBRE_TRIGGER_ZONE_EN_EDITOR",
--   label = "Nombre que vera el jugador",
--   captureFlag = FLAG_QUE_CAPTURA_ESTE_NODO,
--   radius = RADIO_DEL_CIRCULO_EN_METROS,
-- }
--
-- IMPORTANTE:
-- La Trigger Zone debe existir en el Mission Editor.
-- El nombre de zone debe coincidir exactamente.
-- ============================================================

LOGNET.NODES = {

  BASSEL = {
    zone = "LN_BASSEL",
    label = "Bassel Al-Assad",
    captureFlag = 8101,
    radius = 6000,
  },

  ABU = {
    zone = "LN_ABU_DUHUR",
    label = "Abu al-Duhur",
    captureFlag = 8102,
    radius = 6000,
  },

  RENE = {
    zone = "LN_RENE",
    label = "Rene Mouawad",
    captureFlag = 8103,
    radius = 6000,
  },

  -- EJEMPLO PARA AGREGAR OTRO NODO:
  --
  -- HAMA = {
  --   zone = "LN_HAMA",
  --   label = "Hama",
  --   captureFlag = 8104,
  --   radius = 6000,
  -- },

}

-- ============================================================
-- BLOQUE 2: CONEXIONES
-- AQUI DEFINES LAS LINEAS ENTRE NODOS
-- ============================================================
--
-- Formato:
--
-- { from = "ID_NODO_A", to = "ID_NODO_B" },
--
-- Los IDs deben existir en LOGNET.NODES.
-- ============================================================

LOGNET.EDGES = {

  { from = "BASSEL", to = "ABU" },
  { from = "BASSEL", to = "RENE" },
  { from = "RENE", to = "ABU" },

  -- EJEMPLO PARA AGREGAR CONEXIONES:
  --
  -- { from = "HAMA", to = "BASSEL" },
  -- { from = "HAMA", to = "ABU" },

}

-- ============================================================
-- NO TOCAR DESDE AQUI HACIA ABAJO
-- MOTOR LOGNET
-- ============================================================

function LOGNET.NewId()
  LOGNET.NEXT_ID = LOGNET.NEXT_ID + 1
  return LOGNET.NEXT_ID
end

function LOGNET.InitIds()

  for nodeName, node in pairs(LOGNET.NODES) do
    node.captured = false
    node.circleId = LOGNET.NewId()
    node.markId = LOGNET.NewId()
  end

  for i, edge in ipairs(LOGNET.EDGES) do
    edge.lineId = LOGNET.NewId()
  end
end

function LOGNET.Msg(text, seconds)
  trigger.action.outTextForCoalition(
    LOGNET.VISIBLE_TO,
    text,
    seconds or 10
  )
end

function LOGNET.RemoveMark(id)
  if id then
    pcall(function()
      trigger.action.removeMark(id)
    end)
  end
end

function LOGNET.GetZonePoint(zoneName)

  local z = trigger.misc.getZone(zoneName)

  if not z then
    local msg = "LOGNET ERROR: No existe la Trigger Zone: " .. zoneName
    env.info(msg)
    trigger.action.outText(msg, 20)
    return nil
  end

  return {
    x = z.point.x,
    y = z.point.y or 0,
    z = z.point.z
  }
end

function LOGNET.GetNodeColor(node)

  if node.captured then
    return LOGNET.COLORS.BLUE
  end

  return LOGNET.COLORS.RED
end

function LOGNET.GetEdgeColor(edge)

  local nodeA = LOGNET.NODES[edge.from]
  local nodeB = LOGNET.NODES[edge.to]

  if not nodeA or not nodeB then
    return LOGNET.COLORS.GREY
  end

  if nodeA.captured and nodeB.captured then
    return LOGNET.COLORS.BLUE
  end

  if nodeA.captured or nodeB.captured then
    return LOGNET.COLORS.YELLOW
  end

  return LOGNET.COLORS.GREEN
end

function LOGNET.DrawNode(nodeName)

  local node = LOGNET.NODES[nodeName]

  if not node then
    return
  end

  local point = LOGNET.GetZonePoint(node.zone)

  if not point then
    return
  end

  LOGNET.RemoveMark(node.circleId)
  LOGNET.RemoveMark(node.markId)

  local borderColor = LOGNET.GetNodeColor(node)
  local fillColor = {
    borderColor[1],
    borderColor[2],
    borderColor[3],
    0.25
  }

  trigger.action.circleToAll(
    LOGNET.VISIBLE_TO,
    node.circleId,
    point,
    node.radius or 6000,
    borderColor,
    fillColor,
    2,
    true,
    ""
  )

  local statusText = "ENEMIGO"

  if node.captured then
    statusText = "CAPTURADO"
  end

  trigger.action.markToCoalition(
    node.markId,
    node.label .. " - " .. statusText,
    point,
    LOGNET.VISIBLE_TO,
    true,
    ""
  )
end

function LOGNET.DrawEdge(index)

  local edge = LOGNET.EDGES[index]

  if not edge then
    return
  end

  local nodeA = LOGNET.NODES[edge.from]
  local nodeB = LOGNET.NODES[edge.to]

  if not nodeA then
    trigger.action.outText("LOGNET ERROR: Nodo no existe: " .. edge.from, 20)
    return
  end

  if not nodeB then
    trigger.action.outText("LOGNET ERROR: Nodo no existe: " .. edge.to, 20)
    return
  end

  local pointA = LOGNET.GetZonePoint(nodeA.zone)
  local pointB = LOGNET.GetZonePoint(nodeB.zone)

  if not pointA or not pointB then
    return
  end

  LOGNET.RemoveMark(edge.lineId)

  trigger.action.lineToAll(
    LOGNET.VISIBLE_TO,
    edge.lineId,
    pointA,
    pointB,
    LOGNET.GetEdgeColor(edge),
    2,
    true,
    ""
  )
end

function LOGNET.DrawAll()

  for i, _ in ipairs(LOGNET.EDGES) do
    LOGNET.DrawEdge(i)
  end

  for nodeName, _ in pairs(LOGNET.NODES) do
    LOGNET.DrawNode(nodeName)
  end
end

function LOGNET.CaptureNode(nodeName)

  local node = LOGNET.NODES[nodeName]

  if not node then
    return
  end

  if node.captured then
    LOGNET.Msg(node.label .. " ya estaba capturado.", 10)
    return
  end

  node.captured = true

  LOGNET.Msg("BASE CAPTURADA: " .. node.label, 15)

  LOGNET.DrawAll()

  LOGNET.CheckAllCaptured()
end

function LOGNET.CheckCaptureFlags()

  for nodeName, node in pairs(LOGNET.NODES) do

    if node.captureFlag then

      if trigger.misc.getUserFlag(node.captureFlag) == 1 then

        trigger.action.setUserFlag(node.captureFlag, 0)

        LOGNET.CaptureNode(nodeName)

      end
    end
  end

  return timer.getTime() + LOGNET.FLAG_CHECK_INTERVAL
end

function LOGNET.CheckAllCaptured()

  for nodeName, node in pairs(LOGNET.NODES) do

    if not node.captured then
      return false
    end
  end

  LOGNET.Msg(
    "RED LOGISTICA CAPTURADA COMPLETAMENTE. Todas las conexiones estan bajo control BLUE.",
    25
  )

  if LOGNET.ALL_CAPTURED_FLAG then
    trigger.action.setUserFlag(LOGNET.ALL_CAPTURED_FLAG, 1)
  end

  return true
end

function LOGNET.Start()

  LOGNET.InitIds()

  timer.scheduleFunction(function()
    LOGNET.DrawAll()

    LOGNET.Msg(
      "LOGNET iniciado. Red logistica dibujada en F10.",
      15
    )

    return nil
  end, {}, timer.getTime() + 3)

  timer.scheduleFunction(function()
    return LOGNET.CheckCaptureFlags()
  end, {}, timer.getTime() + 5)
end

LOGNET.Start()