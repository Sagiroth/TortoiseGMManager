TortoiseGMManager = TortoiseGMManager or {}

local function trim(value)
    value = value or ""
    value = string.gsub(value, "^%s+", "")
    return string.gsub(value, "%s+$", "")
end

local function lower(value) return string.lower(value or "") end
local function copy(values)
    local result = {}
    local key, value
    for key, value in pairs(values or {}) do result[key] = value end
    return result
end

function TortoiseGMManager.Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffd8a657TortoiseGMManager:|r " .. tostring(message)) end
end

function TortoiseGMManager.FindEntry(value)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(value))
    local i, j
    for i = 1, table.getn(TortoiseGMManager.commands or {}) do
        local entry = TortoiseGMManager.commands[i]
        if entry.id == value or lower(TortoiseGMManager.NormalizeCommand(entry.command)) == normalized then return entry end
        for j = 1, table.getn(entry.legacyCommands or {}) do
            if lower(TortoiseGMManager.NormalizeCommand(entry.legacyCommands[j])) == normalized then return entry end
        end
    end
    return nil
end

function TortoiseGMManager.MigrateFavourites()
    local old = TortoiseGMManagerDB.favourites or {}
    local migrated, included = {}, {}
    local i
    for i = 1, table.getn(old) do
        local entry = TortoiseGMManager.FindEntry(old[i])
        local id = entry and entry.id or nil
        if id and not included[id] then table.insert(migrated, id); included[id] = true end
    end
    TortoiseGMManagerDB.favourites = migrated
    TortoiseGMManagerDB.favouritesVersion = 2
end

function TortoiseGMManager.InitializeDB()
    if not TortoiseGMManagerDB then TortoiseGMManagerDB = {} end
    if not TortoiseGMManagerDB.history then TortoiseGMManagerDB.history = {} end
    if not TortoiseGMManagerDB.favourites then TortoiseGMManagerDB.favourites = {} end
    TortoiseGMManager.MigrateFavourites()
    if TortoiseGMManagerDB.lastCategory == "history" or TortoiseGMManagerDB.lastCategory == "quick" or not TortoiseGMManagerDB.lastCategory then TortoiseGMManagerDB.lastCategory = "favourites" end
    if TortoiseGMManagerDB.minimapX == nil then TortoiseGMManagerDB.minimapX = 52 end
    if TortoiseGMManagerDB.minimapY == nil then TortoiseGMManagerDB.minimapY = 52 end
    if TortoiseGMManagerDB.framePoint == nil then
        TortoiseGMManagerDB.framePoint, TortoiseGMManagerDB.frameRelativePoint = "CENTER", "CENTER"
        TortoiseGMManagerDB.frameX, TortoiseGMManagerDB.frameY = 0, 15
    end
end

function TortoiseGMManager.NormalizeCommand(command)
    command = trim(command)
    command = string.gsub(command, "[\r\n]+", " ")
    command = string.gsub(command, "%s+", " ")
    if command ~= "" and string.sub(command, 1, 1) ~= "." then command = "." .. command end
    return command
end

function TortoiseGMManager.InitializeValues(entry, current)
    local values = copy(current)
    local i
    for i = 1, table.getn(entry and entry.arguments or {}) do
        local argument = entry.arguments[i]
        if values[argument.key] == nil and argument.default ~= nil then values[argument.key] = argument.default end
    end
    return values
end

function TortoiseGMManager.ValidateValues(entry, values)
    local i
    for i = 1, table.getn(entry and entry.arguments or {}) do
        local argument = entry.arguments[i]
        local value = values and values[argument.key]
        if argument.required and (value == nil or trim(tostring(value)) == "") then return false, argument.label .. " is required." end
        if value ~= nil and trim(tostring(value)) ~= "" and argument.type == "number" then
            local number = tonumber(value)
            if not number then return false, argument.label .. " must be a number." end
            if argument.min and number < argument.min then return false, argument.label .. " is below the minimum." end
            if argument.max and number > argument.max then return false, argument.label .. " is above the maximum." end
        end
    end
    return true, nil
end

function TortoiseGMManager.ComposeValues(entry, values)
    if not entry then return "" end
    values = TortoiseGMManager.InitializeValues(entry, values)
    local parts, i = {}, nil
    for i = 1, table.getn(entry.arguments or {}) do
        local value = values[entry.arguments[i].key]
        if value ~= nil and trim(tostring(value)) ~= "" then table.insert(parts, tostring(value)) end
    end
    local suffix = table.concat(parts, " ")
    return TortoiseGMManager.NormalizeCommand(entry.command .. (suffix ~= "" and " " .. suffix or ""))
end

function TortoiseGMManager.AdjustNumber(argument, value, direction)
    local number = tonumber(value) or tonumber(argument.default) or 0
    number = number + ((tonumber(argument.step) or 1) * direction)
    if argument.min and number < argument.min then number = argument.min end
    if argument.max and number > argument.max then number = argument.max end
    return number
