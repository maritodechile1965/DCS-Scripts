# 📊 Dashboard del Proyecto — DCS Scripting (MOOSE/MIST)
**Mapa:** Siria · **Servidor:** 24/7 · **Sesiones:** ~3h · **Blue (humanos) vs Red (IA)**

---

## ⏱️ SESIONES DE TRABAJO

| # | Fecha | Inicio | Fin | Duración | Tema |
|---|---|---|---|---|---|
| 1 | 28/06/2026 | 23:20 | 00:20 | 1h 00min | Dashboard inicial + arquitectura EVT_Dispatcher |
| 2 | 29/06/2026 | 00:30 | 01:50 | 1h 20min | Prueba Event Handlers (EVT_Dispatcher + TEST_Handler) |
| 3 | 29/06/2026 | 06:40 | 08:20 | 1h 40min | Validación BaseCaptured + investigación clases MOOSE |
| 4 | 29/06/2026 | 08:00 | 09:50 | 1h 50min | DATA_Core v1 + migración a GitHub |
| 5* | 29/06/2026 | 14:15 | ~21:15 | ~7h | Validación DATA_Core + PTS_Manager v1→v2 + ledger ampliado |
| 6 | 30/06/2026 | 07:40 | 10:00 | 2h 20min | PTS_Manager Ground Impacts |
| 7 | 30/06/2026 | 11:30 | 14:00 | 2h 30min | PTS_Manager v3 + WEAPON tracking + DATA_Export |
| 8 | 01/07/2026 | 10:10 | 14:45 | 4h 35min | Estrategia grabación / CAMPAIGN_Manager / MissionsGenerator |
| 9 | 02/07/2026 | 10:15 | 10:20 | 5 min | Visión global campaña + roadmap + MOOSE vs custom |
| 10 | 02/07/2026 | 14:20 | 15:00 | 40 min | Resumen general + setup mapa Siria + recomendación unidades |
| 11 | 02/07/2026 | 08:40 | 20:30 | 11h 50min | SAMs escenario + ZONE_State + persistencia bases + CAMP_Net |

**Total acumulado sesiones 1-11: ~35h**
*Sesión 5 extendida sin cierre formal intermedio.

---

## 📋 RESUMEN POR SESIÓN

**Sesiones 1-4 (28-29/06):** Arquitectura event-driven, EVT_Dispatcher, DATA_Core v1, migración GitHub.

**Sesión 5 (29/06, extendida):** Validación DATA_Core. PTS_Manager v1→v2. Ledger ampliado con clockTime, pilotAircraft, domain, targetType. Validado en juego con derribo real.

**Sesión 6 (30/06):** PTS_Manager targets terrestres validado. domain="ground" con 3 fallbacks. Soporte scenery DCS.

**Sesión 7 (30/06):** PTS_Manager v3 con WEAPON tracking. Mensajes [SHOT]/[IMPACT]/[MISS]. DATA_Export v1 validado (CSV + F10).

**Sesión 8 (01/07):** Estrategia grabación híbrida. MissionsGenerator.html. Diseño conceptual CAMPAIGN_Manager. Referencias_Tecnicas.md creado.

**Sesiones 9-10 (02/07):** Visión global campaña formalizada. Roadmap por etapas. Setup mapa Siria (5 zonas, ~65-81 unidades). Progresión campaña en 4 fases.

**Sesión 11 (02/07):** Análisis Test_CSAR.miz (428 unidades, sistemas SAM). Mapa táctico Siria dibujado. Decisión late activation por zona. DATA_Core ampliado con tabla _baseStates (20 bases azules + 9 rojas). ZONE_State.lua creado y validado en juego. DATA_Export ampliado (WriteBaseStates, RestoreBaseStates, grabación periódica). CAMP_Net.lua creado (LogNet renombrado + integración DATA_Core). Bug Lua 5.1 `continue` detectado y corregido. Nuevas misiones definidas (convoyes random, helis, CAPs, templates estáticos).

