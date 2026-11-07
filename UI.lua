TortoiseGMManager = TortoiseGMManager or {}
TortoiseGMManager.InitializeDB()

local Theme = TortoiseGMManager.Theme
local COLORS = Theme.colors

-- Layout grid. Everything is positioned from these numbers so the window
-- keeps one consistent rhythm: 14px outer padding, 8px vertical gaps.
local PANEL_WIDTH = 600
local PAD = 14
local CONTENT_WIDTH = PANEL_WIDTH - (PAD * 2)
local HEADER_HEIGHT = 44
local SEARCH_TOP = -54
local TABS_TOP = -88
local LIST_HEADER_TOP = -122
local ROWS_TOP = -148
local ROWS_PER_PAGE = 5
local ROW_HEIGHT = 36
local ROW_GAP = 4
local ROWS_BLOCK = (ROWS_PER_PAGE * ROW_HEIGHT) + ((ROWS_PER_PAGE - 1) * ROW_GAP)
local COMPOSER_TOP = ROWS_TOP - ROWS_BLOCK - 10
local COMPOSER_HEIGHT = 190
local FOOTER_HEIGHT = 24
local PANEL_HEIGHT = -COMPOSER_TOP + COMPOSER_HEIGHT + 10 + FOOTER_HEIGHT
local ARGUMENT_WIDTH = 134
local ARGUMENT_GAP = 8

local CATEGORY_ACCENTS = {
    lookup = COLORS.blue,
    danger = COLORS.red,
}

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
        return "Interface\\Icons\\INV_Misc_Spyglass_03"
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

    return "Interface\\Icons\\INV_Misc_Book_09"
end

local function trim(value)
    value = value or ""
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function getSingleToggle(entry)
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    if arguments and table.getn(arguments) == 1 and arguments[1].type == "toggle" then return arguments[1] end
    return nil
end

local function executeToggle(entry, optionIndex)
    local definition = getSingleToggle(entry)
    local option = definition and definition.options and definition.options[optionIndex]
    if not option then return end
    local values = TortoiseGMManager.InitializeValues(entry)
    values[definition.key] = option.value
    TortoiseGMManager.Execute(TortoiseGMManager.ComposeValues(entry, values))
end

-- Colour toggle values so state reads at a glance (ON green, OFF muted).
local function getOptionColor(value)
    value = string.lower(tostring(value or ""))
    if value == "on" or value == "1" or value == "true" or value == "yes" then return COLORS.green end
    if value == "off" or value == "0" or value == "false" or value == "no" then return COLORS.muted end
    return COLORS.text
end

local function saveMainPosition(frame)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    TortoiseGMManagerDB.framePoint = point or "CENTER"
    TortoiseGMManagerDB.frameRelativePoint = relativePoint or point or "CENTER"
    TortoiseGMManagerDB.frameX = x or 0
    TortoiseGMManagerDB.frameY = y or 0
end

local function showTooltip(owner, anchor, title, lines)
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    GameTooltip:SetText(title or "", COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
    local i
    for i = 1, table.getn(lines or {}) do
        local line = lines[i]
        if line and line[1] and line[1] ~= "" then GameTooltip:AddLine(line[1], line[2] or 1, line[3] or 1, line[4] or 1, true) end
    end
    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

local main = CreateFrame("Frame", "TortoiseGMManagerFrame", UIParent)
main:SetWidth(PANEL_WIDTH)
main:SetHeight(PANEL_HEIGHT)
main:SetPoint(TortoiseGMManagerDB.framePoint or "CENTER", UIParent, TortoiseGMManagerDB.frameRelativePoint or "CENTER", TortoiseGMManagerDB.frameX or 0, TortoiseGMManagerDB.frameY or 15)
main:SetFrameStrata("DIALOG")
main:SetMovable(true)
main:EnableMouse(true)
main:EnableMouseWheel(true)
main:RegisterForDrag("LeftButton")
main:SetScript("OnDragStart", function() this:StartMoving() end)
main:SetScript("OnDragStop", function() this:StopMovingOrSizing(); saveMainPosition(this) end)
-- Same brand pattern as TortoiseBotsManager: two-tone name + version, and a
-- meta line underneath. The "ban hammer" (Sulfuras) marks the GM tool.
local BRAND_ICON = "Interface\\Icons\\INV_Hammer_Unique_Sulfuras"
local version = tostring(TortoiseGMManager.version or "?")
Theme.Window(main, {
    title = "|cffd8a657Tortoise|r|cff6cb8ffGM|r |cfffff2ccManager|r  |cffffd200v" .. version .. "|r",
    subtitle = "TGMM " .. version .. " · GM command palette · by Sagiroth",
    icon = BRAND_ICON,
    headerHeight = HEADER_HEIGHT,
})
main:Hide()
TortoiseGMManager.frame = main
if UISpecialFrames then table.insert(UISpecialFrames, "TortoiseGMManagerFrame") end

-- Target indicator: a pill with a live dot, right-aligned next to close.
local targetPill = CreateFrame("Frame", nil, main)
targetPill:SetHeight(22)
targetPill:SetPoint("RIGHT", main.closeButton, "LEFT", -8, 0)
Theme.Backdrop(targetPill, COLORS.inset, COLORS.border)
local targetDot = Theme.Dot(targetPill, 6)
targetDot:SetPoint("LEFT", targetPill, "LEFT", 9, 0)
local targetText = Theme.Text(targetPill, 10, COLORS.muted)
targetText:SetPoint("LEFT", targetDot, "RIGHT", 7, 0)
targetText:SetText("Target: none")
TortoiseGMManager.targetName = targetText

---------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------

local searchBox = Theme.Input(main, "TortoiseGMManagerSearchBox", CONTENT_WIDTH, 26, {
    search = true,
    placeholder = "Filter actions by name, command or keyword",
    rightInset = 30,
})
searchBox:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, SEARCH_TOP)
searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
TortoiseGMManager.searchBox = searchBox

local clearSearch = Theme.IconButton(searchBox, 20, "X")
clearSearch:SetPoint("RIGHT", searchBox, "RIGHT", -3, 0)
clearSearch:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)
clearSearch:SetScript("OnEnter", function() showTooltip(this, "ANCHOR_TOP", "Clear filter") end)
clearSearch:SetScript("OnLeave", function() GameTooltip:Hide() end)
clearSearch:Hide()

searchBox:SetScript("OnTextChanged", function()
    TortoiseGMManager.searchText = this:GetText() or ""
    TortoiseGMManager.page = 1
    TortoiseGMManager.RefreshList()
    if TortoiseGMManager.searchText ~= "" then clearSearch:Show() else clearSearch:Hide() end
end)
Theme.WatchInput(searchBox)

---------------------------------------------------------------------------
-- Category tabs
---------------------------------------------------------------------------

