# 📊 Dashboard del Proyecto — DCS Scripting (MOOSE/MIST)

## ⏱️ Horas trabajadas
| Sesión | Fecha | Inicio | Fin | Duración | Tema |
|---|---|---|---|---|---|
| 1 | 28/06/2026 | 23:20 | 00:20 (29/06) | 1h 00min | Creación de dashboard y arquitectura del Event Dispatcher |
| 2 | 29/06/2026 | 00:30 | 01:50 | 1h 20min | Prueba de Event Handlers (EVT_Dispatcher + TEST_Handler) |
| 3 | 29/06/2026 | 06:40 | 08:20 | 1h 40min | Actualización dashboard / Cierre validación EVT_Dispatcher (BaseCaptured) / Investigación clases MOOSE y repos |
| 4 | 29/06/2026 | 08:00 | 09:50 | 1h 50min | Diseño y escritura de DATA_Core v1 / Migración del proyecto a GitHub (estructura docs-scripts-prompts) |

**Total acumulado: 5h 50min**
**Hoy (29/06/2026): 4h 50min**

---

## 🔧 Script en desarrollo
- **DATA_Core.lua** — Estado: **escrito (v1), pendiente de prueba en misión real.**
  - Estructuras en memoria: Pilotos, Coaliciones, Targets/Objetivos, Misiones activas.
  - API pública: `GetOrCreatePilot`, `AddPilotPoints`, `CanFlyMissionToday`, `RegisterMissionFlown`, `AddLogbookEntry`, `RegisterShot`, `GetCoalition`, `AddCoalitionPoints`, `RegisterTarget`, `GetTarget`, `SetTargetDestroyed`, `CreateMission`, `GetMission`, `GetActiveMissions`.
  - Suscrito a `EVT_Dispatcher` (eventos `Shot`, `Dead`, `Crash`, `Takeoff`, `Land`, `PilotDead`, `Ejection`), usando las constantes `EVENTS.X` reales de MOOSE y leyendo los campos correctos del `EventData` nativo (`IniPlayerName`, `IniUnitName`, `WeaponName`, `TgtUnitName`).
  - Corrección aplicada en esta sesión: la primera versión asumía una firma de `Subscribe()` y una forma de `EventData` incorrectas; se corrigió tras revisar el código fuente real de `EVT_Dispatcher.lua`.
  - Sin persistencia a disco (decisión consciente: en memoria por ahora, se resetea con la misión).
  - **Próximo paso:** probar en una misión vacía junto con `EVT_Dispatcher`, confirmar en `dcs.log` el mensaje `"DATA_Core :: INICIADO correctamente, suscrito a EVT_Dispatcher."`.

## ✅ Scripts terminados y funcionando
- **EVT_Dispatcher.lua** — ✅ 13/13 eventos validados en juego. Sin cambios esta sesión.
- **TEST_Handler.lua** — ✅ Cumplió su propósito de validación. Sin cambios esta sesión.

---

## 📋 Scripts pendientes por desarrollar (backlog)
1. Warehouse Blue & Red
2. Fighters Rojos (CAP/intercept enemigo)
3. Escort Bombarderos
4. Escort Transporte
5. Transporte Suministros, paracaídas, combustible
6. Transporte Soldados
7. Soldados atacan Base Roja
8. Rescate Soldados
9. CSAR
10. Ground Control
11. LORD — GCI aéreo (rango de detección configurable)
12. Bases CTLD
13. Creación Template
14. CarrierTemplate — cubierta de portaaviones por fase
15. TemplateSpawn — spawn de templates por coordenada
16. SkyNet Custom (nombre por definir) — IADS propio
17. 🔴 **TextToSpeech (PRIORIDAD ALTA)** — voz dinámica vía SRS

