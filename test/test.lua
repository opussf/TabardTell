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

test.run()