local tabStrip = CreateFrame("Frame", nil, main)
tabStrip:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, TABS_TOP)
tabStrip:SetWidth(CONTENT_WIDTH); tabStrip:SetHeight(26)
local tabBaseline = Theme.Divider(tabStrip, "BACKGROUND")
tabBaseline:SetPoint("BOTTOMLEFT", tabStrip, "BOTTOMLEFT", 0, 0)
tabBaseline:SetPoint("BOTTOMRIGHT", tabStrip, "BOTTOMRIGHT", 0, 0)

TortoiseGMManager.categoryButtons = {}
local categoryIndex
for categoryIndex = 1, table.getn(TortoiseGMManager.categories) do
    local category = TortoiseGMManager.categories[categoryIndex]
    local button = Theme.Tab(tabStrip, category.label, CATEGORY_ACCENTS[category.id] or COLORS.gold)
    button.categoryId = category.id; button.categoryLabel = category.label
    if category.id == "favourites" then
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetWidth(12); button.icon:SetHeight(12)
        button.icon:SetTexture(Theme.STAR_TEXTURE)
        button.icon:SetTexCoord(0, 0.25, 0, 0.25)
        button.text:ClearAllPoints()
        button.text:SetPoint("CENTER", button, "CENTER", 8, 1)
        button.icon:SetPoint("RIGHT", button.text, "LEFT", -4, 0)
    end
    button:SetScript("OnClick", function()
        TortoiseGMManager.currentCategory = this.categoryId
        TortoiseGMManagerDB.lastCategory = this.categoryId
        TortoiseGMManager.page = 1
        searchBox:SetText("")
        TortoiseGMManager.ClearPendingConfirmation()
        TortoiseGMManager.RefreshCategoryButtons()
        TortoiseGMManager.RefreshList()
        if this.categoryId == "lookup" and TortoiseGMManager.currentResults and TortoiseGMManager.currentResults[1] then
            TortoiseGMManager.SetComposer(TortoiseGMManager.currentResults[1])
        elseif TortoiseGMManager.RefreshLookupState then
            TortoiseGMManager.RefreshLookupState()
        end
    end)
    table.insert(TortoiseGMManager.categoryButtons, button)
end

-- Tabs share the strip width in proportion to their label length, so the
-- row always spans edge to edge without uneven gaps.
local function layoutTabs()
    local buttons = TortoiseGMManager.categoryButtons
    local count = table.getn(buttons)
    if count == 0 then return end
    local natural, widths, i = 0, {}, nil
    for i = 1, count do
        local width = (buttons[i].text:GetStringWidth() or 0) + (buttons[i].icon and 16 or 0)
        widths[i] = width
        natural = natural + width
    end
    local extra = (CONTENT_WIDTH - natural) / count
    local x = 0
    for i = 1, count do
        local width = math.floor(widths[i] + extra)
        if i == count then width = CONTENT_WIDTH - x end
        buttons[i]:ClearAllPoints()
        buttons[i]:SetPoint("TOPLEFT", tabStrip, "TOPLEFT", x, 0)
        buttons[i]:SetWidth(width)
        x = x + width
    end
end
layoutTabs()

---------------------------------------------------------------------------
-- Command list
---------------------------------------------------------------------------

local resultLabel = Theme.Text(main, 10, COLORS.muted)
resultLabel:SetPoint("TOPLEFT", main, "TOPLEFT", PAD + 1, LIST_HEADER_TOP - 4)
resultLabel:SetWidth(CONTENT_WIDTH - 140); resultLabel:SetHeight(12)
TortoiseGMManager.resultLabel = resultLabel

local nextButton = Theme.IconButton(main, 20, ">", "secondary")
nextButton:SetPoint("TOPRIGHT", main, "TOPRIGHT", -PAD, LIST_HEADER_TOP)
nextButton:SetScript("OnClick", function()
    if TortoiseGMManager.page < TortoiseGMManager.pageCount then TortoiseGMManager.page = TortoiseGMManager.page + 1; TortoiseGMManager.RefreshList() end
end)
TortoiseGMManager.nextButton = nextButton

local pageText = Theme.Text(main, 10, COLORS.muted, { justify = "CENTER" })
pageText:SetPoint("RIGHT", nextButton, "LEFT", -4, 0)
pageText:SetWidth(54)
pageText:SetText("1 / 1")
TortoiseGMManager.pageText = pageText

local prevButton = Theme.IconButton(main, 20, "<", "secondary")
prevButton:SetPoint("RIGHT", pageText, "LEFT", -4, 0)
prevButton:SetScript("OnClick", function()
    if TortoiseGMManager.page > 1 then TortoiseGMManager.page = TortoiseGMManager.page - 1; TortoiseGMManager.RefreshList() end
end)
TortoiseGMManager.prevButton = prevButton

local emptyState = CreateFrame("Frame", nil, main)
emptyState:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, ROWS_TOP)
emptyState:SetWidth(CONTENT_WIDTH); emptyState:SetHeight(ROWS_BLOCK)
local emptyTitle = Theme.Text(emptyState, 12, COLORS.text, { justify = "CENTER" })
emptyTitle:SetPoint("CENTER", emptyState, "CENTER", 0, 10)
emptyTitle:SetWidth(CONTENT_WIDTH - 40)
local emptyDetail = Theme.Text(emptyState, 10, COLORS.muted, { justify = "CENTER" })
emptyDetail:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -6)
emptyDetail:SetWidth(CONTENT_WIDTH - 80)
emptyState:Hide()

local function setRowHover(row, hovered)
    if not row then return end
    row.hovered = hovered
    if hovered then Theme.Paint(row, COLORS.surfaceHover, COLORS.borderHover)
    else Theme.Paint(row, COLORS.surface, COLORS.border) end
end

local function rowChildEnter(button)
    setRowHover(button:GetParent(), true)
end

local function rowChildLeave(button)
    setRowHover(button:GetParent(), false)
    GameTooltip:Hide()
end

