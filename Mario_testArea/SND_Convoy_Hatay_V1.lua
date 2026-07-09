-- ============================================================
-- SIMPLE_DYNAMIC_GROUND_MISSIONS_SCORE_V3.lua
--
-- Sistema simple de misiones terrestres dinámicas
--
-- Base sin lag:
-- - Random spawn zone
-- - Spawn template
-- - RouteGroundTo
-- - NO usa RouteGroundOnRoad
--
-- V3:
-- - Mantiene CONVOY_HATAY
-- - Agrega INF_ASSLT_ROSH_PINA
-- - Puntaje por DEAD
-- - Puntaje/penalización al entrar a zona destino
-- - Mensaje táctico
-- - Integración segura con PTS_Manager + flags de respaldo
--
-- Requiere:
-- 1. Moose.lua cargado antes
-- 2. Templates Late Activation:
--      TPL_RED_CONVOY_HATAY
--      SND_INF_ASSLT
-- 3. Zonas destino:
--      LN_HATAY
--      LH_ROSH_PINA
-- 4. Zonas spawn:
--      SND_HATAY_SPAWN_01 al 06
--      SND_INF_ASSLT_SPWN_1 al 4
-- ============================================================

SIMPLE_MISSIONS = {}

-- ============================================================
-- CONFIGURACIÓN DE MISIONES
-- ============================================================

SIMPLE_MISSIONS.list = {

    -- ========================================================
    -- MISIÓN 1: CONVOY HATAY
    -- ========================================================

    {
        id = "CONVOY_HATAY",

        menuRoot = "Menu de Campaña",
        menuSub  = "Convoy S&D",
        menuName = "Zona - Hatay",

        templateName = "TPL_RED_CONVOY_HATAY",

        destinationZone = "LN_HATAY",

        spawnZones = {
            "SND_HATAY_SPAWN_01",
            "SND_HATAY_SPAWN_02",
            "SND_HATAY_SPAWN_03",
            "SND_HATAY_SPAWN_04",
            "SND_HATAY_SPAWN_05",
            "SND_HATAY_SPAWN_06"
        },

        speedKmh = 25,
        routeDelaySeconds = 5,
        routeFormation = "On Road",

        blueScoreFlag = 931001,
        redScoreFlag  = 931002,

        mainTargetName = "TPL_RED_CONVOY_HATAY-TARGET",
        mainTargetToken = "TARGET",

        mainTargetPoints = 55,
        opportunityPoints = 5,

        arrivalBluePoints = -50,
        arrivalRedPoints  = 100,

        monitorSeconds = 10,

        usePTSManager = true,
        useFlags = true
    },

    -- ========================================================
    -- MISIÓN 2: INFANTERÍA ASSAULT ROSH PINA
    -- ========================================================

    {
        id = "INF_ASSLT_ROSH_PINA",

        menuRoot = "Menu de Campaña",
        menuSub  = "Infantería",
        menuName = "Asalto Infantería - Rosh Pina",

        templateName = "SND_INF_ASSLT",

        destinationZone = "LH_ROSH_PINA",

        spawnZones = {
            "SND_INF_ASSLT_SPWN_1",
            "SND_INF_ASSLT_SPWN_2",
            "SND_INF_ASSLT_SPWN_3",
            "SND_INF_ASSLT_SPWN_4"
        },

        speedKmh = 8,
        routeDelaySeconds = 5,
        routeFormation = "Off Road",

        blueScoreFlag = 931001,
        redScoreFlag  = 931002,

        mainTargetName = "SND_INF_ASSLT-TARGET",
        mainTargetToken = "TARGET",

        mainTargetPoints = 35,
        opportunityPoints = 2,

        arrivalBluePoints = -30,
        arrivalRedPoints  = 60,

        monitorSeconds = 10,

        usePTSManager = true,
        useFlags = true
    }

}

SIMPLE_MISSIONS.active = {}

-- ============================================================
-- UTILIDADES BÁSICAS
-- ============================================================

local function msgBlue(text, seconds)
    trigger.action.outTextForCoalition(
        coalition.side.BLUE,
        tostring(text),
        seconds or 15
    )
end

local function log(text)
    env.info("[SIMPLE_MISSIONS] " .. tostring(text))
end

local function getFlag(flag)
    local ok, value = pcall(function()
        return trigger.misc.getUserFlag(flag)
    end)

    if ok and value then
        return tonumber(value) or 0
    end

    return 0
