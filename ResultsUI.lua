TortoiseGMManager = TortoiseGMManager or {}

local Theme = TortoiseGMManager.Theme
local COLORS = Theme.colors

-- Layout grid (matches the main window: 14px padding, 44px header, same
-- height so both windows line up when docked side by side).
local RESULTS_PER_PAGE = 6
local RESULT_WIDTH = 440
local RESULT_HEIGHT = TortoiseGMManager.frame and TortoiseGMManager.frame:GetHeight() or 0
if RESULT_HEIGHT < 400 then RESULT_HEIGHT = 578 end
local PAD = 14
local CONTENT_WIDTH = RESULT_WIDTH - (PAD * 2)
local HEADER_HEIGHT = 44
local CONTEXT_TOP = -54
local LIST_HEADER_TOP = -88
local ROWS_TOP = -114
local ROW_HEIGHT = 34
local ROW_GAP = 4
local ROWS_BLOCK = (RESULTS_PER_PAGE * ROW_HEIGHT) + ((RESULTS_PER_PAGE - 1) * ROW_GAP)
local DETAIL_TOP = ROWS_TOP - ROWS_BLOCK - 18

local KIND_ICONS = {
    item = "Interface\\Icons\\INV_Misc_Book_09", spell = "Interface\\Icons\\Spell_Arcane_Arcane01",
    quest = "Interface\\Icons\\INV_Misc_Note_01", creature = "Interface\\Icons\\Ability_Hunter_BeastCall",
    gameobject = "Interface\\Icons\\INV_Misc_Gear_01", skill = "Interface\\Icons\\INV_Misc_Book_09",
    faction = "Interface\\Icons\\Spell_Holy_SealOfMight", itemset = "Interface\\Icons\\INV_Chest_Chain_05",
    event = "Interface\\Icons\\INV_Misc_PocketWatch_01", guild = "Interface\\Icons\\INV_Banner_03",
    player = "Interface\\Icons\\INV_Misc_Head_Human_01", account = "Interface\\Icons\\INV_Misc_Key_03",
}

local function copy(values) local result, k, v = {}, nil, nil; for k, v in pairs(values or {}) do result[k] = v end; return result end
local function getItemReference(result)
    if not result or result.kind ~= "item" then return nil end
    if result.link then
        local _, _, reference = string.find(result.link, "|H([^|]+)|h")
        if reference then return reference end
    end
    return "item:" .. tostring(result.id) .. ":0:0:0:0:0:0:0"
end
local function usableTexture(texture)
    return type(texture) == "string" and texture ~= ""
end
local function getItemTexture(value)
    if not value or not GetItemInfo then return nil end
    -- Tortoise WoW's 1.12 client returns the texture path in slot 9;
    -- slot 10 is a numeric field and paints Texture widgets solid red.
    local name, link, quality, minimum, itemType, subType, stack, equip, texture = GetItemInfo(value)
    if usableTexture(texture) then return texture end
    return nil
end
local function getActualItemIcon(result)
    if not result or result.kind ~= "item" then return nil end
    local texture
    if GetItemIcon then texture = GetItemIcon(tonumber(result.id) or result.id) end
    if usableTexture(texture) then return texture end
    texture = getItemTexture(result.link)
    if not texture then texture = getItemTexture(getItemReference(result)) end
    if not texture then texture = getItemTexture(tonumber(result.id) or result.id) end
    if not texture then texture = getItemTexture(result.name) end
    return texture
end
local function getResultIcon(result)
    return getActualItemIcon(result) or KIND_ICONS[result and result.kind] or "Interface\\Icons\\INV_Misc_Book_09"
end
local ITEM_RARITIES = {
    ["ff9d9d9d"] = { "POOR", 0.62, 0.62, 0.62 },
    ["ffffffff"] = { "COMMON", 1.00, 1.00, 1.00 },
    ["ff1eff00"] = { "UNCOMMON", 0.12, 1.00, 0.00 },
    ["ff0070dd"] = { "RARE", 0.00, 0.44, 0.87 },
    ["ffa335ee"] = { "EPIC", 0.64, 0.21, 0.93 },
    ["ffff8000"] = { "LEGENDARY", 1.00, 0.50, 0.00 },
}
local function getItemRarity(result)
    if not result or result.kind ~= "item" or not result.link then return nil end
    local _, _, code = string.find(string.lower(result.link), "|c(%x%x%x%x%x%x%x%x)")
    return code and ITEM_RARITIES[code] or nil
