local _, ns = ...

ns.Tracker = {}

local L = ns.L

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
local watchers = {}

function ns.Tracker.Watch(fn)
  watchers[#watchers + 1] = fn
end

local function Notify()
  for _, fn in ipairs(watchers) do
    fn()
  end
end

local SENTENCES = {
  quests = function(deed)
    if deed.title then
      return L["DEED_QUEST"]:format(deed.title)
    end
    return deed.questID and L["DEED_QUEST_ID"]:format(deed.questID)
  end,
  npcs = function(deed)
    return deed.name and L[deed.firstMeeting and "DEED_NPC_FIRST" or "DEED_NPC"]:format(deed.name)
  end,
  levels = function(deed)
    return deed.level and L["DEED_LEVEL"]:format(deed.level)
  end,
  places = function(deed)
    return deed.zone and L[deed.firstVisit and "DEED_PLACE_FIRST" or "DEED_PLACE"]:format(deed.zone)
  end,
  items = function(deed)
    local item = deed.link or deed.name
    return item and L["DEED_ITEM"]:format(item)
  end,
  deaths = function(deed)
    return deed.zone and L["DEED_DEATH"]:format(deed.zone)
  end,
  foes = function(deed)
    if not deed.name then
      return nil
    end
    local wipes = deed.wipes or 0
    if wipes == 1 then
      return L["DEED_FOE_WIPE"]:format(deed.name)
    elseif wipes > 1 then
      return L["DEED_FOE_WIPES"]:format(deed.name, wipes)
    end
    return L["DEED_FOE"]:format(deed.name)
  end,
  standing = function(deed)
    return deed.faction and L["DEED_STANDING"]:format(deed.faction)
  end,
  crafts = function(deed)
    return deed.name and L["DEED_CRAFT"]:format(deed.name)
  end,
  company = function(deed)
    local party = deed.party
    return party and #party > 0 and L["DEED_COMPANY"]:format(#party + 1, table.concat(party, ", "))
  end,
}

function ns.Tracker.Describe(deed)
  local sentence = SENTENCES[deed.kind]
  return sentence and sentence(deed) or deed.text or deed.kind
end

function ns.Tracker.Log(kind, deed)
  local character = ns.GetCharacter()
  if not character then
    return
  end

  deed.kind = kind
  deed.time = deed.time or time()
  deed.source = deed.source or sourceOverride or "game"
  deed.text = ns.Tracker.Describe(deed)

  local day = date("%Y-%m-%d", deed.time)
  local bucket = character.log[day]

  if not bucket then
    bucket = {}
    character.log[day] = bucket
  end

  bucket[#bucket + 1] = deed

  Notify()

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

function ns.Tracker.GetDays()
  local days = {}
  local character = ns.GetCharacter()
  if not character then
    return days
  end

  for day, bucket in pairs(character.log) do
    if #bucket > 0 then
      days[#days + 1] = day
    end
  end

  table.sort(days)

  return days
end

function ns.Tracker.GetDeeds(day)
  local deeds = {}
  local character = ns.GetCharacter()
  local bucket = character and character.log[day]
  if not bucket then
    return deeds
  end

  for _, deed in ipairs(bucket) do
    if ns.db.tracking[deed.kind] then
      if ns.db.tracking[deed.kind] then
        deeds[#deeds + 1] = deed
      end
    end
  end

  return deeds
end

function ns.Tracker.Forget(source)
  local character = ns.GetCharacter()
  if not character then
    return 0
  end

  local removed = 0
  for day, bucket in pairs(character.log) do
    for i = #bucket, 1, -1 do
      if bucket[i].source == source then
        tremove(bucket, i)
        removed = removed + 1
      end
    end

    if #bucket == 0 then
      character.log[day] = nil
    end
  end

  Notify()

  return removed
end
