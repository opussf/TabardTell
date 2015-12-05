#!/usr/bin/env lua

addonData = { ["version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- Figure out how to parse the XML here, until then....

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "TabardTell"


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

function test.testFactionInfo_nil()
	assertIsNil( TT.GetFactionInfo() )
end
function test.testFactionInfo_fName()
	fName = TT.GetFactionInfo( "Stormwind" )
	assertEquals( "Stormwind", fName )
end
function test.testFactionInfo_fDescription()
	_, fDescription = TT.GetFactionInfo( "Stormwind" )
	assertEquals( "", fDescription )
end
function test.testFactionInfo_fStandingStr()
	_, _, fStandingStr = TT.GetFactionInfo( "Stormwind" )
	assertEquals( "Revered", fStandingStr )
end
function test.testFactionInfo_fBarBottomValue()
	fBarBottomValue = select(4, TT.GetFactionInfo( "Stormwind" ) )
	assertEquals( 0, fBarBottomValue )
end
function test.testFactionInfo_fBarTopValue()
	fBarTopValue = select(5, TT.GetFactionInfo( "Stormwind" ) )
	assertEquals( 21000, fBarTopValue )
end
function test.testFactionInfo_fBarEarnedValue()
	fBarEarnedValue = select(6, TT.GetFactionInfo( "Stormwind" ) )
	assertEquals( 12397, fBarEarnedValue )
end
function test.testFactionInfo_fAtWarWith()
	fAtWarWith = select(7, TT.GetFactionInfo( "Stormwind" ) )
	assertFalse( fAtWarWith )
end
function test.testFactionInfo_fCanToggleAtWar()
	fCanToggleAtWar = select(8, TT.GetFactionInfo( "Stormwind" ) )
	assertFalse( fCanToggleAtWar )
end
function test.testFactionInfo_fIsHeader()
	fIsHeader = select(9, TT.GetFactionInfo( "Stormwind" ) )
	assertFalse( fIsHeader )
end
function test.testFactionInfo_fIsHeader_header()
	-- GetFactionInfo does not return values if it is a header
	fIsHeader = select(9, TT.GetFactionInfo( "Alliance" ) )
	assertFalse( fIsHeader )
end
function test.testFactionInfo_fIsCollapsed()
	fIsCollapsed = select(10, TT.GetFactionInfo( "Stormwind" ) )
	assertFalse( fIsCollapsed )
end
function test.testFactionInfo_fIsWatched()
	fIsWatched = select(11, TT.GetFactionInfo( "Stormwind" ) )
	assertFalse( fIsWatched )
end
function test.testFactionInfo_factionIndex()
	factionIndex = select(12, TT.GetFactionInfo( "Stormwind" ) )
	assertEquals( 4, factionIndex )
end
function test.testFactionInfo_ExpandsHeaders()
	FactionInfo[1].isCollapsed = true
	FactionInfo[3].isCollapsed = true
	fName = TT.GetFactionInfo( "Stormwind" ) -- 4th faction
	assertEquals( "Stormwind", fName )	-- found the faction
	assertFalse( FactionInfo[3].isCollapsed ) -- assert that it is not collapsed
end
function test.testGetFreeBag_onlyBackPack()
	-- default is to only have the backpack equiped
	local bagID = TT.getFreeBag()
	assertEquals( 0, bagID )
end
function test.testGetFreeBag_2Bags()
	bagInfo[1] = {10, 0}
	local bagID = TT.getFreeBag()
	assertEquals( 1, bagID )
	bagInfo[1] = nil
end
function test.testGetFreeBag_2Bags_firstIsFull()
	bagInfo[1] = {0, 0}
	local bagID = TT.getFreeBag()
	assertEquals( 0, bagID )
	bagInfo[1] = nil
end

test.run()
