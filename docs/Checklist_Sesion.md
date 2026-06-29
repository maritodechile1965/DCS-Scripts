# ✅ Checklist de sesión — Proyecto DCS Scripting

---

## 🟢 AL INICIAR SESIÓN

**1. Abrir Claude Code primero, en la carpeta del repo local**
   `C:\Users\mario\Documents\DCS`

**2. Pegar el prompt de inicio de sesión**
   (`prompts/Prompts_ClaudeCode_GitHub.md`, sección 1)
   → Esto te confirma el estado real del repo: dashboard, backlog,
   código fuente actual de los .lua — antes de tocar nada.

**3. Revisar lo que Claude Code te reportó**
   - [ ] ¿Hay alguna inconsistencia entre el dashboard y el código real?
   - [ ] ¿Quedó algo pendiente de la sesión anterior sin resolver?

**4. Ir al chat de Claude (claude.ai) y escribir:**
   ```
   inicio de sesión
   <fecha>
   <hora>
   Tema: <tema de hoy>
   ```

**5. Pedir que te muestre el dashboard**
   ("muéstrame el dashboard") para confirmar que coincide con lo que
   te mostró Claude Code en el paso 2-3.

**6. Si hay desincronización entre repo y dashboard mostrado:**
   - [ ] Detenerse y resolverlo ANTES de empezar a trabajar
   - [ ] No avanzar con código nuevo sobre una base desincronizada

---

## 🔴 AL TERMINAR SESIÓN

**1. En el chat de Claude, escribir:**
   ```
   fin de sesión
   <fecha>
   <hora>
   ```

**2. Pedir explícitamente que actualice:**
   - [ ] `Dashboard_Proyecto.md`
   - [ ] `Dashboard_Visual.html`
   (No asumir que se actualizan solos — hay que pedirlo cada vez)

**3. Descargar ambos archivos actualizados**
   desde el chat (botón de descarga / present_files)

**4. Copiar los archivos descargados a la carpeta correcta del repo local**
   `C:\Users\mario\Documents\DCS\docs\`
   (reemplazando los anteriores)

**5. Si hubo código nuevo o modificado en la sesión (.lua):**
   - [ ] Confirmar que también está copiado en
         `C:\Users\mario\Documents\DCS\scripts\`

**6. Abrir Claude Code y pegar el prompt de fin de sesión**
   (`prompts/Prompts_ClaudeCode_GitHub.md`, sección 2)
   → Te muestra `git status` / `git diff` — revisar antes de aprobar

**7. Confirmar el contenido del commit cuando Claude Code te lo muestre**
   - [ ] ¿Los archivos listados son los que esperabas?
   - [ ] ¿El mensaje de commit describe bien lo trabajado?

**8. Autorizar el commit + push**
   (Claude Code no lo hace solo sin tu ok explícito)

**9. Verificar en el navegador**
   (con Ctrl+F5 para evitar caché) que GitHub refleje los cambios:
   https://github.com/maritodechile1965/DCS-Scripts

**10. Anotar mentalmente o en notas propias cualquier pendiente**
    para que el prompt de inicio de la próxima sesión lo capture
    (ej. "falta probar X en juego", "decidir Y antes de seguir con Z")

---

## ⚠️ Reglas que no van en la checklist pero rigen siempre

- Ningún script se escribe sin autorización explícita previa
- No modificar scripts que ya funcionan, salvo necesidad justificada
- Nomenclatura idéntica entre todos los módulos del proyecto
- GitHub es la fuente de verdad — ya no se suben archivos sueltos a
  project knowledge de Claude

---
*Versión 1 — creada 29/06/2026*
