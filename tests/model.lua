local Oak = {}
local function load(name) assert(loadfile("" .. name .. ".lua"))("OakLFGSorterForever", Oak) end
local checks = 0
local function check(value, label)
    assert(value, label)
    checks = checks + 1
end
local info, players, leaders, counts, ids = {}, {}, {}, {}, {}
local invited, whispered, combat, raid, members, partyMembers, canInvite = nil, nil, false, false, 0, 0, true
RETRIEVING_DATA = "Retrieving"
C_LFGList = {
    GetSearchResultInfo = function(id) return info[id] end,
    GetSearchResultLeaderInfo = function(id) return leaders[id] end,
    GetSearchResultPlayerInfo = function(id) return players[id] end,
    GetSearchResultMemberCounts = function(id) return counts[id] end,
    GetActivityInfoTable = function(id) return id == 7 and { name = "Blackfathom Deeps" } or nil end,
    GetFilteredSearchResults = function() return #ids, ids end,
    RequestAvailableActivities = function() end,
}
LFGUtil_GetActivityInfoName = function(activity) return activity.name end
GetGeneralPlaystyleString = function() return "Relaxed" end
InCombatLockdown = function() return combat end
IsInRaid = function() return raid end
GetNumGroupMembers = function() return members end
GetNumSubgroupMembers = function() return partyMembers end
LFGBrowseUtil_GetInviteActionForResult = function(id)
    if info[id] and info[id].numMembers == 1 and canInvite then
        return "Invite", function() invited = info[id].leaderName end
    end
end
ChatFrameUtil = { SendTell = function(name) whispered = name end }
wipe = function(t) for k in pairs(t) do t[k] = nil end end
SlashCmdList = {}
local loader
CreateFrame = function()
    loader = { events = {} }
    function loader:RegisterEvent(event) self.events[event] = true end
    function loader:UnregisterAllEvents() wipe(self.events) end
    function loader:SetScript(_, callback) self.callback = callback end
    return loader