end

-- Name colour + icon frame tint for a result (item rarity when known).
local function paintResultIdentity(nameText, icon, result)
    local rarity = getItemRarity(result)
    if rarity then
        nameText:SetTextColor(rarity[2], rarity[3], rarity[4])
        icon:SetBorderColor(rarity[2] * 0.75, rarity[3] * 0.75, rarity[4] * 0.75, 1)
    else
        Theme.SetTextColor(nameText, COLORS.text)
        icon:SetBorderColor(0, 0, 0, 0.9)
    end
    return rarity
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

local frame = CreateFrame("Frame", "TortoiseGMManagerLookupResultsFrame", UIParent)
frame:SetWidth(RESULT_WIDTH); frame:SetHeight(RESULT_HEIGHT); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true)
frame:EnableMouse(true); frame:EnableMouseWheel(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end); frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
Theme.Window(frame, { title = "Lookup Results", subtitle = "Server lookup · pick a result to act on it", icon = "Interface\\Icons\\INV_Misc_Spyglass_03", headerHeight = HEADER_HEIGHT })
frame:Hide(); TortoiseGMManager.lookupResultsFrame = frame
if TortoiseGMManager.frame then frame:SetPoint("TOPLEFT", TortoiseGMManager.frame, "TOPRIGHT", 10, 0) else frame:SetPoint("CENTER", UIParent, "CENTER", 280, 0) end
if UISpecialFrames then table.insert(UISpecialFrames, "TortoiseGMManagerLookupResultsFrame") end

frame.closeButton:SetScript("OnClick", function() TortoiseGMManager.DismissLookupResults(); frame:Hide() end)

-- Context chip: which lookup produced these results and where they go.
local contextBox = CreateFrame("Frame", nil, frame)
contextBox:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, CONTEXT_TOP)
contextBox:SetWidth(CONTENT_WIDTH); contextBox:SetHeight(24)
Theme.Backdrop(contextBox, COLORS.inset, COLORS.border)
local contextPrefix = Theme.Text(contextBox, 13, COLORS.goldDim, { code = true })
contextPrefix:SetPoint("LEFT", contextBox, "LEFT", 9, 0)
contextPrefix:SetText(">")
local context = Theme.Text(contextBox, 12, COLORS.code, { code = true })
context:SetPoint("LEFT", contextBox, "LEFT", 22, 0)
context:SetWidth(CONTENT_WIDTH - 32); context:SetHeight(14)

---------------------------------------------------------------------------
-- Result list
---------------------------------------------------------------------------

local countText = Theme.Text(frame, 10, COLORS.muted)
countText:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 1, LIST_HEADER_TOP - 4)
countText:SetWidth(200); countText:SetHeight(12)

local nextButton = Theme.IconButton(frame, 20, ">", "secondary")
nextButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, LIST_HEADER_TOP)
local pageText = Theme.Text(frame, 10, COLORS.muted, { justify = "CENTER" })
pageText:SetPoint("RIGHT", nextButton, "LEFT", -4, 0); pageText:SetWidth(54)
local prevButton = Theme.IconButton(frame, 20, "<", "secondary")
prevButton:SetPoint("RIGHT", pageText, "LEFT", -4, 0)

local emptyState = CreateFrame("Frame", nil, frame)
emptyState:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, ROWS_TOP)
emptyState:SetWidth(CONTENT_WIDTH); emptyState:SetHeight(ROWS_BLOCK)
local emptyTitle = Theme.Text(emptyState, 12, COLORS.text, { justify = "CENTER" })
emptyTitle:SetPoint("CENTER", emptyState, "CENTER", 0, 10); emptyTitle:SetWidth(CONTENT_WIDTH - 40)
local emptyDetail = Theme.Text(emptyState, 10, COLORS.muted, { justify = "CENTER" })
emptyDetail:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -6); emptyDetail:SetWidth(CONTENT_WIDTH - 60)
emptyState:Hide()

