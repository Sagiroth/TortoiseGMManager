TortoiseGMManager = TortoiseGMManager or {}

local RESULTS_PER_PAGE = 6
local RESULT_WIDTH = 438
local RESULT_HEIGHT = 296

local COLORS = {
    gold = { 0.95, 0.72, 0.28 },
    text = { 0.92, 0.90, 0.84 },
    muted = { 0.62, 0.60, 0.56 },
    blue = { 0.42, 0.76, 1.00 },
}

local KIND_ICONS = {
    item = "Interface\\Icons\\INV_Misc_Bag_10",
    spell = "Interface\\Icons\\Spell_Arcane_Arcane01",
    quest = "Interface\\Icons\\INV_Misc_Note_01",
    creature = "Interface\\Icons\\Ability_Hunter_BeastCall",
    gameobject = "Interface\\Icons\\INV_Misc_Gear_01",
    skill = "Interface\\Icons\\INV_Misc_Book_09",
    faction = "Interface\\Icons\\Spell_Holy_SealOfMight",
    itemset = "Interface\\Icons\\INV_Chest_Chain_05",
    event = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    guild = "Interface\\Icons\\INV_Banner_03",
    player = "Interface\\Icons\\INV_Misc_Head_Human_01",
    account = "Interface\\Icons\\INV_Misc_Key_03",
}

local function setFontColor(fontString, color)
    if fontString and color then
        fontString:SetTextColor(color[1], color[2], color[3])
    end
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
    frame:SetBackdropColor(0.022, 0.030, 0.044, alpha or 0.97)
    frame:SetBackdropBorderColor(0.48, 0.36, 0.15, borderAlpha or 0.92)
end

local frame = CreateFrame("Frame", "TortoiseGMManagerLookupResultsFrame", UIParent)
frame:SetWidth(RESULT_WIDTH)
frame:SetHeight(RESULT_HEIGHT)
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
applyBackdrop(frame, 0.98, 1.0)
frame:Hide()
TortoiseGMManager.lookupResultsFrame = frame

if TortoiseGMManager.frame then
    frame:SetPoint("TOPLEFT", TortoiseGMManager.frame, "TOPRIGHT", 8, -8)
else
    frame:SetPoint("CENTER", UIParent, "CENTER", 280, 0)
end

if UISpecialFrames then table.insert(UISpecialFrames, "TortoiseGMManagerLookupResultsFrame") end

local headerIcon = frame:CreateTexture(nil, "ARTWORK")
headerIcon:SetWidth(22); headerIcon:SetHeight(22)
headerIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 13, -11)
headerIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("LEFT", headerIcon, "RIGHT", 7, 1)
title:SetText("Lookup Results")
setFontColor(title, COLORS.gold)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)

local contextText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
contextText:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -39)
contextText:SetWidth(402); contextText:SetHeight(14); contextText:SetJustifyH("LEFT")
setFontColor(contextText, COLORS.muted)

local divider = frame:CreateTexture(nil, "ARTWORK")
divider:SetTexture(0.48, 0.36, 0.15, 0.65)
divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -58)
divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -11, -58)
divider:SetHeight(1)

TortoiseGMManager.lookupResultRows = {}
local rowIndex
for rowIndex = 1, RESULTS_PER_PAGE do
    local row = CreateFrame("Button", nil, frame)
    row:SetWidth(410); row:SetHeight(30)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -66 - ((rowIndex - 1) * 33))
    applyBackdrop(row, 0.55, 0.42)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(20); row.icon:SetHeight(20)
    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 7, 4)
    row.name:SetWidth(284); row.name:SetHeight(13); row.name:SetJustifyH("LEFT")
    setFontColor(row.name, COLORS.text)

    row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.meta:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
    row.meta:SetWidth(284); row.meta:SetHeight(11); row.meta:SetJustifyH("LEFT")
    setFontColor(row.meta, COLORS.muted)

    row.use = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.use:SetPoint("RIGHT", row, "RIGHT", -9, 0)
    row.use:SetText("USE >")
    setFontColor(row.use, COLORS.gold)

    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    row:SetScript("OnClick", function()
        local result = this.result
        if not result then return end
        local command = TortoiseGMManager.GetLookupResultCommand(result)
        if not command then
            TortoiseGMManager.SetStatus("This result has no default action. Its ID is " .. tostring(result.id) .. ".", "info")
            return
        end
        local pending = TortoiseGMManager.pendingLookup
        local sourceEntry = pending and pending.sourceEntry or nil
        local label = result.name .. "  (#" .. tostring(result.id) .. ")"
        TortoiseGMManager.LoadCommand(command, sourceEntry, label .. " loaded from lookup. Review, then RUN.")
        frame:Hide()
    end)

    row:SetScript("OnEnter", function()
        if this.result then
            GameTooltip:SetOwner(this, "ANCHOR_LEFT")
            GameTooltip:SetText(this.result.name or tostring(this.result.id))
            GameTooltip:AddLine("ID: " .. tostring(this.result.id) .. "  Type: " .. tostring(this.result.kind), 1, 1, 1)
            local command = TortoiseGMManager.GetLookupResultCommand(this.result)
            if command then
                GameTooltip:AddLine("Click loads: " .. command, 0.95, 0.72, 0.28, true)
                GameTooltip:AddLine("Nothing is executed until you press RUN.", 0.65, 0.85, 1.0, true)
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(TortoiseGMManager.lookupResultRows, row)
end

local prevButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
prevButton:SetWidth(58); prevButton:SetHeight(21)
prevButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 12)
prevButton:SetText("< Prev")

local pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pageText:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
pageText:SetWidth(76); pageText:SetJustifyH("CENTER")
pageText:SetText("1 / 1")
setFontColor(pageText, COLORS.muted)

local nextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
nextButton:SetWidth(58); nextButton:SetHeight(21)
nextButton:SetPoint("LEFT", pageText, "RIGHT", 8, 0)
nextButton:SetText("Next >")

local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
countText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 17)
countText:SetWidth(150); countText:SetJustifyH("RIGHT")
setFontColor(countText, COLORS.muted)

TortoiseGMManager.lookupResultsPage = 1

function TortoiseGMManager.RefreshLookupResults()
    local results = TortoiseGMManager.GetLookupResults()
    local count = table.getn(results)
    local pageCount = math.ceil(count / RESULTS_PER_PAGE)
    if pageCount < 1 then pageCount = 1 end
    if TortoiseGMManager.lookupResultsPage > pageCount then TortoiseGMManager.lookupResultsPage = pageCount end
    if TortoiseGMManager.lookupResultsPage < 1 then TortoiseGMManager.lookupResultsPage = 1 end

    local pending = TortoiseGMManager.pendingLookup
    if pending then
        local context = pending.lookupCommand or "lookup"
        if pending.query and pending.query ~= "" then context = context .. "  '" .. pending.query .. "'" end
        if pending.sourceEntry and pending.sourceEntry.label then context = context .. "  ->  " .. pending.sourceEntry.label end
        contextText:SetText(context)
    else
        contextText:SetText("Last captured lookup")
    end

    local startIndex = ((TortoiseGMManager.lookupResultsPage - 1) * RESULTS_PER_PAGE) + 1
    for rowIndex = 1, RESULTS_PER_PAGE do
        local row = TortoiseGMManager.lookupResultRows[rowIndex]
        local result = results[startIndex + rowIndex - 1]
        if result then
            row.result = result
            row.icon:SetTexture(KIND_ICONS[result.kind] or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(result.name or tostring(result.id))
            row.meta:SetText(string.upper(result.kind or "result") .. "  #" .. tostring(result.id))
            row:Show()
        else
            row.result = nil
            row:Hide()
        end
    end

    pageText:SetText(tostring(TortoiseGMManager.lookupResultsPage) .. " / " .. tostring(pageCount))
    countText:SetText(tostring(count) .. (count == 1 and " result" or " results"))
    if TortoiseGMManager.lookupResultsPage <= 1 then prevButton:Disable() else prevButton:Enable() end
    if TortoiseGMManager.lookupResultsPage >= pageCount then nextButton:Disable() else nextButton:Enable() end
end

prevButton:SetScript("OnClick", function()
    if TortoiseGMManager.lookupResultsPage > 1 then
        TortoiseGMManager.lookupResultsPage = TortoiseGMManager.lookupResultsPage - 1
        TortoiseGMManager.RefreshLookupResults()
    end
end)

nextButton:SetScript("OnClick", function()
    local count = table.getn(TortoiseGMManager.GetLookupResults())
    local pageCount = math.ceil(count / RESULTS_PER_PAGE)
    if pageCount < 1 then pageCount = 1 end
    if TortoiseGMManager.lookupResultsPage < pageCount then
        TortoiseGMManager.lookupResultsPage = TortoiseGMManager.lookupResultsPage + 1
        TortoiseGMManager.RefreshLookupResults()
    end
end)

function TortoiseGMManager.ShowLookupResults()
    TortoiseGMManager.RefreshLookupResults()
    frame:Show()
end

function TortoiseGMManager.HideLookupResults()
    frame:Hide()
end

TortoiseGMManager.OnLookupStarted = function()
    TortoiseGMManager.lookupResultsPage = 1
    TortoiseGMManager.RefreshLookupResults()
end

TortoiseGMManager.OnLookupResultsChanged = function()
    TortoiseGMManager.RefreshLookupResults()
end
