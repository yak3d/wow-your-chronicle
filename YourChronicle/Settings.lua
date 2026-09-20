local addonName, ns = ...

-- Locale.lua is listed before this file in the TOC, so ns.L already exists.
local L = ns.L

ns.Settings = {}

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
-- Setting variable names must be unique across every loaded addon, so they are
-- prefixed with this addon's name.
local VAR_PREFIX = addonName .. "_"

local category = nil

-- ---------------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------------
-- Called from Core.lua on ADDON_LOADED once ns.db has been assigned. Safe to
-- call more than once.
function ns.Settings.Init()
    if category or not ns.db then
        return
    end

    local db = ns.db
    local defaults = ns.defaults

    category = Settings.RegisterVerticalLayoutCategory(L["TITLE"])

    -- Enabled (checkbox)
    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            VAR_PREFIX .. "Enabled",
            "enabled",
            db,
            Settings.VarType.Boolean,
            L["SETTING_ENABLED"],
            defaults.enabled
        )
        Settings.CreateCheckbox(category, setting, L["SETTING_ENABLED_TT"])
    end

    -- Example value (slider)
    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            VAR_PREFIX .. "ExampleValue",
            "exampleValue",
            db,
            Settings.VarType.Number,
            L["SETTING_EXAMPLE_VALUE"],
            defaults.exampleValue
        )
        local options = Settings.CreateSliderOptions(0, 100, 5)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, setting, options, L["SETTING_EXAMPLE_VALUE_TT"])
    end

    Settings.RegisterAddOnCategory(category)
end

-- ---------------------------------------------------------------------------
-- Open the panel (used by /yc config)
-- ---------------------------------------------------------------------------
function ns.Settings.Open()
    if not category then
        ns.Settings.Init()
    end
    if category then
        Settings.OpenToCategory(category:GetID())
    end
end
