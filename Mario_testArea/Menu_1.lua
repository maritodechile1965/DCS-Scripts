--[[ Perfecto. Esta sería la **primera versión funcional** del menú:

```text id="l3wqhr"
F10 Other
└── Menu de Campa
    ├── 00 - Tierra / Servicios
    │   ├── Rearm & Refuel
    │   ├── Request Repair
    │   ├── Wheel Chocks
    │   │   ├── Wheel Chocks ON
    │   │   └── Wheel Chocks OFF
    │   ├── Carrier / F-18
    │   │   ├── Salute
    │   │   └── Request Launch
    │   ├── Change Helmet Mounted Device / NVG
    │   └── Previous Menu
    │
    └── 10 - ATC
        ├── En Tierra / Despegue
        │   ├── Request Taxi
        │   └── Request Takeoff
        │
        └── En Aire / Aterrizaje
            ├── Callsign - Aproximando
            ├── Callsign - Solicito circuito de aproximacion
            ├── Callsign - Inicial
            ├── Callsign - Final
            ├── Callsign - Landing
            └── Callsign - Taxi a la plataforma
```

Punto importante: por ahora este menú **no reemplaza el menú nativo de DCS**. Crea un menú propio dentro de **F10 Other**. Las opciones como `Rearm & Refuel`, `Request Repair`, `Salute`, `Request Launch`, etc., por ahora muestran mensajes de prueba. Después las podemos conectar a flags, stock logístico, carrier ops, ATC propio, etc.

---

# Script completo v0.1

Guárdalo como:

```text id="59keiy"
HYDRA_Menu_Campa_v01.lua
```

Y cárgalo en Mission Editor con:

```text id="fpggm9"
TRIGGER:
MISSION START
DO SCRIPT FILE:
HYDRA_Menu_Campa_v01.lua
```
```lua id="9bbcpn"
--]]


-- ======================================================================
-- HYDRA / DCS - MENU DE CAMPAÑA
-- Autor: Zeus para Marte
-- Version: v0.1
--
-- Menu principal:
--   F10 Other -> Menu de Campa
--
-- Objetivo:
--   Crear primer menu general de campaña para todos los pilotos.
--   Incluye servicios de tierra y ATC basico.
--
-- Nota:
--   Este script NO reemplaza el menu nativo de DCS.
--   Crea un menu propio dentro de F10 Other.
-- ======================================================================

HYDRA_MENU_CAMPA = {}
HYDRA_MENU_CAMPA.version = "v0.1"
HYDRA_MENU_CAMPA.debug = true
HYDRA_MENU_CAMPA.groupMenus = {}

-- ======================================================================
-- UTILIDADES
-- ======================================================================

function HYDRA_MENU_CAMPA:Log(text)
    if self.debug then
        env.info("[HYDRA_MENU_CAMPA] " .. tostring(text))
    end
end

function HYDRA_MENU_CAMPA:MsgToGroup(groupId, text, seconds)
    if groupId then
        trigger.action.outTextForGroup(groupId, text, seconds or 10)
    end
end

function HYDRA_MENU_CAMPA:GetPlayerName(unit)
    if not unit then return nil end

    local ok, name = pcall(function()
        return unit:getPlayerName()
    end)

    if ok then
        return name
    end

    return nil
end

function HYDRA_MENU_CAMPA:GetUnitType(unit)
    if not unit then return "UNKNOWN" end

    local ok, typeName = pcall(function()
        return unit:getTypeName()
    end)

    if ok and typeName then
        return typeName
    end

    return "UNKNOWN"
end

function HYDRA_MENU_CAMPA:GetCallsign(unit)
    if not unit then return "Callsign" end

    local ok, callsign = pcall(function()
        return unit:getCallsign()
    end)

    if ok and callsign then
        return callsign
    end

    local playerName = self:GetPlayerName(unit)
    if playerName then
        return playerName
    end

    local group = unit:getGroup()
    if group then
        return group:getName()
    end

    return "Callsign"
end

function HYDRA_MENU_CAMPA:IsUnitInAir(unit)
    if not unit then return false end

    local ok, result = pcall(function()
        return unit:inAir()
    end)

    if ok then
        return result
    end

    return false
end

function HYDRA_MENU_CAMPA:GetUnitFromData(data)
    if not data then return nil end
    if not data.unitName then return nil end

    local unit = Unit.getByName(data.unitName)
    if unit and unit:isExist() then
        return unit
    end

    return nil
end

function HYDRA_MENU_CAMPA:AddCommand(groupId, groupName, unitName, text, path, actionId)
    return missionCommands.addCommandForGroup(
        groupId,
        text,
        path,
        function(data)
            HYDRA_MENU_CAMPA:Action(data)
        end,
        {
            gid = groupId,
            groupName = groupName,
            unitName = unitName,
            action = actionId,
            label = text
        }
    )
end

-- ======================================================================
-- ACCIONES DEL MENU
-- Por ahora son mensajes de prueba.
-- Despues conectamos aqui logistica, ATC, carrier, flags, etc.
-- ======================================================================

function HYDRA_MENU_CAMPA:Action(data)
    if not data then return end

    local groupId = data.gid
    local action = data.action or "NO_ACTION"
    local label = data.label or action
    local unit = self:GetUnitFromData(data)
    local callsign = self:GetCallsign(unit)
    local typeName = self:GetUnitType(unit)
    local inAir = self:IsUnitInAir(unit)

    self:Log("Accion seleccionada: " .. tostring(action))

    -- ==============================================================
    -- TIERRA / SERVICIOS
    -- ==============================================================

    if action == "GROUND_REARM_REFUEL" then

        if inAir then
            self:MsgToGroup(groupId, "Menu de Campa\nRearm & Refuel solo disponible en tierra.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. " solicita Rearm & Refuel.\n" ..
            "Aeronave: " .. typeName .. "\n" ..
            "Estado: solicitud registrada.",
            10
        )
        return
    end

    if action == "GROUND_REQUEST_REPAIR" then

        if inAir then
            self:MsgToGroup(groupId, "Menu de Campa\nRequest Repair solo disponible en tierra.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. " solicita reparacion.\n" ..
            "Estado: solicitud registrada.",
            10
        )
        return
    end

    if action == "GROUND_CHOCKS_ON" then

        if inAir then
            self:MsgToGroup(groupId, "Menu de Campa\nWheel Chocks solo disponible en tierra.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. ": Wheel Chocks ON.\n" ..
            "Estado: orden registrada.",
            10
        )
        return
    end

    if action == "GROUND_CHOCKS_OFF" then

        if inAir then
            self:MsgToGroup(groupId, "Menu de Campa\nWheel Chocks solo disponible en tierra.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. ": Wheel Chocks OFF.\n" ..
            "Estado: orden registrada.",
            10
        )
        return
    end

    if action == "GROUND_SALUTE" then

        if inAir then
            self:MsgToGroup(groupId, "Menu de Campa\nSalute solo disponible en tierra / carrier.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. ": Salute solicitado.\n" ..
            "Nota: esta es una accion propia del menu HYDRA, no el menu nativo del carrier.",
            10
        )
        return
    end

    if action == "GROUND_REQUEST_LAUNCH" then

        if inAir then
            self:MsgToGroup(groupId, "Menu de Campa\nRequest Launch solo disponible en tierra / carrier.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. ": Request Launch solicitado.\n" ..
            "Estado: solicitud registrada.",
            10
        )
        return
    end

    if action == "GROUND_HMD_NVG" then

        self:MsgToGroup(
            groupId,
            "Menu de Campa\n" ..
            callsign .. ": solicitud de cambio Helmet Mounted Device / NVG registrada.",
            10
        )
        return
    end

    if action == "PREVIOUS_MENU" then
        self:MsgToGroup(
            groupId,
            "Menu de Campa\nUsa la opcion nativa de DCS para volver al menu anterior.\nEste boton queda como referencia visual.",
            10
        )
        return
    end

    -- ==============================================================
    -- ATC - EN TIERRA / DESPEGUE
    -- ==============================================================

    if action == "ATC_REQUEST_TAXI" then

        if inAir then
            self:MsgToGroup(groupId, "ATC\nRequest Taxi solo disponible en tierra.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Request Taxi.\n" ..
            "ATC: solicitud de rodaje recibida.",
            10
        )
        return
    end

    if action == "ATC_REQUEST_TAKEOFF" then

        if inAir then
            self:MsgToGroup(groupId, "ATC\nRequest Takeoff solo disponible antes del despegue.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Request Takeoff.\n" ..
            "ATC: solicitud de despegue recibida.",
            10
        )
        return
    end

    -- ==============================================================
    -- ATC - EN AIRE / ATERRIZAJE
    -- ==============================================================

    if action == "ATC_APPROACHING" then

        if not inAir then
            self:MsgToGroup(groupId, "ATC\nAproximando se usa normalmente en vuelo.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Aproximando.\n" ..
            "ATC: recibido, continue aproximacion.",
            10
        )
        return
    end

    if action == "ATC_REQUEST_PATTERN" then

        if not inAir then
            self:MsgToGroup(groupId, "ATC\nSolicitud de circuito se usa normalmente en vuelo.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": solicito circuito de aproximacion.\n" ..
            "ATC: recibido, ingrese al circuito publicado.",
            10
        )
        return
    end

    if action == "ATC_INITIAL" then

        if not inAir then
            self:MsgToGroup(groupId, "ATC\nInicial se reporta normalmente en vuelo.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Inicial.\n" ..
            "ATC: recibido Inicial.",
            10
        )
        return
    end

    if action == "ATC_FINAL" then

        if not inAir then
            self:MsgToGroup(groupId, "ATC\nFinal se reporta normalmente en vuelo.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Final.\n" ..
            "ATC: recibido Final.",
            10
        )
        return
    end

    if action == "ATC_LANDING" then

        if not inAir then
            self:MsgToGroup(groupId, "ATC\nLanding se reporta normalmente en vuelo.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Landing.\n" ..
            "ATC: aterrizaje registrado.",
            10
        )
        return
    end

    if action == "ATC_TAXI_TO_RAMP" then

        if inAir then
            self:MsgToGroup(groupId, "ATC\nTaxi a plataforma solo disponible despues de aterrizar.", 10)
            return
        end

        self:MsgToGroup(
            groupId,
            "ATC\n" ..
            callsign .. ": Taxi a la plataforma.\n" ..
            "ATC: autorizado a plataforma segun instrucciones locales.",
            10
        )
        return
    end

    -- ==============================================================
    -- FALLBACK
    -- ==============================================================

    self:MsgToGroup(
        groupId,
        "Menu de Campa\nSeleccionado: " .. tostring(label),
        10
    )
end

-- ======================================================================
-- LIMPIEZA DE MENU
-- ======================================================================

function HYDRA_MENU_CAMPA:RemoveMenuForGroup(group)
    if not group then return end

    local groupName = group:getName()
    local groupId = group:getID()

    if self.groupMenus[groupName] and self.groupMenus[groupName].root then
        missionCommands.removeItemForGroup(groupId, self.groupMenus[groupName].root)
        self.groupMenus[groupName] = nil
        self:Log("Menu eliminado para grupo: " .. groupName)
    end
end

-- ======================================================================
-- CONSTRUCCION DEL MENU
-- ======================================================================

function HYDRA_MENU_CAMPA:BuildGroundMenu(groupId, groupName, unitName, root)
    local ground = missionCommands.addSubMenuForGroup(
        groupId,
        "00 - Tierra / Servicios",
        root
    )

    self:AddCommand(groupId, groupName, unitName, "Rearm & Refuel", ground, "GROUND_REARM_REFUEL")
    self:AddCommand(groupId, groupName, unitName, "Request Repair", ground, "GROUND_REQUEST_REPAIR")

    local chocks = missionCommands.addSubMenuForGroup(
        groupId,
        "Wheel Chocks",
        ground
    )

    self:AddCommand(groupId, groupName, unitName, "Wheel Chocks ON", chocks, "GROUND_CHOCKS_ON")
    self:AddCommand(groupId, groupName, unitName, "Wheel Chocks OFF", chocks, "GROUND_CHOCKS_OFF")

    local carrier = missionCommands.addSubMenuForGroup(
        groupId,
        "Carrier / F-18",
        ground
    )

    self:AddCommand(groupId, groupName, unitName, "Salute", carrier, "GROUND_SALUTE")
    self:AddCommand(groupId, groupName, unitName, "Request Launch", carrier, "GROUND_REQUEST_LAUNCH")

    self:AddCommand(
        groupId,
        groupName,
        unitName,
        "Change Helmet Mounted Device / NVG",
        ground,
        "GROUND_HMD_NVG"
    )

    self:AddCommand(groupId, groupName, unitName, "Previous Menu", ground, "PREVIOUS_MENU")
end

function HYDRA_MENU_CAMPA:BuildATCMenu(groupId, groupName, unitName, root)
    local atc = missionCommands.addSubMenuForGroup(
        groupId,
        "10 - ATC",
        root
    )

    local groundATC = missionCommands.addSubMenuForGroup(
        groupId,
        "En Tierra / Despegue",
        atc
    )

    self:AddCommand(groupId, groupName, unitName, "Request Taxi", groundATC, "ATC_REQUEST_TAXI")
    self:AddCommand(groupId, groupName, unitName, "Request Takeoff", groundATC, "ATC_REQUEST_TAKEOFF")

    local airATC = missionCommands.addSubMenuForGroup(
        groupId,
        "En Aire / Aterrizaje",
        atc
    )

    self:AddCommand(groupId, groupName, unitName, "Callsign - Aproximando", airATC, "ATC_APPROACHING")
    self:AddCommand(groupId, groupName, unitName, "Callsign - Solicito circuito de aproximacion", airATC, "ATC_REQUEST_PATTERN")
    self:AddCommand(groupId, groupName, unitName, "Callsign - Inicial", airATC, "ATC_INITIAL")
    self:AddCommand(groupId, groupName, unitName, "Callsign - Final", airATC, "ATC_FINAL")
    self:AddCommand(groupId, groupName, unitName, "Callsign - Landing", airATC, "ATC_LANDING")
    self:AddCommand(groupId, groupName, unitName, "Callsign - Taxi a la plataforma", airATC, "ATC_TAXI_TO_RAMP")
end

function HYDRA_MENU_CAMPA:CreateMenuForUnit(unit)
    if not unit then return end

    local playerName = self:GetPlayerName(unit)
    if not playerName then
        return
    end

    local group = unit:getGroup()
    if not group then return end

    local groupName = group:getName()
    local groupId = group:getID()
    local unitName = unit:getName()
    local typeName = self:GetUnitType(unit)

    -- Evita duplicados
    self:RemoveMenuForGroup(group)

    local root = missionCommands.addSubMenuForGroup(
        groupId,
        "Menu de Campa",
        nil
    )

    self.groupMenus[groupName] = {
        root = root,
        groupId = groupId,
        groupName = groupName,
        unitName = unitName,
        playerName = playerName,
        typeName = typeName
    }

    self:BuildGroundMenu(groupId, groupName, unitName, root)
    self:BuildATCMenu(groupId, groupName, unitName, root)

    self:MsgToGroup(
        groupId,
        "Menu de Campa activo.\n" ..
        "Piloto: " .. tostring(playerName) .. "\n" ..
        "Aeronave: " .. tostring(typeName),
        8
    )

    self:Log("Menu creado para grupo: " .. groupName .. " / " .. typeName)
end

function HYDRA_MENU_CAMPA:CreateMenuForUnitName(unitName)
    if not unitName then return end

    local unit = Unit.getByName(unitName)
    if unit and unit:isExist() then
        self:CreateMenuForUnit(unit)
    end
end

-- ======================================================================
-- ESCANEO DE JUGADORES ACTIVOS
-- Sirve si el script se carga cuando algun piloto ya esta en cabina.
-- ======================================================================

function HYDRA_MENU_CAMPA:ScanActivePlayers()
    local sides = {
        coalition.side.BLUE,
        coalition.side.RED
    }

    local categories = {
        Group.Category.AIRPLANE,
        Group.Category.HELICOPTER
    }

    for _, side in ipairs(sides) do
        for _, cat in ipairs(categories) do
            local groups = coalition.getGroups(side, cat)

            if groups then
                for _, group in pairs(groups) do
                    if group and group:isExist() then
                        local units = group:getUnits()

                        if units then
                            for _, unit in pairs(units) do
                                if unit and unit:isExist() and self:GetPlayerName(unit) then
                                    self:CreateMenuForUnit(unit)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ======================================================================
-- EVENT HANDLER
-- Crea menu cuando nace un jugador.
-- ======================================================================

HYDRA_MENU_CAMPA.EventHandler = {}

function HYDRA_MENU_CAMPA.EventHandler:onEvent(event)
    if not event then return end
    if not event.initiator then return end

    if event.id == world.event.S_EVENT_BIRTH then
        local unit = event.initiator

        if not unit then return end
        if not unit:isExist() then return end

        local playerName = HYDRA_MENU_CAMPA:GetPlayerName(unit)

        if playerName then
            local unitName = unit:getName()

            timer.scheduleFunction(
                function(args)
                    HYDRA_MENU_CAMPA:CreateMenuForUnitName(args.unitName)
                    return nil
                end,
                { unitName = unitName },
                timer.getTime() + 2
            )
        end
    end
end

-- ======================================================================
-- INIT
-- ======================================================================

function HYDRA_MENU_CAMPA:Init()
    world.addEventHandler(self.EventHandler)

    timer.scheduleFunction(
        function()
            HYDRA_MENU_CAMPA:ScanActivePlayers()
            return nil
        end,
        nil,
        timer.getTime() + 5
    )

    self:Log("Inicializado " .. self.version)

    trigger.action.outText(
        "HYDRA Menu de Campa cargado " .. self.version,
        10
    )
end

HYDRA_MENU_CAMPA:Init()
--[[

---

## Qué vas a ver en DCS

Cuando entres a un avión o helicóptero como cliente/player:

```text id="krz8ld"
F10 Other
└── Menu de Campa
```

Y dentro:

```text id="xb6lnt"
00 - Tierra / Servicios
10 - ATC
```

Por ahora, al seleccionar una opción, aparecerá un mensaje como:

```text id="c07mty"
ATC
Ford 1-1: Request Taxi.
ATC: solicitud de rodaje recibida.
```

o:

```text id="k3xke8"
Menu de Campa
Ford 1-1 solicita Rearm & Refuel.
Aeronave: FA-18C_hornet
Estado: solicitud registrada.
```

---

## Observaciones importantes

`Previous Menu` no puede forzar realmente la navegación hacia atrás, porque eso lo maneja el menú interno de radio de DCS. Lo dejé como referencia visual, pero DCS ya tiene su propia opción de volver al menú anterior.

`Salute`, `Request Launch`, `Rearm & Refuel`, `Request Repair`, `Wheel Chocks` y `Change Helmet Mounted Device / NVG` todavía no ejecutan la acción nativa de DCS. Son comandos propios de campaña. Más adelante podemos hacer que activen:

```text id="0l82p3"
- flags
- mensajes al ATC
- consumo de recursos de base
- permisos de salida
- permisos de carrier
- registro del piloto
- bloqueo/desbloqueo lógico de misión
```

Para la versión siguiente, yo agregaría una tabla de configuración para que el menú se pueda activar solo en bases, FARPs o carriers específicos.
--]]