**Sesiones 13-14 (09-10/07):** WH_Manager.lua v2 (gestión de combustible por base, pendiente prueba en juego). Limpieza y optimización de CAMP_Net (captura/reconquista automática validada, radio 2000m). MISSIONS_Config.lua v2 reestructurado (categorías always/campaign/intel, filtrado por plataforma fighter/heli/transport). MIS_Manager.lua v2 con menús F10 dinámicos por plataforma del piloto (evento PlayerEnterUnit). STATUS_Manager.lua v1 creado (menú Intel/Status: estado AWACS LORD, bases/combustible, puntos de coalición, estadísticas por piloto). 9 misiones de prueba agregadas para validar el filtrado por plataforma.

---

## ✅ SCRIPTS EN PRODUCCIÓN

| Script | Versión | Estado | Descripción |
|---|---|---|---|
| `EVT_Dispatcher.lua` | v1 | ✅ Validado 13/13 | Dispatcher central Pub/Sub sobre MOOSE EVENTHANDLER |
| `TEST_Handler.lua` | v1 | ✅ Completado | Script de validación temporal — cumplió su propósito |
| `DATA_Core.lua` | v2 | ✅ Validado | Base de datos en memoria + tabla _baseStates (29 bases) |
| `PTS_Manager.lua` | v3 | ⚠️ Parcial | Scoring completo + WEAPON tracking. Pendiente: validar con piloto humano |
| `DATA_Export.lua` | v2 | ✅ Validado | CSV + F10 + WriteBaseStates + RestoreBaseStates + timer configurable |
| `ZONE_State.lua` | v1 | ✅ Validado | Persistencia bases, BaseCaptured handler, grabación automática |
| `CAMP_Net.lua` | v2 | ✅ Validado | Red visual F10 de campaña — captura/reconquista automática, radio 2000m |
| `WH_Manager.lua` | v2 | ⚠️ Pendiente prueba en juego | Gestión de combustible por base |
| `MISSIONS_Config.lua` | v2 | ✅ Validado | 9 misiones de prueba (fighter/heli/transport). Categorías always/campaign/intel |
| `MIS_Manager.lua` | v2 | ✅ Validado | Menú F10 dinámico filtrado por plataforma del piloto (PlayerEnterUnit) |
| `STATUS_Manager.lua` | v1 | ✅ Validado | Menú Intel/Status: AWACS LORD, bases/combustible, puntos, estadísticas piloto |

### Orden de carga (Mission Editor — MISSION START)
```lua
assert(loadfile("C:\\Users\\mario\\Saved Games\\DCS\\Scripts\\Moose.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\EVT_Dispatcher.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Core.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\PTS_Manager.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Export.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\ZONE_State.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\CAMP_Net.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\WH_Manager.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\MISSIONS_Config.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\MIS_Manager.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\STATUS_Manager.lua"))()
```

---

## 🗺️ HOJA DE RUTA

### ETAPA 1 — BASE ✅ (~23h — COMPLETADA)
- [x] EVT_Dispatcher, DATA_Core, PTS_Manager, DATA_Export
- [x] Ledger de puntos con todos los campos
- [x] GitHub como fuente de verdad

### ETAPA 2 — ZONA Y CAMPAÑA 🔄 EN PROGRESO (~30-35h)
- [x] `ZONE_State.lua` — persistencia de bases entre sesiones ✅
- [x] `CAMP_Net.lua` — red visual F10 de campaña ✅
- [x] `MISSIONS_Config.lua` — tabla de configuración de misiones ✅
- [x] `MIS_Manager` — menú F10 dinámico de misiones (filtrado por plataforma) ✅
- [ ] `TIMER_Manager` — timers de reconquista y ventanas de tiempo
- [ ] Definir zonas Trigger en Mission Editor (LN_*)
- [ ] Poblar MISSIONS_Config con misiones Fase 1

