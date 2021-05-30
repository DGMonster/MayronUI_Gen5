-- luacheck: ignore MayronUI self 143
---@type MayronUI
local MayronUI = _G.MayronUI;
local tk, _, em, gui, obj, L = MayronUI:GetCoreComponents();
local MEDIA = tk:GetAssetFilePath("Textures\\Chat\\");

---@class ChatFrame
local C_ChatFrame = obj:Import("MayronUI.ChatModule.ChatFrame");

local ChatMenu, CreateFrame, UIMenu_Initialize, UIMenu_AutoSize, string, table, pairs =
	_G.ChatMenu, _G.CreateFrame, _G.UIMenu_Initialize, _G.UIMenu_AutoSize, _G.string, _G.table, _G.pairs;

local UIMenu_AddButton, FriendsFrame_SetOnlineStatus = _G.UIMenu_AddButton, _G.FriendsFrame_SetOnlineStatus;

local FRIENDS_TEXTURE_ONLINE, FRIENDS_TEXTURE_AFK, FRIENDS_TEXTURE_DND =
	_G.FRIENDS_TEXTURE_ONLINE, _G.FRIENDS_TEXTURE_AFK, _G.FRIENDS_TEXTURE_DND;

local FRIENDS_LIST_AVAILABLE, FRIENDS_LIST_AWAY, FRIENDS_LIST_BUSY =
  _G.FRIENDS_LIST_AVAILABLE, _G.FRIENDS_LIST_AWAY, _G.FRIENDS_LIST_BUSY;

local IsAddOnLoaded, InCombatLockdown, UIParent = _G.IsAddOnLoaded, _G.InCombatLockdown, _G.UIParent;

-- C_ChatFrame -----------------------

obj:DefineParams("string", "ChatModule", "table");
---@param anchorName string position of chat frame (i.e. "TOPLEFT")
---@param chatModule ChatModule
---@param chatModuleSettings table
function C_ChatFrame:__Construct(data, anchorName, chatModule, chatModuleSettings)
	data.anchorName = anchorName;
	data.chatModule = chatModule;
	data.chatModuleSettings = chatModuleSettings;
	data.settings = chatModuleSettings.chatFrames[anchorName];
end

obj:DefineParams("boolean");
---@param enabled boolean enable/disable the chat frame
function C_ChatFrame:SetEnabled(data, enabled)
	if (not data.frame and enabled) then
		data.frame = self:CreateFrame();
		self:SetUpTabBar(data.settings.tabBar);

		if (data.anchorName ~= "TOPLEFT") then
			self:Reposition();
		end

    if (IsAddOnLoaded("Blizzard_CompactRaidFrames")) then
      data.chatModule:SetUpRaidFrameManager();
    else
      -- if it is not loaded, create a callback to trigger when it is loaded
      local listener = em:CreateEventListener(function(_, name)
        if (name == "Blizzard_CompactRaidFrames") then
          data.chatModule:SetUpRaidFrameManager();
        end
      end)

      listener:SetExecuteOnce(true);
      listener:RegisterEvent("ADDON_LOADED");
    end

		-- chat channel button
		data.chatModule:SetUpLayoutButton(data.frame.layoutButton);
	end

	if (data.frame) then
		data.frame:SetShown(enabled);

		if (enabled) then
			self:SetUpButtonHandler(data.settings.buttons);
    end

    self.Static:SetUpSideBarIcons(data.chatModule, data.chatModuleSettings);
    _G.ChatFrameChannelButton:DisableDrawLayer("ARTWORK");

    if (tk:IsRetail()) then
      _G.ChatFrameToggleVoiceDeafenButton:DisableDrawLayer("ARTWORK");
      _G.ChatFrameToggleVoiceMuteButton:DisableDrawLayer("ARTWORK");

      local dummyFunc = function() return true; end

      _G.ChatFrameToggleVoiceDeafenButton:SetVisibilityQueryFunction(dummyFunc);
      _G.ChatFrameToggleVoiceDeafenButton:UpdateVisibleState();

      _G.ChatFrameToggleVoiceMuteButton:SetVisibilityQueryFunction(dummyFunc);
      _G.ChatFrameToggleVoiceMuteButton:UpdateVisibleState();
    end
	end
