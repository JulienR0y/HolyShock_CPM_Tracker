-- Define the spell ID for Holy Shock
local HOLY_SHOCK_SPELL_ID = 20473

-- Create a new frame for displaying the Holy Shock counter
local cpmFrame = CreateFrame("Frame", "HolyShockCPMFrame", UIParent)
cpmFrame:SetPoint("CENTER", 0, 0)
cpmFrame:SetSize(200, 50)

-- Create a new font string for displaying the Holy Shock counter value
local cpmText = cpmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cpmText:SetPoint("CENTER", 0, 0)
cpmText:SetText("Holy Shock: 0")
cpmText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

-- Create a new font string for displaying the clicks per minute
local cpmTrackerFontString = cpmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cpmTrackerFontString:SetPoint("BOTTOM", cpmText, "TOP", 0, 5)
cpmTrackerFontString:SetText("CPM: 0")
cpmTrackerFontString:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

-- Create a new font string for displaying the Est. clicks per minute
local estimatedCPMFontString = cpmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
estimatedCPMFontString:SetPoint("BOTTOM", cpmTrackerFontString, "TOP", 0, 5)
estimatedCPMFontString:SetText("Est. CPM: 0")
estimatedCPMFontString:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

-- Create a new button to reset the Holy Shock cast counter
local resetButton = CreateFrame("Button", "HolyShockCPMResetButton", cpmFrame, "UIPanelButtonTemplate")
resetButton:SetText("Reset Counter")
resetButton:SetPoint("BOTTOM", cpmFrame, "BOTTOM", 0, -10)
resetButton:SetSize(100, 25)
resetButton:SetScript("OnClick", function()
    counter = 0
    cpmText:SetText("Holy Shock: " .. counter)
    clicks = 0
    startTime = 0
    endTime = 0
    inCombat = false
    lastCastTime = 0
    cpmTrackerFontString:SetText("CPM: 0")
    estimatedCPMFontString:SetText("Est. CPM: 0")
end)

-- Keep track of clicks per minute while in combat
local clicks = 0
local startTime = 0
local endTime = 0
local inCombat = false
local lastCastTime = 0
local tracker = CreateFrame("Frame")
tracker:RegisterEvent("PLAYER_REGEN_DISABLED")
tracker:RegisterEvent("PLAYER_REGEN_ENABLED")
tracker:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        startTime = GetTime()
        inCombat = true
        self:SetScript("OnUpdate", function(self, elapsed)
            endTime = GetTime()
            if endTime - startTime >= 60 then
                if inCombat then -- Update only if inCombat is true
                    cpmTrackerFontString:SetText("CPM: " .. clicks)
                    clicks = 0
                    startTime = GetTime()
                end
                inCombat = false -- Set inCombat to false after update
            end
            local timeSinceLastCast = endTime - (lastCastTime or 0)
            if timeSinceLastCast > 0 then
                local gcd = select(2, GetSpellCooldown(61304))
                if gcd == 0 then
                    gcd = 1.5
                end
                local estimatedCPM = math.floor(60 / (timeSinceLastCast + gcd))
                estimatedCPMFontString:SetText("Est. CPM: " .. estimatedCPM)
            end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        self:SetScript("OnUpdate", nil)
        cpmTrackerFontString:SetText("CPM: 0")
        clicks = 0
        startTime = 0
        endTime = 0
    end
end)

tracker:SetScript("OnUpdate", function(self, elapsed)
    endTime = GetTime()
    if endTime - startTime >= 60 then
        if inCombat then -- Update only if inCombat is true
            cpmTrackerFontString:SetText("CPM: " .. clicks)
            clicks = 0
            startTime = GetTime()
        end
        inCombat = false -- Set inCombat to false after update
    end
    local timeSinceLastCast = endTime - (lastCastTime or 0)
    if timeSinceLastCast > 0 then
        local estimatedCPM = math.floor(60 / timeSinceLastCast)
        estimatedCPMFontString:SetText("Est. CPM: " .. estimatedCPM)
    end
end)

-- Update the Holy Shock counter value and clicks per minute whenever the player casts Holy Shock
local counter = 0
cpmFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
cpmFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
cpmFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
cpmFrame:SetScript("OnEvent", function(self, event, ...)
    local _, eventType, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") and spellID == HOLY_SHOCK_SPELL_ID then
        counter = counter + 1
        cpmText:SetText("Holy Shock: " .. counter)
        clicks = clicks + 1
        lastCastTime = GetTime()
        inCombat = true -- Set inCombat to true when the player casts Holy Shock
    elseif event == "PLAYER_REGEN_ENABLED" then
        counter = 0
        cpmText:SetText("Holy Shock: " .. counter)
    end
end)

-- Enable font size adjustment using the mouse wheel
cpmFrame:EnableMouseWheel(true)
cpmFrame:SetScript("OnMouseWheel", function(self, delta)
    if IsShiftKeyDown() then
        local font, size, flags = cpmText:GetFont()
        if delta > 0 then
            size = size + 1
        elseif delta < 0 then
            size = size - 1
        end
        cpmText:SetFont(font, size, flags)
        cpmTrackerFontString:SetFont(font, size, flags)
    else
        local width = self:GetWidth()
        local height = self:GetHeight()
        if delta > 0 then
            self:SetSize(width + 10, height + 10)
        elseif delta < 0 then
            self:SetSize(width - 10, height - 10)
        end
    end
end)

-- Enable frame movement with Shift + Left Click
cpmFrame:SetMovable(true)
cpmFrame:RegisterForDrag("LeftButton")
cpmFrame:SetScript("OnMouseDown", function(self, button)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end)
cpmFrame:SetScript("OnMouseUp", function(self, button)
    self:StopMovingOrSizing()
end)

-- Enable clicks per minute tracking
local clicks = 0
local startTime = 0
local endTime = 0
local tracker = CreateFrame("Frame")
tracker:RegisterEvent("PLAYER_REGEN_DISABLED")
tracker:RegisterEvent("PLAYER_REGEN_ENABLED")
tracker:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        startTime = GetTime()
        self:SetScript("OnUpdate", function(self, elapsed)
            endTime = GetTime()
            if endTime - startTime >= 60 then
                cpmTrackerFontString:SetText("CPM: " .. clicks)
                clicks = 0
                startTime = GetTime()
            end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:SetScript("OnUpdate", nil)
        cpmTrackerFontString:SetText("CPM: 0")
        clicks = 0
        startTime = 0
        endTime = 0
    end
end)

cpmFrame:SetScript("OnUpdate", function(self, elapsed)
    local _, eventType, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") and spellID == HOLY_SHOCK_SPELL_ID then
        counter = counter + 1
        cpmText:SetText("Holy Shock: " .. counter)
        clicks = clicks + 1
    end
end)
