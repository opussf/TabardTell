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
-- 09 | False      | nil              | False             | True             | TT_outsideTabard = nil, UIC registered
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
function test.notestPLAYER_ENTERING_WORLD_03_notInInstance_linkOutside_noEquipped_noValid()
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
function test.notestPLAYER_ENTERING_WORLD_05_notInstance_nilOutside_hasEquipped_noValid()
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
function test.notestPLAYER_ENTERING_WORLD_06_inInstance_nilOutside_hasEquipped_noValid()
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
function test.notestPLAYER_ENTERING_WORLD_07_notInInstance_linkOutside_hasEquipped_noValid()
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
function test.notestPLAYER_ENTERING_WORLD_08_inInstance_linkOutside_hasEquipped_noValid()
	currentInstance = 14
	TT_outsideTabard = "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"
	myInventory = {}

	TT.PLAYER_ENTERING_WORLD()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
	assertEquals( "45579", myGear[tabardSlot], "No changes made" )
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
	TT_outsideTabard = "|cffffffff|Hitem:45580:0:0:0:0:0:0:0:14:258:0:0:0|h[Exodar Tabard]|h|r"
	tabardSlot = GetInventorySlotInfo("TabardSlot")
	myGear[tabardSlot] = "45579"

	TT.UNIT_INVENTORY_CHANGED()
	assertEquals( "|cffffffff|Hitem:45579:0:0:0:0:0:0:0:14:258:0:0:0|h[Darnassus Tabard]|h|r", TT_outsideTabard )
end

test.run()
