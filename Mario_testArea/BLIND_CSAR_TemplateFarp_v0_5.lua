-- ============================================================
-- MISION BLIND - CSAR FARP TEMPLATE SPAWNER
-- Version: 0.5
-- Generado desde Template_Farp.miz
-- Zeus / Marte
--
-- Objetivo:
-- Spawnear la FARP diseñada manualmente en Mission Editor
-- usando coordenadas relativas al centro de los 4 PADs.
--
-- Requiere en la misión destino:
-- Trigger Zone: BLIND_RENE_HELIPAD_ZONE
-- ============================================================

local DEBUG = true
local DEST_ZONE_NAME = "BLIND_RENE_HELIPAD_ZONE"
local SPAWN_PREFIX = "BLIND_CSAR_FARP_01"
local FARP_COUNTRY = country.id.USA
local BASE_HEADING_DEG = 0
local REMOVE_ORIGINAL_TEMPLATE = false

local TEMPLATE_ANCHOR_X = -49635.898760057498
local TEMPLATE_ANCHOR_Z = 7489.432372399875

local TEMPLATE_STATICS = {
    {
        name = "TPL_CSAR_AMMO_001",
        type = "FARP Ammo Dump Coating",
        category = "Fortifications",
        shape_name = "SetkaKP",
        dx = 20.5136443225,
        dz = 6.45649685203,
        heading = 0,
        rate = 50,
    },
    {
        name = "TPL_CSAR_FUEL_001",
        type = "FARP Fuel Depot",
        category = "Fortifications",
        shape_name = "GSM Rus",
        dx = 19.6238483635,
        dz = -20.7458367431,
        heading = 0,
        rate = 20,
    },
    {
        name = "TPL_CSAR_HESCO_0010",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 14.9644123205,
        dz = 19.0010827649,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_0011",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 14.9644123205,
        dz = 37.1359238735,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_0012",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -13.4953748205,
        dz = 43.4897368167,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_002",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 3.9776107735,
        dz = -44.1399333579,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_003",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = -13.6277459235,
        dz = -44.2193560197,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_004",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = -35.6145861295,
        dz = 48.9699004802,
        heading = 4.71238898038,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_005",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 25.1040388095,
        dz = -46.4034792189,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_006",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 2.2567864345,
        dz = 43.2249946107,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_007",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 14.8320412175,
        dz = -36.065296076,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_008",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 14.8320412175,
        dz = -17.7980838644,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_009",
        type = "ERO_Hesco_Barrier_9x1x1",
        category = "Fortifications",
        dx = 14.9644123205,
        dz = 0.601499450325,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_021",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1892719875,
        dz = -46.5906224795,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_022",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1859244475,
        dz = -32.671782345,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_023",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1859244475,
        dz = -18.7126478486,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_024",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1167283565,
        dz = -4.70762226178,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_025",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1859244475,
        dz = 9.32595851043,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_026",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1825769075,
        dz = 23.244798645,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_027",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1825769075,
        dz = 37.2039331413,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_028",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 41.1825769075,
        dz = 51.2834050041,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_029",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 35.3532096125,
        dz = 59.513335358,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_030",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 21.4343694775,
        dz = 59.5099878179,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_031",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 7.4752349815,
        dz = 59.5099878178,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_032",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -6.6042368815,
        dz = 59.5099878178,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_033",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -20.5633713775,
        dz = 59.5099878177,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_034",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -34.5486750375,
        dz = 59.5815141888,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_035",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -48.4413460085,
        dz = 59.5066402776,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_036",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0500502455,
        dz = 43.1245315657,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_037",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0500502455,
        dz = 29.045059703,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_038",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0500502455,
        dz = 15.0859252066,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_039",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0467027045,
        dz = 1.16708507202,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_040",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0467027045,
        dz = -12.7920494243,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_041",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0467027045,
        dz = -26.871521287,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_042",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0467027045,
        dz = -40.8306557834,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_043",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -66.0433551645,
        dz = -54.7494959179,
        heading = 1.57079632679,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_044",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -59.9335644945,
        dz = -62.5395166725,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_045",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -45.8540926325,
        dz = -62.5395166725,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_046",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -31.8949581355,
        dz = -62.5395166726,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_047",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -17.9761180015,
        dz = -62.5361691324,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_048",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = -4.0169835045,
        dz = -62.5361691323,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_049",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 10.0624883575,
        dz = -62.5361691323,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_HESCO_050",
        type = "ERO_Hesco_Barrier_7x1x2",
        category = "Fortifications",
        dx = 24.0216228545,
        dz = -62.5361691323,
        heading = 3.14159265359,
        rate = 5,
    },
    {
        name = "TPL_CSAR_MEDIC_01",
        type = "ERO_Tent_RedCross_A",
        category = "Fortifications",
        dx = -38.8179668215,
        dz = -34.6092139432,
        heading = 0,
        rate = 1,
    },
    {
        name = "TPL_CSAR_PAD_1",
        type = "FARP_SINGLE_01",
        category = "Heliports",
        shape_name = "FARP_SINGLE_01",
        dx = 0.171261277501,
        dz = -32.8711687406,
        heading = 0,
        heliport_callsign_id = 1,
        heliport_modulation = 0,
        heliport_frequency = "127.5",
        rate = 100,
    },
    {
        name = "TPL_CSAR_PAD_2",
        type = "FARP_SINGLE_01",
        category = "Heliports",
        shape_name = "FARP_SINGLE_01",
        dx = -0.184216644499,
        dz = -11.0876964235,
        heading = 0,
        heliport_callsign_id = 1,
        heliport_modulation = 0,
        heliport_frequency = "127.5",
        rate = 100,
    },
    {
        name = "TPL_CSAR_PAD_3",
        type = "FARP_SINGLE_01",
        category = "Heliports",
        shape_name = "FARP_SINGLE_01",
        dx = 0.403590992501,
        dz = 11.0588165859,
        heading = 0,
        heliport_callsign_id = 1,
        heliport_modulation = 0,
        heliport_frequency = "127.5",
        rate = 100,
    },
    {
        name = "TPL_CSAR_PAD_4",
        type = "FARP_SINGLE_01",
        category = "Heliports",
        shape_name = "FARP_SINGLE_01",
        dx = -0.390635625503,
        dz = 32.9000485781,
        heading = 0,
        heliport_callsign_id = 1,
        heliport_modulation = 0,
        heliport_frequency = "127.5",
        rate = 100,
    },
    {
        name = "TPL_CSAR_TENT_001",
        type = "FARP Tent",
        category = "Fortifications",
        shape_name = "PalatkaB",
        dx = -54.3980456425,
        dz = -12.4767655244,
        heading = 0,
        rate = 50,
    },
    {
        name = "TPL_CSAR_TENT_002",
        type = "FARP Tent",
        category = "Fortifications",
        shape_name = "PalatkaB",
        dx = -54.5436538555,
        dz = -1.55614952837,
        heading = 0,
        rate = 50,
    },
    {
        name = "TPL_CSAR_TENT_003",
        type = "FARP Tent",
        category = "Fortifications",
        shape_name = "PalatkaB",
        dx = -54.6892620685,
        dz = 9.21885825442,
        heading = 0,
        rate = 50,
    },
    {
        name = "TPL_CSAR_TOWER_NW",
        type = "ERO_Hesco_Barrier_Tower",
        category = "Fortifications",
        dx = -63.9287650575,
        dz = 48.916952039,
        heading = 3.14159265359,
        rate = 50,
    },
    {
        name = "TPL_CSAR_TOWER_SE",
        type = "ERO_Hesco_Barrier_Tower",
        category = "Fortifications",
        dx = 31.1136868845,
        dz = -56.3180748323,
        heading = 1.57079632679,
        rate = 50,
    },
    {
        name = "TPL_CSAR_WINDSOC_01",
        type = "Windsock",
        category = "Fortifications",
        shape_name = "H-Windsock_RW",
        dx = -15.1101483305,
        dz = -0.149017604175,
        heading = 1.55334303428,
        rate = 3,
    },
}

