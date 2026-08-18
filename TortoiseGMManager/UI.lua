TortoiseGMManager = TortoiseGMManager or {}
TortoiseGMManager.InitializeDB()

local ROWS_PER_PAGE = 4
local PANEL_WIDTH = 590
local PANEL_HEIGHT = 435
local CONTENT_LEFT = 14
local CONTENT_WIDTH = 562

local COLORS = {
    gold = { 0.95, 0.72, 0.28 },
    text = { 0.92, 0.90, 0.84 },
    muted = { 0.62, 0.60, 0.56 },
    green = { 0.30, 0.90, 0.45 },
    red = { 1.00, 0.34, 0.28 },
    orange = { 1.00, 0.64, 0.20 },
    blue = { 0.42, 0.76, 1.00 },
}

local CATEGORY_ICONS = {
    quick = "Interface\\Icons\\INV_Misc_Gear_01",
    all = "Interface\\Icons\\INV_Misc_Book_09",
    travel = "Interface\\Icons\\Spell_Arcane_TeleportStormWind",
    player = "Interface\\Icons\\Spell_Holy_SealOfMight",
    world = "Interface\\Icons\\Spell_Nature_Earthquake",
    lookup = "Interface\\Icons\\INV_Misc_Book_09",
    admin = "Interface\\Icons\\INV_Misc_Gear_01",
    danger = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    history = "Interface\\Icons\\INV_Misc_Note_01",
}

local function getCategoryIcon(category)
    return CATEGORY_ICONS[category or ""] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function startsWith(value, prefix)
    value = string.lower(value or "")
    prefix = string.lower(prefix or "")
    return string.sub(value, 1, string.len(prefix)) == prefix
end

local function getCommandIcon(entry)
    local command = entry and entry.command or ""

    if entry and entry.danger then
        return "Interface\\Icons\\Spell_Shadow_DeathCoil"
    elseif startsWith(command, ".tele") or startsWith(command, ".go ") or startsWith(command, ".goname") or startsWith(command, ".summon") then
        return "Interface\\Icons\\Spell_Arcane_TeleportStormWind"
    elseif startsWith(command, ".lookup") then
        return "Interface\\Icons\\INV_Misc_Book_09"
    elseif startsWith(command, ".npc") or startsWith(command, ".list creature") then
        return "Interface\\Icons\\Ability_Hunter_BeastCall"
    elseif startsWith(command, ".quest") then
        return "Interface\\Icons\\INV_Misc_Note_01"
    elseif startsWith(command, ".additem") or startsWith(command, ".deleteitem") then
        return "Interface\\Icons\\INV_Misc_Bag_10"
    elseif startsWith(command, ".god") or startsWith(command, ".revive") or startsWith(command, ".aura") then
        return "Interface\\Icons\\Spell_Holy_Resurrection"
    elseif startsWith(command, ".cast") or startsWith(command, ".cooldown") or startsWith(command, ".unaura") then
        return "Interface\\Icons\\Spell_Arcane_Arcane01"
    elseif startsWith(command, ".gps") then
        return "Interface\\Icons\\Ability_Tracking"
    elseif startsWith(command, ".event") then
        return "Interface\\Icons\\INV_Misc_PocketWatch_01"
    elseif startsWith(command, ".server") or startsWith(command, ".reload") or startsWith(command, ".gm") or startsWith(command, ".modify") then
        return "Interface\\Icons\\INV_Misc_Gear_01"
    end

    return getCategoryIcon(entry and entry.category)
end

local function applyBackdrop(frame, alpha, borderAlpha)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 11,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.025, 0.032, 0.045, alpha or 0.96)
    frame:SetBackdropBorderColor(0.48, 0.36, 0.15, borderAlpha or 0.90)
end

local function setFontColor(fontString, color)
    if fontString and color then
        fontString:SetTextColor(color[1], color[2], color[3])
    end
end

