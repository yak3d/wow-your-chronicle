local addonName, ns = ...

-- ---------------------------------------------------------------------------
-- Constants and defaults
-- ---------------------------------------------------------------------------
local ADDON_COLOR = "|cff00ccff"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
function ns.Print(msg)
  print(ADDON_COLOR .. "Your Chronicle|r: " .. tostring(msg))
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

    ns.DB.Init()

    -- Register the Settings -> AddOns category now that ns.db exists.
    ns.Settings.Init()

    -- Build the main window now that ns.db exists.
    ns.Frame.Init()

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
  local cmd, rest = strtrim(input):match("^(%S+)%s*(.*)")
  cmd = cmd and cmd:lower() or ""

  if cmd == "config" then
    ns.Settings.Open()

  elseif cmd == "toggle" then
    ns.db.enabled = not ns.db.enabled
    ns.Print(ns.db.enabled and L["ENABLED"] or L["DISABLED"])

  elseif cmd == "test" then
    ns.Dev.Handle(rest or "")

  elseif cmd == "help" then
    ns.Print(L["HELP_HEADER"])
    ns.Print(L["HELP_WINDOW"])
    ns.Print(L["HELP_CONFIG"])
    ns.Print(L["HELP_TOGGLE"])

  elseif cmd ~= "" then
    ns.Print(L["UNKNOWN_COMMAND"]:format(cmd))

  else
    ns.Frame.Toggle()
  end
end
