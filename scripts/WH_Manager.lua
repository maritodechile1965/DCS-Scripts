--[[
====================================================================
 WH_Manager.lua  Warehouse Manager NIVEL 1
 Gestiona el stock de combustible de las bases azules.
 Lee el estado via MOOSE STORAGE (wrapper del DCS warehouse nativo).

 Funciones:
   - Lectura de fuel por base cada CHECK_INTERVAL segundos
   - Umbrales: WARNING (30.000 lbs) y BLOCKED (5.000 lbs)
   - Avisos automticos en pantalla cuando cambia el estado
   - Men F10 para consultar stock de cada base

 REQUISITO EN EL MISSION EDITOR:
   Cada base que quieras monitorear debe tener "Limited Stock"
   habilitado en su pestaa Warehouse (click derecho en la base
    Properties  Warehouse  activar "Limited Stock").
   Sin esto DCS reporta stock infinito y los umbrales no aplican.

 Dependencias: Moose.lua  EVT_Dispatcher.lua  DATA_Core.lua
 Versin: v1  Nivel 1 (solo lectura y avisos)
====================================================================
]]

WH_Manager = {}

--------------------------------------------------------------------
-- CONFIGURACIN
--------------------------------------------------------------------

-- Intervalo de chequeo en segundos (60 = cada 1 minuto)
WH_Manager.CHECK_INTERVAL = 60

-- Umbrales de combustible (en libras)
WH_Manager.FUEL_WARNING_LBS = 30000  -- aviso en pantalla
WH_Manager.FUEL_BLOCKED_LBS = 5000   -- base bloqueada para misiones de ataque

-- Coalicin que ve los mensajes del Warehouse
WH_Manager.COALITION = coalition.side.BLUE

--------------------------------------------------------------------
-- BASES MONITOREADAS
-- dcsName: nombre EXACTO de la base en DCS (como aparece en el ME)
-- hub: true = base principal (siempre abastecida), false = base avanzada
-- node: ID del nodo en CAMP_Net (para futuras integraciones)
--------------------------------------------------------------------

WH_Manager.BASES = {
  -- HUBS principales (siempre deben tener stock)
  { id="AKRO",   dcsName="Akrotiri",              label="Akrotiri",      hub=true  },
  { id="CVN73",  dcsName="BLUE_CVN73_GROUP",      label="CVN-73",        hub=true  },
  { id="RAMAT",  dcsName="Ramat David",           label="Ramat David",   hub=true  },
  -- Bases Chipre
  { id="PAPHOS", dcsName="Paphos",                label="Paphos",        hub=false },
  { id="LARNA",  dcsName="Larnaca",               label="Larnaca",       hub=false },
  { id="KINGS",  dcsName="Lakatamia",             label="Lakatamia",     hub=false },
  { id="GECIT",  dcsName="Gecitkale",             label="Gecitkale",     hub=false },
  { id="ERKAN",  dcsName="Ercan",                 label="Ercan",         hub=false },
  -- Bases Israel
  { id="SHEMER", dcsName="Eyn Shemer",            label="Eyn Shemer",    hub=false },
  { id="HERZI",  dcsName="Herzliya",              label="Herzliya",      hub=false },
  { id="TELNOF", dcsName="Tel Nof",               label="Tel Nof",       hub=false },
  { id="HATZOR", dcsName="Hatzor",                label="Hatzor",        hub=false },
  { id="TEYMAN", dcsName="Teyman",                label="Teyman",        hub=false },
  { id="NEVATIM",dcsName="Nevatim",               label="Nevatim",       hub=false },
}

-- Tabla interna de estado por base
-- { fuel=number, status="ok"|"warning"|"blocked", lastNotify="ok"|"warning"|"blocked" }
WH_Manager._status = {}

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------

local function _msg(text, seconds)
  trigger.action.outTextForCoalition(
    WH_Manager.COALITION,
    text,
    seconds or 15
  )
end

-- Convierte libras a un string legible
local function _fuelStr(lbs)
  if not lbs or lbs <= 0 then return "N/A" end
  if lbs >= 1000 then
    return string.format("%.1f k lbs", lbs / 1000)
  end
  return string.format("%d lbs", math.floor(lbs))
end