TortoiseGMManager.rows = {}
local rowIndex
for rowIndex = 1, ROWS_PER_PAGE do
    local row = CreateFrame("Frame", nil, main)
    row:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, ROWS_TOP - ((rowIndex - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetWidth(CONTENT_WIDTH); row:SetHeight(ROW_HEIGHT)
    Theme.Card(row)

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(2)
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
    Theme.Fill(row.accent, COLORS.gold)

    row.icon = Theme.Icon(row, 24)
    row.icon:SetPoint("LEFT", row, "LEFT", 10, 0)

    row.title = Theme.Text(row, 12, COLORS.text)
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 44, -5)
    row.title:SetHeight(14)

    row.badge = Theme.Badge(row)
    row.badge:SetPoint("LEFT", row.title, "RIGHT", 7, 0)

    row.command = Theme.Text(row, 11, COLORS.code, { code = true })
    row.command:SetPoint("TOPLEFT", row, "TOPLEFT", 44, -20)
    row.command:SetWidth(360); row.command:SetHeight(12)

    row:EnableMouse(true)
    row:SetScript("OnEnter", function()
        setRowHover(this, true)
        if this.entry then
            showTooltip(this, "ANCHOR_RIGHT", this.entry.label or this.entry.command or "Command", {
                { this.entry.detail, 1, 1, 1 },
                { this.entry.hint and this.entry.hint ~= "" and ("Args: " .. this.entry.hint) or nil, COLORS.gold[1], COLORS.gold[2], COLORS.gold[3] },
                { this.entry.lookupCommand and ("FIND: " .. this.entry.lookupCommand) or nil, COLORS.blue[1], COLORS.blue[2], COLORS.blue[3] },
                { this.entry.access and this.entry.access ~= "" and ("Access: " .. this.entry.access) or nil, COLORS.muted[1], COLORS.muted[2], COLORS.muted[3] },
            })
        end
    end)
    row:SetScript("OnLeave", function() setRowHover(this, false); GameTooltip:Hide() end)

    -- Right-hand action cluster: [primary action] [favourite] [help]
    row.helpButton = Theme.IconButton(row, 22, "?")
    row.helpButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.helpButton:SetScript("OnClick", function() if this.entry then TortoiseGMManager.RequestHelp(this.entry.command) end end)
    row.helpButton:SetScript("OnEnter", function()
        rowChildEnter(this)
        if this.entry then
            showTooltip(this, "ANCHOR_RIGHT", "Server syntax help", { { "Sends: .help " .. string.sub(this.entry.command, 2), 1, 1, 1 } })
        end
    end)
    row.helpButton:SetScript("OnLeave", function() rowChildLeave(this) end)

    row.favoriteButton = Theme.TextureButton(row, 22, Theme.STAR_TEXTURE, 13)
    row.favoriteButton.icon:SetTexCoord(0, 0.25, 0, 0.25)
    row.favoriteButton:SetPoint("RIGHT", row.helpButton, "LEFT", -2, 0)
    row.favoriteButton:SetScript("OnClick", function()
        if not this.entry then return end
        local added = TortoiseGMManager.ToggleFavourite(this.entry)
        TortoiseGMManager.SetStatus(added and "Added to favourites." or "Removed from favourites.", "ok")
        TortoiseGMManager.RefreshList()
    end)
    row.favoriteButton:SetScript("OnEnter", function()
        rowChildEnter(this)
        this.icon:SetAlpha(1)
        showTooltip(this, "ANCHOR_RIGHT", TortoiseGMManager.IsFavourite(this.entry and this.entry.command) and "Remove from favourites" or "Add to favourites")
    end)
    row.favoriteButton:SetScript("OnLeave", function()
        rowChildLeave(this)
        if not this.isFavourite then this.icon:SetAlpha(0.35) end
    end)

    row.useButton = Theme.Button(row, "", "secondary", 84, 22)
    row.useButton:SetPoint("RIGHT", row.favoriteButton, "LEFT", -6, 0)
    row.useButton:SetScript("OnClick", function()
        local entry = this.entry
        if not entry then return end
        local interaction = TortoiseGMManager.GetInteraction(entry)
        if getSingleToggle(entry) then
            executeToggle(entry, 1)
        elseif interaction == "execute" then
            TortoiseGMManager.Execute(entry.command)
        else
            TortoiseGMManager.SetComposer(entry)
            if interaction == "review" then TortoiseGMManager.SetStatus("Dangerous action loaded. Press EXECUTE twice to confirm.", "warn") end
        end
    end)
    row.useButton:SetScript("OnEnter", function()
        rowChildEnter(this)
        if this.entry then
            local title
            if TortoiseGMManager.IsDangerous(this.entry.command) then title = "Review dangerous command"
            elseif this.entry.direct then title = "Run now" else title = "Load into command bar" end
            showTooltip(this, "ANCHOR_RIGHT", title, {
                { this.entry.detail or "", 1, 1, 1 },
                { this.entry.hint and this.entry.hint ~= "" and ("Args: " .. this.entry.hint) or nil, COLORS.gold[1], COLORS.gold[2], COLORS.gold[3] },
            })
        end
    end)
    row.useButton:SetScript("OnLeave", function() rowChildLeave(this) end)

    -- Two-state commands render as a joined ON | OFF segmented control.
    row.toggleOffButton = Theme.Button(row, "OFF", "secondary", 42, 22)
    row.toggleOffButton:SetPoint("RIGHT", row.favoriteButton, "LEFT", -6, 0)
    row.toggleOffButton:SetScript("OnClick", function() if this.entry then executeToggle(this.entry, 2) end end)
    row.toggleOffButton:SetScript("OnEnter", function()
        rowChildEnter(this)
        showTooltip(this, "ANCHOR_RIGHT", "Turn off now", { { "Sends the OFF form immediately.", 1, 1, 1 } })
    end)
    row.toggleOffButton:SetScript("OnLeave", function() rowChildLeave(this) end)
    row.toggleOffButton:Hide()

    table.insert(TortoiseGMManager.rows, row)
end

main:SetScript("OnMouseWheel", function()
    local delta = arg1 or 0
    if delta > 0 and TortoiseGMManager.page > 1 then TortoiseGMManager.page = TortoiseGMManager.page - 1; TortoiseGMManager.RefreshList()
    elseif delta < 0 and TortoiseGMManager.page < TortoiseGMManager.pageCount then TortoiseGMManager.page = TortoiseGMManager.page + 1; TortoiseGMManager.RefreshList() end
end)

---------------------------------------------------------------------------
-- Composer: header, optional lookup row, arguments, preview + execute
---------------------------------------------------------------------------

local composer = CreateFrame("Frame", nil, main)
composer:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, COMPOSER_TOP)
composer:SetWidth(CONTENT_WIDTH); composer:SetHeight(COMPOSER_HEIGHT)
Theme.Card(composer, { 0.066, 0.069, 0.083, 0.98 }, COLORS.border)

-- Header: icon, action name + badge, one-line description, access level.
local composerIcon = Theme.Icon(composer, 28)
composerIcon:SetPoint("TOPLEFT", composer, "TOPLEFT", 10, -8)

local composerTitle = Theme.Text(composer, 13, COLORS.text)
composerTitle:SetPoint("TOPLEFT", composer, "TOPLEFT", 47, -8)
composerTitle:SetHeight(16)

local composerBadge = Theme.Badge(composer)
composerBadge:SetPoint("LEFT", composerTitle, "RIGHT", 8, 0)

local composerDetail = Theme.Text(composer, 10, COLORS.muted)
composerDetail:SetPoint("TOPLEFT", composer, "TOPLEFT", 47, -25)
composerDetail:SetWidth(CONTENT_WIDTH - 60); composerDetail:SetHeight(12)

