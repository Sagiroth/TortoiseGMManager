TortoiseGMManager = TortoiseGMManager or {}

-- Shared visual language for every TortoiseGMManager window.
-- Flat dark surfaces, 1px borders, one gold accent and semantic colours for
-- lookup (blue), danger (red) and success (green). Only stock client textures
-- and fonts are used, so nothing is bundled with the addon.

local Theme = {}
TortoiseGMManager.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"
Theme.WHITE = WHITE
Theme.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
Theme.CODE_FONT = "Fonts\\ARIALN.TTF"
Theme.STAR_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

Theme.colors = {
    window = { 0.051, 0.055, 0.067, 0.97 },
    header = { 0.078, 0.078, 0.090, 1 },
    surface = { 0.082, 0.086, 0.102, 0.96 },
    surfaceHover = { 0.110, 0.112, 0.130, 0.98 },
    inset = { 0.027, 0.029, 0.037, 1 },
    border = { 0.180, 0.176, 0.165, 1 },
    borderHover = { 0.420, 0.340, 0.180, 1 },
    borderFocus = { 0.780, 0.580, 0.220, 1 },
    divider = { 1, 1, 1, 0.07 },

    text = { 0.930, 0.910, 0.860 },
    muted = { 0.600, 0.585, 0.550 },
    faint = { 0.400, 0.392, 0.370 },
    code = { 0.960, 0.780, 0.420 },
    goldDim = { 0.620, 0.470, 0.200 },

    gold = { 0.960, 0.740, 0.300 },
    blue = { 0.440, 0.730, 1.000 },
    green = { 0.400, 0.860, 0.500 },
    red = { 1.000, 0.380, 0.320 },
    orange = { 1.000, 0.640, 0.220 },
}
local C = Theme.colors

Theme.buttonVariants = {
    primary = { bg = { 0.800, 0.580, 0.200, 1 }, border = { 0.980, 0.780, 0.360, 1 }, text = { 0.090, 0.060, 0.020 }, hover = { 1, 0.95, 0.80, 0.20 }, shadow = false },
    secondary = { bg = { 0.118, 0.122, 0.145, 1 }, border = { 0.260, 0.250, 0.225, 1 }, text = C.text, hover = { 1, 1, 1, 0.07 }, shadow = true },
    ghost = { bg = { 0, 0, 0, 0 }, border = { 0, 0, 0, 0 }, text = C.muted, hover = { 1, 1, 1, 0.08 }, shadow = true },
    danger = { bg = { 0.520, 0.130, 0.110, 1 }, border = { 0.880, 0.320, 0.260, 1 }, text = { 1, 0.930, 0.910 }, hover = { 1, 0.65, 0.55, 0.16 }, shadow = true },
    info = { bg = { 0.090, 0.180, 0.290, 1 }, border = { 0.330, 0.560, 0.830, 1 }, text = { 0.870, 0.930, 1 }, hover = { 0.70, 0.85, 1, 0.14 }, shadow = true },
}
Theme.disabledButton = { bg = { 0.095, 0.097, 0.110, 1 }, border = { 0.170, 0.168, 0.160, 1 }, text = C.faint }

local BACKDROP = {
    bgFile = WHITE,
    edgeFile = WHITE,
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

function Theme.SetTextColor(fontString, color)
    if fontString and color then fontString:SetTextColor(color[1], color[2], color[3]) end
end

function Theme.Fill(texture, color, alpha)
    texture:SetTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end

function Theme.Backdrop(frame, background, border)
    frame:SetBackdrop(BACKDROP)
    Theme.Paint(frame, background or C.surface, border or C.border)
end

function Theme.Paint(frame, background, border)
    if background then frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1) end
    if border then frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1) end
end

function Theme.SetFont(fontString, size, code)
    fontString:SetFont(code and Theme.CODE_FONT or Theme.FONT, size or 11, "")
    fontString:SetShadowColor(0, 0, 0, 0.85)
    fontString:SetShadowOffset(1, -1)
