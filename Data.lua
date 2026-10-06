local _, Oak = ...

Oak.roles = { "TANK", "HEALER", "DAMAGER" }
Oak.roleKeys = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }
Oak.roleAtlases = {
    TANK = "groupfinder-icon-role-micro-tank",
    HEALER = "groupfinder-icon-role-micro-heal",
    DAMAGER = "groupfinder-icon-role-micro-dps",
}
Oak.classArmor = { WARRIOR="Plate", PALADIN="Plate", DEATHKNIGHT="Plate", HUNTER="Mail", SHAMAN="Mail", ROGUE="Leather", DRUID="Leather", MONK="Leather", DEMONHUNTER="Leather", PRIEST="Cloth", MAGE="Cloth", WARLOCK="Cloth" }

function Oak.ReadResult(id)
    local info = C_LFGList.GetSearchResultInfo(id)
    if not info or info.isDelisted then return end
    local leader = C_LFGList.GetSearchResultLeaderInfo(id)
    local solo = info.numMembers <= 1
    local player = solo and C_LFGList.GetSearchResultPlayerInfo(id, 1) or leader
    local counts = C_LFGList.GetSearchResultMemberCounts(id) or {}
    local activities = {}
    for _, activityID in ipairs(info.activityIDs or {}) do
        local activity = C_LFGList.GetActivityInfoTable(activityID)
        if activity then activities[#activities + 1] = LFGUtil_GetActivityInfoName(activity) end
    end
    local roles = {}
    for _, role in ipairs(Oak.roles) do
        if solo then
            roles[role] = player and player.lfgRoles and player.lfgRoles[Oak.roleKeys[role]] and 1 or 0
        else
            roles[role] = counts[role] or 0
        end
    end
    local style = info.generalPlaystyle and GetGeneralPlaystyleString(info.generalPlaystyle) or ""
    local result = {
        id = id, name = info.leaderName or RETRIEVING_DATA,
        class = player and player.classFilename,
        armor = player and Oak.classArmor[player.classFilename],
        level = solo and player and player.level or 0,
        size = info.numMembers, kind = solo and "Player" or "Group",
        activity = table.concat(activities, ", "), note = info.comment or "",
        style = style or "", age = info.age or 0, roles = roles,
        hasSelf = info.hasSelf, friendly = info.newPlayerFriendly,
    }
    result.searchText = string.lower(table.concat({ result.name, result.activity, result.note, result.style }, " "))
    return result
end

function Oak.Matches(result, filters)
    if not result.hasSelf then
        if filters.kind ~= "All" and filters.kind ~= result.kind then return false end
        if filters.role ~= "ALL" and result.roles[filters.role] == 0 then return false end
        if filters.classes and next(filters.classes) and not filters.classes[result.class] then return false end
        if filters.armor and next(filters.armor) and not filters.armor[result.armor] then return false end
        if filters.friendly and not result.friendly then return false end
        if filters.text ~= "" and not result.searchText:find(string.lower(filters.text), 1, true) then return false end
    end
    return true
end

function Oak.Sort(results, key, descending)
    table.sort(results, function(a, b)
        if a.hasSelf ~= b.hasSelf then return a.hasSelf end
        local av, bv = a[key], b[key]
        if type(av) == "string" then av, bv = string.lower(av), string.lower(bv) end
        if av == bv then return a.id < b.id end
        if descending then return av > bv end
        return av < bv
    end)
end

function Oak.GetActionInfo(id)
    if not id then return end
    local info = C_LFGList.GetSearchResultInfo(id)
    if not info or info.isDelisted or info.hasSelf or not info.leaderName then return end
    return info
end

function Oak.GetInviteAction(id)
    if not Oak.GetActionInfo(id) or InCombatLockdown() or IsInRaid() and GetNumGroupMembers() >= 40
        or not IsInRaid() and GetNumSubgroupMembers() >= 4 then return end
    local _, action = LFGBrowseUtil_GetInviteActionForResult(id)
    return action
end

function Oak.Whisper()
    local info = Oak.GetActionInfo(Oak.selected)
    if info then
        if Oak.db and Oak.db.customWhisper ~= "" then
            ChatFrameUtil.SendTell(info.leaderName, Oak.db.customWhisper)
        else
            ChatFrameUtil.SendTell(info.leaderName)
        end
    end
end

function Oak.Invite()
    local action = Oak.GetInviteAction(Oak.selected)
    if action then action() end
end
