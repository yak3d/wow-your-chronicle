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
SLASH_YOURCHRONICLE1 = "/yc"

local function PrintHelp()
  local L = ns.L
  ns.Print(L["HELP_HEADER"])
  ns.Print(L["HELP_WINDOW"])
  ns.Print(L["HELP_CONFIG"])
  ns.Print(L["HELP_LOG"])
  ns.Print(L["HELP_NEW"])
end

local function PrintLog()
  local L = ns.L
  local character = ns.GetCharacter()
  local deeds = character and character.log[date("%Y-%m-%d")] or {}

  if #deeds == 0 then
    ns.Print(L["LOG_EMPTY"])
    return
  end

  ns.Print(L["LOG_HEADER"]:format(#deeds))
  for _, deed in ipairs(deeds) do
    ns.Print(("  %s  %s"):format(date("%H:%M", deed.time), deed.text or deed.kind))
  end
end

SlashCmdList["YOURCHRONICLE"] = function(input)
  local L = ns.L
  local cmd, rest = strtrim(input):match("^(%S+)%s*(.*)")
  cmd = cmd and cmd:lower() or ""

  if cmd == "config" then
    ns.Settings.Open()

  elseif cmd == "log" then
    PrintLog()

  elseif cmd == "new" then
    ns.Frame.Open("journal")
    ns.Page.Focus()

  elseif cmd == "test" then
    ns.Dev.Handle(rest or "")

  elseif cmd == "help" then
    PrintHelp()

  elseif cmd ~= "" then
    ns.Print(L["UNKNOWN_COMMAND"]:format(cmd))
    PrintHelp()

  else
    ns.Frame.Toggle()
  end
end
