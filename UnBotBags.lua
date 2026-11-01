function UnBotTick(bagsFrame, tick)
	if (bagsFrame.lastFlushTick > 0) then
		if  ((tick - bagsFrame.lastFlushTick) > bagsFrame.waitFlushTime) then
			bagsFrame.lastFlushTick = 0;
			UnBotEnableAllFrameFlushButton();
		end
	end
	if (bagsFrame.queryQueue ~= nil) then
		UnBotProcessItemQuery(bagsFrame, tick);
	end
	if (bagsFrame.pendingTradeLink ~= nil and UnBotBagsTradeIsOpen() == true) then
		UnBotBagsSendPendingTrade(bagsFrame);
	end
	if (bagsFrame.pendingTradeRefreshTick ~= nil) then
		if ((tick - bagsFrame.pendingTradeRefreshTick) >= 1) then
			bagsFrame.pendingTradeRefreshTick = nil;
			if (bagsFrame.flushFunc ~= nil) then
				bagsFrame.flushFunc(bagsFrame, bagsFrame.command);
				UnBotDisableAllFrameFlushButton();
			end
		end
	end
end

function UnBotBagsTradeIsOpen()
	if (TradeFrame ~= nil and (TradeFrame:IsShown() or TradeFrame:IsVisible())) then
		return true;
	end
	return false;
end

function UnBotBagsSendPendingTrade(bagsFrame)
	if (bagsFrame == nil or bagsFrame.pendingTradeLink == nil) then
		return;
	end
	SendChatMessage(bagsFrame.pendingTradeLink, "WHISPER", nil, bagsFrame.target);
	bagsFrame.pendingTradeLink = nil;
	bagsFrame.needTradeRefresh = true;
end

function UnBotBagsOnTradeShow(bagsFrame)
	UnBotBagsSendPendingTrade(bagsFrame);
end

function UnBotBagsOnTradeClosed(bagsFrame)
	if (bagsFrame == nil) then
		return;
	end
	if (bagsFrame.pendingTradeLink ~= nil) then
		return;
	end
	if (bagsFrame.needTradeRefresh == true and bagsFrame.flushFunc ~= nil) then
		bagsFrame.needTradeRefresh = nil;
		bagsFrame.pendingTradeRefreshTick = GetTime();
	end
end

function UnBotCanFlushInfo(bagsFrame)
	if (bagsFrame == nil) then
		return false;
	end
	if (bagsFrame.lastFlushTick > 0) then
		return true;
	else
		return false;
	end
end

function UnBotBagsHeadFrameSetFontText(rece, name, info)
	local text = "|cff0000cc"..rece.."|r|cff00cccc"..name.."|r-|cffcccccc"..info.."|r";
	return text;
end

function UnBotGetCostEnergyText(costType, costValue)
	if (costValue <= 0) then
		return " ";
	end
	if (costType == 0) then
		return "Costs " .. tostring(costValue) .. " Mana";
	elseif (costType == 1) then
		return "Costs " .. tostring(costValue) .. " Rage";
	elseif (costType == 3) then
		return "Costs " .. tostring(costValue) .. " Energy";
	else
		return "Costs " .. tostring(costValue) .. " Resources";
	end
end
local function CreateIconGroupByParent(fromParent,hheadGap,vheadGap,hnum,vnum,hgap,vgap,size)
	if (fromParent == nil) then
		return nil;
	end
	local iconsGroup = {};
	local iconsIndex = 1;
	for v=1, vnum do
		for h=1, hnum do
			local newFrame = CreateFrame("Button","BGIconsFrame"..tostring(iconsIndex),fromParent,"UnBotBagsButtonTemplate");
			newFrame.bagsIcon = nil;
			newFrame.iconIndex = -1;
			newFrame.Icon = newFrame:CreateTexture("BGIcons"..tostring(iconsIndex),"BACKGROUND");
			newFrame.Icon:SetTexture(fromParent.disableIcon);
			newFrame.Icon:SetAllPoints(newFrame);
			newFrame.Icon:Show();
			newFrame:SetPushedTexture([[Interface\BUTTONS\UI-Quickslot-Depress]]);
			newFrame:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]],"ADD");
			newFrame:Show();
			local offsetX = hheadGap+(h-1)*size+hgap*h;
			local offsetY = (vheadGap+(v-1)*size+vgap*v)*(-1);
			newFrame:SetPoint("TOPLEFT", fromParent, "TOPLEFT", offsetX, offsetY);
			newFrame.index = iconsIndex;
			iconsGroup[iconsIndex] = newFrame;
			iconsIndex = iconsIndex + 1;
			newFrame.countLabel = newFrame:CreateFontString(newFrame:GetName().."Count","OVERLAY");
			newFrame.countLabel:SetFont([[Fonts\ARIALN.TTF]],12);
			newFrame.countLabel:SetTextColor(0.8,0,0.8,1);
			newFrame.countLabel:SetHeight(12);
			newFrame.countLabel:SetText(" ");
			newFrame.countLabel:SetPoint("BOTTOMRIGHT",newFrame,"BOTTOMRIGHT",-2,2);
			newFrame.countLabel:SetJustifyH("RIGHT");
			newFrame.countLabel:SetJustifyV("BOTTOM");
			newFrame.countLabel:SetShadowColor(0.1,0.1,0.1);
			newFrame.countLabel:SetShadowOffset(1,-1);
			newFrame:SetScript("OnEnter", function() UnBotShowButtonTips(newFrame, fromParent) end);
			newFrame:SetScript("OnLeave", function() GameTooltip:Hide() end);
			newFrame:SetScript("OnClick", function(self, button)
				local over = ExecuteCommandByBagsItem(fromParent,newFrame.dataIndex);
				if (over == true and fromParent.afterRemove) then
					RemoveByIndex(fromParent,newFrame.dataIndex);
				end
			end);
			newFrame:SetScript("OnMouseUp", function(self, button)
				if (button == "RightButton") then
					RemoveByIndex(fromParent,newFrame.dataIndex);
				end
			end);
		end
	end
	return iconsGroup;
