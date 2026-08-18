TortoiseGMManager = TortoiseGMManager or {}

local RESULTS_PER_PAGE = 6
local RESULT_WIDTH, RESULT_HEIGHT = 438, 520
local COLORS = { gold={0.95,0.72,0.28}, text={0.92,0.90,0.84}, muted={0.62,0.60,0.56}, red={1,0.35,0.3} }
local KIND_ICONS = {
    item="Interface\\Icons\\INV_Misc_Bag_10", spell="Interface\\Icons\\Spell_Arcane_Arcane01",
    quest="Interface\\Icons\\INV_Misc_Note_01", creature="Interface\\Icons\\Ability_Hunter_BeastCall",
    gameobject="Interface\\Icons\\INV_Misc_Gear_01", skill="Interface\\Icons\\INV_Misc_Book_09",
    faction="Interface\\Icons\\Spell_Holy_SealOfMight", itemset="Interface\\Icons\\INV_Chest_Chain_05",
    event="Interface\\Icons\\INV_Misc_PocketWatch_01", guild="Interface\\Icons\\INV_Banner_03",
    player="Interface\\Icons\\INV_Misc_Head_Human_01", account="Interface\\Icons\\INV_Misc_Key_03",
}

local function color(font, value) if font and value then font:SetTextColor(value[1],value[2],value[3]) end end
local function backdrop(frame, alpha, border)
    frame:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=11, insets={left=3,right=3,top=3,bottom=3} })
    frame:SetBackdropColor(0.022,0.030,0.044,alpha or 0.97); frame:SetBackdropBorderColor(0.48,0.36,0.15,border or 0.92)
end
local function copy(values) local result,k,v={},nil,nil; for k,v in pairs(values or {}) do result[k]=v end; return result end

local frame=CreateFrame("Frame","TortoiseGMManagerLookupResultsFrame",UIParent)
frame:SetWidth(RESULT_WIDTH); frame:SetHeight(RESULT_HEIGHT); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true)
frame:EnableMouse(true); frame:EnableMouseWheel(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart",function() this:StartMoving() end); frame:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
backdrop(frame,0.98,1); frame:Hide(); TortoiseGMManager.lookupResultsFrame=frame
if TortoiseGMManager.frame then frame:SetPoint("TOPLEFT",TortoiseGMManager.frame,"TOPRIGHT",8,-8) else frame:SetPoint("CENTER",UIParent,"CENTER",280,0) end
if UISpecialFrames then table.insert(UISpecialFrames,"TortoiseGMManagerLookupResultsFrame") end

local icon=frame:CreateTexture(nil,"ARTWORK"); icon:SetWidth(22); icon:SetHeight(22); icon:SetPoint("TOPLEFT",frame,"TOPLEFT",13,-11)
icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03"); icon:SetTexCoord(0.08,0.92,0.08,0.92)
local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("LEFT",icon,"RIGHT",7,1); title:SetText("Lookup Results"); color(title,COLORS.gold)
local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-3)
close:SetScript("OnClick",function() TortoiseGMManager.DismissLookupResults(); frame:Hide() end)
local context=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); context:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-39)
context:SetWidth(402); context:SetHeight(14); context:SetJustifyH("LEFT"); color(context,COLORS.muted)
local divider=frame:CreateTexture(nil,"ARTWORK"); divider:SetTexture(0.48,0.36,0.15,0.65)
divider:SetPoint("TOPLEFT",frame,"TOPLEFT",11,-58); divider:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-11,-58); divider:SetHeight(1)