### 💡 Ideas en evaluación (no oficiales aún — ver Ideas_Sueltas.md)
- PTS_Manager — lógica de puntos (gana/pierde) para piloto y coalición. Próximo bloque lógico después de validar DATA_Core en juego.
- TARS (`Ops.TARS`) — misiones de reconocimiento foto/visual.
- SCORING (`Functional.Scoring`) — puntaje oficial MOOSE + CSV, posible conexión a Warehouse.

---

## 🗂️ Infraestructura del proyecto — Migración a GitHub (decidida esta sesión)
- Repo: https://github.com/maritodechile1965/DCS-Scripts
- Estructura adoptada:
  ```
  DCS-Scripts/
  ├── readme.md
  ├── .gitignore
  ├── docs/      (este dashboard, dashboard visual, referencias MOOSE, ideas sueltas)
  ├── scripts/   (EVT_Dispatcher.lua, DATA_Core.lua, TEST_Handler.lua)
  └── prompts/   (prompts de Claude Code: inicio sesión, fin sesión, estructura inicial, conectar/push)
  ```
- Repo local en `C:\Users\mario\Documents\DCS`, inicializado con `git init` (historial propio, no clonado del remoto original).
- Primer commit local: `4eddded` (10 archivos).
- `core.autocrlf = true` configurado para evitar warnings de saltos de línea en Windows.
- El remoto original tenía 2 commits placeholder sin contenido de valor; Mario autorizó sobrescribirlos con `push --force-with-lease` (o `--force` si era necesario) desde el repo local.
- **Pendiente de confirmar en la próxima sesión:** verificar en el navegador que el push se reflejó correctamente en GitHub (carpetas docs/scripts/prompts visibles).
- A partir de ahora, GitHub es la fuente de verdad del proyecto — se reemplaza la subida manual de archivos sueltos a project knowledge por el flujo: prompt de inicio (Claude Code lee el repo real) → trabajo en chat → prompt de fin (Claude Code hace commit/push con confirmación de Mario).

---

## 🧷 Comandos de referencia — Carga de scripts vía `loadfile()` (DO SCRIPT, Mission Editor)

```lua
assert(loadfile("C:\\Users\\TU_USUARIO\\Saved Games\\DCS\\Scripts\\Moose.lua"))()
assert(loadfile("C:\\Users\\TU_USUARIO\\DCS_Scripts\\EVT_Dispatcher.lua"))()
assert(loadfile("C:\\Users\\TU_USUARIO\\DCS_Scripts\\DATA_Core.lua"))()
```

> Orden obligatorio: Moose.lua → EVT_Dispatcher.lua → DATA_Core.lua, todos en triggers `MISSION START`. Reemplazar `TU_USUARIO` y rutas reales. Doble barra invertida `\\` obligatoria en Lua.

---

## 🏛️ Decisiones de arquitectura vigentes
- Event Dispatcher Central construido sobre MOOSE (`EVENTHANDLER`/`_EVENTDISPATCHER`), no Lua puro — para no duplicar el motor de eventos.
- `DATA_Core` es la única "base de datos" en memoria del proyecto — los demás módulos deben leer/escribir a través de su API pública, nunca manipular tablas internas directamente.
- Convención de nombres fija para todo el proyecto:
  - Dispatcher central: `EVT_Dispatcher`
  - Módulo de datos: `DATA_Core`
  - Prefijos por módulo: `WH_`, `CSAR_`, `FTR_`, `ESC_`, `TRP_`, `GC_`, `CTLD_`
  - Casing: `PascalCase` (objetos MOOSE), `camelCase` (variables locales), `UPPER_SNAKE_CASE` (constantes/flags)
  - Handlers por módulo: `<PREFIJO>_Handler`
  - Regla extendida: nomenclatura idéntica entre todos los scripts del proyecto, sin renombrar equivalentes entre módulos
- No modificar scripts ya funcionando salvo necesidad justificada.
- Ningún script se escribe sin autorización explícita previa.
- Infraestructura: GitHub como fuente de verdad única (ver sección de arriba).

---
*Última actualización: 29/06/2026 — Sesión 4 cerrada (09:50)*