end

local function addFlag(flag, points)
    local newValue = getFlag(flag) + points
    trigger.action.setUserFlag(flag, newValue)
    return newValue
end

local function getZone(zoneName)
    return trigger.misc.getZone(zoneName)
end

local function getCoordinateFromZone(zoneName)
    local zone = getZone(zoneName)

    if not zone or not zone.point then
        return nil
    end

    return COORDINATE:NewFromVec3(zone.point)
end

local function dist2D(a, b)
    local dx = a.x - b.x
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dz * dz)
end

local function metersToNM(meters)
    return meters / 1852
end

local function vec3ToMGRS(vec3)
    local ok, text = pcall(function()
        local lat, lon = coord.LOtoLL(vec3)
        local mgrs = coord.LLtoMGRS(lat, lon)

        return string.format(
            "%s %s %05d %05d",
            tostring(mgrs.UTMZone),
            tostring(mgrs.MGRSDigraph),
            math.floor(mgrs.Easting),
            math.floor(mgrs.Northing)
        )
    end)

    if ok and text then
        return text
    end

    return "MGRS no disponible"
end

local function pickRandomSpawnZone(mission)
    local total = #mission.spawnZones

    if total == 0 then
        return nil
    end

    local index = math.random(1, total)

    return mission.spawnZones[index]
end

-- ============================================================
-- DETECCIÓN ROBUSTA DEL BLANCO PRINCIPAL
-- ============================================================

local function isMainTarget(unitName, mission)
    if not unitName then
        return false
    end

    local unitLower = string.lower(tostring(unitName))
    local mainLower = string.lower(tostring(mission.mainTargetName or ""))
    local tokenLower = string.lower(tostring(mission.mainTargetToken or "TARGET"))

    if unitLower == mainLower then
        return true
    end

    if mainLower ~= "" and string.find(unitLower, mainLower, 1, true) then
        return true
    end

    if tokenLower ~= "" and string.find(unitLower, tokenLower, 1, true) then
        return true
    end

    return false
end

-- ============================================================
-- INTEGRACIÓN DE PUNTOS
-- ============================================================

function SIMPLE_MISSIONS.AddCampaignPoints(mission, sideName, points, reason, payload)

    local sideNumber = coalition.side.BLUE

    if sideName == "RED" then
        sideNumber = coalition.side.RED
    end

    local ptsHandled = false

    -- Hook propio opcional.
    if type(SIMPLE_MISSIONS.PointsHook) == "function" then
        local okHook, handled = pcall(function()
            return SIMPLE_MISSIONS.PointsHook(sideName, sideNumber, points, reason, payload)
        end)

        if okHook and handled == true then
            ptsHandled = true
            log("Puntos enviados por PointsHook: " .. sideName .. " " .. tostring(points))
        end
    end

    -- PTS_Manager opcional.
    if not ptsHandled and mission.usePTSManager and type(PTS_Manager) == "table" then

        local methods = {
            "AddMissionPoints",
            "AddPoints",
            "AddScore",
            "AwardPoints",
            "AddCoalitionPoints"
        }

        for _, methodName in ipairs(methods) do
            if type(PTS_Manager[methodName]) == "function" then

                local okMethod = pcall(function()
                    PTS_Manager[methodName](
                        PTS_Manager,
                        sideName,
                        points,
                        reason,
                        payload
                    )
                end)

                if okMethod then
                    ptsHandled = true

                    log(
                        "PTS_Manager." ..
                        methodName ..
                        " usado: " ..
                        tostring(sideName) ..
                        " " ..
                        tostring(points) ..
                        " | " ..
                        tostring(reason)
                    )

                    break
                end
            end
        end
    end

    -- Flags de respaldo/control.
    if mission.useFlags then
        local flag = mission.blueScoreFlag

        if sideName == "RED" then
            flag = mission.redScoreFlag
        end

        local total = addFlag(flag, points)

        log(
            "FLAG SCORE " ..
            tostring(sideName) ..
            " " ..
            tostring(points) ..
            " | Flag " ..
            tostring(flag) ..
            " total: " ..
            tostring(total) ..
            " | " ..
            tostring(reason)
        )

        return total
    end

    return nil
end

-- ============================================================
-- REGISTRAR UNIDADES PARA PUNTAJE
-- ============================================================

