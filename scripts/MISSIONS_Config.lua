--[[
====================================================================
 MISSIONS_Config.lua
 Base de datos de misiones de la campana dinamica.

 REGLA: para agregar, modificar o desactivar una mision,
        editar SOLO este archivo. Nunca tocar MIS_Manager.lua.

 CAMPOS:
   id         string  identificador unico
   name       string  nombre largo para logs
   type       string  "AWACS"|"CAP"|"SEAD"|"STRIKE"|"HELI"|"TRANSPORT"
   category   string  "always"|"campaign"|"intel"
   platforms  table   {"fighter"|"heli"|"transport"|"all"}
   coalition  string  "blue"|"red"
   active     bool    true = disponible
   menuText   string  texto en el menu F10
   briefing   string  descripcion al activar
   cost       number  puntos de coalicion (0 = gratis)
   conditions table   condiciones (nil = siempre disponible)

 CAMPOS ESPECIFICOS AWACS:
   template   string  grupo late-activated en el ME
   spawnBase  string  nombre del carrier/base en DCS
   frequency  number  frecuencia radio
   modulation string  "AM"|"FM"
   orbitFL    number  flight level de orbita

 Actualizado: 10/07/2026
====================================================================
]]

MISSIONS_Config = {

  -- ==========================================================
  -- INTEL / STATUS (category = "intel")
  -- Aparecen en el menu Intel/Status, no en Misiones
  -- ==========================================================

  {
    id         = "LORD_001",
    name       = "LORD - Control Aereo AWACS E-2D",
    type       = "AWACS",
    category   = "intel",
    platforms  = { "all" },
    coalition  = "blue",
    active     = true,
    menuText   = "Solicitar LORD (AWACS E-2D)",
    briefing   = "AWACS LORD despega del CVN-73 y orbita overhead.\n" ..
                 "Frecuencia: 130.0 AM | FL270.\n" ..
                 "RTB automatico por nivel de combustible.",
    cost       = 0,
    template   = "BLUE_AWACS_E2D",
    spawnBase  = "BLUE_CVN73_GROUP",
    frequency  = 130.0,
    modulation = "AM",
    orbitFL    = 270,
    conditions = nil,
  },

  -- ==========================================================
  -- SIEMPRE DISPONIBLES (category = "always")
  -- ==========================================================

  -- FIGHTER TEST
  {
    id        = "TEST_FIGHTER_01",
    name      = "Prueba Fighter 1 - CAP Zona Norte",
    type      = "TEST",
    category  = "always",
    platforms = { "fighter" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST F-1 | CAP Zona Norte",
    briefing  = "Mision de prueba para cazas. CAP Zona Norte.",
    cost      = 0,
    conditions = nil,
  },
  {
    id        = "TEST_FIGHTER_02",
    name      = "Prueba Fighter 2 - SEAD Zona Costera",
    type      = "TEST",
    category  = "always",
    platforms = { "fighter" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST F-2 | SEAD Zona Costera",
    briefing  = "Mision de prueba para cazas. SEAD Zona Costera.",
    cost      = 0,
    conditions = nil,
  },
  {
    id        = "TEST_FIGHTER_03",
    name      = "Prueba Fighter 3 - Strike Objetivo Alpha",
    type      = "TEST",
    category  = "always",
    platforms = { "fighter" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST F-3 | Strike Objetivo Alpha",
    briefing  = "Mision de prueba para cazas. Strike Objetivo Alpha.",
    cost      = 0,
    conditions = nil,
  },

  -- HELI TEST
  {
    id        = "TEST_HELI_01",
    name      = "Prueba Heli 1 - Transporte Tropas",
    type      = "TEST",
    category  = "always",
    platforms = { "heli" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST H-1 | Transporte Tropas",
    briefing  = "Mision de prueba para helicopteros. Transporte de tropas.",
    cost      = 0,
    conditions = nil,
  },
  {
    id        = "TEST_HELI_02",
    name      = "Prueba Heli 2 - CSAR Piloto Caido",
    type      = "TEST",
    category  = "always",
    platforms = { "heli" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST H-2 | CSAR Piloto Caido",
    briefing  = "Mision de prueba para helicopteros. CSAR.",
    cost      = 0,
    conditions = nil,
  },
  {
    id        = "TEST_HELI_03",
    name      = "Prueba Heli 3 - Reabastecimiento FARP",
    type      = "TEST",
    category  = "always",
    platforms = { "heli" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST H-3 | Reabastecimiento FARP",
    briefing  = "Mision de prueba para helicopteros. Reabastecimiento.",
    cost      = 0,
    conditions = nil,
  },

  -- TRANSPORT TEST
  {
    id        = "TEST_TRANS_01",
    name      = "Prueba Transporte 1 - Suministros Akrotiri",
    type      = "TEST",
    category  = "always",
    platforms = { "transport" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST T-1 | Suministros Akrotiri",
    briefing  = "Mision de prueba para transporte. Suministros a Akrotiri.",
    cost      = 0,
    conditions = nil,
  },
  {
    id        = "TEST_TRANS_02",
    name      = "Prueba Transporte 2 - Carga Ramat David",
    type      = "TEST",
    category  = "always",
    platforms = { "transport" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST T-2 | Carga Ramat David",
    briefing  = "Mision de prueba para transporte. Carga a Ramat David.",
    cost      = 0,
    conditions = nil,
  },
  {
    id        = "TEST_TRANS_03",
    name      = "Prueba Transporte 3 - Logistica CVN-73",
    type      = "TEST",
    category  = "always",
    platforms = { "transport" },
    coalition = "blue",
    active    = true,
    menuText  = "TEST T-3 | Logistica CVN-73",
    briefing  = "Mision de prueba para transporte. Logistica al CVN-73.",
    cost      = 0,
    conditions = nil,
  },
  -- Ejemplo:
  -- {
  --   id        = "CAP_MED_001",
  --   name      = "CAP Mediterraneo",
  --   type      = "CAP",
  --   category  = "always",
  --   platforms = { "fighter" },
  --   coalition = "blue",
  --   active    = false,
  --   menuText  = "CAP Mediterraneo",
  --   briefing  = "Patrulla CAP sobre el Mediterraneo Sur.",
  --   cost      = 0,
  --   conditions = nil,
  -- },

  -- ==========================================================
  -- CAMPANA ACTIVA (category = "campaign")
  -- Se desbloquean por condiciones de CAMP_Net/ZONE_State
  -- ==========================================================

  -- Agregar aqui las misiones de campana cuando esten listas

}
