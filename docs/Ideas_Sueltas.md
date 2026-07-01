# 💡 Ideas Sueltas — Mecánicas y Conceptos para Futuras Misiones

Este documento es un **vaciadero de ideas**: cosas interesantes que vamos encontrando
(clases MOOSE, mecánicas, conceptos de misión) que NO están todavía en el backlog
oficial del `Dashboard_Proyecto.md`, pero que no queremos olvidar.

Cuando una idea madura y se decide desarrollar, se mueve formalmente al backlog
del dashboard con su número correspondiente.

---

## 📌 Ideas registradas

### TARS
**Fuente:** [`Ops.TARS`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.TARS.html) (clase oficial MOOSE)

Simula misiones de reconocimiento fotográfico y observación visual en DCS World. Los jugadores vuelan una aeronave o helicóptero de reconocimiento designado, activan la "película" desde el menú de radio F10, sobrevuelan unidades enemigas dentro de la envolvente de vuelo del sensor, y regresan a un aeródromo o FARP aliado para disparar el debrief. Los objetivos detectados se publican como marcadores F10 visibles solo para la coalición, con créditos de puntaje opcionales.

**Por qué podría interesarnos:** complementa bien con Ground Control (designación de objetivos) y con un futuro sistema de scoring. Posible sinergia con LORD/GCI (detección) y con CSAR (reconocimiento de pilotos derribados antes del rescate).

*Agregado: 29/06/2026*

---

### ~~SCORING~~ — DESCARTADO
**Fuente:** [`Functional.Scoring`](https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Scoring.html) (clase oficial MOOSE)

**Estado:** descartado (ver `Dashboard_Proyecto.md`, sección "Ideas en evaluación") — bypasea `EVT_Dispatcher`, duplica `DATA_Core`, y requiere `os`/`io`.

Administra el puntaje de los logros de los jugadores, y crea un archivo CSV registrando los eventos de puntaje y resultados, para uso en sitios web de equipo o escuadrón.

**Idea de aplicación propia:** usar estos puntos para otorgar "beneficios" tanto al jugador individual como a la coalición (ej. desbloquear recursos en Warehouse, prioridad de refuerzos, ventajas tácticas). Conecta directamente con el `EVT_Dispatcher` (eventos Hit/Dead/Kill ya cableados) y con Warehouse Blue/Red para materializar esos beneficios.

*Agregado: 29/06/2026*

---

### 🔴 TEXT-TO-SPEECH (TTS) vía SRS — **PRIORIDAD ALTA**
**Fuente:** [Text to Speech — MOOSE](https://flightcontrol-master.github.io/MOOSE/advanced/text-to-speech.html) · clase relacionada a revisar: `Sound.SRS`

Capacidad transversal (no es un script único, sino algo que varios módulos pueden usar): generar voz dinámica y enviarla a una frecuencia de radio específica vía **DCS-SimpleRadio-Standalone (SRS)**. El piloto debe estar conectado al cliente SRS y sintonizado en la frecuencia correcta para escucharlo — **no funciona con el VOIP nativo de DCS**.

Mecanismo: ejecutable externo `DCS-SR-ExternalAudio.exe` recibe texto + frecuencia + modulación (AM/FM) + coalición, y genera el audio en esa frecuencia. Soporta voz por defecto o Google Cloud TTS (voces más naturales, requiere cuenta/credenciales `.json`).

**Por qué es prioridad alta:** transversal a múltiples módulos del backlog:
- **LORD (GCI aéreo)** → llamadas de control tipo "Bandits, bearing X, range Y" por voz
- **CSAR** → Mayday del piloto eyectado, confirmaciones de rescate por radio
- **Ground Control / futuro AWACS** → probablemente comparte este mismo mecanismo

**Movido al backlog oficial como item 17 "TextToSpeech" en `Dashboard_Proyecto.md`** — pendiente: revisar si la clase `Sound.SRS` de MOOSE ya envuelve `DCS-SR-ExternalAudio.exe` en una API más cómoda antes de llamarlo directo.

*Agregado: 29/06/2026 — prioridad alta*

---

## 📝 Notas de uso

- Formato sugerido por idea: **Nombre** → fuente (si aplica) → descripción breve → por qué podría interesarnos → fecha agregada.
- Este documento se revisa periódicamente para decidir qué ideas pasan al backlog oficial.

---
*Última actualización: 29/06/2026*
