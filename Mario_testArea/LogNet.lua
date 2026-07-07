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

  INCIR = {
    zone = "LN_INCIR",
    label = "Incirlink",
    captureFlag = 8101,
    radius = 6000,
  },

  GAZIAN = {
    zone = "LN_GAZIAN",
    label = "Gaziantep",
    captureFlag = 8102,
    radius = 6000,
  },

  MINAK = {
    zone = "LN_MINAKH",
    label = "Minakh",
    captureFlag = 8103,
    radius = 6000,
  },

  KUWEIRES = {
    zone = "LN_KUWEIRES",
    label = "Kuweires",
    captureFlag = 8104,
    radius = 6000,
  },

  JIRAH = {
    zone = "LN_JIRAH",
    label = "Jirah",
    captureFlag = 8105,
    radius = 6000,
  },
  
    TABQA = {
    zone = "LN_TABQUA",
    label = "Tabqa",
    captureFlag = 8106,
    radius = 6000,
  },

    ERZOR = {
    zone = "LN_ERZOR",
    label = "Deir er-Zor",
    captureFlag = 8107,
    radius = 6000,
  },
  
   ABU = {
    zone = "LN_ABUAL",
    label = "Abu al-Duhur",
    captureFlag = 8108,
    radius = 6000,
  },

   BASSEL = {
    zone = "LN_BASEL",
    label = "Bassel Al-Assad",
    captureFlag = 8109,
    radius = 6000,
  },

   HAMA = {
    zone = "LN_HAMA",
    label = "Hama",
    captureFlag = 81010,
    radius = 6000,
  },
  
   RENE = {
    zone = "LN_RENE",
    label = "Hama",
    captureFlag = 81011,
    radius = 6000,
  },
    
   QUSAYR = {
    zone = "LN_QUSAYR",
    label = "Al-Qusayr",
    captureFlag = 81012,
    radius = 6000,
  },
    
   SHAYRAT = {
    zone = "LN_SHAYRAT",
    label = "Shayrat",
    captureFlag = 81013,
    radius = 6000,
  },    
    
   TIYAS = {
    zone = "LN_TIYAS",
    label = "Tiyas",
    captureFlag = 81014,
    radius = 6000,
  },
           
   PALMYRA = {
    zone = "LN_PALMYRA",
    label = "Palmyra",
    captureFlag = 81015,
    radius = 6000,
  },
           
   SAYQAL = {
    zone = "LN_SAYQAL",
    label = "Sayqal",
    captureFlag = 81016,
    radius = 6000,
  },    
           
   NASIRI = {
    zone = "LN_NASIRI",
    label = "An Nasiriya",
    captureFlag = 81017,
    radius = 6000,
  }, 

   RAYAK = {
    zone = "LN_RAYAK",
    label = "Rayak",
    captureFlag = 81018,
    radius = 6000,
  }, 
  
   DUMAYR = {
    zone = "LN_DUMAYR",
    label = "Al-Dumayr",
    captureFlag = 81019,
    radius = 6000,
  }, 
  
   MEZZE = {
    zone = "LN_MEZZE",
    label = "Mezzeh",
    captureFlag = 81020,
    radius = 6000,
  }, 
   
   MARJ = {
    zone = "LN_MARJ",
    label = "Marj Ruhayyil",
    captureFlag = 81021,
    radius = 6000,
  }, 
    
   KALK = {
    zone = "LN_KALK",
    label = "Khalkhalah",
    captureFlag = 81022,
    radius = 6000,
  }, 
     
   TALAH = {
    zone = "LN_THALAH",
    label = "Tha'lah",
    captureFlag = 81023,
    radius = 6000,
  }, 
              
  -- =====  BLUE ==== ---
      
   PAPHOS = {
    zone = "LN_PAPHOS",
    label = "Paphos",
    captureFlag = 82001,
    radius = 6000,
  },
      
   AKRO = {
    zone = "LN_AKRO",
    label = "Akrotiri",
    captureFlag = 82002,
    radius = 6000,
  },
      
   LARNA = {
    zone = "LN_LARNA",
    label = "Larnaca",
    captureFlag = 82003,
    radius = 6000,
  },
      
   KINGS = {
    zone = "LN_KINGS",
    label = "Larnaca",
    captureFlag = 82004,
    radius = 6000,
  },
      
   GECIT = {
    zone = "LN_GECIT",
    label = "Gecitkale",
    captureFlag = 82005,
    radius = 6000,
  },
      
   ERKAN = {
    zone = "LN_ERKAN",
    label = "Ercan",
    captureFlag = 82006,
    radius = 6000,
  },
      
   CVN73 = {
    zone = "LN_CVN73",
    label = "CVN-73",
    captureFlag = 82007,
    radius = 6000,
  },
      
   RAMAT = {
    zone = "LN_RAMAT",
    label = "CVN-73",
    captureFlag = 82008,
    radius = 6000,
  },
      
   SHEMER = {
    zone = "LN_SHEMER",
    label = "Eyn Shemer",
    captureFlag = 82009,
    radius = 6000,
  },
      
   HERZI = {
    zone = "LN_HERZI",
    label = "Herzliya",
    captureFlag = 820010,
    radius = 6000,
  },
      
   TELNOF = {
    zone = "LN_TELNOF",
    label = "Tel Nof",
    captureFlag = 820011,
    radius = 6000,
  },
      
   HATZOR = {
    zone = "LN_HATZOR",
    label = "Hatzor",
    captureFlag = 820012,
    radius = 6000,
  },
       
   TEYMAN = {
    zone = "LN_TEYMAN",
    label = "Teyman",
    captureFlag = 820013,
    radius = 6000,
  }, 
        
   NEVATIM = {
    zone = "LN_NEVATIM",
    label = "Teyman",
    captureFlag = 820013,
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

  { from = "INCIR", to = "GAZIAN" },
  { from = "INCIR", to = "MINAK" },
  { from = "GAZIAN", to = "JIRAH" },
  { from = "MINAK", to = "KUWEIRES" },
  { from = "KUWEIRES", to = "JIRAH" },  
  { from = "JIRAH", to = "TABQA" },   
  { from = "TABQA", to = "ERZOR" },   
  { from = "ERZOR", to = "PALMYRA" },
  { from = "PALMYRA", to = "TABQA" },
  { from = "KUWEIRES", to = "ABU" },
  { from = "ABU", to = "BASSEL" },
  { from = "BASSEL", to = "HAMA" },  
  { from = "ABU", to = "HAMA" },
  { from = "HAMA", to = "RENE" },
  { from = "HAMA", to = "QUSAYR" }, 
  { from = "RENE", to = "QUSAYR" },  
  { from = "SHAYRAT", to = "QUSAYR" },  
  { from = "SHAYRAT", to = "TIYAS" }, 
  { from = "PALMYRA", to = "TIYAS" },  
  { from = "PALMYRA", to = "SAYQAL" },  
  { from = "NASIRI", to = "SAYQAL" },  
  { from = "NASIRI", to = "SHAYRAT" },  
  { from = "RAYAK", to = "SHAYRAT" }, 
  { from = "NASIRI", to = "DUMAYR" }, 
  { from = "SAYQAL", to = "DUMAYR" }, 
  { from = "RAYAK", to = "MEZZE" },
  { from = "MARJ", to = "MEZZE" },
  { from = "MARJ", to = "DUMAYR" },
  { from = "MARJ", to = "KALK" },
  { from = "MARJ", to = "TALAH" },
  { from = "KALK", to = "TALAH" },
  
  
  -- ===== BLUE ====---
  
  { from = "NEVATIM", to = "TEYMAN" },
  { from = "HATZOR", to = "TEYMAN" }, 
  { from = "NEVATIM", to = "HATZOR" },
  { from = "TELNOF", to = "HATZOR" },
  { from = "TELNOF", to = "HERZI" },
  { from = "TELNOF", to = "RAMAT" },
  { from = "SHEMER", to = "HERZI" },
  { from = "SHEMER", to = "RAMAT" },
  { from = "CVN73", to = "RAMAT" },  
  { from = "CVN73", to = "HATZOR" },  
  { from = "CVN73", to = "PAPHOS" },  
  { from = "CVN73", to = "AKRO" },    
  { from = "LARNA", to = "AKRO" },   
  { from = "KINGS", to = "GECIT" }, 
  { from = "KINGS", to = "ERKAN" },   
  { from = "LARNA", to = "KINGS" },   
  
  
 -- === WHITE === -- 
 
   { from = "LARNA", to = "BASSEL" },
   { from = "LARNA", to = "RENE" },
   { from = "LARNA", to = "INCIR" },   
   { from = "CVN73", to = "RENE" },
   { from = "CVN73", to = "MARJ" },
   { from = "CVN73", to = "TALAH" },  
   { from = "RAMAT", to = "MARJ" },  
   { from = "RAMAT", to = "TALAH" }, 


   
  
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