end

function C_ChatFrame.Static:SetUpSideBarIcons(chatModule, settings)
  local muiChatFrame = _G["MUI_ChatFrame_" .. settings.icons.anchor];
  local selectedChatFrame;

  if (muiChatFrame and muiChatFrame:IsShown()) then
    selectedChatFrame = muiChatFrame;
  else
    for anchorName, _ in pairs(chatModule:GetChatFrames()) do
      muiChatFrame = _G["MUI_ChatFrame_" .. anchorName];

      if (muiChatFrame and muiChatFrame:IsShown()) then
        selectedChatFrame = muiChatFrame;
        break;
      end
    end
  end

  if (selectedChatFrame) then
    self:PositionSideBarIcons(settings, selectedChatFrame);
  end
end

function C_ChatFrame:CreateButtons(data)
	local butonMediaFile;
	data.buttons = obj:PopTable();

	for buttonID = 1, 3 do
		local btn = tk:PopFrame("Button", data.buttonsBar);
		data.buttons[buttonID] = btn;

		btn:SetSize(135, 20);
		btn:SetNormalFontObject("MUI_FontSmall");
		btn:SetHighlightFontObject("GameFontHighlightSmall");
		btn:SetText(tk.Strings.Empty);

		-- position button
		if (buttonID == 1) then
			btn:SetPoint("TOPLEFT");
		else
			local previousButton = data.buttons[#data.buttons - 1];
			btn:SetPoint("LEFT", previousButton, "RIGHT");
		end

		-- get button texture (first and last buttons share the same "side" texture)
		if (buttonID == 1 or buttonID == 3) then
			-- use "side" button texture
			butonMediaFile = string.format("%ssideButton", MEDIA);
		else
			-- use "middle" button texture
			butonMediaFile = string.format("%smiddleButton", MEDIA);
		end

		btn:SetNormalTexture(butonMediaFile);
		btn:SetHighlightTexture(butonMediaFile);

		if (buttonID == 3) then
			-- flip last button texture horizontally
			btn:GetNormalTexture():SetTexCoord(1, 0, 0, 1);
			btn:GetHighlightTexture():SetTexCoord(1, 0, 0, 1);
		end

		if (tk.Strings:Contains(data.anchorName, "BOTTOM")) then
			-- flip vertically

			if (buttonID == 3) then
				-- flip last button texture horizontally
				btn:GetNormalTexture():SetTexCoord(1, 0, 1, 0);
				btn:GetHighlightTexture():SetTexCoord(1, 0, 1, 0);
			else
				btn:GetNormalTexture():SetTexCoord(0, 1, 1, 0);
				btn:GetHighlightTexture():SetTexCoord(0, 1, 1, 0);
			end
		end
	end
end

obj:DefineReturns("Frame");
---@return Frame returns an MUI chat frame
function C_ChatFrame:CreateFrame(data)
	local muiChatFrame = CreateFrame("Frame", "MUI_ChatFrame_" .. data.anchorName, UIParent);

  muiChatFrame:SetFrameStrata("LOW");
  muiChatFrame:SetFrameLevel(1);
	muiChatFrame:SetSize(358, 310);
	muiChatFrame:SetPoint(data.anchorName, data.settings.xOffset, data.settings.yOffset);

	muiChatFrame.sidebar = muiChatFrame:CreateTexture(nil, "ARTWORK");
	muiChatFrame.sidebar:SetTexture(string.format("%ssidebar", MEDIA));
	muiChatFrame.sidebar:SetSize(24, 300);
	muiChatFrame.sidebar:SetPoint(data.anchorName, 0, -10);

	muiChatFrame.window = tk:PopFrame("Frame", muiChatFrame);
	muiChatFrame.window:SetSize(367, 248);
	muiChatFrame.window:SetPoint("TOPLEFT", muiChatFrame.sidebar, "TOPRIGHT", 2, data.settings.window.yOffset);

	muiChatFrame.window.texture = muiChatFrame.window:CreateTexture(nil, "ARTWORK");
	muiChatFrame.window.texture:SetTexture(string.format("%swindow", MEDIA));
	muiChatFrame.window.texture:SetAllPoints(true);

	muiChatFrame.layoutButton = tk:PopFrame("Button", muiChatFrame);
	muiChatFrame.layoutButton:SetNormalFontObject("MUI_FontSmall");
	muiChatFrame.layoutButton:SetHighlightFontObject("GameFontHighlightSmall");
	muiChatFrame.layoutButton:SetText(" ");
	muiChatFrame.layoutButton:GetFontString():SetPoint("CENTER", 1, 0);
	muiChatFrame.layoutButton:SetSize(21, 120);
	muiChatFrame.layoutButton:SetPoint("LEFT", muiChatFrame.sidebar, "LEFT");
	muiChatFrame.layoutButton:SetNormalTexture(string.format("%slayoutButton", MEDIA));
	muiChatFrame.layoutButton:SetHighlightTexture(string.format("%slayoutButton", MEDIA));

	data.buttonsBar = tk:PopFrame("Frame", muiChatFrame);
	data.buttonsBar:SetSize(135 * 3, 20);
	data.buttonsBar:SetPoint("TOPLEFT", 20, 0);

	tk:ApplyThemeColor(
		muiChatFrame.layoutButton:GetNormalTexture(),
		muiChatFrame.layoutButton:GetHighlightTexture()
	);

	self:CreateButtons();

	return muiChatFrame;
end

function C_ChatFrame:SetUpTabBar(data, settings)
	if (settings.show) then
		if (not data.tabs) then
			data.tabs = data.frame:CreateTexture(nil, "ARTWORK");
			data.tabs:SetSize(358, 23);
			data.tabs:SetTexture(string.format("%stabs", MEDIA));
		end

		data.tabs:ClearAllPoints();

		if (tk.Strings:Contains(data.anchorName, "RIGHT")) then
			data.tabs:SetPoint(data.anchorName, data.frame.sidebar, "TOPLEFT", 0, settings.yOffset);
			data.tabs:SetTexCoord(1, 0, 0, 1);
		else
			data.tabs:SetPoint(data.anchorName, data.frame.sidebar, "TOPRIGHT", 0, settings.yOffset);
		end
	end

	if (data.tabs) then
		data.tabs:SetShown(settings.show);
	end
end

function C_ChatFrame:Reposition(data)
	data.frame:ClearAllPoints();
	data.frame.window:ClearAllPoints();
	data.frame.sidebar:ClearAllPoints();
  data.buttonsBar:ClearAllPoints();

  data.frame:SetPoint(data.anchorName, UIParent, data.anchorName,
    data.settings.xOffset, data.settings.yOffset);

	if (data.anchorName == "TOPRIGHT") then
		data.frame.sidebar:SetPoint(data.anchorName, data.frame, data.anchorName, 0 , -10);
		data.frame.window:SetPoint("TOPRIGHT", data.frame.sidebar, "TOPLEFT", -2, data.settings.window.yOffset);
		data.frame.window.texture:SetTexCoord(1, 0, 0, 1);

	elseif (tk.Strings:Contains(data.anchorName, "BOTTOM")) then
		data.frame.sidebar:SetPoint(data.anchorName, data.frame, data.anchorName, 0 , 10);

		if (data.anchorName == "BOTTOMLEFT") then
			data.frame.window:SetPoint(
        "BOTTOMLEFT", data.frame.sidebar, "BOTTOMRIGHT",
        2, data.settings.window.yOffset);
			data.frame.window.texture:SetTexCoord(0, 1, 1, 0);

		elseif (data.anchorName == "BOTTOMRIGHT") then
      data.frame.window:SetPoint(
        "BOTTOMRIGHT", data.frame.sidebar, "BOTTOMLEFT",
        -2, data.settings.window.yOffset);
			data.frame.window.texture:SetTexCoord(1, 0, 1, 0);
		end
	end

	if (tk.Strings:Contains(data.anchorName, "RIGHT")) then
		data.frame.layoutButton:SetPoint("LEFT", data.frame.sidebar, "LEFT", 2, 0);
		data.frame.layoutButton:GetNormalTexture():SetTexCoord(1, 0, 0, 1);
		data.frame.layoutButton:GetHighlightTexture():SetTexCoord(1, 0, 0, 1);
		data.frame.sidebar:SetTexCoord(1, 0, 0, 1);
		data.buttonsBar:SetPoint(data.anchorName, -20, 0);
	else
		data.buttonsBar:SetPoint(data.anchorName, 20, 0);
	end

	self:SetUpTabBar(data.settings.tabBar);
end

do
	local CreatePlayerStatusButton,
    CreateToggleEmoteButton,
    CreateCopyChatButton,
    CreateProfessionsButton,
    CreateShortcutsButton,
    SetUpChatFrameChannelButton;

	local function PositionChatIconMenu(icon, menu, protected)
    local chatAnchor = icon:GetParent():GetName():match(".*_(.*)$");
    menu:ClearAllPoints();

    if (protected) then
      local x, y = icon:GetCenter();

      if (chatAnchor:find("TOP")) then
        y = y + 10;
      elseif (chatAnchor:find("BOTTOM")) then
        y = y - 10;
      end

      if (chatAnchor:find("LEFT")) then
        x = x + 15;
      elseif (chatAnchor:find("RIGHT")) then
        x = x - 15;
      end

      menu:SetPoint(chatAnchor, UIParent, "BOTTOMLEFT", x, y);
    else
      local orig, new = "RIGHT", "LEFT";

      if (chatAnchor:find("LEFT")) then
        orig, new = "LEFT", "RIGHT";
      end

      local relPoint = chatAnchor:gsub(orig, new);
      menu:SetPoint(chatAnchor, icon, relPoint);
    end

		icon:GetScript("OnLeave")(icon);
	end

	local function PositionIcon(enabled, currentIcon, anchorIcon, frame, createFunc, bottom)
		if (enabled) then
			if (not currentIcon) then
				currentIcon = createFunc(frame);
      elseif (currentIcon.Menu) then
        currentIcon.Menu:SetParent(frame);
      end

			currentIcon:ClearAllPoints();
			currentIcon:SetParent(frame);
      currentIcon:SetSize(24, 24); -- fixes inconsistencies with blizz buttons (e.g., voice chat icons)

			if (anchorIcon) then
        local point, relPoint, yOffset = "TOPLEFT", "BOTTOMLEFT", -2;

        if (bottom) then
          point, relPoint, yOffset = "BOTTOMLEFT", "TOPLEFT", 2;
        end

				currentIcon:SetPoint(point, anchorIcon, relPoint, 0, yOffset);
			else
        local point, relPoint, yOffset = "TOPLEFT", "TOPLEFT", -14;

        if (bottom) then
          point, relPoint, yOffset = "BOTTOMLEFT", "BOTTOMLEFT", 14;
        end

				currentIcon:SetPoint(point, frame.sidebar, relPoint, 1, yOffset);
			end

			currentIcon:Show();
			return currentIcon;

		elseif (currentIcon) then
			currentIcon:Hide();
		end

		return anchorIcon;
	end

  function C_ChatFrame.Static:PositionSideBarIcons(chatModuleSettings, muiChatFrame)
		local anchorIcon;

    -- TOP ICONS!
    anchorIcon = PositionIcon(chatModuleSettings.icons.voiceChat,
      nil, nil, muiChatFrame, SetUpChatFrameChannelButton);

    if (not tk:IsRetail() or not anchorIcon) then
      -- Profession icons!
      anchorIcon = PositionIcon(true, -- TODO: Make configurable
        _G.MUI_ToggleProfessionsButton, anchorIcon, muiChatFrame, CreateProfessionsButton);

        PositionIcon(true, -- TODO: Make configurable
        _G.MUI_ShortcutsButton, anchorIcon, muiChatFrame, CreateShortcutsButton);
    end

    -- BOTTOM ICONS!
    anchorIcon = PositionIcon(chatModuleSettings.icons.playerStatus,
      _G.MUI_PlayerStatusButton, nil, muiChatFrame, CreatePlayerStatusButton, true);

    anchorIcon = PositionIcon(chatModuleSettings.icons.emotes,
      _G.MUI_ToggleEmotesButton, anchorIcon, muiChatFrame, CreateToggleEmoteButton, true);

    PositionIcon(chatModuleSettings.icons.copyChat,
      _G.MUI_CopyChatButton, anchorIcon, muiChatFrame, CreateCopyChatButton, true);
	end

  function SetUpChatFrameChannelButton()
    local btn = _G.ChatFrameChannelButton;

    if (tk:IsRetail()) then
      _G.ChatFrameToggleVoiceDeafenButton:SetParent(btn);
      _G.ChatFrameToggleVoiceMuteButton:SetParent(btn);
    else
      tk:KillElement(_G.ChatFrameMenuButton);
    end

    return btn;
  end

  function CreateToggleEmoteButton(muiChatFrame)
    local toggleEmotesButton = CreateFrame("Button", "MUI_ToggleEmotesButton", muiChatFrame);
    toggleEmotesButton:SetNormalTexture(string.format("%sspeechIcon", MEDIA));
    toggleEmotesButton:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
    toggleEmotesButton:SetHighlightAtlas("chatframe-button-highlight");

    tk:SetBasicTooltip(toggleEmotesButton, L["Show Chat Menu"], "ANCHOR_CURSOR_RIGHT", 16, 8);

    toggleEmotesButton:SetScript("OnClick", function(self)
      PositionChatIconMenu(self, ChatMenu);
      _G.ChatFrame_ToggleMenu();
    end);

    return toggleEmotesButton;
  end

	do
		-- accountNameCode cannot be used as |K breaks the editBox
		local function RefreshChatText(editBox)
			local chatFrame = _G[string.format("ChatFrame%d", editBox.chatFrameID)];
			local messages = obj:PopTable();
			local totalMessages = chatFrame:GetNumMessages();
      local message, r, g, b;

			for i = 1, totalMessages do
        message, r, g, b = chatFrame:GetMessageInfo(i);

        if (obj:IsString(message) and #message > 0) then
          -- |Km26|k (BSAp) or |Kq%d+|k
          message = message:gsub("|K.*|k", tk.ReplaceAccountNameCodeWithBattleTag);
          message = tk.Strings:SetTextColorByRGB(message, r, g, b);

					table.insert(messages, message);
				end
      end

			local fullText = table.concat(messages, " \n", 1, #messages);
			obj:PushTable(messages);

			editBox:SetText(fullText);
		end

    local function CreateCopyChatFrame()
      local frame = CreateFrame("Frame", nil, _G.UIParent);
      frame:SetSize(600, 300);
      frame:SetPoint("CENTER");
      frame:Hide();

      gui:CreateDialogBox(tk.Constants.AddOnStyle, nil, nil, frame);
      gui:AddCloseButton(tk.Constants.AddOnStyle, frame);
      gui:AddTitleBar(tk.Constants.AddOnStyle, frame, L["Copy Chat Text"]);

      local editBox = CreateFrame("EditBox", "MUI_CopyChatEditBox", frame);
      editBox:SetMultiLine(true);
      editBox:SetMaxLetters(99999);
      editBox:EnableMouse(true);
      editBox:SetAutoFocus(false);
      editBox:SetFontObject("GameFontHighlight");
      editBox:SetHeight(200);
      editBox.chatFrameID = 1;

      editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus();
      end);

      local refreshButton = CreateFrame("Button", nil, frame);
      refreshButton:SetSize(18, 18);
      refreshButton:SetPoint("TOPRIGHT", frame.closeBtn, "TOPLEFT", -10, -3);
      refreshButton:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton");
      refreshButton:SetHighlightAtlas("chatframe-button-highlight");
      tk:SetBasicTooltip(refreshButton, "Refresh Chat Text");

      refreshButton:SetScript("OnClick", function()
        RefreshChatText(editBox);
      end);

      local dropdown = gui:CreateDropDown(tk.Constants.AddOnStyle, frame);
      local dropdownContainer = dropdown:GetFrame();
      dropdownContainer:SetSize(150, 20);
      dropdownContainer:SetPoint("TOPRIGHT", refreshButton, "TOPLEFT", -10, 0);

      local function DropDown_OnOptionSelected(_, chatFrameID)
        editBox.chatFrameID = chatFrameID;
        RefreshChatText(editBox);
      end

      for chatFrameID = 1, _G.NUM_CHAT_WINDOWS do
        local tab = _G[string.format("ChatFrame%dTab", chatFrameID)];
        local tabText = tab.Text:GetText();

        if (obj:IsString(tabText) and #tabText > 0 and tab:IsShown()) then
          dropdown:AddOption(tabText, DropDown_OnOptionSelected, chatFrameID);
        end
      end

      local container = gui:CreateScrollFrame(tk.Constants.AddOnStyle, frame, "MUI_CopyChatFrame", editBox);
      container:SetPoint("TOPLEFT", 10, -30);
      container:SetPoint("BOTTOMRIGHT", -10, 10);

      container.ScrollFrame:ClearAllPoints();
      container.ScrollFrame:SetPoint("TOPLEFT", 5, -5);
      container.ScrollFrame:SetPoint("BOTTOMRIGHT", -5, 5);

      container.ScrollFrame:HookScript("OnScrollRangeChanged", function(self)
        local maxScroll = self:GetVerticalScrollRange();
        self:SetVerticalScroll(maxScroll);
      end);

      tk:SetBackground(container, 0, 0, 0, 0.4);

      frame.editBox = editBox;
      frame.dropdown = dropdown;
      return frame;
    end

		function CreateCopyChatButton(muiChatFrame)
			local copyChatButton = CreateFrame("Button", "MUI_CopyChatButton", muiChatFrame);
			copyChatButton:SetNormalTexture(string.format("%scopyIcon", MEDIA));
			copyChatButton:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
			copyChatButton:SetHighlightAtlas("chatframe-button-highlight");

			tk:SetBasicTooltip(copyChatButton, L["Copy Chat Text"], "ANCHOR_CURSOR_RIGHT", 16, 8);

			copyChatButton:SetScript("OnClick", function(self)
				if (not self.chatTextFrame) then
					self.chatTextFrame = CreateCopyChatFrame();
				end

				-- get chat frame text:
				RefreshChatText(self.chatTextFrame.editBox);
				self.chatTextFrame:SetShown(not self.chatTextFrame:IsShown());

				local tab = _G[string.format("ChatFrame%dTab", self.chatTextFrame.editBox.chatFrameID)];
				local tabText = tab.Text:GetText();
				self.chatTextFrame.dropdown:SetLabel(tabText);

				self:GetScript("OnLeave")(self);
			end);

			return copyChatButton;
		end
	end

  ---@type LibAddonCompat
  local LibAddonCompat = _G.LibStub("LibAddonCompat-1.0");
  -- local LAB = _G.LibStub("LibActionButton-1.0");

  function CreateProfessionsButton(muiChatFrame)
    local professionsIcon = CreateFrame("Button", "MUI_ToggleProfessionsButton", muiChatFrame);
    professionsIcon:SetNormalTexture(string.format("%sbook", MEDIA));
		professionsIcon:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
		professionsIcon:SetHighlightAtlas("chatframe-button-highlight");

    tk:SetBasicTooltip(professionsIcon, "Show Professions", "ANCHOR_CURSOR_RIGHT", 16, 8);

    local menuWidth = 240;
    local buttonHeight = 24;
    local profMenu = CreateFrame("Frame", "MUI_ProfessionsMenu", UIParent, "TooltipBackdropTemplate");
    profMenu:SetSize(menuWidth, buttonHeight);
    profMenu:SetScript("OnShow", _G.UIMenu_OnShow);
    profMenu:SetScript("OnUpdate", _G.UIMenu_OnUpdate);

    --self, text, shortcut, func, nested, value
    local prof1, prof2, _, fishing, cooking, firstAid  = LibAddonCompat:GetProfessions();
    local professions = obj:PopTable(prof1, prof2, fishing, cooking, firstAid);
    tk.Tables:CleanIndexes(professions);

    local function HideMenu() profMenu:Hide(); end

    local prev;
    for i, profID in pairs(professions) do
      local name = "MUI_ProfessionsMenuButton"..i;
      local btn = CreateFrame("CheckButton", name, profMenu, "SpellButtonTemplate");
      local btnIcon = _G[name.."IconTexture"];

      local iconFrame = CreateFrame("Frame", nil, btn, _G.BackdropTemplateMixin and "BackdropTemplate");
      iconFrame:SetSize(buttonHeight, buttonHeight);
      iconFrame:ClearAllPoints();
      iconFrame:SetPoint("LEFT", 6, 0);
      iconFrame:SetBackdrop(tk.Constants.BACKDROP);
      iconFrame:SetBackdropBorderColor(0, 0, 0, 1);

      btnIcon:SetSize(buttonHeight - 2, buttonHeight - 2);
      btnIcon:ClearAllPoints();
      btnIcon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1);
      btnIcon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1);
      btnIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9);

      btn:SetSize(menuWidth - 8, buttonHeight + 8);
      btn:SetScript("OnEnter", _G.UIMenuButton_OnEnter);
      btn:SetScript("OnLeave", _G.UIMenuButton_OnLeave);
      btn:SetCheckedTexture(nil);
      btn:DisableDrawLayer("BACKGROUND");
      btn:DisableDrawLayer("ARTWORK");

      btn.SpellName:SetWidth(300);
      btn.SpellName:ClearAllPoints();
      btn.SpellName:SetPoint("TOPLEFT", btnIcon, "TOPRIGHT", 8, 0);
      btn.SpellSubName:SetFontObject("GameFontHighlightSmall");

      btn:HookScript("OnClick", HideMenu);

      btn:HookScript("OnEvent", function(_, event)
        local profName, _, skillRank, skillMaxRank, _, spellbookID = LibAddonCompat:GetProfessionInfo(profID);
        local text = tk.Strings:Concat(profName, " (", skillRank, "/", skillMaxRank, ")");

        btn:SetID(spellbookID + 1);
        btn.SpellName:SetText(text);

        local r, g, b = tk:GetThemeColor();
        btn:SetHighlightTexture(1, "ADD");
        btn:GetHighlightTexture():SetColorTexture(r * 0.7, g * 0.7, b * 0.7, 0.4);
      end);

      btn:ClearAllPoints();
      if (not prev) then
        btn:SetPoint("TOPLEFT", 4, -4);
      else
        btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT");
      end

      prev = btn;
    end

    profMenu:SetHeight(32 + (#professions * buttonHeight));
    local missingAnchor = true;

    professionsIcon:SetScript("OnClick", function(self)
      if (InCombatLockdown()) then
        MayronUI:Print(L["Cannot toggle menu while in combat."]);
        return
      end

      if (missingAnchor) then
        PositionChatIconMenu(self, profMenu, true);
        missingAnchor = nil;
        return
      end

      profMenu:SetShown(not profMenu:IsShown());

      if (profMenu:IsShown()) then
        PositionChatIconMenu(self, profMenu, true);
        missingAnchor = nil;
      end
    end);

    return professionsIcon;
  end

  function CreateShortcutsButton(muiChatFrame)
    local btn = CreateFrame("Button", "MUI_ShortcutsButton", muiChatFrame);
    btn:SetNormalTexture(string.format("%sshortcuts", MEDIA));
    btn:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
    btn:SetHighlightAtlas("chatframe-button-highlight");

    tk:SetBasicTooltip(btn, "Show AddOn Shortcuts", "ANCHOR_CURSOR_RIGHT", 16, 8);

    local menu = CreateFrame("Frame", "MUI_ShortcutsMenu", muiChatFrame, "UIMenuTemplate");
    UIMenu_Initialize(menu);

    local lines = {
      { "MUI Config", "/mui config", function() MayronUI:TriggerCommand("config") end};
      { "MUI Install", "/mui install", function() MayronUI:TriggerCommand("install") end};
      { "MUI Layouts", "/mui layouts", function() MayronUI:TriggerCommand("layouts") end};
      { "MUI Profile Manager", "/mui profiles", function() MayronUI:TriggerCommand("profiles") end};
      { "MUI Show Profiles", "/mui profiles list", function() MayronUI:TriggerCommand("profiles", "list") end};
      { "MUI Version", "/mui version", function() MayronUI:TriggerCommand("version") end};
      { "MUI Report", "/mui report", function() MayronUI:TriggerCommand("report") end};
      { "Leatrix Plus", _G.SLASH_Leatrix_Plus1, function() _G.SlashCmdList.Leatrix_Plus("") end};
      { "Toggle Alignment Grid", "/ltp grid", function() _G.SlashCmdList.Leatrix_Plus("grid") end};
      { "Bartender", "/bt", _G.Bartender4.ChatCommand};
      { "Shadowed Unit Frames", _G.SLASH_SHADOWEDUF1, function() _G.SlashCmdList.SHADOWEDUF("") end};
      { "Masque", _G.SLASH_MASQUE1, _G.SlashCmdList.MASQUE};
      { "Bagnon Bank", "/bgn bank", function() _G.Bagnon.Commands.OnSlashCommand("bank") end };
      { "Bagnon Guild Bank", "/bgn guild", function() _G.Bagnon.Commands.OnSlashCommand("guild") end, true };
      { "Bagnon Void Storage", "/bgn vault", function() _G.Bagnon.Commands.OnSlashCommand("vault") end, true };
      { "Bagnon Config", "/bgn config", function() _G.Bagnon.Commands.OnSlashCommand("config") end };
    };

    for _, line in pairs(lines) do
      if (not line[4] or tk:IsRetail()) then
        UIMenu_AddButton(menu, line[1], line[2], line[3]);
      end
    end

    UIMenu_AutoSize(menu);
    menu:Hide();

    btn:SetScript("OnClick", function(self)
      menu:SetShown(not menu:IsShown());

      if (menu:IsShown()) then
        PositionChatIconMenu(self, menu);
      end
    end);

    btn.Menu = menu;

    return btn;
  end

	function CreatePlayerStatusButton(muiChatFrame)
		local playerStatusButton = CreateFrame("Button", "MUI_PlayerStatusButton", muiChatFrame);

		local listener = em:CreateEventListener(function()
			local status = _G.FRIENDS_TEXTURE_ONLINE;
			local _, _, _, _, bnetAFK, bnetDND = _G.BNGetInfo();

			if (bnetAFK) then
				status = _G.FRIENDS_TEXTURE_AFK;
			elseif (bnetDND) then
				status = _G.FRIENDS_TEXTURE_DND;
			end

			playerStatusButton:SetNormalTexture(status);
    end);

    listener:RegisterEvent("BN_INFO_CHANGED");
    em:TriggerEventListener(listener);

		playerStatusButton:SetHighlightAtlas("chatframe-button-highlight");
		tk:SetBasicTooltip(playerStatusButton, L["Change Status"], "ANCHOR_CURSOR_RIGHT", 16, 8);

		local optionText = "\124T%s.tga:16:16:0:0\124t %s";
		local availableText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE);
		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY);
		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY);

		local function SetOnlineStatus(btn)
			FriendsFrame_SetOnlineStatus(btn);
			playerStatusButton:SetNormalTexture(btn.value);
		end

    local statusMenu = CreateFrame("Frame", "MUI_StatusMenu", muiChatFrame, "UIMenuTemplate");
    UIMenu_Initialize(statusMenu);
    --self, text, shortcut, func, nested, value
    UIMenu_AddButton(statusMenu, availableText, nil, SetOnlineStatus, nil, FRIENDS_TEXTURE_ONLINE);
    UIMenu_AddButton(statusMenu, afkText, nil, SetOnlineStatus, nil, FRIENDS_TEXTURE_AFK);
    UIMenu_AddButton(statusMenu, dndText, nil, SetOnlineStatus, nil, FRIENDS_TEXTURE_DND);
    UIMenu_AutoSize(statusMenu);
    statusMenu:Hide();

    playerStatusButton:SetScript("OnClick", function(self)
      statusMenu:SetShown(not statusMenu:IsShown());

      if (statusMenu:IsShown()) then
        PositionChatIconMenu(self, statusMenu);
      end
    end);

    playerStatusButton.Menu = statusMenu;

		return playerStatusButton;
	end
end