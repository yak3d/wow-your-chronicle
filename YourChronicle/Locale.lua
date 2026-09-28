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
L["UNKNOWN_COMMAND"] = "Unknown command: %s"

-- Slash command help
L["HELP_HEADER"] = "Commands:"
L["HELP_CONFIG"] = "  /yc config - Open the settings panel"
L["HELP_WINDOW"] = "  /yc - Open or close the journal window"
L["HELP_LOG"] = "  /yc log - List the deeds recorded today"
L["HELP_NEW"] = "  /yc new - Open the journal and start writing"
L["LOG_HEADER"] = "Today's deeds (%d):"
L["LOG_EMPTY"] = "No deeds recorded today."

-- Header Strip
L["FRAME_SCOPE_CHARACTER"] = "Character volume"
L["FRAME_SCOPE_ACCOUNT"] = "Account volume"

-- Tabs
L["TAB_UNWRITTEN"] = "This page is not yet written."
L["TAB_JOURNAL"] = "Entries"
L["TAB_FEATS"] = "Feats"

-- Settings panel
L["SETTINGS_GENERAL"] = "General"
L["SETTING_SCOPE"] = "File new entries in"
L["SETTING_SCOPE_TT"] = "Choose which volume new entries go into. Switching never moves entries you already wrote."
L["SETTING_MINIMAP"] = "Show minimap button"
L["SETTING_MINIMAP_TT"] = "A minimap button that opens the journal. (Coming in a later update.)"
L["SETTING_AUTO_CHAPTERS"] = "Name chapters automatically"
L["SETTING_AUTO_CHAPTERS_TT"] = "Title each chapter after the zone and level you were at. (Coming in a later update.)"
L["SETTING_MEMORIAL"] = "Arm the memorial page"
L["SETTING_MEMORIAL_TT"] = "When this character dies, write a final memorial page and lock the journal forever. (Coming in a later update.)"
L["SETTINGS_PAGE"] = "The Page"
L["SETTING_FONT"] = "Default font"
L["SETTING_FONT_TT"] = "The font a new entry starts in."
L["SETTING_SIZE"] = "Default size"
L["SETTING_SIZE_TT"] = "The text size a new entry starts at."
L["SETTING_RARITY"] = "Record loot of at least"
L["SETTING_RARITY_TT"] = "Items below this quality are not written into your chronicle."
L["SETTINGS_RECORDING"] = "Recording"
L["SETTING_TRACKING"] = "What to record"

-- Volume
L["VOLUME_EMPTY"] = "No entries yet."

L["PAGE_ZONE"] = " recorded in %s "
L["PAGE_SEAL"] = "Save Entry"
L["PAGE_SEALED"] = "Saved entry: %s"
L["PAGE_NEW"] = "New Entry"
L["PAGE_EDIT"] = "Edit"
L["PAGE_SAVE_CHANGES"] = "Save Changes"
L["PAGE_SAVED"] = "Saved"
L["PAGE_UPDATED"] = "Updated entry: %s"
L["PAGE_UNTITLED"] = "(untitled)"
L["PAGE_NOTHING_TO_SEAL"] = "Nothing to save, write about your adventures first!"
L["PAGE_WORDS"] = "%d words"

-- Entries
L["ENTRY_DELETE"] = "Delete Entry"
L["ENTRY_DELETE_CONFIRM"] = "Delete \"%s\"?\nThis cannot be undone."
L["ENTRY_DELETED"] = "Deleted entry: %s"

-- Rarities
L["RARITY_0"] = "Poor"
L["RARITY_1"] = "Common"
L["RARITY_2"] = "Uncommon"
L["RARITY_3"] = "Rare"
L["RARITY_4"] = "Epic"
L["RARITY_5"] = "Legendary"

-- Feat Tracking
L["TRACK_TT"] = "Choose which kinds of deeds are written into your chronicle. Deeds already recorded are kept."

