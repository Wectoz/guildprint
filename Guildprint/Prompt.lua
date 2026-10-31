-- One-click popup: "post your ad?" on zone entry, "invite?" when a whispered player replies.
local _, ns = ...
local UI = ns.UI

local DURATION = 30
local frame, timer

local function Hide()
  if frame then frame:Hide() end
end

local function Build()
  frame = CreateFrame("Frame", "GuildprintPrompt", UIParent, "SettingsFrameTemplate")
  frame:SetSize(340, 132)
  frame:SetPoint("TOP", 0, -140)
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame.NineSlice.Text:SetText("Guildprint")

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.title:SetPoint("TOP", 0, -36)
  frame.title:SetWidth(310)
  frame.title:SetWordWrap(false)
  frame.line = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.line:SetPoint("TOP", frame.title, "BOTTOM", 0, -6)
  frame.line:SetWidth(310)
  frame.line:SetWordWrap(false)

  local action = UI.Button(frame, "", 110, true)
  action:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -4, 20)
  action:SetScript("OnClick", function() frame.onAction(); Hide() end)
  frame.action = action
  local later = UI.Button(frame, "Not Now", 110)
  later:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 4, 20)
  later:SetScript("OnClick", Hide)

  -- Countdown bar: one Scale animation runs in the client, no OnUpdate.
  local bar = frame:CreateTexture(nil, "ARTWORK")
  bar:SetColorTexture(0.94, 0.78, 0.35)
  bar:SetHeight(3)
  bar:SetPoint("BOTTOMLEFT", 12, 9)
  bar:SetPoint("BOTTOMRIGHT", -8, 9)
  local anim = bar:CreateAnimationGroup()
  local scale = anim:CreateAnimation("Scale")
  scale:SetScaleFrom(1, 1)
  scale:SetScaleTo(0.001, 1)
  scale:SetOrigin("LEFT", 0, 0)
  scale:SetDuration(DURATION)
  frame.anim = anim

  frame:SetScript("OnHide", function()
    anim:Stop()
    if timer then timer:Cancel(); timer = nil end
  end)
end

-- shortcut: one popup at a time, a newer one replaces the older; queue them if users miss replies.
function ns.ShowPrompt(title, line, actionLabel, onAction)
  if not frame then Build() end
  frame.title:SetText(title)
  frame.line:SetText(line)
  frame.action:SetText(actionLabel)
  frame.onAction = onAction
  frame:Show()
  frame.anim:Restart()
  if timer then timer:Cancel() end
  timer = C_Timer.NewTimer(DURATION, Hide)
end
