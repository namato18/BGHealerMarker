-- small change
-- Register the frame and events
local f = CreateFrame("Frame")
f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
f:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

local healer_list = {}
local check_tracker = 0
local iconSize = 32


f:SetSize(200, 150) -- Width, Height
f:SetPoint("CENTER", UIParent, "CENTER")

-- Create background texture
local bgTexture = f:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints(f)
-- bgTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
bgTexture:SetColorTexture(0, 0, 0, 0.8) -- RGBA color


local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("TOP", f, "TOP", 0, -10)
text:SetText("Set Icon Size")

-- Create a slider
local slider = CreateFrame("Slider", nil, f, "OptionsSliderTemplate")
slider:SetPoint("CENTER", f, "CENTER", 0, 0) -- Adjust position as needed
slider:SetMinMaxValues(0, 100) -- Set the min and max values for the slider
slider:SetValue(32) -- Set the initial value
slider:SetValueStep(1) -- Set the step size for the slider
slider:SetWidth(180) -- Set the width of the slider

-- Create a text label to display the current value
local sliderValueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sliderValueText:SetPoint("TOP", slider, "BOTTOM", 0, -5)
sliderValueText:SetText("Value: " .. slider:GetValue())

-- Update the text label when the slider value changes
slider:SetScript("OnValueChanged", function(self, value)
    sliderValueText:SetText("Value: " .. math.floor(value))
end)

-- Create an "Okay" button
local button = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
button:SetSize(80, 22) -- Set the size of the button
button:SetPoint("BOTTOM", f, "BOTTOM", 0, 10) -- Position below the slider with some padding
button:SetText("Okay") -- Set the button text

button:SetScript("OnClick", function()
    iconSize = math.floor(slider:GetValue())
    f:Hide()
end)

f:Hide()

-- Define the slash command and its handler
SLASH_BGCHECK1 = "/bghealer"

function SlashCmdList.BGCHECK(msg, editBox)
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

-- Testing a change
-- Define the slash command and its handler
SLASH_HEALERDETECTOR1 = "/check"

function SlashCmdList.HEALERDETECTOR(msg, editBox)
    -- Your command logic here
    print('quick check ' .. UnitName("player"))
end



local function CheckEnemyHealers()
    local numScores = GetNumBattlefieldScores()

    for i=1, numScores do
        local name, killingBlows, honorableKills, deaths, honorGained,
              faction, race, class, classToken, damageDone, healingDone,
              bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i)

        if check_tracker == 0 then
            if name == UnitName("player") then
                playerFaction = faction

                check_tracker = 1
                break
            end
            
        else
            if (talentSpec == 'Mistweaver' or
             talentSpec == 'Holy' or
             talentSpec == 'Preservation' or
             talentSpec == 'Restoration' or
             talentSpec == 'Discipline') and
             faction ~= playerFaction then
                local displayName = name:gsub("%-.*", " ")
                displayName = displayName:gsub("%s+", "")

                

                if not healer_list[displayName] then
                    healer_list[displayName] = true
                    print("Healer added:", displayName)
                end


            end
        end   
    end

end

-- Table to store created icons
local iconTable = {}

local function CreateIconAboveNameplate(unitID)

        -- Fetch the nameplate frame for the unit
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)

        -- Create an icon frame if not already created
        if not iconTable[unitID] then

            -- Create the icon frame
            local icon = CreateFrame("Frame", nil, UIParent)
            icon:SetSize(iconSize, iconSize)
            icon:SetFrameStrata("HIGH")

            -- Create a texture for the main icon
            local texture = icon:CreateTexture(nil, "ARTWORK")
            texture:SetAllPoints()
            texture:SetTexture("Interface\\Icons\\Spell_Holy_FlashHeal")  -- Main icon texture
            texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)  -- Adjust if needed

            icon:Show()

            -- Set default position (centered in the screen)
            icon:SetPoint("CENTER", nameplate, "CENTER", 0, 50)


            -- Store the icon in the table
            iconTable[unitID] = icon
        end
    -- end
end

local function RemoveIconForNameplate(unitID)
    -- Check if the icon exists in the table
    if iconTable[unitID] then
        -- Remove the icon frame
        iconTable[unitID]:Hide()
        iconTable[unitID]:SetParent(nil) -- Detach from UIParent to clean up

        -- Remove the icon from the table
        iconTable[unitID] = nil
    end
end



-- Event handler function
    f:SetScript("OnEvent", function(self, event, unitID)
        if event == "NAME_PLATE_UNIT_ADDED" then
            local fullName = UnitName(unitID)
            local playerName = fullName:match("^[^ ]+")
            -- if healer_list[playerName] then
                CreateIconAboveNameplate(unitID)
            -- end

        elseif event == 'NAME_PLATE_UNIT_REMOVED' then
            RemoveIconForNameplate(unitID)
        elseif event == "UPDATE_BATTLEFIELD_SCORE" then
            CheckEnemyHealers()
        elseif event == "PLAYER_ENTERING_BATTLEGROUND" then
            check_tracker = 0
            healer_list = {}
        end
    end)