end

function TortoiseGMManager.CycleToggle(argument, value, direction)
    local options = argument.options or {}
    if table.getn(options) == 0 then return value end
    local index, i = 1, nil
    for i = 1, table.getn(options) do if options[i].value == value then index = i; break end end
    index = index + (direction or 1)
    if index > table.getn(options) then index = 1 elseif index < 1 then index = table.getn(options) end
    return options[index].value
end

function TortoiseGMManager.GetOptionLabel(argument, value)
    local i
    for i = 1, table.getn(argument.options or {}) do if argument.options[i].value == value then return argument.options[i].label end end
    return tostring(value or "")
end

function TortoiseGMManager.GetInteraction(entry)
    if not entry then return "load" end
    if entry.danger or TortoiseGMManager.IsDangerous(entry.command) then return "review" end
    if table.getn(entry.arguments or {}) > 0 or (entry.hint and entry.hint ~= "") then return "configure" end
    if entry.direct then return "execute" end
    return "load"
end

function TortoiseGMManager.ComposeLookupResult(entry, values, id)
    values = TortoiseGMManager.InitializeValues(entry, values)
    local i, filled = nil, false
    for i = 1, table.getn(entry and entry.arguments or {}) do
        if entry.arguments[i].type == "lookup-id" then values[entry.arguments[i].key] = tostring(id); filled = true; break end
    end
    if not filled then return values, TortoiseGMManager.Compose(entry, tostring(id)) end
    return values, TortoiseGMManager.ComposeValues(entry, values)
end

function TortoiseGMManager.IsDangerous(command)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    if TortoiseGMManager.safeCommands and TortoiseGMManager.safeCommands[normalized] then return false end
    local i
    for i = 1, table.getn(TortoiseGMManager.dangerPrefixes or {}) do
        local prefix = lower(TortoiseGMManager.NormalizeCommand(TortoiseGMManager.dangerPrefixes[i]))
        if normalized == prefix or string.sub(normalized, 1, string.len(prefix) + 1) == prefix .. " " then return true end
    end
    return false
end

function TortoiseGMManager.AddHistory(command)
    TortoiseGMManager.InitializeDB()
    local i
    for i = table.getn(TortoiseGMManagerDB.history), 1, -1 do if TortoiseGMManagerDB.history[i] == command then table.remove(TortoiseGMManagerDB.history, i) end end
    table.insert(TortoiseGMManagerDB.history, 1, command)
    while table.getn(TortoiseGMManagerDB.history) > 20 do table.remove(TortoiseGMManagerDB.history) end
end
function TortoiseGMManager.SetPendingConfirmation(command) TortoiseGMManager.pendingCommand, TortoiseGMManager.pendingUntil = command, GetTime() + 5 end
function TortoiseGMManager.ClearPendingConfirmation() TortoiseGMManager.pendingCommand, TortoiseGMManager.pendingUntil = nil, nil end

function TortoiseGMManager.Execute(command)
    command = TortoiseGMManager.NormalizeCommand(command)
    if command == "" or command == "." then if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Enter a GM command first.", "error") end; return false end
    if string.len(command) > 255 then if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Command is longer than the Vanilla chat limit (255 characters).", "error") end; return false end
    if TortoiseGMManager.IsDangerous(command) then
        local now = GetTime()
        if TortoiseGMManager.pendingCommand ~= command or not TortoiseGMManager.pendingUntil or now > TortoiseGMManager.pendingUntil then
            TortoiseGMManager.SetPendingConfirmation(command)
            if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Dangerous command armed. Click EXECUTE again within 5 seconds to confirm.", "warn") end
            return false
        end
    end
    TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.AddHistory(command)
    if TortoiseGMManager.BeginLookupCommand then TortoiseGMManager.BeginLookupCommand(command) end
    SendChatMessage(command, "SAY")
    if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Sent: " .. command, "ok") end
    if TortoiseGMManager.RefreshList then TortoiseGMManager.RefreshList() end
    return true
end

function TortoiseGMManager.CommandMatchesEntry(entry, command)
    if not entry then return false end
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    local candidates, i = { entry.command }, nil
    for i = 1, table.getn(entry.legacyCommands or {}) do table.insert(candidates, entry.legacyCommands[i]) end
    for i = 1, table.getn(candidates) do
        local base = lower(TortoiseGMManager.NormalizeCommand(candidates[i]))
        if normalized == base or string.sub(normalized, 1, string.len(base) + 1) == base .. " " then return true end
    end
    return false
end