-- Determina el estado segn los umbrales
local function _getStatus(fuelLbs)
  if not fuelLbs or fuelLbs <= WH_Manager.FUEL_BLOCKED_LBS then
    return "blocked"
  elseif fuelLbs <= WH_Manager.FUEL_WARNING_LBS then
    return "warning"
  end
  return "ok"
end

-- Estado en ASCII puro (DCS no soporta UTF-8 en textos F10/outText)
local function _statusLabel(status)
  if status == "blocked" then return "[BLOQUEADA]" end
  if status == "warning"  then return "[ AVISO   ]" end
  return                                "[ OK      ]"
end

--------------------------------------------------------------------
-- LECTURA DE STOCK VIA MOOSE STORAGE
--------------------------------------------------------------------

-- Lee el combustible de una base via MOOSE AIRBASE:GetStorage().
-- Retorna el valor en libras, o nil si la base no est disponible.
local function _readFuel(dcsName)
  -- Obtener objeto AIRBASE de MOOSE
  local ok1, ab = pcall(function()
    return AIRBASE:FindByName(dcsName)
  end)
  if not ok1 or not ab then
    return nil
  end

  -- Obtener STORAGE (wrapper del DCS warehouse nativo)
  local ok2, storage = pcall(function()
    return ab:GetStorage()
  end)
  if not ok2 or not storage then
    return nil
  end

  -- Leer combustible Jet A (tipo 0 en DCS)
  -- STORAGE usa STORAGE.Liquid.JetA en MOOSE moderno
  local ok3, fuel = pcall(function()
    return storage:GetAmount(STORAGE.Liquid.JetA)
  end)
  if ok3 and fuel then return fuel end

  -- Fallback: intentar con DCS nativo directo
  local ok4, abDCS = pcall(function()
    return Airbase.getByName(dcsName)
  end)
  if ok4 and abDCS then
    local ok5, wh = pcall(function() return abDCS:getWarehouse() end)
    if ok5 and wh then
      local ok6, liq = pcall(function()
        return wh:getLiquidAmount(0)  -- 0 = JetA en DCS nativo
      end)
      if ok6 and liq then return liq end
    end
  end

  return nil
end

--------------------------------------------------------------------
-- CICLO PRINCIPAL DE CHEQUEO
--------------------------------------------------------------------

function WH_Manager.CheckAll()
  local warnings  = {}
  local blocked   = {}
  local recovered = {}

  for _, base in ipairs(WH_Manager.BASES) do
    local fuel   = _readFuel(base.dcsName)
    local status = fuel and _getStatus(fuel) or "unknown"

    -- Inicializar estado si es la primera vez
    if not WH_Manager._status[base.id] then
      WH_Manager._status[base.id] = {
        fuel       = fuel or 0,
        status     = status,
        lastNotify = status,
      }
    end

    local prev = WH_Manager._status[base.id]

    -- Actualizar valores
    prev.fuel   = fuel or prev.fuel
    prev.status = status

    -- Detectar cambios de estado para notificar
    if status ~= prev.lastNotify then
      if status == "blocked" then
        table.insert(blocked, base)
      elseif status == "warning" then
        table.insert(warnings, base)
      elseif status == "ok" and (prev.lastNotify == "warning" or prev.lastNotify == "blocked") then
        table.insert(recovered, base)
      end
      prev.lastNotify = status
    end

    -- Log en dcs.log
    env.info(string.format(
      "WH_Manager :: %s  fuel: %s [%s]",
      base.label,
      fuel and _fuelStr(fuel) or "N/A",
      status
    ))
  end

  -- Notificaciones de cambio de estado
  for _, base in ipairs(blocked) do
    _msg(string.format(
      "*** %s SIN COMBUSTIBLE  Misiones de ataque BLOQUEADAS.\nVuela a otra base o solicita reabastecimiento.",
      base.label
    ), 30)
    env.info("WH_Manager :: BLOQUEADA: " .. base.label)
  end

  for _, base in ipairs(warnings) do
    _msg(string.format(
      "!!! %s - Combustible BAJO (%s). Considera reabastecerte pronto.",
      base.label,
      _fuelStr(WH_Manager._status[base.id].fuel)
    ), 20)
    env.info("WH_Manager :: AVISO bajo fuel: " .. base.label)
  end

  for _, base in ipairs(recovered) do
    _msg(string.format(
      ">>> %s - Combustible repuesto. Misiones disponibles.",
      base.label
    ), 15)
    env.info("WH_Manager :: RECUPERADA: " .. base.label)
  end

  return timer.getTime() + WH_Manager.CHECK_INTERVAL