end

function UnBotShowButtonTips(newFrame, fromParent)
	if (newFrame.bagsIcon ~= nil) then
		GameTooltip:SetOwner(newFrame, "ANCHOR_TOPRIGHT");
		local itemID = fromParent.dataGroup[ newFrame.dataIndex ][ 2 ];
		if (itemID ~= nil and itemID > 0) then
			local needQuery = fromParent.dataGroup[ newFrame.dataIndex ][ 5 ];
			if (needQuery == false) then
				if (fromParent.bagsType == 1) then
					local queryLink = UnBotGetItemQueryLink(fromParent.dataGroup[ newFrame.dataIndex ]);
					GameTooltip:SetHyperlink(queryLink or ("item:"..itemID..":0:0:0:0:0:0:0"));
					if (fromParent.dataGroup[ newFrame.dataIndex ][ 7 ] ~= nil and fromParent.dataGroup[ newFrame.dataIndex ][ 7 ] > 1) then
						GameTooltip:AddLine(" ",1,1,1,1);
						GameTooltip:AddDoubleLine("Owned Count:", tostring(fromParent.dataGroup[ newFrame.dataIndex ][ 7 ]), 0, 0.8, 0.8, 0.8, 0.8, 0);
					end
				elseif (fromParent.bagsType == 2) then
					local spellLink = GetSpellLink(itemID);
					if (spellLink ~= nil) then
						GameTooltip:SetHyperlink(spellLink);
					else
						local spellData = fromParent.dataGroup[ newFrame.dataIndex ];
						GameTooltip:AddLine(spellData[ 3 ],1,0,0,1);
						GameTooltip:AddDoubleLine(UnBotGetCostEnergyText(spellData[ 7 ],spellData[ 8 ]),tostring(spellData[ 6 ]),1,1,1,0.5,0.5,0.5);
						local castDis = "";
						if (spellData[ 10 ] <= 0) then
							castDis = "Self Cast";
						else
							castDis = tostring(spellData[ 10 ]) .. " yd Range";
						end
						if (spellData[ 9 ] <= 0) then
							GameTooltip:AddDoubleLine("Instant Cast",castDis,0.65,0.55,0,0,0.8,0.8);
						else
							GameTooltip:AddDoubleLine(tostring(spellData[ 9 ]/1000) .. " sec cast", castDis, 0.65, 0.55, 0, 0, 0.8, 0.8);
						end
					end
				end
			else
				GameTooltip:AddLine(fromParent.dataGroup[ newFrame.dataIndex ][ 3 ],1,0,0,1);
				GameTooltip:AddLine("This item is unknown. Click the ? button next to close to query the server.", 1, 0, 0, 1);
			end
			GameTooltip:AddLine(" ",1,1,1,1);
			if (fromParent.command ~= nil and fromParent.command ~= "") then
				GameTooltip:AddLine("Left-click: Make " .. fromParent.target .. " " .. fromParent.activeText, 0.65, 0.55, 0, 1);
			end
			if (fromParent.bagsType == 1) then
				GameTooltip:AddLine("Right-click: Hide this item",0.65,0.55,0,1);
			elseif (fromParent.bagsType == 2) then
				GameTooltip:AddLine("Right-click: Hide this spell",0.65,0.55,0,1);
			else
				GameTooltip:AddLine("Right-click: Hide this icon",0.65,0.55,0,1);
			end
			if (fromParent.bagsType == 2) then
				GameTooltip:AddDoubleLine("Spell ID:",tostring(itemID),0,0.8,0.8,0.8,0,0);
			end
		else
			GameTooltip:AddLine(newFrame.bagsIcon);
		end
		GameTooltip:AddDoubleLine("Index Order:", tostring(newFrame.iconIndex), 0, 0, 1, 1, 0, 1);
		GameTooltip:AddTexture(fromParent.dataGroup[ newFrame.dataIndex ][ 4 ]);
		GameTooltip:Show();
	end