local composerAccess = Theme.Text(composer, 10, COLORS.muted, { justify = "RIGHT" })
composerAccess:SetPoint("TOPRIGHT", composer, "TOPRIGHT", -12, -10)
composerAccess:SetWidth(160); composerAccess:SetHeight(12)

local composerDivider = Theme.Divider(composer)
composerDivider:SetPoint("TOPLEFT", composer, "TOPLEFT", 1, -44)
composerDivider:SetPoint("TOPRIGHT", composer, "TOPRIGHT", -1, -44)

-- Shown in the body when there is nothing to fill in.
local composerEmpty = Theme.Text(composer, 10, COLORS.faint, { justify = "CENTER" })
composerEmpty:SetPoint("TOP", composer, "TOP", 0, -82)
composerEmpty:SetWidth(CONTENT_WIDTH - 40); composerEmpty:SetHeight(12)

local layoutComposer

local function refreshComposerHeader()
    local entry = TortoiseGMManager.selectedEntry
    if entry then
        composerIcon:SetTexture(getCommandIcon(entry)); composerIcon:SetAlpha(1)
        composerTitle:SetText(entry.label or entry.command or "Command")
        Theme.SetTextColor(composerTitle, COLORS.text)
        composerDetail:SetText(entry.detail or "")
        local interaction = TortoiseGMManager.GetInteraction(entry)
        if interaction == "review" then Theme.SetBadge(composerBadge, "REVIEW", COLORS.red)
        elseif entry.lookupCommand then Theme.SetBadge(composerBadge, "LOOKUP", COLORS.blue)
        elseif interaction == "configure" then Theme.SetBadge(composerBadge, "CONFIGURE", COLORS.gold)
        elseif interaction == "execute" then Theme.SetBadge(composerBadge, "INSTANT", COLORS.green)
        else Theme.SetBadge(composerBadge, nil) end
        if entry.access and entry.access ~= "" then
            composerAccess:SetText("Access  " .. Theme.Hex(COLORS.text) .. entry.access .. "|r")
        else composerAccess:SetText("") end
    else
        local command = trim(TortoiseGMManager.commandBox and TortoiseGMManager.commandBox:GetText() or "")
        composerIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); composerIcon:SetAlpha(0.5)
        if command ~= "" then
            composerTitle:SetText("Manual command")
            Theme.SetTextColor(composerTitle, COLORS.text)
            composerDetail:SetText("Supplied through /tgmm. Not linked to a catalogue action.")
        else
            composerTitle:SetText("No action selected")
            Theme.SetTextColor(composerTitle, COLORS.muted)
            composerDetail:SetText("Pick an action above, or send any command with /tgmm <command>.")
        end
        Theme.SetBadge(composerBadge, nil)
        composerAccess:SetText("")
    end
    if layoutComposer then layoutComposer() end
end

-- Lookup row (only for lookup-capable actions)
local lookupLabel = Theme.Caption(composer, "ITEM NAME OR ID")
lookupLabel:SetPoint("TOPLEFT", composer, "TOPLEFT", 12, -58)
lookupLabel:SetWidth(112); lookupLabel:SetHeight(12)

local function getLookupEntry()
    local selected = TortoiseGMManager.selectedEntry
    if selected and selected.lookupCommand then return selected end
    return nil
end

local lookupButton
local lookupBox = Theme.Input(composer, "TortoiseGMManagerLookupBox", 344, 24, { search = true, placeholder = "Type a name and press Enter, or an ID" })
lookupBox:SetPoint("TOPLEFT", composer, "TOPLEFT", 126, -52)
lookupBox:SetScript("OnEnterPressed", function()
    local entry = getLookupEntry()
    if entry and trim(this:GetText()) ~= "" then TortoiseGMManager.ExecuteLookup(entry, this:GetText()) end
end)
lookupBox:SetScript("OnTextChanged", function() if TortoiseGMManager.RefreshLookupState then TortoiseGMManager.RefreshLookupState() end end)
Theme.WatchInput(lookupBox)
TortoiseGMManager.lookupBox = lookupBox

lookupButton = Theme.Button(composer, "SEARCH", "info", 82, 24)
lookupButton:SetPoint("LEFT", lookupBox, "RIGHT", 8, 0)
lookupButton:Disable()
lookupButton:SetScript("OnClick", function() TortoiseGMManager.ExecuteLookup(getLookupEntry(), lookupBox:GetText()) end)
lookupButton:SetScript("OnEnter", function()
    local entry = getLookupEntry()
    if entry then
        showTooltip(this, "ANCHOR_TOP", entry == TortoiseGMManager.selectedEntry and "Search by name or ID" or "Search items by name or ID", {
            { "Uses " .. entry.lookupCommand .. " and loads the matching action without running it.", 1, 1, 1 },
        })
    else showTooltip(this, "ANCHOR_TOP", "Item lookup unavailable") end
end)
lookupButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
TortoiseGMManager.lookupButton = lookupButton
lookupLabel:Hide(); lookupBox:Hide(); lookupButton:Hide()

-- Arguments sit directly under the lookup row, or take its place when the
-- action has no lookup, so the composer never shows an empty band.
local argumentAnchor = CreateFrame("Frame", nil, composer)
argumentAnchor:SetWidth(CONTENT_WIDTH - 20); argumentAnchor:SetHeight(1)

layoutComposer = function()
    argumentAnchor:ClearAllPoints()
    if lookupBox:IsShown() then argumentAnchor:SetPoint("TOPLEFT", composer, "TOPLEFT", 10, -84)
    else argumentAnchor:SetPoint("TOPLEFT", composer, "TOPLEFT", 10, -52) end
    local hasArguments, i = false, nil
    for i = 1, table.getn(TortoiseGMManager.argumentControls or {}) do
        if TortoiseGMManager.argumentControls[i]:IsShown() then hasArguments = true end
    end
    if hasArguments or lookupBox:IsShown() then composerEmpty:Hide()
    else
        local manual = trim(TortoiseGMManager.commandBox and TortoiseGMManager.commandBox:GetText() or "") ~= ""
        if TortoiseGMManager.selectedEntry then composerEmpty:SetText("No options needed. Check the preview below and execute.")
        elseif manual then composerEmpty:SetText("Review the preview below, then execute.")
        else composerEmpty:SetText("Choose an action from the list to configure it here.") end
        composerEmpty:Show()
    end
end
layoutComposer()