end

--------------------------------------------------------------------
-- API PBLICA
--------------------------------------------------------------------

--- Retorna el estado actual de una base.
-- @param id string  ID del nodo (ej. "AKRO")
-- @return table|nil  { fuel, status, lastNotify }
function WH_Manager.GetStatus(id)
  return WH_Manager._status[id]
end

--- Retorna true si la base est bloqueada para misiones de ataque.
-- @param id string  ID del nodo
-- @return boolean
function WH_Manager.IsBlocked(id)
  local s = WH_Manager._status[id]
  return s and s.status == "blocked"
end

--- Muestra el stock de todas las bases en pantalla.
function WH_Manager.ShowAllStock()
  local lines = {
    "================================",
    "  COMBUSTIBLE POR BASE",
    "================================",
    string.format("  %-16s %-12s %s", "BASE", "ESTADO", "FUEL"),
    "--------------------------------",
  }
  local hubs = {}
  local fwd  = {}

  for _, base in ipairs(WH_Manager.BASES) do
    local s      = WH_Manager._status[base.id]
    local fuel   = s and s.fuel or 0
    local status = s and s.status or "unknown"
    local line   = string.format("  %-16s %-12s %s",
      base.label,
      _statusLabel(status),
      s and _fuelStr(fuel) or "N/A"
    )
    if base.hub then
      table.insert(hubs, line)
    else
      table.insert(fwd, line)
    end
  end

  table.sort(hubs)
  table.sort(fwd)

  table.insert(lines, "  [HUBS PRINCIPALES]")
  for _, l in ipairs(hubs) do table.insert(lines, l) end
  table.insert(lines, "  [BASES AVANZADAS]")
  for _, l in ipairs(fwd)  do table.insert(lines, l) end
  table.insert(lines, "================================")

  _msg(table.concat(lines, "\n"), 30)
end

--- Muestra solo las bases con stock disponible (no bloqueadas).
function WH_Manager.ShowAvailableBases()
  local lines = {
    "================================",
    "  BASES CON FUEL DISPONIBLE",
    "================================",
    string.format("  %-16s %-12s %s", "BASE", "ESTADO", "FUEL"),
    "--------------------------------",
  }
  local found = false

  for _, base in ipairs(WH_Manager.BASES) do
    local s = WH_Manager._status[base.id]
    if s and s.status ~= "blocked" then
      local prefix = base.hub and "* " or "  "
      table.insert(lines, string.format("%s%-16s %-12s %s",
        prefix,
        base.label,
        _statusLabel(s.status),
        _fuelStr(s.fuel)
      ))
      found = true
    end
  end

  if not found then
    table.insert(lines, "  !!! Sin bases disponibles.")
  end
  table.insert(lines, "================================")
  table.insert(lines, "  (* = Hub principal)")

  _msg(table.concat(lines, "\n"), 25)
end

--------------------------------------------------------------------
-- MENU F10 NIVEL 1
--------------------------------------------------------------------

local _menuRoot = nil  -- referencia al menu raiz para agregar items Nivel 2

local function _buildMenu()
  _menuRoot = missionCommands.addSubMenu("Warehouse / Logistica", nil)

  missionCommands.addCommandForCoalition(
    WH_Manager.COALITION,
    "Ver stock de todas las bases",
    _menuRoot,
    WH_Manager.ShowAllStock
  )

  missionCommands.addCommandForCoalition(
    WH_Manager.COALITION,
    "Bases disponibles con combustible",
    _menuRoot,
    WH_Manager.ShowAvailableBases
  )

  env.info("WH_Manager :: Menu F10 registrado: 'Warehouse / Logistica'")
end

--------------------------------------------------------------------
-- NIVEL 2 - TRANSPORTES IA
--------------------------------------------------------------------

-- Cantidad de fuel entregado por cada transporte al llegar
WH_Manager.FUEL_DELIVERY_LBS = 50000  -- 50.000 lbs por entrega

-- Radio de zona de llegada para detectar entrega (metros)
WH_Manager.ARRIVAL_RADIUS = 8000

