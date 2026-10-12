local Oak, checks = {}, 0
local function check(value, label) assert(value, label); checks = checks + 1 end
local function noop() end
local methods = {}
for _, key in ipairs({ "SetFont", "SetJustifyH", "SetWordWrap", "SetAllPoints", "SetColorTexture", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetVertexColor", "SetFrameStrata", "SetToplevel", "SetMovable", "SetClampedToScreen", "EnableMouse", "SetTitle", "SetTexture", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "ClearAllPoints", "SetAutoFocus", "SetMaxLetters", "ClearFocus", "EnableMouseWheel", "SetValueStep", "SetObeyStepOnDrag", "SetAtlas", "SetAlpha" }) do methods[key] = noop end
local function object()
    return setmetatable({ scripts = {}, events = {}, shown = true, text = "", enabled = true }, { __index = methods })
end
function methods:SetPoint(...) self.point = {...} end
function methods:GetPoint() return unpack(self.point or {"CENTER", UIParent, "CENTER", 0, 0}) end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:SetScale(scale) self.scale=scale end
function methods:SetScript(key, callback) self.scripts[key]=callback end
function methods:HookScript(key, callback)
    local old=self.scripts[key]
    self.scripts[key]=function(...) if old then old(...) end; callback(...) end
end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:Show()
    local was=self.shown; self.shown=true
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local was=self.shown; self.shown=false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetEnabled(value) self.enabled=value end
function methods:SetText(value)
    self.text=tostring(value)
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text end
function methods:SetTextColor(...) self.color={...} end
function methods:SetJustifyH(value) self.justifyH=value end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
function methods:SetHighlightTexture() self.highlight=object() end
function methods:GetHighlightTexture() return self.highlight end
function methods:SetMinMaxValues(a,b) self.min,self.max=a,b end
function methods:SetValue(value)
    if self.value==value then return end
    self.value=value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
local loader
CreateFrame=function(kind,name,parent,template)
    local frame=object()
    if template=="PortraitFrameTemplate" then
        frame.CloseButton,frame.TitleText,frame.Bg,frame.Inset,frame.TopTileStreaks=object(),object(),object(),object(),object()
        frame.PortraitContainer={portrait=object()}
    end
    if not loader then loader=frame end
    return frame
end
UIParent=object()
UISpecialFrames={}
StaticPopupDialogs={}
tinsert=table.insert
wipe=function(t) for k in pairs(t) do t[k]=nil end end
SlashCmdList={}
RAID_CLASS_COLORS={ DRUID={r=1,g=0.5,b=0} }
InCombatLockdown=function() return false end
IsInRaid=function() return false end
GetNumSubgroupMembers=function() return 0 end
C_AddOns={IsAddOnLoaded=function() return true end}
C_LFGList={
    GetFilteredSearchResults=function() return 0,{} end,
    GetSearchResultInfo=function() return nil end,
    HasActiveEntryInfo=function() return false end,
    RequestAvailableActivities=noop,
    GetAvailableCategories=function() return {2} end,
    GetLfgCategoryInfo=function() return {name="Dungeons"} end,
    GetActivityInfoTable=function() return {name="Blackfathom Deeps"} end,
}
LFGUtil_GetFilteredActivities=function() return {7} end
LFGUtil_GetActivityInfoName=function(info) return info.name end
LFGBrowseUtil_GetInviteActionForResult=function() return "Invite",nil end
LFGBrowseFrame=object()
LFGBrowseFrame.CategoryDropdown={GetValue=function() return 0 end}
LFGBrowseFrame.ActivityDropdown={selectedValues={}}
LFGBrowseFrame.UpdateResults=noop
LFGBrowse_DoSearch=noop
GameTooltip={Hide=noop}
hooksecurefunc=function(target,key,callback)
    if type(target)=="string" then callback=key; key=target; target=_G end
    local old=target[key]
    target[key]=function(...) local result=old(...); callback(...); return result end
end
local menuItems={}
local menu={}
function menu:CreateTitle() end
function menu:SetScrollMode() end
function menu:CreateButton(label,callback) menuItems[label]=callback; return self end
function menu:CreateCheckbox(label,selected,callback) menuItems[label]=callback; return self end
function menu:CreateRadio(label,selected,callback) menuItems[label]=callback; return self end
MenuUtil={CreateContextMenu=function(owner, callback) callback(owner,menu) end}
GetCVarBool=function() return false end
for _,name in ipairs({"Data","UI","Core"}) do
    assert(loadfile(""..name..".lua"))("OakLFGSorterForever",Oak)
end
loader.scripts.OnEvent(loader,"ADDON_LOADED","OakLFGSorterForever")
check(Oak.frame==nil,"lazy login")
SlashCmdList.OAKLFGFOREVER("")
check(Oak.frame and Oak.frame:IsShown(),"slash builds and opens UI")
check(#Oak.frame.rows==9,"fixed nine-row pool")
check(Oak.frame.width==660 and Oak.frame.height==484,"compact frame dimensions")
LFGBrowseFrame.ActivityDropdown.selectedValues = {7}
Oak.Render()
check(not Oak.frame.headers.activity:IsShown() and not Oak.frame.rows[1].fields.activity:IsShown(), "single activity hides header and row field")
check(Oak.frame.headers.note.width == 213 and Oak.frame.headers.age.width == 36, "single activity expands notes without resizing age")
check(Oak.frame.rows[1].fields.zone.justifyH == "CENTER" and Oak.frame.rows[1].fields.name.justifyH == "LEFT"
    and Oak.frame.rows[1].fields.note.justifyH == "LEFT", "zone centered and free text left aligned")
LFGBrowseFrame.ActivityDropdown.selectedValues = {7, 8}
Oak.Render()
check(Oak.frame.headers.activity:IsShown() and Oak.frame.rows[1].fields.activity:IsShown()
    and Oak.frame.headers.note.width == 97, "multiple activities restore column and note width")
check(Oak.frame.headers.note.point[2] + Oak.frame.headers.note.width == 636, "columns retain original right edge")
LFGBrowseFrame.ActivityDropdown.selectedValues = {}
Oak.Render()
check(Oak.frame.headers.activity:IsShown(), "all activities retains activity column")
check(not Oak.frame.whisper.enabled and not Oak.frame.invite.enabled,"empty selection disables actions")
check(Oak.frame.empty.text:find("Choose a category",1,true),"initial empty state")
check(Oak.frame.events.LFG_LIST_SEARCH_RESULTS_RECEIVED,"visible events registered")
Oak.ShowOptions(Oak.frame)
check(menuItems["Open with Blizzard's browser"]~=nil,"options menu constructed")
Oak.ShowCategoryMenu(Oak.frame)
check(menuItems.Dungeons~=nil,"native categories available")
Oak.ShowZoneMenu(Oak.frame.zone)
check(menuItems["All zones"] and menuItems["My zone"], "zone menu constructed")
menuItems["My zone"]()
check(Oak.filters.myZone and Oak.frame.zone.label.text == "My zone", "my zone selection updates control")
menuItems["All zones"]()
check(not Oak.filters.myZone and not Oak.filters.zone, "all zones clears location filter")
Oak.ShowClassArmor()
local classPanel = Oak.classArmorPanel
local druid = classPanel.classChecks.DRUID
druid:SetChecked(true)
druid.scripts.OnClick(druid)
check(Oak.filters.classes.DRUID, "class checkbox updates filter")
local leather = classPanel.armorChecks.Leather
leather:SetChecked(true)
leather.scripts.OnClick(leather)
check(Oak.filters.armor.Leather, "armor checkbox updates filter")
wipe(Oak.filters.classes)
wipe(Oak.filters.armor)
Oak.Refilter()
check(not druid:GetChecked() and not leather:GetChecked(), "cleared filters reset visible checkmarks")
classPanel:Hide()
Oak.filters.classes.DRUID = true
Oak.ShowClassArmor()
check(classPanel == Oak.classArmorPanel and druid:GetChecked(), "reopening reused panel synchronizes filters")
wipe(Oak.filters.classes)
classPanel:Hide()
Oak.results={}
for index=1,20 do
    Oak.results[index]={id=index,name="Player"..index,kind="Player",class="DRUID",level=25,
        activity="Blackfathom Deeps",zone="Ashenvale",note="",style="Relaxed",age=30,roles={TANK=1,HEALER=0,DAMAGER=1},hasSelf=false,searchText="player"}
end
Oak.Refilter()
check(Oak.frame.rows[1].fields.name.text=="Player1","row binding")
check(Oak.frame.rows[1].fields.zone.text == "Ashenvale", "zone column binding")
Oak.ShowZoneMenu(Oak.frame.zone)
check(menuItems.Ashenvale ~= nil, "zone menu includes loaded locations")
check(Oak.frame.scroll:IsShown() and Oak.frame.scroll.max==11,"scroll range")
Oak.frame.scripts.OnMouseWheel(Oak.frame,-1)
check(Oak.offset==3,"mouse wheel advances pooled list")
Oak.frame.search:SetText("nonmatching")
check(#Oak.visible==0 and Oak.frame.empty:IsShown(),"text filter redraw")
LFGBrowseFrame.searching=true
Oak.Render()
check(not Oak.frame.category.enabled and not Oak.frame.refresh.enabled,"search disables repeated requests")
Oak.searchTimedOut=true
Oak.Render()
check(Oak.frame.refresh.label.text == "Retry" and Oak.frame.status.text:find("timed out",1,true),
    "stalled search offers visible recovery")
Oak.searchTimedOut=nil
LFGBrowseFrame.searching=false
LFGBrowseFrame.searchFailed=true
Oak.Render()
check(Oak.frame.status.text:find("Search failed",1,true),"search failure state")
SlashCmdList.OAKLFGFOREVER("")
check(not Oak.frame:IsShown() and Oak.frame.events.LFG_LIST_SEARCH_RESULTS_RECEIVED
    and not Oak.frame.events.GROUP_ROSTER_UPDATE,"slash closes but retains search completion events")
print(string.format("PASS: %d UI startup, menu, scrolling, and state checks (mock frames)",checks))

