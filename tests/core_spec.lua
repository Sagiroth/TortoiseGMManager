-- Lightweight behavior tests for the public TortoiseGM core interface.
-- Run with: npx --yes fengari-node-cli tests/core_spec.lua

if not table.getn then
    table.getn = function(value)
        return #value
    end
end

TortoiseGMManager = nil
TortoiseGMManagerDB = nil

local sent = {}
local now = 100

function GetTime()
    return now
end

function SendChatMessage(message, channel)
    table.insert(sent, { message = message, channel = channel })
end

DEFAULT_CHAT_FRAME = nil

dofile("Data.lua")
dofile("Core.lua")

-- Keep the behavioral assertions readable while exercising the renamed addon.
local TortoiseGM = TortoiseGMManager

local failures = 0
local checks = 0

local function expectEqual(actual, expected, label)
    checks = checks + 1
    if actual ~= expected then
        failures = failures + 1
        print("FAIL: " .. label .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
    end
end

local function expectTrue(actual, label)
    expectEqual(actual, true, label)
end

local function expectFalse(actual, label)
    expectEqual(actual, false, label)
end

-- UI placement defaults are persistent core state, not frame implementation details.
TortoiseGM.InitializeDB()
local TortoiseGMDB = TortoiseGMManagerDB
expectEqual(TortoiseGMDB.minimapX, 52, "default minimap X offset")
expectEqual(TortoiseGMDB.minimapY, 52, "default minimap Y offset")
expectEqual(TortoiseGMDB.framePoint, "CENTER", "default frame anchor")
expectEqual(TortoiseGMDB.frameX, 0, "default frame X offset")
expectEqual(TortoiseGMDB.frameY, 15, "default frame Y offset")

-- Safety semantics should match command tokens, not arbitrary string prefixes.
expectTrue(TortoiseGM.IsDangerous(".server restart 10"), "restart is dangerous")
expectTrue(TortoiseGM.IsDangerous(".server idlerestart 10"), "idle restart is dangerous")
expectTrue(TortoiseGM.IsDangerous(".server idleshutdown 10"), "idle shutdown is dangerous")
expectFalse(TortoiseGM.IsDangerous(".server restart cancel"), "restart cancel is safe")
expectFalse(TortoiseGM.IsDangerous(".kickstarter"), "unrelated command sharing .kick prefix is safe")
expectTrue(TortoiseGM.IsDangerous(".kick PlayerName"), "kick command is dangerous")
expectTrue(TortoiseGM.IsDangerous(".tele add MySpot"), "persistent teleport creation is dangerous")
expectTrue(TortoiseGM.IsDangerous(".gobject delete 123"), "gameobject deletion is dangerous")
expectTrue(TortoiseGM.IsDangerous(".learn all_items"), "bulk learn command is dangerous")
expectFalse(TortoiseGM.IsDangerous(".tele name Player Stormwind"), "player teleport is not treated as persistent tele edit")

-- Every catalogue entry explicitly marked danger must participate in the core confirmation guard.
local dangerIndex
for dangerIndex = 1, table.getn(TortoiseGM.commands) do
    local dangerEntry = TortoiseGM.commands[dangerIndex]
    if dangerEntry.danger then
        expectTrue(TortoiseGM.IsDangerous(dangerEntry.command), "danger preset is guarded: " .. dangerEntry.command)
    end
end

-- Lookup uses an explicit query and never derives it from executable command arguments.
local lookupEntry = { command = ".additem", lookupCommand = ".lookup item", lookupHint = "an item name" }
expectEqual(TortoiseGM.BuildLookupCommand(lookupEntry, "Thunderfury"), ".lookup item Thunderfury", "builds lookup from explicit query")
expectEqual(TortoiseGM.BuildLookupCommand(lookupEntry, ""), nil, "empty explicit query builds nothing")

-- Normalization and composer extraction are the public text-processing seam.
expectEqual(TortoiseGM.NormalizeCommand("  gm   visible   on\n"), ".gm visible on", "normalizes whitespace and dot prefix")
expectEqual(TortoiseGM.GetComposerArgs(lookupEntry, ".ADDITEM Thunderfury"), "Thunderfury", "composer args are extracted case-insensitively")
expectEqual(TortoiseGM.GetComposerArgs(lookupEntry, ".cast Fireball"), ".cast Fireball", "unrelated composer text is preserved")

-- Positive FIND path sends the lookup only, preserving the action for the UI.
local sentBeforeLookup = table.getn(sent)
expectTrue(TortoiseGM.ExecuteLookup(lookupEntry, "Thunderfury"), "explicit lookup executes")
expectEqual(table.getn(sent), sentBeforeLookup + 1, "matching lookup sends one chat command")
expectEqual(sent[table.getn(sent)].message, ".lookup item Thunderfury", "matching lookup sends expected command")
expectEqual(sent[table.getn(sent)].channel, "SAY", "lookup uses chat command channel")

-- Help strips user arguments and targets the known catalogue route.
local sentBeforeHelp = table.getn(sent)
expectTrue(TortoiseGM.RequestHelp(".server restart 10"), "help request accepts composed command")
expectEqual(sent[table.getn(sent)].message, ".help server restart", "help strips user arguments")
expectEqual(table.getn(sent), sentBeforeHelp + 1, "help sends once")

-- Dangerous execution is two-step; explicit lifecycle cancel is immediate.
local sentBeforeDanger = table.getn(sent)
expectFalse(TortoiseGM.Execute(".server restart 10"), "first dangerous RUN only arms")
expectEqual(table.getn(sent), sentBeforeDanger, "armed dangerous command sends nothing")
expectTrue(TortoiseGM.Execute(".server restart 10"), "second identical dangerous RUN executes")
expectEqual(sent[table.getn(sent)].message, ".server restart 10", "confirmed dangerous command is sent")

local sentBeforeCancel = table.getn(sent)
expectTrue(TortoiseGM.Execute(".server restart cancel"), "restart cancel executes immediately")
expectEqual(table.getn(sent), sentBeforeCancel + 1, "restart cancel sends once")

-- History deduplicates and keeps most-recent-first ordering.
TortoiseGM.AddHistory(".gps")
TortoiseGM.AddHistory(".server info")
TortoiseGM.AddHistory(".gps")
expectEqual(TortoiseGMDB.history[1], ".gps", "history moves repeated command to front")
expectEqual(TortoiseGMDB.history[2], ".server info", "history retains other recent command")

-- Favourites persist known catalogue commands and toggle cleanly.
local favouriteEntry = TortoiseGM.commands[1]
expectTrue(TortoiseGM.ToggleFavourite(favouriteEntry), "favourite can be added")
expectTrue(TortoiseGM.IsFavourite(favouriteEntry.command), "added command is favourite")
expectEqual(table.getn(TortoiseGM.GetFavouriteCommands()), 1, "favourites view returns added command")
expectFalse(TortoiseGM.ToggleFavourite(favouriteEntry), "favourite can be removed")
expectFalse(TortoiseGM.IsFavourite(favouriteEntry.command), "removed command is not favourite")

-- Structured values are initialized, validated and composed through the core seam.
local scaleEntry = TortoiseGM.FindEntry("modify-scale")
local scaleValues = TortoiseGM.InitializeValues(scaleEntry)
expectEqual(scaleValues.scale, 1, "scale default")
expectEqual(scaleValues.persist, "off", "scale persistence default")
expectEqual(TortoiseGM.ComposeValues(scaleEntry, scaleValues), ".modify scale 1 off", "structured scale composition")
expectEqual(TortoiseGM.AdjustNumber(scaleEntry.arguments[1], 9.95, 1), 10, "numeric increment clamps maximum")
expectEqual(TortoiseGM.AdjustNumber(scaleEntry.arguments[1], 0.1, -1), 0.1, "numeric decrement clamps minimum")

local hoverEntry = TortoiseGM.FindEntry("hover")
local hoverValues = TortoiseGM.InitializeValues(hoverEntry)
expectEqual(TortoiseGM.ComposeValues(hoverEntry, hoverValues), ".hover 1", "hover preserves numeric on token")
hoverValues.state = TortoiseGM.CycleToggle(hoverEntry.arguments[1], hoverValues.state, 1)
expectEqual(hoverValues.state, "0", "toggle cycles to exact off token")
expectEqual(TortoiseGM.GetOptionLabel(hoverEntry.arguments[1], hoverValues.state), "OFF", "toggle display label")
expectEqual(TortoiseGM.ComposeValues(hoverEntry, hoverValues), ".hover 0", "toggle off composition")

local addItem = TortoiseGM.FindEntry("additem")
local valid, validationMessage = TortoiseGM.ValidateValues(addItem, TortoiseGM.InitializeValues(addItem))
expectFalse(valid, "required lookup ID validation")
expectEqual(validationMessage, "Item ID is required.", "required validation identifies field")
expectEqual(TortoiseGM.GetInteraction(TortoiseGM.FindEntry("gps")), "execute", "safe argument-free interaction")
expectEqual(TortoiseGM.GetInteraction(addItem), "configure", "structured interaction")
expectEqual(TortoiseGM.GetInteraction(TortoiseGM.FindEntry("deleteitem")), "review", "dangerous interaction")
expectEqual(TortoiseGM.GetInteraction(nil), "load", "manual interaction")

local itemValues = TortoiseGM.InitializeValues(addItem)
itemValues.count = 7
local filledValues, filledCommand = TortoiseGM.ComposeLookupResult(addItem, itemValues, 19019)
expectEqual(filledValues.itemId, "19019", "lookup fills lookup-id")
expectEqual(filledValues.count, 7, "lookup preserves count")
expectEqual(filledCommand, ".additem 19019 7", "lookup result composes modifiers")

-- Legacy command favourites migrate once to stable IDs, including merged aliases.
TortoiseGMManagerDB.favourites = { ".gm on", ".hover 0", ".not-a-command" }
TortoiseGM.MigrateFavourites()
expectEqual(TortoiseGMManagerDB.favourites[1], "gm-mode", "legacy GM favourite migrates")
expectEqual(TortoiseGMManagerDB.favourites[2], "hover", "merged alias favourite migrates")
expectEqual(table.getn(TortoiseGMManagerDB.favourites), 2, "unresolvable favourite is omitted")
TortoiseGM.MigrateFavourites()
expectEqual(table.getn(TortoiseGMManagerDB.favourites), 2, "favourite migration is idempotent")
expectTrue(table.getn(TortoiseGM.GetFilteredCommands("all", ".gm off")) > 0, "search includes merged legacy command")
expectTrue(table.getn(TortoiseGM.GetFilteredCommands("all", "OFF")) > 0, "search includes option labels")
expectTrue(table.getn(TortoiseGM.GetFilteredCommands("all", "item id")) > 0, "search includes argument labels")

-- Every hinted command receives a helpful fallback input when no richer schema exists.
local teleEntry = TortoiseGM.FindEntry("tele")
local teleValues = TortoiseGM.InitializeValues(teleEntry)
teleValues.location = "Thunder Bluff"
expectEqual(TortoiseGM.ComposeValues(teleEntry, teleValues), ".tele Thunder Bluff", "tele location input composes exact command")
local summonEntry = TortoiseGM.FindEntry("summon")
local summonArguments = TortoiseGM.GetEntryArguments(summonEntry)
expectEqual(table.getn(summonArguments), 1, "hinted command receives one fallback input")
expectEqual(summonArguments[1].key, "arguments", "fallback input stores raw syntax arguments")
local summonValues = TortoiseGM.InitializeValues(summonEntry)
summonValues.arguments = "Testplayer"
expectEqual(TortoiseGM.ComposeValues(summonEntry, summonValues), ".summon Testplayer", "fallback input updates command preview")
local hpEntry = TortoiseGM.FindEntry("modify-hp")
local hpValues = TortoiseGM.InitializeValues(hpEntry)
hpValues.current = 5000; hpValues.maximum = 7500
expectEqual(TortoiseGM.ComposeValues(hpEntry, hpValues), ".modify hp 5000 7500", "HP controls compose current and maximum")

if failures > 0 then
    error(tostring(failures) .. " of " .. tostring(checks) .. " checks failed")
end

print("PASS: " .. tostring(checks) .. " core checks")
