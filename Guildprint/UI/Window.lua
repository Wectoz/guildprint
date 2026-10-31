-- Main window and Options → AddOns entry. Both show one shared body (sidebar + pages),
-- built on first open and reparented to whichever is visible.
local _, ns = ...
local UI = ns.UI

local SECTIONS = { "Recruiting", "Settings" }
local MAX_ADS = 6  -- rows the Messages page has room for
local pages, order = {}, {}   -- key -> {label, section, build, frame}
local body, window, current
local navButtons = {}

function ns.RegisterPage(key, label, section, build)
  pages[key] = { label = label, section = section, build = build }
  order[#order + 1] = key
end

local function ShowPage(key)
  current = key
  for k, p in pairs(pages) do
    if p.frame then p.frame:SetShown(k == key) end
  end
  local p = pages[key]
  if not p.frame then
    p.frame = CreateFrame("Frame", nil, body.content)
    p.frame:Hide()  -- so the Show below fires the OnShow that build() installs
    p.frame:SetAllPoints()
    p.build(p.frame)
  end
  p.frame:Show()
  for k, b in pairs(navButtons) do
    b.Texture:SetAtlas(k == key and "Options_List_Active" or "Options_List_Hover", true)
    b.Texture:SetShown(k == key)
  end
end

local function NavButton(parent, key, label)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(175, 20)
  b.Texture = b:CreateTexture(nil, "BACKGROUND")
  b.Texture:SetPoint("LEFT")
  b.Texture:Hide()
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("LEFT", 26, 0)
  fs:SetText(label)
  b:SetScript("OnEnter", function(self) if current ~= key then self.Texture:SetAtlas("Options_List_Hover", true) self.Texture:Show() end end)
  b:SetScript("OnLeave", function(self) if current ~= key then self.Texture:Hide() end end)
  b:SetScript("OnClick", function() ShowPage(key) end)
  navButtons[key] = b
  return b
end

local function BuildBody()
  body = CreateFrame("Frame")
  local nav = CreateFrame("Frame", nil, body)
  nav:SetPoint("TOPLEFT", 0, 0)
  nav:SetPoint("BOTTOMLEFT", 0, 0)
  nav:SetWidth(190)
  local y = -6
  for i, section in ipairs(SECTIONS) do
    local head = nav:CreateTexture(nil, "BACKGROUND")
    head:SetAtlas("Options_CategoryHeader_" .. i, true)
    head:SetPoint("TOPLEFT", 4, y)
    local fs = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    fs:SetPoint("LEFT", head, "LEFT", 12, 0)
    fs:SetText(section)
    y = y - 34
    for _, key in ipairs(order) do
      if pages[key].section == section then
        NavButton(nav, key, pages[key].label):SetPoint("TOPLEFT", 4, y)
        y = y - 22
      end
    end
    y = y - 10
  end
  body.content = CreateFrame("Frame", nil, body)
  body.content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 14, -6)
  body.content:SetPoint("BOTTOMRIGHT", -14, 10)
end

local function Attach(parent)
  if not body then BuildBody() end
  body:SetParent(parent)
  body:ClearAllPoints()
  if parent == window then
    body:SetPoint("TOPLEFT", 10, -28)
    body:SetPoint("BOTTOMRIGHT", -6, 6)
  else
    body:SetAllPoints()
  end
  body:Show()
  ShowPage(current or "advertise")
end

