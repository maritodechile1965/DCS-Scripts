# 💡 Ideas Sueltas — Mecánicas y Conceptos para Futuras Misiones

Este documento es un **vaciadero de ideas**: cosas interesantes que vamos encontrando
(clases MOOSE, mecánicas, conceptos de misión) que NO están todavía en el backlog
oficial del `Dashboard_Proyecto.md`, pero que no queremos olvidar.

Cuando una idea madura y se decide desarrollar, se mueve formalmente al backlog
del dashboard con su número correspondiente.

---

## 📌 Ideas registradas

### TARS (MOVIDO AL BACKLOG — 07/07/2026)
**Fuente:** [`Ops.TARS`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.TARS.html) (clase oficial MOOSE)

Simula misiones de reconocimiento fotográfico y observación visual en DCS World.

**Por qué podría interesarnos:** complementa bien con Ground Control y con CSAR.

**Estado:** movido al backlog oficial de `Dashboard_Proyecto.md` como ítem **#18** (etapa 4).

*Agregado: 29/06/2026 — Movido al backlog: 07/07/2026*

---

### SCORING (DESCARTADO)
**Fuente:** [`Functional.Scoring`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Scoring.html) (clase oficial MOOSE)

**NOTA (sesión 5):** evaluado y descartado — bypasea EVT_Dispatcher, duplica DATA_Core, requiere os/io. Se construyó PTS_Manager propio en su lugar.

*Agregado: 29/06/2026*

---

### Bajas Colaterales / Daño Civil
Los `object_id` numéricos de DCS en el ledger como `Collateral` corresponden a edificios del mapa base. En el futuro cruzar contra catálogo de edificios para cuantificar daño civil. Por ahora registrados con `amount=0`.

*Agregado: 30/06/2026 — No prioritario*

---

### Grabación de Datos — Modelo Híbrido (DECISIÓN TOMADA — 01/07/2026)
**Estado:** Decisión confirmada. Pendiente de implementar en DATA_Export.

**Cómo funciona:**
- `DATA_Core` mantiene en memoria el ledger completo durante toda la sesión (IA + humanos)
- Al **aterrizar correctamente** (Land + motor apagado + PlayerLeaveUnit): graba CSV individual del piloto → `DCS_Pilot_<callsign>_<fecha>.csv`
- Al **fin de sesión** (~3 horas o cierre manual vía F10): graba ledger completo → `DCS_Session_<fecha>.csv`
- Piloto que se desconecta sin aterrizar → sus datos NO se graban individualmente (incentivo a volar y aterrizar correctamente), pero sus kills sí quedan en el ledger general de sesión

**Pendiente de construir en DATA_Export:**
- Detectar "aterrizaje correcto": evento `Land` + motor apagado + `PlayerLeaveUnit`
- `DATA_Export.WritePilotLog(pilotId)` → CSV individual del piloto
- `DATA_Export.WriteSessionLog()` → CSV de sesión completa con timestamp

*Agregado: 01/07/2026*

---

### Ranking de Pilotos (POSTERGADO — 01/07/2026)
Mario genera el ranking directamente en Excel con tabla dinámica sobre los CSVs existentes. Cuando se conecte la web, se implementará `DATA_Export.WriteRanking()`.

**Campos del ranking:** Callsign · Plataforma · Disparos A-A / Kills A-A (% efectividad) · Armas A-G / Impactos en blancos (% efectividad) · Horas voladas · Misiones realizadas.

*Agregado: 01/07/2026*

---

### Web de Pilotos — Actuación Diaria/Semanal/Mensual (IDEA FUTURA — 01/07/2026)
**Estado:** Registrada, no prioritaria. Arquitectura definida para cuando llegue el momento.

**Visión:** página web donde los pilotos ven su actuación individual y rankings comparativos.

**Arquitectura propuesta:**
```
DCS Server (Lua/MOOSE)
    → CSV (generado por DATA_Export al aterrizar / fin de sesión)
    → Script Python externo (vigila Logs/, procesa CSVs)
    → SQLite (base de datos local, sin servidor adicional)
    → Web / API REST (rankings, historial, estadísticas)
```

**Restricción técnica:** DCS no puede hablar directamente con una DB (sandbox Lua). El CSV es el puente obligatorio.

*Agregado: 01/07/2026*

---

### Persistencia entre Sesiones (DISEÑO PENDIENTE — 01/07/2026)
**Estado:** Diseño definido conceptualmente. Implementar junto con CAMPAIGN_Manager.