end

-- Fonts are applied on top of a stock template so the string always has a
-- valid font, even if a locale ships a different font file.
function Theme.Text(parent, size, color, options)
    options = options or {}
    local fontString = parent:CreateFontString(nil, options.layer or "OVERLAY", options.template or "GameFontHighlightSmall")
    Theme.SetFont(fontString, size, options.code)
    Theme.SetTextColor(fontString, color or C.text)
    fontString:SetJustifyH(options.justify or "LEFT")
    return fontString
end

-- Small uppercase section label, e.g. "PREVIEW".
function Theme.Caption(parent, text)
    local caption = Theme.Text(parent, 9, C.muted)
    caption:SetText(text or "")
    return caption
end

function Theme.Divider(parent, layer)
    local line = parent:CreateTexture(nil, layer or "ARTWORK")
    Theme.Fill(line, C.divider)
    line:SetHeight(1)
    return line
end

-- Soft outer shadow drawn as four strips outside the frame edges.
function Theme.Shadow(frame, size)
    size = size or 5
    local function strip()
        local texture = frame:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture(WHITE)
        texture:SetVertexColor(0, 0, 0, 1)
        return texture
    end
    local top = strip(); top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0); top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0); top:SetHeight(size)
    local bottom = strip(); bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0); bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0); bottom:SetHeight(size)
    local left = strip(); left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0); left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0); left:SetWidth(size)
    local right = strip(); right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0); right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0); right:SetWidth(size)
    if top.SetGradientAlpha then
        top:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.45, 0, 0, 0, 0)
        bottom:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.45)
        left:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, 0.45)
        right:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.45, 0, 0, 0, 0)
    else
        top:SetAlpha(0.25); bottom:SetAlpha(0.25); left:SetAlpha(0.25); right:SetAlpha(0.25)
    end
end

-- Draggable top-level window with header band, title and close button.
function Theme.Window(frame, options)
    options = options or {}
    Theme.Backdrop(frame, C.window, { 0.230, 0.215, 0.180, 1 })
    Theme.Shadow(frame, 6)

    local headerHeight = options.headerHeight or 44
    local header = frame:CreateTexture(nil, "BACKGROUND")
    Theme.Fill(header, C.header)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    header:SetHeight(headerHeight - 1)

    -- Thin gold hairline across the very top gives the window its accent.
    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetTexture(WHITE)
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    if accent.SetGradientAlpha then
        accent:SetGradientAlpha("HORIZONTAL", C.gold[1], C.gold[2], C.gold[3], 0.95, C.gold[1], C.gold[2], C.gold[3], 0.10)
    else
        accent:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.7)
    end

    local headerLine = Theme.Divider(frame)
    headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -headerHeight)
    headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -headerHeight)

    -- Brand mark: a slightly larger icon with a two-line title block
    -- (name on top, muted meta line below), matching TortoiseBotsManager.
    local iconSize = options.subtitle and 30 or 26
    local icon = Theme.Icon(frame, iconSize)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -math.floor((headerHeight - iconSize) / 2) - 1)
    icon:SetTexture(options.icon or "Interface\\Icons\\INV_Misc_Gear_01")
    icon:SetBorderColor(C.goldDim[1], C.goldDim[2], C.goldDim[3], 1)

    local title = Theme.Text(frame, 14, C.gold)
    title:SetText(options.title or "")
    local subtitle
    if options.subtitle then
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 1)
        subtitle = Theme.Text(frame, 10, C.muted)
        subtitle:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 0)
        subtitle:SetText(options.subtitle)
    else
        title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    end

    local close = Theme.IconButton(frame, 22, "X")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -11, -math.floor((headerHeight - 22) / 2) - 1)
    close:SetScript("OnClick", function() this:GetParent():Hide() end)
    close:SetScript("OnEnter", function() Theme.SetTextColor(this.text, C.red) end)
    close:SetScript("OnLeave", function() Theme.PaintButton(this) end)

    frame.headerIcon, frame.headerTitle, frame.headerSubtitle, frame.closeButton = icon, title, subtitle, close
    return frame
