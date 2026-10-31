-- What happens after a whisper or invite: replies, opt-outs, declines, joins.
local _, ns = ...
local Logic = ns.Logic

local SendChat = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage

-- Chat payloads are secret during chat messaging lockdown; comparing them would error.
local function Readable(...)
  if not issecretvalue then return true end
  for i = 1, select("#", ...) do
    if issecretvalue((select(i, ...))) then return false end
  end
  return true
end

-- A player we whispered writes back: opt-out blocks them, anything else offers a one-click invite.
local function OnWhisper(_, text, sender)
  if not ns.history or not Readable(text, sender) then return end
  local key = ns.FullName(sender)
  if not ns.history[key] or ns.blocked[key] then return end
  local short = Logic.ShortName(sender)
  if Logic.IsOptOut(text) then
    ns.blocked[key] = "opt-out"
    ns.Print(short .. " isn't interested. Guildprint won't contact them again.")
    return
  end
  if not CanGuildInvite() or ns.invited[key] or C_GuildInfo.MemberExistsByName(sender) then return end
  local quote = #text > 60 and (text:sub(1, 57) .. "...") or text
  ns.ShowPrompt(short .. " replied", '|cffffffff"' .. quote .. '"|r', "Invite", function() ns.Invite(sender) end)
end

-- Blizzard's own message formats, so it works in every client language.
local declinePatterns, joinPattern = {}, nil

local function OnSystem(_, text)
  if not Readable(text) then return end
  for _, p in ipairs(declinePatterns) do
    local name = text:match(p)
    local key = name and ns.FullName(name)
    if key and ns.invited[key] then
      ns.invited[key] = nil
      ns.blocked[key] = "declined"
      ns.Print(Logic.ShortName(name) .. " declined. Guildprint won't contact them again.")
      return
    end
  end
  local name = joinPattern and text:match(joinPattern)
  local key = name and ns.FullName(name)
  if not (key and ns.invited[key]) then return end
  ns.invited[key] = nil
  local welcome = ns.db.welcome
  if Logic.HasText(welcome) and not C_ChatInfo.InChatMessagingLockdown() then
    SendChat(Logic.FillPlaceholders(welcome, (GetGuildInfo("player")), name), "GUILD")
  end
end

-- System messages only matter once we've invited someone this session.
function ns.OnInviteSent()
  ns.OnInviteSent = nil
  for _, fmt in ipairs({ ERR_GUILD_DECLINE_S, ERR_GUILD_DECLINE_AUTO_S }) do
    if fmt then declinePatterns[#declinePatterns + 1] = Logic.FormatToPattern(fmt) end
  end
  joinPattern = ERR_GUILD_JOIN_S and Logic.FormatToPattern(ERR_GUILD_JOIN_S)
  ns.On("CHAT_MSG_SYSTEM", OnSystem)
end

ns.On("CHAT_MSG_WHISPER", OnWhisper)
