local addonName, ns = ...

ns.Frame = {}

local L = ns.L

local frame = YourChronicleFrame

frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame:SetBackdropBorderColor(1, 0.82, 0, 1)

tinsert(UISpecialFrames, "YourChronicleFrame")

local titleBg = frame:CreateTexture(nil, "OVERLAY")
titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
titleBg:SetSize(320, 64)
titleBg:SetPoint("TOP", 0, 12)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, 0)
title:SetText(L["TITLE"])
title:SetFont("fonts/morpheus.ttf", 18, "")

local function SaveGeometry()
  local db = ns.db.frame
  db.x = math.floor(frame:GetLeft() + 0.5)
  db.y = math.floor(frame:GetTop() + 0.5)
  db.width = math.floor(frame:GetWidth() + 0.5)
  db.height = math.floor(frame:GetHeight() + 0.5)
end

local function RestoreGeometry()
  local db = ns.db.frame
  frame:SetSize(db.width, db.height)
  frame:ClearAllPoints()
  if db.x then
    -- clamp: keep the window fully on screen even if the screen shrank
    local sw, sh = GetScreenWidth(), GetScreenHeight()
    local x = math.min(math.max(db.x, 0), math.max(sw - db.width, 0))
    local y = math.min(math.max(db.y, 0), math.max(sh - db.height, 0))
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
  else
    -- never moved yet: stay centred, the default from MainFrame.xml
    frame:SetPoint("CENTER")
  end
end

frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function()
  frame:StartMoving()
end)
frame:SetScript("OnDragStop", function()
  frame:StopMovingOrSizing()
  SaveGeometry()
end)

frame:SetResizable(true)
frame:SetResizeBounds(520, 340, 1024, 768)

local grip = CreateFrame("Button", nil, frame)
grip:SetSize(16, 16)
grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:RegisterForDrag("LeftButton")
grip:SetScript("OnDragStart", function()
  frame:StartSizing("BOTTOMRIGHT")
end)
grip:SetScript("OnDragStop", function()
  frame:StopMovingOrSizing()
  SaveGeometry()
end)

-- ----------------------------------
-- Header
-- ----------------------------------
local headerName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
headerName:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -42)

local headerZone = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
headerZone:SetPoint("TOP", frame, "TOP", 0, -42)

local headerScope = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
headerScope:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -42)

local function UpdateHeader()
  local name = UnitName("player") or "?"
  local realm = GetRealmName()

  headerName:SetText(name .. (realm and ("-" .. realm) or ""))
  headerZone:SetText(GetZoneText() or "")
  headerScope:SetText(ns.db.scope == "account" and L["FRAME_SCOPE_ACCOUNT"] or L["FRAME_SCOPE_CHARACTER"])
end

local zoneWatcher = CreateFrame("Frame")
zoneWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneWatcher:SetScript("OnEvent", UpdateHeader)

-- -----------
-- Tabs
-- -----------
local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -54)
content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 26)

local tabs = {}
local pages = {}
local buttons = {}

local function SelectTab(id)
  local row
  for _, t in ipairs(tabs) do
    if t.id == id then
      row = t
    end
  end
  row = row or tabs[1]
  if not row then
    return
  end

  if not pages[row.id] and row.build then
    pages[row.id] = row.build(content)
  end

  -- exactly one page and one button highlighted at a time
  for _, t in ipairs(tabs) do
    local page = pages[t.id]
    if page then
      page:SetShown(t.id == row.id)
    end
    local button = buttons[t.id]

    if button then
      button:SetChecked(t.id == row.id)
    end
  end

  ns.db.ui.tab = row.id
end

local function BuildTabButtons()
  local previous

  for _, tab in ipairs(tabs) do
    if not buttons[tab.id] then
      local button = CreateFrame("CheckButton", nil, frame)
      button:SetSize(55, 55)

      if previous then
        button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
      else
        button:SetPoint("TOPLEFT", frame, "TOPRIGHT", -5, -30)
      end

      local backing = button:CreateTexture(nil, "BACKGROUND")
      backing:SetAtlas("common-sidetab")
      backing:SetSize(55, 60)
      backing:SetPoint("CENTER")

      local icon = button:CreateTexture(nil, "ARTWORK")
      icon:SetSize(50, 50)
      icon:SetPoint("CENTER", -4, 0)
      icon:SetTexture(tab.icon)
      icon:SetTexCoord(0.03, 0.97, 0.03, 0.97)
      button.icon = icon

      local mask = button:CreateMaskTexture()
      mask:SetAtlas("common-sidetab-mask")
      mask:SetSize(55, 60)
      mask:SetPoint("CENTER")
      icon:AddMaskTexture(mask)

      local hover = button:CreateTexture(nil, "HIGHLIGHT")
      hover:SetAtlas("common-sidetab-hover")
      hover:SetSize(55, 60)
      hover:SetPoint("CENTER")
      button:SetHighlightTexture(hover)

      local selected = button:CreateTexture(nil, "OVERLAY")
      selected:SetAtlas("common-sidetab-selected")
      selected:SetSize(55, 60)
      selected:SetPoint("CENTER")
      button:SetCheckedTexture(selected)

      button.label = tab.label

      button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.label)
        GameTooltip:Show()
      end)

      button:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)

      button:SetScript("OnClick", function()
        SelectTab(tab.id)
      end)

      buttons[tab.id] = button
    end

    previous = buttons[tab.id]
  end
end

function ns.Frame.RegisterTab(id, label, icon, build)
  for i, tab in ipairs(tabs) do
    if tab.id == id then
      tabs[i] = {
        id = id,
        label = label,
        icon = icon,
        build = build,
      }
      pages[id] = nil

      if buttons[id] then
        buttons[id].label = label
        buttons[id].icon:SetTexture(icon)
      end

      return
    end
  end

  tabs[#tabs + 1] = {
    id = id,
    label = label,
    icon = icon,
    build = build,
  }
end

local function BuildPlaceholder(parent)
  local page = CreateFrame("Frame", nil, parent)
  page:SetAllPoints()

  local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  note:SetPoint("CENTER")
  note:SetText(L["TAB_UNWRITTEN"])

  return page
end

ns.Frame.RegisterTab(
  "journal",
  L["TAB_JOURNAL"],
  "Interface\\Icons\\INV_Misc_Book_09",
  BuildPlaceholder
)
ns.Frame.RegisterTab(
  "feats",
  L["TAB_FEATS"],
  "Interface\\Icons\\INV_Misc_Head_Dragon_01",
  BuildPlaceholder
)

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, addon)
  if addon ~= addonName then
    return
  end
  RestoreGeometry()
  UpdateHeader()
  BuildTabButtons()
  SelectTab(ns.db.ui.tab)
  self:UnregisterEvent("ADDON_LOADED")
end)


function ns.Frame.Toggle()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end