end

-- Card: a raised surface for rows and panels.
function Theme.Card(frame, background, border)
    Theme.Backdrop(frame, background or C.surface, border or C.border)
    return frame
end

-- Icon with a crisp 1px dark frame. Returns the icon texture; the frame
-- texture is available as icon.border so it can be tinted (e.g. item rarity).
function Theme.Icon(parent, size, layer)
    local border = parent:CreateTexture(nil, layer or "ARTWORK")
    border:SetTexture(WHITE)
    border:SetVertexColor(0, 0, 0, 0.9)
    border:SetWidth(size); border:SetHeight(size)
    local icon = parent:CreateTexture(nil, layer or "ARTWORK")
    icon:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.border = border
    -- Callers anchor the icon itself; forward anchors to the frame texture.
    icon.SetPoint = function(self, point, relativeTo, relativePoint, x, y) self.border:SetPoint(point, relativeTo, relativePoint, x, y) end
    icon.ClearAllPoints = function(self) self.border:ClearAllPoints() end
    icon.SetBorderColor = function(self, r, g, b, a) self.border:SetVertexColor(r, g, b, a or 1) end
    local baseShow, baseHide = icon.Show, icon.Hide
    icon.Show = function(self) baseShow(self); self.border:Show() end
    icon.Hide = function(self) baseHide(self); self.border:Hide() end
    return icon
end

---------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------

function Theme.PaintButton(button)
    local style = button.tgmmEnabled and (Theme.buttonVariants[button.variant] or Theme.buttonVariants.secondary) or Theme.disabledButton
    Theme.Paint(button, style.bg, style.border)
    local textColor = style.text
    if button.tgmmEnabled and button.textColor then textColor = button.textColor end
    Theme.SetTextColor(button.text, textColor)
    if style.shadow == false then button.text:SetShadowOffset(0, 0) else button.text:SetShadowOffset(1, -1) end
    if button.icon then button.icon:SetAlpha(button.tgmmEnabled and 1 or 0.4) end
    local hover = style.hover or Theme.buttonVariants.secondary.hover
    button.highlight:SetTexture(hover[1], hover[2], hover[3], hover[4])
    button.highlight:SetAlpha(button.tgmmEnabled and 1 or 0)
end

-- Flat button. Variants: primary, secondary, ghost, danger, info.
-- Enable/Disable/SetText keep the stock Button API so callers stay unchanged.
function Theme.Button(parent, label, variant, width, height, fontSize)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width or 80)
    button:SetHeight(height or 22)
    button:SetBackdrop(BACKDROP)
    button.variant = variant or "secondary"
    button.tgmmEnabled = true

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

    button.text = Theme.Text(button, fontSize or 10, C.text, { justify = "CENTER" })
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText(label or "")

    local baseEnable, baseDisable = button.Enable, button.Disable
    button.Enable = function(self) baseEnable(self); self.tgmmEnabled = true; Theme.PaintButton(self) end
    button.Disable = function(self) baseDisable(self); self.tgmmEnabled = false; Theme.PaintButton(self) end
    button.SetText = function(self, value) self.text:SetText(value) end
    button.GetText = function(self) return self.text:GetText() end
    button.SetVariant = function(self, value)
        if self.variant ~= value then self.variant = value; Theme.PaintButton(self) end
    end
    button.SetLabelColor = function(self, color)
        self.textColor = color; Theme.PaintButton(self)
    end

    -- Tactile press: nudge the label down while the mouse is held.
    button:SetScript("OnMouseDown", function()
        if this.tgmmEnabled then this.text:SetPoint("CENTER", this, "CENTER", this.textOffsetX or 0, -1) end
    end)
    button:SetScript("OnMouseUp", function()
        this.text:SetPoint("CENTER", this, "CENTER", this.textOffsetX or 0, 0)
    end)

    Theme.PaintButton(button)
    return button
