TT_MSG_VERSION = GetAddOnMetadata("Tabard Tell","Version");
TT_MSG_ADDONNAME = "Tabard Tell";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_END = "|r";

TT = {}
TT.errorString = "Unfold all of the faction groups to see your standing for this faction.";
TT.TABARD_EQUIP_FILTER = "Equip:";
TT.TABARD_FACTION_FILTER = "the cause of [the ]*([%u%l%s]+)."  -- 0 or more 'the ', upper, lower, spaces till '.'
TT.lines = {5,6,7};  -- lines of the tooltip to examine

function TT.OnLoad()
	GameTooltip:HookScript("OnTooltipSetItem", TT.HookSetItem)
	ItemRefTooltip:HookScript("OnTooltipSetItem", TT.HookSetItem)

	if TT_options.changeEnabled then
		TTFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end
function TT.GetEquipTextFromToolTip()
	for _,i in pairs(TT.lines) do
		TT.text = getglobal("GameTooltipTextLeft"..i):GetText();
		if TT.text and strfind(TT.text, TT.TABARD_EQUIP_FILTER) then
			return TT.text;
		end
	end
end
function TT.HookSetItem(tooltip, ...)
	TT.item = tooltip:GetItem();
	if TT.item then
		TT.slot = select(9,GetItemInfo(TT.item));
		if TT.slot == "INVTYPE_TABARD" then
			TT.itemEquip = TT.GetEquipTextFromToolTip();
			if TT.itemEquip then
				_, _, TT.faction = strfind(TT.itemEquip, TT.TABARD_FACTION_FILTER);
				if TT.faction then
					_, _, TT.standing, _, TT.topVal, TT.currentVal = TT.GetFactionInfo( TT.faction );
					if TT.standing then
						TT.factionString = string.format("\n%s %s / %s (%0.2f%%)",
								TT.standing, TT.currentVal, TT.topVal, (TT.currentVal / TT.topVal) * 100);
						tooltip:AddLine(TT.factionString);
					else
						tooltip:AddLine(TT.errorString);
					end
				end
			end
		end
	end
end
-- return a list of faction info
function TT.GetFactionInfo( factionNameIn )
	for factionIndex = 1, GetNumFactions() do
		TT.fName, TT.fDescription, TT.fStandingId, TT.fBottomValue, TT.fTopValue, TT.fEarnedValue, TT.fAtWarWith,
				TT.fCanToggleAtWar, TT.fIsHeader, TT.fIsCollapsed, TT.fIsWatched = GetFactionInfo(factionIndex);
		if TT.fIsCollapsed then
			ExpandFactionHeader(factionIndex);
		end
		TT.fBarBottomValue = 0;
		TT.fBarTopValue = TT.fTopValue - TT.fBottomValue;
		TT.fBarEarnedValue = TT.fEarnedValue - TT.fBottomValue;
		TT.fStandingStr = getglobal("FACTION_STANDING_LABEL"..TT.fStandingId);

		if not TT.fIsHeader and strfind(TT.fName, factionNameIn) then
			return TT.fName, TT.fDescription, TT.fStandingStr, TT.fBarBottomValue, TT.fBarTopValue, TT.fBarEarnedValue,
					TT.fAtWarWith, TT.fCanToggleAtWar, TT.fIsHeader, TT.fIsCollapsed, TT.fIsWatched, factionIndex;
		end
	end
end
function TT.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_RED..TT_MSG_ADDONNAME.."> "..COLOR_END..msg;
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end
------------
-- Equip Code
------------
function TT.PLAYER_ENTERING_WORLD()
	local inInstance = IsInInstance()
	if inInstance then
		if TT_options.changeVerbose then TT.Print("You have entered an Instance"); end
		TT.tabards = {}
		for bag = 0, 4 do
			if GetContainerNumSlots(bag) > 0 then
				for slot = 0, GetContainerNumSlots(bag) do
					local link = GetContainerItemLink( bag, slot )
					if link then
						local name, _, _, _, _, _, _, _, equipSlot = GetItemInfo( link )
						if equipSlot and equipSlot == "INVTYPE_TABARD" then
							local _, _, factionName = strfind( name, "([%u%l%s]+) Tabard" )
							TT.GetFactionInfo( factionName )
							if TT.fName == factionName then
								table.insert( TT.tabards, {["name"] = name, ["earnedValue"] = TT.fEarnedValue, ["link"] = link} )
							end
						end
					end
				end
			end
		end
		local slotNum = GetInventorySlotInfo("TabardSlot");
		local link = GetInventoryItemLink( "player", slotNum )
		if link then
			local name, _, _, _, _, _, _, _, equipSlot = GetItemInfo( link )
			local _, _, factionName = strfind( name, "([%u%l%s]+) Tabard" )
			TT.GetFactionInfo( factionName )
			if TT.fName == factionName then
				table.insert( TT.tabards, {["name"] = name, ["earnedValue"] = TT.fEarnedValue, ["link"] = link} )
			end
			if TT_options.changeVerbose then TT.Print(link.." is equipped"); end
			if not TT_equippedTabbard then  -- if set, don't overwrite
				TT_equippedTabbard = link
			end
		end

		table.sort( TT.tabards, function(a,b) return a.earnedValue<b.earnedValue end ) -- sort by earned Value

		if TT.tabards[1] then
			if TT_options.changeVerbose then TT.Print("Equipping: "..TT.tabards[1]["link"]); end
			EquipItemByName( TT.tabards[1]["link"] )
		else
			if TT_options.changeVerbose then TT.Print("Found no valid tabards to equip"); end
		end
	else
		if TT_equippedTabbard then
			if TT_options.changeVerbose then TT.Print("I should re-equip: "..TT_equippedTabbard); end
			EquipItemByName( TT_equippedTabbard )
			TT_equippedTabbard = nil
		else
			if TT_options.changeVerbose then TT.Print("I should remove the equipped tabard"); end
			ClearCursor()
			local freeBagId = TT.getFreeBag()
			if freeBagId then
				local slotNum = GetInventorySlotInfo("TabardSlot")
				PickupInventoryItem( slotNum )
				if freeBagId == 0 then
					PutItemInBackpack()
				else
					PutItemInBag(freeBagId+19)
				end
			else
				TT.Print("Unable to remove equipped tabard.  Bags are full.")
			end
		end
	end
	-- EquipItemByName( Stripper.targetSetItemArray[i], i )
	--Stripper.RemoveFromSlot( "TabardSlot", true )
end
function TT.getFreeBag()
	-- http://www.wowwiki.com/BagId
	local freeid, typeid
	for bagid = NUM_BAG_SLOTS, 0, -1 do
		freeid, typeid = GetContainerNumFreeSlots(bagid)
		if  freeid > 0 and typeid == 0 then
			return bagid
		end
	end
	return nil
end
