-- Find unguilded players with /who, then whisper or invite them in a slow trickle.
local _, ns = ...
local Logic, UI = ns.Logic, ns.UI

local SendChat = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
local QUEUE_INTERVAL = 3
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
  queuePos = queuePos + 1
  local name = queue[queuePos]
  if not name then StopQueue() return end
  if queueKind == "whisper" then
    SendChat(Logic.FillPlaceholders(ns.db.whisper, (GetGuildInfo("player"))), "WHISPER", nil, name)
    ns.history[name] = time()
  else
    C_GuildInfo.Invite(name)
  end
  if page then page:UpdateQueue() end
  if queuePos >= #queue then StopQueue() end
end

-- names: list of "Name-Realm"; kind: "whisper" or "invite"
function ns.QueueSend(names, kind)
  if queue then ns.Print("Already sending. Press Stop first.") return end
  if kind == "whisper" and not Logic.HasText(ns.db.whisper) then
    ns.Print("Your whisper text is empty. Write it under Whisper.") return
  end
  if kind == "whisper" then
    -- never re-whisper someone inside the history window, even if still ticked
    local now, fresh = time(), {}
    for _, n in ipairs(names) do
      if not Logic.IsRecent(ns.history, n, now, ns.HISTORY_DAYS) then fresh[#fresh + 1] = n end
    end
    names = fresh
  end
  if #names == 0 then ns.Print("Nobody new to send to.") return end
  queue, queueKind, queuePos = names, kind, 0
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

  local function Selected()
    local names = {}
    for _, r in ipairs(results) do
      if r.selected then names[#names + 1] = r.name end
    end
    return names
  end

  function f:UpdateQueue()
    local running = queue ~= nil
    stopBtn:SetShown(running)
    progress:SetShown(running)
    if running then progress:SetText(queuePos .. " / " .. #queue) end
    local n = #Selected()
    whisperBtn:SetText("Whisper selected (" .. n .. ")")
    whisperBtn:SetEnabled(not running and n > 0)
    inviteBtn:SetEnabled(not running and n > 0 and CanGuildInvite())
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
    local raw = {}
    for i = 1, num do
      local info = C_FriendList.GetWhoInfo(i)
      if info then
        raw[#raw + 1] = {
          name = info.fullName, guild = info.fullGuildName or "",
          level = info.level, class = info.classStr, classFile = info.filename, zone = info.area,
        }
      end
    end
    results = Logic.FilterWho(raw, ns.history, time(), ns.HISTORY_DAYS)
    if total >= WHO_CAP then
      status:SetText(#results .. " without a guild. Showing first " .. WHO_CAP .. ", narrow the level range.")
    else
      status:SetText(#results .. " without a guild.")
    end
    ShowResults()
  end

  -- /who needs a hardware event: this click provides it.
  search:SetScript("OnClick", function()
    local query = Logic.WhoQuery(minEdit:GetText(), maxEdit:GetText())
    if not query then
      status:SetText("|cffff4040Enter levels 1-60, lowest first.|r")
      return
    end
    db.minLevel, db.maxLevel = tonumber(minEdit:GetText()), tonumber(maxEdit:GetText())
    status:SetText("Searching...")
    C_FriendList.SetWhoToUi(true)
    ns.Off("WHO_LIST_UPDATE", OnWho)
    ns.On("WHO_LIST_UPDATE", OnWho)
    C_FriendList.SendWho(query, Enum.SocialWhoOrigin.Unknown)
  end)

  whisperBtn:SetScript("OnClick", function() ns.QueueSend(Selected(), "whisper") end)
  inviteBtn:SetScript("OnClick", function() ns.QueueSend(Selected(), "invite") end)

  f:SetScript("OnShow", function()
    minEdit:SetText(db.minLevel)
    maxEdit:SetText(db.maxLevel)
    f:UpdateQueue()
  end)
  minEdit:SetText(db.minLevel)
  maxEdit:SetText(db.maxLevel)
  f:UpdateQueue()
end)
