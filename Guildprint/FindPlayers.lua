-- Find unguilded players with /who, then whisper them in a slow trickle or invite them one click at a time.
local _, ns = ...
local Logic, UI = ns.Logic, ns.UI

local SendChat = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
local QUEUE_INTERVAL = 3
local DAILY_WHISPERS = 100  -- account-wide, keeps a recruiter clear of spam reports
local WHO_CAP = 50
local ROW_H = 22

local queue, queueKind, queuePos, ticker
local page   -- set when the page is built; queue updates its progress text

local function StopQueue()
  if ticker then ticker:Cancel(); ticker = nil end
  queue = nil
  if page then page:UpdateQueue() end
end

local function SendNext()
  if not queue then return end
  if queueKind == "whisper" and C_ChatInfo.InChatMessagingLockdown() then return end  -- retry next tick
  -- skip players who declined/opted out (or got an invite) since the list was built
  local name, key
  repeat
    queuePos = queuePos + 1
    name = queue[queuePos]
    key = name and ns.FullName(name)
  until not name or not (ns.blocked[key] or (queueKind == "invite" and ns.invited[key]))
  if not name then StopQueue() return end
  if queueKind == "whisper" then
    if not Logic.TakeDaily(ns.daily, date("%Y-%m-%d"), DAILY_WHISPERS) then
      ns.Print("Daily limit of " .. DAILY_WHISPERS .. " whispers reached. More tomorrow.")
      StopQueue()
      return
    end
    SendChat(Logic.FillPlaceholders(ns.db.whisper, (GetGuildInfo("player")), name), "WHISPER", nil, name)
    ns.history[key] = time()
  else
    ns.Invite(name)
  end
  if page then page:UpdateQueue() end
  if queuePos >= #queue then StopQueue() end
end

-- Invites need a click or keypress each (Blizzard rule): button, key binding or /gp next.
function ns.InviteNext()
  if queueKind == "invite" and queue then SendNext() else ns.Print("No invites queued. Use Invite selected in Find Players.") end
end
ns.slash.next = ns.InviteNext

