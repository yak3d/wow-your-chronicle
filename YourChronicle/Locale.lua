local _, ns = ...

-- ---------------------------------------------------------------------------
-- Localization
-- ---------------------------------------------------------------------------
-- Missing keys fall back to the key itself, so a forgotten translation shows
-- the key instead of erroring.
local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

-- ---------------------------------------------------------------------------
-- enUS (default)
-- ---------------------------------------------------------------------------
L["TITLE"] = "Your Chronicle"
L["LOADED"] = "Loaded. Type /yc for commands."
L["ENABLED"] = "Enabled."
L["DISABLED"] = "Disabled."
L["UNKNOWN_COMMAND"] = "Unknown command: %s"

-- Slash command help
L["HELP_HEADER"] = "Commands:"
L["HELP_CONFIG"] = "  /yc config - Open the settings panel"
L["HELP_TOGGLE"] = "  /yc toggle - Enable or disable the addon"

-- Settings panel
L["SETTING_ENABLED"] = "Enable Your Chronicle"
L["SETTING_ENABLED_TT"] = "Turn the addon on or off without disabling it in the AddOns list."
L["SETTING_EXAMPLE_VALUE"] = "Example Value"
L["SETTING_EXAMPLE_VALUE_TT"] = "An example numeric setting. Replace or remove it."

-- ---------------------------------------------------------------------------
-- Other locales
-- ---------------------------------------------------------------------------
-- Override only the keys that differ from enUS.
local locale = GetLocale()
if locale == "deDE" then
    -- L["ENABLED"] = "Aktiviert."
elseif locale == "frFR" then
    -- L["ENABLED"] = "Activé."
end