-- Four reusable argument controls keep the composer small and avoid creating
-- frames whenever another action is selected.
TortoiseGMManager.argumentControls = {}
local argumentIndex
for argumentIndex = 1, 4 do
    local control = CreateFrame("Frame", nil, composer)
    control:SetWidth(ARGUMENT_WIDTH); control:SetHeight(44)
    control:SetPoint("TOPLEFT", argumentAnchor, "TOPLEFT", (argumentIndex - 1) * (ARGUMENT_WIDTH + ARGUMENT_GAP), 0)
    control.label = Theme.Caption(control, "")
    control.label:SetPoint("TOPLEFT", control, "TOPLEFT", 2, 0)
    control.label:SetWidth(ARGUMENT_WIDTH - 4); control.label:SetHeight(12)
    control.edit = Theme.Input(control, nil, ARGUMENT_WIDTH - 44, 24, { justify = "CENTER" })
    control.edit:SetPoint("BOTTOM", control, "BOTTOM", 0, 0)
    control.minus = Theme.Button(control, "-", "secondary", 23, 24, 13)
    control.minus:SetPoint("RIGHT", control.edit, "LEFT", 1, 0)
    control.plus = Theme.Button(control, "+", "secondary", 23, 24, 13)
    control.plus:SetPoint("LEFT", control.edit, "RIGHT", -1, 0)
    control.toggle = Theme.Button(control, "", "secondary", ARGUMENT_WIDTH, 24, 11)
    control.toggle:SetPoint("BOTTOM", control, "BOTTOM", 0, 0)
    control:Hide()
    table.insert(TortoiseGMManager.argumentControls, control)
end

local commandBox

function TortoiseGMManager.RefreshStructuredPreview()
    local entry = TortoiseGMManager.selectedEntry
    if not entry then return end
    local valid, message = TortoiseGMManager.ValidateValues(entry, TortoiseGMManager.structuredValues)
    commandBox:SetText(TortoiseGMManager.ComposeValues(entry, TortoiseGMManager.structuredValues))
    if not valid then TortoiseGMManager.SetStatus(message, "info") end
end

function TortoiseGMManager.RefreshArgumentControls()
    local entry = TortoiseGMManager.selectedEntry
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    local argumentCount = table.getn(arguments)
    local i
    for i = 1, 4 do
        local control = TortoiseGMManager.argumentControls[i]
        local argument = arguments[i]
        if argument then
            control.argument = argument
            control:ClearAllPoints(); control.label:ClearAllPoints(); control.edit:ClearAllPoints()
            if argumentCount == 1 and argument.type == "text" then
                -- A single free-text argument gets one full-width labelled field.
                control:SetWidth(CONTENT_WIDTH - 20); control:SetHeight(24); control:SetPoint("TOPLEFT", argumentAnchor, "TOPLEFT", 0, 0)
                -- Label column grows with long hint-derived labels (capped).
                control.label:SetPoint("LEFT", control, "LEFT", 2, 0); control.label:SetWidth(260)
                control.label:SetText(string.upper(argument.label or "") .. (argument.required and " *" or ""))
                local labelWidth = (control.label:GetStringWidth() or 0) + 16
                if labelWidth < 116 then labelWidth = 116 elseif labelWidth > 260 then labelWidth = 260 end
                control.label:SetWidth(labelWidth - 6)
                control.edit:SetPoint("LEFT", control, "LEFT", labelWidth, 0); control.edit:SetWidth(CONTENT_WIDTH - 20 - labelWidth)
                if control.edit.SetJustifyH then control.edit:SetJustifyH("LEFT") end
            else
                control:SetWidth(ARGUMENT_WIDTH); control:SetHeight(44); control:SetPoint("TOPLEFT", argumentAnchor, "TOPLEFT", (i - 1) * (ARGUMENT_WIDTH + ARGUMENT_GAP), 0)
                control.label:SetPoint("TOPLEFT", control, "TOPLEFT", 2, 0); control.label:SetWidth(ARGUMENT_WIDTH - 4)
                control.edit:SetPoint("BOTTOM", control, "BOTTOM", 0, 0)
            end
            control.label:SetText(string.upper(argument.label or "") .. (argument.required and (" " .. Theme.Hex(COLORS.gold) .. "*|r") or ""))
            control.edit.argument = argument; control.minus.argument = argument; control.plus.argument = argument; control.toggle.argument = argument
            control.edit:SetText(tostring(TortoiseGMManager.structuredValues[argument.key] or ""))
            if argument.type == "toggle" then
                control.edit:Hide(); control.minus:Hide(); control.plus:Hide(); control.toggle:Show()
                local value = TortoiseGMManager.structuredValues[argument.key]
                control.toggle:SetText(TortoiseGMManager.GetOptionLabel(argument, value))
                control.toggle:SetLabelColor(getOptionColor(value))
            else
                control.toggle:Hide(); control.edit:Show()
                if argument.type == "number" then
                    control.edit:SetWidth(ARGUMENT_WIDTH - 44); control.minus:Show(); control.plus:Show()
                    if control.edit.SetJustifyH then control.edit:SetJustifyH("CENTER") end
                elseif not (argumentCount == 1 and argument.type == "text") then
                    control.minus:Hide(); control.plus:Hide(); control.edit:SetWidth(ARGUMENT_WIDTH)
                    if control.edit.SetJustifyH then control.edit:SetJustifyH("LEFT") end
                else
                    control.minus:Hide(); control.plus:Hide()
                end
            end
            control:Show()
        else control.argument = nil; control:Hide() end
    end
end

for argumentIndex = 1, 4 do
    local control = TortoiseGMManager.argumentControls[argumentIndex]
    control.edit:SetScript("OnTextChanged", function()
        local argument = this.argument
        if argument and TortoiseGMManager.structuredValues then TortoiseGMManager.structuredValues[argument.key] = this:GetText(); TortoiseGMManager.RefreshStructuredPreview() end
    end)
    control.edit:SetScript("OnEnterPressed", function()
        local entry = TortoiseGMManager.selectedEntry
        if not entry or not this.argument then return end
        local valid, message = TortoiseGMManager.ValidateValues(entry, TortoiseGMManager.structuredValues)
        if not valid then TortoiseGMManager.SetStatus(message, "error"); return end
        TortoiseGMManager.Execute(commandBox:GetText())
        this:ClearFocus()
    end)
    Theme.WatchInput(control.edit)
    control.minus:SetScript("OnClick", function()
        local argument = this.argument
        if not argument or not TortoiseGMManager.structuredValues then return end
        TortoiseGMManager.structuredValues[argument.key] = TortoiseGMManager.AdjustNumber(argument, TortoiseGMManager.structuredValues[argument.key], -1)
        TortoiseGMManager.RefreshArgumentControls(); TortoiseGMManager.RefreshStructuredPreview()
    end)
    control.plus:SetScript("OnClick", function()
        local argument = this.argument
        if not argument or not TortoiseGMManager.structuredValues then return end
        TortoiseGMManager.structuredValues[argument.key] = TortoiseGMManager.AdjustNumber(argument, TortoiseGMManager.structuredValues[argument.key], 1)
        TortoiseGMManager.RefreshArgumentControls(); TortoiseGMManager.RefreshStructuredPreview()
    end)
    control.toggle:SetScript("OnClick", function()
        local argument = this.argument
        if not argument or not TortoiseGMManager.structuredValues then return end
        TortoiseGMManager.structuredValues[argument.key] = TortoiseGMManager.CycleToggle(argument, TortoiseGMManager.structuredValues[argument.key], 1)
        TortoiseGMManager.RefreshArgumentControls(); TortoiseGMManager.RefreshStructuredPreview()
    end)
    control.toggle:SetScript("OnEnter", function()
        if this.argument then showTooltip(this, "ANCHOR_TOP", this.argument.label or "Option", { { "Click to cycle the value.", 1, 1, 1 } }) end
    end)
    control.toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Preview + primary action, pinned to the bottom of the composer.
