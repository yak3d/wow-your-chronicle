local _, ns = ...

ns.Page = {}

local L = ns.L

-- --------------
-- Private State
-- --------------
local pageFrame
local parchment
local titleBox
local body
local bodyScroll
local sizeLabel
local fontDropdown
local footerText

local FONTS = {
  { key = "morpheus", label = "Morpheus", file = "Fonts\\MORPHEUS.ttf" },
  { key = "friz", label = "Friz", file = "Fonts\\FRIZQT__.ttf" },
  { key = "skurri", label = "Skurri", file = "Fonts\\SKURRI.ttf" },
}

-- Menu font strings disallow SetFont, so previews use font objects instead
for _, h in ipairs(FONTS) do
  h.fontObject = CreateFont("YourChronicleMenuFont_" .. h.key)
  h.fontObject:CopyFontObject(GameFontHighlightSmall)
  h.fontObject:SetFont(h.file, 13, "")
end

local font = "morpheus"
local size = 17
local titleSize = 18

local MIN_SIZE, MAX_SIZE, SIZE_STEP = 13, 23, 2

local function FontFile()
  for _, h in ipairs(FONTS) do
    if h.key == font then
      return h.file
    end
  end

  return FONTS[1].file
end

local function EnsureDraft()
  if not ns.db.draft then
    ns.db.draft = {
      day = date("%Y-%m-%d"),
      timestamp = time(),
    }
  end

  return ns.db.draft
end

local function SaveDraft()
  local title = titleBox and titleBox:GetText() or ""
  local text = body and body:GetText() or ""

  if title == "" and text == "" then
    ns.db.draft = nil
    return
  end

  local draft = EnsureDraft()
  draft.title = title
  draft.body = text
  draft.font = font
  draft.size = size
end

local function CountWords(text)
  local _, words = (text or ""):gsub("%S+", "")

  return words
end

local function UpdateFooter()
  if not footerText then
    return
  end

  footerText:SetText(
    L["PAGE_WORDS"]:format(CountWords(body and body:GetText() or ""))
  )
end

local function Seal()
  local title = titleBox and titleBox:GetText() or ""
  local text = body and body:GetText() or ""

  if title == "" and text == "" then
    ns.Print(L["PAGE_NOTHING_TO_SEAL"])

    return
  end

  local volume = ns.GetVolume()
  if not volume then
    return
  end

  local draft = ns.db.draft
  volume[#volume + 1] = {
    title = title,
    text = text,
    day = draft and draft.day or date("%Y-%m-%d"),
    timestamp = time(),
    font = font,
    size = size,
  }

  ns.Print(L["PAGE_SEALED"]:format(title ~= "" and title or L["PAGE_UNTITLED"]))

  ns.db.draft = nil
  titleBox:SetText("")
  body:SetText("")

  UpdateFooter()

  ns.Volumes.SelectLast()
end

local function ApplyFont()
  local file = FontFile()

  if body then
    body:SetFont(file, size, "")
  end

  if titleBox then
    titleBox:SetFont(file, titleSize, "")
  end

  if fontDropdown then
    fontDropdown:GenerateMenu()
  end

  if sizeLabel then
    sizeLabel:SetText(size .. " px")
  end

  SaveDraft()
end

local function SetFont(key)
  font = key
  ApplyFont()
end

local function SetSize(delta)
  size = math.min(math.max(size + delta, MIN_SIZE), MAX_SIZE)
  ApplyFont()
end

