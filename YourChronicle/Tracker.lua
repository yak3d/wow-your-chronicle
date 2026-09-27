local _, ns = ...

ns.Tracker = {}

-- -----------------------------
-- Category Registry
-- -----------------------------
local categories = {}

local function RegisterCategory(row)
  categories[row.key] = row
end

RegisterCategory({
  key = "quests",
  events = { "QUEST_ACCEPTED" },
  -- UPDATED: was function(questID). Dispatch now passes the event's name
  -- first, so handlers that listen to two events can tell them apart.
  handler = function(_, questID)
    local title = questID and C_QuestLog.GetTitleForQuestID(questID) or nil
    ns.Tracker.Log("quests", {
      questID = questID,
      title = title,
      zone = GetZoneText(),
      -- NEW: the deed's sentence, built from its own fields.
      text = title and ("accepted: " .. title) or ("accepted quest #" .. tostring(questID)),
    })
  end,
})

RegisterCategory({
  key = "npcs",
  events = { "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS" },
  handler = function(_, forcedName)
    local name = type(forcedName) == "string" and forcedName or UnitName("npc")
    local guid = UnitGUID("npc")

    if not name or name == "" or not guid or guid == "" then
      return
    end

    local character = ns.GetCharacter()
    if not character then
      return
    end

    local firstMeeting = not character.met[guid]
    ns.Tracker.Log("npcs", {
      name = name,
      zone = GetZoneText(),
      firstMeeting = firstMeeting,
      text = firstMeeting and ("first meeting: " .. name) or ("spoke with: " .. name)
    })

    character.met[guid] = true
  end,
})

local lastLevelDeed = nil
RegisterCategory({
  key = "levels",
  events = { "PLAYER_LEVEL_UP", "TIME_PLAYED_MSG" },
  handler = function(event, newLevel)
    if event == "PLAYER_LEVEL_UP" then
      lastLevelDeed = ns.Tracker.Log("levels", {
        level = newLevel,
        zone = GetZoneText(),
        text = "reached level " .. tostring(newLevel),
      })
      RequestTimePlayed()
    else
      if lastLevelDeed then
        lastLevelDeed.played = newLevel
        lastLevelDeed = nil
      end
    end
  end,
})

RegisterCategory({
  key = "places",
  events = { "ZONE_CHANGED_NEW_AREA" },
  handler = function()
    local mapID = C_Map.GetBestMapForUnit("player")
    local info = mapID and C_Map.GetMapInfo(mapID)
    local zone = info and info.name or GetZoneText()

    if not zone or zone == "" then
      return
    end

    local character = ns.GetCharacter()
    if not character then
      return
    end

    local firstVisit = not character.places[zone]

    ns.Tracker.Log("places", {
      zone = zone,
      firstVisit = firstVisit,
      text = firstVisit and ("first visit: " .. zone) or ("returned to: " .. zone),
    })

    character.places[zone] = true
  end,
})

RegisterCategory({
  key = "items",
  events = { "CHAT_MSG_LOOT" },
  handler = function(_, message, looter)
    local link
    if not looter then
      if type(message) == "number" then
        local name, itemLink, quality = C_Item.GetItemInfo(message)
        if not itemLink then
          ns.Print("items: no cached data for item " .. message .. " — try again or use a pasted link")
          return
        end
        link = itemLink
      else
        link = message:match("|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h")
      end
    else
      if looter ~= UnitName("player") then
        return
      end

      link = message:match("|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h")
    end
    if not link then
      return
    end

    local name, _, quality = C_Item.GetItemInfo(link)
    if not name or not quality or quality < ns.db.rarityFloor then
      return
    end

    ns.Tracker.Log("items", {
      name = name,
      link = link,
      quality = quality,
      zone = GetZoneText(),
      text = "looted: " .. link,
    })
  end,
})