TortoiseGMManager.lookupResultRows={}
local rowIndex
for rowIndex=1,RESULTS_PER_PAGE do
    local row=CreateFrame("Button",nil,frame); row:SetWidth(410); row:SetHeight(30)
    row:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-66-((rowIndex-1)*33)); backdrop(row,0.55,0.42)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetWidth(20); row.icon:SetHeight(20); row.icon:SetPoint("LEFT",row,"LEFT",6,0); row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    row.name=row:CreateFontString(nil,"OVERLAY","GameFontNormal"); row.name:SetPoint("LEFT",row.icon,"RIGHT",7,4); row.name:SetWidth(284); row.name:SetHeight(13); row.name:SetJustifyH("LEFT"); color(row.name,COLORS.text)
    row.meta=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); row.meta:SetPoint("TOPLEFT",row.name,"BOTTOMLEFT",0,-1); row.meta:SetWidth(284); row.meta:SetHeight(11); row.meta:SetJustifyH("LEFT"); color(row.meta,COLORS.muted)
    row.use=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); row.use:SetPoint("RIGHT",row,"RIGHT",-9,0); row.use:SetText(">"); color(row.use,COLORS.gold)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row:SetScript("OnClick",function()
        if not this.result then return end
        TortoiseGMManager.selectedLookupResult=this.result
        TortoiseGMManager.lookupActionValues=copy(TortoiseGMManager.structuredValues)
        TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.RefreshLookupResults(true)
    end)
    row:SetScript("OnEnter",function()
        if this.result then GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText(this.result.name or tostring(this.result.id)); GameTooltip:AddLine("ID: "..tostring(this.result.id).."  Type: "..tostring(this.result.kind),1,1,1); GameTooltip:Show() end
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    table.insert(TortoiseGMManager.lookupResultRows,row)
end

local prev=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); prev:SetWidth(58); prev:SetHeight(21); prev:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-267); prev:SetText("< Prev")
local pageText=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); pageText:SetPoint("LEFT",prev,"RIGHT",8,0); pageText:SetWidth(76); pageText:SetJustifyH("CENTER"); color(pageText,COLORS.muted)
local next=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); next:SetWidth(58); next:SetHeight(21); next:SetPoint("LEFT",pageText,"RIGHT",8,0); next:SetText("Next >")
local countText=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); countText:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-14,-271); countText:SetWidth(135); countText:SetJustifyH("RIGHT"); color(countText,COLORS.muted)
local actionDivider=frame:CreateTexture(nil,"ARTWORK"); actionDivider:SetTexture(0.48,0.36,0.15,0.65); actionDivider:SetPoint("TOPLEFT",frame,"TOPLEFT",11,-298); actionDivider:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-11,-298); actionDivider:SetHeight(1)
local selectedText=frame:CreateFontString(nil,"OVERLAY","GameFontNormal"); selectedText:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-309); selectedText:SetWidth(405); selectedText:SetJustifyH("LEFT"); color(selectedText,COLORS.gold)

local controls={}
local function changed(control)
    if control.updating or not control.argument then return end
    TortoiseGMManager.lookupActionValues=TortoiseGMManager.lookupActionValues or {}
    TortoiseGMManager.lookupActionValues[control.argument.key]=control.edit:GetText()
    TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.RefreshLookupResults(false)
end
for rowIndex=1,3 do
    local control={}
    control.label=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); control.label:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-333-((rowIndex-1)*34)); control.label:SetWidth(104); control.label:SetJustifyH("LEFT"); color(control.label,COLORS.text)
    control.minus=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); control.minus:SetWidth(25); control.minus:SetHeight(21); control.minus:SetPoint("LEFT",control.label,"RIGHT",2,0); control.minus:SetText("-")
    control.edit=CreateFrame("EditBox",nil,frame,"InputBoxTemplate"); control.edit:SetWidth(174); control.edit:SetHeight(21); control.edit:SetPoint("LEFT",control.minus,"RIGHT",5,0); control.edit:SetAutoFocus(false); control.edit:SetMaxLetters(80)
    control.plus=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); control.plus:SetWidth(25); control.plus:SetHeight(21); control.plus:SetPoint("LEFT",control.edit,"RIGHT",5,0); control.plus:SetText("+")
    control.edit:SetScript("OnTextChanged",function() changed(control) end)
    control.edit:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    control.edit:SetScript("OnEnterPressed",function() this:ClearFocus(); TortoiseGMManager.ActivateLookupAction() end)
    control.minus:SetScript("OnClick",function()
        local a=control.argument; if not a then return end
        local value=a.type=="toggle" and TortoiseGMManager.CycleToggle(a,control.edit:GetText(),-1) or TortoiseGMManager.AdjustNumber(a,control.edit:GetText(),-1)
        control.edit:SetText(tostring(value))
    end)
    control.plus:SetScript("OnClick",function()
        local a=control.argument; if not a then return end
        local value=a.type=="toggle" and TortoiseGMManager.CycleToggle(a,control.edit:GetText(),1) or TortoiseGMManager.AdjustNumber(a,control.edit:GetText(),1)
        control.edit:SetText(tostring(value))
    end)
    controls[rowIndex]=control
