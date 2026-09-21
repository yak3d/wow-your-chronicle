local _, ns = ...

ns.DB = {}

local DB_VERSION = 1

local DEFAULT_DB = {
  version = DB_VERSION,
  enabled = true,

  exampleValue = 50,

  scope = "character",

  tracking = {
    quests = true, souls = true, relics = true, levels = true,
    deaths = true, places = true, foes = true, standing = true,
    crafts = true, company = true,
  },

  -- Rarities
  -- 0 = Greys
  -- 1 = Common (white)
  -- 2 = Uncommon (green)
  -- 3 = Rare (blue)
  -- 4 = Epic (purple)
  -- 5 = Legendary (orange)
  rarityFloor = 2,

  -- account wide chronicle volume
  global = { entries = {} },

  -- per character records, keyed "Name-Realm". Created on first use.
  characters = {}
}

ns.defaults = DEFAULT_DB

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

function ns.DB.Init()
  if not YourChronicleDB then
    YourChronicleDB = {}
  end
  DeepCopyDefaults(DEFAULT_DB, YourChronicleDB)

  if (YourChronicleDB.version or 0) < DB_VERSION then
    -- new migrations to new versions will go here
    YourChronicleDB.version = DB_VERSION
  end

  ns.db = YourChronicleDB
end

function ns.GetCharacter()
  local name = UnitName("player")
  local realm = GetRealmName()

  if not name or name == "" or not realm then
    return nil
  end

  local key = name .. "-" .. realm
  local character = ns.db.characters[key]

  if not character then
    character = { entries = {}, log = {} }
    ns.db.characters[key] = character
  end

  character.entries = character.entries or {}
  character.log = character.log or {}
  character.met = character.met or {}
  character.places = character.places or {}
  character.wipes = character.wipes or {}

  return character
end

function ns.GetVolume()
  if ns.db.scope == "account" then
    return ns.db.global.entries
  end

  local character = ns.GetCharacter()

  return character and character.entries or nil
end
