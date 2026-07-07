--[[
====================================================================
 DATA_Export.lua
 Modulo de exportacion a CSV. Lee los datos desde DATA_Core y los
 escribe a disco usando io/lfs (requiere MissionScripting.lua
 modificado para habilitar io, lfs y os).

 Dependencias:
   - DATA_Core.lua (cargado antes)

 Version: v1
 Archivos generados en: <DCS_writedir>/Logs/
   - DCS_Points_Ledger.csv  -> ledger completo de puntos/kills
   - DCS_Weapon_Log.csv     -> disparos registrados por piloto
====================================================================
]]

DATA_Export = {}

--------------------------------------------------------------------
-- CONFIGURACIÓN
--------------------------------------------------------------------

-- Intervalo de grabación automática en segundos.
-- Default: 10800 = 3 horas. Modificar libremente sin tocar el resto.
-- Ejemplos: 300 = 5 min (para pruebas), 3600 = 1 hora, 10800 = 3 horas
DATA_Export.SAVE_INTERVAL_SECONDS = 10800

-- Ruta base de los logs (DCS writedir, ej. Saved Games\DCS\)
-- lfs.writedir() siempre termina en backslash en Windows.
local _logDir = nil
local function _getLogDir()
  if _logDir then return _logDir end
  local ok, dir = pcall(function() return lfs.writedir() end)
  if ok and dir then
    _logDir = dir .. "Logs\\"
    -- Crear el directorio si no existe (no falla si ya existe)
    pcall(function() lfs.mkdir(_logDir) end)
    return _logDir
  end
  return nil
end

--------------------------------------------------------------------
-- UTILIDADES INTERNAS
--------------------------------------------------------------------

-- Escapa un valor para CSV: si contiene coma, comilla o salto de
-- linea, lo envuelve en comillas dobles y escapa las comillas.
local function _csv(val)
  if val == nil then return "" end
  local s = tostring(val)
  if s:find('[,"\n\r]') then
    s = '"' .. s:gsub('"', '""') .. '"'
  end
  return s
end

-- Abre un archivo CSV, escribe el encabezado y retorna el handle.
-- Retorna nil si no se puede abrir.
local function _openCSV(filename, header)
  local dir = _getLogDir()
  if not dir then
    env.error("DATA_Export :: lfs no disponible. Verificar MissionScripting.lua.")
    return nil
  end
  local path = dir .. filename
  local file, err = io.open(path, "w")
  if not file then
    env.error("DATA_Export :: No se pudo crear " .. path .. " | " .. tostring(err))
    return nil
  end
  file:write(header .. "\n")
  return file, path
end

--------------------------------------------------------------------
-- API PUBLICA
--------------------------------------------------------------------

--- Exporta el ledger completo de puntos a CSV.
-- Escribe: DCS_Points_Ledger.csv en <writedir>/Logs/
-- @return boolean  true si se escribio correctamente
function DATA_Export.WritePointsLedger()
  local header = "clockTime,pilotId,pilotAircraft,coalition,category,domain,"
               .. "amount,weapon,targetName,targetType,mgrs,reason"

  local file, path = _openCSV("DCS_Points_Ledger.csv", header)
  if not file then return false end

  local ledger = DATA_Core.GetPointsLedger()
  local count  = 0

  for _, e in ipairs(ledger) do
    local line = table.concat({
      _csv(e.clockTime),
      _csv(e.pilotId),
      _csv(e.pilotAircraft),
      _csv(e.coalition),
      _csv(e.category),
      _csv(e.domain),
      _csv(e.amount),
      _csv(e.weapon),
      _csv(e.targetName),
      _csv(e.targetType),
      _csv(e.mgrs),
      _csv(e.reason),
    }, ",")
    file:write(line .. "\n")
    count = count + 1
  end

  file:close()
  local msg = string.format("DATA_Export :: Ledger exportado: %d entradas -> %s", count, path)
  env.info(msg)
  trigger.action.outText(msg, 15)
  return true
end

