# 📊 Dashboard del Proyecto — DCS Scripting (MOOSE/MIST)

## ⏱️ Horas trabajadas
| Sesión | Fecha | Inicio | Fin | Duración | Tema |
|---|---|---|---|---|---|
| 1 | 28/06/2026 | 23:20 | 00:20 (29/06) | 1h 00min | Creación de dashboard y arquitectura del Event Dispatcher |
| 2 | 29/06/2026 | 00:30 | 01:50 | 1h 20min | Prueba de Event Handlers (EVT_Dispatcher + TEST_Handler) |
| 3 | 29/06/2026 | 06:40 | 08:20 | 1h 40min | Actualización dashboard / Cierre validación EVT_Dispatcher (BaseCaptured) / Investigación clases MOOSE y repos |
| 4 | 29/06/2026 | 08:00 | 09:50 | 1h 50min | Diseño y escritura de DATA_Core v1 / Migración del proyecto a GitHub |
| 5 | 29/06/2026 | 14:15 | 16:20 | 2h 05min | Validación en juego de DATA_Core + diseño y escritura de PTS_Manager |

**Total acumulado: 7h 55min**

---

## ✅ Scripts terminados y funcionando
- **EVT_Dispatcher.lua** — ✅ 13/13 eventos validados en juego.
- **TEST_Handler.lua** — ✅ Cumplió su propósito de validación.
- **DATA_Core.lua** — ✅ **v1 VALIDADO EN JUEGO** (sesión 5).
  - Estructuras: Pilotos, Coaliciones, Targets/Objetivos, Misiones activas, **Ledger de puntos** (nuevo, sesión 5).
  - 8 suscripciones a eventos de vuelo/piloto.
  - Nueva API (sesión 5): `AddPointsLedgerEntry`, `GetPointsLedger`, `PointsLedgerToCSV` (esta última solo concatena strings en memoria, no usa `io`, lista para exportar el día que se habilite `os`/`io`/`lfs` en `MissionScripting.lua` sin tocar nada de la lógica existente).
  - 2 bugs corregidos en validación: suscripción faltante a `PlayerEnterUnit`, y uso de `os` (sandboxeado por DCS) reemplazado por `timer.getTime()`.

## 🔧 Script en desarrollo
- **PTS_Manager.lua** — Estado: **escrito (v1), pendiente de prueba en juego.**
  - Tabla `POINTS` con valores editables: `TARGET_DESTROYED` (+15), `ENEMY_KILL` (+10), `BLUE_ON_BLUE` (-20), `COLLATERAL` (0), `OWN_LOSS` (-10) — todos placeholder, ajustables libremente sin tocar la lógica.
  - Se suscribe a `Hit`, `Dead`, `Crash` (3 eventos nuevos en el proyecto).
  - Registra cada impacto (arma, piloto, coalición, posición MGRS) en un log temporal por unidad objetivo.
  - Al morir la unidad, clasifica en 4 categorías: `TargetDestroyed` (target oficial de misión), `EnemyKill`, `BlueOnBlue` (fuego amigo, penaliza), `Collateral` (sin atribución clara, neutro por defecto).
  - Reparte puntos en partes iguales entre todos los pilotos que contribuyeron al kill (no solo "el último impacto").
  - Penaliza automáticamente al bando que pierde la unidad (`OwnLoss`), de forma simétrica al que la destruyó.
  - Cada evento de puntos queda registrado en el ledger de `DATA_Core` con: piloto, coalición, categoría, monto, arma, nombre del target, MGRS y motivo — pensado desde el diseño para exportarse a CSV/Excel más adelante.
  - **Próximo paso:** probar en juego (derribo real) y confirmar con `#DATA_Core.GetPointsLedger()` que se registró correctamente.

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
- TARS (`Ops.TARS`) — misiones de reconocimiento.
- ~~SCORING (`Functional.Scoring`)~~ — **evaluado y descartado en sesión 5**: bypasea EVT_Dispatcher (su propio HandleEvent), tiene tabla de jugadores propia (duplica DATA_Core), y requiere `os`/`io` habilitado para CSV. Se construyó PTS_Manager propio en su lugar, reutilizando solo el concepto de reparto entre contribuyentes y escalas configurables.
- **DATA_Export.lua** (futuro) — módulo que lea `DATA_Core.PointsLedgerToCSV()` y escriba a disco, el día que se decida habilitar `os`/`io`/`lfs` en `MissionScripting.lua`. No requiere tocar PTS_Manager ni DATA_Core cuando se construya.

---

## 🗂️ Infraestructura del proyecto — GitHub
- Repo: https://github.com/maritodechile1965/DCS-Scripts
- Directorio local: `C:\Users\mario\Documents\DCS-Scripts` (scripts en `...\DCS-Scripts\scripts\`)
- Estructura:
  ```
  DCS-Scripts/
  ├── readme.md
  ├── .gitignore
  ├── docs/      (dashboards, referencias MOOSE, ideas sueltas, checklist de sesión)
  ├── scripts/   (EVT_Dispatcher.lua, DATA_Core.lua, PTS_Manager.lua, TEST_Handler.lua)
  └── prompts/   (inicio sesión, fin sesión, estructura inicial, conectar/push)
  ```
- GitHub es la fuente de verdad del proyecto.
- Sesión 5 cerrada y subida al repo (commit Sesión 5).

---

## 🧷 Comandos de referencia — Carga de scripts vía `loadfile()` (DO SCRIPT, Mission Editor)

```lua
assert(loadfile("C:\\Users\\mario\\Saved Games\\DCS\\Scripts\\Moose.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\EVT_Dispatcher.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\DATA_Core.lua"))()
assert(loadfile("C:\\Users\\mario\\Documents\\DCS-Scripts\\scripts\\PTS_Manager.lua"))()
```

> Orden obligatorio: Moose.lua → EVT_Dispatcher.lua → DATA_Core.lua → PTS_Manager.lua, todos en triggers `MISSION START`.

---

## 🏛️ Decisiones de arquitectura vigentes
- Event Dispatcher Central construido sobre MOOSE (`EVENTHANDLER`), no Lua puro.
- `DATA_Core` es la única "base de datos" en memoria del proyecto.
- Los módulos se suscriben SOLO a los eventos que realmente necesitan, agregando suscripciones incrementalmente.
- No usar la librería `os` de Lua — usar `timer.getTime()`. Funciones de exportación a texto (CSV en memoria) SÍ se pueden escribir ya, evitando solo la escritura real a disco (`io.open`) hasta que se decida habilitar el sandbox.
- `PTS_Manager` no almacena estado propio — toda la persistencia vive en `DATA_Core` (ledger de puntos incluido). Los módulos de lógica de negocio (puntos, misiones, CSAR, etc.) son "sin estado", leen/escriben siempre a través de `DATA_Core`.
- Se evaluó y descartó adoptar la clase nativa `Functional.Scoring` de MOOSE por incompatibilidad arquitectónica (ver sección de ideas en evaluación).
- Convención de nombres: prefijos `WH_` `CSAR_` `FTR_` `ESC_` `TRP_` `GC_` `CTLD_` `PTS_` `DATA_`; `PascalCase`/`camelCase`/`UPPER_SNAKE_CASE`.
- No modificar scripts ya funcionando salvo necesidad justificada.
- Ningún script se escribe sin autorización explícita previa.
- Infraestructura: GitHub como fuente de verdad única.

---
*Última actualización: 29/06/2026 — Sesión 5 cerrada (16:20)*
