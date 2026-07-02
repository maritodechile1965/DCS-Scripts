# 📚 Referencias Técnicas — DCS Scripting (MOOSE/MIST)

Documento vivo con lecciones aprendidas, patrones de código, decisiones de diseño
y referencias que no queremos volver a descubrir. Diferente al Dashboard (operacional)
y a Ideas_Sueltas (conceptual/futuro).

---

## 1. VISIÓN COMPLETA DE LA CAMPAÑA

Definida por Mario en la sesión inicial (28/06/2026). Mapa: Siria (cambio desde
Golfo Pérsico, decidido 01/07/2026). Servidor 24/7, sesiones de ~3 horas.

### Coaliciones
- **Blue (humana):** pilotos reales, gestión de puntos, toma de decisiones
- **Red (IA + posiblemente algunos humanos):** gestión delegable a humanos

### Sistema de puntos y economía
- Puntos por piloto (individual) y por coalición (colectivo)
- Puntos de piloto se pueden "donar" a la coalición para comprar recursos
- Con puntos de coalición: solicitar combustible, armamento, aeronaves, vehículos,
  refuerzos IADS (radares, launchers, SHORAD)
- Máximo 2 misiones aéreas por piloto por día (controlado por DATA_Core)
- Los rescates CSAR dan puntos al rescatar; restan si el heli es destruido
- Las misiones logísticas que llegan a destino también suman

### Misiones previstas (catálogo completo)
**Siempre disponibles (simples, pocos puntos constantes):**
- CAP en zonas determinadas
- Ataques menores a templates en el escenario
- Transporte de combustible/armas
- CSAR (rescate de pilotos caídos)
- Reconocimiento (TARS — clase MOOSE Ops.TARS)

**De campaña (condiciones, muchos puntos, planificación >1h):**
- SEAD/DEAD sobre bases aéreas enemigas
- Strike con requisito de SEAD previo
- Captura de bases (heli/C-130 con tropas, CTLD)
- Escort de bombarderos
- Escort de transporte
- Transporte de soldados
- Asalto terrestre (soldados atacan base roja)
- Rescate de soldados terrestres
- Guerra de tanques (con CAS de A-10, AH-64)
- JFAC/CAS con controlador humano o IA
- Ataques a buques
- CarrierOps (operaciones desde portaaviones)
- MEDEVAC

**IA Roja (automáticas):**
- Fighters de CAP defensiva en sectores del mapa
- Reconquista de bases neutralizadas (timer ~60 min)
- Escorts de bombarderos rojos
- Transporte de tropas

### CSAR — detalle de implementación
- Cuando piloto cae: capturar posición → spawnear template de rescate a ~30nm
- Helicóptero de rescate desde ese template hacia el piloto caído
- Distancia elegida para que el vuelo dure ~15-20 min de juego real
- Puntaje: +X al rescatar, -Y si el heli es destruido

### Página web de misiones (target folder)
Cada misión tendrá su paquete de datos publicado en web:
- Target Folder (objetivos, coordenadas, tipo)
- SPINS (Special Instructions)
- JIPTL (Joint Integrated Prioritized Target List)
- ATO (Air Tasking Order) con brief/intel/callsigns/frecuencias/meteo
- FPL recomendado con TOT (Time on Target)
- NAV Card (frecuencias, waypoints, push, apoyos)
- Target Data Package (JIPTL/coords/tipo/riesgo)
- La web se actualiza con el resultado de cada misión

### IADS propio (SkyNet Custom)
- Basado en SkyNet o construido a medida
- Parámetros propios: rango de detección configurable
- Comprable con puntos de coalición (refuerzo parcial)
- Integrado con la campaña dinámica (se degrada al perder radares)

### Carrier
- Área de portaaviones en el mapa
- Heli de rescate permanente por si hay accidente en cubierta
- CarrierOps como misiones específicas

### Persistencia entre sesiones
- Unidades con nombres fijos en el Mission Editor
- Al fin de sesión: `DCS_Dead_Units.csv` con nombres de unidades destruidas
- Al reiniciar: script Lua lee el CSV y destruye esas unidades via `Unit:destroy()`
- DCS tiene autosave nativo en servidor — evaluarlo como complemento

---

## 2. LECCIONES TÉCNICAS DCS / MOOSE / LUA

### 2.1 Librería `os` sandboxeada en DCS
DCS bloquea por defecto `os`, `io`, `lfs` en el entorno Lua de misiones.
Para habilitarlos hay que editar:
`C:\Program Files\Eagle Dynamics\DCS World\Scripts\MissionScripting.lua`
(comentar las líneas `os = nil`, `io = nil`, `lfs = nil`)