local previewLabel = Theme.Caption(composer, "PREVIEW")
previewLabel:SetPoint("BOTTOMLEFT", composer, "BOTTOMLEFT", 12, 42)

local hintText = Theme.Text(composer, 10, COLORS.muted)
hintText:SetPoint("LEFT", previewLabel, "RIGHT", 10, 0)
hintText:SetWidth(CONTENT_WIDTH - 90); hintText:SetHeight(12)
hintText:SetText("Read-only. Built from the controls above.")
TortoiseGMManager.hintText = hintText

local runButton = Theme.Button(composer, "EXECUTE", "primary", 104, 28, 11)
runButton:SetPoint("BOTTOMRIGHT", composer, "BOTTOMRIGHT", -10, 10)

local helpButton = Theme.Button(composer, "HELP", "secondary", 56, 28)
helpButton:SetPoint("RIGHT", runButton, "LEFT", -6, 0)
helpButton:SetScript("OnClick", function() TortoiseGMManager.RequestHelp(TortoiseGMManager.selectedEntry or commandBox:GetText()) end)
helpButton:SetScript("OnEnter", function() showTooltip(this, "ANCHOR_TOP", "Server syntax help", { { "Asks the server for .help on the current command.", 1, 1, 1 } }) end)
helpButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

commandBox = Theme.Input(composer, "TortoiseGMManagerCommandBox", CONTENT_WIDTH - 20 - 104 - 6 - 56 - 6, 28, {
    code = true,
    prefix = ">",
    placeholder = "The exact command appears here",
})
commandBox:SetPoint("BOTTOMLEFT", composer, "BOTTOMLEFT", 10, 10)
commandBox:EnableKeyboard(false)
commandBox:SetScript("OnTextChanged", function()
    TortoiseGMManager.ClearPendingConfirmation()
    if TortoiseGMManager.RefreshLookupState then TortoiseGMManager.RefreshLookupState() end
end)
Theme.WatchInput(commandBox)
TortoiseGMManager.commandBox = commandBox

function TortoiseGMManager.RefreshLookupState()
    local entry = getLookupEntry()
    if not entry then
        lookupLabel:Hide(); lookupBox:Hide(); lookupButton:Hide(); lookupButton:Disable()
        layoutComposer()
        return
    end
    lookupLabel:Show(); lookupBox:Show(); lookupButton:Show()
    layoutComposer()
    local query = trim(lookupBox:GetText())
    local actionMatches = TortoiseGMManager.CommandMatchesEntry(entry, commandBox:GetText())
    if query ~= "" and actionMatches then lookupButton:Enable() else lookupButton:Disable() end
end

runButton:SetScript("OnClick", function()
    if TortoiseGMManager.selectedEntry and table.getn(TortoiseGMManager.GetEntryArguments(TortoiseGMManager.selectedEntry)) > 0 then
        local valid, message = TortoiseGMManager.ValidateValues(TortoiseGMManager.selectedEntry, TortoiseGMManager.structuredValues)
        if not valid then TortoiseGMManager.SetStatus(message, "error"); return end
    end
    TortoiseGMManager.Execute(commandBox:GetText())
end)
runButton:SetScript("OnEnter", function()
    local command = TortoiseGMManager.NormalizeCommand(commandBox:GetText() or "")
    if command ~= "" and TortoiseGMManager.IsDangerous(command) then
        showTooltip(this, "ANCHOR_TOP", "Dangerous command", { { "Press twice within 5 seconds to confirm.", 1, 1, 1 } })
    else
        showTooltip(this, "ANCHOR_TOP", "Execute", { { "Sends the previewed command to the server.", 1, 1, 1 } })
    end
end)
runButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Reflects the confirmation guard on the button itself: dangerous commands
-- turn it red and an armed command shows a live countdown.
local runState = {}
local function refreshRunButton()
    local command = TortoiseGMManager.NormalizeCommand(commandBox:GetText() or "")
    local dangerous = command ~= "" and command ~= "." and TortoiseGMManager.IsDangerous(command)
    local label = "EXECUTE"
    if dangerous and TortoiseGMManager.pendingCommand == command and TortoiseGMManager.pendingUntil then
        local remaining = TortoiseGMManager.pendingUntil - GetTime()
        if remaining >= 0 then label = "CONFIRM  " .. tostring(math.ceil(remaining)) .. "s" end
    end
    if runState.label ~= label then runState.label = label; runButton:SetText(label) end
    if runState.dangerous ~= dangerous then runState.dangerous = dangerous; runButton:SetVariant(dangerous and "danger" or "primary") end
end

local runElapsed = 0
composer:SetScript("OnUpdate", function()
    runElapsed = runElapsed + (arg1 or 0)
    if runElapsed < 0.1 then return end
    runElapsed = 0
    refreshRunButton()
end)

---------------------------------------------------------------------------
-- Status bar
---------------------------------------------------------------------------

local footer = CreateFrame("Frame", nil, main)
footer:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 1, 1)
footer:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -1, 1)
footer:SetHeight(FOOTER_HEIGHT)
local footerBackground = footer:CreateTexture(nil, "BACKGROUND")
footerBackground:SetAllPoints(footer)
Theme.Fill(footerBackground, COLORS.header)
local footerLine = Theme.Divider(footer)
footerLine:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 0)
footerLine:SetPoint("TOPRIGHT", footer, "TOPRIGHT", 0, 0)

local statusDot = Theme.Dot(footer, 6)
statusDot:SetPoint("LEFT", footer, "LEFT", PAD, 0)
Theme.SetDotColor(statusDot, COLORS.blue)

local footerHint = Theme.Text(footer, 9, COLORS.faint, { justify = "RIGHT" })
footerHint:SetPoint("RIGHT", footer, "RIGHT", -PAD, 0)
footerHint:SetText("Wheel: page    Esc: close")

local statusText = Theme.Text(footer, 10, COLORS.blue)
statusText:SetPoint("LEFT", statusDot, "RIGHT", 8, 0)
statusText:SetWidth(CONTENT_WIDTH - 140); statusText:SetHeight(12)
statusText:SetText("Ready.")
TortoiseGMManager.statusText = statusText

