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
  Logic.PruneHistory(GuildprintDB.history, time(), HISTORY_DAYS)
  ns.db = GuildprintCharDB
  ns.history = GuildprintDB.history
  ns.HISTORY_DAYS = HISTORY_DAYS
  ns.Off("ADDON_LOADED", OnLoaded)
  for _, fn in ipairs(ns.ready) do fn() end
end
ns.On("ADDON_LOADED", OnLoaded)

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
    ns.Print("Commands: /gp (open window), /gp post (post your ad)")
  end
end