RegisterCategory({
  key = "deaths",
  events = { "PLAYER_DEAD" },
  handler = function(event)
    local character = ns.GetCharacter()
    if not character then
      return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")

    local members = {}
    if IsInGroup() then
      for memberIndex = 1, GetNumGroupMembers() do
        local name = UnitName("group" .. memberIndex)
        if name and name ~= UnitName("player") then
          members[#members + 1] = name
        end
      end
    end

    ns.Tracker.Log("deaths", {
      zone = GetZoneText(),
      x = pos and pos.x or nil,
      y = pos and pos.y or nil,
      killer = nil,
      party = members,
      text = "died in " .. GetZoneText(),
    })
  end,
})

RegisterCategory({
  key = "foes",
  events = { "ENCOUNTER_END" },
  handler = function(_, encounterID, name, difficultyID, _, success)
    local character = ns.GetCharacter()
    if not character then
      return
    end

    if success == 1 then
      local wipes = character.wipes[encounterID] or 0
      character.wipes[encounterID] = 0
      ns.Tracker.Log("foes", {
        name = name,
        difficultyID = difficultyID,
        wipes = wipes,
        text = "defeated: " .. name
          .. (wipes > 0 and (" (after " .. wipes .. (wipes == 1 and " wipe)" or "wipes)")) or ""),
      })
    else
      character.wipes[encounterID] = (character.wipes[encounterID] or 0) + 1
    end
  end,
})

RegisterCategory({
  key = "standing",
  events = { "UPDATE_FACTION" },
  handler = function()
    local character = ns.GetCharacter()
    if not character then
      return
    end

    if not character.standing then
      character.standing = {}
    end

    local factionCount = C_Reputation.GetNumFactions()
    for i = 1, factionCount do
      local data = C_Reputation.GetFactionDataByIndex(i)
      if data and not data.isHeader then
        local previous = character.standing[data.name]
        character.standing[data.name] = data.reaction

        if previous and data.reaction > previous then
          ns.Tracker.Log("standing", {
            faction = data.name,
            standingID = data.reaction,
            text = data.name .. " standing increased",
          })
        end
      end
    end
  end,
})

RegisterCategory({
  key = "crafts",
  events = { "NEW_RECIPE_LEARNED" },
  handler = function(_, recipeID)
    local spellInfo = recipeID and C_Spell.GetSpellInfo(recipeID)
    if not spellInfo or not spellInfo.name then
      return
    end

    ns.Tracker.Log("crafts", {
      recipeID = recipeID,
      name = spellInfo.name,
      zone = GetZoneText(),
      text = "learned: " .. spellInfo.name,
    })
  end,
})

RegisterCategory({
  key = "company",
  events = { "GROUP_JOINED" },
  handler = function()
    local character = ns.GetCharacter()
    if not character then
      return
    end

    local members = {}
    for i = 1, GetNumGroupMembers() do
      local name = UnitName("group" .. i)
      if name and name ~= UnitName("player") then
        members[#members + 1] = name
      end
    end

    if #members == 0 then
      return
    end

    ns.Tracker.Log("company", {
      party = members,
      text = "joined " .. (#members + 1) .. " travelers: " .. table.concat(members, ", "),
    })
  end,
})

-- -------------
-- Event Frame
-- -------------
local eventFrame = CreateFrame("Frame")

for _, row in pairs(categories) do
  for _, event in ipairs(row.events) do
    eventFrame:RegisterEvent(event)
  end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  for _, row in pairs(categories) do
    if tContains(row.events, event) and ns.db.tracking[row.key] then
      row.handler(event, ...)
    end
  end
end)

local sourceOverride = nil


function ns.Tracker.Log(kind, deed)
  local character = ns.GetCharacter()
  if not character then
    return
  end

  local day = date("%Y-%m-%d")
  local bucket = character.log[day]

  if not bucket then
    bucket = {}
    character.log[day] = bucket
  end

  deed.kind = kind
  deed.time = time()
  deed.source = sourceOverride or "game"
  bucket[#bucket + 1] = deed

  return deed
end

function ns.Tracker.Simulate(key, ...)
  local row = categories[key]
  if not row then
    ns.Print("simulate: unknown category " .. tostring(key))
    return
  end

  local previous = sourceOverride
  sourceOverride = "test"

  if ns.db.tracking[row.key] then
    row.handler(row.events[1], ...)
  end

  sourceOverride = previous
end