L["TRACK_GROUP_ADVENTURE"] = "Adventure"
L["TRACK_GROUP_BATTLE"] = "Battle"
L["TRACK_GROUP_FORTUNE"] = "People & Fortune"

L["TRACK_QUESTS"] = "Quests accepted"
L["TRACK_QUESTS_TT"] = "Each quest you pick up."
L["TRACK_NPCS"] = "People you meet"
L["TRACK_NPCS_TT"] = "Characters you speak with. The first meeting is marked."
L["TRACK_LEVELS"] = "Levels gained"
L["TRACK_LEVELS_TT"] = "Every level you reach."
L["TRACK_PLACES"] = "Places visited"
L["TRACK_PLACES_TT"] = "Zones you travel into."
L["TRACK_ITEMS"] = "Loot found"
L["TRACK_ITEMS_TT"] = "Items you loot, at or above the quality chosen below."
L["TRACK_DEATHS"] = "Deaths"
L["TRACK_DEATHS_TT"] = "Each time you fall."
L["TRACK_FOES"] = "Bosses fought"
L["TRACK_FOES_TT"] = "Dungeon and raid bosses, won or lost."
L["TRACK_STANDING"] = "Reputation gained"
L["TRACK_STANDING_TT"] = "Changes in your standing with factions."
L["TRACK_CRAFTS"] = "Recipes learned"
L["TRACK_CRAFTS_TT"] = "New recipes and patterns you learn."
L["TRACK_COMPANY"] = "Groups joined"
L["TRACK_COMPANY_TT"] = "Each party or raid you join."

-- Deed sentences, built from each deed's fields when shown
L["DEED_QUEST"] = "Accepted %s"
L["DEED_QUEST_ID"] = "Accepted quest #%d"
L["DEED_NPC_FIRST"] = "First meeting with %s"
L["DEED_NPC"] = "Spoke with %s"
L["DEED_LEVEL"] = "Reached level %d"
L["DEED_PLACE_FIRST"] = "First visit to %s"
L["DEED_PLACE"] = "Returned to %s"
L["DEED_ITEM"] = "Looted %s"
L["DEED_DEATH"] = "Died in %s"
L["DEED_FOE"] = "Defeated %s"
L["DEED_FOE_WIPE"] = "Defeated %s (after 1 wipe)"
L["DEED_FOE_WIPES"] = "Defeated %s (after %d wipes)"
L["DEED_STANDING"] = "Standing with %s rose"
L["DEED_CRAFT"] = "Learned %s"
L["DEED_COMPANY"] = "Joined a party of %d: %s"

L["FEATS_TODAY"] = "Today"
L["FEATS_NO_DAYS"] = "No deeds recorded yet"
L["FEATS_EMPTY"] = "Nothing recorded on this day."
L["FEATS_CITE"] = "Cite"

L["CITE_QUEST"] = "Quest #%d"
L["CITE_LEVEL"] = "Level %d"
L["CITE_DEATH"] = "Fell in %s"

-- Citation tooltip subtitles: describe a single past deed
L["CITE_KIND_QUESTS"] = "Quest accepted"
L["CITE_KIND_NPCS"] = "Person met"
L["CITE_KIND_LEVELS"] = "Level reached"
L["CITE_KIND_PLACES"] = "Place visited"
L["CITE_KIND_ITEMS"] = "Loot found"
L["CITE_KIND_DEATHS"] = "Slain"
L["CITE_KIND_FOES"] = "Boss fought"
L["CITE_KIND_STANDING"] = "Reputation gained"
L["CITE_KIND_CRAFTS"] = "Recipe learned"
L["CITE_KIND_COMPANY"] = "Group joined"

-- ---------------------------------------------------------------------------
-- Other locales
-- ---------------------------------------------------------------------------
-- Override only the keys that differ from enUS.
local locale = GetLocale()
if locale == "deDE" then
    -- L["TITLE"] = "Deine Chronik"
elseif locale == "frFR" then
    -- L["TITLE"] = "Ta chronique"
end