**Reemplazos sin necesidad de habilitar `os`:**
- `os.time()` → `timer.getTime()` (segundos desde inicio de misión)
- `os.date()` → `timer.getAbsTime()` convertido a HH:MM:SS con aritmética

**Mario habilitó `io`/`lfs` en su instalación** → `DATA_Export.lua` puede escribir CSV.

### 2.2 EventData.Weapon vs EventData.weapon (MOOSE vs DCS nativo)
Dos objetos distintos que coexisten en el EventData de MOOSE:
- `EventData.Weapon` (mayúscula) → MOOSE wrapper (puede tener métodos
  como `:GetCoordinate()`, `:GetDCSObject()`)
- `EventData.weapon` (minúscula) → objeto DCS nativo crudo (tiene `:getPoint()`,
  `:getDesc()`, `:getTypeName()`)

**Regla práctica:** para obtener posición en el evento Hit, usar el DCS nativo
(`EventData.weapon:getPoint()`) siguiendo el patrón del BombImpact.lua de Mario.
El wrapper MOOSE puede fallar si el objeto DCS ya fue destruido.

### 2.3 Impact callback de MOOSE WEAPON — limitación confirmada
`WEAPON:SetFuncImpact(callback)` / `WEAPON:StartTrack()` detectan cuando el arma
desaparece. El problema: cuando el callback se dispara, el objeto DCS del arma
**ya fue destruido** por DCS. Por eso:
```
GetPointVec3() → error "Object doesn't exist"
GetCoordinate() → error "Object doesn't exist"
```
**Consecuencia de diseño:** el MGRS de impacto para MISS (arma en terreno) es
`nil` por limitación técnica de DCS/MOOSE — decisión consciente, no un bug
pendiente de resolver.

**El MGRS SÍ funciona para hits reales** (vía `EventData.weapon:getPoint()` en
`_onHit`, cuando el objeto del arma todavía existe).

### 2.4 COORDINATE:NewFromVec3() — espera tabla plana, no objeto MOOSE
```lua
-- INCORRECTO: pasa un objeto POINT_VEC3 de MOOSE
local pv = unit:GetPointVec3()
COORDINATE:NewFromVec3(pv)  -- falla silenciosamente

-- CORRECTO: extraer campos planos primero
local vec3 = { x = pv.x, y = pv.y, z = pv.z }
COORDINATE:NewFromVec3(vec3):ToStringMGRS()
```

### 2.5 Valores correctos de coalición en DCS/MOOSE
```lua
coalition.side.BLUE  -- = 2 (no usar el número directamente)
coalition.side.RED   -- = 1
coalition.side.NEUTRAL -- = 0
```
En EventData: `EventData.IniCoalition` devuelve estos valores numéricos.
Comparar siempre contra `coalition.side.X`, nunca contra strings.

### 2.6 Object.Category vs Unit.Category
Para clasificar objetos en DCS:
```lua
Object.Category.UNIT    -- unidad dinámica (avión, vehículo, barco)
Object.Category.STATIC  -- objeto estático colocado en el editor
Object.Category.SCENERY -- scenery del mapa (edificios del terreno base)
Object.Category.BASE    -- aeródromos

-- Dentro de UNIT, subcategorías:
Unit.Category.AIRPLANE
Unit.Category.HELICOPTER
Unit.Category.GROUND_UNIT
Unit.Category.SHIP
Unit.Category.STRUCTURE
```

### 2.7 PlayerEnterUnit — único evento confiable para detectar piloto humano
- `Birth` se dispara también para unidades IA → no usar para crear fichas de piloto
- `PlayerEnterUnit` se dispara SOLO cuando un humano ocupa una unidad
- Es el momento correcto para: crear registro en DATA_Core, capturar `aircraftType`
  (mientras la unidad aún existe y `GetTypeName()` es confiable)

### 2.8 pcall() es obligatorio en TODA llamada a DCS/MOOSE
Las APIs de DCS pueden fallar silenciosamente o lanzar errores en cualquier momento
(objeto destruido, nil inesperado, etc.). Patrón obligatorio en el proyecto:
```lua
local ok, result = pcall(function()
  return EventData.TgtUnit:GetCoordinate():ToStringMGRS()
end)
if ok and result then
  -- usar result
end
```

### 2.9 Object_id numérico = scenery del mapa
Cuando `EventData.IniUnitName` o `TgtUnitName` es un número puro (ej. `86122733`),
es un objeto del terreno base de DCS, no una unidad colocada por el editor.
```lua
if tonumber(targetUnitName) then
  -- es scenery: domain="ground", no tiene coalición confiable
  -- registrar como Collateral en el ledger
end
```