local function paintRow(row)
    if row.selected then Theme.Paint(row, { 0.150, 0.125, 0.070, 0.98 }, COLORS.borderFocus)
    elseif row.hovered then Theme.Paint(row, COLORS.surfaceHover, COLORS.borderHover)
    else Theme.Paint(row, COLORS.surface, COLORS.border) end
    if row.selected then Theme.SetTextColor(row.use, COLORS.gold) else Theme.SetTextColor(row.use, COLORS.faint) end
end

TortoiseGMManager.lookupResultRows = {}
local rowIndex
for rowIndex = 1, RESULTS_PER_PAGE do
    local row = CreateFrame("Button", nil, frame); row:SetWidth(CONTENT_WIDTH); row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, ROWS_TOP - ((rowIndex - 1) * (ROW_HEIGHT + ROW_GAP)))
    Theme.Card(row)
    row.icon = Theme.Icon(row, 24); row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
    row.name = Theme.Text(row, 12, COLORS.text); row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 40, -5); row.name:SetWidth(330); row.name:SetHeight(14)
    row.meta = Theme.Text(row, 9, COLORS.muted); row.meta:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1); row.meta:SetWidth(330); row.meta:SetHeight(11)
    row.use = Theme.Text(row, 13, COLORS.faint, { justify = "RIGHT" }); row.use:SetPoint("RIGHT", row, "RIGHT", -11, 0); row.use:SetText(">")
    row:SetScript("OnClick", function()
        if not this.result then return end
        TortoiseGMManager.selectedLookupResult = this.result
        TortoiseGMManager.lookupActionValues = copy(TortoiseGMManager.structuredValues)
        TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.RefreshLookupResults(true)
    end)
    row:SetScript("OnEnter", function()
        this.hovered = true; paintRow(this)
        if not this.result then return end
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        local reference = getItemReference(this.result)
        if reference then
            GameTooltip:SetHyperlink(reference)
            this.icon:SetTexture(getResultIcon(this.result))
            GameTooltip:AddLine("Item ID: " .. tostring(this.result.id), 0.62, 0.60, 0.56)
        else
            GameTooltip:SetText(this.result.name or tostring(this.result.id))
            GameTooltip:AddLine("ID: " .. tostring(this.result.id) .. "  Type: " .. tostring(this.result.kind), 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() this.hovered = false; paintRow(this); GameTooltip:Hide() end)
    table.insert(TortoiseGMManager.lookupResultRows, row)
end

---------------------------------------------------------------------------
-- Selected result: identity, modifiers, preview, action
---------------------------------------------------------------------------

local detailDivider = Theme.Divider(frame)
detailDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, DETAIL_TOP + 9)
detailDivider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, DETAIL_TOP + 9)

local selectedIcon = Theme.Icon(frame, 32)
selectedIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, DETAIL_TOP)
local selectedText = Theme.Text(frame, 13, COLORS.gold)
selectedText:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 42, DETAIL_TOP - 2)
selectedText:SetWidth(CONTENT_WIDTH - 42); selectedText:SetHeight(16)
local selectedMeta = Theme.Text(frame, 10, COLORS.muted)
selectedMeta:SetPoint("TOPLEFT", selectedText, "BOTTOMLEFT", 0, -2)
selectedMeta:SetWidth(CONTENT_WIDTH - 42); selectedMeta:SetHeight(12)

local controls = {}
local function changed(control)
    if control.updating or not control.argument then return end
    TortoiseGMManager.lookupActionValues = TortoiseGMManager.lookupActionValues or {}
    TortoiseGMManager.lookupActionValues[control.argument.key] = control.edit:GetText()
    TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.RefreshLookupResults(false)