end

-- Square ghost button carrying a short glyph such as "?", "X", "<" or ">".
function Theme.IconButton(parent, size, glyph, variant)
    return Theme.Button(parent, glyph, variant or "ghost", size, size, 11)
end

-- Square ghost button carrying a texture instead of text.
function Theme.TextureButton(parent, size, texture, iconSize)
    local button = Theme.Button(parent, "", "ghost", size, size)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetWidth(iconSize or (size - 8)); button.icon:SetHeight(iconSize or (size - 8))
    button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    if texture then button.icon:SetTexture(texture) end
    return button
end

-- Size a button to its label with comfortable horizontal padding.
function Theme.FitButton(button, minimum, padding)
    local textWidth = button.text:GetStringWidth() or 0
    if textWidth < 4 then textWidth = string.len(button.text:GetText() or "") * 7 end
    local width = textWidth + ((padding or 14) * 2)
    if minimum and width < minimum then width = minimum end
    button:SetWidth(math.floor(width + 0.5))
end

---------------------------------------------------------------------------
-- Tabs
---------------------------------------------------------------------------

function Theme.Tab(parent, label, accent)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetHeight(26)
    tab.accent = accent or C.gold

    tab.background = tab:CreateTexture(nil, "BACKGROUND")
    tab.background:SetAllPoints(tab)
    tab.background:SetTexture(1, 1, 1, 0.045)
    tab.background:Hide()

    tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
    tab.highlight:SetAllPoints(tab)
    tab.highlight:SetTexture(1, 1, 1, 0.05)

    tab.underline = tab:CreateTexture(nil, "OVERLAY")
    tab.underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    tab.underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
    tab.underline:SetHeight(2)
    Theme.Fill(tab.underline, tab.accent)
    tab.underline:Hide()

    tab.text = Theme.Text(tab, 11, C.muted, { justify = "CENTER" })
    tab.text:SetPoint("CENTER", tab, "CENTER", 0, 1)
    tab.text:SetText(label or "")

    tab.SetSelected = function(self, selected)
        self.selected = selected
        if selected then
            Theme.SetTextColor(self.text, self.accent)
            self.background:Show(); self.underline:Show()
            if self.icon then self.icon:SetAlpha(1); self.icon:SetVertexColor(1, 1, 1) end
        else
            Theme.SetTextColor(self.text, C.muted)
            self.background:Hide(); self.underline:Hide()
            if self.icon then self.icon:SetAlpha(0.55); self.icon:SetVertexColor(0.75, 0.75, 0.75) end
        end
    end
    tab:SetScript("OnEnter", function() if not this.selected then Theme.SetTextColor(this.text, C.text) end end)
    tab:SetScript("OnLeave", function() this:SetSelected(this.selected) end)
    return tab
end

---------------------------------------------------------------------------
-- Inputs
---------------------------------------------------------------------------

function Theme.RefreshInput(edit)
    local focused = edit.tgmmFocused
    if focused then Theme.Paint(edit, C.inset, C.borderFocus)
    elseif edit.tgmmHover then Theme.Paint(edit, C.inset, C.borderHover)
    else Theme.Paint(edit, C.inset, C.border) end
    if edit.placeholder then
        local text = edit:GetText()
        if text == nil or text == "" then edit.placeholder:Show() else edit.placeholder:Hide() end
    end
    if edit.searchIcon then edit.searchIcon:SetAlpha(focused and 0.95 or 0.55) end
end