-- Rutas de suministro disponibles
-- from/to = ID de base en WH_Manager.BASES
-- template = nombre del grupo late-activated en el ME
-- type     = "c130" | "viking" | "heli"
-- cost     = puntos de coalicion que cuesta la mision
WH_Manager.SUPPLY_ROUTES = {
  -- Akrotiri -> Hubs principales
  { id=1,  from="AKRO",  to="RAMAT",  template="BLUE_AKRO_C-130",  type="c130",  cost=100, label="Akrotiri -> Ramat David  [C-130]" },
  { id=2,  from="AKRO",  to="CVN73",  template="BLUE_AKRO_C-130",  type="c130",  cost=100, label="Akrotiri -> CVN-73        [C-130]" },
  -- CVN-73 -> Bases con Viking
  { id=3,  from="CVN73", to="RAMAT",  template="BLUE_CVN73_VIKING", type="viking", cost=75, label="CVN-73 -> Ramat David      [Viking]" },
  { id=4,  from="CVN73", to="LARNA",  template="BLUE_CVN73_VIKING", type="viking", cost=75, label="CVN-73 -> Larnaca          [Viking]" },
  { id=5,  from="CVN73", to="PAPHOS", template="BLUE_CVN73_VIKING", type="viking", cost=75, label="CVN-73 -> Paphos           [Viking]" },
  -- Ramat David -> Bases avanzadas con C-130
  { id=6,  from="RAMAT", to="HATZOR",  template="BLUE_AKRO_C-130", type="c130",  cost=100, label="Ramat David -> Hatzor      [C-130]" },
  { id=7,  from="RAMAT", to="NEVATIM", template="BLUE_AKRO_C-130", type="c130",  cost=100, label="Ramat David -> Nevatim     [C-130]" },
  { id=8,  from="RAMAT", to="TELNOF",  template="BLUE_AKRO_C-130", type="c130",  cost=100, label="Ramat David -> Tel Nof     [C-130]" },
  -- Ramat David -> Bases peque?as con Heli
  { id=9,  from="RAMAT", to="HERZI",  template="BLUE_RAMAT_UH1H",  type="heli",  cost=50,  label="Ramat David -> Herzliya   [UH-1H]" },
  { id=10, from="RAMAT", to="SHEMER", template="BLUE_RAMAT_UH1H",  type="heli",  cost=50,  label="Ramat David -> Eyn Shemer [UH-1H]" },
  { id=11, from="RAMAT", to="TEYMAN", template="BLUE_RAMAT_UH1H",  type="heli",  cost=50,  label="Ramat David -> Teyman     [UH-1H]" },
}

-- Transportes activos en vuelo
-- { [groupName] = { routeId, fromLabel, toLabel, toId, status, spawned } }
WH_Manager._activeTransports = {}

-- Helper: obtener config de base por ID
local function _getBase(id)
  for _, b in ipairs(WH_Manager.BASES) do
    if b.id == id then return b end
  end
  return nil
end

-- Helper: puntos de coalicion azul actuales
local function _getBluePoints()
  if DATA_Core and DATA_Core.GetCoalitionPoints then
    return DATA_Core.GetCoalitionPoints("blue") or 0
  end
  return 0
end

local function _addBluePoints(amount)
  if DATA_Core and DATA_Core.AddCoalitionPoints then
    DATA_Core.AddCoalitionPoints("blue", amount)
  end
end

--------------------------------------------------------------------
-- REQUEST SUPPLY
--------------------------------------------------------------------