end
for rowIndex = 1, 3 do
    local control = {}
    local top = DETAIL_TOP - 44 - ((rowIndex - 1) * 30)
    control.label = Theme.Caption(frame, "")
    control.label:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 2, top - 7)
    control.label:SetWidth(112); control.label:SetHeight(12)
    control.minus = Theme.Button(frame, "-", "secondary", 23, 24, 13)
    control.minus:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 118, top)
    control.edit = Theme.Input(frame, nil, 200, 24, { justify = "CENTER" })
    control.edit:SetPoint("LEFT", control.minus, "RIGHT", -1, 0)
    control.edit:SetMaxLetters(80)
    control.plus = Theme.Button(frame, "+", "secondary", 23, 24, 13)
    control.plus:SetPoint("LEFT", control.edit, "RIGHT", -1, 0)
    control.edit:SetScript("OnTextChanged", function() changed(control) end)
    control.edit:SetScript("OnEnterPressed", function() this:ClearFocus(); TortoiseGMManager.ActivateLookupAction() end)
    control.minus:SetScript("OnClick", function()
        local a = control.argument; if not a then return end
        local value = a.type == "toggle" and TortoiseGMManager.CycleToggle(a, control.edit:GetText(), -1) or TortoiseGMManager.AdjustNumber(a, control.edit:GetText(), -1)
        control.edit:SetText(tostring(value))
    end)
    control.plus:SetScript("OnClick", function()
        local a = control.argument; if not a then return end
        local value = a.type == "toggle" and TortoiseGMManager.CycleToggle(a, control.edit:GetText(), 1) or TortoiseGMManager.AdjustNumber(a, control.edit:GetText(), 1)
        control.edit:SetText(tostring(value))
    end)
    controls[rowIndex] = control
end

local previewLabel = Theme.Caption(frame, "PREVIEW")
previewLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + 2, 76)
local preview = Theme.Input(frame, nil, CONTENT_WIDTH, 26, { code = true, prefix = ">", placeholder = "Select a result to build the command" })
preview:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, 46)
preview:EnableKeyboard(false)
Theme.WatchInput(preview)
local validationDot = Theme.Dot(frame, 6)
validationDot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + 2, 23)
local validation = Theme.Text(frame, 10, COLORS.muted)
validation:SetPoint("LEFT", validationDot, "RIGHT", 7, 0)
validation:SetWidth(CONTENT_WIDTH - 180); validation:SetHeight(24)
local actionButton = Theme.Button(frame, "", "primary", 160, 28, 11)
actionButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, 12)

local function setValidation(message, color)
    validation:SetText(message or "")
    Theme.SetTextColor(validation, color or COLORS.muted)
    if message and message ~= "" then Theme.SetDotColor(validationDot, color or COLORS.muted); validationDot:Show() else validationDot:Hide() end
end

local currentDescriptor
function TortoiseGMManager.ActivateLookupAction()
    if not currentDescriptor or not currentDescriptor.valid then return end
    if currentDescriptor.kind == "load" then
        if TortoiseGMManager.LoadCommand then TortoiseGMManager.LoadCommand(currentDescriptor.command, currentDescriptor.entry, "Loaded from lookup.", currentDescriptor.values) end
        TortoiseGMManager.SetStatus("Command loaded in the main composer.", "info"); return
    end
    if currentDescriptor.kind ~= "action" then return end
    local command = currentDescriptor.command
    TortoiseGMManager.Execute(command)
    TortoiseGMManager.RefreshLookupResults(false)
end
actionButton:SetScript("OnClick", function() TortoiseGMManager.ActivateLookupAction() end)

-- Label for a valid action; shows CONFIRM while the guard is armed.
local function paintActionLabel()
    if not currentDescriptor or currentDescriptor.kind ~= "action" or not currentDescriptor.valid then return end
    local armed = TortoiseGMManager.pendingCommand == currentDescriptor.command and TortoiseGMManager.pendingUntil and GetTime() <= TortoiseGMManager.pendingUntil
    local label = (armed and "CONFIRM " or "") .. currentDescriptor.label
    if actionButton:GetText() ~= label then actionButton:SetText(label) end
end

