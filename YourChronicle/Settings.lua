local addonName, ns = ...

local RARITY_COLORS = {
  [0] = "ff9d9d9d",
  "ffffffff",
  "ff1eff00",
  "ff0070dd",
  "ffa335ee",
  "ffff8000",
}

local TRACKING_KEYS = {
  "quests", "npcs", "levels", "places", "items",
  "deaths", "foes", "standing", "crafts", "company",
}

local TRACKING_BITS = {}
for i, key in ipairs(TRACKING_KEYS) do
  TRACKING_BITS[key] = bit.lshift(1, i - 1)
end

local TRACKING_GROUPS = {
  { title = "TRACK_GROUP_ADVENTURE", keys = { "quests", "places", "levels" } },
  { title = "TRACK_GROUP_BATTLE", keys = { "foes", "deaths" } },
  { title = "TRACK_GROUP_FORTUNE", keys = { "npcs", "company", "standing", "items", "crafts" } },
}

local function PackTracking(tbl)
  local mask = 0
  for i, key in ipairs(TRACKING_KEYS) do
    if tbl[key] then
      mask = mask + bit.lshift(1, i - 1)
    end
  end
  return mask
end

local function UnpackTracking(mask, tbl)
  for i, key in ipairs(TRACKING_KEYS) do
    tbl[key] = bit.band(mask, bit.lshift(1, i - 1)) ~= 0
  end
end

-- Locale.lua is listed before this file in the TOC, so ns.L already exists.
local L = ns.L

ns.Settings = {}

local GRID_LEFT = 37
local GRID_COLUMN_WIDTH = 200
local GRID_ROW_HEIGHT = 26
local GRID_TOP = 4

