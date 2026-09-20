local addonName, ns = ...

-- ---------------------------------------------------------------------------
-- Constants and defaults
-- ---------------------------------------------------------------------------
local ADDON_COLOR = "|cff00ccff"
local DB_VERSION = 1

local DEFAULT_DB = {
    version = DB_VERSION,
    enabled = true,
    exampleValue = 50,
}

-- Exposed so Settings.lua can use the same defaults when registering settings.
ns.defaults = DEFAULT_DB

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
function ns.Print(msg)
    print(ADDON_COLOR .. "Your Chronicle|r: " .. tostring(msg))
end

-- Recursively fills in any keys missing from dst using the values in src,
-- without overwriting values the player has already saved.
local function DeepCopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if dst[k] == nil then
                dst[k] = {}
            end
            if type(dst[k]) == "table" then
                DeepCopyDefaults(v, dst[k])
            end
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

-- ---------------------------------------------------------------------------
-- Event frame
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= addonName then
            return
        end

        -- Initialize SavedVariables
        if not YourChronicleDB then
            YourChronicleDB = {}
        end
        DeepCopyDefaults(DEFAULT_DB, YourChronicleDB)

        -- DB migration
        if (YourChronicleDB.version or 0) < DB_VERSION then
            -- Add per-version migration steps here as DB_VERSION grows.
            YourChronicleDB.version = DB_VERSION
        end

        ns.db = YourChronicleDB

        -- Register the Settings -> AddOns category now that ns.db exists.
        ns.Settings.Init()

        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        -- The world is ready; hook frames and read player state from here on.
        ns.Print(ns.L["LOADED"])
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
-- These global names are SLASH_ + the addon name in upper case + an index.
SLASH_YOURCHRONICLE1 = "/yc"
SLASH_YOURCHRONICLE2 = "/yourchronicle"

SlashCmdList["YOURCHRONICLE"] = function(input)
    local L = ns.L
    -- rest holds everything after the subcommand, for commands that take arguments.
    local cmd, rest = input:match("^(%S+)%s*(.*)") -- luacheck: ignore rest
    cmd = cmd and cmd:lower() or ""

    if cmd == "config" then
        ns.Settings.Open()

    elseif cmd == "toggle" then
        ns.db.enabled = not ns.db.enabled
        ns.Print(ns.db.enabled and L["ENABLED"] or L["DISABLED"])

    elseif cmd ~= "" then
        ns.Print(L["UNKNOWN_COMMAND"]:format(cmd))

    else
        ns.Print(L["HELP_HEADER"])
        ns.Print(L["HELP_CONFIG"])
        ns.Print(L["HELP_TOGGLE"])
    end
end