local function renderAction(focusFirst)
    local result = TortoiseGMManager.selectedLookupResult
    currentDescriptor = TortoiseGMManager.GetLookupActionDescriptor(result, TortoiseGMManager.lookupActionValues)
    local i
    for i = 1, 3 do
        local control = controls[i]; local argument = currentDescriptor.arguments[i]; control.argument = argument
        if argument then
            control.label:SetText(string.upper(argument.label or "")); control.updating = true; control.edit:SetText(tostring(currentDescriptor.values[argument.key] or "")); control.updating = false
            if argument.type == "number" then control.minus:SetText("-"); control.plus:SetText("+"); control.minus:Show(); control.plus:Show()
            elseif argument.type == "toggle" then control.minus:SetText("<"); control.plus:SetText(">"); control.minus:Show(); control.plus:Show(); control.edit:EnableKeyboard(false)
            else control.minus:Hide(); control.plus:Hide() end
            if argument.type ~= "toggle" then control.edit:EnableKeyboard(true) end
            control.label:Show(); control.edit:Show()
        else control.label:Hide(); control.minus:Hide(); control.edit:Hide(); control.plus:Hide() end
    end
    actionButton:SetVariant(currentDescriptor.dangerous and "danger" or "primary")
    if not result then
        selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); selectedIcon:SetAlpha(0.5); selectedIcon:SetBorderColor(0, 0, 0, 0.9)
        selectedText:SetText("No result selected"); Theme.SetTextColor(selectedText, COLORS.muted)
        selectedMeta:SetText("Select a result to see details and available actions.")
        preview:SetText(""); setValidation(""); actionButton:SetText("CHOOSE RESULT"); actionButton:Disable(); return
    end
    selectedIcon:SetTexture(getResultIcon(result)); selectedIcon:SetAlpha(1)
    selectedText:SetText(result.name or tostring(result.id))
    local rarity = paintResultIdentity(selectedText, selectedIcon, result)
    local kindLabel = rarity and (rarity[1] .. " ITEM") or string.upper(result.kind or "result")
    local source = currentDescriptor.entry and currentDescriptor.entry.label
    selectedMeta:SetText(kindLabel .. "   #" .. tostring(result.id) .. (source and ("   " .. Theme.Hex(COLORS.faint) .. "Action:|r " .. source) or ""))
    if currentDescriptor.kind == "information" then
        preview:SetText(""); setValidation("Informational result - no source action was declared.", COLORS.muted); actionButton:SetText("ID " .. tostring(result.id)); actionButton:Disable(); return
    end
    preview:SetText(currentDescriptor.command or "")
    if currentDescriptor.kind == "load" then setValidation("This action cannot execute safely here.", COLORS.muted); actionButton:SetText("LOAD COMMAND"); actionButton:Enable(); return end
    if currentDescriptor.valid then
        if currentDescriptor.dangerous then setValidation("Requires two identical confirmations.", COLORS.orange) else setValidation("Ready.", COLORS.green) end
        paintActionLabel(); actionButton:Enable()
    else setValidation(currentDescriptor.message or "Invalid value.", COLORS.red); actionButton:SetText(currentDescriptor.label); actionButton:Disable() end
    if focusFirst and currentDescriptor.arguments[1] and currentDescriptor.arguments[1].required then controls[1].edit:SetFocus(); controls[1].edit:HighlightText() end
end

local function refreshEmptyState(count, session)
    if count > 0 then emptyState:Hide(); return end
    local state = session and session.state
    local query = session and session.query and session.query ~= "" and ("\"" .. session.query .. "\"") or "this lookup"
    if state == "searching" then
        emptyTitle:SetText("Searching the server...")
        emptyDetail:SetText("Results appear here as the server answers.")
    elseif state == "timedout" then
        emptyTitle:SetText("No answer from the server")
        emptyDetail:SetText("The lookup for " .. query .. " timed out. Check your GM access and try again.")
    elseif state == "noresults" then
        emptyTitle:SetText("No results for " .. query)
        emptyDetail:SetText("Try a shorter or partial name.")
    else
        emptyTitle:SetText("No lookup yet")
        emptyDetail:SetText("Search from a lookup-capable action to see results here.")
    end
    emptyState:Show()
end