### ETAPA 3 — PERSISTENCIA 🔄 EN PROGRESO (~12-15h)
- [x] `DCS_Base_State.csv` — exportar/restaurar estados de bases ✅
- [ ] `DCS_Dead_Units.csv` — unidades destruidas entre sesiones
- [ ] Script de restauración de unidades destruidas
- [ ] `DATA_Export.WritePilotLog()` + `WriteSessionLog()`
- [ ] Detectar aterrizaje correcto (Land + PlayerLeaveUnit)

### ETAPA 4 — CSAR DINÁMICO 🟡 (~8h con Ops.CSAR)
### ETAPA 5 — WAREHOUSE Y ECONOMÍA 🟡 (~12h con Functional.Warehouse)
### ETAPA 6 — IA ROJA 🟡 (~8h con EasyGCICAP + Mantis)
### ETAPA 7 — WEB Y ANALYTICS 🟢 FUTURO (~35-40h)

---

## 🎯 PENDIENTES PARA SESIÓN 12

1. **Validar PTS_Manager con piloto humano** — [SHOT]/[IMPACT] en pantalla, pilotAircraft en ledger, BlueOnBlue, TargetDestroyed
2. **Crear Trigger Zones en Mission Editor** (LN_INCIR, LN_BASSEL, etc.) para que CAMP_Net pueda dibujar la red
3. **Probar CAMP_Net en juego** — verificar que dibuja nodos y conexiones en F10
4. **MISSIONS_Config.lua** — primeras misiones Fase 1 (simples, siempre disponibles)
5. **Foto del F10 map** con zonas cargadas para diseñar CAMPAIGN_Manager

---

## 🗺️ SETUP MAPA SIRIA (sesión 10-11)

**Teatro:** Incirlik (norte) → Damasco (sur) · Chipre/Israel (oeste) · NFZ Jordania (sur)

**Bases Azules:** Akrotiri · Ramat David · Carrier CVN-73 · Paphos + bases Israel

**Zonas Rojas:**
- Zona 1 — Costera (Latakia/Tartús): SA-10 + SA-11 · Base: Bassel Al-Assad
- Zona 2 — Central (Homs/T-4): SA-6 + SA-15 + T-72 · Base: Shayrat/Tiyas
- Zona 3 — Damasco: SA-10 + SA-8 + T-72/T-80 · Base: Mezzeh
- Zona 4 — Líbano: SA-6 móvil + blindados (sin base aérea roja)
- Zona 5 — Alepo (late activation): SA-10 · Base: Kuweires

**Total activo:** ~65-81 unidades · Late activation por zona

**Misiones adicionales definidas (sesión 11):**
- Convoyes terrestres random (spawn dinámico, destinos random)
- Helis enemigos con rutas random
- CAPs rojas por sectores (siempre activas en zonas rojas)
- Templates estáticos como blancos de oportunidad

---

## 🏗️ INFRAESTRUCTURA

- **Repo:** https://github.com/maritodechile1965/DCS-Scripts
- **Local:** `C:\Users\mario\Documents\DCS-Scripts`
- **Docs:** `docs/` · **Scripts:** `scripts/` · **Prompts:** `prompts/`

### Documentos clave
| Archivo | Descripción |
|---|---|
| `Dashboard_Proyecto.md` | Este archivo — estado general |
| `Dashboard_Visual.html` | Versión visual HUD del dashboard |
| `Referencias_Tecnicas.md` | **DOCUMENTO MAESTRO** — visión, lecciones, patrones |
| `Referencias_MOOSE.md` | Clases MOOSE evaluadas |
| `Ideas_Sueltas.md` | Ideas futuras y decisiones de diseño |
| `Checklist_Sesion.md` | Protocolo inicio/cierre de sesión |
| `MissionsGenerator.html` | Generador visual MISSIONS_Config.lua (no va al repo) |

---

## 🏛️ DECISIONES DE ARQUITECTURA VIGENTES

