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

TTFrame = CreateFrame()

-- addon setup
function test.before()
end
function test.after()
end

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
---------
-- if the player is outside of an instance (inInstance() == false) then:
--    Set the tabard to what TT_outsideTabard is set to, or none if nil.
--    Register the UNIT_INVENTORY_CHANGED event
-- on UNIT_INVENTORY_CHANGED event fired:
--    Set TT_outsideTabard to what ever tabard is set (or nil if none)
-- on entering an instance:
--    UnRegister the UNIT_INVENTORY_CHANGED event
--    Set any tabard you want.
---------
-- PLAYER_ENTERING_WORLD
-- id | inInstance | TT_outsideTabard | HasTabardEquipped | ValidTabardInBag | result
--------------------------------------------------------------------------------------
-- 01 | False      | nil              | False             | False            | TT_outsideTabard = nil, UNIT_INVENTORY_CHANGED is registered
-- 02 | True       | nil              | False             | False            | TT_outsideTabard = nil, UNIT_INVENTORY_CHANGED is not registered
-- 03 | False      | Link             | False             | False            | TT_outsideTabard = Link, EquippedTabard = nil, UIC registered
-- 04 | True       | Link             | False             | False            | TT_outsideTabard = Link, no changes, UIC not registered
-- 05 | False      | nil              | True              | False            | TT_outsideTabard = nil, clear EquippedTabard, UIC registered
-- 06 | True       | nil              | True              | False            | TT_outsideTabard = nil, probably keep tabard, UIC not registered
-- 07 | False      | Link             | True              | False            | TT_outsideTabard = Link, equipped = Link, UIC registered
-- 08 | True       | Link             | True              | False            | TT_outsideTabard = Link, probably keep tabard, UIC not registered
-- 09 | False      | nil              | False             | True
-- 10 | True       | nil              | False             | True



function test.testPLAYER_ENTERING_WORLD_01_notInInstance_nilOutside_noEquipped_noValid()
	currentInstance = nil
	TT_outsideTabard = nil
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = nil
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard, "This should continue to be nil." )
	assertTrue( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should be registered." )
end
function test.testPLAYER_ENTERING_WORLD_02_inInstance_nilOutside_noEquipped_noValid()
	currentInstance = 14
	TT_outsideTabard = nil
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = nil
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard, "Nothing equipped when entering." )
	assertIsNil( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should not be registered." )
end
function test.testPLAYER_ENTERING_WORLD_03_notInInstance_linkOutside_noEquipped_noValid()
	-- Tossed the tabard out while inside the dungeon?
	currentInstance = nil
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = nil
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
	assertIsNil( myGear[tabardSlot], "No tabard equipped.")
	assertTrue( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should be registered." )
end
function test.testPLAYER_ENTERING_WORLD_04_inInstance_linkOutside_noEquipped_noValid()
	currentInstance = 14
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = nil
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
	assertIsNil( myGear[tabardSlot], "None should be equipped." )
	assertIsNil( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should not be registered." )
end
function test.testPLAYER_ENTERING_WORLD_05_notInstance_nilOutside_hasEquipped_noValid()
	currentInstance = nil
	TT_outsideTabard = nil
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard, "Should only be changed when outside the instance." )
	assertIsNil( myGear[tabardSlot], "Equipped tabard should be cleared." )
	assertTrue( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should be registered." )
end
function test.testPLAYER_ENTERING_WORLD_06_inInstance_nilOutside_hasEquipped_noValid()
	currentInstance = 14
	TT_outsideTabard = nil
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertIsNil( TT_outsideTabard, "Should only be changed when outside the instance." )
	assertEquals( "45579", myGear[tabardSlot] )
	assertIsNil( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should not be registered." )
end
function test.testPLAYER_ENTERING_WORLD_07_notInInstance_linkOutside_hasEquipped_noValid()
	currentInstance = nil
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
	assertEquals( "45579", myGear[tabardSlot] )
	assertTrue( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should be registered." )
end
function test.testPLAYER_ENTERING_WORLD_08_inInstance_linkOutside_hasEquipped_noValid()
	currentInstance = 14
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
	assertEquals( "45579", myGear[tabardSlot], "No changes made" )
	assertIsNil( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should not be registered." )
	currentInstance = 14
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
	assertEquals( "45579", myGear[tabardSlot] )
	assertIsNil( TTFrame.Events.UNIT_INVENTORY_CHANGED, "UNIT_INVENTORY_CHANGED should not be registered." )
end

-- UNIT_INVENTORY_CHANGED
-- id | TT_outsideTabard | HasTabardEquipped | result
------------------------------------------------------
-- 01 | nil              | False             | TT_outsideTabard = nil
-- 02 | Link             | False             | TT_outsideTabard = nil
-- 03 | nil              | True              | TT_outsideTabard = Link
-- 04 | Link (current)   | True              | TT_outsideTabard = Link (current)
-- 05 | Link (not curr)  | True              | TT_outsideTabard = Link (current)

function test.testUNIT_INVENTORY_CHANGED_01_nilOutside_noEquipped()
	TT_outsideTabard = nil
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = nil

	TT.UNIT_INVENTORY_CHANGED()
	assertIsNil( TT_outsideTabard )
end
function test.testUNIT_INVENTORY_CHANGED_02_linkOutside_noEquipped()
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = nil

	TT.UNIT_INVENTORY_CHANGED()
	assertIsNil( TT_outsideTabard )
end
function test.testUNIT_INVENTORY_CHANGED_03_nilOutside_hasEquipped()
	TT_outsideTabard = nil
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"

	TT.UNIT_INVENTORY_CHANGED()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
end
function test.testUNIT_INVENTORY_CHANGED_04_linkOutside_hasEquipped()
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"

	TT.UNIT_INVENTORY_CHANGED()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
end
function test.testUNIT_INVENTORY_CHANGED_05_linkOutside_hasEquipped()
	TT_outsideTabard = "|cffffffff|Hitem:45580:0:0:0:0:0:0:0:14:258:0:0:0|h[Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"

	TT.UNIT_INVENTORY_CHANGED()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
end

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

--[[
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
]]

test.run()
