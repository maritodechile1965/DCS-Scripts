# 📚 Referencias — Documentación y Repositorios MOOSE

Este archivo centraliza enlaces de referencia externos (documentación oficial,
repositorios, ejemplos) usados como apoyo para el desarrollo del proyecto.
Se actualiza a medida que encontramos nuevas fuentes útiles.

---

## 🔗 Repositorios oficiales MOOSE (GitHub)

| Repositorio | Descripción | Uso para este proyecto |
|---|---|---|
| [MOOSE](https://github.com/FlightControl-Master/MOOSE) | Código fuente Lua completo del framework | Consulta de implementación interna de clases (ej. `EVENTHANDLER`) |
| [MOOSE_INCLUDE](https://github.com/FlightControl-Master/MOOSE_INCLUDE) | Archivo `Moose.lua` / `Moose_.lua` listo para incluir en misiones | **Fuente oficial del `Moose.lua` que cargamos vía `loadfile()`** — verificar que esté actualizado |
| [MOOSE_MISSIONS](https://github.com/FlightControl-Master/MOOSE_MISSIONS) | Misiones de demostración empaquetadas (.miz) | Ejemplos reales y funcionales — revisar antes de diseñar Warehouse, CSAR, Transporte, etc. |
| [Moose_Community_Scripts](https://github.com/FlightControl-Master/Moose_Community_Scripts) | Scripts/snippets hechos por la comunidad | Referencia de enfoque para LORD (GCI aéreo) y SkyNet Custom |
| [MOOSE_DOCS](https://github.com/FlightControl-Master/MOOSE_DOCS) | Generador del sitio de documentación | Solo referencia, no código |

**Repositorios marcados "outdated" (NO usar como referencia):** MOOSE_GUIDES, MOOSE_MISSIONS_DYNAMIC, MOOSE_MISSIONS_UNPACKED, MOOSE_COMMUNITY_MISSIONS, MOOSE_TOOLS.

---

## 🔗 Páginas de documentación MOOSE (sitio web)

| Página | Contenido |
|---|---|
| [Usage Guide](https://flightcontrol-master.github.io/MOOSE/archive/guide-usage.html) | Conceptos de Clases, Objetos, Herencia. Índice a guías por categoría (AI, Tasking, Cargo, Functional, Wrapper, Core) |
| [Repositories](https://flightcontrol-master.github.io/MOOSE/repositories.html) | Mapa de todos los repositorios oficiales (fuente de la tabla de arriba) |
| [AI classes guide](https://flightcontrol-master.github.io/MOOSE/archive/classes-ai.html) | Relevante para Fighters Rojos, Escort, LORD/GCI |
| [Cargo classes guide](https://flightcontrol-master.github.io/MOOSE/archive/classes-cargo.html) | Relevante para Transporte Suministros, CTLD |
| [Core classes guide](https://flightcontrol-master.github.io/MOOSE/archive/classes-core.html) | Relevante para EVT_Dispatcher (schedulers, event handlers) |

---

## ⚠️ Aclaración importante: MOOSE_DOCS vs MOOSE_DOCS_DEVELOP

Estas páginas **NO son misiones de ejemplo** — son el **catálogo de documentación de clases** de MOOSE (descripción de cada clase, no código de misión funcional). Las misiones de ejemplo reales (.miz, código) están en el repositorio separado `MOOSE_MISSIONS` (ver tabla de repositorios arriba).

Existen dos ramas (branches) de este mismo catálogo:

| | [MOOSE_DOCS](https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/index.html) (master) | [MOOSE_DOCS_DEVELOP](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/index.html) (develop) |
|---|---|---|
| Qué es | Documentación de la versión **estable/release** de MOOSE | Documentación de la versión **en desarrollo activo** (próxima release, posiblemente no estable) |
| Coincide con | El `Moose.lua` que descargamos de `MOOSE_INCLUDE` | Puede tener clases o cambios de API más nuevos, no siempre probados |
| Estado al 29/06/2026 | Comparadas clase por clase, **ambas ramas mostraban el mismo set de clases** en esta fecha (sin diferencias detectadas en el índice general) | — |

**Regla de uso para el proyecto:**
1. Usar **MOOSE_DOCS (master)** como referencia principal — es lo que coincide con nuestro `Moose.lua` cargado vía `loadfile()`.
2. Consultar **MOOSE_DOCS_DEVELOP** solo si una clase necesaria no aparece en master, o si sospechamos una versión más nueva con método/parámetro que no existe en la estable.
3. Si hay diferencia de comportamiento entre ambas al implementar algo, documentarlo aquí.

---



**Principio guía del proyecto:** minimizar trabajo propio, reutilizar lo que MOOSE ya resolvió. No reinventamos la rueda — implementamos, adaptamos, simplificamos o mejoramos las clases oficiales según nuestra arquitectura y necesidad real, en lugar de programar todo desde cero.

Fuente: [índice completo de clases MOOSE (rama develop)](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/index.html)

| Script del backlog | Clase MOOSE oficial a evaluar primero |
|---|---|
| CSAR / Rescate Soldados | [`Ops.CSAR`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.CSAR.html) · [`Functional.AICSAR`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.AICSAR.html) |
| Bases CTLD | [`Ops.CTLD`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.CTLD.html) — ya incluido oficialmente en MOOSE |
| Warehouse Blue/Red | [`Functional.Warehouse`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Warehouse.html) · familia `Ops.Airwing` / `Ops.Brigade` / `Ops.Fleet` / `Ops.Legion` (warehouses especializados aire/tierra/mar) |
| LORD (GCI aéreo) | [`Ops.EasyGCICAP`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.EasyGCICAP.html) — "Create your A2A Defenses" |
| Fighters Rojos | `Ops.EasyGCICAP` (mismo) o clases AI de interceptación |
| Escort Bombarderos / Escort Transporte | [`Functional.Escort`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Escort.html) |
| CarrierTemplate | [`Ops.Airboss`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.Airboss.html) — maneja recuperaciones CASE I/II/III, justo las fases que describimos |
| Transporte Suministros / Transporte Soldados | [`Ops.OpsTransport`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.OpsTransport.html) |
| SkyNet Custom (IADS propio) | [`Functional.Mantis`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Mantis.html) — sistema de targeting/intercepción para defensas aéreas, equivalente oficial de Skynet — punto de partida/comparación |
| Ground Control | [`Core.MarkerOps_Base`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Core.MarkerOps_Base.html) — gestión de marcas F10 |
| EVT_Dispatcher (ya construido) | [`Core.Event`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Core.Event.html) — confirma que nuestro diseño Pub/Sub está alineado con el modelo interno de MOOSE |

**Flujo de trabajo a partir de ahora, por cada ítem del backlog:**
1. Revisar si existe una clase MOOSE oficial que cubra el caso (tabla de arriba).
2. Evaluar si la clase tal cual sirve, o si necesita una capa propia encima (respetando nuestra nomenclatura: `WH_`, `CSAR_`, `FTR_`, etc.) para integrarse al `EVT_Dispatcher` y al resto del proyecto.
3. Solo si no existe nada reutilizable o la clase oficial no encaja, se diseña desde cero.

---

## 🔧 Flujo de trabajo recomendado: repos GitHub (local vs consulta web)

**Decisión (29/06/2026):** enfoque híbrido.

1. **Mario descarga/clona los repos relevantes** (ej. `MOOSE_MISSIONS`) a su disco local — para abrir `.miz` reales en DCS, probarlos en vivo, y buscar rápido en todos los archivos con su editor (Notepad++/VS Code/Claude Code). Claude nunca puede ejecutar una misión ni acceder al disco local de Mario directamente.
2. **Claude sigue consultando la web (`web_fetch`)** cuando se necesite analizar/explicar/comparar código puntual de un archivo específico del repo — más simple para casos sueltos.
3. **Para análisis profundo y recurrente de un archivo concreto:** mejor que Mario **suba ese `.lua` puntual al proyecto** (como con los PDFs) — así Claude lo lee instantáneo vía `project_knowledge_search`, sin depender de fetches web ni de límites de conexión, y queda disponible permanentemente.

---
- Estos enlaces son para **consulta y referencia de diseño**, no para copiar código directo — siempre adaptamos a la convención de nombres y arquitectura propia del proyecto (ver `Dashboard_Proyecto.md`).
- Cuando lleguemos a un módulo específico del backlog, revisar primero si hay ejemplo relevante en `MOOSE_MISSIONS` o `Moose_Community_Scripts`.

---
*Última actualización: 29/06/2026*
