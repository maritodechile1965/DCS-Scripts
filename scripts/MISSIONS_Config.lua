--[[
====================================================================
 MISSIONS_Config.lua
 Base de datos de misiones de la campana dinamica.

 REGLA FUNDAMENTAL:
   Para agregar, modificar o desactivar una mision:
   editar SOLO este archivo. Nunca tocar MIS_Manager.lua.

 TIPOS DE MISION SOPORTADOS (por MIS_Manager):
   "AWACS"  - aeronave de control aereo en orbita
   "CAP"    - patrulla aerea de combate (proxima version)
   "SEAD"   - supresion de defensas enemigas (proxima version)
   "STRIKE" - ataque a objetivos (proxima version)

 CAMPOS COMUNES A TODAS LAS MISIONES:
   id          string  identificador unico (ej. "LORD_001")
   name        string  nombre largo para logs
   type        string  tipo de mision (ver lista arriba)
   coalition   string  "blue" o "red"
   menuText    string  texto que aparece en el menu F10
   briefing    string  descripcion para el piloto al activar
   cost        number  puntos de coalicion que cuesta activar (0 = gratis)
   active      bool    true = disponible en el menu (false = oculta)
   conditions  table   condiciones para disponibilidad (nil = siempre)

 CAMPOS ESPECIFICOS TIPO "AWACS":
   template      string  nombre del grupo late-activated en el ME
   spawnBase     string  nombre exacto de la base de spawn en DCS
   takeoff       string  "cold" | "hot" | "air"
   orbitZone     string  nombre de la Trigger Zone de orbita en el ME
   orbitFL       number  flight level (ej. 270 = FL270 = 27.000 ft)
   orbitSpeedKts number  velocidad en nudos en la orbita
   orbitLegNm    number  longitud del leg del hipodromo en NM
   orbitHdg      number  heading del leg principal en grados
   frequency     number  frecuencia de radio (ej. 130.0)
   modulation    string  "AM" o "FM"
   durationMin   number  duracion en minutos antes de RTB
   rtbBase       string  nombre exacto de la base de regreso en DCS

 Actualizacion: 09/07/2026
====================================================================
]]

MISSIONS_Config = {

  -- ==========================================================
  -- MISIONES SIEMPRE DISPONIBLES
  -- (sin campo conditions o conditions = nil)
  -- ==========================================================

  -- ----------------------------------------------------------
  -- LORD - AWACS E-3 desde CVN-73
  -- Orbita en ZONA_AWACS_E2D a FL270, 40nm, hdg 010
  -- Frecuencia 130.0 AM, 2 horas de mision
  -- ----------------------------------------------------------
  {
    id            = "LORD_001",
    name          = "LORD - Control Aereo AWACS E-3",
    type          = "AWACS",
    coalition     = "blue",
    active        = true,
    menuText      = "Activar LORD (AWACS E-3)",
    briefing      = "AWACS LORD despega del CVN-73 y orbita overhead.\n" ..
                    "Frecuencia: 130.0 AM | FL270.\n" ..
                    "RTB automatico por nivel de combustible.",
    cost          = 0,
    -- Spawn (RECOVERYTANKER usa el nombre del grupo del carrier)
    template      = "BLUE_AWACS_E2D",
    spawnBase     = "BLUE_CVN73_GROUP",
    -- Radio
    frequency     = 130.0,
    modulation    = "AM",
    -- Altitud de orbita
    orbitFL       = 270,
    -- Sin condiciones = siempre disponible
    conditions    = nil,
  },

  -- ==========================================================
  -- PROXIMAS MISIONES (ejemplos de estructura para futuras)
  -- Desactivadas con active = false hasta estar listas
  -- ==========================================================

  -- EJEMPLO FUTURO: CAP sobre el Mediterraneo
  -- {
  --   id         = "CAP_MED_001",
  --   name       = "CAP Mediterraneo Sur",
  --   type       = "CAP",
  --   coalition  = "blue",
  --   active     = false,
  --   menuText   = "CAP Mediterraneo Sur",
  --   briefing   = "Patrulla CAP sobre el Mediterraneo.",
  --   cost       = 0,
  --   template   = "BLUE_CAP_F16",
  --   spawnBase  = "Akrotiri",
  --   takeoff    = "hot",
  --   orbitZone  = "ZONA_CAP_MED",
  --   orbitFL    = 200,
  --   orbitSpeedKts = 350,
  --   orbitLegNm = 30,
  --   orbitHdg   = 90,
  --   frequency  = 121.5,
  --   modulation = "AM",
  --   durationMin = 60,
  --   rtbBase    = "Akrotiri",
  --   conditions = nil,
  -- },

}
