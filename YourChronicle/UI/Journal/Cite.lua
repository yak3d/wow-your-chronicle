local _, ns = ...

ns.Cite = {}

local L = ns.L

local COLORS = {
  quests = "ffffd100",
  npcs   = "ff4fb4ff",
}
local DEFAULT_COLOR = "ffe6cc80"

local LABELS = {
  quests = function(deed)
    return deed.title or L["CITE_QUEST"]:format(deed.questID or 0)
  end,

  npcs = function(deed)
    return deed.name
  end,

  levels = function(deed)
    return L["CITE_LEVEL"]:format(deed.level or 0)
  end,

  places = function(deed)
    return deed.zone
  end,

  deaths = function(deed)
    return L["CITE_DEATH"]:format(deed.zone or "?")
  end,

  foes = function(deed)
    return deed.name
  end,

  standing = function(deed)
    return deed.faction
  end,

  crafts = function(deed)
    return deed.name
  end,
}

function ns.Cite.Token(deed)
  if deed.kind == "items" and deed.link then
    return deed.link
  end

  local labelFn = LABELS[deed.kind]
  local label = labelFn and labelFn(deed) or deed.text or deed.kind

  label = label:gsub("[%[%]|]", "")

  local color = COLORS[deed.kind] or DEFAULT_COLOR
  return ("|c%s|Hyc:%s|h[%s]|h|r"):format(color, deed.kind, label)
end

function ns.Cite.Insert(deed)
  ns.Frame.Open("journal")
  ns.Page.Insert(ns.Cite.Token(deed))
end

local picker
local pickerRows = {}
local PICKER_MAX = 10
local PICKER_ROW = 18
local PICKER_WIDTH = 260

function ns.Cite.ClosePicker()
  if picker and picker:IsShown() then
    picker:Hide()
    return true
  end
  return false
end

local function CreatePickerRow(i)
  local row = CreateFrame("Button", nil, picker)
  row:SetHeight(PICKER_ROW)
  row:SetPoint("TOPLEFT", 8, -8 - (i - 1) * PICKER_ROW)
  row:SetPoint("RIGHT", -8, 0)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

  local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", 4, 0)
  text:SetPoint("RIGHT", -4, 0)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(false)
  row:SetFontString(text)

  row:SetScript("OnClick", function()
    ns.Cite.ClosePicker()
    ns.Page.Insert(ns.Cite.Token(row.deed), "@")
  end)

  return row
end

function ns.Cite.OpenPicker(anchor, x, y)
  local deeds = ns.Tracker.GetDeeds(date("%Y-%m-%d"))
  if #deeds == 0 then
    ns.Cite.ClosePicker()
    return
  end

  if not picker then
    picker = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
    picker:SetFrameStrata("DIALOG")
    picker:SetClampedToScreen(true)
  end

  local count = math.min(#deeds, PICKER_MAX)
  for i = 1, count do
    local deed = deeds[#deeds - i + 1]
    local row = pickerRows[i] or CreatePickerRow(i)
    pickerRows[i] = row
    row.deed = deed
    row:SetText(ns.Cite.Token(deed))
    row:Show()
  end

  for i = count + 1, #pickerRows do
    pickerRows[i]:Hide()
  end

  picker:SetSize(PICKER_WIDTH, count * PICKER_ROW + 16)
  picker:ClearAllPoints()
  picker:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, y)
  picker:Show()
end

function ns.Cite.ShowTooltip(owner, link, text)
  GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")

  if link:match("^item:") then
    GameTooltip:SetHyperlink(link)
  else
    GameTooltip:SetText(text)
    local kind = link:match("^yc:(%a+)")
    if kind then
      GameTooltip:AddLine(L["CITE_KIND_" .. kind:upper()], 0.6, 0.6, 0.6)
    end
  end

  GameTooltip:Show()
end

