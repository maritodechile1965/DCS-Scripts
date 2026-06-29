# 📊 Dashboard del Proyecto — DCS Scripting (MOOSE/MIST)

## ⏱️ Horas trabajadas
| Sesión | Fecha | Inicio | Fin | Duración | Tema |
|---|---|---|---|---|---|
| 1 | 28/06/2026 | 23:20 | 00:20 (29/06) | 1h 00min | Creación de dashboard y arquitectura del Event Dispatcher |
| 2 | 29/06/2026 | 00:30 | 01:50 | 1h 20min | Prueba de Event Handlers (EVT_Dispatcher + TEST_Handler) |
| 3 | 29/06/2026 | 06:40 | 08:20 | 1h 40min | Actualización dashboard / Cierre validación EVT_Dispatcher (BaseCaptured) / Investigación clases MOOSE y repos |
| 4 | 29/06/2026 | 08:00 | — | — | Descripción objetivo scripts y campaña dinámica / Reconciliación de dashboard |

**Total acumulado: 4h 00min** (sesiones 1–3 cerradas; sesión 4 en curso)
**Hoy (29/06/2026): 3h 00min** + sesión 4 en curso

---

## 🔧 Script en desarrollo
*(ninguno en desarrollo activo en este momento)*

## ✅ Scripts terminados y funcionando
- **EVT_Dispatcher.lua** — ✅ **13/13 eventos validados en juego.**
  - Base: MOOSE `EVENTHANDLER` (no Lua puro).
  - Pub/Sub central con `Subscribe()` / `Unsubscribe()`.
  - Aislamiento de errores por `pcall`.
  - Eventos confirmados: Birth, Takeoff, Land, PlayerEnterUnit, PlayerLeaveUnit, Dead, Crash, Hit, Shot, Ejection, LandingAfterEjection, PilotDead, **BaseCaptured**.
  - Listo para que otros módulos del backlog se suscriban a él.

- **TEST_Handler.lua** — ✅ Cumplió su propósito de validación. Queda como módulo de referencia/debug; no es necesario mantenerlo activo en producción (se puede remover del `loadfile()` de carga, o dejar comentado).

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
14. CarrierTemplate — cubierta de portaaviones por fase (despegue, recuperaciones, recuperación de emergencia)
15. TemplateSpawn — spawn de templates (ej. helipad) en cualquier punto del mapa, por coordenada/referencia
16. SkyNet Custom (nombre por definir) — IADS propio inspirado en Skynet, a medida del proyecto
17. 🔴 **TextToSpeech (PRIORIDAD ALTA)** — capacidad transversal de voz dinámica vía SRS (DCS-SimpleRadio-Standalone), para LORD/GCI, CSAR, Ground Control y futuro AWACS

### 💡 Ideas en evaluación (no oficiales aún — ver Ideas_Sueltas.md)
- DATA_Core — estructura central de "base de datos" en memoria (Pilotos, Coalición, Objetivos/Unidades, Misiones activas). Identificado como bloque crítico previo a Warehouse y Puntos.
- PTS_Manager — lógica de puntos (gana/pierde) para piloto y coalición.
- TARS (`Ops.TARS`) — misiones de reconocimiento foto/visual.
- SCORING (`Functional.Scoring`) — puntaje oficial MOOSE + CSV, posible conexión a Warehouse.

### 🗺️ Alcance de campaña dinámica (Golfo Pérsico) — registrado 29/06/2026
Visión general del proyecto completo descrita por Mario: 2 coaliciones (Blue humana / Red IA), Warehouse con consumo de recursos, sistema de puntos individual y de coalición, IADS propio, CSAR con template de spawn a ~30nm, misiones de reconocimiento, menú de suministros por puntos, refuerzo de IADS, misiones terrestres de invasión, misiones de ala fija (SEAD/Escort/Strike/Runway Attack) con mínimo de pilotos requerido, bitácora de vuelo por piloto (máx. 2 misiones aéreas/día), página web de misiones (target folder, SPINS, JIPTL, ATO, FPL, NAV Card, Target Data Package), puntos por A-A y pérdidas, CSAR con puntos, logística, tabla de objetos/objetivos con coordenadas y estado, registro de armamento disparado/ranking, reporte automatizado post-misión, área de carrier con heli de rescate, CTLD simplificado, guerra terrestre de tanques con CAS, MEDEVAC, CarrierOps, ataques a buques, CAPs IA. Esta visión se descompone progresivamente en el backlog oficial a medida que cada pieza madura.

---

## 🧷 Comandos de referencia — Carga de scripts vía `loadfile()` (DO SCRIPT, Mission Editor)

```lua
assert(loadfile("C:\\Users\\TU_USUARIO\\Saved Games\\DCS\\Scripts\\Moose.lua"))()
assert(loadfile("C:\\Users\\TU_USUARIO\\DCS_Scripts\\EVT_Dispatcher.lua"))()
```

> Orden obligatorio: Moose.lua primero, EVT_Dispatcher.lua después, ambos en triggers `MISSION START`. Reemplazar `TU_USUARIO` y rutas reales. Doble barra invertida `\\` obligatoria en Lua.

---

## 🏛️ Decisiones de arquitectura vigentes
- Event Dispatcher Central construido sobre MOOSE (`EVENTHANDLER`/`_EVENTDISPATCHER`), no Lua puro — para no duplicar el motor de eventos.
- Convención de nombres fija para todo el proyecto:
  - Dispatcher central: `EVT_Dispatcher`
  - Prefijos por módulo: `WH_`, `CSAR_`, `FTR_`, `ESC_`, `TRP_`, `GC_`, `CTLD_`
  - Casing: `PascalCase` (objetos MOOSE), `camelCase` (variables locales), `UPPER_SNAKE_CASE` (constantes/flags)
  - Handlers por módulo: `<PREFIJO>_Handler`
  - Regla extendida: nombres de variables, objetos MOOSE y nomenclatura deben mantenerse idénticos/consistentes entre todos los scripts del proyecto (sin renombrar equivalentes entre módulos)
- No modificar scripts ya funcionando salvo necesidad justificada.
- Ningún script se escribe sin autorización explícita previa.

---
*Última actualización: 29/06/2026 — Sesión 4 (08:00)*
