TortoiseGMManager = TortoiseGMManager or {}

local function trim(value)
    if not value then
        return ""
    end
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function lower(value)
    return string.lower(value or "")
end

function TortoiseGMManager.Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffd8a657TortoiseGMManager:|r " .. tostring(message))
    end
end

function TortoiseGMManager.InitializeDB()
    if not TortoiseGMManagerDB then
        TortoiseGMManagerDB = {}
    end
    if not TortoiseGMManagerDB.history then
        TortoiseGMManagerDB.history = {}
    end
    if TortoiseGMManagerDB.lastCategory == nil then
        TortoiseGMManagerDB.lastCategory = "quick"
    end
    if TortoiseGMManagerDB.minimapX == nil then
        TortoiseGMManagerDB.minimapX = 52
    end
    if TortoiseGMManagerDB.minimapY == nil then
        TortoiseGMManagerDB.minimapY = 52
    end
    if TortoiseGMManagerDB.framePoint == nil then
        TortoiseGMManagerDB.framePoint = "CENTER"
        TortoiseGMManagerDB.frameRelativePoint = "CENTER"
        TortoiseGMManagerDB.frameX = 0
        TortoiseGMManagerDB.frameY = 15
    end
end

function TortoiseGMManager.NormalizeCommand(command)
    command = trim(command)
    command = string.gsub(command, "[\r\n]+", " ")
    command = string.gsub(command, "%s+", " ")

    if command ~= "" and string.sub(command, 1, 1) ~= "." then
        command = "." .. command
    end

    return command
end

function TortoiseGMManager.IsDangerous(command)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))

    if TortoiseGMManager.safeCommands and TortoiseGMManager.safeCommands[normalized] then
        return false
    end

    local i
    for i = 1, table.getn(TortoiseGMManager.dangerPrefixes or {}) do
        local prefix = lower(TortoiseGMManager.NormalizeCommand(TortoiseGMManager.dangerPrefixes[i]))
        if normalized == prefix or string.sub(normalized, 1, string.len(prefix) + 1) == prefix .. " " then
            return true
        end
    end
    return false
end

function TortoiseGMManager.AddHistory(command)
    TortoiseGMManager.InitializeDB()

    local history = TortoiseGMManagerDB.history
    local i
    for i = table.getn(history), 1, -1 do
        if history[i] == command then
            table.remove(history, i)
        end
    end

    table.insert(history, 1, command)
    while table.getn(history) > 20 do
        table.remove(history, table.getn(history))
    end
end

function TortoiseGMManager.SetPendingConfirmation(command)
    TortoiseGMManager.pendingCommand = command
    TortoiseGMManager.pendingUntil = GetTime() + 5
end

function TortoiseGMManager.ClearPendingConfirmation()
    TortoiseGMManager.pendingCommand = nil
    TortoiseGMManager.pendingUntil = nil
end

function TortoiseGMManager.Execute(command)
    command = TortoiseGMManager.NormalizeCommand(command)

    if command == "" or command == "." then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("Enter a GM command first.", "error")
        end
        return false
    end

    if string.len(command) > 255 then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("Command is longer than the Vanilla chat limit (255 characters).", "error")
        end
        return false
    end

    if TortoiseGMManager.IsDangerous(command) then
        local now = GetTime()
        if TortoiseGMManager.pendingCommand ~= command or not TortoiseGMManager.pendingUntil or now > TortoiseGMManager.pendingUntil then
            TortoiseGMManager.SetPendingConfirmation(command)
            if TortoiseGMManager.SetStatus then
                TortoiseGMManager.SetStatus("Dangerous command armed. Click RUN again within 5 seconds to confirm.", "warn")
            end
            return false
        end
    end

    TortoiseGMManager.ClearPendingConfirmation()
    TortoiseGMManager.AddHistory(command)
    if TortoiseGMManager.BeginLookupCommand then
        TortoiseGMManager.BeginLookupCommand(command)
    end
    SendChatMessage(command, "SAY")

    if TortoiseGMManager.SetStatus then
        TortoiseGMManager.SetStatus("Sent: " .. command, "ok")
    end

    if TortoiseGMManager.RefreshList then
        TortoiseGMManager.RefreshList()
    end

    return true
end

