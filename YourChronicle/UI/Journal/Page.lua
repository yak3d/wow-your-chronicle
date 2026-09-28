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
local mode = "draft"
local dateline
local zone
local newButton
local seal
local shown
local dirty = false
local saveTimer
local AUTOSAVE_DELAY = 1
local cursorX, cursorY, cursorH = 0, 0, 0
local readView
local readText

local SEAL_LABELS = { draft = "PAGE_SEAL", read = "PAGE_EDIT", edit = "PAGE_SAVE_CHANGES" }

local FONTS = {
  { key = "morpheus", label = "Morpheus", file = "Fonts\\MORPHEUS.ttf" },
  { key = "friz", label = "Friz", file = "Fonts\\FRIZQT__.ttf" },
  { key = "skurri", label = "Skurri", file = "Fonts\\SKURRI.ttf" },
}

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

function ns.Page.GetFonts()
  return FONTS
end

function ns.Page.Focus()
  if body then
    body:SetFocus()
  end
end

local function UseDefaults()
  font = ns.db.page.font
  size = ns.db.page.size
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
  if mode ~= "draft" then
    return
  end

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

local function UpdateSealButton()
  if not seal then
    return
  end

  if mode == "edit" and not dirty then
    seal:SetText(L["PAGE_SAVED"])
    seal:Disable()
  else
    seal:SetText(L[SEAL_LABELS[mode]])
    seal:Enable()
  end
end

local function FlushEdit()
  if saveTimer then
    saveTimer:Cancel()
    saveTimer = nil
  end

  if not dirty or not shown then
    return
  end

  shown.title = titleBox:GetText()
  shown.text = body:GetText()
  shown.font = font
  shown.size = size

  dirty = false
  UpdateSealButton()
  ns.Volumes.Refresh()
end

local function MarkDirty()
  dirty = true
  UpdateSealButton()

  if saveTimer then
    saveTimer:Cancel()
  end
  saveTimer = C_Timer.NewTimer(AUTOSAVE_DELAY, FlushEdit)
end