-- names: list of "Name-Realm"; kind: "whisper" or "invite"
function ns.QueueSend(names, kind)
  if queue then ns.Print("Already sending. Press Stop first.") return end
  if kind == "whisper" and not Logic.HasText(ns.db.whisper) then
    ns.Print("Your whisper text is empty. Write it under Whisper.") return
  end
  if kind == "invite" and not CanGuildInvite() then ns.Print("Your guild rank can't invite.") return end
  local now, fresh = time(), {}
  for _, n in ipairs(names) do
    local key = ns.FullName(n)
    -- never re-whisper someone inside the history window, even if still ticked
    local skip = kind == "whisper" and Logic.IsRecent(ns.history, key, now, ns.HISTORY_DAYS)
      or kind == "invite" and ns.invited[key]
    if not ns.blocked[key] and not skip then
      fresh[#fresh + 1] = n
    end
  end
  names = fresh
  if #names == 0 then ns.Print("Nobody new to send to.") return end
  queue, queueKind, queuePos = names, kind, 0
  if kind == "invite" then
    ns.Print("Press Invite next, your Guildprint key binding or /gp next for each invite.")
    if page then page:UpdateQueue() end
    return
  end
  SendNext()
  if queue then ticker = C_Timer.NewTicker(QUEUE_INTERVAL, SendNext) end
end

ns.RegisterPage("find", "Find Players", "Recruiting", function(f)
  page = f
  local db = ns.db
  local rows, results = {}, {}

  UI.Place(UI.Header(f, "Find Players"), f, 4, -4)
  local lvl = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontNormal"), f, 4, -42)
  lvl:SetText("Level")
  local minEdit = UI.Edit(f, 40, 2)
  minEdit:SetPoint("LEFT", lvl, "RIGHT", 12, 0)
  minEdit:SetNumeric(true)
  local to = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  to:SetPoint("LEFT", minEdit, "RIGHT", 8, 0)
  to:SetText("to")
  local maxEdit = UI.Edit(f, 40, 2)
  maxEdit:SetPoint("LEFT", to, "RIGHT", 12, 0)
  maxEdit:SetNumeric(true)
  local search = UI.Button(f, "Search", 100)
  search:SetPoint("LEFT", maxEdit, "RIGHT", 14, 0)
  local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  status:SetPoint("LEFT", search, "RIGHT", 12, 0)
  status:SetPoint("RIGHT", f, "RIGHT", -4, 0)
  status:SetJustifyH("LEFT")

  -- column headers
  local cols = { { "Name", 30 }, { "Lvl", 190 }, { "Class", 230 }, { "Zone", 340 } }
  for _, c in ipairs(cols) do
    local h = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"), f, c[2], -74)
    h:SetText(c[1])
  end

  local scroll = CreateFrame("ScrollFrame", nil, f, "ScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -90)
  scroll:SetPoint("BOTTOMRIGHT", -22, 44)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(1, 1)
  scroll:SetScrollChild(child)

  local whisperBtn = UI.Button(f, "Whisper selected", 170, true)
  whisperBtn:SetPoint("BOTTOMRIGHT", -4, 6)
  local inviteBtn = UI.Button(f, "Invite selected", 140)
  inviteBtn:SetPoint("RIGHT", whisperBtn, "LEFT", -6, 0)
  local stopBtn = UI.Button(f, "Stop", 80)
  stopBtn:SetPoint("BOTTOMLEFT", 4, 6)
  stopBtn:SetScript("OnClick", StopQueue)
  local progress = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  progress:SetPoint("LEFT", stopBtn, "RIGHT", 10, 0)

  local split  -- {level, last} while a capped search is walked one level per click

  local function SearchLabel()
    search:SetText(split and ("Search level " .. split.level) or "Search")
  end

  local function Selected()
    local names = {}
    for _, r in ipairs(results) do
      if r.selected then names[#names + 1] = r.target end
    end
    return names
  end

  function f:UpdateQueue()
    local running = queue ~= nil
    local inviting = running and queueKind == "invite"
    stopBtn:SetShown(running)
    progress:SetShown(running)
    if running then progress:SetText(queuePos .. " / " .. #queue) end
    local n = #Selected()
    whisperBtn:SetText("Whisper selected (" .. n .. ")")
    whisperBtn:SetEnabled(not running and n > 0)
    if inviting then
      inviteBtn:SetText("Invite next (" .. (#queue - queuePos) .. " left)")
      inviteBtn:SetEnabled(true)
    else
      inviteBtn:SetText("Invite selected")
      inviteBtn:SetEnabled(not running and n > 0 and CanGuildInvite())
    end
  end

  local function Row(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Frame", nil, child)
    row:SetSize(560, ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row.box = CreateFrame("CheckButton", nil, row)
    row.box:SetSize(22, 22)
    row.box:SetPoint("LEFT", 2, 0)
    row.box:SetNormalAtlas("checkbox-minimal")
    row.box:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.box:GetCheckedTexture():SetAtlas("checkmark-minimal")
    row.box:SetScript("OnClick", function(self)
      results[i].selected = self:GetChecked()
      f:UpdateQueue()
    end)
    row.cells = {}
    for c, col in ipairs(cols) do
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", col[2], 0)
      fs:SetWidth(c == 4 and 220 or (cols[c + 1][2] - col[2] - 6))
      fs:SetJustifyH("LEFT")
      fs:SetWordWrap(false)
      row.cells[c] = fs
    end
    rows[i] = row
    return row
  end

  local function ShowResults()
    local now = time()
    for i, r in ipairs(results) do
      local row = Row(i)
      row.box:SetChecked(r.selected)
      local color = r.classFile and C_ClassColor.GetClassColor(r.classFile)
      local name = r.name:match("^[^-]+")
      row.cells[1]:SetText(r.recent and ("|cff808080" .. name .. "|r") or (color and color:WrapTextInColorCode(name) or name))
      row.cells[2]:SetText(r.level)
      row.cells[3]:SetText(r.class)
      if r.recent then
        row.cells[4]:SetText("|cff808080whispered " .. math.floor((now - ns.history[r.name]) / 86400) .. "d ago|r")
      else
        row.cells[4]:SetText(r.zone)
      end
      row:Show()
    end
    for i = #results + 1, #rows do rows[i]:Hide() end
    child:SetSize(560, #results * ROW_H)
    f:UpdateQueue()
  end

  local function OnWho()
    ns.Off("WHO_LIST_UPDATE", OnWho)
    C_FriendList.SetWhoToUi(false)  -- the player's own /who goes back to chat
    local num, total = C_FriendList.GetNumWhoResults()
    local raw, seen = {}, {}
    if split then
      for _, r in ipairs(results) do seen[r.name] = true end
    end
    for i = 1, num do
      local info = C_FriendList.GetWhoInfo(i)
      if info then
        local name = ns.FullName(info.fullName)
        if not seen[name] then
          raw[#raw + 1] = {
            name = name, target = info.fullName, guild = info.fullGuildName or "",
            level = info.level, class = info.classStr, classFile = info.filename, zone = info.area,
          }
        end
      end
    end
    local found = Logic.FilterWho(raw, ns.history, ns.blocked, time(), ns.HISTORY_DAYS)
    local note = ""
    if split then
      for _, r in ipairs(found) do results[#results + 1] = r end
      if total >= WHO_CAP then note = " Level " .. split.level .. " alone has over " .. WHO_CAP .. "." end
      split.level = split.level + 1
      if split.level > split.last then split = nil end
      if split then note = note .. " Click Search level " .. split.level .. " for more." end
    else
      results = found
      local lo, hi = tonumber(db.minLevel), tonumber(db.maxLevel)
      if total >= WHO_CAP and lo < hi then
        -- /who stops at 50: walk the range one level per click (each /who needs a click)
        split = { level = lo, last = hi }
        note = " /who stops at " .. WHO_CAP .. ". Click Search level " .. lo .. " to go level by level."
      elseif total >= WHO_CAP then
        note = " Showing first " .. WHO_CAP .. "."
      end
    end
    SearchLabel()
    status:SetText(#results .. " without a guild." .. note)
    ShowResults()
  end

  -- /who needs a hardware event: this click provides it.
  search:SetScript("OnClick", function()
    local query
    if split then
      query = split.level .. "-" .. split.level
    else
      query = Logic.WhoQuery(minEdit:GetText(), maxEdit:GetText())
      if not query then
        status:SetText("|cffff4040Enter levels 1-60, lowest first.|r")
        return
      end
      db.minLevel, db.maxLevel = tonumber(minEdit:GetText()), tonumber(maxEdit:GetText())
    end
    status:SetText("Searching...")
    C_FriendList.SetWhoToUi(true)
    ns.Off("WHO_LIST_UPDATE", OnWho)
    ns.On("WHO_LIST_UPDATE", OnWho)
    C_FriendList.SendWho(query, Enum.SocialWhoOrigin.Unknown)
  end)

  -- editing the range starts a fresh search
  local function ResetSplit(_, user) if user and split then split = nil; SearchLabel() end end
  minEdit:SetScript("OnTextChanged", ResetSplit)
  maxEdit:SetScript("OnTextChanged", ResetSplit)

  whisperBtn:SetScript("OnClick", function() ns.QueueSend(Selected(), "whisper") end)
  inviteBtn:SetScript("OnClick", function()
    if queue and queueKind == "invite" then ns.InviteNext() else ns.QueueSend(Selected(), "invite") end
  end)

  f:SetScript("OnShow", function()
    minEdit:SetText(db.minLevel)
    maxEdit:SetText(db.maxLevel)
    f:UpdateQueue()
  end)
  minEdit:SetText(db.minLevel)
  maxEdit:SetText(db.maxLevel)
  f:UpdateQueue()
end)
