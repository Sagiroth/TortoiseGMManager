-- Lookup capture behavior tests using the public TortoiseGM lookup interface.
-- Run with: npx --yes --package fengari-node-cli fengari tests/lookup_spec.lua

if not table.getn then
    table.getn = function(value)
        return #value
    end
end

TortoiseGMManager = nil
TortoiseGMManagerDB = nil

local now = 100

function GetTime()
    return now
end

function SendChatMessage()
end

function CreateFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

DEFAULT_CHAT_FRAME = nil

dofile("TortoiseGMManager/Data.lua")
dofile("TortoiseGMManager/Core.lua")
dofile("TortoiseGMManager/Lookup.lua")

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

local addItemEntry = {
    label = "Add item",
    command = ".additem",
    lookupCommand = ".lookup item",
}

expectTrue(TortoiseGM.BeginLookup(addItemEntry, "thunder", ".lookup item thunder"), "starts item lookup")
expectEqual(TortoiseGM.GetLookupKind(".lookup item thunder"), "item", "detects item lookup kind")

local itemMessage = "19019 - |cffa335ee|Hitem:19019:0:0:0:0:0:0:0|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"
expectEqual(TortoiseGM.CaptureLookupMessage(itemMessage), 1, "captures item hyperlink result")
expectEqual(table.getn(TortoiseGM.GetLookupResults()), 1, "stores one item result")
expectEqual(TortoiseGM.GetLookupResults()[1].id, "19019", "keeps item id")
expectEqual(TortoiseGM.GetLookupResults()[1].name, "Thunderfury, Blessed Blade of the Windseeker", "keeps clean item name")
expectEqual(TortoiseGM.GetLookupResultCommand(TortoiseGM.GetLookupResults()[1]), ".additem 19019", "result loads originating action")

expectEqual(TortoiseGM.CaptureLookupMessage(itemMessage), 0, "deduplicates repeated result")
expectEqual(table.getn(TortoiseGM.GetLookupResults()), 1, "duplicate does not grow results")

local foreignSpell = "133 - |cffffffff|Hspell:133|h[Fireball enUS]|h|r"
expectEqual(TortoiseGM.CaptureLookupMessage(foreignSpell), 0, "ignores foreign link kind during item lookup")

expectTrue(TortoiseGM.BeginLookupCommand(".lookup creature wolf"), "starts manual creature lookup")
local creatureMessage = "123 - |cffffffff|Hcreature_entry:123|h[Forest Wolf]|h|r"
expectEqual(TortoiseGM.CaptureLookupMessage(creatureMessage), 1, "captures creature result")
expectEqual(TortoiseGM.GetLookupResults()[1].kind, "creature", "maps creature hyperlink kind")
expectEqual(TortoiseGM.GetLookupResultCommand(TortoiseGM.GetLookupResults()[1]), ".go creature id 123", "manual creature result gets safe go command")

expectTrue(TortoiseGM.BeginLookupCommand(".lookup event faire"), "starts manual event lookup")
local eventMessage = "4 - |cffffffff|Hgameevent:4|h[Darkmoon Faire]|h|r [active]"
expectEqual(TortoiseGM.CaptureLookupMessage(eventMessage), 1, "captures game event result")
expectEqual(TortoiseGM.GetLookupResults()[1].kind, "event", "maps gameevent hyperlink kind")
expectEqual(TortoiseGM.GetLookupResultCommand(TortoiseGM.GetLookupResults()[1]), ".event info 4", "event result loads info command")

expectTrue(TortoiseGM.BeginLookupCommand(".lookup player name arth"), "recognizes nested player lookup")
expectEqual(TortoiseGM.GetLookupKind(".lookup player name arth"), "player", "uses longest nested lookup command")

expectTrue(TortoiseGM.BeginLookupCommand(".lookup item expired"), "starts lookup for expiry check")
now = 113
expectFalse(TortoiseGM.IsLookupPending(), "lookup expires after capture window")
expectEqual(TortoiseGM.CaptureLookupMessage(itemMessage), 0, "expired lookup captures nothing")

if failures > 0 then
    error(tostring(failures) .. " of " .. tostring(checks) .. " checks failed")
end

print("PASS: " .. tostring(checks) .. " lookup checks")
