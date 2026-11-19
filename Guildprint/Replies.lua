-- What happens after a whisper or invite: replies, opt-outs, declines, joins.
local _, ns = ...
local Logic = ns.Logic

local SendChat = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage

-- A player we whispered writes back: opt-out blocks them, anything else offers their /ginvite line.
local function OnWhisper(_, text, sender)
  if not ns.history or not ns.Readable(text, sender) then return end
  local key = ns.FullName(sender)
  if not ns.history[key] or ns.blocked[key] then return end
  local short = Logic.ShortName(sender)
  if Logic.IsOptOut(text) then
    ns.blocked[key] = "opt-out"
    ns.HidePrompt(key)
    ns.Print(short .. " isn't interested. Guildprint won't contact them again.")
    return
  end
  if not CanGuildInvite() or ns.invited[key:lower()] or C_GuildInfo.MemberExistsByName(sender) then return end
  -- the popup line has a fixed width and no wrap, so the client shortens long replies itself
  ns.PromptInvite(sender, short .. " replied", '|cffffffff"' .. text .. '"|r')
end

-- Blizzard's own message formats, so it works in every client language.
local declinePatterns, joinPattern, notFoundPattern = {}, nil, nil

local function OnSystem(_, text)
  if not ns.Readable(text) then return end
  text = Logic.PlainName(text)
  -- an invite that reached nobody is not an invite: they stay contactable
  local missing = notFoundPattern and text:match(notFoundPattern)
  if missing then ns.invited[ns.FullName(missing):lower()] = nil return end
  for _, p in ipairs(declinePatterns) do
    local name = text:match(p)
    local key = name and ns.FullName(name)
    if key and ns.invited[key:lower()] then
      ns.invited[key:lower()] = nil
      ns.blocked[key] = "declined"
      ns.Print(Logic.ShortName(name) .. " declined. Guildprint won't contact them again.")
      return
    end
  end
  local name = joinPattern and text:match(joinPattern)
  local key = name and ns.FullName(name)
  if not (key and ns.invited[key:lower()]) then return end
  ns.invited[key:lower()] = nil
  local welcome = ns.db.welcome
  if not Logic.HasText(welcome) then return end
  -- Forever blocks guild chat sent from an event, so the welcome goes out on a click
  local msg = Logic.FillPlaceholders(welcome, (GetGuildInfo("player")), name)
  ns.ShowPrompt({ title = Logic.ShortName(name) .. " joined", line = "|cffffffff" .. msg .. "|r", action = "Welcome",
    onAction = function()
      if C_ChatInfo.InChatMessagingLockdown() then ns.Print("Chat is locked right now. Welcome not sent.") return end
      SendChat(msg, "GUILD")
    end })
end

-- System messages only matter once someone has been invited this session.
function ns.OnInviteSent()
  ns.OnInviteSent = nil
  for _, fmt in ipairs({ ERR_GUILD_DECLINE_S, ERR_GUILD_DECLINE_AUTO_S }) do
    if fmt then declinePatterns[#declinePatterns + 1] = Logic.FormatToPattern(fmt) end
  end
  joinPattern = ERR_GUILD_JOIN_S and Logic.FormatToPattern(ERR_GUILD_JOIN_S)
  notFoundPattern = ERR_GUILD_PLAYER_NOT_FOUND_S and Logic.FormatToPattern(ERR_GUILD_PLAYER_NOT_FOUND_S)
  ns.On("CHAT_MSG_SYSTEM", OnSystem)
end

ns.On("CHAT_MSG_WHISPER", OnWhisper)