function SIMPLE_MISSIONS.RegisterUnits(mission, groupName)

    local group = Group.getByName(groupName)

    if not group or not group:isExist() then
        msgBlue("ERROR: No pude registrar unidades del grupo " .. tostring(groupName), 20)
        return nil
    end

    local missionState = SIMPLE_MISSIONS.active[mission.id]

    if not missionState then
        return nil
    end

    missionState.units = {}
    missionState.blueMissionPoints = 0
    missionState.redMissionPoints = 0
    missionState.arrivalScored = false
    missionState.mainTargetDetected = false
    missionState.mainTargetUnitName = nil

    local units = group:getUnits()
    local count = 0

    for _, unit in ipairs(units) do
        if unit and unit:isExist() then

            local unitName = unit:getName()
            local typeName = unit:getTypeName()
            local main = isMainTarget(unitName, mission)

            missionState.units[unitName] = {
                name = unitName,
                type = typeName,
                isMain = main,
                points = main and mission.mainTargetPoints or mission.opportunityPoints,
                scored = false
            }

            count = count + 1

            if main then
                missionState.mainTargetDetected = true
                missionState.mainTargetUnitName = unitName
            end
        end
    end

    log(
        "Unidades registradas para " ..
        tostring(mission.id) ..
        ": " ..
        tostring(count)
    )

    if not missionState.mainTargetDetected then
        msgBlue(
            "AVISO:\n" ..
            "No se detectó el blanco principal.\n\n" ..
            "Debe existir una unidad llamada o marcada con:\n" ..
            tostring(mission.mainTargetName) .. "\n\n" ..
            "También se acepta que el nombre contenga:\n" ..
            tostring(mission.mainTargetToken),
            25
        )
    end

    return true
end

-- ============================================================
-- PUNTAJE POR DEAD
-- ============================================================

function SIMPLE_MISSIONS.ScoreDead(unitName)

    for missionId, missionState in pairs(SIMPLE_MISSIONS.active) do

        if missionState and missionState.active and missionState.units then

            local data = missionState.units[unitName]

            if data and not data.scored then

                data.scored = true

                local mission = missionState.mission
                local points = data.points

                missionState.blueMissionPoints = missionState.blueMissionPoints + points

                local reason = "DEAD " .. tostring(unitName)

                local blueTotal = SIMPLE_MISSIONS.AddCampaignPoints(
                    mission,
                    "BLUE",
                    points,
                    reason,
                    {
                        missionId = missionId,
                        unitName = unitName,
                        unitType = data.type,
                        isMain = data.isMain,
                        event = "DEAD"
                    }
                )

                local title = data.isMain and "BLANCO PRINCIPAL DESTRUIDO" or "Blanco de oportunidad destruido"

                local text =
                    "PUNTAJE MISIÓN\n\n" ..
                    "Misión: " .. tostring(mission.menuName) .. "\n" ..
                    title .. "\n" ..
                    "Unidad: " .. tostring(data.name) .. "\n" ..
                    "Tipo: " .. tostring(data.type) .. "\n" ..
                    "BLUE +" .. tostring(points) .. " puntos\n\n"

                if data.isMain then
                    text = text ..
                        "Detalle:\n" ..
                        "Objetivo principal + unidad destruida\n\n"
                end

                text = text ..
                    "Puntos BLUE misión actual: " .. tostring(missionState.blueMissionPoints)

                if blueTotal then
                    text = text .. "\nTotal BLUE: " .. tostring(blueTotal)
                end

                msgBlue(text, 18)

                log(
                    "DEAD puntuado | " ..
                    tostring(unitName) ..
                    " | BLUE +" ..
                    tostring(points)
                )

                return
            end
        end
    end
end

-- ============================================================
-- EVENT HANDLER
-- ============================================================

function SIMPLE_MISSIONS.OnEvent(event)

    if not event then return end
    if event.id ~= world.event.S_EVENT_DEAD then return end
    if not event.initiator then return end

    local ok, unitName = pcall(function()
        return event.initiator:getName()
    end)

    if ok and unitName then
        SIMPLE_MISSIONS.ScoreDead(unitName)
    end
end

