-- ============================================================
-- MISSIONS_Config.lua
-- Generado por el Constructor de Misiones DCS
-- Misiones: 1  |  03-07-2026, 12:31:01 a. m.
-- Sin bloque conditions => misión SIEMPRE disponible.
-- ============================================================

MISSIONS_Config = {

  {
    id           = "SEAD SA-5 TABQA",
    name         = "SEAD SAM 5 TABQA",
    type         = "SEAD",
    domain       = "ground",
    coalition    = "blue",
    minPilots    = 2,
    maxPilots    = 8,
    pointsReward = 50,
    pointsPenalty= -5,
    briefing     = "Atacar y destruir el SA5 que se encuentra en las cercanias de Tabqa. Para tener el exito en la mision, se deben eliminar TODOS los radares del sistema y al menos 2 Lanzadoras.",
    targets      = {
      { unitName = "RED_SAM_SA5 TABQA-1", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 66926 60750", mandatory = true },
      { unitName = "RED_SAM_SA5 TABQA-3", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 66753 60763", mandatory = true },
      { unitName = "RED_SAM_SA5 TABQA-2", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 67039 60887", mandatory = true },
      { unitName = "RED_SAM_SA5 TABQA-12", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 67039 60887", mandatory = true },
      { unitName = "RED_SAM_SA5 TABQA-6", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 66904 60792", mandatory = false },
      { unitName = "RED_SAM_SA5 TABQA-9", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 66985 60824", mandatory = false },
      { unitName = "RED_SAM_SA5 TABQA-7", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 67029 60781", mandatory = false },
      { unitName = "RED_SAM_SA5 TABQA-5", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 67027 60709", mandatory = false },
      { unitName = "RED_SAM_SA5 TABQA-4", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 66964 60684", mandatory = false },
      { unitName = "RED_SAM_SA5 TABQA-8", type = "VEHICLE", mgrs = "MGRS GRID: 37 S DV 66903 60714", mandatory = false },
    },
  },

}
