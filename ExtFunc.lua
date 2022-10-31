
ExtFunc = {
    Hue = 0,
    PowerType = {
        ["MANA"]           = 0,
        ["RAGE"]           = 1,
        ["FOCUS"]          = 2,
        ["ENERGY"]         = 3,
        ["HAPPINESS"]      = 4,
        ["RUNES"]          = 5,
        ["RUNICPOWER"]     = 6,
        ["SOULSHARDS"]     = 7,
        ["ECLIPSE"]        = 8,
        ["HOLYPOWER"]      = 9,
        ["ALTERNATE"]      = 10,
        ["MAELSTROM"]      = 11,
        ["CHI"]            = 12,
        ["INSANITY"]       = 13,
        ["OBSOLETE"]       = 14,
        ["OBSOLETE2"]      = 15,
        ["ARCANECHARGES"]  = 16,
        ["FURY"]           = 17,
        ["PAIN"]           = 18
    }
};

--  HSV to RGB color conversion
--  ===============================
--  H runs from 0 to 360 degrees
--  S and V run from 0 to 100

--  Ported from the java algorithm by Eugene Vishnevsky at:
--- http://www.cs.rit.edu/~ncs/color/t_convert.html

-- ported from: https://gist.github.com/eyecatchup/9536706
function ExtFunc.HSVtoRGB(h, s, v)
	ExtFunc.Hue = h;
	local e = ExtFunc;
    local r, g, b;
    local i;
    local f, p, q, t;
     
    -- Make sure our arguments stay in-range
    h = math.max(0, math.min(360, h));
    s = math.max(0, math.min(100, s));
    v = math.max(0, math.min(100, v));
    
    -- We accept saturation and value arguments from 0 to 100 because that's
    -- how Photoshop represents those values. Internally, however, the
    -- saturation and value are calculated from a range of 0 to 1. We make
    -- That conversion here.

    s = s / 100;
    v = v / 100;
     
    if(s == 0) then
        -- Achromatic (grey)
        r = v;
		g = v;
		b = v;
        return { e.round(r, 2), e.round(g, 2), e.round(b, 2), 1};
    end
     
    h = h / 60; -- sector 0 to 5
    i = math.floor(h);
    f = h - i; -- factorial part of h
    p = v * (1 - s);
    q = v * (1 - s * f);
    t = v * (1 - s * (1 - f));
    

	if i == 0 then
	    r = v;
		g = t;
		b = p;
    elseif i == 1 then
		r = q;
		g = v;
		b = p;
	elseif i == 2 then
		r = p;
		g = v;
		b = t;
    elseif i == 3 then
		r = p;
		g = q;
		b = v;
    elseif i == 4 then
		r = t;
		g = p;
		b = v;
    else
		r = v;
		g = p;
		b = q;
	end
     
    return { e.round(r, 2),  e.round(g, 2), e.round(b, 2), 1};
end

function ExtFunc.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ExtFunc.UpdateColorWATexture(id, colorValue)

	local WA = WeakAuras;
	local obj, modify;
    
    if WA.regions and WA.regions[id] and WA.regions[id]['region'] then
        obj = WA.regions[id]['region']
    end
	
    local anchor, data;
    if obj then
        anchor, data = select(2, obj:GetPoint()), WA.GetData(id)
    end
    
    if WA.regionTypes and WA.regionTypes.texture and WA.regionTypes.texture.modify then
        modify = WA.regionTypes.texture.modify
    end
    
    if data then
		data.color = colorValue;
    end
    
    if anchor and obj and data then
        modify(anchor, obj, data)
    end
    
    return true;

end

function ExtFunc.GetArtifactPower()

    local itemID, altItemID, name, icon, xp, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
    local pointsAvailable = 0

    if pointsSpent == nil then
        return 0, 0, 0
    end

    local nextRankCost = C_ArtifactUI.GetCostForPointAtRank(pointsSpent + pointsAvailable, artifactTier) or 0
    
    while xp >= nextRankCost and nextRankCost > 0 do
        xp = xp - nextRankCost
        pointsAvailable = pointsAvailable + 1
        nextRankCost = C_ArtifactUI.GetCostForPointAtRank(pointsSpent + pointsAvailable, artifactTier) or 0
    end

    return xp or 0, nextRankCost or 0, pointsAvailable or 0
end

function ExtFunc.CommaValue(amount)
    local formatted = amount
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
  end

function ExtFunc.ReadableNumber(num, places)
    local ret
    local placeValue = ("%%.%df"):format(places or 0)
    if not num then
        return 0
    elseif num >= 1e12 then
        ret = placeValue:format(num / 1e12) .. " T" -- trillion
    elseif num >= 1e9 then
        ret = placeValue:format(num / 1e9) .. " B" -- billion
    elseif num >= 1e6 then
        ret = placeValue:format(num / 1e6) .. " M" -- million
    elseif num >= 1000 then
        ret = placeValue:format(num / 1000) .. "K" -- thousand
    else
        ret = num -- hundreds
    end
    return ret
end

function ExtFunc.GetWatchedFactionInfo()

    local FRIEND_FACTION_COLOR_INDEX = 5
    local PARAGON_FACTION_COLOR_INDEX = #FACTION_BAR_COLORS
    local MAX_REPUTATION_REACTION = _G.MAX_REPUTATION_REACTION

    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()

    if not name then
        local color = FACTION_BAR_COLORS[1]
        --self:SetColor(color.r, color.g, color.b)
        --self:SetValues()
        --self:SetText(_G.REPUTATION)
        return
    end

    local description, colorIndex, capped

    if C_Reputation.IsFactionParagon(factionID) then
        local currentValue, threshold, rewardQuestID, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
        min, max, value = 0, threshold, currentValue % threshold

        colorIndex = PARAGON_FACTION_COLOR_INDEX
        description = GetText('FACTION_STANDING_LABEL'..reaction, UnitSex('player'))
        capped = false
    else
        local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
        if friendID then
            if nextFriendThreshold then
                min, max, value = friendThreshold, nextFriendThreshold, friendRep
            else
                min, max, value = 0, 1, 1
                capped = true
            end

            colorIndex = FRIEND_FACTION_COLOR_INDEX
            description = friendTextLevel
        else
            if reaction == MAX_REPUTATION_REACTION then
                min, max, value = 0, 1, 1
                capped = true
            end

            colorIndex = reaction
            description = GetText('FACTION_STANDING_LABEL'..reaction, UnitSex('player'))
        end
    end

    max = max - min
    value = value - min

    local color = FACTION_BAR_COLORS[reaction]

    return color, name, value, max, description, capped
end

function ExtFunc.slashCommand(command,args)
    for key,func in pairs(SlashCmdList) do
        local i = 1
        local c = _G[("SLASH_%s1"):format(key)]
        while c do
            if c == command then
                func(args)
                return
            end
            i=i+1
            c = _G[("SLASH_%s%d"):format(key,i)]
        end
    end
end