function SIMPLE_MISSIONS.InstallEventHandler()

    SIMPLE_MISSIONS.eventHandler = {
        onEvent = function(self, event)
            local ok, err = pcall(function()
                SIMPLE_MISSIONS.OnEvent(event)
            end)

            if not ok then
                log("ERROR OnEvent: " .. tostring(err))
            end
        end
    }

    world.addEventHandler(SIMPLE_MISSIONS.eventHandler)

    log("Event handler instalado. Puntaje por DEAD activo.")
end

-- ============================================================
-- ASIGNAR RUTA SIN LAG
-- ============================================================

function SIMPLE_MISSIONS.AssignRoute(data)

    if not data then return nil end
    if not data.spawnedGroup then return nil end
    if not data.destinationCoord then return nil end

    local okRoute, routeErr = pcall(function()
        data.spawnedGroup:RouteGroundTo(
            data.destinationCoord,
            data.speedKmh,
            data.routeFormation,
            0
        )
    end)

    if not okRoute then
        msgBlue(
            "ERROR:\n" ..
            "El grupo fue creado, pero no recibió ruta RouteGroundTo.\n" ..
            "Revisa DCS.log.",
            20
        )

        log("ERROR RouteGroundTo: " .. tostring(routeErr))
        return nil
    end

    msgBlue(
        "MISIÓN TERRESTRE\n\n" ..
        "Ruta asignada.\n" ..
        "Método: RouteGroundTo\n" ..
        "Formación: " .. tostring(data.routeFormation) .. "\n" ..
        "Destino: " .. tostring(data.destinationZone) .. "\n" ..
        "Velocidad: " .. tostring(data.speedKmh) .. " km/h",
        12
    )

    log("Ruta asignada a " .. tostring(data.groupName))

    return nil
end

-- ============================================================
-- MONITOREAR LLEGADA A DESTINO
-- ============================================================

function SIMPLE_MISSIONS.MonitorMission(missionId)

    local missionState = SIMPLE_MISSIONS.active[missionId]

    if not missionState or not missionState.active then
        return nil
    end

    local mission = missionState.mission
    local group = Group.getByName(missionState.groupName)

    if not group or not group:isExist() then
        missionState.active = false
        return nil
    end

    local units = group:getUnits()
    local aliveCount = 0

    for _, unit in ipairs(units) do
        if unit and unit:isExist() and unit:getLife() > 0 then

            aliveCount = aliveCount + 1

            local unitPoint = unit:getPoint()
            local distance = dist2D(unitPoint, missionState.destinationPoint)

            if distance <= missionState.destinationRadius then

                if not missionState.arrivalScored then

                    missionState.arrivalScored = true

                    missionState.blueMissionPoints =
                        missionState.blueMissionPoints + mission.arrivalBluePoints

                    missionState.redMissionPoints =
                        missionState.redMissionPoints + mission.arrivalRedPoints

                    local blueTotal = SIMPLE_MISSIONS.AddCampaignPoints(
                        mission,
                        "BLUE",
                        mission.arrivalBluePoints,
                        "Grupo entró a zona destino " .. tostring(mission.destinationZone),
                        {
                            missionId = missionId,
                            event = "ARRIVAL",
                            destinationZone = mission.destinationZone
                        }
                    )

                    local redTotal = SIMPLE_MISSIONS.AddCampaignPoints(
                        mission,
                        "RED",
                        mission.arrivalRedPoints,
                        "Grupo entró a zona destino " .. tostring(mission.destinationZone),
                        {
                            missionId = missionId,
                            event = "ARRIVAL",
                            destinationZone = mission.destinationZone
                        }
                    )

                    msgBlue(
                        "MISIÓN TERRESTRE\n\n" ..
                        "MISIÓN FALLIDA.\n" ..
                        "El grupo entró a la zona destino:\n" ..
                        tostring(mission.destinationZone) .. "\n\n" ..
                        "Misión: " .. tostring(mission.menuName) .. "\n\n" ..
                        "BLUE " .. tostring(mission.arrivalBluePoints) .. " puntos\n" ..
                        "RED +" .. tostring(mission.arrivalRedPoints) .. " puntos\n\n" ..
                        "Puntos BLUE misión actual: " .. tostring(missionState.blueMissionPoints) .. "\n" ..
                        "Puntos RED misión actual: " .. tostring(missionState.redMissionPoints) .. "\n\n" ..
                        "Total BLUE: " .. tostring(blueTotal or "N/A") .. "\n" ..
                        "Total RED: " .. tostring(redTotal or "N/A"),
                        25
                    )

                    log(
                        "Grupo llegó a destino | " ..
                        tostring(missionId) ..
                        " | BLUE " ..
                        tostring(mission.arrivalBluePoints) ..
                        " | RED +" ..
                        tostring(mission.arrivalRedPoints)
                    )
                end

                missionState.active = false
                return nil
            end
        end
    end

    if aliveCount <= 0 then
        msgBlue(
            "MISIÓN TERRESTRE\n\n" ..
            "MISIÓN CUMPLIDA.\n" ..
            "El grupo fue destruido antes de llegar a destino.\n\n" ..
            "Misión: " .. tostring(mission.menuName) .. "\n" ..
            "Puntos BLUE misión actual: " .. tostring(missionState.blueMissionPoints),
            25
        )

        missionState.active = false
        return nil
    end

    return timer.getTime() + mission.monitorSeconds