local function BuildWindow()
  window = CreateFrame("Frame", "GuildprintFrame", UIParent, "SettingsFrameTemplate")
  window:SetSize(780, 560)
  window:SetPoint("CENTER")
  window:SetFrameStrata("HIGH")
  window:SetToplevel(true)
  window:EnableMouse(true)
  window:SetMovable(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", window.StartMoving)
  window:SetScript("OnDragStop", window.StopMovingOrSizing)
  window.NineSlice.Text:SetText("Guildprint")
  window:SetScript("OnShow", function() Attach(window) end)
  tinsert(UISpecialFrames, "GuildprintFrame")  -- Escape closes it
end

function ns.OpenWindow(page)
  if not window then BuildWindow() end
  if page then current = page end
  if window:IsShown() then ShowPage(current) else window:Show() end
end

-- Options → AddOns → Guildprint: an empty canvas until opened.
tinsert(ns.ready, function()
  local canvas = CreateFrame("Frame")
  canvas:SetScript("OnShow", function(self)
    if window then window:Hide() end
    Attach(self)
  end)
  local category = Settings.RegisterCanvasLayoutCategory(canvas, "Guildprint")
  Settings.RegisterAddOnCategory(category)
  ns.settingsCategory = category
end)

-- ---------------------------------------------------------------- Settings pages

ns.RegisterPage("messages", "Messages", "Settings", function(f)
  local db = ns.db
  local selected = db.activeAd
  local rows = {}
  local nameEdit, textArea, list

  UI.Place(UI.Header(f, "Messages"), f, 4, -4)
  local hint = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"), f, 4, -32)
  hint:SetText("Tick the ad to post. Click a name to edit it. {guild} becomes your guild name.")

  list = CreateFrame("Frame", nil, f)
  UI.Place(list, f, 0, -54):SetSize(520, 1)

  local function Refresh()
    for i = 1, math.max(#rows, #db.ads) do
      local ad, row = db.ads[i], rows[i]
      if ad and not row then
        row = CreateFrame("Button", nil, list)
        row:SetSize(520, 26)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 28)
        row.hl = row:CreateTexture(nil, "BACKGROUND")
        row.hl:SetAtlas("Options_List_Active")
        row.hl:SetAllPoints()
        row.box = CreateFrame("CheckButton", nil, row)
        row.box:SetSize(26, 26)
        row.box:SetPoint("LEFT")
        row.box:SetNormalAtlas("checkbox-minimal")
        row.box:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.box:GetCheckedTexture():SetAtlas("checkmark-minimal")
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("LEFT", 34, 0)
        row.name:SetWidth(110)
        row.name:SetJustifyH("LEFT")
        row.preview = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.preview:SetPoint("LEFT", 150, 0)
        row.preview:SetPoint("RIGHT", -4, 0)
        row.preview:SetJustifyH("LEFT")
        row.preview:SetWordWrap(false)
        local idx = i
        row.box:SetScript("OnClick", function() db.activeAd = idx; Refresh() end)
        row:SetScript("OnClick", function() selected = idx; Refresh() end)
        rows[i] = row
      end
      if row then
        row:SetShown(ad ~= nil)
        if ad then
          row.name:SetText(ad.name)
          row.preview:SetText(ad.text)
          row.box:SetChecked(i == db.activeAd)
          row.hl:SetShown(i == selected)
        end
      end
    end
    local ad = db.ads[selected]
    nameEdit:SetText(ad and ad.name or "")
    textArea.EditBox:SetText(ad and ad.text or "")
    nameEdit:SetEnabled(ad ~= nil)
    textArea.EditBox:SetEnabled(ad ~= nil)
  end

  local y = -54 - 6 * 28
  local newBtn = UI.Place(UI.Button(f, "New", 90), f, 0, y)
  newBtn:SetScript("OnClick", function()
    if #db.ads >= MAX_ADS then ns.Print("You can keep up to " .. MAX_ADS .. " ads.") return end
    db.ads[#db.ads + 1] = { name = "New ad", text = "" }
    selected = #db.ads
    if not db.ads[db.activeAd] then db.activeAd = selected end
    Refresh()
    textArea.EditBox:SetFocus()
  end)
  local delBtn = UI.Button(f, "Delete", 90)
  delBtn:SetPoint("LEFT", newBtn, "RIGHT", 6, 0)
  delBtn:SetScript("OnClick", function()
    if not db.ads[selected] then return end
    table.remove(db.ads, selected)
    if db.activeAd > selected or db.activeAd > #db.ads then db.activeAd = math.max(1, db.activeAd - 1) end
    selected = math.min(selected, #db.ads)
    Refresh()
  end)

  local nameLabel = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontNormal"), f, 4, y - 40)
  nameLabel:SetText("Name")
  nameEdit = UI.Edit(f, 200, 32)
  nameEdit:SetPoint("LEFT", nameLabel, "LEFT", 70, 0)
  nameEdit:SetScript("OnTextChanged", function(self, user)
    if user and db.ads[selected] then db.ads[selected].name = self:GetText(); rows[selected].name:SetText(self:GetText()) end
  end)

  local textLabel = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontNormal"), f, 4, y - 72)
  textLabel:SetText("Text")
  textArea = UI.Place(UI.TextArea(f, 520, 90, 255), f, 0, y - 92)
  textArea.EditBox:SetScript("OnTextChanged", function(self, user)
    if user and db.ads[selected] then db.ads[selected].text = self:GetText(); rows[selected].preview:SetText(self:GetText()) end
  end)

  f:SetScript("OnShow", Refresh)
  Refresh()
end)

ns.RegisterPage("whisper", "Whisper", "Settings", function(f)
  -- key: the ns.db field the box edits
  local function TextBlock(title, hintText, key, y)
    UI.Place(UI.Header(f, title), f, 4, y)
    local hint = UI.Place(f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"), f, 4, y - 28)
    hint:SetText(hintText)
    local area = UI.Place(UI.TextArea(f, 520, 90, 255), f, 0, y - 50)
    area.EditBox:SetScript("OnTextChanged", function(self, user) if user then ns.db[key] = self:GetText() end end)
    area.EditBox:SetText(ns.db[key])
    return area
  end
  local whisper = TextBlock("Find Players whisper",
    "Sent to each player you pick in Find Players. {name} is their name, {guild} your guild's.", "whisper", -4)
  local welcome = TextBlock("Welcome message",
    "Said in guild chat when someone you invited joins. Leave empty to stay quiet.", "welcome", -170)
  f:SetScript("OnShow", function()
    whisper.EditBox:SetText(ns.db.whisper)
    welcome.EditBox:SetText(ns.db.welcome)
  end)
end)
