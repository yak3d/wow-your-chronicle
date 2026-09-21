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

  local character = ns.GetCharacter()
  ns.Print(("character record: %s, %d entries"):format(
    character and "ready" or "not ready yet",
    character and #character.entries or 0))

  local today = date("%Y-%m-%d")
  local bucket = character and character.log[today]

  if bucket and #bucket > 0 then
    ns.Print(("today (%s): %d deeds"):format(today, #bucket))

    for _, deed in ipairs(bucket) do
      ns.Print((" %s [%s] %s"):format(
        date("%H:%M", deed.time), deed.source, deed.text or deed.kind))
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
