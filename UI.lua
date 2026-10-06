local _, Oak = ...
local FONT = "Interface\\AddOns\\OakLFGSorterForever\\Media\\OakFont.ttf"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ROWS, ROW_HEIGHT = 9, 30
local columns = {
    { key = "kind", label = "Type", x = 0, width = 48 },
    { key = "name", label = "Name / Leader", x = 48, width = 134 },
    { key = "level", label = "Lvl", x = 182, width = 34 },
    { key = "activity", label = "Activity", x = 216, width = 116 },
    { key = "size", label = "Roles / Size", x = 332, width = 85 },
    { key = "age", label = "Age", x = 417, width = 36 },
    { key = "note", label = "Note / Style", x = 453, width = 169 },
}

local function Text(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size or 11, "")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function Fill(parent, r, g, b, a)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(r, g, b, a)
    return texture
end

local function Button(parent, label, width, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 23)
    button:SetPoint("TOPLEFT", x, y)
    button:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    button:SetBackdropColor(0.20, 0.20, 0.20, 1)
    button:SetBackdropBorderColor(0.34, 0.34, 0.34, 1)
    button.label = Text(button)
    button.label:SetPoint("LEFT", 5, 0)
    button.label:SetPoint("RIGHT", -5, 0)
    button.label:SetJustifyH("CENTER")
    button.label:SetText(label)
    button:SetHighlightTexture(WHITE)
    button:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.10)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnable", function(self) self.label:SetTextColor(0.95, 0.95, 0.95) end)
    button:SetScript("OnDisable", function(self) self.label:SetTextColor(0.45, 0.45, 0.45) end)
    return button
end

local function Selected(button, active)
    button:SetBackdropColor(active and 0.23 or 0.20, active and 0.32 or 0.20, active and 0.39 or 0.20, 1)
    button:SetBackdropBorderColor(active and 0.40 or 0.34, active and 0.65 or 0.34, active and 0.80 or 0.34, 1)
end

function Oak.ShowCategoryMenu(owner)
    if LFGBrowseFrame.searching then return end
    MenuUtil.CreateContextMenu(owner, function(_, menu)
        menu:CreateTitle("Category")
        if C_LFGList.HasActiveEntryInfo() then
            menu:CreateButton("Your listing", function() LFGBrowseFrame:SearchActiveEntry() end)
        end
        for _, id in ipairs(C_LFGList.GetAvailableCategories()) do
            if #LFGUtil_GetFilteredActivities(id) > 0 then
                local info = C_LFGList.GetLfgCategoryInfo(id)
                if info then
                    menu:CreateRadio(info.name, function() return LFGBrowseFrame.CategoryDropdown:GetValue() == id end,
                        function()
                            if LFGBrowseFrame.searching then return end
                            LFGBrowseFrame.CategoryDropdown:SetValue(id)
                            LFGBrowseCategoryButton_OnClick()
                        end)
                end
            end
        end
    end)
end

function Oak.ShowActivityMenu(owner)
    if LFGBrowseFrame.searching then return end
    local category = LFGBrowseFrame.CategoryDropdown:GetValue()
    if category <= 0 then return end
    MenuUtil.CreateContextMenu(owner, function(_, menu)
        menu:CreateTitle("Activities")
        menu:SetScrollMode(360)
        menu:CreateButton("All activities", function()
            if LFGBrowseFrame.searching then return end
            LFGBrowseFrame.ActivityDropdown:ValueReset()
            LFGBrowse_DoSearch()
        end)
        for _, id in ipairs(LFGUtil_GetFilteredActivities(category)) do
            local info = C_LFGList.GetActivityInfoTable(id)
            if info then
                menu:CreateCheckbox(LFGUtil_GetActivityInfoName(info), function()
                    return LFGBrowseFrame.ActivityDropdown:ValueIsSelected(id)
                end, function()
                    if LFGBrowseFrame.searching then return end
                    LFGBrowseFrame.ActivityDropdown:ValueToggleSelected(id)
                    LFGBrowse_DoSearch()
                end)
            end
        end
    end)