end

local previewLabel=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); previewLabel:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-438); previewLabel:SetText("Exact command"); color(previewLabel,COLORS.muted)
local preview=CreateFrame("EditBox",nil,frame,"InputBoxTemplate"); preview:SetWidth(394); preview:SetHeight(21); preview:SetPoint("TOPLEFT",frame,"TOPLEFT",19,-452); preview:SetAutoFocus(false); preview:EnableKeyboard(false); preview:SetTextColor(0.75,0.75,0.72)
local validation=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); validation:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-478); validation:SetWidth(275); validation:SetJustifyH("LEFT")
local actionButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); actionButton:SetWidth(128); actionButton:SetHeight(24); actionButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-14,12)

local currentDescriptor
function TortoiseGMManager.ActivateLookupAction()
    if not currentDescriptor or not currentDescriptor.valid then return end
    if currentDescriptor.kind=="load" then
        if TortoiseGMManager.LoadCommand then TortoiseGMManager.LoadCommand(currentDescriptor.command,currentDescriptor.entry,"Loaded from lookup.",currentDescriptor.values) end
        TortoiseGMManager.SetStatus("Command loaded in the main composer.","info"); return
    end
    if currentDescriptor.kind~="action" then return end
    local command=currentDescriptor.command
    TortoiseGMManager.Execute(command)
    TortoiseGMManager.RefreshLookupResults(false)
end
actionButton:SetScript("OnClick",function() TortoiseGMManager.ActivateLookupAction() end)

local function renderAction(focusFirst)
    local result=TortoiseGMManager.selectedLookupResult
    currentDescriptor=TortoiseGMManager.GetLookupActionDescriptor(result,TortoiseGMManager.lookupActionValues)
    local i
    for i=1,3 do
        local control=controls[i]; local argument=currentDescriptor.arguments[i]; control.argument=argument
        if argument then
            control.label:SetText(argument.label); control.updating=true; control.edit:SetText(tostring(currentDescriptor.values[argument.key] or "")); control.updating=false
            if argument.type=="number" then control.minus:Show(); control.plus:Show()
            elseif argument.type=="toggle" then control.minus:Show(); control.plus:Show(); control.edit:EnableKeyboard(false)
            else control.minus:Hide(); control.plus:Hide() end
            if argument.type~="toggle" then control.edit:EnableKeyboard(true) end
            control.label:Show(); control.edit:Show()
        else control.label:Hide(); control.minus:Hide(); control.edit:Hide(); control.plus:Hide() end
    end
    if not result then
        selectedText:SetText("Select a result to see details and available actions."); preview:SetText(""); validation:SetText(""); actionButton:SetText("CHOOSE RESULT"); actionButton:Disable(); return
    end
    selectedText:SetText((result.name or tostring(result.id)).."  (#"..tostring(result.id)..")")
    if currentDescriptor.kind=="information" then
        preview:SetText(""); validation:SetText("Informational result - no source action was declared."); color(validation,COLORS.muted); actionButton:SetText("ID "..tostring(result.id)); actionButton:Disable(); return
    end
    preview:SetText(currentDescriptor.command or "")
    if currentDescriptor.kind=="load" then validation:SetText("This action cannot execute safely here."); color(validation,COLORS.muted); actionButton:SetText("LOAD COMMAND"); actionButton:Enable(); return end
    if currentDescriptor.valid then
        validation:SetText(currentDescriptor.dangerous and "Requires two identical confirmations." or "Ready."); color(validation,COLORS.muted)
        local armed=TortoiseGMManager.pendingCommand==currentDescriptor.command and TortoiseGMManager.pendingUntil and GetTime()<=TortoiseGMManager.pendingUntil
        actionButton:SetText((armed and "CONFIRM " or "")..currentDescriptor.label); actionButton:Enable()
    else validation:SetText(currentDescriptor.message or "Invalid value."); color(validation,COLORS.red); actionButton:SetText(currentDescriptor.label); actionButton:Disable() end
    if focusFirst and currentDescriptor.arguments[1] and currentDescriptor.arguments[1].required then controls[1].edit:SetFocus(); controls[1].edit:HighlightText() end