end

-- ============================================================
-- MENSAJE TÁCTICO
-- ============================================================

function SIMPLE_MISSIONS.SendTacticalMessage(mission, spawnZoneName, spawnZone, destinationZone, missionState)

    local distanceMeters = dist2D(spawnZone.point, destinationZone.point)
    local distanceNm = metersToNM(distanceMeters)

    local detectedTarget = "NO DETECTADO"

    if missionState and missionState.mainTargetUnitName then
        detectedTarget = missionState.mainTargetUnitName
    end

    msgBlue(
        "MISIÓN ACTIVADA\n\n" ..
        "Tipo: " .. tostring(mission.menuSub) .. "\n" ..
        "Misión: " .. tostring(mission.menuName) .. "\n\n" ..

        "INICIO:\n" ..
        "Spawn: " .. tostring(spawnZoneName) .. "\n" ..
        "MGRS: " .. vec3ToMGRS(spawnZone.point) .. "\n\n" ..

        "DESTINO:\n" ..
        "Zona: " .. tostring(mission.destinationZone) .. "\n" ..
        "MGRS: " .. vec3ToMGRS(destinationZone.point) .. "\n\n" ..

        "NAVEGACIÓN:\n" ..
        "Distancia directa: " .. string.format("%.1f", distanceNm) .. " NM\n" ..
        "Velocidad: " .. tostring(mission.speedKmh) .. " km/h\n" ..
        "Ruta: RouteGroundTo / Formación " .. tostring(mission.routeFormation) .. "\n\n" ..

        "OBJETIVO:\n" ..
        "Localizar y destruir el grupo enemigo.\n" ..
        "Blanco principal: " .. tostring(mission.mainTargetName) .. "\n" ..
        "Unidad detectada: " .. tostring(detectedTarget) .. "\n\n" ..

        "PUNTAJE:\n" ..
        "- Blanco principal DEAD: BLUE +" .. tostring(mission.mainTargetPoints) .. "\n" ..
        "- Otros DEAD: BLUE +" .. tostring(mission.opportunityPoints) .. " c/u\n" ..
        "- Si entra a destino: BLUE " .. tostring(mission.arrivalBluePoints) ..
        " / RED +" .. tostring(mission.arrivalRedPoints),
        45
    )
end

-- ============================================================
-- INICIAR MISIÓN
-- ============================================================