function TortoiseGMManager.RequestHelp(value)
    local entry = type(value) == "table" and value or nil
    if not entry then
        local normalized, best, i = TortoiseGMManager.NormalizeCommand(value), nil, nil
        for i = 1, table.getn(TortoiseGMManager.commands or {}) do
            local candidate = TortoiseGMManager.commands[i]
            if TortoiseGMManager.CommandMatchesEntry(candidate, normalized) and (not best or string.len(candidate.command) > string.len(best.command)) then best = candidate end
        end
        entry = best
    end
    local command = entry and entry.command or value
    command = TortoiseGMManager.NormalizeCommand(command)
    if command == "" or command == "." then return false end
    SendChatMessage(".help " .. string.sub(command, 2), "SAY"); return true
end

function TortoiseGMManager.IsFavourite(value)
    TortoiseGMManager.InitializeDB()
    local entry = TortoiseGMManager.FindEntry(value)
    local id = entry and entry.id or value
    local i
    for i = 1, table.getn(TortoiseGMManagerDB.favourites) do if TortoiseGMManagerDB.favourites[i] == id then return true end end
    return false
end
function TortoiseGMManager.ToggleFavourite(entry)
    if not entry or not entry.id then return false end
    TortoiseGMManager.InitializeDB()
    local i
    for i = table.getn(TortoiseGMManagerDB.favourites), 1, -1 do if TortoiseGMManagerDB.favourites[i] == entry.id then table.remove(TortoiseGMManagerDB.favourites, i); return false end end
    table.insert(TortoiseGMManagerDB.favourites, entry.id); return true
end
function TortoiseGMManager.GetFavouriteCommands()
    TortoiseGMManager.InitializeDB(); local results, i = {}, nil
    for i = 1, table.getn(TortoiseGMManagerDB.favourites) do local entry = TortoiseGMManager.FindEntry(TortoiseGMManagerDB.favourites[i]); if entry then table.insert(results, entry) end end
    return results
end

function TortoiseGMManager.GetFilteredCommands(category, query)
    local source = category == "favourites" and TortoiseGMManager.GetFavouriteCommands() or (TortoiseGMManager.commands or {})
    local q, ranked, results = lower(trim(query)), { {}, {}, {}, {}, {} }, {}
    local i, j
    for i = 1, table.getn(source) do
        local entry = source[i]
        if category == "favourites" or category == "all" or entry.category == category then
            if q == "" then table.insert(results, entry) else
                local label, command = lower(entry.label), lower(entry.command)
                local details = lower((entry.id or "") .. " " .. (entry.hint or "") .. " " .. (entry.detail or "") .. " " .. (entry.lookupCommand or ""))
                for j = 1, table.getn(entry.legacyCommands or {}) do details = details .. " " .. lower(entry.legacyCommands[j]) end
                for j = 1, table.getn(entry.arguments or {}) do
                    local argument = entry.arguments[j]; details = details .. " " .. lower(argument.label)
                    local k; for k = 1, table.getn(argument.options or {}) do details = details .. " " .. lower(argument.options[k].label) end
                end
                local rank
                if label == q then rank = 1 elseif string.sub(label, 1, string.len(q)) == q then rank = 2 elseif string.find(label, q, 1, true) then rank = 3 elseif string.find(command, q, 1, true) then rank = 4 elseif string.find(details, q, 1, true) then rank = 5 end
                if rank then table.insert(ranked[rank], entry) end
            end
        end
    end
    if q ~= "" then for i = 1, 5 do for j = 1, table.getn(ranked[i]) do table.insert(results, ranked[i][j]) end end end
    return results
end

function TortoiseGMManager.GetComposerArgs(entry, command)
    if not entry then return trim(command) end
    command = trim(command); local base = trim(entry.command or "")
    if string.sub(lower(command), 1, string.len(base)) == lower(base) then return trim(string.sub(command, string.len(base) + 1)) end
    return command
end
function TortoiseGMManager.BuildLookupCommand(entry, query) if not entry or not entry.lookupCommand or trim(query) == "" then return nil end; return TortoiseGMManager.NormalizeCommand(entry.lookupCommand .. " " .. trim(query)) end
function TortoiseGMManager.ExecuteLookup(entry, query)
    local lookup = TortoiseGMManager.BuildLookupCommand(entry, query)
    if not lookup then return false end
    if string.find(trim(query), "^%d+$") then
        local values, command = TortoiseGMManager.ComposeLookupResult(entry, TortoiseGMManager.structuredValues, trim(query))
        TortoiseGMManager.structuredValues = values
        if TortoiseGMManager.LoadCommand then TortoiseGMManager.LoadCommand(command, entry, "Numeric ID loaded. Review, then EXECUTE.", values) end
        return true
    end
    TortoiseGMManager.AddHistory(lookup); if TortoiseGMManager.BeginLookup then TortoiseGMManager.BeginLookup(entry, query, lookup) end
    SendChatMessage(lookup, "SAY"); return true
end
function TortoiseGMManager.Compose(entry, args) return TortoiseGMManager.NormalizeCommand((entry and entry.command or "") .. (trim(args) ~= "" and " " .. trim(args) or "")) end
