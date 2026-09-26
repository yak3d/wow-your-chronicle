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
L["HELP_WINDOW"] = "  /yc - Open or close the journal window"

-- Header Strip
L["FRAME_SCOPE_CHARACTER"] = "Character volume"
L["FRAME_SCOPE_ACCOUNT"] = "Account volume"

-- Tabs
L["TAB_UNWRITTEN"] = "This page is not yet written."
L["TAB_JOURNAL"] = "Entries"
L["TAB_FEATS"] = "Feats"

-- Settings panel
L["SETTING_ENABLED"] = "Enable Your Chronicle"
L["SETTING_ENABLED_TT"] = "Turn the addon on or off without disabling it in the AddOns list."
L["SETTING_EXAMPLE_VALUE"] = "Example Value"
L["SETTING_EXAMPLE_VALUE_TT"] = "An example numeric setting. Replace or remove it."

-- Volume
L["VOLUME_EMPTY"] = "No entries yet."

L["PAGE_ZONE"] = " recorded in %s "
L["PAGE_SEAL"] = "Save Entry"
L["PAGE_UNTITLED"] = "(untitled)"
L["PAGE_NOTHING_TO_SEAL"] = "Nothing to save, write about your adventures first!"
L["PAGE_WORDS"] = "%d words"

-- Entries
L["ENTRY_DELETE"] = "Delete Entry"
L["ENTRY_DELETE_CONFIRM"] = "Delete \"%s\"?\nThis cannot be undone."
L["ENTRY_DELETED"] = "Deleted entry: %s"

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