function TortoiseGMManager.SetStatus(message, kind)
    if not statusText then return end
    statusText:SetText(message or "")
    local color = COLORS.text
    if kind == "error" then color = COLORS.red
    elseif kind == "warn" then color = COLORS.orange
    elseif kind == "ok" then color = COLORS.green
    elseif kind == "info" then color = COLORS.blue end
    Theme.SetTextColor(statusText, color)
    Theme.SetDotColor(statusDot, color)
end

---------------------------------------------------------------------------
-- Composer state
---------------------------------------------------------------------------

function TortoiseGMManager.SetComposer(entry)
    if not entry then return end
    TortoiseGMManager.selectedEntry = entry
    TortoiseGMManager.structuredValues = TortoiseGMManager.InitializeValues(entry)
    TortoiseGMManager.ClearPendingConfirmation()
    local command = TortoiseGMManager.ComposeValues(entry, TortoiseGMManager.structuredValues)
    commandBox:SetText(command)
    TortoiseGMManager.RefreshArgumentControls()
    local hint = ""
    if entry.hint and entry.hint ~= "" then hint = "Args: " .. entry.hint end
    lookupBox:SetText("")
    if entry.lookupCommand then
        local lookupPrompt = string.upper(entry.lookupHint or "NAME OR ID")
        if entry.lookupCommand == ".lookup item" then lookupPrompt = "ITEM NAME OR ID" end
        lookupLabel:SetText(lookupPrompt)
        hint = hint .. (hint ~= "" and "   " or "") .. "Search by name or enter an ID directly"
    else lookupLabel:SetText("ITEM NAME OR ID") end
    hintText:SetText(hint)
    TortoiseGMManager.RefreshLookupState()
    refreshComposerHeader()
    if entry.lookupCommand then lookupBox:SetFocus()
    elseif TortoiseGMManager.argumentControls[1] and TortoiseGMManager.argumentControls[1].edit:IsVisible() then TortoiseGMManager.argumentControls[1].edit:SetFocus() end
end

function TortoiseGMManager.LoadCommand(command, entry, hint, values)
    TortoiseGMManager.selectedEntry = entry
    TortoiseGMManager.structuredValues = TortoiseGMManager.InitializeValues(entry, values or TortoiseGMManager.structuredValues)
    TortoiseGMManager.ClearPendingConfirmation()
    commandBox:SetText(TortoiseGMManager.NormalizeCommand(command))
    TortoiseGMManager.RefreshArgumentControls()
    hintText:SetText(hint or "Loaded from lookup results. Review, adjust arguments if needed, then EXECUTE.")
    TortoiseGMManager.RefreshLookupState()
    refreshComposerHeader()
    TortoiseGMManager.ShowUI()
end

function TortoiseGMManager.RefreshCategoryButtons()
    local i
    for i = 1, table.getn(TortoiseGMManager.categoryButtons) do
        local button = TortoiseGMManager.categoryButtons[i]
        button:SetSelected(button.categoryId == TortoiseGMManager.currentCategory)
    end
end

function TortoiseGMManager.RefreshTarget()
    local name = UnitName("target")
    if name and name ~= "" then
        targetText:SetText("Target: " .. name); Theme.SetTextColor(targetText, COLORS.text); Theme.SetDotColor(targetDot, COLORS.green)
    else
        targetText:SetText("Target: none"); Theme.SetTextColor(targetText, COLORS.muted); Theme.SetDotColor(targetDot, COLORS.faint)
    end
    targetText:SetWidth(160)
    local textWidth = targetText:GetStringWidth() or 0
    if textWidth < 20 or textWidth > 160 then textWidth = 160 end
    targetText:SetWidth(textWidth + 2); targetText:SetHeight(12)
    targetPill:SetWidth(textWidth + 32)
end

local function refreshEmptyState(count, query)
    if count > 0 then emptyState:Hide(); return end
    if query ~= "" then
        emptyTitle:SetText("No actions match \"" .. query .. "\"")
        emptyDetail:SetText("Try a shorter keyword, a command such as .npc, or switch to the All tab.")
    elseif TortoiseGMManager.currentCategory == "favourites" then
        emptyTitle:SetText("No favourites yet")
        emptyDetail:SetText("Click the star on any action to pin it here.")
    else
        emptyTitle:SetText("Nothing here yet")
        emptyDetail:SetText("This category has no actions.")
    end
    emptyState:Show()
end

function TortoiseGMManager.RefreshList()
    if not TortoiseGMManager.currentCategory then TortoiseGMManager.currentCategory = TortoiseGMManager.GetDefaultCategory() end
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
    local resultSummary = Theme.Hex(COLORS.text) .. string.upper(categoryLabel) .. "|r   " .. tostring(count) .. (count == 1 and " command" or " commands")
    if query ~= "" then resultSummary = resultSummary .. " matching \"" .. query .. "\"" end
    resultLabel:SetText(resultSummary)

    local startIndex = ((TortoiseGMManager.page - 1) * ROWS_PER_PAGE) + 1
    for rowIndex = 1, ROWS_PER_PAGE do
        local row = TortoiseGMManager.rows[rowIndex]
        local entry = results[startIndex + rowIndex - 1]
        if entry then
            row.entry = entry; row.useButton.entry = entry; row.toggleOffButton.entry = entry; row.favoriteButton.entry = entry; row.helpButton.entry = entry
            if entry.hint and entry.hint ~= "" then row.helpButton:Show() else row.helpButton:Hide() end
            -- Measure the label so the badge can sit right after it.
            row.title:SetWidth(290)
            row.title:SetText(entry.label or entry.command)
            local titleWidth = row.title:GetStringWidth() or 0
            if titleWidth < 8 or titleWidth > 288 then titleWidth = 288 end
            row.title:SetWidth(titleWidth + 2)
            row.icon:SetTexture(getCommandIcon(entry))
            if entry.danger then
                Theme.Fill(row.accent, COLORS.red); Theme.SetBadge(row.badge, "DANGER", COLORS.red)
            elseif entry.lookupCommand then
                Theme.Fill(row.accent, COLORS.blue); Theme.SetBadge(row.badge, "LOOKUP", COLORS.blue)
            else
                Theme.Fill(row.accent, COLORS.goldDim); Theme.SetBadge(row.badge, nil)
            end
            local raw = entry.command or ""
            if entry.hint and entry.hint ~= "" then raw = raw .. "  " .. Theme.Hex(COLORS.faint) .. "<" .. entry.hint .. ">|r" end
            row.command:SetText(raw)
            local interaction = TortoiseGMManager.GetInteraction(entry)
            local toggle = getSingleToggle(entry)
            row.useButton:ClearAllPoints()
            if toggle and toggle.options and table.getn(toggle.options) >= 2 then
                row.useButton:SetWidth(42); row.useButton:SetPoint("RIGHT", row.toggleOffButton, "LEFT", 1, 0)
                row.useButton:SetText(toggle.options[1].label or "ON")
                row.useButton:SetVariant("secondary"); row.useButton:SetLabelColor(COLORS.green)
                row.toggleOffButton:SetText(toggle.options[2].label or "OFF")
                row.toggleOffButton:SetLabelColor(COLORS.muted)
                row.toggleOffButton:Show()
            else
                row.useButton:SetWidth(84); row.useButton:SetPoint("RIGHT", row.favoriteButton, "LEFT", -6, 0)
                row.toggleOffButton:Hide()
                row.useButton:SetLabelColor(nil)
                if interaction == "review" then row.useButton:SetText("REVIEW"); row.useButton:SetVariant("secondary"); row.useButton:SetLabelColor(COLORS.red)
                elseif interaction == "execute" then row.useButton:SetText("RUN NOW"); row.useButton:SetVariant("primary")
                else row.useButton:SetText("CONFIGURE"); row.useButton:SetVariant("secondary") end
            end
            local favourite = TortoiseGMManager.IsFavourite(entry.command)
            row.favoriteButton.isFavourite = favourite
            row.favoriteButton.icon:SetAlpha(favourite and 1 or 0.35)
            if favourite then row.favoriteButton.icon:SetVertexColor(1, 1, 1) else row.favoriteButton.icon:SetVertexColor(0.6, 0.6, 0.6) end
            setRowHover(row, false)
            row:Show()
        else
            row.entry = nil; row.useButton.entry = nil; row.toggleOffButton.entry = nil; row.toggleOffButton:Hide(); row.favoriteButton.entry = nil; row.helpButton.entry = nil; row.helpButton:Hide(); row:Hide()
        end
    end

    refreshEmptyState(count, query)
    pageText:SetText(tostring(TortoiseGMManager.page) .. " / " .. tostring(pageCount))
    if TortoiseGMManager.page <= 1 then prevButton:Disable() else prevButton:Enable() end
    if TortoiseGMManager.page >= pageCount then nextButton:Disable() else nextButton:Enable() end
    TortoiseGMManager.RefreshTarget()
