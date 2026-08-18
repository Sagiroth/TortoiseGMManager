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
    if not TortoiseGMManagerDB.favourites then
        TortoiseGMManagerDB.favourites = {}
    end
    if TortoiseGMManagerDB.lastCategory == "history" then
        TortoiseGMManagerDB.lastCategory = "favourites"
    elseif TortoiseGMManagerDB.lastCategory == nil then
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

function TortoiseGMManager.RequestHelp(value)
    local command
    if type(value) == "table" then
        command = value.command
    else
        command = value
        local normalized = TortoiseGMManager.NormalizeCommand(command)
        local best = nil
        local i
        for i = 1, table.getn(TortoiseGMManager.commands or {}) do
            local entry = TortoiseGMManager.commands[i]
            if TortoiseGMManager.CommandMatchesEntry(entry, normalized) and (not best or string.len(entry.command) > string.len(best.command)) then
                best = entry
            end
        end
        if best then command = best.command end
    end
    command = TortoiseGMManager.NormalizeCommand(command)
    if command == "" or command == "." then
        if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Choose an action first.", "error") end
        return false
    end
    SendChatMessage(".help " .. string.sub(command, 2), "SAY")
    if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Requested server help for: " .. command, "info") end
    return true
end

function TortoiseGMManager.IsFavourite(command)
    TortoiseGMManager.InitializeDB()
    local normalized = TortoiseGMManager.NormalizeCommand(command)
    local i
    for i = 1, table.getn(TortoiseGMManagerDB.favourites) do
        if TortoiseGMManagerDB.favourites[i] == normalized then return true end
    end
    return false
end

function TortoiseGMManager.ToggleFavourite(entry)
    if not entry or not entry.command then return false end
    TortoiseGMManager.InitializeDB()
    local command = TortoiseGMManager.NormalizeCommand(entry.command)
    local i
    for i = table.getn(TortoiseGMManagerDB.favourites), 1, -1 do
        if TortoiseGMManagerDB.favourites[i] == command then
            table.remove(TortoiseGMManagerDB.favourites, i)
            return false
        end
    end
    table.insert(TortoiseGMManagerDB.favourites, command)
    return true
end

function TortoiseGMManager.GetFavouriteCommands()
    TortoiseGMManager.InitializeDB()
    local results = {}
    local i
    for i = 1, table.getn(TortoiseGMManagerDB.favourites) do
        local command = TortoiseGMManagerDB.favourites[i]
        local j
        for j = 1, table.getn(TortoiseGMManager.commands or {}) do
            local entry = TortoiseGMManager.commands[j]
            if TortoiseGMManager.NormalizeCommand(entry.command) == command then
                table.insert(results, entry)
                break
            end
        end
    end
    return results
end

function TortoiseGMManager.GetFilteredCommands(category, query)
    local source = category == "favourites" and TortoiseGMManager.GetFavouriteCommands() or (TortoiseGMManager.commands or {})
    local normalizedQuery = lower(trim(query))
    local ranked = { {}, {}, {}, {}, {} }
    local results = {}
    local i
    for i = 1, table.getn(source) do
        local entry = source[i]
        local inCategory = category == "favourites" or category == "all" or entry.category == category
        if inCategory then
            if normalizedQuery == "" then table.insert(results, entry)
            else
                local label = lower(entry.label or "")
                local command = lower(entry.command or "")
                local details = lower((entry.hint or "") .. " " .. (entry.detail or "") .. " " .. (entry.lookupCommand or "") .. " " .. (entry.lookupHint or ""))
                local rank = nil
                if label == normalizedQuery then rank = 1
                elseif string.sub(label, 1, string.len(normalizedQuery)) == normalizedQuery then rank = 2
                elseif string.find(label, normalizedQuery, 1, true) then rank = 3
                elseif string.find(command, normalizedQuery, 1, true) then rank = 4
                elseif string.find(details, normalizedQuery, 1, true) then rank = 5 end
                if rank then table.insert(ranked[rank], entry) end
            end
        end
    end
    if normalizedQuery ~= "" then
        local rank, j
        for rank = 1, 5 do for j = 1, table.getn(ranked[rank]) do table.insert(results, ranked[rank][j]) end end
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

function TortoiseGMManager.BuildLookupCommand(entry, query)
    if not entry or not entry.lookupCommand then return nil end
    query = trim(query)
    if query == "" then return nil end
    return TortoiseGMManager.NormalizeCommand(entry.lookupCommand .. " " .. query)
end

function TortoiseGMManager.ExecuteLookup(entry, query)
    if not entry or not entry.lookupCommand then
        if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("This action has no lookup configured.", "error") end
        return false
    end
    query = trim(query)
    if query == "" then
        if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Type " .. (entry.lookupHint or "a name or ID") .. ", then click SEARCH.", "info") end
        return false
    end
    if string.find(query, "^%d+$") then
        local command = TortoiseGMManager.Compose(entry, query)
        if TortoiseGMManager.LoadCommand then TortoiseGMManager.LoadCommand(command, entry, "Numeric ID loaded directly. Review, then RUN.") end
        return true
    end
    local lookup = TortoiseGMManager.BuildLookupCommand(entry, query)
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