function TortoiseGMManager.RequestHelp(command)
    command = TortoiseGMManager.NormalizeCommand(command)
    if command == "" or command == "." then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("Choose or enter a command first.", "error")
        end
        return
    end

    local body = string.sub(command, 2)
    SendChatMessage(".help " .. body, "SAY")
    if TortoiseGMManager.SetStatus then
        TortoiseGMManager.SetStatus("Requested server help for: " .. command, "info")
    end
end

function TortoiseGMManager.GetHistoryCommands()
    TortoiseGMManager.InitializeDB()
    local results = {}
    local i
    for i = 1, table.getn(TortoiseGMManagerDB.history) do
        table.insert(results, {
            category = "history",
            label = "Recent " .. tostring(i),
            command = TortoiseGMManagerDB.history[i],
            detail = "Previously executed command.",
            access = "History",
            direct = false,
            fromHistory = true,
        })
    end
    return results
end

function TortoiseGMManager.GetFilteredCommands(category, query)
    local source
    if category == "history" then
        source = TortoiseGMManager.GetHistoryCommands()
    else
        source = TortoiseGMManager.commands or {}
    end

    local normalizedQuery = lower(trim(query))
    local results = {}
    local i

    for i = 1, table.getn(source) do
        local entry = source[i]
        local inCategory = category == "history" or category == "all" or entry.category == category
        if inCategory then
            if normalizedQuery == "" then
                table.insert(results, entry)
            else
                local haystack = lower((entry.label or "") .. " " .. (entry.command or "") .. " " .. (entry.hint or "") .. " " .. (entry.detail or "") .. " " .. (entry.lookupCommand or "") .. " " .. (entry.lookupHint or ""))
                if string.find(haystack, normalizedQuery, 1, true) then
                    table.insert(results, entry)
                end
            end
        end
    end

    return results
end

function TortoiseGMManager.CommandMatchesEntry(entry, command)
    if not entry or not entry.command then
        return false
    end

    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    local base = lower(TortoiseGMManager.NormalizeCommand(entry.command))
    if normalized == base then
        return true
    end

    return string.sub(normalized, 1, string.len(base) + 1) == base .. " "
end

function TortoiseGMManager.GetComposerArgs(entry, command)
    if not entry then
        return trim(command)
    end

    command = trim(command)
    local base = trim(entry.command or "")
    if base == "" then
        return command
    end

    local baseLength = string.len(base)
    if string.sub(lower(command), 1, baseLength) == lower(base) then
        local boundary = string.sub(command, baseLength + 1, baseLength + 1)
        if boundary == "" or boundary == " " then
            return trim(string.sub(command, baseLength + 1))
        end
    end

    return command
end

function TortoiseGMManager.ExecuteLookup(entry, command)
    if not entry or not entry.lookupCommand then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("This command has no name lookup configured.", "error")
        end
        return false
    end

    if not TortoiseGMManager.CommandMatchesEntry(entry, command) then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("FIND is disabled because the command bar no longer matches the selected action.", "error")
        end
        return false
    end

    local query = TortoiseGMManager.GetComposerArgs(entry, command)
    if query == "" then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("Type " .. (entry.lookupHint or "a name") .. " after the command, then click FIND.", "info")
        end
        return false
    end

    local lookup = TortoiseGMManager.NormalizeCommand(entry.lookupCommand .. " " .. query)
    if string.len(lookup) > 255 then
        if TortoiseGMManager.SetStatus then
            TortoiseGMManager.SetStatus("Lookup is longer than the Vanilla chat limit (255 characters).", "error")
        end
        return false
    end

    TortoiseGMManager.AddHistory(lookup)
    if TortoiseGMManager.BeginLookup then
        TortoiseGMManager.BeginLookup(entry, query, lookup)
    end
    SendChatMessage(lookup, "SAY")

    if TortoiseGMManager.SetStatus then
        TortoiseGMManager.SetStatus("Lookup sent: " .. lookup .. ". Matching results will open in the lookup browser.", "ok")
    end
    if TortoiseGMManager.RefreshList then
        TortoiseGMManager.RefreshList()
    end
    return true
end

function TortoiseGMManager.Compose(entry, args)
    if not entry then
        return ""
    end

    local command = entry.command or ""
    args = trim(args)
    if args ~= "" then
        command = command .. " " .. args
    end
    return TortoiseGMManager.NormalizeCommand(command)
end
