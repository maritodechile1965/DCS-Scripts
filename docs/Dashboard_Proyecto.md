# 📊 Dashboard del Proyecto — DCS Scripting (MOOSE/MIST)

## ⏱️ Horas trabajadas
| Sesión | Fecha | Inicio | Fin | Duración | Tema |
|---|---|---|---|---|---|
| 1 | 28/06/2026 | 23:20 | 00:20 (29/06) | 1h 00min | Creación de dashboard y arquitectura del Event Dispatcher |
| 2 | 29/06/2026 | 00:30 | 01:50 | 1h 20min | Prueba de Event Handlers (EVT_Dispatcher + TEST_Handler) |
| 3 | 29/06/2026 | 06:40 | 08:20 | 1h 40min | Actualización dashboard / Cierre validación EVT_Dispatcher (BaseCaptured) / Investigación clases MOOSE |
| 4 | 29/06/2026 | 08:00 | 09:50 | 1h 50min | Diseño y escritura de DATA_Core v1 / Migración del proyecto a GitHub |
| 5* | 29/06/2026 | 14:15 | ~21:15 | ~7h | Validación DATA_Core + PTS_Manager v2 + ledger ampliado (hora/avión/dominio/tipo) |
| 6 | 30/06/2026 | 07:40 | 10:00 | 2h 20min | PTS_Manager Ground Impacts — validación targets terrestres |
| 7 | 30/06/2026 | 11:30 | 14:00 | 2h 30min | PTS_Manager v3 + WEAPON tracking + mensajes pantalla + DATA_Export |
| 8 | 01/07/2026 | 10:10 | 14:45 | 4h 35min | Estrategia grabación / Persistencia / CAMPAIGN_Manager / MissionsGenerator / Referencias_Tecnicas |

**Total acumulado: ~23h 25min**
*Sesión 5 extendida sin cierre formal intermedio.

---

## ✅ Scripts terminados y funcionando
- **EVT_Dispatcher.lua** — ✅ 13/13 eventos validados en juego.
- **TEST_Handler.lua** — ✅ Cumplió su propósito de validación.
- **DATA_Core.lua** — ✅ v1 VALIDADO EN JUEGO.
  - Estructuras: Pilotos (con `aircraftType`), Coaliciones, Targets/Objetivos, Misiones activas, Ledger de puntos.
  - 8 suscripciones: PlayerEnterUnit, Shot, Dead, Crash, Takeoff, Land, PilotDead, Ejection.
  - API: `GetOrCreatePilot`, `GetPilot`, `SetPilotAircraftType`, `AddPilotPoints`, `CanFlyMissionToday`, `RegisterMissionFlown`, `ResetDailyCounters`, `AddLogbookEntry`, `RegisterShot`, `GetCoalition`, `AddCoalitionPoints`, `RegisterTarget`, `GetTarget`, `SetTargetDestroyed`, `CreateMission`, `GetMission`, `GetActiveMissions`, `AddPointsLedgerEntry`, `GetPointsLedger`, `PointsLedgerToCSV`.

- **PTS_Manager.lua** — ✅ v3 VALIDADO EN JUEGO (A-A y terrestre).
  - Categorías: `TargetDestroyed`, `EnemyKill`, `BlueOnBlue`, `Collateral`, `OwnLoss`.
  - Campos del ledger: `clockTime` (HH:MM:SS mundo DCS), `pilotId`, `pilotAircraft`, `coalition`, `category`, `domain` ("air"/"ground"), `amount`, `weapon`, `targetName`, `targetType`, `mgrs`, `reason`.
  - Reparto proporcional de puntos entre contribuyentes.
  - 3 fallbacks de dominio en `_onHit` y `_onDeadOrCrash`.
  - Soporte para scenery DCS (object_id numérico) → `Collateral` + `domain="ground"`.
  - Soporte para edificios estáticos colocados por el usuario via `RegisterTarget()`.
  - **Pendiente validar:** `BlueOnBlue`, `TargetDestroyed` con piloto humano (todas las pruebas de terrestre fueron con IA).
  - MGRS funciona para todos los hits reales (via DCS nativo en _onHit). MGRS para MISS es nil por decisión consciente: cuando MOOSE dispara el impact callback, el objeto DCS del arma ya fue destruido ("Object doesn't exist") — no es posible obtener la posición. Los tiros perdidos en terreno no necesitan posición exacta.
  - targetType clasificado correctamente: VEHICLE, AIRCRAFT, BUILDING, STRUCTURE, SHIP via `Object.getCategory()` DCS nativo.
  - Nueva estructura de mensajes en pantalla: `[SHOT] piloto | aeronave | arma | MGRS_lanzamiento` y `[IMPACT] objeto | tipo | MGRS | alt | arma | aeronave | piloto`
  - **Pendiente validar:** BlueOnBlue, TargetDestroyed con piloto humano, WeaponLog con humano (actualmente 0 disparos porque todas las pruebas de terrestre fueron con IA).