end
load("Data")
load("Core")
loader:callback("ADDON_LOADED", "OakLFGSorterForever")
check(Oak.db.autoOpen == false and next(loader.events) == nil, "default off unregisters loader")
check(Oak.frame == nil, "no UI built at login")
check(SlashCmdList.OAKLFGFOREVER ~= nil, "slash command available")
info[1] = { leaderName = "Solo", numMembers = 1, activityIDs = {7}, comment = "A 100% relaxed run", generalPlaystyle = 1, age = 35, hasSelf = false }
players[1] = { classFilename = "DRUID", level = 25, lfgRoles = { tank = true, healer = true } }
info[2] = { leaderName = "Group", numMembers = 3, activityIDs = {7}, comment = "", hasSelf = false }
leaders[2] = { classFilename = "WARRIOR", level = 30 }
counts[2] = { TANK = 1, HEALER = 0, DAMAGER = 2 }
info[3] = { leaderName = "Me", numMembers = 1, activityIDs = {7}, hasSelf = true }
info[4] = { leaderName = "Gone", numMembers = 1, isDelisted = true }
local solo, group, self = Oak.ReadResult(1), Oak.ReadResult(2), Oak.ReadResult(3)
check(solo.kind == "Player" and solo.level == 25, "solo listing data")
check(solo.roles.TANK == 1 and solo.roles.HEALER == 1 and solo.roles.DAMAGER == 0, "multi-role solo preserved")
check(group.kind == "Group" and group.roles.DAMAGER == 2 and group.level == 0, "group composition")
check(solo.activity == "Blackfathom Deeps" and solo.style == "Relaxed", "native activity and style")
check(self.level == 0 and self.class == nil, "missing player info accepted")
check(Oak.ReadResult(4) == nil and Oak.ReadResult(999) == nil, "delisted and missing results excluded")
local filters = { kind = "All", role = "ALL", text = "100%", friendly = false }
check(Oak.Matches(solo, filters), "literal search accepts percent")
filters.text = "BLACKFATHOM"
check(Oak.Matches(solo, filters), "search case-insensitive")
filters.text, filters.kind = "", "Group"
check(not Oak.Matches(solo, filters) and Oak.Matches(group, filters), "mixed listing type filter")
filters.kind, filters.role = "All", "HEALER"
check(Oak.Matches(solo, filters) and not Oak.Matches(group, filters), "role filter distinguishes multi-role solo from group")
filters.text, filters.friendly = "nonmatching", true
check(Oak.Matches(self, filters), "own listing always visible")
check(not Oak.Matches(solo, filters), "friendly filter excludes other listings")
local sorted = { solo, group, self }
Oak.Sort(sorted, "name", false)
check(sorted[1] == self and sorted[2] == group, "own listing first and ascending")
Oak.Sort(sorted, "name", true)
check(sorted[1] == self and sorted[2] == solo, "own listing first and descending")
check(Oak.GetInviteAction(1) ~= nil and Oak.GetInviteAction(2) == nil, "only solo invitations")
check(Oak.GetInviteAction(3) == nil and Oak.GetInviteAction(4) == nil, "no self or delisted actions")
canInvite = false
check(Oak.GetInviteAction(1) == nil, "native permission enforced")
canInvite, combat = true, true
check(Oak.GetInviteAction(1) == nil, "no invitations in combat")
combat, partyMembers = false, 4
check(Oak.GetInviteAction(1) == nil, "party full")
partyMembers, raid, members = 0, true, 40
check(Oak.GetInviteAction(1) == nil, "raid full")
raid, members = false, 0
Oak.selected = 1
Oak.Invite()
check(invited == "Solo", "explicit invite resolves selected result")
Oak.selected = 2
Oak.Whisper()
check(whispered == "Group", "group leader whisper draft")
info[2].isDelisted = true
whispered = nil
Oak.Whisper()
check(whispered == nil, "revalidate target at click")
info[2].isDelisted = false
Oak.Render = function() end
Oak.results, Oak.visible = {}, {}
Oak.filters = { kind = "All", role = "ALL", text = "", friendly = false }
Oak.sortKey, Oak.descending, Oak.offset = "name", false, 0
ids = {1,2,3,4}
Oak.RefreshResults()
check(#Oak.results == 3 and #Oak.visible == 3, "mixed native result refresh")
check(Oak.groupCount == 1 and Oak.playerCount == 1, "counts exclude own listing")
Oak.filters.kind = "Player"
Oak.Refilter()
check(#Oak.visible == 2 and Oak.selected == nil, "filter clears hidden selection")
Oak.selected = 1
info[1].isDelisted = true
Oak.OnEvent(nil, "LFG_LIST_SEARCH_RESULT_UPDATED", 1)
check(Oak.selected == nil and #Oak.results == 2, "delist event clears selected result")
local registered, focusCleared = {}, false
Oak.frame = {
    RegisterEvent = function(_, name) registered[name] = true end,
    UnregisterAllEvents = function() wipe(registered) end,
    search = { ClearFocus = function() focusCleared = true end },
}
GameTooltip = { Hide = function() end }
Oak.OnShow()
check(registered.LFG_LIST_SEARCH_RESULT_UPDATED and registered.PLAYER_REGEN_ENABLED, "events active while shown")
Oak.OnHide()
check(registered.LFG_LIST_SEARCH_RESULTS_RECEIVED and registered.LFG_LIST_SEARCH_FAILED
    and not registered.LFG_LIST_SEARCH_RESULT_UPDATED and focusCleared,
    "hidden window retains completion events and clears focus")
local timerCallback, searchCalls = nil, 0
C_Timer = { NewTimer = function(_, callback)
    timerCallback = callback
    return { Cancel = function() timerCallback = nil end }
end }
LFGBrowseFrame = { searching = true, CategoryDropdown = { GetValue = function() return 2 end },
    ActivityDropdown = { selectedValues = {7} } }
C_LFGList.Search = function(category, _, _, _, _, _, activities)
    check(category == 2 and activities[1] == 7, "retry preserves search selection")
    searchCalls = searchCalls + 1
end
Oak.WatchSearch()
timerCallback()
check(Oak.searchTimedOut and not Oak.IsSearching(), "timeout enables manual recovery")
check(LFGBrowseFrame.searching and searchCalls == 0, "timeout neither mutates Blizzard nor auto-searches")
Oak.Search()
Oak.Search()
check(searchCalls == 1 and Oak.IsSearching(), "retry sends once and blocks duplicate requests")
LFGBrowseFrame.searching = false
Oak.OnEvent(nil, "LFG_LIST_SEARCH_FAILED")
check(not Oak.IsSearching() and not Oak.searchTimedOut and not timerCallback, "failure clears retry and timer")
print(string.format("PASS: %d Forever model, action, and lifecycle checks", checks))

