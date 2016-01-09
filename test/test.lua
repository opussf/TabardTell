#!/usr/bin/env lua

addonData = { ["version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"


-- Figure out how to parse the XML here, until then....

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "TabardTell"
require "TabardTellOptions"

-- addon setup
function test.before()
end
function test.after()
end

--[[
-- these tests only examine the RE for finding the faction name
function test.testFactionFilter_noThe()
	globals = {
		["GameTooltipTextLeft5"] = { ["GetText"] = function()
			return "Equip: You champion the cause of Darnassus. All reputation gains while in dungeons will be applied to your standing with them."
		end, },
	}
	local actual = TT.GetEquipTextFromToolTip()
	_, _, TT.faction = strfind(actual, TT.TABARD_FACTION_FILTER);
	assertEquals( "Darnassus", TT.faction )
end
function test.testFactionFilter_withThe()
	globals = {
		["GameTooltipTextLeft5"] = { ["GetText"] = function()
			return "Equip: You champion the cause of the Bilgewater Cartel. All reputation gains while in dungeons will be applied to your standing with them."
		end, },
	}
	local actual = TT.GetEquipTextFromToolTip()
	_, _, TT.faction = strfind(actual, TT.TABARD_FACTION_FILTER);
	assertEquals( "Bilgewater Cartel", TT.faction)
end
]]
---------
-- id | inInstance | TT_outsideTabard | HasTabardEquipped | ValidTabardInBag | result
--------------------------------------------------------------------------------------
-- 01 | False      | nil              | False             | False            | TT_outsideTabard = nil
-- 02 | True       | nil              | False             | False            | TT_outsideTabard = "None"
-- 03 | False      | None             | False             | False            | TT_outsideTabard = nil, currentTabard should not be equipped
-- 04 | True       | None             | False             | False            | TT_outsideTabard = "None"
-- 05 | False      | Link             | False             | False            | TT_outsideTabard = nil, equip Link tabard if possible -- player tossed tabard?
-- 06 | True       | Link             | False             | False            | TT_outsideTabard = "Link" -- should never happen? - will be reset upon exit
-- 07 | False      | nil              | True              | False            | TT_outsideTabard = nil, currentTabard should be the same
-- 08 | True       | nil              | True              | False            | TT_outsideTabard = "Link", currentTabard should be the same
-- 09 | False      | None             | True              | False            | TT_outsideTabard = nil, un-equip current tabard
-- 10 | True       | None             | True              | False            | TT_outsideTabard = "None", currentTabard should be the same
-- 11 | False      | Link             | True              | False            | TT_outsideTabard = nil, if equippedTabrd is Link, no change
-- 12 | True       | Link             | True              | False            | TT_outsideTabard = "Link", Link should be the equipped tabard

-- 13 | False      | nil              | False             | True             | TT_outsideTabard = nil, no tabard equipped
-- 14 | True       | nil              | False             | True             | TT_outsideTabard = "None", currentTabard should be equipped
-- 15 | False      | None             | False             | True             | TT_outsideTabard = nil, no tabard equipped
-- 16 | True       | None             | False             | True             | TT_outsideTabard = "None", currentTabard should be equipped
-- 17 | False      | Link             | False             | True             | TT_outsideTabard = nil, equip Link tabard if possible
-- 18 | True       | Link             | False             | True             | TT_outsideTabard = "None",
-- 19 | False      | nil              | True              | True             | TT_outsideTabard = nil, no change
-- 20 | True       | nil              | True              | True             | TT_outsideTabard = "Link", valid tabard equipped
-- 21 | False      | None             | True              | True             | TT_outsideTabard = nil
-- 22 | True       | None             | True              | True             | TT_outsideTabard = "None", review tabard
-- 23 | False      | Link             | True              | True             | TT_outsideTabard = nil, Link tabard equipped
-- 24 | True       | Link             | True              | True             | TT_outsideTabard = "Link", review tabard

function test.testPLAYER_ENTERING_WORLD_01_notInInstance_nilOutside_noEquipped_noValid()  -- False, nil, False, False
	currentInstance = nil
	TT_outsideTabard = nil
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_02_inInstance_nilOutside_noEquipped_noValid()  -- True, nil, False, False
	currentInstance = 14
	TT_outsideTabard = nil
	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "None", TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_03_notInInstance_noneOutside_noEquipped_noValid()  -- False, None, False, False
	currentInstance = nil
	TT_outsideTabard = "None"
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_04_inInstance_noneOutside_noEquipped_noValid()  -- True, None, False, False
	currentInstance = 14
	TT_outsideTabard = "None"
	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "None", TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_05_notInInstance_linkOutside_noEquipped_noValid()  -- False, Link, False, False
	currentInstance = nil
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_06_inIntance_linkOutside_noEquipped_noValid() -- True, Link, False, False
	currentInstance = 14
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_07_notInInstance_nilOutside_isEquipped_noValid() -- False, nil, True, False
	currentInstance = nil
	TT_outsideTabard = nil
	-- set an equipped Tabard
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
	-- assert same tabard
end
function test.testPLAYER_ENTERING_WORLD_08_inInstance_nilOutside_isEquipped_noValid() -- True, nil, True, False
	currentInstance = 14
	TT_outsideTabard = nil
	-- set an equipped Tabard
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
	-- assert same tabard
end
function test.testPLAYER_ENTERING_WORLD_09_notInInstance_noneOutside_isEquipped_noValid() -- False, None, True, False
	currentInstance = nil
	TT_outsideTabard = "None"
	-- set an equipped Tabard
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_10_inInstance_noneOutside_isEquipped_noValid() -- True, None, True, False
	currentInstance = 14
	TT_outsideTabard = "None"
	-- set an equipped Tabard
	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "None", TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_11_notInInstance_linkTTEquipped_isEquipped_noValid() -- False, Link, True, False
	currentInstance = nil
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	-- set an equipped Tabard
	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_12_inInstance_linkTTEquipped_isEquipped_noValid() -- True, Link, True, False
	currentInstance = nil
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	-- set an equipped Tabard
	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
end
function test.testPLAYER_ENTERING_WORLD_notInInstance_nilTTEquipped_noEquipped_Valid() -- False, nil, False, True (58)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_inInstance_nilTTEquipped_noEquipped_Valid() -- True, nil, False, True (59)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_notInInstance_noneTTEquipped_noEquipped_Valid() -- False, None, False, True (60)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_inInstance_noneTTEquipped_noEquipped_Valid() -- True, None, False, True (61)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_notInInstance_nilTTEquipped_isEquipped_Valid() -- False, nil, True, True (62)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_inInstance_nilTTEquipped_isEquipped_Valid() -- True, nil, True, True (63)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_notInInstance_noneTTEquipped_isEquipped_Valid() -- False, None, True, True (64)
	TT.PLAYER_ENTERING_WORLD()
end
function test.testPLAYER_ENTERING_WORLD_inInstance_noneTTEquipped_isEquipped_Valid() -- True, None, True, True (65)
	TT.PLAYER_ENTERING_WORLD()
end


test.run()