function WH_Manager.RequestSupply(routeId)
  local route = nil
  for _, r in ipairs(WH_Manager.SUPPLY_ROUTES) do
    if r.id == routeId then route = r; break end
  end
  if not route then
    env.info("WH_Manager :: RequestSupply: ruta " .. routeId .. " no encontrada.")
    return
  end

  -- Verificar puntos de coalicion
  local pts = _getBluePoints()
  if pts < route.cost then
    _msg(string.format(
      "SUMINISTROS: Puntos insuficientes.\nNecesitas %d pts. Tienes %d pts.",
      route.cost, pts
    ), 15)
    return
  end

  -- Verificar que la base origen tiene fuel (Akrotiri siempre tiene)
  local fromBase = _getBase(route.from)
  local toBase   = _getBase(route.to)
  if not fromBase or not toBase then
    env.info("WH_Manager :: RequestSupply: base no encontrada en config.")
    return
  end

  if route.from ~= "AKRO" then
    local fromStatus = WH_Manager._status[route.from]
    if fromStatus and fromStatus.status == "blocked" then
      _msg(string.format(
        "SUMINISTROS: %s sin fuel suficiente para despachar un transporte.",
        fromBase.label
      ), 15)
      return
    end
  end

  -- Descontar puntos
  _addBluePoints(-route.cost)

  -- Obtener airbase origen
  local ok1, fromAB = pcall(function()
    return AIRBASE:FindByName(fromBase.dcsName)
  end)
  if not ok1 or not fromAB then
    _msg("ERROR: No se encontro la base " .. fromBase.label .. " en DCS.", 15)
    _addBluePoints(route.cost)  -- reembolso
    return
  end

  -- Obtener airbase destino
  local ok2, toAB = pcall(function()
    return AIRBASE:FindByName(toBase.dcsName)
  end)
  if not ok2 or not toAB then
    _msg("ERROR: No se encontro la base " .. toBase.label .. " en DCS.", 15)
    _addBluePoints(route.cost)  -- reembolso
    return
  end

  -- Crear spawner y spawnear en la base origen
  local ok3, spawner = pcall(function()
    return SPAWN:New(route.template)
  end)
  if not ok3 or not spawner then
    _msg("ERROR: Template " .. route.template .. " no encontrado en ME.", 15)
    _addBluePoints(route.cost)  -- reembolso
    return
  end

  local ok4, grp = pcall(function()
    return spawner:SpawnAtAirbase(fromAB, SPAWN.Takeoff.Hot)
  end)
  if not ok4 or not grp then
    _msg("ERROR: No se pudo spawnear el transporte en " .. fromBase.label, 15)
    _addBluePoints(route.cost)  -- reembolso
    return
  end

  -- Dar tarea de vuelo al destino
  pcall(function()
    grp:RouteAirbase(toAB, COORDINATE.WaypointType.LandingReFuAr)
  end)

  -- Registrar en tabla de activos
  local groupName = grp:GetName()
  WH_Manager._activeTransports[groupName] = {
    routeId   = routeId,
    route     = route,
    fromLabel = fromBase.label,
    toLabel   = toBase.label,
    toId      = route.to,
    toDcsName = toBase.dcsName,
    status    = "enroute",
    spawned   = timer.getTime(),
  }

  env.info("WH_Manager :: Transporte despachado: " .. groupName ..
    " | " .. fromBase.label .. " -> " .. toBase.label)

  _msg(string.format(
    "TRANSPORTE DESPACHADO\n%s -> %s  [%s]\nCosto: %d pts | Entrega: %s\nPuntos restantes: %d pts",
    fromBase.label,
    toBase.label,
    string.upper(route.type),
    route.cost,
    _fuelStr(WH_Manager.FUEL_DELIVERY_LBS),
    _getBluePoints()
  ), 25)
end

--------------------------------------------------------------------
-- DETECCION DE LLEGADA (via zona alrededor del destino)
-- Se chequea cada 30s si algun transporte activo est? cerca
-- de su destino - m?s confiable que detectar aterrizaje exacto
--------------------------------------------------------------------

local function _checkArrivals()
  local now = timer.getTime()

  for groupName, transport in pairs(WH_Manager._activeTransports) do
    if transport.status == "enroute" then

      -- Verificar si el grupo sigue vivo
      local ok, grp = pcall(function()
        return GROUP:FindByName(groupName)
      end)

      if not ok or not grp or not grp:IsAlive() then
        -- Grupo destruido
        transport.status = "lost"
        _msg(string.format(
          "*** TRANSPORTE PERDIDO: %s -> %s\nLos suministros no llegaron.",
          transport.fromLabel, transport.toLabel
        ), 25)
        env.info("WH_Manager :: Transporte perdido: " .. groupName)
        WH_Manager._activeTransports[groupName] = nil

      else
        -- Verificar proximidad al destino
        local ok2, destAB = pcall(function()
          return AIRBASE:FindByName(transport.toDcsName)
        end)
        if ok2 and destAB then
          local ok3, grpCoord = pcall(function()
            return grp:GetCoordinate()
          end)
          local ok4, destCoord = pcall(function()
            return destAB:GetCoordinate()
          end)
          if ok3 and ok4 and grpCoord and destCoord then
            local dist = grpCoord:Get2DDistance(destCoord)
            if dist <= WH_Manager.ARRIVAL_RADIUS then
              -- ENTREGA EXITOSA
              transport.status = "delivered"

              -- Agregar fuel al destino via STORAGE
              pcall(function()
                local ab = AIRBASE:FindByName(transport.toDcsName)
                if ab then
                  local st = ab:GetStorage()
                  if st then
                    st:AddItem(STORAGE.Liquid.JetA, WH_Manager.FUEL_DELIVERY_LBS)
                  end
                end
              end)

              -- Devolver puntos como recompensa
              _addBluePoints(transport.route.cost)

              _msg(string.format(
                "SUMINISTROS ENTREGADOS\n%s -> %s  [%s]\n+%s fuel | +%d pts (recompensa)\nPuntos actuales: %d pts",
                transport.fromLabel,
                transport.toLabel,
                string.upper(transport.route.type),
                _fuelStr(WH_Manager.FUEL_DELIVERY_LBS),
                transport.route.cost,
                _getBluePoints()
              ), 25)

              env.info("WH_Manager :: Entrega exitosa: " .. groupName ..
                " -> " .. transport.toLabel)

              -- Destruir el transporte IA (ya cumpli? su misi?n)
              pcall(function() grp:Destroy() end)
              WH_Manager._activeTransports[groupName] = nil
            end
          end
        end
      end
    end
  end

  return now + 30  -- chequear cada 30 segundos
