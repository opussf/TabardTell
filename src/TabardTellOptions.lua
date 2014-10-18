TT_options = {
	["changeEnabled"] = true,
	["changeVerbose"] = true,
}


function TT.OptionsPanel_OnLoad(panel)
	panel.name = "Tabard Tell";
	TabardTellOptionsFrame_Title:SetText(FB_MSG_ADDONNAME.." "..FB_MSG_VERSION);
	--panel.parent="";
	panel.okay = TT.OptionsPanel_OKAY;
	panel.cancel = TT.OptionsPanel_Cancel;
	panel.default = TT.OptionsPanel_Default;
--	panel.refresh = TT.OptionsPanel_Refresh;

	InterfaceOptions_AddCategory(panel);
	InterfaceAddOnsList_Update();
end

function TT.OptionsPanel_OKAY()
	-- Data was recorded, clear the temp
	TT.oldValues = nil;
	if TT_options.changeEnabled then
		TTFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	else
		TTFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end
function TT.OptionsPanel_Cancel()
	-- reset to temp and update the UI
	if TT.oldValues then
		for key,val in pairs(TT.oldValues) do
			--FB.Print(key..":"..val);
			TT_options[key] = val;
		end
	end
	TT.oldValues = nil;
	TT.OptionsPanel_Reset();	-- Call this once the values are restored to reset the UI
end
function TT.OptionsPanel_Default()
	TT_options = {
		["changeEnabled"] = true,
		["changeVerbose"] = true,
	}
end

function TT.OptionsPanel_Reset() -- Called from the ADDON_LOADED event function
--	FB.OptionsPanel_NumBarSlider_Init(FactionBarsOptionsFrame_NumBars);
--	FB.OptionsPanel_TrackPeriodSlider_Init(FactionBarsOptionsFrame_TrackPeriodSlider);
end
-------
function TT.OptionsPanel_CheckButton_OnLoad( self, option, text )
	getglobal(self:GetName().."Text"):SetText(text);
	self:SetChecked(FB_options[option]);
end
function TT.OptionsPanel_CheckButton_PostClick( self, option )
	if TT.oldValues then
		TT.oldValues[option] = TT.oldValues[option] or TT_options[option];
	else
		TT.oldValues={[option]=TT_options[option]};
	end
	TT_options[option] = self:GetChecked();
end