function SIMPLE_MISSIONS.StartMission(mission)

    if SIMPLE_MISSIONS.active[mission.id] and SIMPLE_MISSIONS.active[mission.id].active then
        msgBlue("Ya hay una misión activa: " .. tostring(mission.menuName), 15)
        return
    end

    if not SPAWN or not COORDINATE then
        msgBlue("ERROR: MOOSE no está cargado antes de este script.", 20)
        return
    end

    local destinationZone = getZone(mission.destinationZone)

    if not destinationZone or not destinationZone.point then
        msgBlue(
            "ERROR:\nNo existe la zona destino:\n" ..
            tostring(mission.destinationZone),
            20
        )
        return
    end

    local destinationCoord = getCoordinateFromZone(mission.destinationZone)

    if not destinationCoord then
        msgBlue("ERROR: No pude convertir la zona destino a coordenada MOOSE.", 20)
        return
    end

    local spawnZoneName = pickRandomSpawnZone(mission)

    if not spawnZoneName then
        msgBlue("ERROR: No hay zonas de spawn definidas.", 20)
        return
    end

    local spawnZone = getZone(spawnZoneName)

    if not spawnZone or not spawnZone.point then
        msgBlue(
            "ERROR:\nNo existe la zona de spawn:\n" ..
            tostring(spawnZoneName),
            20
        )
        return
    end

    local spawnCoord = getCoordinateFromZone(spawnZoneName)

    if not spawnCoord then
        msgBlue("ERROR: No pude convertir la zona de spawn a coordenada MOOSE.", 20)
        return
    end

    local spawnedGroup = nil

    local okSpawn, spawnResult = pcall(function()
        return SPAWN:New(mission.templateName):SpawnFromCoordinate(spawnCoord)
    end)

    if okSpawn and spawnResult then
        spawnedGroup = spawnResult
    else
        msgBlue(
            "ERROR:\nNo se pudo spawnear el template:\n" ..
            tostring(mission.templateName),
            20
        )

        log("ERROR Spawn: " .. tostring(spawnResult))
        return
    end

    local groupName = spawnedGroup:GetName()

    SIMPLE_MISSIONS.active[mission.id] = {
        active = true,
        mission = mission,
        groupName = groupName,

        destinationPoint = destinationZone.point,
        destinationRadius = destinationZone.radius or 700,

        units = {},
        arrivalScored = false,
        blueMissionPoints = 0,
        redMissionPoints = 0,

        mainTargetDetected = false,
        mainTargetUnitName = nil
    }

    SIMPLE_MISSIONS.RegisterUnits(mission, groupName)

    local missionState = SIMPLE_MISSIONS.active[mission.id]

    SIMPLE_MISSIONS.SendTacticalMessage(
        mission,
        spawnZoneName,
        spawnZone,
        destinationZone,
        missionState
    )

    timer.scheduleFunction(
        SIMPLE_MISSIONS.AssignRoute,
        {
            missionId = mission.id,
            spawnedGroup = spawnedGroup,
            groupName = groupName,
            destinationCoord = destinationCoord,
            destinationZone = mission.destinationZone,
            speedKmh = mission.speedKmh,
            routeFormation = mission.routeFormation or "Off Road"
        },
        timer.getTime() + (mission.routeDelaySeconds or 5)
    )

    timer.scheduleFunction(
        SIMPLE_MISSIONS.MonitorMission,
        mission.id,
        timer.getTime() + mission.monitorSeconds
    )

    log(
        "Misión iniciada: " ..
        tostring(mission.id) ..
        " | Grupo: " ..
        tostring(groupName) ..
        " | Spawn random: " ..
        tostring(spawnZoneName)
    )
end

function SIMPLE_MISSIONS.StartMissionSafe(mission)

    local ok, err = pcall(function()
        SIMPLE_MISSIONS.StartMission(mission)
    end)

    if not ok then
        msgBlue(
            "ERROR SIMPLE_MISSIONS:\n" ..
            tostring(err),
            25
        )

        log("ERROR StartMissionSafe: " .. tostring(err))
    end
end

-- ============================================================
-- MENÚS
-- ============================================================

function SIMPLE_MISSIONS.CreateMenus()

    local rootMenus = {}
    local subMenus = {}

    for _, mission in ipairs(SIMPLE_MISSIONS.list) do

        if not rootMenus[mission.menuRoot] then
            rootMenus[mission.menuRoot] = missionCommands.addSubMenuForCoalition(
                coalition.side.BLUE,
                mission.menuRoot
            )
        end

        local subKey = mission.menuRoot .. "/" .. mission.menuSub

        if not subMenus[subKey] then
            subMenus[subKey] = missionCommands.addSubMenuForCoalition(
                coalition.side.BLUE,
                mission.menuSub,
                rootMenus[mission.menuRoot]
            )
        end

        local missionRef = mission

        missionCommands.addCommandForCoalition(
            coalition.side.BLUE,
            mission.menuName,
            subMenus[subKey],
            function()
                SIMPLE_MISSIONS.StartMissionSafe(missionRef)
            end
        )
    end

    msgBlue(
        "SIMPLE MISSIONS SCORE V3 cargado.\n" ..
        "F10 / Menu de Campaña",
        10
    )

    log("Menús F10 creados.")
end

-- ============================================================
-- INIT
-- ============================================================

do
    SIMPLE_MISSIONS.InstallEventHandler()
    SIMPLE_MISSIONS.CreateMenus()

    log("SIMPLE_DYNAMIC_GROUND_MISSIONS_SCORE_V3.lua cargado.")
end