**El problema:** al reiniciar el servidor, DCS vuelve a cargar la misión desde cero — todas las unidades destruidas reaparecen.

**La solución acordada:**
- Las unidades tienen **nombres fijos** definidos por Mario en el Mission Editor
- Al fin de sesión, `DATA_Export` graba `DCS_Dead_Units.csv` con los nombres de unidades destruidas
- Al inicio de la siguiente sesión, un script Lua lee ese CSV y destruye esas unidades via `Unit:destroy()` — recreando el estado del mundo anterior
- Para daño de área (explosiones), `trigger.action.explosion()` como efecto visual secundario
- DCS tiene función nativa de autosave de estado en servidor — evaluarlo como alternativa o complemento

**Nota:** este approach solo funciona con unidades de nombres fijos (no spawneadas dinámicamente con MOOSE SPAWN que cambia nombres).

*Agregado: 01/07/2026*

---

### CAMPAIGN_Manager — Diseño Conceptual (PRÓXIMO GRAN BLOQUE — 01/07/2026)
**Estado:** Diseño conceptual completo. Próximo módulo a desarrollar en chat dedicado.

**Escenario:** **Siria** (cambio desde Golfo Pérsico — decidido 01/07/2026 para pruebas).

**Arquitectura del módulo:**
```
CAMPAIGN_Manager
├── ZONE_State       -- estado de cada zona/base (ROJA/NEUTRAL/AZUL)
├── MIS_Manager      -- misiones disponibles según estado de zonas
└── TIMER_Manager    -- timers de reconquista, ventanas de tiempo
```

**Dos tipos de misiones:**

**Tipo 1 — Simples (siempre disponibles, pocos puntos constantes):**
- CAP en zonas determinadas
- Transporte de combustible/armas
- Ataques menores a templates en el escenario
- CSAR

**Tipo 2 — De campaña (condiciones, muchos puntos, planificación):**
- Tienen prerequisitos (ej. SEAD antes de Strike)
- Tienen ventanas de tiempo (ej. solo de día)
- Se activan por eventos dinámicos (ej. unidad destruida, base capturada)
- Generan consecuencias en el mundo (nuevas misiones, timers de reconquista)

**Ejemplo de flujo de campaña:**
```
BASE_AEREA_SUR → Estado: ROJA
    ↓ SEAD exitoso
Estado: NEUTRALIZADA → mensaje a pilotos → disponible: Asalto con tropas
    ↓ si no hay asalto en 60 min → IA roja reconquista → vuelve a ROJA
    ↓ si hay asalto exitoso
Estado: AZUL → disponibles: logística, AAA (con puntos), transporte de aviones
    ↓ nuevas misiones se desbloquean según puntos de coalición
```

**Grafo de estados de zona:**
```
ROJA ←→ NEUTRALIZADA ←→ AZUL
 ↑___________reconquista___|
```

**Sistema de condiciones en MISSIONS_Config.lua:**
```lua
conditions = {
  requires   = { { mission = "SEAD_001", status = "completed" } },
  timeWindow = { start = "08:00", stop = "22:00" },
  trigger    = { type = "unit_destroyed", unit = "radar-norte-1" },
}
```

**Relación con el backlog actual:**
- Warehouse Blue & Red → inventario de recursos de CAMPAIGN_Manager
- Fighters Rojos → ZONE_State reconquista → SPAWN IA
- Transporte Suministros → misión simple siempre disponible
- Soldados Atacan Base → ZONE_State → IA terrestre
- Bases CTLD → zonas capturables de CAMPAIGN_Manager

**Sistema de economía (puntos para comprar recursos):**
- `DATA_Core.GetCoalition("blue").points` ya existe
- CAMPAIGN_Manager verifica puntos antes de mostrar opciones en F10
- Al comprar: descuenta puntos + hace spawn del elemento

**Sesiones de juego:**
- ~3 horas por sesión (puesta en marcha, marshal, push, navegación, ataque, RTB, envío de tropas, captura)
- Diseñadas para que una misión compleja quepa en una sesión completa

*Agregado: 01/07/2026 — Desarrollar en chat dedicado*

---

## 📝 Notas de uso

- Formato sugerido: **Nombre** → fuente → descripción → por qué interesa → fecha.
- Este documento se revisa periódicamente para decidir qué pasa al backlog oficial.

---
*Última actualización: 01/07/2026 — Sesión 8*