end

function Oak.ShowOptions(owner)
    MenuUtil.CreateContextMenu(owner, function(_, menu)
        menu:CreateTitle("Oak LFG Sorter - Forever")
        menu:CreateCheckbox("Open with Blizzard's browser", function() return Oak.db.autoOpen end, function()
            Oak.db.autoOpen = not Oak.db.autoOpen
            Oak.InstallAutoOpen()
        end)
        menu:CreateButton("Custom whisper message", Oak.ShowWhisperSettings)
        menu:CreateCheckbox("New-player-friendly listings only", function() return Oak.filters.friendly end, function()
            Oak.filters.friendly = not Oak.filters.friendly
            Oak.Refilter()
        end)
        menu:CreateCheckbox("Include activities outside suggested level", function()
            return GetCVarBool("disableSuggestedLevelActivityFilter")
        end, function()
            if LFGBrowseFrame.searching then return end
            SetCVar("disableSuggestedLevelActivityFilter", not GetCVarBool("disableSuggestedLevelActivityFilter"))
            Oak.Render()
        end)
        local scale = menu:CreateButton("Window scale")
        for _, value in ipairs({ 0.8, 0.9, 1, 1.1, 1.2 }) do
            scale:CreateRadio(string.format("%d%%", value * 100), function() return Oak.db.scale == value end, function()
                Oak.db.scale = value
                Oak.frame:SetScale(value)
            end)
        end
        menu:CreateButton("Reset position", Oak.ResetPosition)
        menu:CreateButton("Supporters", Oak.ShowSupporters)
    end)
end

function Oak.ShowWhisperSettings()
    if Oak.whisperSettings then Oak.whisperSettings:Show(); Oak.whisperSettings.edit:SetFocus(); return end
    local panel = CreateFrame("Frame", "OakLFGSorterForeverWhisperSettings", UIParent, "BackdropTemplate")
    Oak.whisperSettings = panel
    panel:SetSize(420, 150); panel:SetPoint("CENTER"); panel:SetFrameStrata("TOOLTIP")
    panel:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }); panel:SetBackdropColor(0.04, 0.04, 0.04, 0.98); panel:SetBackdropBorderColor(0.4, 0.65, 0.8, 1)
    local title = Text(panel, 13); title:SetPoint("TOP", 0, -14); title:SetText("Custom whisper message")
    local help = Text(panel, 10); help:SetPoint("TOPLEFT", 16, -40); help:SetWidth(388); help:SetWordWrap(true); help:SetText("Used for group whispers and double-clicks. Leave blank to open a normal whisper.")
    panel.edit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate"); panel.edit:SetSize(388, 24); panel.edit:SetPoint("TOPLEFT", 16, -75); panel.edit:SetAutoFocus(false); panel.edit:SetMaxLetters(180); panel.edit:SetText(Oak.db.customWhisper or "")
    panel.edit:SetScript("OnEscapePressed", function() panel:Hide() end)
    Button(panel, "Save", 90, 112, -112, function() Oak.db.customWhisper = panel.edit:GetText(); panel:Hide() end)
    Button(panel, "Cancel", 90, 218, -112, function() panel:Hide() end)
    panel:Show(); panel.edit:SetFocus()
end

function Oak.ShowSupporters()
    if Oak.supporters then Oak.supporters:Show(); return end
    local panel = CreateFrame("Frame", "OakLFGSorterForeverSupporters", UIParent, "BackdropTemplate")
    Oak.supporters = panel
    panel:SetSize(380, 390); panel:SetPoint("CENTER"); panel:SetFrameStrata("TOOLTIP")
    panel:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }); panel:SetBackdropColor(0.04, 0.04, 0.04, 0.98); panel:SetBackdropBorderColor(0.4, 0.65, 0.8, 1)
    local title = Text(panel, 14); title:SetPoint("TOP", 0, -14); title:SetText("Oak LFG Sorter supporters")
    local body = Text(panel, 11); body:SetPoint("TOPLEFT", 18, -44); body:SetPoint("TOPRIGHT", -18, -44); body:SetJustifyH("LEFT"); body:SetWordWrap(true)
    body:SetText("Thank you to everyone who supports Oak addons and helps test the Forever client.\\n\\nSupport Oak: Patreon.com/Oakensoul\\nDiscord: discord.gg/FRGUFaEEVd\\n\\nCurrent supporter names are maintained with the addon release.")
    Button(panel, "Close", 100, 140, -350, function() panel:Hide() end); panel:Show()