--- Exporta el log de disparos por piloto a CSV.
-- Lee DATA_Core._pilots[*].weaponsLog para cada piloto registrado.
-- Escribe: DCS_Weapon_Log.csv en <writedir>/Logs/
-- @return boolean
function DATA_Export.WriteWeaponLog()
  local header = "pilotId,pilotAircraft,coalition,weapon,targetId,hit,clockTime"

  local file, path = _openCSV("DCS_Weapon_Log.csv", header)
  if not file then return false end

  -- Iterar todos los pilotos registrados en DATA_Core
  -- Accedemos via GetPilot() buscando por los IDs del ledger
  -- (DATA_Core no expone iteracion directa de _pilots por diseño)
  local seen    = {}
  local count   = 0
  local ledger  = DATA_Core.GetPointsLedger()

  -- Recolectar pilotIds unicos del ledger
  for _, entry in ipairs(ledger) do
    if entry.pilotId and not seen[entry.pilotId] then
      seen[entry.pilotId] = true
    end
  end

  -- Escribir weaponsLog de cada piloto encontrado
  for pilotId, _ in pairs(seen) do
    local pilot = DATA_Core.GetPilot(pilotId)
    if pilot and pilot.weaponsLog then
      for _, shot in ipairs(pilot.weaponsLog) do
        local line = table.concat({
          _csv(pilot.id),
          _csv(pilot.aircraftType),
          _csv(pilot.coalition),
          _csv(shot.weapon),
          _csv(shot.targetId),
          _csv(shot.hit),
          _csv(shot.timestamp),
        }, ",")
        file:write(line .. "\n")
        count = count + 1
      end
    end
  end

  file:close()
  local msg = string.format("DATA_Export :: WeaponLog exportado: %d disparos -> %s", count, path)
  env.info(msg)
  trigger.action.outText(msg, 15)
  return true
end

--- Exporta todos los logs disponibles en una sola llamada.
-- Conveniente para disparar desde un trigger de tecla o al aterrizar.
function DATA_Export.WriteAll()
  local ok1 = DATA_Export.WritePointsLedger()
  local ok2 = DATA_Export.WriteWeaponLog()
  local ok3 = DATA_Export.WriteBaseStates()
  if ok1 and ok2 and ok3 then
    trigger.action.outText("DATA_Export :: Todos los logs exportados correctamente.", 15)
  else
    trigger.action.outText("DATA_Export :: Algunos logs no se pudieron exportar. Ver dcs.log.", 15)
  end
end

--- Exporta el estado actual de todas las bases a CSV.
-- Escribe: DCS_Base_State.csv en <writedir>/Logs/
-- Llamar al fin de cada sesión (junto con WriteAll).
-- @return boolean
function DATA_Export.WriteBaseStates()
  local header = "baseName,coalition,fixed"
  local file, path = _openCSV("DCS_Base_State.csv", header)
  if not file then return false end

  local states = DATA_Core.GetAllBaseStates()
  local count  = 0
  for baseName, state in pairs(states) do
    local line = table.concat({
      _csv(baseName),
      _csv(state.coalition),
      _csv(state.fixed and "true" or "false"),
    }, ",")
    file:write(line .. "\n")
    count = count + 1
  end

  file:close()
  local msg = string.format("DATA_Export :: Base states exportados: %d bases → %s", count, path)
  env.info(msg)
  trigger.action.outText(msg, 10)
  return true
end

--- Lee DCS_Base_State.csv y aplica las coaliciones en DCS + DATA_Core.
-- Llamar al inicio de la misión (en un DO SCRIPT de MISSION START,
-- DESPUÉS de cargar todos los scripts principales).
-- Solo aplica bases con fixed=false que hayan cambiado de coalición.
-- @return boolean
function DATA_Export.RestoreBaseStates()
  local dir = _getLogDir()
  if not dir then return false end

  local path = dir .. "DCS_Base_State.csv"
  local file, err = io.open(path, "r")
  if not file then
    env.info("DATA_Export :: RestoreBaseStates: no existe CSV previo (" .. tostring(err) .. ") — usando estado inicial.")
    return false
  end

  local lineNum = 0
  local restored = 0
  for line in file:lines() do
    lineNum = lineNum + 1
    if lineNum > 1 then  -- saltar header
      local parts = {}
      for field in (line .. ","):gmatch("([^,]*),") do
        table.insert(parts, field)
      end

      local baseName  = parts[1] or ""
      local coalition = parts[2] or ""
      local fixed     = parts[3] == "true"

      if baseName ~= "" and not fixed then
        local updated = DATA_Core.SetBaseCoalition(baseName, coalition)
        if updated then
          local ok = pcall(function()
            local ab = Airbase.getByName(baseName)
            if ab then
              local side = coalition == "blue" and coalition.side.BLUE or coalition.side.RED
              ab:autoCapture(false)
              coalition.addAirfield(side, baseName)
            end
          end)
          if ok then restored = restored + 1 end
        end
      end
    end
  end

  file:close()
  local msg = string.format("DATA_Export :: Bases restauradas: %d → desde %s", restored, path)
  env.info(msg)
  trigger.action.outText(msg, 10)
  return true
end

--------------------------------------------------------------------
-- REGISTRO AUTOMATICO DEL MENU F10
-- Al cargar el modulo, agrega automaticamente un item en el menu
-- F10 → Other → "Exportar logs (CSV)" disponible para todos los
-- jugadores en la mision.
--------------------------------------------------------------------
pcall(function()
  missionCommands.addCommand(
    "Exportar logs (CSV)",
    nil,
    function()
      DATA_Export.WriteAll()
    end
  )
  env.info("DATA_Export :: Menu F10 registrado: 'Exportar logs (CSV)'")
end)
