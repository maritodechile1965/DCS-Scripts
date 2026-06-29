# Prompts para Claude Code — Sincronización con GitHub

Proyecto: DCS Scripting (MOOSE/MIST) — Mario
Repo: https://github.com/maritodechile1965/DCS-Scripts

Reemplaza solo `<RUTA_LOCAL_DEL_REPO>` por la carpeta donde tengas el repo
clonado en tu computador (ej. C:\Users\Mario\DCS-Scripts o similar).

Estructura del repo:

DCS-Scripts/
├── readme.md
├── docs/
│   ├── Dashboard_Proyecto.md
│   ├── Dashboard_Visual.html
│   ├── Referencias_MOOSE.md
│   └── Ideas_Sueltas.md
├── scripts/
│   ├── EVT_Dispatcher.lua
│   ├── DATA_Core.lua
│   └── TEST_Handler.lua
└── prompts/
    └── Prompts_ClaudeCode_GitHub.md

---

## 1. PROMPT DE INICIO DE SESIÓN

Úsalo al abrir Claude Code antes de empezar a trabajar. Su objetivo es que
Claude Code lea el estado real del repo (no memoria, no asunciones) y te
entregue un resumen fresco antes de tocar nada.

```
Estoy iniciando una sesión de trabajo en el proyecto DCS Scripting
(MOOSE/MIST/Lua 5.1). Repo local: <RUTA_LOCAL_DEL_REPO>

Antes de hacer cualquier cambio, necesito que:

1. Leas el contenido actual de Dashboard_Proyecto.md y lo resumas:
   horas acumuladas, scripts terminados, scripts en desarrollo, y el
   backlog pendiente completo con sus números.

2. Leas Ideas_Sueltas.md y me digas si hay ideas registradas que aún
   no pasaron al backlog oficial.

3. Leas el código fuente real de TODOS los archivos .lua del repo
   (no asumas firmas de funciones ni estructuras de datos — léelas
   directamente del código). Presta especial atención a:
   - EVT_Dispatcher.lua (API de Subscribe/Unsubscribe, eventos registrados)
   - DATA_Core.lua (estructuras de datos y funciones públicas)
   - Cualquier otro módulo presente en el repo

4. Me entregues un resumen breve en español chileno con:
   - Estado real del proyecto (qué está terminado, qué está en desarrollo)
   - Cualquier inconsistencia que detectes entre el dashboard y el
     código real (ej. funciones documentadas que no existen en el
     código, o viceversa)
   - Convenciones de nombres vigentes (prefijos de módulo, casing)
     para que las respete en este chat

No modifiques ningún archivo todavía. Esto es solo para tener el
contexto fresco y correcto antes de empezar a trabajar.
```

---

## 2. PROMPT DE FIN DE SESIÓN

Úsalo al cerrar la sesión de trabajo, después de que los cambios de la
sesión (código nuevo, dashboard actualizado, etc.) ya estén guardados
en los archivos locales del repo.

```
Estoy cerrando la sesión de trabajo en el proyecto DCS Scripting.
Repo local: C:\Users\mario\Documents\DCS-Scripts

Necesito que hagas lo siguiente, en orden:

1. Ejecuta git status y muéstrame qué archivos cambiaron o se
   agregaron desde el último commit.

2. Revisa los cambios con git diff antes de hacer nada más, y
   confírmame brevemente qué representa cada cambio (qué archivo,
   qué se modificó en términos generales).

3. Si Dashboard_Proyecto.md no refleja todavía los cambios de hoy
   (nueva sesión registrada, scripts que cambiaron de estado, backlog
   actualizado), avísame ANTES de continuar — no lo edites tú mismo
   sin que yo confirme el contenido exacto de la sesión (fecha, hora
   de inicio/fin, tema).

4. Una vez que confirme que todo está correcto, haz:
   - git add con los archivos relevantes (nunca uses git add . a
     ciegas, lista qué archivos vas a agregar primero y espera mi ok)
   - git commit con un mensaje descriptivo en español, formato:
     "Sesión N: <resumen breve de lo trabajado>"
   - git push al repo remoto

5. Confírmame al final con el hash del commit y un resumen de una
   línea de lo que quedó subido.

No hagas push sin que yo haya confirmado el contenido del commit
primero.
```

---

## Notas de uso

- Estos prompts asumen que Mario ya cerró la sesión conversacional con
  Claude (chat) ANTES de pasar a Claude Code para el commit — el chat
  es donde se decide y valida el contenido, Claude Code es quien
  ejecuta los comandos git.
- Si en el futuro se agrega un script nuevo al backlog oficial, no es
  necesario modificar estos prompts — son genéricos y leen el estado
  real del repo cada vez.
- Si el repo crece y se subdividen carpetas (ej. /scripts, /docs),
  actualizar la ruta de lectura en el prompt de inicio para que cubra
  todas las subcarpetas relevantes.
