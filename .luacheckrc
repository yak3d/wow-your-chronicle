-- luacheck configuration for Your Chronicle (World of Warcraft addon).
-- Run with `make lint` or `luacheck YourChronicle`.

std = "lua51"
max_line_length = 140
codes = true

-- Do not warn about an unused "self" argument in methods.
self = false

ignore = {
    "211/_.*", -- unused locals whose names start with an underscore
    "212/_.*", -- unused arguments whose names start with an underscore
    "542",     -- empty if branch (locale stubs in Locale.lua)
}

exclude_files = {
    ".release/",
}

-- Globals this addon creates or mutates.
-- The SLASH_ names are SLASH_ + the upper-cased addon name + an index.
globals = {
    "YourChronicleDB",
    "YourChronicleTrackingGridMixin",
    "SLASH_YOURCHRONICLE1",
    "SlashCmdList",
    "YourChronicleFrame",
    "UISpecialFrames",
    "StaticPopupDialogs",
}

-- WoW API surface this addon reads. Extend as the addon grows.
read_globals = {
    -- Lua extensions shipped with WoW
    "bit", "format", "strsplit", "strjoin", "strtrim", "tinsert", "tremove", "wipe", "tContains",
    "date", "time", "debugstack", "geterrorhandler", "hooksecurefunc", "securecall",

    -- Frames and UI
    "CreateFrame", "UIParent", "GameTooltip", "DEFAULT_CHAT_FRAME",
    "StaticPopup_Show", "MenuUtil", "YES", "NO", "Mixin", "CreateFromMixins",
    "Settings", "MinimalSliderWithSteppersMixin", "Enum", "SOUNDKIT",
    "CreateSettingsListSectionHeaderInitializer", "SettingsControlMixin",
    

    -- API functions and namespaces
    "GetLocale", "GetTime", "GetBuildInfo", "GetRealmName", "InCombatLockdown", "IsInInstance",
    "UnitName", "UnitClass", "UnitGUID", "PlaySound", "PlaySoundFile", "GetCVar", "SetCVar",
    "C_AddOns", "C_ChatInfo", "C_CVar", "C_Item", "C_Map", "C_Spell", "C_Timer", "C_UnitAuras",
    "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "WOW_PROJECT_CLASSIC", "C_QuestLog", "GetZoneText",
    "RequestTimePlayed", "IsInGroup", "GetNumGroupMembers", "C_Reputation", "C_Spell", "GetScreenWidth",
    "GetScreenHeight",
}
