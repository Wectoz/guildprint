-- Small builders over Blizzard templates so every window matches the client.
local _, ns = ...
local UI = {}
ns.UI = UI

-- In Forever, UIPanelButtonTemplate is the red button (Options "Close"); the gray one is secondary.
function UI.Button(parent, text, w, red)
  local b = CreateFrame("Button", nil, parent, red and "UIPanelButtonTemplate" or "UIPanelButtonGrayTemplate")
  b:SetSize(w or 120, 24)
  b:SetText(text)
  if not red then
    b:SetNormalFontObject(GameFontNormal)
    b:SetHighlightFontObject(GameFontHighlight)
  end
  return b
end

-- Settings-style row: gold label on the left, checkbox in a column to the right.
function UI.Check(parent, label, get, set)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(300, 30)
  local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", 0, 0)
  text:SetText(label)
  local box = CreateFrame("CheckButton", nil, row)
  box:SetSize(30, 29)
  box:SetPoint("LEFT", 240, 0)
  box:SetNormalAtlas("checkbox-minimal")
  box:SetPushedAtlas("checkbox-minimal")
  box:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
  box:GetCheckedTexture():SetAtlas("checkmark-minimal")
  box:SetScript("OnClick", function(self) set(self:GetChecked()) end)
  row.box, row.label = box, text
  function row:Refresh() box:SetChecked(get() and true or false) end
  row:SetScript("OnShow", row.Refresh)
  return row
end

function UI.Edit(parent, w, maxLetters)
  local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  e:SetSize(w, 24)
  e:SetAutoFocus(false)
  e:SetMaxLetters(maxLetters)
  return e
end

-- Multi-line text box (ads, whisper). No scroll: 255 chars fit in the box.
function UI.TextArea(parent, w, h, maxLetters)
  local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  box:SetSize(w, h)
  box:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  box:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
  box:SetBackdropBorderColor(0.6, 0.47, 0.22)
  local e = CreateFrame("EditBox", nil, box)
  e:SetMultiLine(true)
  e:SetAutoFocus(false)
  e:SetFontObject(ChatFontNormal)
  e:SetMaxLetters(maxLetters)
  e:SetPoint("TOPLEFT", 8, -8)
  e:SetPoint("BOTTOMRIGHT", -8, 8)
  e:SetScript("OnEscapePressed", e.ClearFocus)
  box:EnableMouse(true)
  box:SetScript("OnMouseDown", function() e:SetFocus() end)
  box.EditBox = e
  return box
end

-- White section title with the Options divider under it.
function UI.Header(parent, text)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  fs:SetText(text)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetAtlas("Options_HorizontalDivider", true)
  line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", -4, -4)
  fs.divider = line
  return fs
end

function UI.Slider(parent, minV, maxV, step, get, set, fmt)
  local s = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
  s:SetSize(250, 20)
  local formatters = { [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt) }
  s:Init(get(), minV, maxV, (maxV - minV) / step, formatters)
  s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, v) set(v) end, s)
  return s
end

-- Small helper so page builders read top-to-bottom.
function UI.Place(widget, parent, x, y)
  widget:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  return widget
end
