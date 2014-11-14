t = {}

local function HexToRGBPerc(hex)
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
end

local function RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

local RED_VALUE, GREEN_VALUE, BLUE_VALUE = HexToRGBPerc('aaaaaa');
local MAX_LINES = 5;

gw_lastUpdate = 0;
gw_thisPlayerName = '';

local MAX_LEVEL = 100;

RAID_CLASS_COLORS = {
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["MAGE"] = { r = 0.41, g = 0.8, b = 0.94 },
    ["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41 },
    ["DRUID"] = { r = 1.0, g = 0.49, b = 0.04 },
    ["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87 },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["DEATH KNIGHT"] = { r = 0.77, g = 0.12 , b = 0.23 },
    ["MONK"] = { r = 0.0, g = 1.00 , b = 0.59 },
};

function GuildWho_WriteChatMessage(what)
    DEFAULT_CHAT_FRAME:AddMessage('|cffff9900<|cffff6600GuildWho|cffff9900>|r ' .. what, RED_VALUE, GREEN_VALUE, BLUE_VALUE);
end

function GuildWho_GetClassColor(class)
    color = RAID_CLASS_COLORS[class:upper()];
    if color == nil then
        GuildWho_WriteChatMessage("cannot find class " .. class);
        hex = "";
    else
        hex = RGBPercToHex(color.r, color.g, color.b);
    end
    return hex;
end

function GuildWho_OnUpdate(self, elapsed)
    gw_lastUpdate = gw_lastUpdate + elapsed;
    if (gw_lastUpdate > 5.0) then
        GuildRoster();
        gw_lastUpdate = 0;
    end
end

function GuildWho_Update()
    if (gw_thisPlayerName=='') then
        gw_thisPlayerName, x = UnitName('player');
    end
    total, online = GetNumGuildMembers();
    msg = '';
    max_lines = 0;
    for i=1, total do
        if (max_lines > MAX_LINES - 1) then
            break
        end
        name, x, x, level, class, zone, x, x, online, x, x, x, x, x = GetGuildRosterInfo(i);
        name = string.sub(name, 0, string.find(name, '-') - 1); -- strip server
        if (true or name ~= gw_thisPlayerName) then
            if (online) then
                if (t[name] ~= zone) then
                    if (t[name] == nil) then
                        t[name] = 'offline'
                    end
                    GuildWho_WriteChatMessage('|cff' .. GuildWho_GetClassColor(class) .. name ..
                                              '|r |cffffffff' .. t[name] ..
                                              '|r > |cffffffff' .. zone .. '|r');
                end
                t[name] = zone;
                msg = msg .. '|cff' .. GuildWho_GetClassColor(class) .. name .. '|r';
                if (level ~= MAX_LEVEL) then
                    msg = msg .. ' [' .. level .. ']';
                end
                msg = msg .. ' - ' .. zone .. '\n';
                max_lines = max_lines + 1;
            end
            if (not online) then
                local y, m, d, h = GetGuildRosterLastOnline(i);
                if (y == 0 and m == 0 and d == 0 and h >= 0) then
                    msg = msg .. name;
                    if (level ~= MAX_LEVEL) then
                        msg = msg .. ' [' .. level .. ']';
                    end
                    msg = msg .. ' - ' .. zone;
                    if (h == 0) then
                        msg = msg .. ' (<1h ago)\n';
                    else
                        msg = msg .. ' (' .. h .. 'h ago)\n';
                    end
                    max_lines = max_lines + 1;
                end
            end
        end
    end
    GuildWhoMessageFrame:AddMessage(msg, RED_VALUE, GREEN_VALUE, BLUE_VALUE);
end

function GuildWho_ParseParameters(paramStr)
    if (paramStr == 'lock') then
        sgw_frame:EnableMouse(false);
        sgw_frame:RegisterForDrag('');
        GuildWho_WriteChatMessage("locked");
    elseif (paramStr == 'unlock') then
        sgw_frame:EnableMouse(true);
        sgw_frame:RegisterForDrag('LeftButton');
        GuildWho_WriteChatMessage("unlocked, use left-click to move");
    else
        GuildWho_WriteChatMessage("lock: lock the display");
        GuildWho_WriteChatMessage("unlock: unlock the display");
    end
end

function GuildWho_OnEvent(self, event, arg1, arg2, arg3, arg4)
    if (event == 'GUILD_ROSTER_UPDATE') then
        GuildWho_Update();
    elseif (event == 'ADDON_LOADED' and arg1 == 'Preech_GuildWho') then
        GuildWho_WriteChatMessage("GuildWho loaded (/sgw)");
        SLASH_PREECH_GUILDWHO1 = '/pgw';
        SlashCmdList['PREECH_GUILDWHO'] = GuildWho_ParseParameters;
    end
end

sgw_frame=CreateFrame('MessageFrame', 'GuildWhoMessageFrame', UIParent);
sgw_frame:SetMovable(true);
sgw_frame:SetScript('OnDragStart', sgw_frame.StartMoving);
sgw_frame:SetScript('OnDragStop', sgw_frame.StopMovingOrSizing);
sgw_frame:SetScript('OnUpdate', GuildWho_OnUpdate);
sgw_frame:SetScript('OnEvent', GuildWho_OnEvent);
sgw_frame:RegisterEvent('ADDON_LOADED');
sgw_frame:RegisterEvent('GUILD_ROSTER_UPDATE');
sgw_frame:SetWidth(300);
sgw_frame:SetHeight(20);
sgw_frame:SetFrameStrata('HIGH');
sgw_frame:SetFading(false);
sgw_frame:SetPoint('TOPLEFT');
sgw_frame:SetFontObject(GameFontNormalSmall, 10, "OUTLINE");
font = sgw_frame:GetFontObject();
font:SetJustifyH('LEFT');
sgw_frame:Show();
SortGuildRoster('online');