### 2.10 Functional.Scoring de MOOSE — descartado
Evaluado en sesión 5 y descartado. Razones:
- Bypasea EVT_Dispatcher con su propio HandleEvent
- Mantiene tabla de jugadores propia (duplica DATA_Core)
- Requiere `os`/`io` habilitados para CSV
- Modelo de scoring por "threat level" no apto para nuestras reglas de negocio

---

## 3. PATRONES DE CÓDIGO DEL PROYECTO

### 3.1 Patrón de suscripción a EVT_Dispatcher
```lua
-- En el bloque de suscripción de cada módulo:
if EVT_Dispatcher and EVT_Dispatcher.Subscribe and DATA_Core then
  EVT_Dispatcher:Subscribe(EVENTS.Hit,   _onHit,    "PTS_Manager")
  EVT_Dispatcher:Subscribe(EVENTS.Dead,  _onDead,   "PTS_Manager")
  env.info("PTS_Manager :: INICIADO correctamente.")
else
  env.error("PTS_Manager :: EVT_Dispatcher o DATA_Core no encontrados.")
end
```
Siempre verificar que EVT_Dispatcher y DATA_Core existen antes de suscribirse.
Siempre pasar el nombre del módulo como tercer parámetro (aparece en el log).

### 3.2 Patrón de obtención de MGRS desde evento Hit
```lua
-- En _onHit, usar DCS nativo primero (patrón BombImpact.lua de Mario):
local function _mgrsFromEvent(EventData)
  -- 1: arma DCS nativa (más confiable para hits terrestres y aéreos)
  if EventData.weapon then
    local ok, vec3 = pcall(function() return EventData.weapon:getPoint() end)
    if ok and vec3 then return _vec3ToMGRS(vec3) end
  end
  -- 2: unidad objetivo DCS nativa
  if EventData.TgtUnit then
    local ok, obj = pcall(function() return EventData.TgtUnit:GetDCSObject() end)
    if ok and obj then
      local ok2, vec3 = pcall(function() return obj:getPoint() end)
      if ok2 and vec3 then return _vec3ToMGRS(vec3) end
    end
  end
  return nil
end
```

### 3.3 Clasificación de objetos DCS para el ledger
```lua
local function _classifyDCSTarget(dcsTarget)
  local ok, objCat = pcall(function() return Object.getCategory(dcsTarget) end)
  if not ok then return "UNKNOWN", nil end
  local typeName = nil
  local ok2, tn = pcall(function() return dcsTarget:getTypeName() end)
  if ok2 then typeName = tn end
  if objCat == Object.Category.UNIT then
    local ok3, desc = pcall(function() return dcsTarget:getDesc() end)
    if ok3 and desc then
      local c = desc.category
      if c == Unit.Category.AIRPLANE or c == Unit.Category.HELICOPTER then return "AIRCRAFT", typeName end
      if c == Unit.Category.GROUND_UNIT  then return "VEHICLE",   typeName end
      if c == Unit.Category.SHIP         then return "SHIP",      typeName end
      if c == Unit.Category.STRUCTURE    then return "STRUCTURE",  typeName end
    end
  elseif objCat == Object.Category.STATIC  then return "BUILDING", typeName
  elseif objCat == Object.Category.SCENERY then return "BUILDING", typeName
  end
  return "OBJECT", typeName
end
```

### 3.4 Conversión de Vec3 a MGRS (tabla plana requerida)
```lua
local function _vec3ToMGRS(vec3)
  if not vec3 then return nil end
  local ok, mgrs = pcall(function()
    return COORDINATE:NewFromVec3({x=vec3.x, y=vec3.y, z=vec3.z}):ToStringMGRS()
  end)
  if ok and mgrs then return mgrs end
  return nil
end
```

### 3.5 Hora del mundo DCS sin usar `os`
```lua
local function _missionClockHHMMSS()
  local ok, t = pcall(timer.getAbsTime)
  if not ok or not t then return nil end
  local s = math.floor(t) % 86400
  return string.format("%02d:%02d:%02d",
    math.floor(s/3600),
    math.floor((s%3600)/60),
    s%60)
end
```

---

## 4. REFERENCIAS EXTERNAS

### 4.1 BombImpact.lua (script propio de Mario, v1.07)
Script pre-existente que resolvió el problema del MGRS de impacto terrestre.
Patrón clave utilizado:
```lua
-- En el HitEventHandler (world.addEventHandler nativo):
local pos = event.weapon:getPoint()   -- DCS nativo, no MOOSE wrapper
local lat, lon = coord.LOtoLL(pos)    -- conversión DCS nativa
```
El mismo archivo también tiene el patrón `WEAPON:SetFuncImpact()` + `StartTrack()`
para tracking de armas. Guardado como referencia en el repositorio del usuario.

