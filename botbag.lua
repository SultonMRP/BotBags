BotBagsConfig = BotBagsConfig or {};

UnBotFrame = UnBotFrame or {};
UnBotFrame.ShowedBags = UnBotFrame.ShowedBags or {};

UnBotExecuteCommand = UnBotExecuteCommand or {
	[65] = "destroy ",
	[66] = "e ",
	[67] = "s ",
	[68] = "u ",
};

function UnBotSplit(str, split_char)
	local sub_str_tab = {};
	while (true) do
		local pos = string.find(str, split_char);
		if (not pos) then
			sub_str_tab[#sub_str_tab + 1] = str;
			break;
		end
		local sub_str = string.sub(str, 1, pos - 1);
		sub_str_tab[#sub_str_tab + 1] = sub_str;
		str = string.sub(str, pos + 1, #str);
	end
	return sub_str_tab;
end

function DisplayInfomation(info)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00cccc"..info.."|r");
end

function GetIconPathByIndex(index)
	return "Interface\\Icons\\Temp";
end

function CanAddToUnBotFrame(targetName)
	for i=1, #(UnBotFrame.ShowedBags) do
		if (UnBotFrame.ShowedBags[i]:GetName() == targetName) then
			return false;
		end
	end
	return true;
end

function AddToUnBotFrame(bagsFrame, targetName)
	for i=1, #(UnBotFrame.ShowedBags) do
		if (UnBotFrame.ShowedBags[i]:GetName() == targetName) then
			return false;
		end
	end
	table.insert(UnBotFrame.ShowedBags, bagsFrame);
	return true;
end

function RemoveFromUnBotFrame(bagsFrame)
	for i=1, #(UnBotFrame.ShowedBags) do
		if (UnBotFrame.ShowedBags[i]:GetName() == bagsFrame:GetName()) then
			table.remove(UnBotFrame.ShowedBags,i);
			return;
		end
	end
end

function UnBotEnableAllFrameFlushButton()
	for i=1, #(UnBotFrame.ShowedBags) do
		local flushButton = _G["BagsFrameFlush"..(UnBotFrame.ShowedBags[i]:GetName())]
		if (flushButton ~= nil) then
			flushButton:Enable();
		end
	end
end

function UnBotDisableAllFrameFlushButton()
	for i=1, #(UnBotFrame.ShowedBags) do
		local flushButton = _G["BagsFrameFlush"..(UnBotFrame.ShowedBags[i]:GetName())]
		if (flushButton ~= nil) then
			flushButton:Disable();
		end
	end
end

local function BotBagsFindFrame(name)
	for i=1, #(UnBotFrame.ShowedBags) do
		if (UnBotFrame.ShowedBags[i]:GetName() == name) then
			return UnBotFrame.ShowedBags[i];
		end
	end
	return nil;
end

function BotBagsOpen(unit, name)
	if (unit == nil or unit == "") then
		unit = "target";
	end
	local targetName = name;
	if (targetName == nil or targetName == "") then
		targetName = UnitName(unit);
	end
	if (unit ~= nil and UnitExists(unit) and UnitIsUnit(unit, "player")) then
		return;
	end
	if (targetName ~= nil and targetName == UnitName("player")) then
		return;
	end
	local targetClass = nil;
	local isParty = nil;
	local isRaid = nil;
	if (unit ~= nil and UnitExists(unit)) then
		targetClass = UnitClass(unit);
		isParty = UnitInParty(unit);
		isRaid = UnitInRaid(unit);
		if (not UnitIsPlayer(unit)) then
			DisplayInfomation("You need to select a player bot.");
			return;
		end
	else
		targetClass = UnitClass("target");
		isParty = UnitInParty("target");
		isRaid = UnitInRaid("target");
		if (targetName ~= nil) then
			if (UnitInParty(targetName)) then
				isParty = 1;
			end
			if (UnitInRaid(targetName)) then
				isRaid = 1;
			end
		end
	end
	if (targetName == nil or targetName == "") then
		DisplayInfomation("You do not have a target selected.");
		return;
	end
	if (isParty == nil and isRaid == nil) then
		DisplayInfomation("The selected target is not in your group.");
		return;
	end
	if (targetClass == nil) then
		targetClass = "";
	end

	local frameName = "UnBotItemList"..targetName;
	local existing = BotBagsFindFrame(frameName);
	if (existing ~= nil) then
		existing:Show();
		return;
	end

	CreateIconsByUnBotBagsFrame(1, frameName, 1, false, {}, targetName, targetClass, " View Items", FlushItemsToBags, nil, GetItemFunc);
end

local function BotBagsInsertPopupMenu(menuName)
	local menu = UnitPopupMenus[menuName];
	if (menu == nil) then
		return;
	end
	local i;
	for i=1, #menu do
		if (menu[i] == "BOTBAG") then
			return;
		end
	end
	for i=1, #menu do
		if (menu[i] == "CANCEL") then
			table.insert(menu, i, "BOTBAG");
			return;
		end
	end
	table.insert(menu, "BOTBAG");
end

UnitPopupButtons["BOTBAG"] = { text = "Bot Bag", dist = 0 };
BotBagsInsertPopupMenu("PARTY");
BotBagsInsertPopupMenu("RAID_PLAYER");
BotBagsInsertPopupMenu("PLAYER");

hooksecurefunc("UnitPopup_HideButtons", function()
	local dropdownMenu = UIDROPDOWNMENU_INIT_MENU;
	if (dropdownMenu == nil or dropdownMenu.which == nil or UnitPopupMenus[dropdownMenu.which] == nil) then
		return;
	end
	local hide = false;
	if (dropdownMenu.unit ~= nil and UnitExists(dropdownMenu.unit) and UnitIsUnit(dropdownMenu.unit, "player")) then
		hide = true;
	elseif (dropdownMenu.name ~= nil and dropdownMenu.name == UnitName("player")) then
		hide = true;
	end
	if (hide == false) then
		return;
	end
	local index, value;
	for index, value in ipairs(UnitPopupMenus[dropdownMenu.which]) do
		if (value == "BOTBAG") then
			UnitPopupShown[index] = 0;
		end
	end
end);

hooksecurefunc("UnitPopup_OnClick", function()
	local dropdownFrame = UIDROPDOWNMENU_INIT_MENU;
	local button = this.value;
	if (button ~= "BOTBAG" or dropdownFrame == nil) then
		return;
	end
	BotBagsOpen(dropdownFrame.unit, dropdownFrame.name);
end);

SLASH_BOTBAG1 = "/botbag";
SlashCmdList["BOTBAG"] = function(msg)
	BotBagsOpen();
end
