-- Posting the ad, the Advertise page, and the zone/city triggers.
local _, ns = ...
local Logic, UI = ns.Logic, ns.UI

local SendChat = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
local DEFAULT_CHANNELS = { "Trade", "General", "LookingForGroup" }

-- Channel posts need a hardware event: call only from a click, keypress or slash command.
function ns.PostAd()
  local db = ns.db
  local text = Logic.ActiveAdText(db)
  if not text then ns.Print("No ad to post. Write one under Messages.") return end
  local ids = Logic.FindChannelIds({ GetChannelList() }, db.channels)
  if #ids == 0 then ns.Print("None of your ad channels are joined here.") return end
  text = Logic.FillPlaceholders(text, (GetGuildInfo("player")))
  local names = {}
  for i, id in ipairs(ids) do
    SendChat(text, "CHANNEL", nil, id)
    local _, name = GetChannelName(id)
    names[i] = name and Logic.ChannelBase(name) or tostring(id)
  end
  ns.Print("Posted to " .. table.concat(names, ", ") .. ".")
end
ns.slash.post = ns.PostAd

-- Forever's capital map IDs are unconfirmed, so a joined Trade channel also counts as "in a city".
local function InCity()
  if Logic.IsCapital(C_Map.GetBestMapForUnit("player")) then return true end
  return #Logic.FindChannelIds({ GetChannelList() }, { Trade = true }) > 0
end

local function CheckZone()
  local db = ns.db
  local city = InCity()
  if not ((city and db.triggers.city) or (not city and db.triggers.zone)) then return end
  local blocked = InCombatLockdown() or (IsInInstance())
  if not Logic.ShouldPrompt(time(), db.lastPromptAt, db.cooldownMin, blocked) then return end
  if not Logic.ActiveAdText(db) then return end
  db.lastPromptAt = time()
  local ad = db.ads[db.activeAd]
  ns.ShowPrompt("Welcome to |cffffd200" .. GetZoneText() .. "|r",
    'Post "' .. (ad and ad.name or "") .. '" to your ad channels?', "Post Ad", ns.PostAd)
end

-- The client joins/leaves Trade a moment after the zone change, so look a little later.
local function OnZone()
  C_Timer.After(3, CheckZone)
end

-- The zone event is only registered while a trigger is on.
function ns.UpdateTriggers()
  ns.Off("ZONE_CHANGED_NEW_AREA", OnZone)
  if ns.db.triggers.city or ns.db.triggers.zone then ns.On("ZONE_CHANGED_NEW_AREA", OnZone) end
end
tinsert(ns.ready, ns.UpdateTriggers)

ns.RegisterPage("advertise", "Advertise", "Recruiting", function(f)
  local db = ns.db

  UI.Place(UI.Header(f, "Advertise"), f, 4, -4)
  local active = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontNormal"), f, 4, -40)
  local change = UI.Button(f, "Change", 90)
  change:SetPoint("LEFT", active, "LEFT", 360, 0)
  change:SetScript("OnClick", function() ns.OpenWindow("messages") end)

  UI.Place(UI.Header(f, "Auto-Prompt"), f, 4, -74)
  local checks = {
    UI.Place(UI.Check(f, "Entering a capital city", function() return db.triggers.city end,
      function(v) db.triggers.city = v; ns.UpdateTriggers() end), f, 4, -106),
    UI.Place(UI.Check(f, "Entering a new zone", function() return db.triggers.zone end,
      function(v) db.triggers.zone = v; ns.UpdateTriggers() end), f, 4, -136),
  }
  local coolLabel = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"), f, 22, -174)
  coolLabel:SetText("Minimum time between prompts")
  local slider = UI.Slider(f, 5, 60, 5, function() return db.cooldownMin end,
    function(v) db.cooldownMin = v end, function(v) return v .. " min" end)
  slider:SetPoint("LEFT", coolLabel, "LEFT", 222, 0)

  UI.Place(UI.Header(f, "Channels"), f, 4, -206)
  local channelRows = {}

  local post = UI.Button(f, "Post Ad Now", 150, true)
  post:SetPoint("BOTTOMRIGHT", -4, 4)
  post:SetScript("OnClick", ns.PostAd)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 4, 10)
  hint:SetText("Channel posts need one click (Blizzard rule).")

  -- Default channels plus any other channel joined right now.
  local function ChannelNames()
    local names, seen = {}, {}
    for _, n in ipairs(DEFAULT_CHANNELS) do names[#names + 1] = n; seen[n] = true end
    local list = { GetChannelList() }
    for i = 2, #list, 3 do
      local base = Logic.ChannelBase(list[i])
      if not seen[base] then names[#names + 1] = base; seen[base] = true end
    end
    for n, on in pairs(db.channels) do
      if on and not seen[n] then names[#names + 1] = n; seen[n] = true end
    end
    return names
  end

  f:SetScript("OnShow", function()
    local ad = db.ads[db.activeAd]
    active:SetText("Active ad:  |cffffffff" .. (ad and ad.name or "none") .. "|r")
    for _, c in ipairs(checks) do c:Refresh() end
    local names = ChannelNames()
    for i, name in ipairs(names) do
      local row = channelRows[i]
      if not row then
        row = UI.Check(f, "", function() return db.channels[row.channel] end,
          function(v) db.channels[row.channel] = v end)
        UI.Place(row, f, 4 + ((i - 1) % 2) * 300, -238 - math.floor((i - 1) / 2) * 30)
        channelRows[i] = row
      end
      row.channel = name
      row.label:SetText(name)
      row:Show()
      row:Refresh()
    end
    for i = #names + 1, #channelRows do channelRows[i]:Hide() end
  end)
end)