end

function TortoiseGMManager.ShowUI()
    TortoiseGMManager.InitializeDB()
    TortoiseGMManager.currentCategory = TortoiseGMManager.currentCategory or TortoiseGMManager.GetDefaultCategory()
    layoutTabs()
    TortoiseGMManager.RefreshCategoryButtons(); TortoiseGMManager.RefreshList(); refreshComposerHeader(); main:Show()
end

function TortoiseGMManager.HideUI()
    main:Hide()
end

main:SetScript("OnHide", function()
    if TortoiseGMManager.HideLookupResults then TortoiseGMManager.HideLookupResults(true) end
    if TortoiseGMManager.pendingLookup and TortoiseGMManager.EndLookup then TortoiseGMManager.EndLookup("dismissed") end
    TortoiseGMManager.ClearPendingConfirmation()
    TortoiseGMManager.selectedEntry = nil
    TortoiseGMManager.structuredValues = nil
    TortoiseGMManager.RefreshArgumentControls()
    TortoiseGMManager.RefreshLookupState()
    hintText:SetText("Read-only. Built from the controls above.")
    refreshComposerHeader()
    commandBox:ClearFocus(); lookupBox:ClearFocus(); searchBox:ClearFocus()
end)

function TortoiseGMManager.ToggleUI()
    if main:IsVisible() then TortoiseGMManager.HideUI() else TortoiseGMManager.ShowUI() end
end

---------------------------------------------------------------------------
-- Minimap launcher (stock minimap-button look so it sits with the others)
---------------------------------------------------------------------------

local minimapButton = CreateFrame("Button", "TortoiseGMManagerMinimapButton", Minimap)
minimapButton:SetWidth(30); minimapButton:SetHeight(30); minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetPoint("CENTER", Minimap, "CENTER", TortoiseGMManagerDB.minimapX or 52, TortoiseGMManagerDB.minimapY or 52)
minimapButton:RegisterForClicks("LeftButtonUp"); minimapButton:RegisterForDrag("LeftButton")
local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetWidth(20); minimapIcon:SetHeight(20); minimapIcon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapIcon:SetTexture(BRAND_ICON); minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetWidth(52); minimapBorder:SetHeight(52); minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
TortoiseGMManager.minimapButton = minimapButton

local function restoreSavedPositions()
    main:ClearAllPoints()
    main:SetPoint(TortoiseGMManagerDB.framePoint or "CENTER", UIParent, TortoiseGMManagerDB.frameRelativePoint or "CENTER", TortoiseGMManagerDB.frameX or 0, TortoiseGMManagerDB.frameY or 15)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", TortoiseGMManagerDB.minimapX or 52, TortoiseGMManagerDB.minimapY or 52)
end

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
    TortoiseGMManager.minimapWasDragged = false
    if not IsShiftKeyDown() then return end
    TortoiseGMManager.minimapDragging = true; TortoiseGMManager.minimapWasDragged = true
    this:SetScript("OnUpdate", updateMinimapButtonPosition)
end)
minimapButton:SetScript("OnDragStop", function()
    if not TortoiseGMManager.minimapDragging then return end
    TortoiseGMManager.minimapDragging = false; this:SetScript("OnUpdate", nil); updateMinimapButtonPosition()
end)
minimapButton:SetScript("OnClick", function()
    if TortoiseGMManager.minimapWasDragged then TortoiseGMManager.minimapWasDragged = false; return end
    TortoiseGMManager.ToggleUI()
end)
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT"); GameTooltip:SetText("TortoiseGMManager", COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
    GameTooltip:AddLine("Click: open / close", 1, 1, 1); GameTooltip:AddLine("Shift-drag: move around minimap", 0.75, 0.75, 0.75); GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_TORTOISEGMMANAGER1 = "/tgmm"
SlashCmdList["TORTOISEGMMANAGER"] = function(msg)
    msg = trim(msg); TortoiseGMManager.ShowUI()
    if msg ~= "" then
        TortoiseGMManager.selectedEntry = nil; TortoiseGMManager.structuredValues = nil
        TortoiseGMManager.RefreshArgumentControls(); lookupButton:Disable(); commandBox:SetText(TortoiseGMManager.NormalizeCommand(msg))
        hintText:SetText("Command supplied through /tgmm. Review the read-only preview, then press EXECUTE.")
        refreshComposerHeader()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED"); eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD"); eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        TortoiseGMManager.InitializeDB()
        TortoiseGMManager.currentCategory = TortoiseGMManager.GetDefaultCategory()
        TortoiseGMManagerDB.lastCategory = TortoiseGMManager.currentCategory
        restoreSavedPositions()
        TortoiseGMManager.RefreshCategoryButtons(); TortoiseGMManager.RefreshList(); TortoiseGMManager.Print("Loaded. Click the minimap hammer or use /tgmm.")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then TortoiseGMManager.RefreshTarget() end
end)