### 4.2 Clases MOOSE evaluadas
| Clase | Estado | Razón |
|---|---|---|
| `Functional.Scoring` | ❌ Descartada | Bypasea EVT_Dispatcher, duplica DATA_Core |
| `Ops.TARS` | 🔵 Evaluación futura | Misiones de reconocimiento |
| `Functional.Warehouse` | 🔵 Pendiente | Inventory/resources (backlog #1) |
| `Ops.Chief` | 🔵 Evaluar | Zonas estratégicas para CAMPAIGN_Manager |
| `WEAPON` | ✅ En uso | Tracking de armas en PTS_Manager |
| `SPAWN` | 🔵 Pendiente | TemplateSpawn, Fighters Rojos |
| `SCHEDULER` | ✅ En uso | Timers en PTS_Manager (MISS detection) |

---

## 5. PENDIENTES DE DISEÑO NO FORMALIZADOS

### 5.1 Menú F10 dinámico (MIS_Manager — no implementado aún)
- `missionCommands.addCommand()` para ítems simples
- `missionCommands.addSubMenu()` para submenús por tipo de misión
- El menú se regenera dinámicamente según estado de zonas (CAMPAIGN_Manager)
- `DATA_Export.WriteAll()` ya está registrado como ítem F10 en DATA_Export.lua
- MIS_Manager debe agregar/quitar ítems según `ZONE_State` de cada zona

### 5.2 Aterrizaje correcto (no implementado en DATA_Export aún)
Secuencia de eventos para detectar "aterrizaje correcto" y grabar CSV individual:
1. `EVENTS.Land` → piloto tocó pista
2. Motor apagado → por ahora no hay evento directo en MOOSE; opciones:
   - Polling con SCHEDULER cada N segundos chequeando `unit:getFuelRelative()`
   - O simplemente `EVENTS.PlayerLeaveUnit` después de un `Land` reciente
3. `EVENTS.PlayerLeaveUnit` → piloto salió de la unidad
Si la secuencia Land → PlayerLeaveUnit ocurre sin un Crash/Dead intermedio
= aterrizaje correcto → llamar `DATA_Export.WritePilotLog(pilotId)`

### 5.3 Filosofía de scoring (valores de PTS_Manager.POINTS)
Razonamiento detrás de los valores actuales (todos editables):
- `TARGET_DESTROYED (+15) > ENEMY_KILL (+10)`: cumplir la misión asignada
  vale más que un kill oportunista
- `BLUE_ON_BLUE (-20)`: más negativo que cualquier ganancia posible en un
  solo evento, para desincentivar fuertemente el fuego amigo
- `OWN_LOSS (-10)`: perder un avión propio tiene costo, pero no catastrófico
- `COLLATERAL (0)`: daño colateral neutro por defecto; en el futuro podría
  penalizarse si se destruyen objetivos civiles específicos
- `MISS (0)`: el tiro fallado ya tiene su costo implícito (recurso gastado);
  no penalizar adicionalmente para no desincentivar el ataque

### 5.4 ZONE_State — estados de zonas de campaña
Diseño conceptual aprobado (01/07/2026), no implementado:
```
Estado de una zona: ROJA / NEUTRALIZADA / AZUL / RECONQUISTADA
```
Transiciones:
- ROJA → NEUTRALIZADA: objetivos clave destruidos (ej. SEAD exitoso)
- NEUTRALIZADA → AZUL: asalto terrestre exitoso (CTLD/tropas)
- AZUL → RECONQUISTADA: timer ~60 min sin defensa → IA roja reconquista
- RECONQUISTADA → ROJA: loop reinicia

Cada transición: mensaje a todos los jugadores + actualización del menú F10
+ posibles spawns de IA o misiones nuevas desbloqueadas.

### 5.5 MISSIONS_Config.lua — herramienta de generación
Generador visual HTML creado (MissionsGenerator.html, no va al repo — es
herramienta personal de Mario). Genera el archivo Lua con validación de IDs,
MGRS, condiciones y consistencia entre misiones. Guarda en localStorage del
navegador + exporta/importa JSON para respaldo.

---

## 6. ORDEN DE CARGA DE SCRIPTS (estado actual)

```lua
-- DO SCRIPT FILE — Trigger: MISSION START — orden obligatorio
assert(loadfile("C:\\Users\\mario\\Saved Games\\DCS\\Scripts\\Moose.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\EVT_Dispatcher.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Core.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\PTS_Manager.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Export.lua"))()
-- Próximos a agregar:
-- MISSIONS_Config.lua  (tabla de configuración de misiones)
-- CAMPAIGN_Manager.lua (motor de estados de zonas y misiones)
```

---

*Última actualización: 01/07/2026 — Sesión 8*