TortoiseGMManager.lookupResultsPage = 1
function TortoiseGMManager.RefreshLookupResults(focusFirst)
    local results = TortoiseGMManager.GetLookupResults(); local count = table.getn(results); local pages = math.ceil(count / RESULTS_PER_PAGE); if pages < 1 then pages = 1 end
    if TortoiseGMManager.lookupResultsPage > pages then TortoiseGMManager.lookupResultsPage = pages end; if TortoiseGMManager.lookupResultsPage < 1 then TortoiseGMManager.lookupResultsPage = 1 end
    local session = TortoiseGMManager.pendingLookup or TortoiseGMManager.lastLookupSession; if not session and count > 0 then session = results[1].context end
    if session then
        local value = session.lookupCommand or "lookup"
        if session.query and session.query ~= "" then value = value .. "  '" .. session.query .. "'" end
        if session.sourceEntry and session.sourceEntry.label then value = value .. "  " .. Theme.Hex(COLORS.faint) .. "->|r  " .. Theme.Hex(COLORS.text) .. session.sourceEntry.label .. "|r" end
        context:SetText(value)
    else context:SetText("Lookup results") end
    local start = ((TortoiseGMManager.lookupResultsPage - 1) * RESULTS_PER_PAGE) + 1
    for rowIndex = 1, RESULTS_PER_PAGE do
        local row = TortoiseGMManager.lookupResultRows[rowIndex]; local result = results[start + rowIndex - 1]
        if result then
            row.result = result; row.icon:SetTexture(getResultIcon(result)); row.name:SetText(result.name or tostring(result.id))
            local rarity = paintResultIdentity(row.name, row.icon, result)
            if rarity then row.meta:SetText(rarity[1] .. " ITEM   #" .. tostring(result.id))
            else row.meta:SetText(string.upper(result.kind or "result") .. "   #" .. tostring(result.id)) end
            row.selected = result == TortoiseGMManager.selectedLookupResult; paintRow(row); row:Show()
        else row.result = nil; row.selected = false; row:Hide() end
    end
    pageText:SetText(tostring(TortoiseGMManager.lookupResultsPage) .. " / " .. tostring(pages))
    if count == 0 and session and session.state == "searching" then countText:SetText("Searching...")
    else countText:SetText(count == 0 and "No results" or tostring(count) .. (count == 1 and " result" or " results")) end
    if TortoiseGMManager.lookupResultsPage <= 1 then prevButton:Disable() else prevButton:Enable() end; if TortoiseGMManager.lookupResultsPage >= pages then nextButton:Disable() else nextButton:Enable() end
    refreshEmptyState(count, session)
    renderAction(focusFirst)
end
prevButton:SetScript("OnClick", function() if TortoiseGMManager.lookupResultsPage > 1 then TortoiseGMManager.lookupResultsPage = TortoiseGMManager.lookupResultsPage - 1; TortoiseGMManager.RefreshLookupResults(false) end end)
nextButton:SetScript("OnClick", function() local pages = math.ceil(table.getn(TortoiseGMManager.GetLookupResults()) / RESULTS_PER_PAGE); if TortoiseGMManager.lookupResultsPage < pages then TortoiseGMManager.lookupResultsPage = TortoiseGMManager.lookupResultsPage + 1; TortoiseGMManager.RefreshLookupResults(false) end end)
frame:SetScript("OnMouseWheel", function() if (arg1 or 0) > 0 then prevButton:GetScript("OnClick")() else nextButton:GetScript("OnClick")() end end)

local iconRetryElapsed, labelElapsed = 0, 0
frame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0
    -- Keep the CONFIRM label honest once the 5 second window expires.
    labelElapsed = labelElapsed + elapsed
    if labelElapsed >= 0.2 then labelElapsed = 0; paintActionLabel() end
    iconRetryElapsed = iconRetryElapsed + elapsed
    if iconRetryElapsed < 0.5 then return end
    iconRetryElapsed = 0
    local i
    for i = 1, table.getn(TortoiseGMManager.lookupResultRows) do
        local row = TortoiseGMManager.lookupResultRows[i]
        local texture = getActualItemIcon(row.result)
        if texture then row.icon:SetTexture(texture) end
    end
end)
function TortoiseGMManager.ShowLookupResults() TortoiseGMManager.RefreshLookupResults(false); frame:Show() end
function TortoiseGMManager.HideLookupResults(dismiss) if dismiss then TortoiseGMManager.DismissLookupResults() end; frame:Hide() end
TortoiseGMManager.OnLookupStarted = function() TortoiseGMManager.lookupResultsPage = 1; TortoiseGMManager.selectedLookupResult = nil; TortoiseGMManager.lookupActionValues = nil; TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.RefreshLookupResults(false); frame:Show() end
TortoiseGMManager.OnLookupResultsChanged = function() TortoiseGMManager.RefreshLookupResults(false) end
TortoiseGMManager.OnLookupEnded = function() TortoiseGMManager.RefreshLookupResults(false); if not TortoiseGMManager.lookupResultsDismissed then frame:Show() end end