- **DATA_Export.lua** — ✅ v1 IMPLEMENTADO (escritura a disco pendiente de validar en juego).
  - Requiere `MissionScripting.lua` modificado para habilitar `io`/`lfs`/`os`.
  - API: `WritePointsLedger`, `WriteWeaponLog`, `WriteAll`.
  - Genera `DCS_Points_Ledger.csv` y `DCS_Weapon_Log.csv` en `<writedir>/Logs/`.
  - Registra automáticamente un ítem en el menú F10 → Other → "Exportar logs (CSV)".
  - **Modelo híbrido pendiente de construir** (ver sección "Pendiente en DATA_Export" más abajo): `WritePilotLog`, `WriteSessionLog`, detección de aterrizaje correcto.

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
11. LORD — GCI aéreo
12. Bases CTLD
13. Creación Template
14. CarrierTemplate
15. TemplateSpawn
16. SkyNet Custom (IADS)
17. 🔴 **TextToSpeech (PRIORIDAD ALTA)**

### 💡 Ideas en evaluación
- **Bajas colaterales** (futuro) — cruzar `object_id` numéricos del ledger contra catálogo de edificios del mapa para cuantificar daño civil/estructural. No prioritario.
- TARS (`Ops.TARS`) — misiones de reconocimiento.
- ~~SCORING (`Functional.Scoring`)~~ — descartado (bypasea EVT_Dispatcher, duplica DATA_Core, requiere os/io).

---

## 🎯 Pendientes para sesión 9 (validación PTS_Manager)
1. Validar con **piloto humano disparando** (no IA): confirmar [SHOT]/[IMPACT] en pantalla, pilotAircraft en ledger, WeaponLog con datos reales
2. Validar **BlueOnBlue** en juego
3. Validar **TargetDestroyed** con piloto humano

## 🏗️ Próximo gran bloque: CAMPAIGN_Manager (chat dedicado)
- Escenario: **Siria** (cambio desde Golfo Pérsico — decidido sesión 8)
- Módulos: `ZONE_State`, `MIS_Manager`, `TIMER_Manager`
- Archivo de configuración: `MISSIONS_Config.lua` (Lua nativo, en el repo)
- Ver diseño completo en `Ideas_Sueltas.md`

## 🔧 Pendiente en DATA_Export (modelo híbrido)
- Detectar "aterrizaje correcto" (Land + motor apagado + PlayerLeaveUnit)
- `DATA_Export.WritePilotLog(pilotId)` → CSV individual del piloto
- `DATA_Export.WriteSessionLog()` → CSV de sesión completa con timestamp
- Persistencia: `DCS_Dead_Units.csv` para recrear destrucción entre sesiones

---

## 🗂️ Infraestructura — GitHub
- Repo: https://github.com/maritodechile1965/DCS-Scripts
- Directorio local: `C:\Users\mario\Documents\DCS-Scripts`
- Último commit confirmado: `0f5e9e4` (sincronizado)
- Estructura:
  ```
  DCS-Scripts/
  ├── readme.md / .gitignore
  ├── docs/      (Dashboard_Proyecto.md, Dashboard_Visual.html, Referencias_MOOSE.md, Ideas_Sueltas.md, Checklist_Sesion.md, Referencias_Tecnicas.md)
  ├── scripts/   (EVT_Dispatcher.lua, DATA_Core.lua, PTS_Manager.lua, DATA_Export.lua, TEST_Handler.lua)
  └── prompts/   (Prompts_ClaudeCode_GitHub.md, Prompt_Estructura_Inicial_Repo.md, Prompt_Conectar_Push_GitHub.md)
  ```

---

## 🧷 Comandos — Carga loadfile() en Mission Editor

```lua
assert(loadfile("C:\\Users\\mario\\Saved Games\\DCS\\Scripts\\Moose.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\EVT_Dispatcher.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Core.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\PTS_Manager.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Export.lua"))()
```

Orden obligatorio. Doble barra invertida `\\` obligatoria en Lua.

---

## 🏛️ Decisiones de arquitectura vigentes
- Dispatcher central `EVT_Dispatcher` sobre MOOSE `EVENTHANDLER` (no Lua puro).
- `DATA_Core` es la única fuente de estado del proyecto — los módulos no tocan tablas internas directamente.
- `PTS_Manager` es "sin estado" — toda persistencia vive en `DATA_Core`.
- Módulos se suscriben SOLO a los eventos que necesitan, agregando incrementalmente.
- No usar `os` de Lua — usar `timer.getTime()` y `timer.getAbsTime()`.
- `PointsLedgerToCSV()` genera el CSV en memoria; `DATA_Export.lua` ya implementa la escritura a disco (`WritePointsLedger`, `WriteWeaponLog`, `WriteAll`), pendiente de validar en juego con `os`/`io`/`lfs` habilitados en `MissionScripting.lua`. Modelo híbrido de grabación (por piloto + por sesión) pendiente de construir — ver `Ideas_Sueltas.md`.
- Convención: `EVT_Dispatcher`, `DATA_Core`, prefijos `WH_` `CSAR_` `FTR_` `ESC_` `TRP_` `GC_` `CTLD_` `PTS_` `DATA_`, `PascalCase`/`camelCase`/`UPPER_SNAKE`.
- No modificar scripts funcionando salvo necesidad justificada. Ningún código sin autorización previa.
- GitHub como fuente de verdad única.

---
*Última actualización: 01/07/2026 — Sesión 8 CERRADA (14:45)*
