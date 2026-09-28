local _, ns = ...

ns.Dev = {}

local verbs = {}

function ns.Dev.RegisterVerb(name, fn)
  verbs[name] = fn
end

function ns.Dev.Handle(input)
  local verb, rest = input:match("^(%S*)%s*(.*)")
  local fn = verbs[verb:lower()]

  if not fn then
    ns.Print("test: unknown verb. Try /yc test dump")
    return
  end

  fn(rest)
end

ns.Dev.RegisterVerb("dump", function ()
  ns.Print(("version %d | scope %s | rarity floor %d"):format(
    ns.db.version,
    ns.db.scope,
    ns.db.rarityFloor
  ))

  local switches = {}

  for name, isOn in pairs(ns.db.tracking) do
    switches[#switches + 1] = name .. "=" .. (isOn and "on" or "off")
  end

  table.sort(switches)
  ns.Print("tracking: " .. table.concat(switches, " "))

  local volume = ns.GetVolume()
  ns.Print(("volume %s with %d sealed entries"):format(
    ns.db.scope == "account" and "account" or "character",
    volume and #volume or 0
  ))

  if volume and #volume > 0 then
    ns.Print(("entries (%d):"):format(#volume))
    for i, entry in ipairs(volume) do
      ns.Print(("  %d. [%s %s] %s"):format(
        i,
        entry.day or "?",
        entry.timestamp and date("%H:%M", entry.timestamp) or "--:--",
        entry.title or "(untitled)"))
    end
  end

  local character = ns.GetCharacter()
  ns.Print(("character record: %s, %d entries"):format(
    character and "ready" or "not ready yet",
    character and #character.entries or 0))

  local today = date("%Y-%m-%d")
  local bucket = character and character.log[today]

  ns.Print(("frame: %dx%d at (%s, %s)"):format(
    ns.db.frame.width,
    ns.db.frame.height,
    tostring(ns.db.frame.x),
    tostring(ns.db.frame.y)
  ))

  if bucket and #bucket > 0 then
    ns.Print(("today (%s): %d deeds"):format(today, #bucket))

    for _, deed in ipairs(bucket) do
      ns.Print((" %s [%s] %s"):format(
        date("%H:%M", deed.time), deed.source, ns.Tracker.Describe(deed)))
    end

  else
    ns.Print("today: no deeds logged")
  end
end)

ns.Dev.RegisterVerb("inject", function(rest)
  local key, args = rest:match("^(%S*)%s*(.*)")

  local parts = {}
  for value in (args or ""):gmatch("%S+") do
    parts[#parts + 1] = tonumber(value) or value
  end

  ns.Tracker.Simulate(key:lower(), unpack(parts))
end)

ns.Dev.RegisterVerb("seed", function(rest)
  local count = tonumber((rest:match("^%s*(%d+)"))) or 3
  local volume = ns.GetVolume()
  if not volume then
    ns.Print("seed: no volume yet (finish logging in first)")
    return
  end

  local titles = { "The Long Road", "Wolf Trouble", "A Quiet Hearth", "First Spark", "Old Friends" }
  local texts = {
    "Traveled the long road east and kept my head down.",
    "Wolves at the fence again. Three pelts, one scar.",
    "Slept by the fire. The soup was thin but hot.",
    "Learned my first spark of magic today.",
    "Met an old friend at the crossroads.",
  }

  for i = 1, count do
    local pick = (i - 1) % #titles + 1
    volume[#volume + 1] = {
      title = titles[pick],
      text = texts[pick],
      day = date("%Y-%m-%d"),
      timestamp = time(),
      source = "test",
    }
  end

  ns.Print(("seeded %d sample entries (source=test)"):format(count))
  ns.Volumes.Refresh()
end)

ns.Dev.RegisterVerb("unseed", function()
  local volume = ns.GetVolume()
  if not volume then
    return
  end

  local kept = {}
  for _, entry in ipairs(volume) do
    if entry.source ~= "test" then
      kept[#kept + 1] = entry
    end
  end

  local removed = #volume - #kept

  wipe(volume)

  for i, entry in ipairs(kept) do
    volume[i] = entry
  end

  ns.Print(("removed %d test entries, kept %d"):format(removed, #kept))
  ns.Volumes.Refresh()
end)

local SAMPLE_EPIC = "|cffa335ee|Hitem:12640::::::::|h[Lionheart Helm]|h|r"

ns.Dev.RegisterVerb("deeds", function()
  local now = time()
  local yesterday = now - 24 * 60 * 60

  local samples = {
    { kind = "npcs", time = yesterday, name = "Marshal McBride", firstMeeting = true },
    { kind = "quests", time = yesterday + 60, questID = 7, title = "Kobold Camp Cleanup" },
    { kind = "places", time = now - 120, zone = "Westfall", firstVisit = true },
    { kind = "quests", time = now - 60, questID = 33, title = "Wolves Across the Border" },
    { kind = "items", time = now, name = "Lionheart Helm", quality = 4, link = SAMPLE_EPIC },
  }

  for _, deed in ipairs(samples) do
    deed.source = "test"
    ns.Tracker.Log(deed.kind, deed)
  end

  ns.Print(("planted %d test deeds across 2 days"):format(#samples))
end)

ns.Dev.RegisterVerb("undeeds", function()
  ns.Print(("removed %d test deeds"):format(ns.Tracker.Forget("test")))
end)

ns.Dev.RegisterVerb("raw", function(rest)
  local index = tonumber(rest:match("^%s*(%d+)"))
  local text

  if index then
    local volume = ns.GetVolume()
    local entry = volume and volume[index]
    if not entry then
      ns.Print(("raw: no entry #%d"):format(index))
      return
    end
    text = entry.text
  else
    text = ns.db.draft and ns.db.draft.body
  end

  ns.Print("raw: " .. (text or "(empty)"):gsub("|", "||"))
end)