local function trim(value)
    value = value or ""
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function saveMainPosition(frame)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    TortoiseGMManagerDB.framePoint = point or "CENTER"
    TortoiseGMManagerDB.frameRelativePoint = relativePoint or point or "CENTER"
    TortoiseGMManagerDB.frameX = x or 0
    TortoiseGMManagerDB.frameY = y or 0
end

local main = CreateFrame("Frame", "TortoiseGMManagerFrame", UIParent)
main:SetWidth(PANEL_WIDTH)
main:SetHeight(PANEL_HEIGHT)
main:SetPoint(TortoiseGMManagerDB.framePoint or "CENTER", UIParent, TortoiseGMManagerDB.frameRelativePoint or "CENTER", TortoiseGMManagerDB.frameX or 0, TortoiseGMManagerDB.frameY or 15)
main:SetFrameStrata("DIALOG")
main:SetMovable(true)
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:SetScript("OnDragStart", function() this:StartMoving() end)
main:SetScript("OnDragStop", function() this:StopMovingOrSizing(); saveMainPosition(this) end)
applyBackdrop(main, 0.98, 1.0)
main:Hide()
TortoiseGMManager.frame = main
if UISpecialFrames then table.insert(UISpecialFrames, "TortoiseGMManagerFrame") end

local titleIcon = main:CreateTexture(nil, "ARTWORK")
titleIcon:SetWidth(24); titleIcon:SetHeight(24)
titleIcon:SetPoint("TOPLEFT", main, "TOPLEFT", 14, -8)
titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("LEFT", titleIcon, "RIGHT", 7, 0)
title:SetText("TortoiseGMManager")
setFontColor(title, COLORS.gold)

local headerGlow = main:CreateTexture(nil, "BACKGROUND")
headerGlow:SetTexture(0.55, 0.35, 0.08, 0.12)
headerGlow:SetPoint("TOPLEFT", main, "TOPLEFT", 8, -5)
headerGlow:SetPoint("TOPRIGHT", main, "TOPRIGHT", -8, -5)
headerGlow:SetHeight(32)

local targetText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
targetText:SetPoint("TOPRIGHT", main, "TOPRIGHT", -42, -18)
targetText:SetWidth(180); targetText:SetJustifyH("RIGHT")
targetText:SetText("Target: none")
setFontColor(targetText, COLORS.muted)
TortoiseGMManager.targetName = targetText

local closeButton = CreateFrame("Button", nil, main, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", main, "TOPRIGHT", -3, -3)

local divider = main:CreateTexture(nil, "ARTWORK")
divider:SetTexture(0.48, 0.36, 0.15, 0.70)
divider:SetPoint("TOPLEFT", main, "TOPLEFT", 12, -39)
divider:SetPoint("TOPRIGHT", main, "TOPRIGHT", -12, -39)
divider:SetHeight(1)

local searchLabel = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("TOPLEFT", main, "TOPLEFT", CONTENT_LEFT + 2, -50)
searchLabel:SetText("Search")
setFontColor(searchLabel, COLORS.muted)

local searchBox = CreateFrame("EditBox", "TortoiseGMManagerSearchBox", main, "InputBoxTemplate")
searchBox:SetWidth(325); searchBox:SetHeight(22)
searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
searchBox:SetScript("OnTextChanged", function()
    TortoiseGMManager.searchText = this:GetText() or ""
    TortoiseGMManager.page = 1
    TortoiseGMManager.RefreshList()
end)
TortoiseGMManager.searchBox = searchBox

local clearSearch = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
clearSearch:SetWidth(45); clearSearch:SetHeight(21)
clearSearch:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
clearSearch:SetText("Clear")
clearSearch:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)

