-- Popup: "post your ad?" on zone entry, a /ginvite line to copy, "welcome?" when an invited player joins.
local _, ns = ...
local UI = ns.UI

local DURATION = 30
local frame, timer

local function Hide()
  if frame then frame:Hide() end
end

local function Build()
  frame = CreateFrame("Frame", "GuildprintPrompt", UIParent, "SettingsFrameTemplate")
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

  -- Copy mode: a selected chat command the player pastes into chat themselves.
  local copy = UI.Edit(frame, 290, 255)
  copy:SetPoint("TOP", frame.line, "BOTTOM", 0, -8)
  copy:SetScript("OnTextChanged", function(self, user)
    if user then self:SetText(frame.copyText); self:HighlightText() end  -- copy only, undo typing
  end)
  copy:SetScript("OnKeyDown", function(_, key)
    -- close once copied; the short wait lets the client finish the copy first
    if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then C_Timer.After(0.2, Hide) end
  end)
  copy:SetScript("OnEscapePressed", Hide)
  copy:SetScript("OnEditFocusGained", copy.HighlightText)
  frame.copy = copy
  frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.hint:SetPoint("TOP", copy, "BOTTOM", 0, -6)
  frame.hint:SetText("Click the line, Ctrl+C, then paste it into chat.")

  local action = UI.Button(frame, "", 110)
  action:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -4, 20)
  action:SetScript("OnClick", function() frame.onAction(); Hide() end)
  frame.action = action
  frame.later = UI.Button(frame, "Not Now", 110)
  frame.later:SetScript("OnClick", Hide)

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
    frame.key = nil
    if timer then timer:Cancel(); timer = nil end
  end)
end

-- p: title, line, then either action + onAction (a button) or copy (a chat command to copy;
-- focus = true selects it right away, for popups the player opened themselves).
-- key (optional) names the player it is about, for ns.HidePrompt.
-- shortcut: one popup at a time, a newer one replaces the older; queue them if users miss replies.
function ns.ShowPrompt(p)
  if not frame then Build() end
  frame.title:SetText(p.title)
  frame.line:SetText(p.line or "")
  frame.key, frame.copyText, frame.onAction = p.key, p.copy, p.onAction
  local copying = p.copy ~= nil
  frame:SetSize(340, copying and 176 or 132)
  frame.copy:SetShown(copying)
  frame.hint:SetShown(copying)
  frame.action:SetShown(not copying)
  frame.action:SetText(p.action or "")
  frame.later:ClearAllPoints()
  if copying then
    frame.later:SetPoint("BOTTOM", 0, 20)
    frame.later:SetText("Close")
  else
    frame.later:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 4, 20)
    frame.later:SetText("Not Now")
  end
  frame:Show()
  if copying then
    frame.copy:SetText(p.copy)
    frame.copy:SetCursorPosition(0)
    -- a popup the player didn't ask for must not take the keyboard mid-fight: they click the box
    if p.focus then frame.copy:SetFocus() else frame.copy:ClearFocus() end
  end
  frame.anim:Restart()
  if timer then timer:Cancel() end
  timer = C_Timer.NewTimer(DURATION, Hide)
end

-- Closes the popup if it is about this player (they opted out while it was open).
function ns.HidePrompt(key)
  if frame and frame.key == key then Hide() end
end

-- Forever forbids addons from sending guild invites, so the player sends /ginvite themselves.
function ns.PromptInvite(name, title, line, focus)
  ns.ShowPrompt({ title = title, line = line, copy = "/ginvite " .. name, key = ns.FullName(name), focus = focus })
end