- **EVT_Dispatcher** como dispatcher central — no duplicar con `world.addEventHandler`
- **DATA_Core** = única fuente de estado (incluye _baseStates con 29 bases)
- **PTS_Manager** sin estado propio — escribe siempre a DATA_Core
- **ZONE_State** gestiona persistencia de bases y graba automáticamente
- **CAMP_Net** es la capa visual — sincroniza con DATA_Core al capturar nodos
- No usar `os` de Lua — usar `timer.getTime()` / `timer.getAbsTime()`
- Evaluar MOOSE antes de escribir código propio — ahorro estimado ~87h
- Unidades con **nombres fijos** en Mission Editor (persistencia)
- `pcall()` obligatorio en TODA llamada DCS/MOOSE
- `continue` no existe en Lua 5.1 — usar `if/then` o `goto`
- Nomenclatura: `EVT_` `DATA_` `PTS_` `ZONE_` `CAMP_` `WH_` `CSAR_` `FTR_`
- GitHub como fuente de verdad única · ningún código sin autorización previa

---

## 📋 BACKLOG (17 ítems)

| # | Nombre | Clase MOOSE | Etapa | Estado |
|---|---|---|---|---|
| 1 | Warehouse Blue & Red | `Functional.Warehouse` | 5 | ⏳ |
| 2 | Fighters Rojos | `Ops.EasyGCICAP` | 6 | ⏳ |
| 3 | Escort Bombarderos | `Functional.Escort` | 6 | ⏳ |
| 4 | Escort Transporte | `Functional.Escort` | 6 | ⏳ |
| 5 | Transporte Suministros | `Ops.OpsTransport` | 2 | ⏳ |
| 6 | Transporte Soldados | `Ops.OpsTransport` | 2 | ⏳ |
| 7 | Soldados Atacan Base Roja | custom | 2 | ⏳ |
| 8 | Rescate Soldados | custom | 2 | ⏳ |
| 9 | CSAR | `Ops.CSAR` | 4 | ⏳ |
| 10 | Ground Control | `Core.MarkerOps_Base` | 2 | ⏳ |
| 11 | LORD (GCI aéreo) | `Ops.EasyGCICAP` | 6 | ⏳ |
| 12 | Bases CTLD | `Ops.CTLD` | 2 | ⏳ |
| 13 | Creación Template | custom | 2 | ⏳ |
| 14 | CarrierTemplate | `Ops.Airboss` | futura | ⏳ |
| 15 | TemplateSpawn | `SPAWN` | 2 | ⏳ |
| 16 | SkyNet Custom (IADS) | `Functional.Mantis` | 6 | ⏳ |
| 17 | TextToSpeech 🔴 PRIORIDAD ALTA | SRS | transversal | ⏳ |

---

| 12 | 07/07/2026 | 00:10 | 01:40 | 1h 30min | Revisión CAMP_Net + ReleaseNode + CheckZoneControl automático |
| 13 | 09/07/2026 | 20:30 | 22:50 | 2h 20min | WH_Manager v2 (combustible) + scripts de prueba AWACS/convoy + limpieza CAMP_Net |
| 14 | 10/07/2026 | 09:15 | 10:21 | 1h 06min | MISSIONS_Config v2 + MIS_Manager v2 (menú F10 por plataforma) + STATUS_Manager v1 |

**Total acumulado sesiones 1-14: ~39h 56min**

---

## 🎯 Pendientes para sesión 15
1. **Probar WH_Manager en juego** — validar consumo/reabastecimiento de combustible por base
2. **Validar PTS_Manager con piloto humano** — sigue pendiente desde sesión 6
3. **Poblar MISSIONS_Config con misiones de campaña** (category = "campaign", desbloqueadas por CAMP_Net/ZONE_State) — reemplazar las 9 misiones de prueba
4. **TIMER_Manager** — timers de reconquista y ventanas de tiempo (etapa 2, aún sin empezar)

---

*Última actualización: 10/07/2026 — Sesión 14 CERRADA (10:21)*
