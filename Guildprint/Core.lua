-- Core: saved data, one event frame, slash commands.
local addonName, ns = ...
local Logic = ns.Logic

local HISTORY_DAYS = 7

-- event -> list of handlers; the frame only registers events that have handlers
local frame = CreateFrame("Frame")
local handlers = {}

frame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  for i = #list, 1, -1 do list[i](event, ...) end
end)

function ns.On(event, fn)
  local list = handlers[event]
  if not list then
    list = {}
    handlers[event] = list
    frame:RegisterEvent(event)
  end
  list[#list + 1] = fn
end

function ns.Off(event, fn)
  local list = handlers[event]
  if not list then return end
  for i = #list, 1, -1 do
    if list[i] == fn then table.remove(list, i) end
  end
  if #list == 0 then
    handlers[event] = nil
    frame:UnregisterEvent(event)
  end
end

function ns.Print(msg)
  print("|cffffd200Guildprint|r: " .. msg)
end

ns.slash = {}
-- modules append init functions that need saved data
ns.ready = {}

local function OnLoaded(_, name)
  if name ~= addonName then return end
  GuildprintCharDB = Logic.MergeDefaults(GuildprintCharDB, Logic.DEFAULTS)
  GuildprintDB = GuildprintDB or {}
  GuildprintDB.history = GuildprintDB.history or {}
  GuildprintDB.blocked = GuildprintDB.blocked or {}  -- name -> "declined" | "opt-out", permanent
  GuildprintDB.daily = GuildprintDB.daily or {}
  Logic.PruneHistory(GuildprintDB.history, time(), HISTORY_DAYS)
  -- 0.1.0 stored same-realm names without "-Realm"; keys are now always Name-Realm
  for name, t in pairs(GuildprintDB.history) do
    local key = Logic.FullName(name, GetNormalizedRealmName())
    if key ~= name then
      GuildprintDB.history[name] = nil
      GuildprintDB.history[key] = math.max(t, GuildprintDB.history[key] or 0)
    end
  end
  ns.db = GuildprintCharDB
  ns.history = GuildprintDB.history
  ns.blocked = GuildprintDB.blocked
  ns.daily = GuildprintDB.daily
  ns.HISTORY_DAYS = HISTORY_DAYS
  ns.Off("ADDON_LOADED", OnLoaded)
  for _, fn in ipairs(ns.ready) do fn() end
end
ns.On("ADDON_LOADED", OnLoaded)

function ns.FullName(name)
  return Logic.FullName(name, GetNormalizedRealmName())
end

-- Players this session's invites went to (key: full name). Join/decline messages are matched against it.
ns.invited = {}

-- Every guild invite goes through here. Needs a click or keypress (Blizzard rule).
function ns.Invite(name)
  C_GuildInfo.Invite(name)
  ns.invited[ns.FullName(name)] = true
  if ns.OnInviteSent then ns.OnInviteSent() end
end

-- Key bindings (Bindings.xml) call the slash handlers.
BINDING_NAME_GUILDPRINT_NEXT = "Invite next player"
BINDING_NAME_GUILDPRINT_POST = "Post guild ad"

SLASH_GUILDPRINT1 = "/guildprint"
SLASH_GUILDPRINT2 = "/gp"
SlashCmdList.GUILDPRINT = function(input)
  local sub, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
  sub = sub:lower()
  local fn = ns.slash[sub]
  if fn then
    fn(rest)
  elseif sub == "" then
    ns.OpenWindow()
  else
    ns.Print("Commands: /gp (open window), /gp post (post your ad), /gp next (invite next player)")
  end
end
