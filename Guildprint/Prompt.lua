-- One-click "post your ad?" popup shown on zone/city entry.
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

  frame.zone = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.zone:SetPoint("TOP", 0, -36)
  frame.ad = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.ad:SetPoint("TOP", frame.zone, "BOTTOM", 0, -6)

  local post = UI.Button(frame, "Post Ad", 110, true)
  post:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -4, 20)
  post:SetScript("OnClick", function() ns.PostAd(); Hide() end)
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

function ns.ShowPrompt(zoneName)
  if not frame then Build() end
  local ad = ns.db.ads[ns.db.activeAd]
  frame.zone:SetText("Welcome to |cffffd200" .. (zoneName or "") .. "|r")
  frame.ad:SetText('Post "' .. (ad and ad.name or "") .. '" to your ad channels?')
  frame:Show()
  frame.anim:Restart()
  if timer then timer:Cancel() end
  timer = C_Timer.NewTimer(DURATION, Hide)
end