local function OnUserEdit()
  if mode == "draft" then
    SaveDraft()
  elseif mode == "edit" then
    MarkDirty()
  end
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
    zone = GetZoneText(),
  }

  ns.Print(L["PAGE_SEALED"]:format(title ~= "" and title or L["PAGE_UNTITLED"]))

  ns.db.draft = nil

  ns.Volumes.Select(#volume)

  return true
end

local function UpdateReadView()
  if not readView or mode ~= "read" then
    return
  end

  local width = bodyScroll:GetWidth()
  readView:SetWidth(width)
  readText:SetWidth(width)

  readText:SetFont(FontFile(), size, "")
  readText:SetText(body:GetText())

  readView:SetHeight(readText:GetStringHeight() + 8)
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

  UpdateReadView()
  OnUserEdit()
end

local function SetFont(key)
  font = key
  ApplyFont()
end

local function SetSize(delta)
  size = math.min(math.max(size + delta, MIN_SIZE), MAX_SIZE)
  ApplyFont()
end

local function SetLocked(locked)
  titleBox:EnableMouse(not locked)
  body:EnableMouse(not locked)

  if locked then
    titleBox:ClearFocus()
    body:ClearFocus()
  end
end

local function SetMode(newMode)
  mode = newMode
  UpdateSealButton()
  newButton:SetShown(newMode ~= "draft")
  SetLocked(newMode == "read")

  local reading = newMode == "read"
  body:SetShown(not reading)
  readView:SetShown(reading)
  bodyScroll:SetScrollChild(reading and readView or body)
  UpdateReadView()
end

function ns.Page.ShowEntry(entry)
  FlushEdit()

  if not body then
    return
  end

  SetMode("read")
  shown = entry

  titleBox:SetText(entry.title or "")
  body:SetText(entry.text or "")
  font = entry.font or ns.db.page.font
  size = entry.size or ns.db.page.size

  dateline:SetText(date("%d %B %Y", entry.timestamp or time()))

  zone:SetShown(entry.zone ~= nil)
  if entry.zone then
    zone:SetText(L["PAGE_ZONE"]:format(entry.zone))
  end

  UpdateFooter()
  ApplyFont()
end

function ns.Page.NewDraft()
  FlushEdit()

  if not body then
    return
  end

  SetMode("draft")
  shown = nil

  local draft = ns.db.draft
  titleBox:SetText(draft and draft.title or "")
  body:SetText(draft and draft.body or "")

  if draft then
    font = draft.font or ns.db.page.font
    size = draft.size or ns.db.page.size
  else
    UseDefaults()
  end

  dateline:SetText(date("%d %B %Y", draft and draft.timestamp or time()))
  zone:SetText(L["PAGE_ZONE"]:format(GetZoneText() or ""))
  zone:Show()

  UpdateFooter()
  ApplyFont()
end

local function BeginEdit()
  SetMode("edit")
  body:SetFocus()
end

local function SaveChanges()
  FlushEdit()
  local title = titleBox:GetText()
  ns.Print(L["PAGE_UPDATED"]:format(title ~= "" and title or L["PAGE_UNTITLED"]))
  SetMode("read")
end

function ns.Page.Insert(text, replace)
  if not body then
    return
  end

  if mode == "read" then
    BeginEdit()
  end

  body:SetFocus()

  if replace then
    local full = body:GetText()
    local cursor = body:GetCursorPosition()
    local before = full:sub(cursor - #replace + 1, cursor)

    if before == replace then
      body:SetText(full:sub(1, cursor - #replace) .. full:sub(cursor + 1))
      body:SetCursorPosition(cursor - #replace)
    end
  end

  body:Insert(text)

  OnUserEdit()
end

local function Build(parent)
  pageFrame = CreateFrame("Frame", nil, parent)
  pageFrame:SetAllPoints()
  pageFrame:SetScript("OnHide", function()
    FlushEdit()
    ns.Cite.ClosePicker()
  end)

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
      OnUserEdit()
    end
  end)

  dateline = parchment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dateline:SetPoint("TOP", parchment, "TOP", 0, -46)
  dateline:SetText(date("%d %B %Y"))
  dateline:SetTextColor(0.45, 0.35, 0.2)

  zone = parchment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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

  readView = CreateFrame("Frame", nil, bodyScroll)
  readView:SetSize(1, 1)
  readView:EnableMouse(true)
  readView:SetHyperlinksEnabled(true)
  readView:Hide()

  readText = readView:CreateFontString(nil, "OVERLAY")
  readText:SetPoint("TOPLEFT")
  readText:SetJustifyH("LEFT")
  readText:SetJustifyV("TOP")
  readText:SetTextColor(0.13, 0.09, 0.05)

  readView:SetScript("OnHyperlinkEnter", function(self, link, text)
    ns.Cite.ShowTooltip(self, link, text)
  end)
  readView:SetScript("OnHyperlinkLeave", function()
    GameTooltip:Hide()
  end)

  body:SetScript("OnEscapePressed", function()
    if not ns.Cite.ClosePicker() then
      body:ClearFocus()
    end
  end)

  body:SetScript("OnChar", function(_, char)
    if char == "@" then
      ns.Cite.OpenPicker(body, cursorX, cursorY - cursorH)
    else
      ns.Cite.ClosePicker()
    end
  end)

  body:SetScript("OnTextChanged", function(_, userInput)
    if userInput then
      OnUserEdit()
    end
    UpdateFooter()
  end)

  body:SetScript("OnCursorChanged", function(_, x, y, _, h)
    cursorX, cursorY, cursorH = x, y, h

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
    if mode ~= "read" then
      body:SetFocus()
    end
  end)

  local footer = CreateFrame("Frame", nil, pageFrame)
  footer:SetHeight(26)
  footer:SetPoint("BOTTOMLEFT")
  footer:SetPoint("BOTTOMRIGHT")

  footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  footerText:SetPoint("LEFT", 8, 0)

  seal = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  seal:SetSize(110, 22)
  seal:SetPoint("RIGHT", -8, 0)
  seal:SetNormalFontObject("GameFontHighlightSmall")
  seal:SetText(L["PAGE_SEAL"])
  seal:SetScript("OnClick", function()
    if mode == "draft" then
      Seal()
    elseif mode == "read" then
      BeginEdit()
    else
      SaveChanges()
    end
  end)

  newButton = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  newButton:SetSize(110, 22)
  newButton:SetPoint("RIGHT", seal, "LEFT", -6, 0)
  newButton:SetNormalFontObject("GameFontHighlightSmall")
  newButton:SetText(L["PAGE_NEW"])
  newButton:SetScript("OnClick", function()
    ns.Volumes.Select(nil)
  end)

  ns.Page.NewDraft()

  bodyScroll:SetScript("OnSizeChanged", function(_, width)
    body:SetWidth(width)
    UpdateReadView()
  end)

  return pageFrame
end

ns.Page.Build = Build

