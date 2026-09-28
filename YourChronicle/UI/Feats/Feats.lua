local _, ns = ...

ns.Feats = {}

local L = ns.L

-- Private state
local page
local dayLabel
local prevButton
local nextButton
local viewing
local scroll
local listChild
local empty
local rows = {}

local ROW_HEIGHT = 26

local GLYPHS = {
  quests = "Interface\\Icons\\INV_Misc_Note_01",
  npcs = "Interface\\Icons\\INV_Misc_Head_Human_01",
  levels = "Interface\\Icons\\Spell_Holy_InnerFire",
  places = "Interface\\Icons\\INV_Misc_Map_01",
  items = "Interface\\Icons\\INV_Misc_Bag_10",
  deaths = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  foes = "Interface\\Icons\\INV_Sword_04",
  standing = "Interface\\Icons\\INV_BannerPVP_02",
  crafts = "Interface\\Icons\\Trade_BlackSmithing",
  company = "Interface\\Icons\\INV_Drink_05",
}

local function DayTitle(day)
  if day == date("%Y-%m-%d") then
    return L["FEATS_TODAY"]
  end

  local y, m, d = day:match("(%d+)-(%d+)-(%d+)")
  return date("%d %B %Y", time({
    year = tonumber(y) --[[@as integer]],
    month = tonumber(m) --[[@as integer]],
    day = tonumber(d) --[[@as integer]],
    hour = 12
  }))
end

local function CreateRow()
  local row = CreateFrame("Frame", nil, listChild)
  row:SetHeight(ROW_HEIGHT)

  local glyph = row:CreateTexture(nil, "ARTWORK")
  glyph:SetSize(20, 20)
  glyph:SetPoint("LEFT", 4, 0)
  row.glyph = glyph

  local clock = row:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  clock:SetPoint("LEFT", glyph, "RIGHT", 6, 0)
  row.clock = clock

  local cite = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  cite:SetSize(52, 20)
  cite:SetPoint("RIGHT", -4, 0)
  cite:SetNormalFontObject("GameFontHighlightSmall")
  cite:SetHighlightFontObject("GameFontHighlightSmall")
  cite:SetText(L["FEATS_CITE"])
  cite:SetScript("OnClick", function()
    ns.Cite.Insert(row.deed)
  end)
  row.cite = cite

  local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("LEFT", clock, "RIGHT", 8, 0)
  label:SetPoint("RIGHT", cite, "LEFT", -6, 0)
  label:SetJustifyH("LEFT")
  label:SetWordWrap(false)
  row.label = label

  return row
end

function ns.Feats.Refresh()
  if not page or not page:IsVisible() then
    return
  end

  local days = ns.Tracker.GetDays()

  local index = #days
  for i, day in ipairs(days) do
    if day == viewing then
      index = i
    end
  end
  viewing = days[index]

  dayLabel:SetText(viewing and DayTitle(viewing) or L["FEATS_NO_DAYS"])

  prevButton:SetEnabled(index > 1)
  nextButton:SetEnabled(index < #days)

  local deeds = viewing and ns.Tracker.GetDeeds(viewing) or {}

  for i, deed in ipairs(deeds) do
    local row = rows[i] or CreateRow()
    rows[i] = row

    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT")

    row.glyph:SetTexture(GLYPHS[deed.kind])
    row.clock:SetText(date("%H:%M", deed.time))
    row.label:SetText(ns.Tracker.Describe(deed))
    row.deed = deed
    row:Show()
  end

  for i = #deeds + 1, #rows do
    rows[i]:Hide()
  end

  listChild:SetHeight(math.max(#deeds * ROW_HEIGHT, 10))
  empty:SetShown(#deeds == 0)
end

local function Step(delta)
  local days = ns.Tracker.GetDays()

  for i, day in ipairs(days) do
    if day == viewing and days[i + delta] then
      viewing = days[i + delta]
      break
    end
  end

  ns.Feats.Refresh()
end

local function CreateArrow(parent, art, delta)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(26, 26)
  button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "Page-Up")
  button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "Page-Down")
  button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "Page-Disabled")
  button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  button:SetScript("OnClick", function()
    Step(delta)
  end)

  return button
end

local function Build(parent)
  page = CreateFrame("Frame", nil, parent)
  page:SetAllPoints()

  local scrubber = CreateFrame("Frame", nil, page)
  scrubber:SetHeight(26)
  scrubber:SetPoint("TOPLEFT")
  scrubber:SetPoint("TOPRIGHT")

  prevButton = CreateArrow(scrubber, "Prev", -1)
  prevButton:SetPoint("LEFT", 4, 0)

  nextButton = CreateArrow(scrubber, "Next", 1)
  nextButton:SetPoint("RIGHT", -4, 0)

  dayLabel = scrubber:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dayLabel:SetPoint("CENTER")

  scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -32)
  scroll:SetPoint("BOTTOMRIGHT", -28, 6)

  listChild = CreateFrame("Frame", nil, scroll)
  listChild:SetSize(1, 1)
  scroll:SetScrollChild(listChild)

  scroll:SetScript("OnSizeChanged", function(_, width)
    listChild:SetWidth(width)
  end)

  empty = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  empty:SetPoint("CENTER")
  empty:SetText(L["FEATS_EMPTY"])

  page:SetScript("OnShow", ns.Feats.Refresh)

  ns.Feats.Refresh()

  return page
end

ns.Tracker.Watch(ns.Feats.Refresh)

ns.Settings.Watch(function(key)
  if key == "tracking" then
    ns.Feats.Refresh()
  end
end)

ns.Frame.RegisterTab("feats", L["TAB_FEATS"], "Interface\\Icons\\Inv_misc_trophy_argent", Build)

