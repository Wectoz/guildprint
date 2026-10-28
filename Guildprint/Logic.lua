-- Pure recruiting logic: no WoW API, unit-tested with tests/run.lua.
local _, ns = ...
local Logic = {}
ns.Logic = Logic

local MAX_MSG = 255
local DAY = 86400

Logic.DEFAULTS = {
  ads = { { name = "Main ad", text = "{guild} is recruiting all levels! /w me for an invite." } },
  activeAd = 1,
  channels = { Trade = true, General = true, LookingForGroup = false },
  triggers = { city = true, zone = true },
  cooldownMin = 15,
  whisper = "Hi! {guild} is recruiting, want an invite?",
  minLevel = 1,
  maxLevel = 60,
  lastPromptAt = 0,
}

local function copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = copy(v) end
  return c
end

function Logic.MergeDefaults(db, defaults)
  db = db or {}
  for k, v in pairs(defaults) do
    if db[k] == nil then
      db[k] = copy(v)
    elseif type(v) == "table" and type(db[k]) == "table" and v[1] == nil then
      -- keyed tables merge; arrays (like ads) are the user's and stay as-is
      Logic.MergeDefaults(db[k], v)
    end
  end
  return db
end

function Logic.HasText(s)
  return type(s) == "string" and s:find("%S") ~= nil
end

-- Chat strips newlines, so they become spaces. The 255 limit is in bytes: never cut a UTF-8 char.
function Logic.FillPlaceholders(text, guildName)
  local out = text:gsub("{guild}", function() return guildName or "our guild" end):gsub("\r?\n", " ")
  if #out <= MAX_MSG then return out end
  out = out:sub(1, MAX_MSG + 1)
  -- back off to the start of the character that straddles the limit
  local cut = MAX_MSG + 1
  while cut > 1 and out:byte(cut) >= 128 and out:byte(cut) < 192 do cut = cut - 1 end
  return out:sub(1, cut - 1)
end

function Logic.ActiveAdText(db)
  local ad = db.ads[db.activeAd]
  if ad and Logic.HasText(ad.text) then return ad.text end
  return nil
end

function Logic.ShouldPrompt(now, lastPromptAt, cooldownMin, blocked)
  return not blocked and now - lastPromptAt >= cooldownMin * 60
end

-- "General - Durotar" -> "General"
function Logic.ChannelBase(name)
  return name:match("^(.-) %- ") or name
end

-- list is the flat GetChannelList() result: id, name, disabled, id, name, disabled, ...
function Logic.FindChannelIds(list, enabled)
  local ids = {}
  for i = 1, #list, 3 do
    local id, name, disabled = list[i], list[i + 1], list[i + 2]
    local base = name and Logic.ChannelBase(name)
    if base and enabled[base] and not disabled then ids[#ids + 1] = id end
  end
  return ids
end

function Logic.WhoQuery(minLevel, maxLevel)
  local lo, hi = tonumber(minLevel), tonumber(maxLevel)
  if not lo or not hi or lo % 1 ~= 0 or hi % 1 ~= 0 then return nil end
  if lo < 1 or hi > 60 or lo > hi then return nil end
  return lo .. "-" .. hi
end

function Logic.PruneHistory(history, now, days)
  local cutoff = now - days * DAY
  for name, t in pairs(history) do
    if t < cutoff then history[name] = nil end
  end
end

function Logic.IsRecent(history, name, now, days)
  local t = history[name]
  return t ~= nil and t >= now - days * DAY
end

function Logic.FilterWho(results, history, now, days)
  local rows = {}
  for _, r in ipairs(results) do
    if r.guild == "" then
      r.recent = Logic.IsRecent(history, r.name, now, days)
      r.selected = not r.recent
      rows[#rows + 1] = r
    end
  end
  return rows
end

-- uiMapIDs: Classic-era (1453-1458) and retail (84-90) numbering; Forever's is unconfirmed
Logic.CAPITALS = {
  [1453] = true, [1454] = true, [1455] = true, [1456] = true, [1457] = true, [1458] = true,
  [84] = true, [85] = true, [87] = true, [88] = true, [89] = true, [90] = true,
}

function Logic.IsCapital(mapID)
  return Logic.CAPITALS[mapID] == true
end