local GRID_ROWS = 0
for _, group in ipairs(TRACKING_GROUPS) do
  GRID_ROWS = math.max(GRID_ROWS, #group.keys)
end

YourChronicleTrackingGridMixin = CreateFromMixins(SettingsControlMixin)

function YourChronicleTrackingGridMixin:OnLoad()
  SettingsControlMixin.OnLoad(self)

  self.Tooltip:Hide()
  self.checkboxes = {}

  for column, group in ipairs(TRACKING_GROUPS) do
    local x = GRID_LEFT + (column - 1) * GRID_COLUMN_WIDTH

    local title = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", x, -GRID_TOP)
    title:SetText(L[group.title])

    for row, key in ipairs(group.keys) do
      local flag = TRACKING_BITS[key]
      local label = L["TRACK_" .. key:upper()]

      local checkbox = CreateFrame("CheckButton", nil, self, "SettingsCheckboxTemplate")
      checkbox:SetPoint("TOPLEFT", x - 6, -GRID_TOP - row * GRID_ROW_HEIGHT + 6)
      checkbox.flag = flag

      local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
      text:SetText(label)

      checkbox:SetTooltipFunc(function()
        Settings.InitTooltip(label, L["TRACK_" .. key:upper() .. "_TT"])
      end)

      checkbox:SetScript("OnClick", function()
        local setting = self:GetSetting()
        setting:SetValue(bit.bxor(setting:GetValue(), flag))
      end)

      self.checkboxes[#self.checkboxes + 1] = checkbox
    end
  end
end

function YourChronicleTrackingGridMixin:Init(initializer)
  SettingsControlMixin.Init(self, initializer)
  self.Text:Hide()
  self:SetValue(self:GetSetting():GetValue())
end

function YourChronicleTrackingGridMixin:SetValue(mask)
  for _, checkbox in ipairs(self.checkboxes) do
    checkbox:SetChecked(bit.band(mask, checkbox.flag) ~= 0)
  end
end

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
-- Setting variable names must be unique across every loaded addon, so they are
-- prefixed with this addon's name.
local VAR_PREFIX = addonName .. "_"

local category = nil
local layout = nil

-- Watchers os  settings changes are added here, they pass in a function and a setting name to watch
local watchers = {}

function ns.Settings.Watch(fn)
  watchers[#watchers + 1] = fn
end

local function Notify(key)
    for _, fn in ipairs(watchers) do
        fn(key)
    end
end

local function Register(tbl, key, default, label)
    local varType = Settings.VarType.String
    if type(default) == "boolean" then
        varType = Settings.VarType.Boolean
    elseif type(default) == "number" then
        varType = Settings.VarType.Number
    end

    local setting = Settings.RegisterAddOnSetting(
        category, VAR_PREFIX .. key, key, tbl, varType, label, default
    )

    setting:SetValueChangedCallback(function()
        Notify(key)
    end)

    return setting
end

local function AddCheckbox(tbl, key, default, label, tooltip)
    local setting = Register(tbl, key, default, label)
    Settings.CreateCheckbox(category, setting, tooltip)
end

local function AddDropdown(tbl, key, default, label, tooltip, choices)
    local setting = Register(tbl, key, default, label)

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        for _, choice in ipairs(choices) do
            container:Add(choice.value, choice.label)
        end
        return container:GetData()
    end

    return Settings.CreateDropdown(category, setting, GetOptions, tooltip)
end

local function AddHeader(text)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

function ns.Settings.Init()
  if category or not ns.db then
    return
  end

  local db = ns.db
  local defaults = ns.defaults

  category, layout = Settings.RegisterVerticalLayoutCategory(L["TITLE"])

  AddHeader(L["SETTINGS_GENERAL"])
  AddDropdown(db, "scope", defaults.scope, L["SETTING_SCOPE"], L["SETTING_SCOPE_TT"], {
    { value = "character", label = L["FRAME_SCOPE_CHARACTER"] },
    { value = "account", label = L["FRAME_SCOPE_ACCOUNT"] },
  })
  AddCheckbox(db, "minimap", defaults.minimap, L["SETTING_MINIMAP"], L["SETTING_MINIMAP_TT"])
  AddCheckbox(db, "autoChapters", defaults.autoChapters, L["SETTING_AUTO_CHAPTERS"], L["SETTING_AUTO_CHAPTERS_TT"])
  AddCheckbox(db, "memorial", defaults.memorial, L["SETTING_MEMORIAL"], L["SETTING_MEMORIAL_TT"])


  AddHeader(L["SETTINGS_PAGE"])

  local fonts = {}
  for _, h in ipairs(ns.Page.GetFonts()) do
    fonts[#fonts + 1] = { value = h.key, label = h.label }
  end
  AddDropdown(db.page, "font", defaults.page.font, L["SETTING_FONT"], L["SETTING_FONT_TT"], fonts)

  do
    local setting = Register(db.page, "size", defaults.page.size, L["SETTING_SIZE"])
    local options = Settings.CreateSliderOptions(13, 23, 2)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, setting, options, L["SETTING_SIZE_TT"])
  end

  AddHeader(L["SETTINGS_RECORDING"])
  local trackingSetting = Settings.RegisterProxySetting(
    category, VAR_PREFIX .. "tracking", Settings.VarType.Number, L["SETTING_TRACKING"],
    PackTracking(defaults.tracking),
    function() return PackTracking(db.tracking) end,
    function(mask) UnpackTracking(mask, db.tracking) end
  )
  trackingSetting:SetValueChangedCallback(function()
    Notify("tracking")
  end)

  local trackingInit = Settings.CreateControlInitializer(
    "YourChronicleTrackingGridTemplate", trackingSetting, nil, L["TRACK_TT"]
  )
  function trackingInit:GetExtent()
    return GRID_TOP * 2 + (GRID_ROWS + 1) * GRID_ROW_HEIGHT
  end
  layout:AddInitializer(trackingInit)

  local rarities = {}
  for quality = 0, 5 do
    rarities[#rarities + 1] = {
      value = quality,
      label = "|c" .. RARITY_COLORS[quality] .. L["RARITY_" .. quality] .. "|r",
    }
  end
  local rarityInit = AddDropdown(db, "rarityFloor", defaults.rarityFloor,
    L["SETTING_RARITY"], L["SETTING_RARITY_TT"], rarities)
  rarityInit:SetParentInitializer(trackingInit, function() return db.tracking.items end)

  Settings.RegisterAddOnCategory(category)
end

function ns.Settings.Open()
    if not category then
        ns.Settings.Init()
    end
    if category then
        Settings.OpenToCategory(category:GetID())
    end
end