end
local function CreateBagsTypeOptions(fromParent, checkedIndex)
	if (fromParent == nil or checkedIndex == nil) then
		return nil;
	end
	
	-- 1. View Option
	local newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType1",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("View");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = nil;
	newFrame.afterRemove = false;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " View Items");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 1);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 1) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end
	
	-- 2. Equip Option
	newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType2",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("Equip");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = UnBotExecuteCommand[ 66 ];
	newFrame.afterRemove = true;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " Equip Items");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 2);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 2) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end
	
	-- 3. Destroy Option
	newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType3",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("Destroy");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = UnBotExecuteCommand[ 65 ];
	newFrame.afterRemove = true;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " Destroy Items");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 3);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 3) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end
	
	-- 4. Sell Option
	newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType4",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("Sell");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = UnBotExecuteCommand[ 67 ];
	newFrame.afterRemove = true;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " Sell Items");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 4);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 4) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end
	
	-- 5. Use Option
	newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType5",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("Use");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = UnBotExecuteCommand[ 68 ];
	newFrame.afterRemove = true;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " Use Items");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 5);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 5) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end

	-- 6. Gbank Option
	newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType6",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("Gbank");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = "gb ";
	newFrame.afterRemove = true;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " Guild Bank deposit");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 6);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 6) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end

	-- 7. Trade Option
	newFrame = CreateFrame("CheckButton",fromParent:GetName().."BagsType7",fromParent,"UnBotBagsTypeTemplate");
	newFrame.title = newFrame:CreateFontString(newFrame:GetName().."Title","ARTWORK");
	newFrame.title:SetFont([[Fonts\ARIALN.TTF]],20);
	newFrame.title:SetTextColor(1.0,0.8,0,1);
	newFrame.title:SetText("Trade");
	newFrame.title:SetPoint("TOPLEFT",newFrame,"TOPRIGHT",2,-5);
	newFrame.title:SetShadowColor(0,0,0);
	newFrame.title:SetShadowOffset(1,-1);
	newFrame:Show();
	newFrame.parentFrame = fromParent;
	newFrame.command = "trade ";
	newFrame.afterRemove = false;
	newFrame.parentFrameText = UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, " Trade Items");
	newFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -70, -24 * 7);
	table.insert(fromParent.optionsType, newFrame);
	if (checkedIndex == 7) then
		BagsTypeOptionsClick(newFrame, fromParent, newFrame.afterRemove);
	end

	for i=1, #(fromParent.optionsType) do
		fromParent.optionsType[ i ]:SetHitRectInsets(0, -70, 0, 0);
	end
end

function BagsTypeOptionsClick(self, bagsFrame, afterRemove)
	for i=1, #(bagsFrame.optionsType) do
		if (bagsFrame.optionsType[ i ] ~= self) then
			bagsFrame.optionsType[ i ]:SetChecked(false);
		else
			bagsFrame.optionsType[ i ]:SetChecked(true);
		end
	end
	bagsFrame.title:SetText(self.parentFrameText);
	bagsFrame.command = self.command;
	bagsFrame.afterRemove = afterRemove;
	if (self.command == "trade ") then
		bagsFrame.tradeMode = true;
	else
		bagsFrame.tradeMode = nil;
		bagsFrame.pendingTradeLink = nil;
	end
