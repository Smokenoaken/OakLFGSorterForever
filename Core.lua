local addonName, Oak = ...
BINDING_HEADER_OAKLFGSORTERFOREVER = "Oak LFG Sorter - Forever"
BINDING_NAME_OAKLFGSORTERFOREVER_TOGGLE = "Open / Close Sorter"
local events = {
    "LFG_LIST_SEARCH_RESULTS_RECEIVED", "LFG_LIST_SEARCH_RESULT_UPDATED",
    "LFG_LIST_SEARCH_FAILED", "LFG_LIST_ACTIVE_ENTRY_UPDATE",
    "LFG_LIST_AVAILABILITY_UPDATE", "GROUP_ROSTER_UPDATE",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
}

function Oak.Refilter(resetScroll)
    wipe(Oak.visible)
    Oak.groupCount, Oak.playerCount = 0, 0
    local selectedVisible = false
    for _, result in ipairs(Oak.results) do
        if Oak.Matches(result, Oak.filters) then
            Oak.visible[#Oak.visible + 1] = result
            if result.id == Oak.selected then selectedVisible = true end
            if not result.hasSelf then
                if result.kind == "Group" then Oak.groupCount = Oak.groupCount + 1
                else Oak.playerCount = Oak.playerCount + 1 end
            end
        end
    end
    if not selectedVisible then Oak.selected = nil end
    Oak.Sort(Oak.visible, Oak.sortKey, Oak.descending)
    if resetScroll ~= false then Oak.offset = 0 end
    Oak.Render()
end

function Oak.RefreshResults()
    wipe(Oak.results)
    local _, ids = C_LFGList.GetFilteredSearchResults()
    for _, id in ipairs(ids or {}) do
        local result = Oak.ReadResult(id)
        if result then Oak.results[#Oak.results + 1] = result end
    end
    Oak.Refilter(false)
end

function Oak.OnEvent(_, event, id)
    if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        Oak.RefreshResults()
    elseif event == "LFG_LIST_SEARCH_RESULT_UPDATED" then
        for index, result in ipairs(Oak.results) do
            if result.id == id then
                local updated = Oak.ReadResult(id)
                if updated then Oak.results[index] = updated else table.remove(Oak.results, index) end
                break
            end
        end
        Oak.Refilter(false)
    else
        Oak.Render()
    end
end

function Oak.OnShow()
    for _, event in ipairs(events) do Oak.frame:RegisterEvent(event) end
    Oak.RefreshResults()
end

function Oak.OnHide()
    Oak.frame:UnregisterAllEvents()
    Oak.frame.search:ClearFocus()
    GameTooltip:Hide()
    Oak.selected = nil
end

function Oak.ResetPosition()
    Oak.db.position, Oak.db.scale = nil, 1
    if Oak.frame then
        Oak.frame:SetScale(1)
        Oak.frame:ClearAllPoints()
        Oak.frame:SetPoint("CENTER")
    end
end

function Oak.InstallAutoOpen()
    if not Oak.db.autoOpen or Oak.autoOpenHooked or not LFGBrowseFrame then return end
    Oak.autoOpenHooked = true
    LFGBrowseFrame:HookScript("OnShow", function()
        if Oak.db.autoOpen and not Oak.openingNative then
            if Oak.EnsureUI() then Oak.frame:Show() end
        end
    end)
end

function Oak.EnsureUI()
    if Oak.frame then return true end
    if InCombatLockdown() then
        print("|cffe03d02OAK|r: Open the Forever sorter after combat.")
        return false
    end
    if not C_AddOns.IsAddOnLoaded("Blizzard_GroupFinder_VanillaStyle") then
        local loaded, reason = C_AddOns.LoadAddOn("Blizzard_GroupFinder_VanillaStyle")
        if not loaded then
            print("|cffe03d02OAK|r: Could not load Forever's finder: " .. tostring(reason))
            return false
        end
    end
    if not LFGBrowseFrame or not LFGBrowseUtil_GetInviteActionForResult then
        print("|cffe03d02OAK|r: This addon requires the Forever group finder.")
        return false
    end
    Oak.results, Oak.visible = {}, {}
    Oak.filters = { kind = "All", role = "ALL", text = "", friendly = false }
    Oak.sortKey, Oak.descending, Oak.offset = "name", false, 0
    Oak.groupCount, Oak.playerCount = 0, 0
    Oak.BuildUI()
    hooksecurefunc("LFGBrowse_DoSearch", function()
        if Oak.frame:IsShown() then
            Oak.selected = nil
            Oak.Render()
        end
    end)
    -- Run after Blizzard updates its search state, regardless of event dispatch order.
    hooksecurefunc(LFGBrowseFrame, "UpdateResults", function()
        if Oak.frame:IsShown() then Oak.Render() end
    end)
    Oak.InstallAutoOpen()
    C_LFGList.RequestAvailableActivities()
    return true
end

function Oak.OpenNative(tab)
    if InCombatLockdown() then
        print("|cffe03d02OAK|r: Open the Blizzard finder after combat.")
        return
    end
    Oak.openingNative = true
    Oak.frame:Hide()
    if LFGVanilla_ShowFrame then
        LFGVanilla_ShowFrame(tab)
    elseif tab == 1 and LFGListingFrame then
        LFGListingFrame:Show()
    elseif LFGBrowseFrame then
        LFGBrowseFrame:Show()
        if LFGBrowseFrame.Raise then LFGBrowseFrame:Raise() end
    end
    Oak.openingNative = false
    print("|cffe03d02OAK|r: Use /sorter to return to Oak.")
end

local function Slash(message)
    if message == "reset" then Oak.ResetPosition(); return end
    if Oak.frame and Oak.frame:IsShown() then Oak.frame:Hide(); return end
    if Oak.EnsureUI() then Oak.frame:Show() end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name == addonName then
        OakLFGSorterForeverDB = OakLFGSorterForeverDB or {}
        Oak.db = OakLFGSorterForeverDB
        Oak.db.scale = math.max(0.8, math.min(1.2, tonumber(Oak.db.scale) or 1))
        if Oak.db.autoOpen == nil then Oak.db.autoOpen = false end
        if Oak.db.customWhisper == nil then Oak.db.customWhisper = "" end
        SLASH_OAKLFGFOREVER1 = "/sorter"
        SLASH_OAKLFGFOREVER2 = "/oaklfgforever"
        SlashCmdList.OAKLFGFOREVER = Slash
        if not Oak.db.autoOpen then self:UnregisterAllEvents() end
    end
    if Oak.db and Oak.db.autoOpen and LFGBrowseFrame then
        Oak.InstallAutoOpen()
        self:UnregisterAllEvents()
    end
end)