end

function Oak.ShowClassArmor()
    if Oak.classArmorPanel then Oak.classArmorPanel:SetShown(not Oak.classArmorPanel:IsShown()); return end
    local panel = CreateFrame("Frame", nil, Oak.frame, "BackdropTemplate"); Oak.classArmorPanel = panel
    panel:SetSize(220, 360); panel:SetPoint("TOPLEFT", Oak.frame, "TOPRIGHT", -8, -72); panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }); panel:SetBackdropColor(0.04,0.04,0.04,0.98); panel:SetBackdropBorderColor(0.4,0.65,0.8,1)
    local title = Text(panel, 12); title:SetPoint("TOP",0,-12); title:SetText("Class / Armor")
    local y = -38
    for _, class in ipairs({ "WARRIOR", "PALADIN", "DEATHKNIGHT", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MONK", "DEMONHUNTER", "PRIEST", "MAGE", "WARLOCK" }) do
        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate"); cb:SetPoint("TOPLEFT", 12, y); cb:SetSize(22,22); cb:SetChecked(Oak.filters.classes[class]); cb:SetScript("OnClick", function(self) Oak.filters.classes[class]=self:GetChecked() or nil; Oak.Refilter() end)
        local text = Text(panel, 10); text:SetPoint("LEFT", cb, "RIGHT", 3, 0); text:SetText((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class); y=y-22
    end
    local armorTitle = Text(panel, 11); armorTitle:SetPoint("TOPLEFT", 14, y-4); armorTitle:SetText("Armor"); y=y-28
    for _, armor in ipairs({ "Cloth", "Leather", "Mail", "Plate" }) do
        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate"); cb:SetPoint("TOPLEFT", 12, y); cb:SetSize(22,22); cb:SetChecked(Oak.filters.armor[armor]); cb:SetScript("OnClick", function(self) Oak.filters.armor[armor]=self:GetChecked() or nil; Oak.Refilter() end)
        local text = Text(panel, 10); text:SetPoint("LEFT", cb, "RIGHT", 3, 0); text:SetText(armor); y=y-22
    end
    Button(panel, "Clear", 80, 68, -330, function() wipe(Oak.filters.classes); wipe(Oak.filters.armor); panel:Hide(); Oak.Refilter() end)
    panel:Show()
end

local function Tooltip(row)
    local result = row.result
    if not result then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(result.name)
    GameTooltip:AddLine(result.hasSelf and "Your listing" or result.kind, 0.5, 0.8, 1)
    GameTooltip:AddLine(result.activity, 0.8, 0.8, 0.8, true)
    if result.style ~= "" then GameTooltip:AddLine(result.style, 0.4, 1, 0.4) end
    if result.friendly then GameTooltip:AddLine("New-player friendly", 0.4, 1, 0.4) end
    if result.note ~= "" then GameTooltip:AddLine(result.note, 1, 1, 1, true) end
    for index = 1, result.size do
        local member = C_LFGList.GetSearchResultPlayerInfo(result.id, index)
        if member then
            local roleNames = {}
            for _, role in ipairs(Oak.roles) do
                if member.lfgRoles and member.lfgRoles[Oak.roleKeys[role]] then
                    roleNames[#roleNames + 1] = role == "DAMAGER" and "DPS" or role == "HEALER" and "Healer" or "Tank"
                end
            end
            local className = member.className or member.classFilename or "Unknown class"
            local color = member.classFilename and RAID_CLASS_COLORS[member.classFilename]
            GameTooltip:AddDoubleLine(member.name or className,
                string.format("%s %s  %s", member.level or "?", className, table.concat(roleNames, "/")),
                color and color.r or 1, color and color.g or 1, color and color.b or 1, 0.7, 0.7, 0.7)
        end
    end
    GameTooltip:Show()
end

local function MakeRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(622, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 14, -147 - (index - 1) * ROW_HEIGHT)
    row.bg = Fill(row, 0.12, 0.12, 0.12, 1)
    row:SetHighlightTexture(WHITE)
    row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.08)
    row.fields = {}
    for _, col in ipairs(columns) do
        if col.key ~= "size" then
            local fs = Text(row)
            fs:SetPoint("LEFT", col.x + 3, 0)
            fs:SetWidth(col.width - 6)
            row.fields[col.key] = fs
        end
    end
    row.roleIcons, row.roleCounts = {}, {}
    for roleIndex, role in ipairs(Oak.roles) do
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", 334 + (roleIndex - 1) * 25, 3)
        icon:SetAtlas(Oak.roleAtlases[role])
        row.roleIcons[role] = icon
        local count = Text(row, 9)
        count:SetPoint("TOP", icon, "BOTTOM", 0, 1)
        row.roleCounts[role] = count
    end
    row:SetScript("OnClick", function(self)
        if not LFGBrowseFrame.searching and self.result and Oak.GetActionInfo(self.result.id) then
            Oak.selected = Oak.selected ~= self.result.id and self.result.id or nil
            Oak.Render()
        end
    end)
    row:SetScript("OnDoubleClick", function(self)
        local result = self.result
        if not result or LFGBrowseFrame.searching then return end
        Oak.selected = result.id
        if result.kind == "Group" then Oak.Whisper() else Oak.Invite() end
        Oak.Render()
    end)
    row:SetScript("OnEnter", Tooltip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

function Oak.BuildUI()
    local frame = CreateFrame("Frame", "OakLFGSorterForeverFrame", UIParent, "PortraitFrameTemplate")
    Oak.frame = frame
    frame:Hide()
    frame:SetSize(660, 484)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetScale(Oak.db.scale)
    if frame.SetTitle then frame:SetTitle("|cffe03d02OAK|r LFG Sorter |cff999999- Forever|r") end
    if frame.TitleText then frame.TitleText:SetText("|cffe03d02OAK|r LFG Sorter - Forever") end
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\AddOns\\OakLFGSorterForever\\Media\\Logo.tga")
    end
    if frame.Bg then frame.Bg:SetColorTexture(0.10, 0.10, 0.10, 0.97) end
    if frame.Inset then frame.Inset:Hide() end
    if frame.TopTileStreaks then frame.TopTileStreaks:Hide() end
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", 64, -3)
    drag:SetPoint("TOPRIGHT", -30, -3)
    drag:SetHeight(28)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() frame:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint()
        Oak.db.position = { point, relativePoint, x, y }
    end)
    if Oak.db.position then
        local p = Oak.db.position
        frame:ClearAllPoints()
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    end
    tinsert(UISpecialFrames, "OakLFGSorterForeverFrame")
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    frame:SetScript("OnShow", Oak.OnShow)
    frame:SetScript("OnHide", Oak.OnHide)
    frame:SetScript("OnEvent", Oak.OnEvent)

    frame.category = Button(frame, "Category", 150, 72, -43, Oak.ShowCategoryMenu)
    frame.activity = Button(frame, "All activities", 229, 228, -43, Oak.ShowActivityMenu)
    frame.refresh = Button(frame, "Refresh", 83, 463, -43, function() LFGBrowse_DoSearch() end)
    Button(frame, "Options", 92, 552, -43, Oak.ShowOptions)
    frame.kindButtons = {}
    for index, kind in ipairs({ "All", "Group", "Player" }) do
        local label = kind == "All" and "All" or kind .. "s"
        frame.kindButtons[kind] = Button(frame, label, 64, 14 + (index - 1) * 68, -76, function()
            Oak.filters.kind = kind
            Oak.Refilter()
        end)
    end
    frame.roleButtons = {}
    for index, role in ipairs({ "ALL", "TANK", "HEALER", "DAMAGER" }) do
        local labels = { ALL = "Any role", TANK = "Tank", HEALER = "Healer", DAMAGER = "DPS" }
        frame.roleButtons[role] = Button(frame, labels[role], 64, 236 + (index - 1) * 68, -76, function()
            Oak.filters.role = role
            Oak.Refilter()
        end)
    end
    Button(frame, "Clear filters", 136, 508, -76, function()
        Oak.filters.kind, Oak.filters.role, Oak.filters.friendly = "All", "ALL", false
        wipe(Oak.filters.classes); wipe(Oak.filters.armor)
        frame.search:SetText("")
        Oak.Refilter()
    end)
    Button(frame, "Class / Armor", 136, 508, -102, Oak.ShowClassArmor)

    frame.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.search:SetSize(237, 22)
    frame.search:SetPoint("TOPLEFT", 20, -106)
    frame.search:SetAutoFocus(false)
    frame.search:SetFont(FONT, 11, "")
    frame.search:SetMaxLetters(120)
    frame.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    frame.search:SetScript("OnTextChanged", function(self)
        Oak.filters.text = self:GetText()
        Oak.Refilter()
    end)
    frame.searchHint = Text(frame, 10)
    frame.searchHint:SetPoint("LEFT", frame.search, "RIGHT", 10, 0)
    frame.searchHint:SetText("Filter name, activity, or note")
    frame.headers = {}
    for _, col in ipairs(columns) do
        local header = Button(frame, col.label, col.width, 14 + col.x, -129, function()
            if Oak.sortKey == col.key then Oak.descending = not Oak.descending
            else Oak.sortKey, Oak.descending = col.key, false end
            Oak.Refilter(false)
        end)
        header:SetHeight(18)
        header.label:SetFont(FONT, 10, "")
        frame.headers[col.key] = header
    end
    frame.rows = {}
    for index = 1, ROWS do frame.rows[index] = MakeRow(frame, index) end
    frame.empty = Text(frame, 12)
    frame.empty:SetPoint("TOP", 0, -225)
    frame.empty:SetWidth(600)
    frame.empty:SetJustifyH("CENTER")
    frame.empty:SetWordWrap(true)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        frame.scroll:SetValue(math.max(0, math.min(math.max(0, #Oak.visible - ROWS), Oak.offset - delta * 3)))
    end)
    frame.scroll = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
    frame.scroll:SetPoint("TOPRIGHT", -7, -166)
    frame.scroll:SetPoint("BOTTOMRIGHT", -7, 85)
    frame.scroll:SetMinMaxValues(0, 0)
    frame.scroll:SetValueStep(1)
    frame.scroll:SetObeyStepOnDrag(true)
    frame.scroll:SetScript("OnValueChanged", function(_, value)
        Oak.offset = math.floor(value + 0.5)
        Oak.RenderRows()
    end)
    frame.status = Text(frame, 10)
    frame.status:SetPoint("TOPLEFT", 16, -422)
    frame.status:SetWidth(622)
    frame.list = Button(frame, "List / Edit", 94, 14, -445, function() Oak.OpenNative(1) end)
    Button(frame, "Blizzard", 80, 114, -445, function() Oak.OpenNative(2) end)
    frame.selection = Text(frame, 10)
    frame.selection:SetPoint("TOPLEFT", 202, -450)
    frame.selection:SetWidth(214)
    frame.whisper = Button(frame, "Whisper", 106, 422, -445, Oak.Whisper)
    frame.invite = Button(frame, "Invite", 106, 534, -445, Oak.Invite)
end

function Oak.RenderRows()
    local frame = Oak.frame
    for index, row in ipairs(frame.rows) do
        local result = Oak.visible[Oak.offset + index]
        row.result = result
        row:SetShown(result ~= nil)
        if result then
            local selected = Oak.selected == result.id
            local shade = index % 2 == 0 and 0.10 or 0.15
            row.bg:SetColorTexture(selected and 0.20 or shade, selected and 0.29 or shade, selected and 0.36 or shade, 0.98)
            row.fields.kind:SetText(result.hasSelf and "You" or result.kind)
            row.fields.name:SetText(result.name)
            local color = result.class and RAID_CLASS_COLORS[result.class]
            row.fields.name:SetTextColor(color and color.r or 1, color and color.g or 0.82, color and color.b or 0)
            row.fields.level:SetText(result.level > 0 and result.level or "-")
            row.fields.activity:SetText(result.hasSelf and "Your listing" or result.activity)
            row.fields.activity:SetTextColor(0.40, 0.75, 1)
            row.fields.age:SetText(result.age < 60 and "<1m" or math.floor(result.age / 60) .. "m")
            row.fields.note:SetText(result.note ~= "" and result.note or result.style)
            row.fields.note:SetTextColor(0.80, 0.80, 0.80)
            for _, role in ipairs(Oak.roles) do
                local count = result.roles[role]
                row.roleIcons[role]:SetAlpha(count > 0 and 1 or 0.18)
                row.roleCounts[role]:SetText(result.kind == "Group" and count or "")
            end
        end
    end
end

function Oak.Render()
    local frame = Oak.frame
    if not frame or not frame:IsShown() then return end
    local searching = LFGBrowseFrame.searching
    local category = LFGBrowseFrame.CategoryDropdown:GetValue()
    local info = category > 0 and C_LFGList.GetLfgCategoryInfo(category)
    frame.category.label:SetText(info and info.name or "Choose category")
    local activities = LFGBrowseFrame.ActivityDropdown.selectedValues
    local activity = #activities == 1 and C_LFGList.GetActivityInfoTable(activities[1])
    frame.activity.label:SetText(activity and LFGUtil_GetActivityInfoName(activity) or #activities > 1 and #activities .. " activities" or "All activities")
    frame.category:SetEnabled(not searching)
    frame.activity:SetEnabled(not searching and category > 0)
    frame.refresh:SetEnabled(not searching and category > 0)
    frame.refresh.label:SetText(searching and "Searching..." or "Refresh")
    for key, button in pairs(frame.kindButtons) do Selected(button, Oak.filters.kind == key) end
    for key, button in pairs(frame.roleButtons) do Selected(button, Oak.filters.role == key) end
    for key, button in pairs(frame.headers) do Selected(button, Oak.sortKey == key) end
    frame.scroll:SetMinMaxValues(0, math.max(0, #Oak.visible - ROWS))
    Oak.offset = math.min(Oak.offset, math.max(0, #Oak.visible - ROWS))
    frame.scroll:SetValue(Oak.offset)
    frame.scroll:SetShown(#Oak.visible > ROWS)
    frame.empty:SetShown(#Oak.visible == 0)
    frame.empty:SetText(searching and "Searching..." or LFGBrowseFrame.searchFailed and "Search failed. Click Refresh to try again."
        or category == 0 and "Choose a category to find players and groups."
        or #Oak.results > 0 and "No listings match your filters." or "No listings found. Click Refresh to search again.")
    local status = string.format("%d shown / %d loaded | %d groups, %d players", #Oak.visible, #Oak.results, Oak.groupCount, Oak.playerCount)
    if Oak.filters.friendly then status = status .. " | New-player friendly" end
    if searching then status = "Searching... previous results shown"
    elseif LFGBrowseFrame.searchFailed then status = "Search failed. Previous results shown; click Refresh to retry." end
    frame.status:SetText(status)
    local selected = not searching and Oak.GetActionInfo(Oak.selected)
    frame.selection:SetText(selected and selected.leaderName or "Select a listing")
    frame.whisper:SetEnabled(selected ~= nil and selected ~= false)
    frame.invite:SetEnabled(not searching and Oak.GetInviteAction(Oak.selected) ~= nil)
    frame.list.label:SetText(C_LFGList.HasActiveEntryInfo() and "Edit listing" or "List yourself")
    Oak.RenderRows()
end
