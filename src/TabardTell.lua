TT_MSG_VERSION = GetAddOnMetadata("Tabard Tell","Version");
TT_MSG_ADDONNAME = "Tabard Tell";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_END = "|r";

TT = {};
TT.errorString = "Unfold all of the faction groups to see your standing for this faction.";
TT.TABARD_EQUIP_FILTER = "Equip:";
TT.TABARD_FACTION_FILTER = "the cause of [the ]*([%u%l%s]+)."  -- 0 or more 'the ', upper, lower, spaces till '.'
TT.lines = {5,6,7};  -- lines of the tooltip to examine

function TT.OnLoad()
	GameTooltip:HookScript("OnTooltipSetItem", TT.HookSetItem)
	ItemRefTooltip:HookScript("OnTooltipSetItem", TT.HookSetItem)
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
