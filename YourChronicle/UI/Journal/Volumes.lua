local _, ns = ...

ns.Volumes = {}

local L = ns.L

-- ---------------------
-- Private State/Locals
-- ---------------------
local page
local contentHost
local scroll
local listChild
local rows = {}
local headers = {}
local selected

local SIDEBAR_WIDTH = 230
local ROW_HEIGHT = 26
local HEADER_HEIGHT = 24

local function GroupKey(entry)
  return date("%Y-%m", entry.timestamp or time())
end

local function GroupTitle(entry)
  return date("%B %Y", entry.timestamp or time())
end

local function CreateRow(parent)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(ROW_HEIGHT)

  -- leftside gold-ish highlight
  local rail = row:CreateTexture(nil, "OVERLAY")
  rail:SetWidth(3)
  rail:SetPoint("TOPLEFT")
  rail:SetPoint("BOTTOMLEFT")
  rail:SetColorTexture(1, 0.82, 0, 1)
  rail:Hide()
  row.rail = rail

  local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("LEFT", 10, 0)
  label:SetPoint("RIGHT", -4, 0)
  label:SetJustifyH("LEFT")
  row.label = label

  -- faint gold when the player hovers over the row
  local hover = row:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  hover:SetColorTexture(1, 0.82, 0, 0.15)
  row:SetHighlightTexture(hover)

  row:SetScript("OnClick", function()
    selected = row.entryIndex
    ns.Volumes.Refresh()
  end)

  return row
end

local function CreateHeader(parent)
  local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  header:SetTextColor(1, 0.82, 0)

  return header
end

function ns.Volumes.Refresh()
  if not page then
    return
  end

  local volume = ns.GetVolume() or {}
  local display = {}
  local lastGroup

  for i, entry in ipairs(volume) do
    local group = GroupKey(entry)

    if group ~= lastGroup then
      display[#display + 1] = {
        kind = "header",
        text = GroupTitle(entry)
      }

      lastGroup = group
    end

    display[#display+1] = {
      kind = "entry",
      index = i,
      entry = entry
    }
  end

  local y = 0
  local rowCount, headerCount = 0, 0
  for _, item in ipairs(display) do
    if item.kind == "header" then
      headerCount = headerCount + 1

      local header = headers[headerCount] or CreateHeader(listChild)
      headers[headerCount] = header
      header:ClearAllPoints()
      header:SetPoint("TOPLEFT", 0, -y)
      header:SetPoint("RIGHT")
      header:SetText(item.text)
      header:Show()
      y = y + HEADER_HEIGHT
    else
      rowCount = rowCount + 1

      local row = rows[rowCount] or CreateRow(listChild)
      rows[rowCount] = row
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", 0, -y)
      row:SetPoint("RIGHT")
      row.label:SetText(item.entry.title or "(untitled)")
      row.entryIndex = item.index
      row.rail:SetShown(item.index == selected)
      row:Show()

      y = y + ROW_HEIGHT
    end
  end

  for i = headerCount + 1, #headers do
    headers[i]:Hide()
  end
  for i = rowCount + 1, #rows do
    rows[i]:Hide()
  end

  listChild:SetHeight(math.max(y, 10))
  page.empty:SetShown(#volume == 0)
end

function ns.Volumes.SelectLast()
  local volume = ns.GetVolume()
  selected = #volume

  ns.Volumes.Refresh()
end

local function Build(parent)
  page = CreateFrame("Frame", nil, parent)
  page:SetAllPoints()

  local bg = page:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT")
  bg:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", SIDEBAR_WIDTH, 0)
  bg:SetColorTexture(0, 0, 0, 0.25)

  local divider = page:CreateTexture(nil, "OVERLAY")
  divider:SetWidth(1)
  divider:SetPoint("TOPLEFT", SIDEBAR_WIDTH, 0)
  divider:SetPoint("BOTTOMLEFT", SIDEBAR_WIDTH, 0)
  divider:SetColorTexture(1, 0.82, 0, 0.4)

  scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
  scroll.scrollBarHideable = true
  scroll.ScrollBar:Hide()
  scroll:SetPoint("TOPLEFT", 6, -6)
  scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", SIDEBAR_WIDTH - 28, 6)

  listChild = CreateFrame("Frame", nil, scroll)
  listChild:SetWidth(SIDEBAR_WIDTH - 34)
  scroll:SetScrollChild(listChild)

  -- shown when there's no entries
  local empty = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  empty:SetPoint("TOP", page, "TOPLEFT", SIDEBAR_WIDTH / 2, -40)
  empty:SetText(L["VOLUME_EMPTY"])
  page.empty = empty

  -- the right hand where entries are entered
  contentHost = CreateFrame("Frame", nil, page)
  contentHost:SetPoint("TOPLEFT", page, "TOPLEFT", SIDEBAR_WIDTH + 12, -6)
  contentHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -6, 6)

  if ns.Page then
    ns.Page.Build(contentHost)
  end

  ns.Volumes.Refresh()

  return page
end

ns.Frame.RegisterTab("journal", L["TAB_JOURNAL"], "Interface\\Icons\\INV_Misc_Book_09", Build)