TortoiseGMManager.categoryButtons = {}
local categoryWidth = 62
local categoryIndex
for categoryIndex = 1, table.getn(TortoiseGMManager.categories) do
    local category = TortoiseGMManager.categories[categoryIndex]
    local button = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    button:SetWidth(categoryWidth); button:SetHeight(22)
    button:SetPoint("TOPLEFT", main, "TOPLEFT", CONTENT_LEFT + ((categoryIndex - 1) * categoryWidth), -73)
    button:SetText("  " .. category.label)
    button.categoryId = category.id; button.categoryLabel = category.label
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetWidth(12); button.icon:SetHeight(12)
    button.icon:SetPoint("LEFT", button, "LEFT", 5, 0)
    button.icon:SetTexture(getCategoryIcon(category.id))
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetScript("OnClick", function()
        TortoiseGMManager.currentCategory = this.categoryId
        TortoiseGMManagerDB.lastCategory = this.categoryId
        TortoiseGMManager.page = 1
        TortoiseGMManager.ClearPendingConfirmation()
        TortoiseGMManager.RefreshCategoryButtons()
        TortoiseGMManager.RefreshList()
    end)
    table.insert(TortoiseGMManager.categoryButtons, button)
end

local resultLabel = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resultLabel:SetPoint("TOPLEFT", main, "TOPLEFT", CONTENT_LEFT + 2, -101)
resultLabel:SetWidth(CONTENT_WIDTH - 4); resultLabel:SetJustifyH("LEFT")
setFontColor(resultLabel, COLORS.muted)
TortoiseGMManager.resultLabel = resultLabel

