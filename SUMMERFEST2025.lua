--!strict

-- Dehash script
local success_dehash, err_dehash = pcall(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/UnclesVan/AdoPtMe-/refs/heads/main/dehashwithslashinmiddle'))()
end)
if not success_dehash then warn("Dehash failed: " .. err_dehash) end
task.wait(2)

-- Load Fluent libraries
local Fluent = nil
local SaveManager = nil
local InterfaceManager = nil

local success_fluent, err_fluent = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
local success_save, err_save = pcall(function()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)
local success_interface, err_interface = pcall(function()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

-- Debug prints for Fluent addon loading
print("Type of SaveManager after direct load: " .. typeof(SaveManager))
print("Type of InterfaceManager after direct load: " .. typeof(InterfaceManager))
print("Type of InterfaceManager.SetTheme: " .. typeof(InterfaceManager and InterfaceManager.SetTheme))


if not Fluent then
    error("Failed to load Fluent UI library. Please check your internet connection or the URL.")
end

-- Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Create main Fluent UI window
local Window = Fluent:CreateWindow({
    Title = "SummerFest 2025 Automation v75", -- Updated title
    SubTitle = "by dawid", -- Updated subtitle
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Define Tabs
local Tabs = {
    TreasureDefence = Window:AddTab({ Title = "Treasure Defence", Icon = "shield-alt" }),
    CannonCircle = Window:AddTab({ Title = "Cannon Circle", Icon = "bullseye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- Hand the library over to our managers and set up their sections
if SaveManager and typeof(SaveManager) == "table" and typeof(SaveManager.SetLibrary) == "function" then
    SaveManager:SetLibrary(Fluent)
    -- SaveManager:IgnoreThemeSettings() -- Uncomment if you want to ignore theme settings in config
    -- SaveManager:SetIgnoreIndexes({}) -- Uncomment and add indexes to ignore specific elements
    SaveManager:SetFolder("FluentScriptHub/specific-game") -- Example folder, adjust if needed
    SaveManager:BuildConfigSection(Tabs.Settings)
    SaveManager:LoadAutoloadConfig()
    print("SaveManager initialized successfully.")
else
    warn("SaveManager could not be initialized or is missing SetLibrary. (Type: " .. typeof(SaveManager) .. ")")
end

if InterfaceManager and typeof(InterfaceManager) == "table" and typeof(InterfaceManager.SetTheme) == "function" then
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("FluentScriptHub") -- Example folder, adjust if needed
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    print("InterfaceManager initialized successfully.")
else
    warn("InterfaceManager could not be initialized or is missing SetTheme. (Type: " .. typeof(InterfaceManager) .. ")")
end

Fluent:Notify({
    Title = "Loaded",
    Content = "Script loaded successfully.",
    Duration = 3
})

-- --- SCRIPT STATE ---
local scriptEnabled = false -- Controls the main script loop
local hotbarSpamActive = true -- Example feature state (controlled by scriptEnabled's main loop)
local teleportToRaidersActive = true -- ONLY THIS TELEPORT IS ACTIVE (controlled by scriptEnabled's main loop)
local scoreIncreasingActionsAllowed = true
local hasClickedStartButton = false
local autoClickHotbarActive = false -- New: State for auto click hotbar toggle
local rewardsAutoClickActive = false -- State for auto click rewards button (now controls new logic)
local detectKelpRaiderShipsActive = true -- State for detecting kelp raider ships
local cannonCircleActive = false -- NEW: State for Cannon Circle automation

-- --- CONFIGURATION ---
local FROSTCLAWS_HOTBAR_APP_NAME = "MinigameHotbarApp"
local DROP_BUTTON_NAME = "DropButton"
local SWORD_BUTTON_NAME = "Sword_Button" -- Corrected from "SwordButton" based on common Roblox UI naming
local EXCLUDED_MODEL_KEYWORDS = {"parrot", "cage"} -- Models to exclude from teleportation
local COCONUT_BONK_INTERIOR_BASE_NAME = "CoconutBonkInterior"
local GOLD_PILE_GUARD_RADIUS = 30 -- Radius around GoldPile to detect raiders
local TARGET_SCORE = 1600
local SCORE_UPPER_TOLERANCE = 50
local SCORE_LOWER_TOLERANCE = 50
local MAX_CONSOLE_LINES = 20
local LOG_FINDING_COOLDOWN = 1
local REWARDS_BUTTON_PATH = "MinigameRewardsApp.Body.Button" -- Original path to the rewards button (kept for reference, but not used in handleRewardsAutoClick anymore)

local TURRET_PARENT_CONTAINER_INDEX = 65
local TURRET_1_NAME = "Meshes/Castle_Crenelation_V3" -- This is a specific name, not an index
local TURRET_2_INDEX = 2 -- This is an index within the "Turrets" folder

-- Constants for minigame phases
local TELEPORT_PHASE_PILES = "Piles"
local TELEPORT_PHASE_TURRETS = "Turrets"
local TELEPORT_PHASE_RAIDERS_SHIPS = "Raiders & Ships"
local TELEPORT_PHASE_INTERVAL = 2 -- seconds to wait between phases for automation loop

-- Constant for score log cooldown
local SCORE_LOG_COOLDOWN = 5 -- seconds

-- --- INTERNAL ---
local lastLogTime = {} -- For logFinding cooldowns
local findingMinigameCoroutine = nil -- To manage the "finding minigame..." loop
local lastScoreLogTime = 0 -- For score logging cooldown
local lastNoThreatLogTime = 0 -- For no threat logging cooldown

-- References to Fluent UI elements for updating
local scriptToggleFluentBtn = nil
local autoClickHotbarFluentBtn = nil
local rewardsAutoClickFluentBtn = nil
local teleportToRaidersFluentBtn = nil
local hotbarSpamFluentBtn = nil
local detectKelpRaiderShipsFluentBtn = nil
local cannonCircleFluentBtn = nil -- NEW: Fluent UI element for Cannon Circle toggle
local consoleOutputElement = nil -- This will be the actual Fluent UI element we write to

-- New: Internal table to manage console log lines
local internalLogLines = {}


-- Ensure character and humanoidrootpart are available from the start, with robust checks
local character = player.Character
local humanoidRootPart = nil

-- --- FUNCTIONS ---

-- Robust function to get character and HumanoidRootPart
local function getCharacterAndHRP()
    local currentCharacter = player.Character
    if not currentCharacter then
        local success, result = pcall(function() return player.CharacterAdded:Wait() end)
        if success and result then
            currentCharacter = result
        else
            warn("Failed to get character: " .. tostring(result))
            return nil, nil
        end
    end

    local currentHrp = nil
    local attempts = 0
    while attempts < 100 do -- Try for up to 10 seconds
        if currentCharacter and currentCharacter.Parent then
            currentHrp = currentCharacter:FindFirstChild("HumanoidRootPart")
            if currentHrp then break end
        end
        task.wait(0.1)
        attempts = attempts + 1
        if not currentCharacter or not currentCharacter.Parent then
            -- Re-attempt to get character if it disappears
            local success, result = pcall(function() return player.Character or player.CharacterAdded:Wait() end)
            if success and result then
                currentCharacter = result
            end
        end
    end
    return currentCharacter, currentHrp
end

-- Utility function for logging to the console UI
function log(message, debugTag)
    local timestamp = os.date("%H:%M:%S", os.time())
    local formattedMessage = "[" .. timestamp .. "] " .. tostring(message)
    if debugTag then
        formattedMessage = formattedMessage .. " " .. debugTag
    end

    -- Check if consoleOutputElement is a valid Fluent Paragraph and has SetContent
    if consoleOutputElement and typeof(consoleOutputElement) == "table" and typeof(consoleOutputElement.SetContent) == "function" then
        local success, err = pcall(function()
            -- Add new message to our internal log history
            table.insert(internalLogLines, formattedMessage)

            -- Limit lines
            if #internalLogLines > MAX_CONSOLE_LINES then
                table.remove(internalLogLines, 1) -- Remove oldest line
            end

            -- Update the Fluent Paragraph element using SetContent
            consoleOutputElement:SetContent(table.concat(internalLogLines, "\n"))
        end)
        if not success then
            warn("Error writing to Fluent UI console output: " .. tostring(err) .. ". Falling back to print().")
            print(formattedMessage) -- Fallback to Roblox output if UI write fails
        end
    else
        print(formattedMessage) -- Fallback to Roblox output if console UI not ready or SetContent is missing
    end
end

-- Log function with cooldown for "finding" messages (now uses global log)
local function logFinding(key, messageName, isFound)
    local currentTime = tick()
    if isFound then
        if lastLogTime[key] ~= "found" then
            log(messageName .. " found!")
            lastLogTime[key] = "found"
        end
    else
        if lastLogTime[key] == "found" then
            log(messageName .. " not found. Searching...")
            lastLogTime[key] = currentTime
        elseif not lastLogTime[key] or (currentTime - lastLogTime[key]) >= LOG_FINDING_COOLDOWN then
            log("Finding " .. messageName .. "...")
            lastLogTime[key] = currentTime
        end
    end
end

-- Simulates a button click (general purpose, now uses global log)
local function clickButton(button)
    if not (button and button.Parent and button.Visible and button.Active) then
        log("Button invalid or not visible/active for clicking: " .. (button and button.Name or "nil"))
        return
    end

    log("Attempting to click: " .. button.Name)

    local success_down, connectionsDown = pcall(function() return getconnections(button.MouseButton1Down) end)
    if success_down and connectionsDown then
        log("MouseButton1Down connections found: " .. #connectionsDown .. ". Firing...")
        for i, connection in ipairs(connectionsDown) do
            local s, e = pcall(function() connection:Fire() end)
            if not s then log("Failed to fire MouseButton1Down connection " .. i .. ": " .. tostring(e)) end
        end
    else
        log("Warning: Could not get MouseButton1Down connections for " .. button.Name .. ". Error: " .. tostring(connectionsDown))
    end
    task.wait(0.05)

    local success_click, connectionsClick = pcall(function() return getconnections(button.MouseButton1Click) end)
    if success_click and connectionsClick then
        log("MouseButton1Click connections found: " .. #connectionsClick .. ". Firing...")
        for i, connection in ipairs(connectionsClick) do
            local s, e = pcall(function() connection:Fire() end)
            if not s then log("Failed to fire MouseButton1Click connection " .. i .. ": " .. tostring(e)) end
        end
    else
        log("Warning: Could not get MouseButton1Click connections for " .. button.Name .. ". Error: " .. tostring(connectionsClick))
    end
    task.wait(0.05)

    local success_up, connectionsUp = pcall(function() return getconnections(button.MouseButton1Up) end)
    if success_up and connectionsUp then
        log("MouseButton1Up connections found: " .. #connectionsUp .. ". Firing...")
        for i, connection in ipairs(connectionsUp) do
            local s, e = pcall(function() connection:Fire() end)
            if not s then log("Failed to fire MouseButton1Up connection " .. i .. ": " .. tostring(e)) end
        end
    else
        log("Warning: Could not get MouseButton1Up connections for " .. button.Name .. ". Error: " .. tostring(connectionsUp))
    end

    log("Completed attempt to click the button: " .. button.Name)
end


-- Checks if the minigame is currently active based on the hotbar UI (now uses global log)
local function isMinigameActive()
    local hotbarApp = playerGui:FindFirstChild(FROSTCLAWS_HOTBAR_APP_NAME)
    if hotbarApp then
        log("DEBUG: Found MinigameHotbarApp. Enabled: " .. tostring(hotbarApp.Enabled))
        if hotbarApp.Enabled then
            logFinding("minigame", "Minigame", true)
            return true
        else
            logFinding("minigame", "Minigame", false)
            return false
        end
    else
        log("DEBUG: MinigameHotbarApp not found.")
        logFinding("minigame", "Minigame", false)
        return false
    end
end

-- Handles clicking of hotbar abilities (Drop and Sword, now uses global log)
local function handleHotbarAbilities()
    if not hotbarSpamActive then -- Check the new toggle state
        log("Hotbar abilities spam is OFF.")
        return
    end
    if not scoreIncreasingActionsAllowed then
        log("Hotbar abilities paused due to score control.")
        return
    end

    local hotbarApp = playerGui:FindFirstChild(FROSTCLAWS_HOTBAR_APP_NAME)
    if hotbarApp then
        local hotbarFrame = hotbarApp:FindFirstChild("Hotbar")
        if hotbarFrame then
            local dropBtnContainer = hotbarFrame:FindFirstChild(DROP_BUTTON_NAME)
            local dropBtn = dropBtnContainer and dropBtnContainer:FindFirstChild("Button")
            local swordBtnContainer = hotbarFrame:FindFirstChild(SWORD_BUTTON_NAME)
            local swordBtn = swordBtnContainer and swordBtnContainer:FindFirstChild("Button")

            if dropBtn and dropBtn.Visible and dropBtn.Active then
                clickButton(dropBtn)
                log("Clicked DropButton.")
            else
                logFinding("drop_button", "Drop Button (nested)", false)
            end
            task.wait(0.1)
            if swordBtn and swordBtn.Visible and swordBtn.Active then
                clickButton(swordBtn)
                log("Clicked SwordButton.")
            else
                logFinding("sword_button", "Sword Button (nested)", false)
            end
        else
            logFinding("hotbar_frame", "Hotbar Frame", false)
        end
    else
        logFinding("hotbar_app", "Hotbar App", false)
    end
end

-- Finds the CoconutBonkInterior instance (now uses global log)
local function findCoconutBonkInterior()
    if not workspace.Interiors then
        logFinding("bonk_interior_base", "workspace.Interiors", false)
        return nil
    end
    for _, interior in ipairs(workspace.Interiors:GetChildren()) do
        if interior.Name:find(COCONUT_BONK_INTERIOR_BASE_NAME, 1, true) then
            logFinding("bonk_interior", "CoconutBonkInterior", true)
            return interior
        end
    end
    logFinding("bonk_interior", "CoconutBonkInterior", false)
    return nil
end

-- Finds the Pets container within the minigame interior (now uses global log)
local function findPetsContainer()
    local interior = findCoconutBonkInterior()
    if not interior then return nil end
    local gameFolder = interior:FindFirstChild("Game")
    if gameFolder then
        local bins = gameFolder:FindFirstChild("Bins")
        if bins then
            local pets = bins:FindFirstChild("Pets")
            if pets then
                logFinding("pets_container", "Pets (Game.Bins.Pets)", true)
                return pets
            end
        end
    end
    logFinding("pets_container", "Pets (Game.Bins.Pets)", false)
    return nil
end

-- Finds Kelp Raider Ships (now uses global log)
local function findKelpRaiderShips()
    local ships = {}
    local interior = findCoconutBonkInterior()
    if not interior then return ships end
    local gameFolder = interior:FindFirstChild("Game")
    if not gameFolder then return ships end
    local binsFolder = gameFolder:FindFirstChild("Bins")
    if not binsFolder then return ships end
    local boatsFolder = binsFolder:FindFirstChild("Boats")
    if not boatsFolder then
        logFinding("boats_folder", "Game.Bins.Boats", false)
        return ships
    end
    logFinding("boats_folder", "Game.Bins.Boats", true)
    for _, obj in ipairs(boatsFolder:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "Boat" then
            local rootPart = obj:FindFirstChild("Root")
            if rootPart and rootPart:IsA("BasePart") then
                table.insert(ships, rootPart)
            end
        end
    end
    return ships
end

-- Handles teleportation to "raider" models (excluding specific keywords, now uses global log)
local function handleTeleportToModels()
    if not teleportToRaidersActive then -- Check the new toggle state
        log("Teleport to Raiders is OFF.")
        return
    end

    local petsContainer = findPetsContainer()
    local currentCharacter, hrp = getCharacterAndHRP()
    local bonkInterior = findCoconutBonkInterior()

    if not petsContainer or not bonkInterior or not hrp or not hrp.Parent == currentCharacter then
        log("Teleport conditions not met (petsContainer, bonkInterior, or HRP missing).")
        return
    end

    local gameFolder = bonkInterior:FindFirstChild("Game")
    local goldPileRoot = gameFolder and gameFolder:FindFirstChild("GoldPile") and gameFolder.GoldPile:FindFirstChild("Root")
    if not goldPileRoot or not goldPileRoot:IsA("BasePart") then
        log("No valid GoldPile Root for raider detection.")
        return
    end
    local goldPos = goldPileRoot.Position

    local threatsFound = false
    -- Check pets
    for _, model in ipairs(petsContainer:GetChildren()) do
        if model:IsA("Model") then
            local nameLower = model.Name:lower()
            local shouldExclude = false
            for _, keyword in ipairs(EXCLUDED_MODEL_KEYWORDS) do
                if nameLower:find(keyword) then
                    shouldExclude = true
                    break
                end
            end
            if not shouldExclude then
                local targetPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
                if targetPart and targetPart:IsA("BasePart") then
                    local dist = (targetPart.Position - goldPos).magnitude
                    if dist <= GOLD_PILE_GUARD_RADIUS then
                        log("Threat: " .. model.Name .. " within guard radius (" .. math.floor(dist) .. " studs). Teleporting.")
                        local teleportPos = targetPart.Position + Vector3.new(0, 5, 0) -- Teleport slightly above
                        local lookAtPos = targetPart.Position -- Look at the raider's position
                        -- Ensure HRP is still valid before teleporting
                        if hrp and hrp.Parent == currentCharacter then
                            hrp.CFrame = CFrame.lookAt(teleportPos, lookAtPos)
                            task.wait(0.005) -- Small wait after teleport
                        end
                        threatsFound = true
                        return -- We teleport to the first detected raider and then return to let the loop continue
                    end
                end
            end
        end
    end

    -- Check Kelp Raider Ships if active
    if detectKelpRaiderShipsActive then
        local ships = findKelpRaiderShips()
        for _, shipPart in ipairs(ships) do
            local dist = (shipPart.Position - goldPos).magnitude
            if dist <= GOLD_PILE_GUARD_RADIUS then
                log("Threat: Kelp Raider Ship within guard radius (" .. math.floor(dist) .. " studs). Teleporting.")
                local teleportPos = shipPart.Position + Vector3.new(0, 5, 0)
                if hrp and hrp.Parent == currentCharacter then
                    hrp.CFrame = CFrame.lookAt(teleportPos, shipPart.Position)
                    task.wait(0.005)
                end
                threatsFound = true
                return
            end
        end
    end

    if not threatsFound then
        local currentTime = tick()
        if currentTime - lastNoThreatLogTime >= LOG_FINDING_COOLDOWN then
            log("No threats found within guard radius.")
            lastNoThreatLogTime = currentTime
        end
    end
end

local function aimAtNearestThreat()
    local currentChar, hrp = getCharacterAndHRP()
    if not hrp or not hrp.Parent then return end

    local targetPart = nil
    local closestDist = math.huge

    local bonkInterior = findCoconutBonkInterior()
    if not bonkInterior then return end
    local gameFolder = bonkInterior:FindFirstChild("Game")
    local goldPileRoot = gameFolder and gameFolder:FindFirstChild("GoldPile") and gameFolder.GoldPile:FindFirstChild("Root")
    if not (goldPileRoot and goldPileRoot:IsA("BasePart")) then return end
    local goldPos = goldPileRoot.Position

    -- Check ships
    if detectKelpRaiderShipsActive then
        local ships = findKelpRaiderShips()
        for _, shipPart in ipairs(ships) do
            if (shipPart.Position - goldPos).magnitude <= GOLD_PILE_GUARD_RADIUS then
                local distToPlayer = (shipPart.Position - hrp.Position).magnitude
                if distToPlayer < closestDist then
                    closestDist = distToPlayer
                    targetPart = shipPart
                end
            end
        end
    end

    -- Check pets
    local pets = findPetsContainer()
    if pets then
        for _, model in ipairs(pets:GetChildren()) do
            if model:IsA("Model") then
                local nameLower = model.Name:lower()
                local shouldExclude = false
                for _, keyword in ipairs(EXCLUDED_MODEL_KEYWORDS) do
                    if nameLower:find(keyword) then
                        shouldExclude = true
                        break
                    end
                end
                if not shouldExclude then
                    local raiderHRP = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
                    if raiderHRP and raiderHRP:IsA("BasePart") then
                        local distToGold = (raiderHRP.Position - goldPos).magnitude
                        if distToGold <= GOLD_PILE_GUARD_RADIUS then
                            local distToPlayer = (raiderHRP.Position - hrp.Position).magnitude
                            if distToPlayer < closestDist then
                                closestDist = distToPlayer
                                targetPart = raiderHRP
                            end
                        end
                    end
                end
            end
        end
    end

    if targetPart then
        log("Aiming at threat: " .. targetPart.Parent.Name)
        local aimStartTime = tick()
        local MAX_AIM_DURATION = 3 -- Aim for a maximum of 3 seconds per call to prevent blocking other phases too long

        while scriptEnabled and isMinigameActive() and targetPart.Parent and (tick() - aimStartTime < MAX_AIM_DURATION) do
            local success, err = pcall(function()
                hrp.CFrame = CFrame.lookAt(hrp.Position, targetPart.Position)
            end)
            if not success then warn("Failed to aim: " .. tostring(err)) break end -- Break if aiming fails

            -- Spam hotbar abilities if enabled
            if hotbarSpamActive and scoreIncreasingActionsAllowed then
                local hotbar = playerGui:FindFirstChild(FROSTCLAWS_HOTBAR_APP_NAME)
                if hotbar and hotbar:IsA("ScreenGui") then
                    local hotbarFrame = hotbar:FindFirstChild("Hotbar")
                    if hotbarFrame and hotbarFrame:IsA("Frame") then
                        local dropBtn = hotbarFrame:FindFirstChild(DROP_BUTTON_NAME)
                        local swordBtn = hotbarFrame:FindFirstChild(SWORD_BUTTON_NAME)

                        if dropBtn and dropBtn:IsA("GuiButton") and dropBtn.Visible and dropBtn.Active then
                            clickButton(dropBtn)
                            task.wait(0.05) -- Smaller wait for faster spam
                        end
                        if swordBtn and swordBtn:IsA("GuiButton") and swordBtn.Visible and swordBtn.Active then
                            clickButton(swordBtn)
                            task.wait(0.05) -- Smaller wait for faster spam
                        end
                    end
                end
            end
            task.wait(0.1) -- Small wait to yield and prevent excessive CPU usage
        end
        log("Finished aiming at threat or duration expired.")
    else
        -- No threat
        local currentTime = tick()
        if currentTime - lastNoThreatLogTime >= LOG_FINDING_COOLDOWN then
            log("No threat to aim at.")
            lastNoThreatLogTime = currentTime
        end
    end
end

local function checkScoreAndAdjustActions()
    local success, valueLabel = pcall(function()
        return playerGui:WaitForChild("MinigameInGameApp", 5)
            :WaitForChild("Body", 5)
            :WaitForChild("Right", 5)
            :WaitForChild("Container", 5)
            :WaitForChild("ValueLabel", 5)
    end)

    if not success or not valueLabel or not valueLabel:IsA("TextLabel") then
        log("❌ ValueLabel not found or not TextLabel after waiting.")
        scoreIncreasingActionsAllowed = true -- Default to allowed if score cannot be read
        return
    end
    logFinding("score_label", "Score ValueLabel", true)

    local currentScore = tonumber(valueLabel.Text)
    if not currentScore then
        log("Could not parse score: " .. tostring(valueLabel.Text))
        scoreIncreasingActionsAllowed = true -- Default to allowed if score cannot be parsed
        return
    end

    local upperThreshold = TARGET_SCORE + SCORE_UPPER_TOLERANCE
    local lowerThreshold = TARGET_SCORE - SCORE_LOWER_TOLERANCE

    if currentScore > upperThreshold and scoreIncreasingActionsAllowed then
        scoreIncreasingActionsAllowed = false
        log(string.format("Score %d > upper threshold (%d). Pausing actions.", currentScore, upperThreshold))
    elseif currentScore < lowerThreshold and not scoreIncreasingActionsAllowed then
        scoreIncreasingActionsAllowed = true
        log(string.format("Score %d < lower threshold (%d). Resuming actions.", currentScore, lowerThreshold))
    end
    log("Current Score: " .. currentScore)
end

local function teleportAndClickPile(pileNumber)
    local currentChar, hrp = getCharacterAndHRP()
    if not hrp or not hrp.Parent then return false end

    local interior = findCoconutBonkInterior()
    if not interior then log("Cannot find interior for piles"); return false end
    local gameFolder = interior:FindFirstChild("Game")
    if not gameFolder then log("Game folder missing for piles."); return false end
    local droppables = gameFolder:FindFirstChild("Droppables")
    if not droppables then
        local childrenNames = {}
        for _, child in ipairs(gameFolder:GetChildren()) do
            table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
        end
        log("Droppables folder missing. Children of Game folder: " .. table.concat(childrenNames, ", "));
        return false
    end

    -- Navigate into the 'Piles' folder
    local pilesFolder = droppables:FindFirstChild("Piles")
    if not pilesFolder then
        local childrenNames = {}
        for _, child in ipairs(droppables:GetChildren()) do
            table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
        end
        log("Piles folder missing inside Droppables. Children of Droppables: " .. table.concat(childrenNames, ", "));
        return false
    end
    logFinding("piles_folder", "Piles folder", true)

    local pile
    local pileName = tostring(pileNumber) -- Piles are named "1", "2" not "Pile1", "Pile2"
    pile = pilesFolder:FindFirstChild(pileName)

    if not pile or not pile:IsA("Model") then
        local childrenNames = {}
        for _, child in ipairs(pilesFolder:GetChildren()) do
            table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
        end
        log("Pile " .. pileNumber .. " not found. Children of Piles folder: " .. table.concat(childrenNames, ", "))
        return false
    end
    logFinding("pile" .. pileNumber, "Pile " .. pileNumber, true)

    local targetPart = pile.PrimaryPart or pile:FindFirstChild("Root") or pile:FindFirstChild("Hitbox")
    if not targetPart or not targetPart:IsA("BasePart") then
        targetPart = pile -- Fallback to the model itself if it's a BasePart
        if not targetPart or not targetPart:IsA("BasePart") then
            log("Target part not found for pile " .. pileNumber .. ". Model type: " .. pile.ClassName)
            return false
        end
    end

    local teleportPos = targetPart.Position + Vector3.new(0, 5, 0)
    if hrp and hrp.Parent then
        hrp.CFrame = CFrame.lookAt(teleportPos, targetPart.Position)
        log("Teleported to Pile " .. pileNumber)
        task.wait(0.2)
    end

    -- Click tap buttons near pile
    local hotbar = playerGui:FindFirstChild(FROSTCLAWS_HOTBAR_APP_NAME)
    if hotbar and hotbar:IsA("ScreenGui") then
        local tapBtns = {}
        for _, obj in ipairs(hotbar:GetDescendants()) do
            if obj:IsA("GuiButton") and obj.Name:lower():find("tapbutton") and obj.Visible and obj.Active then
                table.insert(tapBtns, obj)
            end
        end
        for _, btn in ipairs(tapBtns) do
            if scoreIncreasingActionsAllowed then
                clickButton(btn)
                task.wait(0.1)
            else
                log("Skipping tap button due to high score.")
            end
        end
    end
    return true
end

local function teleportToSpecificTurret(turretNumber)
    local currentChar, hrp = getCharacterAndHRP()
    if not hrp or not hrp.Parent then return false end
    local interior = findCoconutBonkInterior()
    if not interior then log("Cannot find interior for turrets"); return false end
    local visualFolder = interior:FindFirstChild("Visual")
    if not visualFolder then log("Visual folder missing for turrets."); return false end

    local children = visualFolder:GetChildren()
    local turretsContainer
    if #children >= TURRET_PARENT_CONTAINER_INDEX then
        turretsContainer = children[TURRET_PARENT_CONTAINER_INDEX]
    end
    if not turretsContainer or not (turretsContainer:IsA("Model") or turretsContainer:IsA("Folder")) then
        local childrenNames = {}
        for _, child in ipairs(visualFolder:GetChildren()) do
            table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
        end
        log("Turrets container not found at index " .. TURRET_PARENT_CONTAINER_INDEX .. ". Children of Visual folder: " .. table.concat(childrenNames, ", "))
        return false
    end
    logFinding("turrets_container", "Turrets Container", true)

    local targetPart
    if turretNumber == 1 then
        -- Turret 1 is found by name directly under turretsContainer
        targetPart = turretsContainer:FindFirstChild(TURRET_1_NAME, true)
    elseif turretNumber == 2 then
        -- Navigate into the 'Turrets' folder inside the container
        local turretsSubFolder = turretsContainer:FindFirstChild("Turrets")
        if not turretsSubFolder then
            local childrenNames = {}
            for _, child in ipairs(turretsContainer:GetChildren()) do
                table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
            end
            log("Turrets sub-folder not found inside Turrets Container. Children of Turrets Container: " .. table.concat(childrenNames, ", "));
            return false
        end
        logFinding("turrets_sub_folder", "Turrets sub-folder", true)

        if #turretsSubFolder:GetChildren() >= TURRET_2_INDEX then
            local potential = turretsSubFolder:GetChildren()[TURRET_2_INDEX]
            if potential then
                if potential:IsA("Model") then
                    targetPart = potential.PrimaryPart or potential:FindFirstChild("Hitbox") or potential:FindFirstChild("Root") or potential
                elseif potential:IsA("BasePart") then
                    targetPart = potential
                end
            end
        end
    end
    if not targetPart or not targetPart:IsA("BasePart") then
        local childrenNames = {}
        if turretsContainer then
            for _, child in ipairs(turretsContainer:GetChildren()) do
                table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
            end
        end
        log("Turret " .. turretNumber .. " not found. Children of Turrets Container (or its sub-folder): " .. table.concat(childrenNames, ", "))
        return false
    end
    local teleportPos = targetPart.Position + Vector3.new(0, 5, 0)
    if hrp and hrp.Parent then
        hrp.CFrame = CFrame.lookAt(teleportPos, targetPart.Position)
        log("Teleported to Turret " .. turretNumber)
        task.wait(0.2)
    end

    -- Click tap buttons near turret
    local hotbar = playerGui:FindFirstChild(FROSTCLAWS_HOTBAR_APP_NAME)
    if hotbar and hotbar:IsA("ScreenGui") then
        local tapBtns = {}
        for _, obj in ipairs(hotbar:GetDescendants()) do
            if obj:IsA("GuiButton") and obj.Name:lower():find("tapbutton") and obj.Visible and obj.Active then
                table.insert(tapBtns, obj)
            end
        end
        for _, btn in ipairs(tapBtns) do
            if scoreIncreasingActionsAllowed then
                clickButton(btn)
                task.wait(0.1)
            else
                log("Skipping tap button due to high score.")
            end
        end
    end
    return true
end

local function findAllTapButtons()
    local tapButtons = {}
    local hotbar = playerGui:FindFirstChild(FROSTCLAWS_HOTBAR_APP_NAME)
    if hotbar and hotbar:IsA("ScreenGui") then
        for _, obj in ipairs(hotbar:GetDescendants()) do
            if obj:IsA("GuiButton") and obj.Name:lower():find("tapbutton") and obj.Visible and obj.Active then
                table.insert(tapButtons, obj)
            end
        end
    end
    if #tapButtons > 0 then
        logFinding("tap_buttons", "Tap Buttons", true)
        for _, btn in ipairs(tapButtons) do
            if scoreIncreasingActionsAllowed then
                clickButton(btn)
                task.wait(0.1)
            else
                log("Skipping Tap Button due to high score.")
            end
        end
    else
        logFinding("tap_buttons", "Tap Buttons", false)
    end
end

local function clickStartButton()
    if hasClickedStartButton then
        log("Start button already clicked in this round.")
        return
    end
    log("Attempting to find and click Minigame Start Button...")
    local success, startBtn = pcall(function()
        return playerGui:WaitForChild("MinigameReadyApp", 2)
            :FindFirstChild("Body", true)
            :FindFirstChild("Bottom", true)
            :FindFirstChild("Action", true)
            :FindFirstChild("Button", true)
    end)
    if success and startBtn and startBtn:IsA("GuiButton") and startBtn.Visible and startBtn.Active then
        logFinding("start_button", "Minigame Start Button", true)
        clickButton(startBtn)
        hasClickedStartButton = true
        log("Clicked Minigame Start Button.")
    else
        local reason = "Unknown"
        if not success then
            reason = "pcall failed: " .. tostring(startBtn)
        elseif not startBtn then
            reason = "Button object not found."
            local minigameReadyApp = playerGui:FindFirstChild("MinigameReadyApp")
            if minigameReadyApp then
                local body = minigameReadyApp:FindFirstChild("Body", true)
                if body then
                    local bottom = body:FindFirstChild("Bottom", true)
                    if bottom then
                        local action = bottom:FindFirstChild("Action", true)
                        if action then
                            local childrenNames = {}
                            for _, child in ipairs(action:GetChildren()) do
                                table.insert(childrenNames, child.Name .. " (" .. child.ClassName .. ")")
                            end
                            log("Children of MinigameReadyApp.Body.Bottom.Action: " .. table.concat(childrenNames, ", "))
                        else
                            log("MinigameReadyApp.Body.Bottom.Action not found.")
                        end
                    else
                        log("MinigameReadyApp.Body.Bottom not found.")
                    end
                else
                    log("MinigameReadyApp.Body not found.")
                end
            else
                log("MinigameReadyApp not found.")
            end
        elseif not startBtn.Visible then
            reason = "Button not visible."
        elseif not startBtn.Active then
            reason = "Button not active."
        end
        logFinding("start_button", "Minigame Start Button", false, {Reason = reason})
    end
end


local function destroyChoiceSelects()
    local choiceGui = playerGui:FindFirstChild("ChoiceSelectApp")
    if choiceGui and choiceGui:IsA("ScreenGui") and choiceGui.Enabled then
        log("ChoiceSelectApp found, destroying.")
        choiceGui:Destroy()
    end
end

local function antiAFKMovement()
    local currentChar, hrp = getCharacterAndHRP()
    if not hrp or not hrp.Parent then return end
    if RunService:IsStudio() then return end
    hrp.CFrame = hrp.CFrame * CFrame.new(0.1, 0, 0.1)
    task.wait(0.1)
    hrp.CFrame = hrp.CFrame * CFrame.new(-0.1, 0, -0.1)
    log("Anti-AFK movement performed.")
end

-- Gets the teleport ring instance for initial teleport
local function getTeleportRingInstance()
    local ring
    local attempts = 0
    local MAX_RING_ATTEMPTS = 60 -- Max attempts (30 seconds)
    log("Starting search for Teleport Ring...")
    repeat
        local interiors = workspace:FindFirstChild("Interiors")
        local summerfest = interiors and interiors:FindFirstChild("MainMap!Summerfest")
        local joinZone = summerfest and summerfest:FindFirstChild("CoconutBonkJoinZone")
        if joinZone and typeof(joinZone) == "Instance" and type(joinZone.FindFirstChild) == "function" then
            local success, result = pcall(function() return joinZone:FindFirstChild("Ring") end)
            if success then
                ring = result
                if ring then
                    log("Found Teleport Ring at attempt: " .. attempts)
                    break
                end
            else
                log("Error during getTeleportRingInstance: " .. tostring(result))
            end
        else
            logFinding("join_zone", "CoconutBonkJoinZone", false)
        end
        task.wait(0.5)
        attempts = attempts + 1
    until ring or attempts >= MAX_RING_ATTEMPTS
    if not ring then
        warn("Failed to find Teleport Ring after maximum attempts.")
    end
    return ring
end

-- Performs an initial teleport to the game's entry point
local function initialTeleport()
    local currentCharacter, hrp = getCharacterAndHRP()
    local ring = getTeleportRingInstance()
    if ring and hrp and hrp.Parent == currentCharacter then
        local success, err = pcall(function()
            hrp.CFrame = ring.CFrame + Vector3.new(0, 5, 0) -- Teleport slightly above the ring
        end)
        if not success then
            warn("Initial teleport failed: " .. tostring(err))
        else
            log("Initial teleport successful.")
            task.wait(0.5)
        end
    else
        warn("No valid ring or HRP for initial teleport. Skipping.")
    end
end

-- Explicit "finding minigame" logic as requested (for the main minigame)
local isFindingMinigame = false
local function startFindingMinigame()
    if isFindingMinigame then return end
    isFindingMinigame = true
    log("Starting to print 'finding minigame...' repeatedly.")
    findingMinigameCoroutine = coroutine.wrap(function()
        while isFindingMinigame do
            log("finding minigame...")
            task.wait(0.5)
        end
        log("'finding minigame...' printing stopped.")
    end)
    task.spawn(findingMinigameCoroutine)
end

local function stopFindingMinigame()
    if isFindingMinigame then
        isFindingMinigame = false
        if findingMinigameCoroutine then
            -- No explicit way to cancel a running coroutine, but the loop condition handles it.
            findingMinigameCoroutine = nil
        end
        log("Stopped printing 'finding minigame...'.")
    end
end

-- Function to handle auto click hotbar logic
local function handleAutoClickHotbar()
    if autoClickHotbarActive then
        log("Executing Auto Click Hotbar script...")
        local success, err = pcall(function()
            loadstring(game:HttpGet(('https://raw.githubusercontent.com/UnclesVan/ValentinesDay-2025/refs/heads/main/SUMMERFEST2025AUTOCLICKER')))()
        end)
        if not success then
            log("Error executing Auto Click Hotbar script: " .. tostring(err))
        else
            log("Auto Click Hotbar script executed. Note: This script, once loaded, may run independently.")
        end
        -- Since loadstring typically runs once to inject a script, we immediately turn off the toggle
        -- to prevent re-execution on every loop iteration. The external script manages its own state.
        autoClickHotbarActive = false
        -- Update the Fluent UI button to reflect this
        if autoClickHotbarFluentBtn then -- Make sure the button reference exists
            autoClickHotbarFluentBtn:SetTitle("Auto Click Hotbar: OFF")
            autoClickHotbarFluentBtn:SetValue(false) -- Set Fluent Toggle value to false
        end
    end
end

-- New/Modified function to handle rewards auto-clicking, including ChoiceSelects and TapButtons
local function handleRewardsAutoClick()
    if not rewardsAutoClickActive then
        log("handleRewardsAutoClick: Toggle is OFF.")
        return
    end

    log("handleRewardsAutoClick: Toggle is ON. Executing logic.")

    -- Logic for destroying ChoiceSelects frame
    local interactionsApp = playerGui:FindFirstChild("InteractionsApp", true)
    if interactionsApp then
        log("handleRewardsAutoClick: Found InteractionsApp.")
        local choiceSelectsFrame = interactionsApp:FindFirstChild("ChoiceSelects", true)
        if choiceSelectsFrame and choiceSelectsFrame.Parent then
            log("handleRewardsAutoClick: Found ChoiceSelects frame. Destroying.")
            local success, err = pcall(function() choiceSelectsFrame:Destroy() end)
            if not success then
                warn("handleRewardsAutoClick: Error destroying ChoiceSelects frame: " .. tostring(err))
            end
        else
            log("handleRewardsAutoClick: ChoiceSelects frame not found or already destroyed.")
        end
    else
        log("handleRewardsAutoClick: InteractionsApp not found.")
    end


    -- Logic for finding and clicking all TapButtons
    local tapButtons = {}
    for _, obj in ipairs(playerGui:GetDescendants()) do
        -- Ensure it's a GuiObject and named "TapButton", visible, and active
        if obj:IsA("GuiObject") and obj.Name == "TapButton" and obj.Visible and obj.Active then
            table.insert(tapButtons, obj)
        end
    end

    if #tapButtons > 0 then
        log("handleRewardsAutoClick: Found " .. #tapButtons .. " TapButton(s). Clicking them.")
        for _, btn in ipairs(tapButtons) do
            if btn and btn.Parent then -- Double check parent exists before clicking
                clickButton(btn) -- Using the existing clickButton function for consistency
                task.wait(0.1) -- Small wait between clicks
            end
        end
    else
        log("handleRewardsAutoClick: No active TapButton(s) found.")
    end

    -- Original rewards button logic (if needed, otherwise remove this block)
    -- This part is commented out as per previous instructions to repurpose the toggle
    -- local rewardsBtn = playerGui:FindFirstChild(REWARDS_BUTTON_PATH, true)
    -- if rewardsBtn and rewardsBtn:IsA("GuiButton") and rewardsBtn.Visible and rewardsBtn.Active then
    --     log("Rewards button found! Clicking.")
    --     clickButton(rewardsBtn)
    --     task.wait(0.5)
    -- end
end

-- NEW: Placeholder function for Cannon Circle automation logic
local function handleCannonCircle()
    if not cannonCircleActive then
        log("handleCannonCircle: Toggle is OFF.")
        return
    end
    log("handleCannonCircle: Toggle is ON. (Implement Cannon Circle logic here)")
    -- Example: Find and click a "CannonReadyButton" or similar
    -- local cannonReadyButton = playerGui:FindFirstChild("CannonCircleApp.ReadyButton", true)
    -- if cannonReadyButton and cannonReadyButton:IsA("GuiButton") and cannonReadyButton.Visible and cannonReadyButton.Active then
    --     clickButton(cannonReadyButton)
    --     log("Clicked Cannon Ready Button.")
    -- end
    -- Add your specific Cannon Circle automation logic here
end


-- --- Fluent UI Elements ---
do
    local TreasureDefenceTab = Tabs.TreasureDefence
    local CannonCircleTab = Tabs.CannonCircle -- Reference the Cannon Circle tab

    -- Script Controls Section (Treasure Defence Tab)
    local scriptControlsSection = TreasureDefenceTab:AddSection("Script Controls")
    scriptToggleFluentBtn = scriptControlsSection:AddToggle("AutoScriptToggle", {
        Title = "Script: OFF",
        Description = "Enable or disable the main script functionality.",
        Default = false,
    })

    scriptToggleFluentBtn:OnChanged(function(state)
        scriptEnabled = state
        scriptToggleFluentBtn:SetTitle("Script: " .. (state and "ON" or "OFF"))
        
        log("Script toggled: " .. tostring(scriptEnabled))

        if scriptEnabled then
            -- Actions to take when script is enabled
            local currentCharacter, hrp = getCharacterAndHRP()
            local ring = getTeleportRingInstance()
            if ring and hrp and hrp.Parent == currentCharacter then
                local success, err = pcall(function()
                    hrp.CFrame = ring.CFrame + Vector3.new(0, 5, 0)
                end)
                if not success then
                    warn("Teleport on toggle failed: " .. tostring(err))
                else
                    log("Teleported to minigame entry on script enable.")
                    task.wait(0.5)
                end
            else
                warn("Could not teleport: ring or HRP missing for initial teleport on toggle ON.")
            end
        else
            -- Actions to take when script is disabled
            scoreIncreasingActionsAllowed = true -- Reset score control on disable
            stopFindingMinigame() -- Stop the "finding minigame" loop
            log("All main script features deactivated.")
        end
    end)
    -- Ensure initial state is reflected
    scriptToggleFluentBtn:SetTitle("Script: " .. (scriptEnabled and "ON" or "OFF"))
    scriptToggleFluentBtn:SetValue(scriptEnabled)


    -- Feature Toggles Section (Treasure Defence Tab)
    local featureTogglesSection = TreasureDefenceTab:AddSection("Feature Toggles")

    hotbarSpamFluentBtn = featureTogglesSection:AddToggle("HotbarSpamToggle", {
        Title = "Hotbar Spam: ON",
        Description = "Enables or disables spamming of hotbar abilities (Drop/Sword).",
        Default = hotbarSpamActive,
    })
    hotbarSpamFluentBtn:OnChanged(function(state)
        hotbarSpamActive = state
        hotbarSpamFluentBtn:SetTitle("Hotbar Spam: " .. (state and "ON" or "OFF"))
        log("Hotbar Spam: " .. (state and "ON" or "OFF"))
    end)
    hotbarSpamFluentBtn:SetTitle("Hotbar Spam: " .. (hotbarSpamActive and "ON" or "OFF"))
    hotbarSpamFluentBtn:SetValue(hotbarSpamActive)


    teleportToRaidersFluentBtn = featureTogglesSection:AddToggle("TeleportToRaidersToggle", {
        Title = "Teleport to Raiders: ON",
        Description = "Enables or disables teleportation to nearby raiders.",
        Default = teleportToRaidersActive,
    })
    teleportToRaidersFluentBtn:OnChanged(function(state)
        teleportToRaidersActive = state
        teleportToRaidersFluentBtn:SetTitle("Teleport to Raiders: " .. (state and "ON" or "OFF"))
        log("Teleport to Raiders: " .. (state and "ON" or "OFF"))
    end)
    teleportToRaidersFluentBtn:SetTitle("Teleport to Raiders: " .. (teleportToRaidersActive and "ON" or "OFF"))
    teleportToRaidersFluentBtn:SetValue(teleportToRaidersActive)


    rewardsAutoClickFluentBtn = featureTogglesSection:AddToggle("RewardsAutoClickToggle", {
        Title = "Auto Click Rewards: OFF",
        Description = "Automatically handles reward choices and clicks TapButtons.",
        Default = rewardsAutoClickActive,
    })
    rewardsAutoClickFluentBtn:OnChanged(function(state)
        rewardsAutoClickActive = state
        rewardsAutoClickFluentBtn:SetTitle("Auto Click Rewards: " .. (state and "ON" or "OFF"))
        log("Auto Click Rewards: " .. (state and "ON" or "OFF"))
    end)
    rewardsAutoClickFluentBtn:SetTitle("Auto Click Rewards: " .. (rewardsAutoClickActive and "ON" or "OFF"))
    rewardsAutoClickFluentBtn:SetValue(rewardsAutoClickActive)


    autoClickHotbarFluentBtn = featureTogglesSection:AddToggle("AutoClickHotbarToggle", {
        Title = "Auto Click Hotbar: OFF",
        Description = "Loads and enables an external auto-clicker for hotbar items.",
        Default = autoClickHotbarActive,
    })
    autoClickHotbarFluentBtn:OnChanged(function(state)
        local prevState = autoClickHotbarActive
        autoClickHotbarActive = state
        autoClickHotbarFluentBtn:SetTitle("Auto Click Hotbar: " .. (state and "ON" or "OFF"))
        if autoClickHotbarActive then
            log("Auto Click Hotbar: ON (Executing script...)")
            handleAutoClickHotbar() -- This function now knows about autoClickHotbarFluentBtn
        else
            log("Auto Click Hotbar: OFF (Note: External script may continue to run if already loaded.)")
        end
    end)
    autoClickHotbarFluentBtn:SetTitle("Auto Click Hotbar: " .. (autoClickHotbarActive and "ON" or "OFF"))
    autoClickHotbarFluentBtn:SetValue(autoClickHotbarActive)


    detectKelpRaiderShipsFluentBtn = featureTogglesSection:AddToggle("DetectKelpRaiderShipsToggle", {
        Title = "Detect Kelp Raiders: ON",
        Description = "Enables detection and targeting of Kelp Raider Ships.",
        Default = detectKelpRaiderShipsActive,
    })
    detectKelpRaiderShipsFluentBtn:OnChanged(function(state)
        detectKelpRaiderShipsActive = state
        detectKelpRaiderShipsFluentBtn:SetTitle("Detect Kelp Raiders: " .. (state and "ON" or "OFF"))
        log("Detect Kelp Raiders: " .. (state and "ON" or "OFF"))
    end)
    detectKelpRaiderShipsFluentBtn:SetTitle("Detect Kelp Raiders: " .. (detectKelpRaiderShipsActive and "ON" or "OFF"))
    detectKelpRaiderShipsFluentBtn:SetValue(detectKelpRaiderShipsActive)


    -- NEW: Cannon Circle Controls Section
    local cannonCircleControlsSection = CannonCircleTab:AddSection("Game Controls")
    cannonCircleFluentBtn = cannonCircleControlsSection:AddToggle("CannonCircleToggle", {
        Title = "Cannon Circle: OFF",
        Description = "Enables or disables automation for the Cannon Circle minigame.",
        Default = cannonCircleActive,
    })
    cannonCircleFluentBtn:OnChanged(function(state)
        cannonCircleActive = state
        cannonCircleFluentBtn:SetTitle("Cannon Circle: " .. (state and "ON" or "OFF"))
        log("Cannon Circle Automation: " .. (state and "ON" or "OFF"))
    end)
    cannonCircleFluentBtn:SetTitle("Cannon Circle: " .. (cannonCircleActive and "ON" or "OFF"))
    cannonCircleFluentBtn:SetValue(cannonCircleActive)


    -- Console Log Section
    local consoleLogSection = TreasureDefenceTab:AddSection("Console Log")
    -- The initial content can be set here. The 'log' function will append to it via 'internalLogLines'
    consoleOutputElement = consoleLogSection:AddParagraph({
        Title = "LogOutput", -- The title for the paragraph element
        Content = "Console Log:\nScript Version: 2025-07-07_ConsolidatedUIAndLogic_v70" -- Initial content
    })
    -- Debug print for consoleOutputElement itself
    print("Type of consoleOutputElement after creation: " .. typeof(consoleOutputElement))
    print("Type of consoleOutputElement.SetContent: " .. typeof(consoleOutputElement and consoleOutputElement.SetContent))

    -- Initialize internalLogLines with the initial content
    internalLogLines = string.split("Console Log:\nScript Version: 2025-07-07_ConsolidatedUIAndLogic_v70", "\n")


    -- Changelog Section
    local changelogSection = TreasureDefenceTab:AddSection("Changelog")
    local changelogContent = [[
Changelog:
v70 (2025-07-07):
- Fixed AdoptMe/Sumar toggle disappearing by making it a separate ScreenGui.
- AdoptMe/Sumar UI toggle now correctly controls the Enabled property of the MainConsole UI.

v69 (2025-07-07):
- AdoptMe/Sumar UI toggle now controls the Enabled property of the MainConsole UI itself.

v68 (2025-07-07):
- Integrated AdoptMe/Sumar UI toggle functionality. Clicking the circular button now hides/shows the main game UIs.

v65 (2025-07-07):
- Added placeholder entries for future updates (Boat Teleportation, Summer Fest Week 2).

v64 (2025-07-07):
- Adjusted console UI size to be slightly smaller as requested.

v63 (2025-07-07):
- Added dedicated Changelog section to the UI.
- Restructured console UI to support side-by-side log and changelog.

v62 (2025-07-07):
- Removed "Auto Close Rewards" feature as requested.
- Wrapped all `log()` and `logFinding()` calls with `pcall` for error robustness.

v61 (2025-07-07):
- Temporarily disabled external "Auto Click Hotbar" script (`loadstring`) for debugging "attempt to call a string value" error.
- Added `pcall` wrappers around ALL `log()` and `logFinding()` calls to prevent script crashes if these functions are corrupted.

v60 (2025-07-07):
- Integrated "Rewards Button" auto-clicking functionality with a dedicated toggle button in the UI.
- Added diagnostic print statements to check the type of `log` and `logFinding` functions at runtime.

v59 (2025-07-07):
- Fixed "attempt to call a string value" error by ensuring `logFinding` is globally accessible.
- Corrected typo in `UserInputService.InputEnded` for draggable UI.

v58 (2025-07-07):
- Implemented "Auto Close Reward" toggle button and logic.
- Implemented "Auto Click Hotbar" toggle button and logic (loads external script).

v57 (2025-07-07):
- Consolidated all UI elements into a single draggable console window.
- Added main script ON/OFF toggle.
- Added "Boat Teleportation (Coming soon)" button.
- Improved console log display with scrolling and line limits.
- Enhanced anti-AFK movement with random rotations and shifts.
- Refined `getCharacterAndHRP` for better robustness.

v56 (2025-07-07):
- Fixed draggable UI getting stuck after release (removed `input.Handled = true`).
- Initial implementation of consolidated UI framework.
    ]]
    changelogSection:AddParagraph({
        Title = "Changelog",
        Content = changelogContent
    })
end


-- Initial character and HRP retrieval using the robust function
character, humanoidRootPart = getCharacterAndHRP()

-- --- INITIALIZATION ---
task.wait(0.1) -- Small wait to ensure UI elements are fully rendered and accessible
initialTeleport() -- Perform initial teleport regardless of scriptEnabled state

-- --- MAIN LOOP ---
spawn(function() -- Use spawn to run this in a separate thread
    local gameAutomationCoroutine = nil
    while true do
        -- Only call handleRewardsAutoClick and destroyChoiceSelects if minigame is active
        if isMinigameActive() then
            handleRewardsAutoClick() -- This now includes ChoiceSelects and TapButton logic
            destroyChoiceSelects() -- This function is still useful for general ChoiceSelectApp destruction
        else
            log("Not in minigame. Skipping rewards auto-click and choice destruction.")
        end

        -- NEW: Call handleCannonCircle if the toggle is active
        if cannonCircleActive then
            handleCannonCircle()
        end

        if scriptEnabled then
            -- This block runs only when the main script is enabled
            if isMinigameActive() then
                -- Found interior
                stopFindingMinigame() -- Stop the explicit "finding minigame" message

                if not gameAutomationCoroutine then
                    gameAutomationCoroutine = task.spawn(function()
                        local phases = {TELEPORT_PHASE_PILES, TELEPORT_PHASE_TURRETS, TELEPORT_PHASE_RAIDERS_SHIPS}
                        local phaseIdx = 1
                        while scriptEnabled and isMinigameActive() do
                            local phase = phases[phaseIdx]
                            log("Executing phase: " .. phase)
                            local ok, err = pcall(checkScoreAndAdjustActions)
                            if not ok then warn("Error in checkScoreAndAdjustActions: " .. tostring(err)) end

                            if scoreIncreasingActionsAllowed then
                                local ok_hotbar, err_hotbar = pcall(handleHotbarAbilities)
                                if not ok_hotbar then warn("Error in handleHotbarAbilities: " .. tostring(err_hotbar)) end
                            end

                            if phase == TELEPORT_PHASE_PILES then
                                local s1_ok, s1_err = pcall(teleportAndClickPile, 1)
                                if not s1_ok then warn("Error teleporting to pile 1: " .. tostring(s1_err)) end
                                if s1_ok then task.wait(0.5) end
                                local s2_ok, s2_err = pcall(teleportAndClickPile, 2)
                                if not s2_ok then warn("Error teleporting to pile 2: " .. tostring(s2_err)) end
                                if s2_ok then task.wait(0.5) end
                            elseif phase == TELEPORT_PHASE_TURRETS then
                                local t1_ok, t1_err = pcall(teleportToSpecificTurret, 1)
                                if not t1_ok then warn("Error teleporting to turret 1: " .. tostring(t1_err)) end
                                if t1_ok then task.wait(0.5) end
                                local t2_ok, t2_err = pcall(teleportToSpecificTurret, 2)
                                if not t2_ok then warn("Error teleporting to turret 2: " .. tostring(t2_err)) end
                                if t2_ok then task.wait(0.5) end
                            elseif phase == TELEPORT_PHASE_RAIDERS_SHIPS then
                                local htm_ok, htm_err = pcall(handleTeleportToModels)
                                if not htm_ok then warn("Error in handleTeleportToModels: " .. tostring(htm_err)) end
                                task.wait(0.05) -- Reduced wait for faster execution
                                local aat_ok, aat_err = pcall(aimAtNearestThreat)
                                if not aat_ok then warn("Error in aimAtNearestThreat: " .. tostring(aat_err)) end
                                task.wait(0.05) -- Reduced wait
                                if scoreIncreasingActionsAllowed then
                                    local fatb_ok, fatb_err = pcall(findAllTapButtons)
                                    if not fatb_ok then warn("Error in findAllTapButtons: " .. tostring(fatb_err)) end
                                end
                                task.wait(0.05) -- Reduced wait
                            end

                            local afk_ok, afk_err = pcall(antiAFKMovement)
                            if not afk_ok then warn("Error in antiAFKMovement: " .. tostring(afk_err)) end
                            task.wait(0.1)

                            phaseIdx = phaseIdx + 1
                            if phaseIdx > #phases then phaseIdx = 1 end
                            log("Phase '" .. phase .. "' completed. Waiting " .. TELEPORT_PHASE_INTERVAL .. "s.")
                            task.wait(TELEPORT_PHASE_INTERVAL)
                        end
                        log("Game automation coroutine stopped.")
                        gameAutomationCoroutine = nil -- Reset coroutine reference when it stops
                    end)
                end
            else
                -- Minigame not active, attempt to click start button
                log("Minigame not active. Attempting to click start button.")
                local success_start_btn, err_start_btn = pcall(clickStartButton)
                if not success_start_btn then warn("Error clicking start button: " .. tostring(err_start_btn)) end

                if gameAutomationCoroutine then
                    task.cancel(gameAutomationCoroutine)
                    gameAutomationCoroutine = nil
                end
                hasClickedStartButton = false
                startFindingMinigame() -- Start printing "finding minigame..."
                task.wait(1)
            end
        else
            -- Script is disabled
            if gameAutomationCoroutine then
                task.cancel(gameAutomationCoroutine)
                gameAutomationCoroutine = nil
            end
            stopFindingMinigame() -- Ensure "finding minigame" message is stopped
            task.wait(1) -- Yield when script is disabled
        end
        task.wait(0.1) -- Small yield for the main heartbeat loop
    end
end)
