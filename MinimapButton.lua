local _, Oak = ...

local function PositionButton(button)
    local angle = math.rad(Oak.db.minimapAngle or 220)
    local radius = Minimap:GetWidth() * 0.5 + 2
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CreateButton()
    if Oak.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "OakLFGSorterForeverMinimapButton", Minimap)
    Oak.minimapButton = button
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local ring = button:CreateTexture(nil, "BACKGROUND")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(54, 54)
    ring:SetPoint("TOPLEFT")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\OakLFGSorterForever\\Media\\icon.png")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetSize(52, 52)
    highlight:SetPoint("CENTER", 0, 1)

    button:SetScript("OnClick", function(self, mouseButton)
        GameTooltip:Hide()
        if mouseButton == "RightButton" then
            if Oak.EnsureUI() then
                Oak.frame:Show()
                Oak.ShowOptions(self)
            end
        else
            SlashCmdList.OAKLFGFOREVER("")
        end
    end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local centerX, centerY = Minimap:GetCenter()
        if centerX and centerY then
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            Oak.db.minimapAngle = math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX))
        end
        PositionButton(self)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Oak LFG Sorter - Forever", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open or close the sorter.", 1, 1, 1)
        GameTooltip:AddLine("Right-click: options.", 1, 1, 1)
        GameTooltip:AddLine("Drag: reposition around the minimap.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    PositionButton(button)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    CreateButton()
end)