TortoiseGMManager.rows = {}
local rowIndex
for rowIndex = 1, ROWS_PER_PAGE do
    local row = CreateFrame("Frame", nil, main)
    row:SetPoint("TOPLEFT", main, "TOPLEFT", CONTENT_LEFT, -114 - ((rowIndex - 1) * 49))
    row:SetWidth(CONTENT_WIDTH); row:SetHeight(44)
    applyBackdrop(row, 0.64, 0.55)

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -4)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 3, 4)
    row.accent:SetTexture(0.78, 0.53, 0.14, 0.95)

    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    row.hover:SetAllPoints(row)
    row.hover:SetTexture(0.95, 0.72, 0.28, 0.08)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(24); row.icon:SetHeight(24)
    row.icon:SetPoint("LEFT", row, "LEFT", 10, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 39, -6)
    row.title:SetWidth(350); row.title:SetJustifyH("LEFT")

    row.command = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.command:SetPoint("TOPLEFT", row, "TOPLEFT", 39, -24)
    row.command:SetWidth(404); row.command:SetJustifyH("LEFT")
    setFontColor(row.command, COLORS.gold)

    row:EnableMouse(true)
    row:SetScript("OnEnter", function()
        if this.entry then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(this.entry.label or this.entry.command or "Command")
            if this.entry.detail and this.entry.detail ~= "" then GameTooltip:AddLine(this.entry.detail, 1, 1, 1, true) end
            if this.entry.hint and this.entry.hint ~= "" then GameTooltip:AddLine("Args: " .. this.entry.hint, 0.95, 0.72, 0.28, true) end
            if this.entry.lookupCommand then GameTooltip:AddLine("FIND: " .. this.entry.lookupCommand, 0.42, 0.76, 1.00, true) end
            if this.entry.access and this.entry.access ~= "" then GameTooltip:AddLine("Access: " .. this.entry.access, 0.62, 0.60, 0.56, true) end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.useButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.useButton:SetWidth(55); row.useButton:SetHeight(22)
    row.useButton:SetPoint("RIGHT", row, "RIGHT", -35, -5)
    row.useButton:SetScript("OnClick", function()
        local entry = this.entry
        if not entry then return end
        TortoiseGMManager.SetComposer(entry)
        if entry.direct and not TortoiseGMManager.IsDangerous(entry.command) then
            TortoiseGMManager.Execute(entry.command)
        elseif TortoiseGMManager.IsDangerous(entry.command) then
            TortoiseGMManager.SetStatus("Dangerous preset loaded. Press RUN twice to confirm.", "warn")
        end
    end)
    row.useButton:SetScript("OnEnter", function()
        if this.entry then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            if TortoiseGMManager.IsDangerous(this.entry.command) then GameTooltip:SetText("Review dangerous command")
            elseif this.entry.direct then GameTooltip:SetText("Run now") else GameTooltip:SetText("Load into command bar") end
            GameTooltip:AddLine(this.entry.detail or "", 1, 1, 1, true)
            if this.entry.hint and this.entry.hint ~= "" then GameTooltip:AddLine("Args: " .. this.entry.hint, 0.95, 0.72, 0.28, true) end
            GameTooltip:Show()
        end
    end)
    row.useButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.helpButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.helpButton:SetWidth(26); row.helpButton:SetHeight(22)
    row.helpButton:SetPoint("RIGHT", row, "RIGHT", -6, -5)
    row.helpButton:SetText("?")
    row.helpButton:SetScript("OnClick", function() if this.entry then TortoiseGMManager.RequestHelp(this.entry.command) end end)
    row.helpButton:SetScript("OnEnter", function()
        if this.entry then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Server syntax help")
            GameTooltip:AddLine("Sends: .help " .. string.sub(this.entry.command, 2), 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    row.helpButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    table.insert(TortoiseGMManager.rows, row)
end

local prevButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
prevButton:SetWidth(58); prevButton:SetHeight(21)
prevButton:SetPoint("TOPLEFT", main, "TOPLEFT", CONTENT_LEFT, -311)
prevButton:SetText("< Prev")
prevButton:SetScript("OnClick", function()
    if TortoiseGMManager.page > 1 then TortoiseGMManager.page = TortoiseGMManager.page - 1; TortoiseGMManager.RefreshList() end
end)
TortoiseGMManager.prevButton = prevButton

local pageText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pageText:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
pageText:SetWidth(85); pageText:SetJustifyH("CENTER")
pageText:SetText("1 / 1")
setFontColor(pageText, COLORS.muted)
TortoiseGMManager.pageText = pageText

local nextButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
nextButton:SetWidth(58); nextButton:SetHeight(21)
nextButton:SetPoint("LEFT", pageText, "RIGHT", 8, 0)
nextButton:SetText("Next >")
nextButton:SetScript("OnClick", function()
    if TortoiseGMManager.page < TortoiseGMManager.pageCount then TortoiseGMManager.page = TortoiseGMManager.page + 1; TortoiseGMManager.RefreshList() end
end)
TortoiseGMManager.nextButton = nextButton

local composer = CreateFrame("Frame", nil, main)
composer:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", CONTENT_LEFT, 12)
composer:SetWidth(CONTENT_WIDTH); composer:SetHeight(86)
applyBackdrop(composer, 0.82, 0.75)

local composerLabel = composer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
composerLabel:SetPoint("TOPLEFT", composer, "TOPLEFT", 9, -7)
composerLabel:SetText("COMMAND")
setFontColor(composerLabel, COLORS.muted)

local commandBox = CreateFrame("EditBox", "TortoiseGMManagerCommandBox", composer, "InputBoxTemplate")
commandBox:SetWidth(318); commandBox:SetHeight(23)
commandBox:SetPoint("TOPLEFT", composer, "TOPLEFT", 12, -22)
commandBox:SetAutoFocus(false)
commandBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
commandBox:SetScript("OnEnterPressed", function() TortoiseGMManager.Execute(this:GetText()); this:ClearFocus() end)
commandBox:SetScript("OnTextChanged", function()
    TortoiseGMManager.ClearPendingConfirmation()
    if TortoiseGMManager.RefreshLookupState then TortoiseGMManager.RefreshLookupState() end
end)
TortoiseGMManager.commandBox = commandBox

local lookupButton = CreateFrame("Button", nil, composer, "UIPanelButtonTemplate")
lookupButton:SetWidth(54); lookupButton:SetHeight(24)
lookupButton:SetPoint("LEFT", commandBox, "RIGHT", 6, 0)
lookupButton:SetText("FIND"); lookupButton:Disable()
lookupButton:SetScript("OnClick", function() TortoiseGMManager.ExecuteLookup(TortoiseGMManager.selectedEntry, commandBox:GetText()) end)
lookupButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    if TortoiseGMManager.selectedEntry and TortoiseGMManager.selectedEntry.lookupCommand then
        GameTooltip:SetText("Find by name")
        GameTooltip:AddLine("Uses " .. TortoiseGMManager.selectedEntry.lookupCommand .. " and keeps the action loaded.", 1, 1, 1, true)
    else GameTooltip:SetText("No lookup for this command") end
    GameTooltip:Show()
end)
lookupButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
TortoiseGMManager.lookupButton = lookupButton

function TortoiseGMManager.RefreshLookupState()
    local entry = TortoiseGMManager.selectedEntry
    if entry and entry.lookupCommand and TortoiseGMManager.CommandMatchesEntry(entry, commandBox:GetText()) then lookupButton:Enable() else lookupButton:Disable() end
end

local runButton = CreateFrame("Button", nil, composer, "UIPanelButtonTemplate")
runButton:SetWidth(55); runButton:SetHeight(24)
runButton:SetPoint("LEFT", lookupButton, "RIGHT", 5, 0)
runButton:SetText("RUN")
runButton:SetScript("OnClick", function() TortoiseGMManager.Execute(commandBox:GetText()) end)

local helpButton = CreateFrame("Button", nil, composer, "UIPanelButtonTemplate")
helpButton:SetWidth(50); helpButton:SetHeight(24)
helpButton:SetPoint("LEFT", runButton, "RIGHT", 5, 0)
helpButton:SetText("Help")
helpButton:SetScript("OnClick", function() TortoiseGMManager.RequestHelp(commandBox:GetText()) end)

local hintText = composer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintText:SetPoint("TOPLEFT", commandBox, "BOTTOMLEFT", 0, -3)
hintText:SetWidth(532); hintText:SetHeight(14); hintText:SetJustifyH("LEFT")
hintText:SetText("Choose an action above, or type any .command manually.")
setFontColor(hintText, COLORS.muted)
TortoiseGMManager.hintText = hintText

local statusText = composer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusText:SetPoint("BOTTOMLEFT", composer, "BOTTOMLEFT", 10, 7)
statusText:SetWidth(532); statusText:SetHeight(14); statusText:SetJustifyH("LEFT")
statusText:SetText("Ready.")
setFontColor(statusText, COLORS.blue)
TortoiseGMManager.statusText = statusText

function TortoiseGMManager.SetStatus(message, kind)
    if not statusText then return end
    statusText:SetText(message or "")
    if kind == "error" then setFontColor(statusText, COLORS.red)
    elseif kind == "warn" then setFontColor(statusText, COLORS.orange)
    elseif kind == "ok" then setFontColor(statusText, COLORS.green)
    elseif kind == "info" then setFontColor(statusText, COLORS.blue)
    else setFontColor(statusText, COLORS.text) end
end

function TortoiseGMManager.SetComposer(entry)
    if not entry then return end
    TortoiseGMManager.selectedEntry = entry
    TortoiseGMManager.ClearPendingConfirmation()
    local command = entry.command or ""
    if not entry.direct and entry.hint and entry.hint ~= "" then command = command .. " " end
    commandBox:SetText(command)
    local hint = ""
    if entry.hint and entry.hint ~= "" then hint = "Args: " .. entry.hint end
    if entry.lookupCommand then
        if hint ~= "" then hint = hint .. "  |  " end
        hint = hint .. "FIND by name"
    end
    hintText:SetText(hint)
    TortoiseGMManager.RefreshLookupState()
    if not entry.direct and entry.hint and entry.hint ~= "" then commandBox:SetFocus() end
end

function TortoiseGMManager.LoadCommand(command, entry, hint)
    TortoiseGMManager.selectedEntry = entry
    TortoiseGMManager.ClearPendingConfirmation()
    commandBox:SetText(TortoiseGMManager.NormalizeCommand(command))
    hintText:SetText(hint or "Loaded from lookup results. Review, adjust arguments if needed, then RUN.")
    TortoiseGMManager.RefreshLookupState()
    TortoiseGMManager.ShowUI()
    commandBox:SetFocus()
end

function TortoiseGMManager.RefreshCategoryButtons()
    local i
    for i = 1, table.getn(TortoiseGMManager.categoryButtons) do
        local button = TortoiseGMManager.categoryButtons[i]
        button:SetText("  " .. button.categoryLabel)
        if button.categoryId == TortoiseGMManager.currentCategory then
            if button.icon then button.icon:SetAlpha(1.0) end
            button:LockHighlight()
        else
            if button.icon then button.icon:SetAlpha(0.62) end
            button:UnlockHighlight()
        end
    end
end

function TortoiseGMManager.RefreshTarget()
    local name = UnitName("target")
    if name and name ~= "" then targetText:SetText("Target: " .. name); setFontColor(targetText, COLORS.gold)
    else targetText:SetText("Target: none"); setFontColor(targetText, COLORS.muted) end
end

function TortoiseGMManager.RefreshList()
    if not TortoiseGMManager.currentCategory then TortoiseGMManager.currentCategory = TortoiseGMManagerDB.lastCategory or "quick" end
    if not TortoiseGMManager.page then TortoiseGMManager.page = 1 end
    local query = TortoiseGMManager.searchText or ""
    local results = TortoiseGMManager.GetFilteredCommands(TortoiseGMManager.currentCategory, query)
    TortoiseGMManager.currentResults = results
    local count = table.getn(results)
    local pageCount = math.ceil(count / ROWS_PER_PAGE); if pageCount < 1 then pageCount = 1 end
    TortoiseGMManager.pageCount = pageCount
    if TortoiseGMManager.page > pageCount then TortoiseGMManager.page = pageCount end
    if TortoiseGMManager.page < 1 then TortoiseGMManager.page = 1 end
    local categoryLabel = TortoiseGMManager.currentCategory
    local i
    for i = 1, table.getn(TortoiseGMManager.categories) do if TortoiseGMManager.categories[i].id == TortoiseGMManager.currentCategory then categoryLabel = TortoiseGMManager.categories[i].label; break end end
    local resultSummary = categoryLabel .. " - " .. tostring(count) .. (count == 1 and " command" or " commands")
    if query ~= "" then resultSummary = resultSummary .. " matching \"" .. query .. "\"" end
    resultLabel:SetText(resultSummary)

    local startIndex = ((TortoiseGMManager.page - 1) * ROWS_PER_PAGE) + 1
    for rowIndex = 1, ROWS_PER_PAGE do
        local row = TortoiseGMManager.rows[rowIndex]
        local entry = results[startIndex + rowIndex - 1]
        if entry then
            row.entry = entry; row.useButton.entry = entry; row.helpButton.entry = entry
            if entry.danger then row.title:SetText("! " .. (entry.label or entry.command)); setFontColor(row.title, COLORS.orange)
            else row.title:SetText(entry.label or entry.command); setFontColor(row.title, COLORS.text) end
            row.icon:SetTexture(getCommandIcon(entry))
            if entry.danger then row.accent:SetTexture(0.95, 0.34, 0.18, 0.95)
            elseif entry.lookupCommand then row.accent:SetTexture(0.38, 0.68, 0.95, 0.95)
            else row.accent:SetTexture(0.78, 0.53, 0.14, 0.95) end
            local raw = entry.command or ""; if entry.hint and entry.hint ~= "" then raw = raw .. "  <" .. entry.hint .. ">" end
            row.command:SetText(raw)
            if TortoiseGMManager.IsDangerous(entry.command) then row.useButton:SetText("Review") elseif entry.direct then row.useButton:SetText("Run") else row.useButton:SetText("Use") end
            row:Show()
        else
            row.entry = nil; row.useButton.entry = nil; row.helpButton.entry = nil; row:Hide()
        end
    end

    pageText:SetText(tostring(TortoiseGMManager.page) .. " / " .. tostring(pageCount))
    if TortoiseGMManager.page <= 1 then prevButton:Disable() else prevButton:Enable() end
    if TortoiseGMManager.page >= pageCount then nextButton:Disable() else nextButton:Enable() end
    TortoiseGMManager.RefreshTarget()
end

function TortoiseGMManager.ShowUI()
    TortoiseGMManager.InitializeDB()
    TortoiseGMManager.currentCategory = TortoiseGMManager.currentCategory or TortoiseGMManagerDB.lastCategory or "quick"
    TortoiseGMManager.RefreshCategoryButtons(); TortoiseGMManager.RefreshList(); main:Show()
end

function TortoiseGMManager.HideUI()
    main:Hide()
    if TortoiseGMManager.HideLookupResults then TortoiseGMManager.HideLookupResults() end
    TortoiseGMManager.ClearPendingConfirmation()
end

function TortoiseGMManager.ToggleUI()
    if main:IsVisible() then TortoiseGMManager.HideUI() else TortoiseGMManager.ShowUI() end
end

local minimapButton = CreateFrame("Button", "TortoiseGMManagerMinimapButton", Minimap)
minimapButton:SetWidth(30); minimapButton:SetHeight(30); minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetPoint("CENTER", Minimap, "CENTER", TortoiseGMManagerDB.minimapX or 52, TortoiseGMManagerDB.minimapY or 52)
minimapButton:RegisterForClicks("LeftButtonUp"); minimapButton:RegisterForDrag("LeftButton")
local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetWidth(20); minimapIcon:SetHeight(20); minimapIcon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01"); minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetWidth(52); minimapBorder:SetHeight(52); minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
TortoiseGMManager.minimapButton = minimapButton

local function updateMinimapButtonPosition()
    local cursorX, cursorY = GetCursorPosition(); local scale = UIParent:GetScale()
    if scale and scale > 0 then cursorX = cursorX / scale; cursorY = cursorY / scale end
    local centerX, centerY = Minimap:GetCenter(); if not centerX or not centerY then return end
    local dx = cursorX - centerX; local dy = cursorY - centerY; local distance = math.sqrt((dx * dx) + (dy * dy)); if distance < 1 then return end
    local radius = 78; local x = (dx / distance) * radius; local y = (dy / distance) * radius
    minimapButton:ClearAllPoints(); minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    TortoiseGMManagerDB.minimapX = x; TortoiseGMManagerDB.minimapY = y
end

minimapButton:SetScript("OnDragStart", function()
    if not IsShiftKeyDown() then return end
    TortoiseGMManager.minimapDragging = true; TortoiseGMManager.minimapWasDragged = true
    this:SetScript("OnUpdate", updateMinimapButtonPosition)
end)
minimapButton:SetScript("OnDragStop", function() TortoiseGMManager.minimapDragging = false; this:SetScript("OnUpdate", nil); updateMinimapButtonPosition() end)
minimapButton:SetScript("OnClick", function()
    if TortoiseGMManager.minimapWasDragged then TortoiseGMManager.minimapWasDragged = false; return end
    TortoiseGMManager.ToggleUI()
end)
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT"); GameTooltip:SetText("TortoiseGMManager")
    GameTooltip:AddLine("Click: open / close", 1, 1, 1); GameTooltip:AddLine("Shift-drag: move around minimap", 0.75, 0.75, 0.75); GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_TORTOISEGMMANAGER1 = "/tgm"
SLASH_TORTOISEGMMANAGER2 = "/tortoisegm"
SLASH_TORTOISEGMMANAGER3 = "/gmui"
SlashCmdList["TORTOISEGMMANAGER"] = function(msg)
    msg = trim(msg); TortoiseGMManager.ShowUI()
    if msg ~= "" then
        TortoiseGMManager.selectedEntry = nil; lookupButton:Disable(); commandBox:SetText(TortoiseGMManager.NormalizeCommand(msg))
        hintText:SetText("Manual command. Press RUN or Enter to send."); commandBox:SetFocus()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED"); eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD"); eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        TortoiseGMManager.InitializeDB(); TortoiseGMManager.currentCategory = TortoiseGMManagerDB.lastCategory or "quick"
        TortoiseGMManager.RefreshCategoryButtons(); TortoiseGMManager.RefreshList(); TortoiseGMManager.Print("Loaded. Click the minimap gear or use /tgm.")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then TortoiseGMManager.RefreshTarget() end
end)