local function Build(parent)
  pageFrame = CreateFrame("Frame", nil, parent)
  pageFrame:SetAllPoints()

  local toolbar = CreateFrame("Frame", nil, pageFrame)
  toolbar:SetHeight(26)
  toolbar:SetPoint("TOPLEFT")
  toolbar:SetPoint("TOPRIGHT")

  fontDropdown = CreateFrame("DropdownButton", nil, toolbar, "WowStyle1DropdownTemplate")
  fontDropdown:SetWidth(140)
  fontDropdown:SetPoint("LEFT", 4, 0)
  fontDropdown:SetupMenu(function(_, rootDescription)
    for _, h in ipairs(FONTS) do
      local radio = rootDescription:CreateRadio(h.label, function()
        return h.key == font
      end, function()
        SetFont(h.key)
      end)

      radio:AddInitializer(function(button)
        button.fontString:SetFontObject(h.fontObject)
      end)
    end
  end)

  local plus = CreateFrame("Button", nil, toolbar)
  plus:SetSize(22, 22)
  plus:SetPoint("RIGHT", -4, 0)
  plus:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
  plus:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
  plus:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-HI")
  plus:SetScript("OnClick", function()
    SetSize(SIZE_STEP)
  end)

  sizeLabel = toolbar:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlightSmall"
  )
  sizeLabel:SetPoint("RIGHT", plus, "LEFT", -6, 0)

  local minus = CreateFrame("Button", nil, toolbar)
  minus:SetSize(22, 22)
  minus:SetPoint("RIGHT", sizeLabel, "LEFT", -6, 0)
  minus:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
  minus:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
  minus:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-HI")
  minus:SetScript("OnClick", function()
    SetSize(-SIZE_STEP)
  end)

  -- parchment panel
  parchment = CreateFrame("Frame", nil, pageFrame)
  parchment:SetPoint("TOPLEFT", 0, -32)
  parchment:SetPoint("BOTTOMRIGHT", 0, 28)

  local parchmentTex = parchment:CreateTexture(nil, "BACKGROUND")
  parchmentTex:SetAllPoints()
  parchmentTex:SetAtlas("QuestBG-Parchment", true)

  -- title/date line
  titleBox = CreateFrame("EditBox", nil, parchment)
  titleBox:SetPoint("TOPLEFT", parchment, "TOPLEFT", 60, -12)
  titleBox:SetPoint("TOPRIGHT", parchment, "TOPRIGHT", -60, -12)
  titleBox:SetHeight(24)
  titleBox:SetAutoFocus(false)
  titleBox:SetMaxBytes(80)
  titleBox:SetJustifyH("CENTER")
  titleBox:SetTextColor(0.13, 0.09, 0.05)
  titleBox:SetScript("OnEscapePressed", function()
    titleBox:ClearFocus()
  end)
  titleBox:SetScript("OnTextChanged", function(_, userInput)
    if userInput then
      SaveDraft()
    end
  end)

  local dateline = parchment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dateline:SetPoint("TOP", parchment, "TOP", 0, -46)
  dateline:SetText(date("%d %B %Y"))
  dateline:SetTextColor(0.45, 0.35, 0.2)

  local zone = parchment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  zone:SetPoint("TOP", parchment, "TOP", 0, -62)
  zone:SetText(L["PAGE_ZONE"]:format(GetZoneText() or ""))
  zone:SetTextColor(0.45, 0.35, 0.2)

  bodyScroll = CreateFrame("ScrollFrame", nil, parchment, "UIPanelScrollFrameTemplate")
  bodyScroll.scrollBarHideable = true
  bodyScroll.ScrollBar:Hide()
  bodyScroll:SetPoint("TOPLEFT", 16, -80)
  bodyScroll:SetPoint("BOTTOMRIGHT", -34, 12)

  body = CreateFrame("EditBox", nil, bodyScroll)
  body:SetMultiLine(true)
  body:SetAutoFocus(false)
  body:SetTextColor(0.13, 0.09, 0.05)
  bodyScroll:SetScrollChild(body)

  body:SetScript("OnEscapePressed", function()
    body:ClearFocus()
  end)

  body:SetScript("OnTextChanged", function(_, userInput)
    if userInput then
      SaveDraft()
    end
    UpdateFooter()
  end)

  body:SetScript("OnCursorChanged", function(_, _, y, _, h)
    local viewHeight = bodyScroll:GetHeight()
    local offset

    if h < viewHeight then
      offset = y + h / 2 - viewHeight / 2
    else
      offset = y
    end

    offset = math.floor(math.min(math.max(offset, 0), math.max(bodyScroll:GetVerticalScrollRange(), 0)))
    bodyScroll:SetVerticalScroll(offset)
  end)

  bodyScroll:EnableMouse(true)

  bodyScroll:SetScript("OnMouseDown", function()
    body:SetFocus()
  end)

  local footer = CreateFrame("Frame", nil, pageFrame)
  footer:SetHeight(26)
  footer:SetPoint("BOTTOMLEFT")
  footer:SetPoint("BOTTOMRIGHT")

  footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  footerText:SetPoint("LEFT", 8, 0)

  local seal = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  seal:SetSize(110, 22)
  seal:SetPoint("RIGHT", -8, 0)
  seal:SetNormalFontObject("GameFontHighlightSmall")
  seal:SetText(L["PAGE_SEAL"])
  seal:SetScript("OnClick", Seal)

  local draft = ns.db.draft
  if draft then
    titleBox:SetText(draft.title or "")
    body:SetText(draft.body or "")
    font = draft.font or "morpheus"
    size = draft.size or 17

    if draft.timestamp then
      dateline:SetText(date("%d %B %Y", draft.timestamp))
    end
  end

  UpdateFooter()

  bodyScroll:SetScript("OnSizeChanged", function(_, width)
    body:SetWidth(width)
  end)

  ApplyFont()

  return pageFrame
end

ns.Page.Build = Build