end
local function CreateOptionByParent(fromParent,flushFunc)
	if (fromParent == nil) then
		return nil;
	end

	fromParent.title = fromParent:CreateFontString(fromParent:GetName().."Title","ARTWORK");
	fromParent.title:SetFont([[Fonts\ARIALN.TTF]],15);
	fromParent.title:SetTextColor(1.0,1.0,1.0,1);
	fromParent.title:SetText(UnBotBagsHeadFrameSetFontText(fromParent.raceName, fromParent.target, fromParent.activeText));
	fromParent.title:SetPoint("TOPLEFT",fromParent,"TOPLEFT",10,-8);
	fromParent.title:SetShadowColor(0,0,0);
	fromParent.title:SetShadowOffset(1,-1);

	fromParent.page = fromParent:CreateFontString(fromParent:GetName().."Page","ARTWORK");
	fromParent.page:SetFont([[Fonts\ARIALN.TTF]],15);
	fromParent.page:SetTextColor(1.0,1.0,1.0,1);
	fromParent.page:SetText("0-0");
	fromParent.page:SetPoint("CENTER",fromParent,"BOTTOMLEFT",90,22);
	fromParent.page:SetShadowColor(0,0,0);
	fromParent.page:SetShadowOffset(1,-1);

	local newFrame = CreateFrame("Button","BGIconsFrame",fromParent,"UnBotBagsButtonTemplate");
	newFrame.Icon = newFrame:CreateTexture("BGIcons","BACKGROUND");
	newFrame.Icon:SetTexture([[Interface\BUTTONS\UI-SpellbookIcon-PrevPage-Up]]);
	newFrame.Icon:SetAllPoints(newFrame);
	newFrame.Icon:Show();
	newFrame:SetPushedTexture([[Interface\BUTTONS\UI-SpellbookIcon-PrevPage-Down]]);
	newFrame:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]],"ADD");
	newFrame:Show();
	newFrame:SetPoint("BOTTOMLEFT", fromParent, "BOTTOMLEFT", 10, 6);
	newFrame.parentFrame = fromParent;
	newFrame:SetScript("OnClick", function() PickPrevOrNextButton(fromParent,true) end);

	newFrame = CreateFrame("Button","BGIconsFrame",fromParent,"UnBotBagsButtonTemplate");
	newFrame.Icon = newFrame:CreateTexture("BGIcons","BACKGROUND");
	newFrame.Icon:SetTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]]);
	newFrame.Icon:SetAllPoints(newFrame);
	newFrame.Icon:Show();
	newFrame:SetPushedTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Down]]);
	newFrame:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]],"ADD");
	newFrame:Show();
	newFrame:SetPoint("BOTTOMLEFT", fromParent, "BOTTOMLEFT", 140, 6);
	newFrame.parentFrame = fromParent;
	newFrame:SetScript("OnClick", function() PickPrevOrNextButton(fromParent,false) end);

	newFrame = CreateFrame("Button","BagsFrameFlush"..fromParent:GetName(),fromParent,"UIPanelButtonTemplate");
	newFrame:SetText("Refresh");
	newFrame:SetWidth(60);
	newFrame:SetHeight(26);
	newFrame:Show();
	newFrame:SetPoint("BOTTOMLEFT", fromParent, "BOTTOMLEFT", 180, 9);
	newFrame:SetScript("OnClick", function()
		if (flushFunc ~= nil) then
			flushFunc(fromParent,fromParent.command);
			UnBotDisableAllFrameFlushButton();
		end
	end);

	local closeFrame = CreateFrame("Button","BGIconsFrame",fromParent,"UIPanelCloseButton");
	closeFrame:SetWidth(40);
	closeFrame:SetHeight(40);
	closeFrame:Show();
	closeFrame:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", 5, 5);
	closeFrame:SetScript("OnClick", function()
		RemoveFromUnBotFrame(fromParent)
		fromParent:Hide()
		fromParent:SetParent(nil)
	end);

	if (fromParent.bagsType == 1) then
		local headerFrame = _G[fromParent:GetName().."Head"];
		local headerLevel = fromParent:GetFrameLevel() + 4;
		if (headerFrame ~= nil) then
			headerLevel = headerFrame:GetFrameLevel() + 2;
		end

		local soulBtn = CreateFrame("Button", fromParent:GetName().."SoulboundButton", fromParent, "UnBotBagsSoulboundButtonTemplate");
		-- Soulbound toggle: 16x16 matching Assets\soulbound_16.blp. Left of the query button.
		soulBtn:SetWidth(16);
		soulBtn:SetHeight(16);
		soulBtn:Show();
		soulBtn:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -56, -8);
		soulBtn:SetFrameLevel(headerLevel);
		UnBotApplySoulboundButton(soulBtn);
		soulBtn:SetScript("OnClick", function()
			GameTooltip:Hide();
			UnBotToggleIgnoreSoulbound();
		end);
		soulBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
			GameTooltip:AddLine("Soulbound", 1, 0.8, 0, 1);
			if (UnBotIgnoreSoulbound() == true) then
				GameTooltip:AddLine("On. Lines containing soulbound are skipped.", 1, 1, 1, 1);
				GameTooltip:AddLine("Refresh the bag to apply.", 1, 1, 1, 1);
			else
				GameTooltip:AddLine("Off. Soulbound items are listed.", 1, 1, 1, 1);
				GameTooltip:AddLine("Click to hide them on the next refresh.", 1, 1, 1, 1);
			end
			GameTooltip:Show();
		end);
		soulBtn:SetScript("OnLeave", function()
			GameTooltip:Hide();
		end);

		local queryBtn = CreateFrame("Button", fromParent:GetName().."QueryButton", fromParent, "UnBotBagsQueryButtonTemplate");
		-- Query button size: 16x16 matching Assets\query_16.blp
		-- Position: TOPRIGHT -38, -8 (left of the close X). Tweak SetWidth/SetHeight/SetPoint here.
		queryBtn:SetWidth(16);
		queryBtn:SetHeight(16);
		queryBtn:Show();
		queryBtn:SetPoint("TOPRIGHT", fromParent, "TOPRIGHT", -38, -8);
		queryBtn:SetFrameLevel(headerLevel);
		queryBtn:SetScript("OnClick", function()
			GameTooltip:Hide();
			UnBotQueryUnknownItems(fromParent);
		end);
		queryBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
			GameTooltip:AddLine("Query Server", 1, 0, 0, 1);
			GameTooltip:AddLine("Scans this bag for unknown items and queries the server for each one.", 1, 1, 1, 1);
			GameTooltip:AddLine("Names and icons update as each item is queried.", 1, 1, 1, 1);
			GameTooltip:Show();
		end);
		queryBtn:SetScript("OnLeave", function()
			GameTooltip:Hide();
		end);
	end
end

