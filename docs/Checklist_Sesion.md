# Checklist de sesion — Proyecto DCS Scripting

---

## AL INICIAR SESION

**1. Abrir Claude Code primero, en la carpeta del repo local**
   `C:\Users\mario\Documents\DCS-Scripts`

**2. Hacer git pull SIEMPRE antes de empezar**
   (aunque hayas trabajado ayer — puede haber cambios del chat online)
   ```
   git pull origin main
   ```

**3. Pegar el prompt de inicio de sesion**
   (`prompts/Prompts_ClaudeCode_GitHub.md`, seccion 1)
   Claude Code confirma el estado real del repo: dashboard, backlog,
   codigo fuente actual de los .lua — antes de tocar nada.

**4. Revisar lo que Claude Code reporto**
   - [ ] Hay alguna inconsistencia entre el dashboard y el codigo real?
   - [ ] Quedo algo pendiente de la sesion anterior sin resolver?
   - [ ] Hay scripts nuevos que no estaban antes? (ver punto TRABAJO OFFLINE)

**5. Ir al chat de Claude (claude.ai) y escribir:**
   inicio de sesion
   <fecha>
   <hora>
   Tema: <tema de hoy>

**6. Pedir que muestre el dashboard**
   para confirmar que coincide con lo que mostro Claude Code.

**7. Si hay desincronizacion entre repo y dashboard:**
   - [ ] Detenerse y resolverlo ANTES de empezar a trabajar
   - [ ] No avanzar con codigo nuevo sobre una base desincronizada

---

## TRABAJO OFFLINE (regla critica)

**Por que existe este problema:**
Cuando trabajas offline y creas scripts directamente en
`C:\Users\mario\Documents\DCS-Scripts\scripts\`, al retomar el chat
online Claude no sabe que existen. Claude trabaja sobre lo que tiene
en el project knowledge (que puede estar desactualizado) y podemos
terminar con dos versiones distintas del mismo archivo.

**Las 3 reglas que lo resuelven:**

REGLA 1 — GitHub como unico punto de entrada:
Antes de empezar cualquier sesion — online u offline — hacer git pull
para tener la ultima version. Antes de cerrar — online u offline —
hacer git push. Sin excepcion.

REGLA 2 — Documentar en el commit lo que hiciste offline:
El mensaje del commit debe describir exactamente que hiciste:
   git commit -m "Trabajo offline: cree SND_Convoy_Hatay.lua — convoy con script propio"
Asi cuando retomamos aqui, lo primero que hago es leer el repo y veo
exactamente que hay nuevo sin que tengas que explicarlo.

REGLA 3 — Al iniciar sesion online, sincronizar primero:
Si hubo trabajo offline, decirle a Claude al inicio:
   "trabaje offline, revisa el repo"
Claude lee los archivos nuevos antes de proponer nada. Esto evita que
Claude proponga codigo que duplica o contradice lo que ya tienes.

**Ejemplo real que ya ocurrio (09/07/2026):**
En el log de DCS aparecio:
   [SND_HATAY] SND_Convoy_Hatay_MOOSE_V1_5 cargado.
Ese script fue creado offline y Claude no lo tenia registrado. Si
hubieramos avanzado sin informarlo, podriamos haber duplicado
funcionalidad o generado conflictos con EVT_Dispatcher o DATA_Core.

Cuando trabajas sin conexion y creas o modificas scripts:

**Antes de empezar a trabajar offline:**
   - [ ] Hacer git pull para partir de la version mas reciente

**Al crear un script nuevo offline:**
   - [ ] Usar la nomenclatura del proyecto (prefijos WH_, CAMP_, etc.)
   - [ ] Agregar al inicio del archivo un comentario con:
         -- Creado offline: <fecha>
         -- Pendiente: revisar integracion con EVT_Dispatcher / DATA_Core

**Al terminar el trabajo offline:**
   - [ ] git add + git commit con mensaje descriptivo:
         "Trabajo offline: cree NombreScript.lua — descripcion breve"
   - [ ] git push origin main

**Al retomar sesion online despues de trabajo offline:**
   - [ ] Decirle a Claude: "trabaje offline, revisa el repo"
   - [ ] Claude leera los archivos nuevos antes de proponer nada
   - [ ] Revisar juntos si el script offline necesita integracion con
         EVT_Dispatcher, DATA_Core, PTS_Manager u otros modulos
   - [ ] No asumir que Claude ya sabe lo que hiciste — siempre informar

**Por que es importante:**
   Si creas un script offline y no lo informas, Claude puede proponer
   codigo que duplica o contradice lo que ya tienes. Esto genera
   inconsistencias dificiles de detectar y corregir.

---

## AL TERMINAR SESION

**1. En el chat de Claude, escribir:**
   fin de sesion
   <fecha>
   <hora>

**2. Pedir explicitamente que actualice:**
   - [ ] Dashboard_Proyecto.md
   - [ ] Dashboard_Visual.html
   (No asumir que se actualizan solos — hay que pedirlo cada vez)

**3. Descargar los archivos actualizados**
   desde el chat (boton de descarga / present_files)

**4. Copiar los archivos a la carpeta correcta del repo local**
   docs/ para dashboards y documentos
   scripts/ para archivos .lua

**5. Abrir Claude Code y pegar el prompt de fin de sesion**
   (`prompts/Prompts_ClaudeCode_GitHub.md`, seccion 2)
   Muestra git status / git diff — revisar antes de aprobar

**6. Confirmar el contenido del commit**
   - [ ] Los archivos listados son los que esperabas?
   - [ ] El mensaje de commit describe bien lo trabajado?
   - [ ] Si hubo trabajo offline en esta sesion, esta incluido?

**7. Autorizar el commit + push**
   (Claude Code no lo hace solo sin tu ok explicito)

**8. Verificar en el navegador (Ctrl+F5)**
   https://github.com/maritodechile1965/DCS-Scripts

---

## REGLAS QUE RIGEN SIEMPRE

- Ningun script se escribe sin autorizacion explicita previa de Mario
- No modificar scripts que ya funcionan, salvo necesidad justificada
- Nomenclatura identica entre todos los modulos del proyecto
- GitHub es la fuente de verdad unica — no hay "version local correcta"
- git pull antes de empezar, git push al terminar — siempre
- Si un script nuevo aparece en el repo sin que Claude lo sepa,
  informarlo al inicio de la siguiente sesion online

---
*Version 2 — actualizada 09/07/2026 — agrega protocolo trabajo offline*