-- Flat text field. options: placeholder, search (adds a spyglass), code
-- (monospace-like command font), justify, fontSize.
function Theme.Input(parent, name, width, height, options)
    options = options or {}
    local edit = CreateFrame("EditBox", name, parent)
    edit:SetWidth(width or 120)
    edit:SetHeight(height or 24)
    edit:SetAutoFocus(false)
    edit:EnableMouse(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetFont(options.code and Theme.CODE_FONT or Theme.FONT, options.fontSize or (options.code and 13 or 11), "")
    edit:SetTextColor(options.code and C.code[1] or C.text[1], options.code and C.code[2] or C.text[2], options.code and C.code[3] or C.text[3])
    if edit.SetJustifyH and options.justify then edit:SetJustifyH(options.justify) end
    edit:SetBackdrop(BACKDROP)

    local left = options.search and 24 or (options.prefix and 22 or 7)
    edit:SetTextInsets(left, options.rightInset or 7, 0, 0)

    if options.search then
        edit.searchIcon = edit:CreateTexture(nil, "OVERLAY")
        edit.searchIcon:SetWidth(13); edit.searchIcon:SetHeight(13)
        edit.searchIcon:SetPoint("LEFT", edit, "LEFT", 7, 0)
        edit.searchIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")
        edit.searchIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    if options.prefix then
        edit.prefix = Theme.Text(edit, 13, C.goldDim, { code = true })
        edit.prefix:SetPoint("LEFT", edit, "LEFT", 9, 0)
        edit.prefix:SetText(options.prefix)
    end
    if options.placeholder then
        edit.placeholder = Theme.Text(edit, options.code and 12 or 11, C.faint, { code = options.code })
        edit.placeholder:SetPoint("LEFT", edit, "LEFT", left, 0)
        edit.placeholder:SetPoint("RIGHT", edit, "RIGHT", -7, 0)
        edit.placeholder:SetHeight(14)
        edit.placeholder:SetText(options.placeholder)
    end

    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function() this.tgmmFocused = true; Theme.RefreshInput(this) end)
    edit:SetScript("OnEditFocusLost", function() this.tgmmFocused = false; Theme.RefreshInput(this) end)
    edit:SetScript("OnEnter", function() this.tgmmHover = true; Theme.RefreshInput(this) end)
    edit:SetScript("OnLeave", function() this.tgmmHover = false; Theme.RefreshInput(this) end)
    Theme.RefreshInput(edit)
    return edit
end

-- Runs fn after whatever handler is already installed for scriptName.
-- Used to keep placeholders in sync without touching the logic handlers.
function Theme.HookScript(frame, scriptName, fn)
    local previous = frame:GetScript(scriptName)
    frame:SetScript(scriptName, function()
        if previous then previous() end
        fn(frame)
    end)
end

function Theme.WatchInput(edit)
    Theme.HookScript(edit, "OnTextChanged", Theme.RefreshInput)
    Theme.RefreshInput(edit)
end

---------------------------------------------------------------------------
-- Badges & status
---------------------------------------------------------------------------

-- Small uppercase pill, e.g. DANGER or LOOKUP.
function Theme.Badge(parent)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetHeight(14)
    badge:SetBackdrop(BACKDROP)
    badge.text = Theme.Text(badge, 9, C.text, { justify = "CENTER" })
    badge.text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badge:Hide()
    return badge
end

function Theme.SetBadge(badge, text, color)
    if not text or text == "" then badge:Hide(); return end
    color = color or C.gold
    badge.text:SetText(text)
    Theme.SetTextColor(badge.text, color)
    badge:SetBackdropColor(color[1], color[2], color[3], 0.14)
    badge:SetBackdropBorderColor(color[1], color[2], color[3], 0.55)
    local width = badge.text:GetStringWidth() or 0
    if width < 4 then width = string.len(text) * 6 end
    badge:SetWidth(math.floor(width + 12.5))
    badge:Show()
end

-- Coloured dot used for status and target indicators.
function Theme.Dot(parent, size)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(WHITE)
    dot:SetWidth(size or 6); dot:SetHeight(size or 6)
    return dot
end

function Theme.SetDotColor(dot, color)
    dot:SetVertexColor(color[1], color[2], color[3], 1)
end

-- Colour escape helper for inline segments inside one FontString.
function Theme.Hex(color)
    return string.format("|cff%02x%02x%02x", math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5), math.floor(color[3] * 255 + 0.5))
end
