TortoiseGMManager = TortoiseGMManager or {}

local LOOKUP_WINDOW_SECONDS = 12
local MAX_RESULTS = 30
local gfind = string.gfind or string.gmatch

local LOOKUP_KINDS = {
    [".lookup item"] = "item",
    [".lookup spell"] = "spell",
    [".lookup quest"] = "quest",
    [".lookup creature"] = "creature",
    [".lookup object"] = "gameobject",
    [".lookup skill"] = "skill",
    [".lookup faction"] = "faction",
    [".lookup itemset"] = "itemset",
    [".lookup event"] = "event",
    [".lookup guild"] = "guild",
    [".lookup player name"] = "player",
    [".lookup player account"] = "player",
    [".lookup player email"] = "player",
    [".lookup player ip"] = "player",
    [".lookup player character"] = "player",
    [".lookup hwprint"] = "account",
}

local LINK_KINDS = {
    item = "item",
    spell = "spell",
    quest = "quest",
    creature_entry = "creature",
    gameobject_entry = "gameobject",
    skill = "skill",
    faction = "faction",
    itemset = "itemset",
    gameevent = "event",
    player = "player",
}

local function trim(value)
    value = value or ""
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function lower(value)
    return string.lower(value or "")
end

local function stripFormatting(value)
    value = value or ""
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "|H[^|]+|h%[([^%]]+)%]|h", "%1")
    value = string.gsub(value, "|h", "")
    return trim(value)
end

local function getLookupKind(command)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    local bestCommand = nil
    local bestKind = nil
    local lookupCommand, kind

    for lookupCommand, kind in pairs(LOOKUP_KINDS) do
        if normalized == lookupCommand or string.sub(normalized, 1, string.len(lookupCommand) + 1) == lookupCommand .. " " then
            if not bestCommand or string.len(lookupCommand) > string.len(bestCommand) then
                bestCommand = lookupCommand
                bestKind = kind
            end
        end
    end

    return bestKind, bestCommand
end

function TortoiseGMManager.GetLookupKind(command)
    return getLookupKind(command)
end

function TortoiseGMManager.GetLookupResults()
    return TortoiseGMManager.lookupResults or {}
end

function TortoiseGMManager.ClearLookupResults()
    TortoiseGMManager.lookupResults = {}
    TortoiseGMManager.lookupResultKeys = {}
    if TortoiseGMManager.OnLookupResultsChanged then
        TortoiseGMManager.OnLookupResultsChanged()
    end
end

function TortoiseGMManager.AddLookupResult(kind, id, name, link, raw)
    if not kind or not id or tostring(id) == "" then
        return false
    end

    id = tostring(id)
    name = stripFormatting(name)
    if name == "" then
        name = id
    end

    TortoiseGMManager.lookupResults = TortoiseGMManager.lookupResults or {}
    TortoiseGMManager.lookupResultKeys = TortoiseGMManager.lookupResultKeys or {}

    local key = tostring(kind) .. ":" .. id
    if TortoiseGMManager.lookupResultKeys[key] then
        return false
    end

    TortoiseGMManager.lookupResultKeys[key] = true
    table.insert(TortoiseGMManager.lookupResults, {
        kind = kind,
        id = id,
        name = name,
        link = link,
        raw = raw,
    })

    while table.getn(TortoiseGMManager.lookupResults) > MAX_RESULTS do
        local removed = table.remove(TortoiseGMManager.lookupResults, 1)
        if removed then
            TortoiseGMManager.lookupResultKeys[tostring(removed.kind) .. ":" .. tostring(removed.id)] = nil
        end
    end

    if TortoiseGMManager.OnLookupResultsChanged then
        TortoiseGMManager.OnLookupResultsChanged()
    end
    return true
end

