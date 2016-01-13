TT_MSG_VERSION = GetAddOnMetadata("TabardTell","Version");
TT_MSG_ADDONNAME = "TabardTell";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_END = "|r";

TT = {}
TT.errorString = "Unfold all of the faction groups to see your standing for this faction.";
TT.TABARD_EQUIP_FILTER = "Equip:";
TT.TABARD_FACTION_FILTER = "the cause of [the ]*([%u%l%s]+)."  -- 0 or more 'the ', upper, lower, spaces till '.'
TT.lines = {5,6,7};  -- lines of the tooltip to examine
TT.tabardSlot = GetInventorySlotInfo("TabardSlot")

function TT.OnLoad()
	GameTooltip:HookScript("OnTooltipSetItem", TT.HookSetItem)
	ItemRefTooltip:HookScript("OnTooltipSetItem", TT.HookSetItem)
	TTFrame:RegisterEvent("ADDON_LOADED")
end
function TT.ADDON_LOADED()
	TTFrame:UnregisterEvent("ADDON_LOADED");
	TT.OptionsPanel_Reset();
	if TT_options.changeEnabled then
		TTFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		TTFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	TT.Print("Loaded version: "..TT_MSG_VERSION)
	TT.UNIT_INVENTORY_CHANGED()
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
	if factionNameIn then  --  Don't error out if param is nil
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
function TT.UNIT_SPELLCAST_CHANNEL_STOP(...)
	unit, spell, rank, _, spellID = ...
	--TT.Print(unit.." has stopped channeling ".. spell)
	if unit == "player" and spell == TT.castingSpell then
		--TT.Print("-----  Perform SWAP NOW -----")
		TTFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		TT.castingSpell = nil
		TT.PLAYER_ENTERING_WORLD()
	end
end
function TT.UNIT_SPELLCAST_STOP(...)
	unit, spell = ...
	--TT.Print(unit.." has stopped casting "..spell)
	if unit == "player" and spell == TT.castingSpell then
		--TT.Print("----- Perform SWAP NOW -----")
		TTFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
		TT.castingSpell = nil
		TT.PLAYER_ENTERING_WORLD()
	end
end
function TT.PLAYER_REGEN_ENABLED()
	local inInstance = IsInInstance()
	if inInstance then
		local equippedTabbardLink = GetInventoryItemLink( "player", GetInventorySlotInfo( "TabardSlot" ) )
		--TT.Print("Out of combat: "..(equippedTabbardLink or "no tabard").." is equipped.")
		if equippedTabbardLink then
			local name, _, _, _, _, _, _, _, equipSlot = GetItemInfo( equippedTabbardLink )
			local _, _, factionName = strfind( name, "([%u%l%s]+) Tabard" )
			if not factionName then
				_, _, factionName = strfind( name, "Tabard of the ([%u%l%s]+)" )
			end
			local foundFactionName = TT.GetFactionInfo( factionName )
			if TT.fStandingId >= (TT_options.swapRank or 8) then  -- defensive to allow this to be nil
				--TT.Print("You are currently "..TT.fStandingStr.." with "..factionName..". Swapping tabard.")
				spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, interupt = UnitChannelInfo("player")
				--TT.Print((spell or "Nothing").." is being channeled right now."..(spell and (" Ending at :"..endTime) or ""))
				if spell then -- if you are channelling a spell, register the event to swap at end of cast.
					TT.castingSpell = spell
					TTFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
					return  -- channeling a spell, end here.
				end
				spell = UnitCastingInfo("player")
				if spell then
					--TT.Print("Casting "..spell)
					TT.castingSpell = spell
					TTFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
					return  -- casting a spell, end here.
				end
				TT.equipTabbard()
			end
		end
	end
end
function TT.PLAYER_ENTERING_WORLD()
	-- Just entered the world.
	if IsInInstance() then -- in instance
		--TT.Print("inInstance")
		TTFrame:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		TT.equipTabbard()
	else
		--TT.Print("not inInstance")
		if (not UnitIsDeadOrGhost("player")) then
			--TT.Print("You are not dead")
			TTFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
			if TT_outsideTabard then
				TT.equipTabbard( TT_outsideTabard )
			else
				TT.removeTabbard()
			end