local TEMPLATE_GROUPS = {
    {
        name = "TPL_CSAR_Bradley_001",
        task = "Ground Nothing",
        units = {
            {
                name = "Ground-1-1",
                type = "M-2 Bradley",
                dx = -41.5014177795,
                dz = 54.4618193476,
                heading = 3.12763001957,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Bradley_001-1",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Bradley_001-1-1",
                type = "M-2 Bradley",
                dx = -41.4711558615,
                dz = 48.9541502084,
                heading = 3.14159265359,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_TANK_001",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_003-6-1",
                type = "M-1 Abrams",
                dx = 36.7362570845,
                dz = 25.9707312397,
                heading = 4.71238898038,
                skill = "Average",
                livery_id = "desert_summer",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_TANK_001-1",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_TANK_001-1-1",
                type = "M-1 Abrams",
                dx = 32.1221400145,
                dz = 26.1836904891,
                heading = 4.71238898038,
                skill = "Average",
                livery_id = "desert_summer",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_TANK_001-2",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_TANK_001-2-1",
                type = "M-1 Abrams",
                dx = 37.1621755835,
                dz = 36.4767208766,
                heading = 4.71238898038,
                skill = "Average",
                livery_id = "desert_summer",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_TANK_001-3",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_TANK_001-3-1",
                type = "M-1 Abrams",
                dx = 31.9801671815,
                dz = 36.4057344601,
                heading = 4.71238898038,
                skill = "Average",
                livery_id = "desert_summer",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_001",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Bradley_001-2-1",
                type = "CHAP_MATV",
                dx = -26.3442745355,
                dz = 28.865460376,
                heading = 3.1049407393,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_001-1",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_001-1-1",
                type = "CHAP_MATV",
                dx = -26.4227661585,
                dz = 24.5484211361,
                heading = 3.1049407393,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_001-2",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_001-2-1",
                type = "CHAP_MATV",
                dx = -26.7367326485,
                dz = 19.8389237836,
                heading = 3.1049407393,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_003",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_001-3-1",
                type = "MaxxPro_MRAP",
                dx = 19.4114298735,
                dz = -11.1288627159,
                heading = 0,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_003-1",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_003-1-1",
                type = "M1043 HMMWV Armament",
                dx = 18.7703101705,
                dz = 14.1152256181,
                heading = 0,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_003-2",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_003-2-1",
                type = "M1043 HMMWV Armament",
                dx = 18.8504501335,
                dz = 17.8818038775,
                heading = 0,
                skill = "Average",
                livery_id = "summer",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_003-3",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_003-3-1",
                type = "M1043 HMMWV Armament",
                dx = 18.8103801515,
                dz = 21.3678922665,
                heading = 0,
                skill = "Average",
                livery_id = "desert",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_003-4",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_003-4-1",
                type = "MaxxPro_MRAP",
                dx = 19.4114298735,
                dz = -7.56263436398,
                heading = 0,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
    {
        name = "TPL_CSAR_Truck_003-5",
        task = "Ground Nothing",
        units = {
            {
                name = "TPL_CSAR_Truck_003-5-1",
                type = "MaxxPro_MRAP",
                dx = 19.4514998555,
                dz = -3.39535628978,
                heading = 0,
                skill = "Average",
                playerCanDrive = false,
                coldAtStart = false,
            },
        },
    },
}


local function msg(text, time)
    if DEBUG then
        trigger.action.outText(text, time or 10)
    end
end

local function destroyStatic(name)
    local obj = StaticObject.getByName(name)
    if obj then obj:destroy() end
end

local function destroyGroup(name)
    local grp = Group.getByName(name)
    if grp then grp:destroy() end
end

local function rotatePoint(baseX, baseZ, dx, dz, headingRad)
    local c = math.cos(headingRad)
    local s = math.sin(headingRad)
    local x = baseX + dx * c - dz * s
    local z = baseZ + dx * s + dz * c
    return x, z
end

local function spawnName(templateName)
    return SPAWN_PREFIX .. "_" .. templateName:gsub("^TPL_CSAR_", "")
end

local function cleanupSpawned()
    for _, s in ipairs(TEMPLATE_STATICS) do
        destroyStatic(spawnName(s.name))
        if REMOVE_ORIGINAL_TEMPLATE then
            destroyStatic(s.name)
        end
    end
    for _, g in ipairs(TEMPLATE_GROUPS) do
        destroyGroup(spawnName(g.name))
        if REMOVE_ORIGINAL_TEMPLATE then
            destroyGroup(g.name)
        end
    end
end

local function spawnStaticFromEntry(entry, baseX, baseZ)
    local baseHeadingRad = math.rad(BASE_HEADING_DEG)
    local x, z = rotatePoint(baseX, baseZ, entry.dx, entry.dz, baseHeadingRad)

    local data = {
        category = entry.category,
        type = entry.type,
        name = spawnName(entry.name),
        x = x,
        y = z,
        heading = (entry.heading or 0) + baseHeadingRad,
        dead = false,
    }

    if entry.shape_name then data.shape_name = entry.shape_name end
    if entry.heliport_callsign_id then data.heliport_callsign_id = entry.heliport_callsign_id end
    if entry.heliport_modulation then data.heliport_modulation = entry.heliport_modulation end
    if entry.heliport_frequency then data.heliport_frequency = entry.heliport_frequency end
    if entry.rate then data.rate = entry.rate end

    local obj = coalition.addStaticObject(FARP_COUNTRY, data)
    if not obj then
        msg("ERROR BLIND: no se pudo crear static " .. data.name .. " / type: " .. tostring(entry.type), 20)
        return false
    end
    return true
end

local function spawnGroundGroupFromEntry(entry, baseX, baseZ)
    if not entry.units or #entry.units == 0 then return false end

    local baseHeadingRad = math.rad(BASE_HEADING_DEG)
    local routeX, routeZ = rotatePoint(baseX, baseZ, entry.units[1].dx, entry.units[1].dz, baseHeadingRad)

    local groupData = {
        visible = false,
        hidden = false,
        task = entry.task or "Ground Nothing",
        route = {
            points = {
                [1] = {
                    x = routeX,
                    y = routeZ,
                    type = "Turning Point",
                    action = "Off Road",
                    speed = 0,
                    speed_locked = true,
                    ETA = 0,
                    ETA_locked = true,
                    task = {
                        id = "ComboTask",
                        params = { tasks = {} }
                    }
                }
            }
        },
        units = {},
        name = spawnName(entry.name),
    }

    for i, u in ipairs(entry.units) do
        local x, z = rotatePoint(baseX, baseZ, u.dx, u.dz, baseHeadingRad)
        groupData.units[i] = {
            type = u.type,
            name = spawnName(u.name or (entry.name .. "_UNIT_" .. i)),
            x = x,
            y = z,
            heading = (u.heading or 0) + baseHeadingRad,
            skill = u.skill or "Average",
            playerCanDrive = false,
        }
        if u.livery_id then groupData.units[i].livery_id = u.livery_id end
    end

    local grp = coalition.addGroup(FARP_COUNTRY, Group.Category.GROUND, groupData)
    if not grp then
        msg("ERROR BLIND: no se pudo crear grupo " .. groupData.name, 20)
        return false
    end
    return true
end

local function spawnTemplateFarp()
    msg("BLIND CSAR FARP v0.5: iniciando spawn de template...", 10)

    local zone = trigger.misc.getZone(DEST_ZONE_NAME)
    if not zone then
        trigger.action.outText("ERROR BLIND: no existe la zona " .. DEST_ZONE_NAME, 30)
        return
    end

    local baseX = zone.point.x
    local baseZ = zone.point.z

    cleanupSpawned()

    local okStatic = 0
    local failStatic = 0
    local okGroup = 0
    local failGroup = 0

    for _, s in ipairs(TEMPLATE_STATICS) do
        if spawnStaticFromEntry(s, baseX, baseZ) then
            okStatic = okStatic + 1
        else
            failStatic = failStatic + 1
        end
    end

    for _, g in ipairs(TEMPLATE_GROUPS) do
        if spawnGroundGroupFromEntry(g, baseX, baseZ) then
            okGroup = okGroup + 1
        else
            failGroup = failGroup + 1
        end
    end

    trigger.action.outText(
        "BLIND CSAR FARP v0.5 OK: statics " .. okStatic .. "/" .. #TEMPLATE_STATICS ..
        ", grupos " .. okGroup .. "/" .. #TEMPLATE_GROUPS ..
        ", errores statics " .. failStatic ..
        ", errores grupos " .. failGroup,
        30
    )
end

spawnTemplateFarp()