end

--------------------------------------------------------------------
-- MOSTRAR TRANSPORTES ACTIVOS
--------------------------------------------------------------------

function WH_Manager.ShowActiveTransports()
  local lines = {
    "================================",
    "  TRANSPORTES EN VUELO",
    "================================",
  }
  local count = 0
  for groupName, t in pairs(WH_Manager._activeTransports) do
    if t.status == "enroute" then
      count = count + 1
      table.insert(lines, string.format(
        "  [%s] %s -> %s",
        string.upper(t.route.type),
        t.fromLabel,
        t.toLabel
      ))
    end
  end
  if count == 0 then
    table.insert(lines, "  Sin transportes activos.")
  end
  table.insert(lines, "================================")
  _msg(table.concat(lines, "\n"), 20)
end

--------------------------------------------------------------------
-- MENU F10 COMPLETO (Nivel 1 + Nivel 2)
--------------------------------------------------------------------

local function _buildMenu()
  _menuRoot = missionCommands.addSubMenu("Warehouse / Logistica", nil)

  -- Items Nivel 1
  missionCommands.addCommandForCoalition(
    WH_Manager.COALITION, "Ver stock de todas las bases",
    _menuRoot, WH_Manager.ShowAllStock
  )
  missionCommands.addCommandForCoalition(
    WH_Manager.COALITION, "Bases disponibles con combustible",
    _menuRoot, WH_Manager.ShowAvailableBases
  )
  missionCommands.addCommandForCoalition(
    WH_Manager.COALITION, "Ver transportes en vuelo",
    _menuRoot, WH_Manager.ShowActiveTransports
  )

  -- Submenu de rutas de suministro
  local supplyMenu = missionCommands.addSubMenu("Solicitar suministros", _menuRoot)

  for _, route in ipairs(WH_Manager.SUPPLY_ROUTES) do
    local r = route  -- closure
    missionCommands.addCommandForCoalition(
      WH_Manager.COALITION,
      string.format("%s  [%d pts]", route.label, route.cost),
      supplyMenu,
      function() WH_Manager.RequestSupply(r.id) end
    )
  end

  env.info("WH_Manager :: Menu F10 completo registrado (Nivel 1 + Nivel 2).")
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------

-- Primer chequeo inmediato + schedulers
timer.scheduleFunction(function()
  WH_Manager.CheckAll()
  timer.scheduleFunction(function()
    return WH_Manager.CheckAll()
  end, {}, timer.getTime() + WH_Manager.CHECK_INTERVAL)
  return nil
end, {}, timer.getTime() + 8)

-- Scheduler de deteccion de llegada de transportes (cada 30s)
timer.scheduleFunction(function()
  return _checkArrivals()
end, {}, timer.getTime() + 30)

-- Men F10
_buildMenu()

env.info("WH_Manager :: INICIADO correctamente. Chequeo cada " ..
  WH_Manager.CHECK_INTERVAL .. "s  Aviso < " ..
  WH_Manager.FUEL_WARNING_LBS .. " lbs  Bloqueada < " ..
  WH_Manager.FUEL_BLOCKED_LBS .. " lbs")