function TortoiseGMManager.BeginLookup(entry, query, lookupCommand)
    local kind, base = getLookupKind(lookupCommand or (entry and entry.lookupCommand) or "")
    if not kind then
        return false
    end

    TortoiseGMManager.ClearLookupResults()
    TortoiseGMManager.pendingLookup = {
        kind = kind,
        lookupCommand = base,
        query = trim(query),
        sourceEntry = entry,
        startedAt = GetTime(),
    }

    if TortoiseGMManager.OnLookupStarted then
        TortoiseGMManager.OnLookupStarted(TortoiseGMManager.pendingLookup)
    end
    return true
end

function TortoiseGMManager.BeginLookupCommand(command)
    local kind, base = getLookupKind(command)
    if not kind or not base then
        return false
    end

    local query = trim(string.sub(TortoiseGMManager.NormalizeCommand(command), string.len(base) + 1))
    return TortoiseGMManager.BeginLookup(nil, query, base)
end

function TortoiseGMManager.IsLookupPending()
    local pending = TortoiseGMManager.pendingLookup
    if not pending then
        return false
    end

    if GetTime() - (pending.startedAt or 0) > LOOKUP_WINDOW_SECONDS then
        TortoiseGMManager.pendingLookup = nil
        return false
    end
    return true
end

local function captureLinkedResults(text, expectedKind)
    local captured = 0
    local sawKnownLink = false
    local hyperlink, id, name

    for hyperlink, id, name in gfind(text, "|H([%w_]+):(%d+)[^|]*|h%[(.-)%]|h") do
        local kind = LINK_KINDS[hyperlink]
        if kind then
            sawKnownLink = true
            if not expectedKind or expectedKind == kind then
                local _, _, link = string.find(text, "(|c%x%x%x%x%x%x%x%x|H" .. hyperlink .. ":" .. id .. "[^|]*|h%[.-%]|h|r)")
                if TortoiseGMManager.AddLookupResult(kind, id, name, link, text) then
                    captured = captured + 1
                end
            end
        end
    end

    return captured, sawKnownLink
end

local function captureGenericResult(text, pending)
    if not pending then
        return 0
    end

    local _, _, id, tail = string.find(text, "^%s*(%d+)%s*[%-%:]%s*(.+)$")
    if not id then
        _, _, id, tail = string.find(text, "^%s*%[(%d+)%]%s*(.+)$")
    end
    if not id then
        return 0
    end

    local name = stripFormatting(tail)
    if name == "" then
        return 0
    end

    if TortoiseGMManager.AddLookupResult(pending.kind, id, name, nil, text) then
        return 1
    end
    return 0
end

function TortoiseGMManager.CaptureLookupMessage(text)
    if not text or text == "" or not TortoiseGMManager.IsLookupPending() then
        return 0
    end

    local pending = TortoiseGMManager.pendingLookup
    local captured, sawKnownLink = captureLinkedResults(text, pending.kind)
    if captured == 0 and not sawKnownLink then
        captured = captureGenericResult(text, pending)
    end

    if captured > 0 and TortoiseGMManager.ShowLookupResults then
        TortoiseGMManager.ShowLookupResults()
    end
    return captured
end

function TortoiseGMManager.GetLookupResultCommand(result)
    if not result then
        return nil
    end

    local pending = TortoiseGMManager.pendingLookup
    if pending and pending.sourceEntry and pending.sourceEntry.command then
        return TortoiseGMManager.Compose(pending.sourceEntry, result.id)
    end

    local id = tostring(result.id or "")
    if result.kind == "item" then
        return ".additem " .. id
    elseif result.kind == "spell" then
        return ".cast " .. id
    elseif result.kind == "quest" then
        return ".quest status " .. id
    elseif result.kind == "creature" then
        return ".go creature id " .. id
    elseif result.kind == "gameobject" then
        return ".go object id " .. id
    elseif result.kind == "event" then
        return ".event info " .. id
    elseif result.kind == "itemset" then
        return ".additemset " .. id
    elseif result.kind == "skill" then
        return ".setskill " .. id
    elseif result.kind == "faction" then
        return ".modify rep " .. id
    end

    return nil
end

local lookupEventFrame = CreateFrame("Frame")
lookupEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
lookupEventFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" and arg1 then
        TortoiseGMManager.CaptureLookupMessage(arg1)
    end
end)