end

TortoiseGMManager.lookupResultsPage=1
function TortoiseGMManager.RefreshLookupResults(focusFirst)
    local results=TortoiseGMManager.GetLookupResults(); local count=table.getn(results); local pages=math.ceil(count/RESULTS_PER_PAGE); if pages<1 then pages=1 end
    if TortoiseGMManager.lookupResultsPage>pages then TortoiseGMManager.lookupResultsPage=pages end; if TortoiseGMManager.lookupResultsPage<1 then TortoiseGMManager.lookupResultsPage=1 end
    local session=TortoiseGMManager.pendingLookup or TortoiseGMManager.lastLookupSession; if not session and count>0 then session=results[1].context end
    if session then local value=session.lookupCommand or "lookup"; if session.query and session.query~="" then value=value.."  '"..session.query.."'" end; if session.sourceEntry and session.sourceEntry.label then value=value.."  ->  "..session.sourceEntry.label end; context:SetText(value) else context:SetText("Lookup results") end
    local start=((TortoiseGMManager.lookupResultsPage-1)*RESULTS_PER_PAGE)+1
    for rowIndex=1,RESULTS_PER_PAGE do local row=TortoiseGMManager.lookupResultRows[rowIndex]; local result=results[start+rowIndex-1]
        if result then row.result=result; row.icon:SetTexture(KIND_ICONS[result.kind] or "Interface\\Icons\\INV_Misc_QuestionMark"); row.name:SetText(result.name or tostring(result.id)); row.meta:SetText(string.upper(result.kind or "result").."  #"..tostring(result.id)); if result==TortoiseGMManager.selectedLookupResult then row:LockHighlight() else row:UnlockHighlight() end; row:Show()
        else row.result=nil; row:UnlockHighlight(); row:Hide() end
    end
    pageText:SetText(tostring(TortoiseGMManager.lookupResultsPage).." / "..tostring(pages)); countText:SetText(count==0 and "No results" or tostring(count)..(count==1 and " result" or " results"))
    if TortoiseGMManager.lookupResultsPage<=1 then prev:Disable() else prev:Enable() end; if TortoiseGMManager.lookupResultsPage>=pages then next:Disable() else next:Enable() end
    renderAction(focusFirst)
end
prev:SetScript("OnClick",function() if TortoiseGMManager.lookupResultsPage>1 then TortoiseGMManager.lookupResultsPage=TortoiseGMManager.lookupResultsPage-1; TortoiseGMManager.RefreshLookupResults(false) end end)
next:SetScript("OnClick",function() local pages=math.ceil(table.getn(TortoiseGMManager.GetLookupResults())/RESULTS_PER_PAGE); if TortoiseGMManager.lookupResultsPage<pages then TortoiseGMManager.lookupResultsPage=TortoiseGMManager.lookupResultsPage+1; TortoiseGMManager.RefreshLookupResults(false) end end)
frame:SetScript("OnMouseWheel",function() if (arg1 or 0)>0 then prev:GetScript("OnClick")() else next:GetScript("OnClick")() end end)
function TortoiseGMManager.ShowLookupResults() TortoiseGMManager.RefreshLookupResults(false); frame:Show() end
function TortoiseGMManager.HideLookupResults(dismiss) if dismiss then TortoiseGMManager.DismissLookupResults() end; frame:Hide() end
TortoiseGMManager.OnLookupStarted=function() TortoiseGMManager.lookupResultsPage=1; TortoiseGMManager.selectedLookupResult=nil; TortoiseGMManager.lookupActionValues=nil; TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.RefreshLookupResults(false); frame:Show() end
TortoiseGMManager.OnLookupResultsChanged=function() TortoiseGMManager.RefreshLookupResults(false) end
TortoiseGMManager.OnLookupEnded=function() TortoiseGMManager.RefreshLookupResults(false); if not TortoiseGMManager.lookupResultsDismissed then frame:Show() end end