function PickPrevOrNextButton(bagsFrame, pn)
	if (bagsFrame == nil or bagsFrame.dataGroup == nil) then
		return;
	end
	local firstIndex = 1;
	local overIndex = math.ceil((#(bagsFrame.dataGroup)) / bagsFrame.pageCount);
	if (overIndex == 0) then
		overIndex = 1;
	end
	if (pn == true) then
		if (bagsFrame.currentPage > firstIndex) then
			bagsFrame.currentPage = bagsFrame.currentPage - 1;
			UpdateUnBotBagsFramePage(bagsFrame);
		end
	else
		if (bagsFrame.currentPage < overIndex) then
			bagsFrame.currentPage = bagsFrame.currentPage + 1;
			UpdateUnBotBagsFramePage(bagsFrame);
		end
	end
end

function CreateIconsByUnBotBagsFrame(checkedIndex, name,bagType,afterRemove,datas,target,race,activeText,flushFunc,command,getFunc)
	if (CanAddToUnBotFrame(name) == false) then
		return nil;
	end
	local bagsFrame = CreateFrame("Frame",name,UIParent,"UnBotBagsFrame");
	local bagsHead = CreateFrame("Frame",bagsFrame:GetName().."Head",bagsFrame,"UnBotBagsFrameHeadFrame");
	bagsHead:Show();
	if (bagType == 1) then
		bagsFrame:SetSize(350, 236);
		bagsHead:SetSize(350, 32);
	else
		bagsFrame:SetSize(250, 220);
		bagsHead:SetSize(250, 32);
	end
	bagsFrame.bagsType = bagType;
	bagsFrame.bgIconsGroup = CreateIconGroupByParent(bagsFrame,5,32,8,5,0,0,30);
	if (bagsFrame.flushFunc ~= nil or datas == nil) then
		bagsFrame.dataGroup = {};
	else
		bagsFrame.dataGroup = datas;
	end
	bagsFrame.afterRemove = afterRemove;
	bagsFrame.target = target;
	bagsFrame.raceName = race;
	bagsFrame.activeText = activeText;
	bagsFrame.flushFunc = flushFunc;
	bagsFrame.getFunc = getFunc;
	CreateOptionByParent(bagsFrame,flushFunc);
	if (bagType == 1) then
		CreateBagsTypeOptions(bagsFrame, checkedIndex);
	end
	UpdateUnBotBagsFramePage(bagsFrame);
	bagsFrame:Show();
	bagsFrame:RegisterEvent("CHAT_MSG_WHISPER");
	bagsFrame:RegisterEvent("TRADE_SHOW");
	bagsFrame:RegisterEvent("TRADE_CLOSED");
	
	AddToUnBotFrame(bagsFrame, name);
	if (bagsFrame.flushFunc ~= nil) then
		bagsFrame.flushFunc(bagsFrame,command);
		UnBotDisableAllFrameFlushButton();
	end
	return bagsFrame;
end

function UnBotCloseAllBagsFrame()
	for i=1, #(UnBotFrame.ShowedBags) do
		UnBotFrame.ShowedBags[ i ]:Hide();
		UnBotFrame.ShowedBags[ i ]:SetParent(nil);
	end
	UnBotFrame.ShowedBags = {};
end

function UpdateUnBotBagsFramePage(bagsFrame)
	if (bagsFrame == nil) then
		return;
	end
	
	local startIndex = (bagsFrame.currentPage - 1) * bagsFrame.pageCount + 1;
	local groupIndex = 1;
	for i=startIndex, startIndex+bagsFrame.pageCount-1 do
		if (i > #(bagsFrame.dataGroup) or bagsFrame.getFunc == nil) then
			bagsFrame.bgIconsGroup[ groupIndex ].Icon:SetTexture(bagsFrame.disableIcon);
			bagsFrame.bgIconsGroup[ groupIndex ].bagsIcon = nil;
			bagsFrame.bgIconsGroup[ groupIndex ].iconIndex = 0;
			bagsFrame.bgIconsGroup[ groupIndex ].countLabel:SetText(" ");
		else
			local icon, name = bagsFrame.getFunc(bagsFrame, i);
			bagsFrame.bgIconsGroup[ groupIndex ].Icon:SetTexture(icon);
			bagsFrame.bgIconsGroup[ groupIndex ].bagsIcon = name;
			bagsFrame.bgIconsGroup[ groupIndex ].iconIndex = bagsFrame.dataGroup[ i ][ 1 ];
			if (bagsFrame.bagsType == 1 and bagsFrame.dataGroup[ i ][ 7 ] ~= nil and bagsFrame.dataGroup[ i ][ 7 ] > 1) then
				bagsFrame.bgIconsGroup[ groupIndex ].countLabel:SetText(tostring(bagsFrame.dataGroup[ i ][ 7 ]));
			else
				bagsFrame.bgIconsGroup[ groupIndex ].countLabel:SetText(" ");
			end
		end
		bagsFrame.bgIconsGroup[ groupIndex ].dataIndex = i;
		groupIndex = groupIndex + 1;
	end
	local overIndex = math.ceil((#(bagsFrame.dataGroup)) / bagsFrame.pageCount);
	if (overIndex == 0) then
		overIndex = 1;
	end
	bagsFrame.page:SetText("Page " .. tostring(bagsFrame.currentPage) .. " - " .. tostring(overIndex));
end
function UnBotBagsItemLink(data)
	if (data == nil) then
		return nil;
	end
	local itemLink = UnBotGetItemQueryLink(data);
	local _, cachedLink = GetItemInfo(itemLink or tostring(data[ 2 ]));
	if (cachedLink ~= nil) then
		return cachedLink;
	end
	if (itemLink ~= nil) then
		return itemLink;
	end
	if (data[ 2 ] ~= nil) then
		return "item:" .. tostring(data[ 2 ]);
	end
	return nil;
end

function UnBotBagsOpenTrade(name)
	local unit = nil;
	if (name ~= nil and UnitName("target") == name) then
		unit = "target";
	end
	if (unit == nil) then
		for i=1, 4 do
			if (UnitName("party"..i) == name) then
				unit = "party"..i;
				break;
			end
		end
	end
	if (unit == nil) then
		for i=1, 40 do
			if (UnitName("raid"..i) == name) then
				unit = "raid"..i;
				break;
			end
		end
	end
	if (unit ~= nil) then
		InitiateTrade(unit);
		return;
	end
	local editBox = ChatFrameEditBox;
	if (editBox == nil and DEFAULT_CHAT_FRAME ~= nil) then
		editBox = DEFAULT_CHAT_FRAME.editBox;
	end
	if (editBox ~= nil and name ~= nil) then
		editBox:SetText("/trade "..name);
		ChatEdit_SendText(editBox, 0);
	end
end

function UnBotBagsHandleTradeClick(bagsFrame, index)
	if (bagsFrame == nil or index == nil or index < 1 or index > #(bagsFrame.dataGroup)) then
		return false;
	end
	local itemLink = UnBotBagsItemLink(bagsFrame.dataGroup[ index ]);
	if (itemLink == nil) then
		DisplayInfomation("No item link to trade.");
		return false;
	end
	if (UnBotBagsTradeIsOpen() == true) then
		SendChatMessage(itemLink, "WHISPER", nil, bagsFrame.target);
		bagsFrame.needTradeRefresh = true;
	else
		UnBotBagsOpenTrade(bagsFrame.target);
		bagsFrame.pendingTradeLink = itemLink;
	end
	return true;
end

function ExecuteCommandByBagsItem(bagsFrame,index)
	if (bagsFrame == nil or index < 1 or index > #(bagsFrame.dataGroup)) then
		return false;
	end
	if (bagsFrame.tradeMode == true or bagsFrame.command == "trade ") then
		return UnBotBagsHandleTradeClick(bagsFrame, index);
	end
	if (bagsFrame.command ~= nil and bagsFrame.command ~= "") then
		if (bagsFrame.command == UnBotExecuteCommand[ 67 ]) then
			local targetName = UnitName("target");
			if (targetName == nil or targetName == "") then
				DisplayInfomation("You do not have a merchant NPC targeted.");
				return false;
			end
		end
		if (bagsFrame.bagsType == 1) then
			local itemLink = UnBotBagsItemLink(bagsFrame.dataGroup[ index ]);
			if (itemLink ~= nil) then
				SendChatMessage(bagsFrame.command .. itemLink, "WHISPER", nil, bagsFrame.target);
			end
		elseif (bagsFrame.bagsType == 2) then
			local itemID = bagsFrame.dataGroup[ index ][ 2 ];
			SendChatMessage(bagsFrame.command..tostring(itemID), "WHISPER", nil, bagsFrame.target);
		end
	end
	return true;
end

function RemoveByIndex(bagsFrame,index)
	if (bagsFrame == nil or index < 1 or index > #(bagsFrame.dataGroup)) then
		return;
	end
	table.remove(bagsFrame.dataGroup,index);
	UpdateUnBotBagsFramePage(bagsFrame);
end

function FlushItemsToBags(bagsFrame,command)
	if (bagsFrame == nil) then
		return;
	end

	bagsFrame.dataGroup = {};
	bagsFrame.queryQueue = nil;
	bagsFrame.queryIndex = nil;
	bagsFrame.lastQueryTick = nil;
	bagsFrame.queryDoneTick = nil;
	if (command ~= nil) then
		bagsFrame.command = command;
	end
	UpdateUnBotBagsFramePage(bagsFrame);
	if (bagsFrame.bagsType == 1) then
		SendChatMessage("c", "WHISPER", nil, bagsFrame.target);
	elseif (bagsFrame.bagsType == 2) then
		SendChatMessage("spells", "WHISPER", nil, bagsFrame.target);
	end
	bagsFrame.lastFlushTick = GetTime();
end

function GetIconFunc(bagsFrame, index)
	local icon = GetIconPathByIndex(bagsFrame.dataGroup[ index ][ 1 ]);
	local name = GetIconPathByIndex(bagsFrame.dataGroup[ index ][ 1 ]);
	return icon, name;
end

function GetItemFunc(bagsFrame, index)
	if (index < 1 or index > #(bagsFrame.dataGroup)) then
		return nil,nil;
	end
	local icon = bagsFrame.dataGroup[ index ][ 4 ];
	local name = bagsFrame.dataGroup[ index ][ 3 ];
	return icon, name;
end

function IsFilterInfo(info)
	local f1,f2 = string.find(info,"Equip");
	if (f1 ~= nil or f2 ~= nil) then return true; end

	f1,f2 = string.find(info,"Destroy");
	if (f1 ~= nil or f2 ~= nil) then return true; end

	f1,f2 = string.find(info,"Sell");
	if (f1 ~= nil or f2 ~= nil) then return true; end

	f1,f2 = string.find(info,"Use");
	if (f1 ~= nil or f2 ~= nil) then return true; end

	return false;
end

function GetItemCountByLink(info)
	local x1,x2 = string.find(info,"]");
	if (x1 == nil or x2 == nil) then
		return 1;
	end
	local numIndex1,numIndex2 = string.find(info,"x",x2);
	if (numIndex1 == nil or numIndex2 == nil) then
		return 1;
	end
	local count = string.match(info,"%d+",numIndex2);
	return tonumber(count);
end

-- Bot bag list is always a WHISPER reply to command "c" from bagsFrame.target.
-- Example: |cff0070dd|Hitem:24490:0:0:0:0:0:0:0:80|h[Key of Time]|h|r (soulbound)
function UnBotParseBagItemWhisper(info)
	if (info == nil) then
		return nil, nil, nil, nil;
	end
	local itemString = string.match(info, "H(item:[^|]+)");
	local itemID = tonumber(string.match(info, "Hitem:(%d+)"));
	local linkName = string.match(info, "%[([^%]]+)%]");
	local fullLink = string.match(info, "|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r");
	if (fullLink == nil and itemString ~= nil) then
		fullLink = itemString;
	end
	return itemID, itemString, linkName, fullLink;
end

function UnBotGetItemQueryLink(data)
	if (data == nil) then
		return nil;
	end
	if (data[8] ~= nil and data[8] ~= "") then
		return data[8];
	end
	if (data[2] ~= nil and data[2] > 0) then
		return "item:"..tostring(data[2])..":0:0:0:0:0:0:0";
	end
	return nil;
end

function UnBotGetQueryTooltip()
	if (UnBotQueryTooltip == nil) then
		UnBotQueryTooltip = CreateFrame("GameTooltip", "UnBotQueryTooltip", UIParent, "GameTooltipTemplate");
		UnBotQueryTooltip:SetOwner(UIParent, "ANCHOR_NONE");
		UnBotQueryTooltip:SetScript("OnTooltipSetItem", function()
			if (UnBotQueryBagsFrame ~= nil) then
				UnBotApplyQueriedItemInfo(UnBotQueryBagsFrame);
			end
		end);
	end
	return UnBotQueryTooltip;
end

function UnBotQueryItemFromServer(data)
	local link = UnBotGetItemQueryLink(data);
	if (link == nil) then
		return;
	end
	local tip = UnBotGetQueryTooltip();
	tip:SetOwner(UIParent, "ANCHOR_NONE");
	pcall(function()
		tip:SetHyperlink(link);
	end);
	-- AtlasLoot uses GameTooltip:SetHyperlink to actually query 3.3.5a. Do not Hide() here.
	pcall(function()
		GameTooltip:SetOwner(UIParent, "ANCHOR_NONE");
		GameTooltip:SetHyperlink(link);
	end);
end

function UnBotItemIsUnknown(data)
	if (data == nil or data[2] == nil or data[2] <= 0) then
		return false;
	end
	if (data[5] == true) then
		return true;
	end
	if (data[3] == nil or data[3] == "" or data[3] == "???") then
		data[5] = true;
		return true;
	end
	local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(UnBotGetItemQueryLink(data) or data[2]);
	if (name == nil or texture == nil) then
		data[5] = true;
		return true;
	end
	return false;
end

function UnBotApplyQueriedItemInfo(bagsFrame)
	if (bagsFrame == nil or bagsFrame.dataGroup == nil) then
		return;
	end
	local updated = false;
	for i=1, #(bagsFrame.dataGroup) do
		local data = bagsFrame.dataGroup[i];
		if (data ~= nil and data[5] == true and data[2] ~= nil and data[2] > 0) then
			local queryLink = UnBotGetItemQueryLink(data);
			local name, _, itemQuality, _, _, _, _, _, _, texture = GetItemInfo(queryLink or data[2]);
			if (name ~= nil and texture ~= nil) then
				data[3] = name;
				data[4] = texture;
				data[5] = false;
				data[6] = itemQuality;
				updated = true;
			end
		end
	end
	if (updated == true) then
		UpdateUnBotBagsFramePage(bagsFrame);
	end
end

function UnBotQueryUnknownItems(bagsFrame)
	if (bagsFrame == nil or bagsFrame.bagsType ~= 1 or bagsFrame.dataGroup == nil) then
		return;
	end
	if (bagsFrame.queryQueue ~= nil) then
		return;
	end
	UnBotApplyQueriedItemInfo(bagsFrame);

	local queue = {};
	local seen = {};
	for i=1, #(bagsFrame.dataGroup) do
		local data = bagsFrame.dataGroup[i];
		if (UnBotItemIsUnknown(data) == true) then
			local itemID = data[2];
			if (seen[itemID] == nil) then
				seen[itemID] = true;
				table.insert(queue, i);
			end
		end
	end
	if (#(queue) == 0) then
		DisplayInfomation("No unknown items found.");
		return;
	end

	UnBotQueryBagsFrame = bagsFrame;
	bagsFrame.queryQueue = queue;
	bagsFrame.queryIndex = 1;
	bagsFrame.lastQueryTick = 0;
	bagsFrame.queryDoneTick = nil;
	DisplayInfomation("Querying "..tostring(#(queue)).." unknown item(s) from "..tostring(bagsFrame.target).." whisper links.");
end

function UnBotProcessItemQuery(bagsFrame, tick)
	if (bagsFrame.queryIndex == nil or bagsFrame.queryQueue == nil) then
		bagsFrame.queryQueue = nil;
		return;
	end

	if (bagsFrame.queryIndex <= #(bagsFrame.queryQueue)) then
		if (bagsFrame.lastQueryTick == 0 or (tick - bagsFrame.lastQueryTick) >= 0.1) then
			bagsFrame.lastQueryTick = tick;
			local dataIndex = bagsFrame.queryQueue[bagsFrame.queryIndex];
			bagsFrame.queryIndex = bagsFrame.queryIndex + 1;
			local data = bagsFrame.dataGroup[dataIndex];
			UnBotQueryItemFromServer(data);
			UnBotApplyQueriedItemInfo(bagsFrame);
		end
	else
		UnBotApplyQueriedItemInfo(bagsFrame);
		if (bagsFrame.queryDoneTick == nil) then
			bagsFrame.queryDoneTick = tick;
		elseif ((tick - bagsFrame.queryDoneTick) > 3) then
			GameTooltip:Hide();
			bagsFrame.queryQueue = nil;
			bagsFrame.queryIndex = nil;
			bagsFrame.lastQueryTick = nil;
			bagsFrame.queryDoneTick = nil;
			UnBotQueryBagsFrame = nil;
		end
	end
end

function UnBotIgnoreSoulbound()
	if (BotBagsConfig ~= nil and BotBagsConfig["IgnoreSoulbound"] == true) then
		return true;
	end
	return false;
end

function UnBotApplySoulboundButton(button)
	if (button == nil) then
		return;
	end
	local tex = "Interface\\AddOns\\BotBags\\Assets\\soulbound_16";
	if (UnBotIgnoreSoulbound() == true) then
		tex = "Interface\\AddOns\\BotBags\\Assets\\soulbound_16_on";
	end
	button:SetNormalTexture(tex);
	button:SetPushedTexture(tex);
end

function UnBotRefreshSoulboundButtons()
	if (UnBotFrame == nil or UnBotFrame.ShowedBags == nil) then
		return;
	end
	for i=1, #(UnBotFrame.ShowedBags) do
		local bagsFrame = UnBotFrame.ShowedBags[i];
		if (bagsFrame ~= nil) then
			UnBotApplySoulboundButton(_G[bagsFrame:GetName().."SoulboundButton"]);
		end
	end
end

function UnBotToggleIgnoreSoulbound()
	if (BotBagsConfig == nil) then
		BotBagsConfig = {};
	end
	if (BotBagsConfig["IgnoreSoulbound"] == true) then
		BotBagsConfig["IgnoreSoulbound"] = false;
		DisplayInfomation("Soulbound items shown. Refresh the bag to list them.");
	else
		BotBagsConfig["IgnoreSoulbound"] = true;
		DisplayInfomation("Soulbound items hidden. Refresh the bag to apply.");
	end
	UnBotRefreshSoulboundButtons();
end

function RecvOnceItemToBags(bagsFrame,info)
	if (bagsFrame == nil) then
		return;
	end
	
	if (IsFilterInfo(info) == true) then
		return;
	end

	if (UnBotIgnoreSoulbound() == true and string.find(string.lower(info), "soulbound") ~= nil) then
		return;
	end

	local itemID, itemString, linkName, fullLink = UnBotParseBagItemWhisper(info);
	if (itemID == nil) then
		local i1,i2 = string.find(info,"Hitem:");
		if (i1 == nil or i2 == nil) then
			return;
		end
		itemID = tonumber(string.match(info,"%d+",i2));
	end
	if (itemID == nil) then
		return;
	end
	local itemCount = GetItemCountByLink(info);
	if (itemCount == nil) then
		itemCount = 1;
	end
	
	local texture;
	local name;
	local itemQuality;
	if (itemString ~= nil) then
		name,_,_,_,_,_,_,_,_,texture = GetItemInfo(itemString);
	end
	if (name == nil or texture == nil) then
		name,_,_,_,_,_,_,_,_,texture = GetItemInfo(itemID);
	end
	local needQuery = false;
	if (name == nil or texture == nil) then
		if YssBossLoot and YssBossLoot.QueryItemInfo then
			YssBossLoot:QueryItemInfo(itemID);
		end
		if (linkName ~= nil and linkName ~= "") then
			name = linkName;
		else
			name = "???";
		end
		texture = bagsFrame.normalIcon;
		needQuery = true;
	end
	local item = { [ 1 ] = 0, [ 2 ] = itemID, [ 3 ] = name, [ 4 ] = texture, [ 5 ] = needQuery, [ 6 ] = itemQuality, [ 7 ] = itemCount, [ 8 ] = fullLink or itemString };
	table.insert(bagsFrame.dataGroup, item);
	item[ 1 ] = #(bagsFrame.dataGroup);
	
	UpdateUnBotBagsFramePage(bagsFrame);
end

function RecvMuchSpellToBags(bagsFrame,info)
	if (bagsFrame == nil) then
		return;
	end
	local i1,i2 = string.find(info,"Hspell:");
	if (i1 == nil or i2 == nil) then
		return;
	end

	local textList = UnBotSplit(string.sub(info, i2), "Hspell:");
	local ids = {};
	for i=1, #textList do
		local idText = tonumber(string.match(textList[ i ],"%d+"));
		if (idText ~= nil) then
			table.insert(ids, tonumber(idText));
		end
	end
	for i=1, #ids do
		local spellID = ids[ i ];
		local name,rankLV,texture,costMana,un3,costType,castTime,un6,distance = GetSpellInfo(spellID);
		if (name ~= nil) then
			if (texture == nil) then
				texture = bagsFrame.normalIcon;
			end
			local spell = { [ 1 ] = 0, [ 2 ] = spellID, [ 3 ] = name, [ 4 ] = texture, [ 5 ] = false, [ 6 ] = rankLV, [ 7 ] = tonumber(costType), [ 8 ] = tonumber(costMana), [ 9 ] = tonumber(castTime), [ 10 ] = tonumber(distance) };
			table.insert(bagsFrame.dataGroup, spell);
			spell[ 1 ] = #(bagsFrame.dataGroup);
		else
			DisplayInfomation("Recv spell id "..tostring(spellID).." error.");
		end
	end
	
	UpdateUnBotBagsFramePage(bagsFrame);
end