--		else
--			TT.Print("You are dead.")
		end
	end
end
function TT.UNIT_INVENTORY_CHANGED()
	local link = GetInventoryItemLink( "player", TT.tabardSlot )
	TT_outsideTabard = link
end
function TT.removeTabbard()
	if TT_options.changeVerbose then TT.Print("Removing the equipped tabard"); end
	ClearCursor()
	local freeBagId = TT.getFreeBag()
	if freeBagId then
		PickupInventoryItem( TT.tabardSlot )
		if freeBagId == 0 then
			PutItemInBackpack()
		else
			PutItemInBag(freeBagId+19)
		end
	else
		TT.Print("Unable to remove equipped tabard.  Bags are full.")
	end
end
function TT.equipTabbard( linkIn )
	-- if link is given, try to equip that tabard
	-- if no link is given, look for one to equip
	if linkIn then
		if (not (linkIn == GetInventoryItemLink( "player", TT.tabardSlot ) ) ) then
			if TT_options.changeVerbose then TT.Print( "Equipping: "..linkIn ); end
			EquipItemByName( linkIn )
		end
	else
		-- find valid tabards to equip
		TT.tabards = {}
		for bag = 0, 4 do
			if GetContainerNumSlots(bag) > 0 then
				for slot = 0, GetContainerNumSlots(bag) do
					local link = GetContainerItemLink( bag, slot )
					if link then
						local name, _, _, _, _, _, _, _, equipSlot = GetItemInfo( link )
						if equipSlot and equipSlot == "INVTYPE_TABARD" then
							local _, _, factionName = strfind( name, "([%u%l%s]+) Tabard" )
							if not factionName then
								_, _, factionName = strfind( name, "Tabard of the ([%u%l%s]+)" )
							end
							--TT.Print("name: "..name.." FactionName: "..(factionName and factionName or "Nil"))
							foundFactionName =  TT.GetFactionInfo( factionName )
							if foundFactionName and (TT.fEarnedValue+1 < TT.fTopValue) then -- only add if not fully exalted
								table.insert( TT.tabards, {["name"] = name, ["earnedValue"] = TT.fEarnedValue, ["link"] = link} )
							end
						end
					end
				end
			end
		end
		-- determine if the currently worn tabard should be considered
		local link = GetInventoryItemLink( "player", TT.tabardSlot )
		if link then  -- you have a tabard equipped
			local name, _, _, _, _, _, _, _, equipSlot = GetItemInfo( link )
			local _, _, factionName = strfind( name, "([%u%l%s]+) Tabard" )
			if not factionName then
				_, _, factionName = strfind( name, "Tabard of the ([%u%l%s]+)" )
			end
			local foundFactionName = TT.GetFactionInfo( factionName )
			--TT.Print("Name: "..foundFactionName..", Earned/Top: "..TT.fEarnedValue.."/"..TT.fTopValue)
			if foundFactionName and (TT.fEarnedValue+1 < TT.fTopValue) then -- only add if not fully exalted
				table.insert( TT.tabards, {["name"] = name, ["earnedValue"] = TT.fEarnedValue, ["link"] = link} )
			end
			--if TT_options.changeVerbose then TT.Print(link.." is equipped"); end
		end
		-- sort the list by earnedValue
		table.sort( TT.tabards, function(a,b) return a.earnedValue<b.earnedValue end ) -- sort by earned Value

		-- equip the first one.
		if TT.tabards[1] then
			if not (TT.tabards[1].link == link) then  -- if the tabard to equip is not already equipped:
				if TT_options.changeVerbose then TT.Print((link and ("Changing from "..link.." to ") or "Equipping: ")..TT.tabards[1].link); end
				EquipItemByName( TT.tabards[1].link )
			end
		else
			if TT_options.changeVerbose then TT.Print("Found no valid tabards to equip"); end
		end

	end
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
