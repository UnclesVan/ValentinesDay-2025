-- --- LOADSTRING INTEGRATION START ---
-- WARNING: loadstring(game:HttpGet(...)) is highly restricted in Roblox and will likely NOT work
-- in a standard LocalScript environment for legitimate game development due to security measures.
-- This functionality is typically only available in specific exploit contexts.
loadstring(game:HttpGet(('https://raw.githubusercontent.com/UnclesVan/AdoPtMe-/refs/heads/main/dehashwithslashinmiddle')))()

print("----------------------------------------------------------------------")
warn("Remotes has been Dehashed from the RouterClientModule! continuing to load script")
print("----------------------------------------------------------------------")
-- --- LOADSTRING INTEGRATION END ---


-- This is a LocalScript (put in StarterPlayerScripts or similar)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace") -- Added for lure script
local TweenService = game:GetService("TweenService") -- For smooth fading of text (used in continuous teleport part)

local InteriorsM = nil
local success, errorMessage = pcall(function()
    InteriorsM = require(ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM)
end)

if not success then
    warn("Failed to require InteriorsM:", errorMessage)
    warn("Make sure the path 'ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM' is correct.")
    return
end

print("InteriorsM module loaded successfully.")

-- Function to safely get a descendant using a dot-separated path.
-- Returns nil if any part of the path is not found.
local function getDescendantFromPath(parent: Instance, path: string): Instance?
    local currentInstance: Instance? = parent
    for _, partName in ipairs(path:split(".")) do
        if currentInstance then
            currentInstance = currentInstance:FindFirstChild(partName)
        else
            return nil
        end
    end
    return currentInstance
end

-- Function to simulate click events on a UI button.
-- This function uses getconnections and Fire() as per user's request.
-- WARNING: This method might not work in all Roblox environments due to security restrictions.
-- The recommended way to click a GuiButton is button:Click().
local function clickButton(button: GuiButton?)
    if button then
        print("Button found! Attempting to click:", button.Name)

        -- Fire MouseButton1Down connections
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do
            connection:Fire()
        end
        task.wait(0.1) -- Small delay to simulate real-world interaction timing

        -- Fire MouseButton1Click connections
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
        end
        task.wait(0.1) -- Small delay

        -- Fire MouseButton1Up connections
        for _, connection in pairs(getconnections(button.MouseButton1Up)) do
            connection:Fire()
        end
        print("Successfully clicked the button!")
    else
        print("Button not found!")
    end
end

-- Helper function to safely find a UI element by its path.
-- It uses WaitForChild for robustness, waiting for each part of the path.
local function findUIElement(playerGui: PlayerGui, path: string, timeout: number): Instance?
    local currentParent: Instance? = playerGui
    local pathParts = path:split(".")
    local foundElement: Instance? = nil

    for i, partName in ipairs(pathParts) do
        -- Skip "PlayerGui" as we already started from the playerGui object.
        if partName == "PlayerGui" then continue end

        -- Print current parent for debugging
        print("Attempting to find '" .. partName .. "' as child of '" .. (currentParent and currentParent.Name or "nil") .. "' (Path part " .. i .. "/" .. #pathParts .. ")")

        -- Special debug for ScrollingFrame to check its children
        if partName == "ScrollingFrame" and currentParent then
            local scrollingFrame = currentParent:WaitForChild(partName, timeout)
            if scrollingFrame then
                print("Children of " .. currentParent.Name .. "." .. partName .. ":")
                for _, child in ipairs(scrollingFrame:GetChildren()) do
                    print(" - " .. child.Name .. " (" .. child.ClassName .. ")")
                end
            end
        end

        -- Wait for each child to ensure it exists before trying to access its children.
        local child = currentParent:WaitForChild(partName, timeout)
        if child then
            currentParent = child
        else
            print("Could not find part of the path: '" .. partName .. "' in parent '" .. (currentParent and currentParent.Name or "nil") .. "'")
            return nil -- Return nil if any part of the path is not found within the timeout
        end

        -- If we are at the last part of the path, this is our target element.
        if i == #pathParts then
            foundElement = currentParent
        end
    end
    return foundElement
end


-- --- START OF PLAY BUTTON CLICK ---
local newsAppButtonPath = "PlayerGui.NewsApp.EnclosingFrame.MainFrame.Buttons.PlayButton"

LocalPlayer.PlayerGui:WaitForChild("NewsApp", 20) -- Wait for NewsApp to load

local targetNewsAppButton = findUIElement(LocalPlayer.PlayerGui, newsAppButtonPath, 15) -- Use findUIElement
clickButton(targetNewsAppButton)
task.wait(5) -- Added delay to allow HRP and other assets to load after clicking play
-- --- END OF PLAY BUTTON CLICK ---


-- --- PET UNEQUIP SCRIPT INTEGRATION START ---
local ClientDataModule_Pets = nil
local success_pets, errorMessage_pets = pcall(function()
    ClientDataModule_Pets = require(ReplicatedStorage.ClientModules.Core.ClientData)
end)

if not success_pets then
    warn("Failed to load ClientData module for pets:", errorMessage_pets)
    -- Continue script execution, as this block is not critical for the main teleport logic
else
    local function waitForData_Pets()
        local data = ClientDataModule_Pets.get_data()
        while not data do
            task.wait(0.5)
            data = ClientDataModule_Pets.get_data()
        end
        return data
    end

    local targetPlayerName = LocalPlayer.Name

    local serverData_Pets = waitForData_Pets()
    local playerData_Pets = serverData_Pets[targetPlayerName]

    local allPetUniqueIds = {}

    if playerData_Pets and playerData_Pets.inventory and playerData_Pets.inventory.pets then
        local playerPets = playerData_Pets.inventory.pets
        
        print("--- Scanning Owned Pets for " .. targetPlayerName .. " ---")
        
        if next(playerPets) then
            for uniqueId, petData in pairs(playerPets) do
                local speciesId = petData.id
                print("---------------------------")
                print("Unique ID: " .. uniqueId)
                print("Species ID: " .. speciesId)
                table.insert(allPetUniqueIds, uniqueId)
            end
        else
            print("No pets found in your inventory.")
        end
    else
        print("Required data tables not found or player data for " .. targetPlayerName .. " is unavailable for pets.")
    end

    local ToolAPI_Unequip = ReplicatedStorage:WaitForChild("API"):WaitForChild("ToolAPI/Unequip")
    if not ToolAPI_Unequip then
        warn("ToolAPI/Unequip RemoteFunction not found! Cannot unequip pets.")
    else
        -- Loop through each pet ID and call the API with the specific layout
        for _, uniqueId in ipairs(allPetUniqueIds) do
            local args = {
                uniqueId,
                {
                    use_sound_delay = false,
                    equip_as_last = false
                }
            }
            print("Unequipping pet ID:", uniqueId)
            local success_unequip, result_unequip = pcall(function()
                return ToolAPI_Unequip:InvokeServer(unpack(args))
            end)
            if success_unequip then
                print("Successfully unequipped pet ID: " .. uniqueId)
            else
                warn("Failed to unequip pet ID: " .. uniqueId .. " - " .. tostring(result_unequip))
            end
            task.wait(0.1) -- Small delay between unequip calls
        end
        print("Finished unequipping pets.")
    end
end
-- --- PET UNEQUIP SCRIPT INTEGRATION END ---


-- --- DAILY REWARD CLAIM LOOP START ---
print("Starting daily reward claim loop...")
task.spawn(function() -- Use task.spawn to run this loop concurrently
    local DailyLoginAPI_ClaimDailyReward = ReplicatedStorage:WaitForChild("API"):WaitForChild("DailyLoginAPI/ClaimDailyReward")
    if not DailyLoginAPI_ClaimDailyReward then
        warn("DailyLoginAPI/ClaimDailyReward RemoteFunction not found! Cannot claim daily rewards.")
        return
    end

    while true do
        local success_claim, result_claim = pcall(function()
            return DailyLoginAPI_ClaimDailyReward:InvokeServer()
        end)

        if success_claim then
            print("Attempted to claim daily reward. Result: " .. tostring(result_claim))
        else
            warn("Failed to claim daily reward: " .. tostring(result_claim))
        end
        task.wait(60) -- Wait 60 seconds (1 minute) before attempting to claim again
    end
end)
print("Daily reward claim loop initiated in a separate thread.")
-- --- DAILY REWARD CLAIM LOOP END ---


-- --- LURE PLACEMENT SCRIPT INTEGRATION START ---

-- Load the ClientData module safely (re-using the function for clarity, though it's the same module)
local function loadClientDataModule()
    local success, module = pcall(function()
        return require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
    end)
    if not success then
        warn("Failed to load ClientData module for lures.")
        return nil
    end
    return module
end

local ClientData = loadClientDataModule()
if not ClientData then
    warn("ClientData module not available, cannot place lures.")
    -- Continue script execution, as teleportation might still be desired
else
    local function waitForData()
        local data = ClientData.get_data()
        while not data do
            task.wait(0.5)
            data = ClientData.get_data()
        end
        return data
    end

    local serverData = waitForData()

    -- Get local player's name dynamically
    local playerName = game.Players.LocalPlayer and game.Players.LocalPlayer.Name
    if not playerName then
        warn("Could not get local player name, cannot place lures.")
        -- Continue script execution
    else
        local playerData = serverData[playerName]

        if not playerData or not playerData.inventory or not playerData.inventory.food then
            warn("No inventory data for player: " .. playerName .. ", cannot place lures.")
            -- Continue script execution
        else
            -- Find the bait's unique ID
            local baitId = nil
            for uniqueId, foodData in pairs(playerData.inventory.food) do
                if foodData.id == "ice_dimension_2025_ice_soup_bait" then
                    baitId = uniqueId
                    break
                end
            end

            if not baitId then
                warn("Ice Soup Bait not found in inventory, cannot place lures.")
                -- Continue script execution
            else
                -- Find your furniture folder
                local furnitureFolder = Workspace:FindFirstChild("HouseInteriors")
                    and Workspace.HouseInteriors:FindFirstChild("furniture")
                if not furnitureFolder then
                    warn("Furniture folder not found, cannot place lures.")
                    -- Continue script execution
                else
                    print("Attempting to place lures 2 times...")
                    -- Loop twice to place lures two times
                    for activationAttempt = 1, 2 do
                        print(string.format("Lure placement attempt %d/2...", activationAttempt))
                        -- Loop through models to find and activate lures
                        for _, model in pairs(furnitureFolder:GetChildren()) do
                            if typeof(model) == "Instance" and model.Name:find("^" .. playerName .. "/1/nil/true/f%-") then
                                local fNumber = model.Name:match("f%-(%d+)$")
                                if fNumber then
                                    local lure = model:FindFirstChild("Lures2023NormalLure")
                                    if lure then
                                        print("Found lure in model:", model.Name, "f- number:", fNumber)
                                        -- Prepare arguments for activation
                                        local args = {
                                            game:GetService("Players"):WaitForChild(playerName),
                                            "f-" .. fNumber,
                                            "UseBlock",
                                            { bait_unique = baitId },
                                            game.Players.LocalPlayer.Character
                                        }
                                        -- Activate the bait
                                        local success, err = pcall(function()
                                            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateFurniture"):InvokeServer(unpack(args))
                                        end)

                                        if success then
                                            -- Print simplified message
                                            print(string.format("%s has put Ice Soup Bait (%s) into F-%s Lure", playerName, baitId, fNumber))
                                        else
                                            warn("Failed to activate furniture for model:", model.Name, err)
                                        end
                                    else
                                        print("Lure not found in model:", model.Name)
                                    end
                                end
                            end
                        end
                        task.wait(1) -- Small wait between activation attempts
                    end
                    print("Finished lure placement attempts.")
                end
            end
        end
    end
end
-- --- LURE PLACEMENT SCRIPT INTEGRATION END ---


print("Initiating automatic teleport to MainMap.")

local targetDestinationId = "MainMap" -- Changed destination to "MainMap"

-- This was the key for Location.__init to stop complaining about a nil door ID.
-- It serves as the 'destination_door_id' argument in Location.__init's
-- internal interpretation of arguments (where it incorrectly used house_owner for it).
local targetHouseOwner = LocalPlayer.Name

local teleportSettings = {
    fade_in_length = 0.5,
    fade_out_length = 0.4,
    fade_color = Color3.new(0, 0, 0),

    player_about_to_teleport = function() print("Player is about to teleport...") end,
    teleport_completed_callback = function() print("Teleport completed callback.") end,
    player_to_teleport_to = nil,

    anchor_char_immediately = true,
    post_character_anchored_wait = 0.5,

    -- Updated CFrame provided by the user
    spawn_cframe = CFrame.new(-275.9091491699219, 25.812084197998047, -1548.145751953125, -0.9798217415809631, 0.0000227206928684609, 0.19986890256404877, -0.000003862579433189239, 1, -0.00013261348067317158, -0.19986890256404877, -0.00013070966815575957, -0.9798217415317158),
    
    move_camera = true,

    -- These properties in settings didn't cause errors after the house_owner fix,
    -- but they are part of the settings table that enter_smooth expects.
    door_id_for_location_module = nil,
    exiting_door = nil,
}


-- The teleport happens automatically after the script loads.
print("Attempting to trigger automatic door teleport to:", targetDestinationId)
print("Using house owner (now LocalPlayer.Name):", targetHouseOwner)
print("Using spawn_cframe:", teleportSettings.spawn_cframe)

-- Call enter_smooth with the working arguments:
-- (destination_id, house_owner, settings_table, nil)
-- 'house_owner' is LocalPlayer.Name, which satisfies the internal 'destination_door_id' requirement.
InteriorsM.enter_smooth(targetDestinationId, targetHouseOwner, teleportSettings, nil)


print("Adopt Me automatic teleport script ready.")

-- --- CONTINUOUS TELEPORTATION AND WALL MANAGEMENT SCRIPT START ---
-- Define the target path for teleportation and the Summerfest container path.
-- Ensure these paths are correct relative to the 'workspace'.
local TARGET_PART_PATH: string = "Interiors.MainMap!Summerfest.CoconutBonkJoinZone.Ring"
local SUMMERFEST_CONTAINER_PATH: string = "Interiors.MainMap!Summerfest"

-- Define the specific time string at which teleportation should stop.
-- The user specified "00:29"
local STOP_TIME_STRING: string = "00:29"

-- Define the delay between teleports in seconds.
local TELEPORT_DELAY_SECONDS: number = 0.5 -- Adjust this value as needed (e.g., 1 for 1 second delay)

-- Define properties for the wall that will be created.
-- Adjusted for a vertical barrier, extending slightly, and white color.
-- (X-size/Length, Y-size/Height, Z-size/Thickness)
local WALL_SIZE = Vector3.new(35, 20, 2) -- Wider, taller, thin
local WALL_COLOR = BrickColor.new("White") -- Changed to white
local WALL_TRANSPARENCY = 0.0 -- Made fully opaque for visibility
local WALL_MATERIAL = Enum.Material.ForceField -- Added ForceField material for high visibility

-- Define properties for the loading text label
local LOADING_TEXT_FADE_DURATION = 0.5 -- How long it takes for the text to fade out (seconds)

-- Get Roblox services for better practice.
local RunService = game:GetService("RunService") -- Useful for game loops

-- Variable to hold the last created wall instance
local lastCreatedWall: Part? = nil
-- Variable to hold the loading text GUI instance
local loadingTextInstance: TextLabel? = nil
-- Flag to track if the first successful teleport has occurred
local firstTeleportDone: boolean = false

-- New helper function: Converts a "MM:SS" time string to total seconds.
-- Returns 0 if the format is invalid.
local function time_string_to_seconds(time_str: string): number
    local minutes_str, seconds_str = time_str:match("^(%d%d):(%d%d)$")
    if minutes_str and seconds_str then
        return tonumber(minutes_str) * 60 + tonumber(seconds_str)
    end
    warn("Invalid time string format: " .. time_str)
    return 0
end

-- IMPORTANT: THIS FUNCTION HAS BEEN CUSTOMIZED BASED ON YOUR IMAGE AND LATEST PATH.
-- This function is responsible for reading the current time string from your game's UI.
-- It now correctly targets the 'TimerLabel' and extracts the time.
local function get_game_timer_string(): string
    -- Updated path to the TimerLabel as per your latest input
    local timerLabelPath = SUMMERFEST_CONTAINER_PATH .. ".CoconutBonkJoinZone.Billboard.BillboardGui.TimerLabel"
    local timerLabel: TextLabel? = getDescendantFromPath(Workspace, timerLabelPath)

    if timerLabel and timerLabel:IsA("TextLabel") then
        local fullText = timerLabel.Text
        -- Split the text by newline and get the second part (the time)
        local parts = fullText:split("\n")
        if #parts >= 2 then
            return parts[2]:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        end
    end

    -- Default or placeholder if the timer UI element is not found or text format is unexpected.
    return "00:00"
end

-- Function to create and return a temporary loading text label
local function createLoadingText(text: string): TextLabel?
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30) -- Increased timeout for PlayerGui itself
    if not playerGui then
        warn("PlayerGui not found after 30 seconds, cannot display loading text.")
        return nil
    end

    -- Create a ScreenGui to hold the TextLabel
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadingScreenGui"
    screenGui.Parent = playerGui
    print("Loading ScreenGui created and parented to PlayerGui.")

    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingTextDisplay"
    loadingText.Size = UDim2.new(0.3, 0, 0.1, 0) -- 30% width, 10% height of screen
    loadingText.Position = UDim2.new(0.35, 0, 0.45, 0) -- Centered
    loadingText.Text = text
    loadingText.TextColor3 = Color3.new(1, 0, 0) -- Bright Red text for visibility
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.SourceSansBold
    loadingText.TextWrapped = true
    loadingText.BackgroundTransparency = 0 -- Fully opaque background
    loadingText.BackgroundColor3 = Color3.new(0, 0, 0) -- Black background
    loadingText.ZIndex = 10 -- Ensure it's on top of other UI
    loadingText.Parent = screenGui -- Parent to the new ScreenGui
    print("Loading text label created and parented to LoadingScreenGui.")
    return loadingText
end

-- --- SCRIPT START: DISPLAY INITIAL LOADING TEXT ("Script Loading...") ---
print("Roblox Teleport Script started. Creating initial loading GUI.")
loadingTextInstance = createLoadingText("Script Loading...")
if not loadingTextInstance then
    warn("Failed to create loading text instance; script may not be visible.")
end
task.wait(1) -- Give it a moment to render
-- --- END SCRIPT START ---


-- --- INITIAL WALL CREATION (Runs once after initial loading text) ---
-- This wall will be placed at the target teleport location (the Ring)
local initialTargetPart = getDescendantFromPath(Workspace, TARGET_PART_PATH)
if initialTargetPart and initialTargetPart:IsA("BasePart") then
    local wall = Instance.new("Part")
    wall.Size = WALL_SIZE
    wall.BrickColor = WALL_COLOR
    wall.Transparency = WALL_TRANSPARENCY
    wall.Material = WALL_MATERIAL -- Set material for visibility
    wall.CanCollide = false
    wall.Anchored = true
    -- Position and orient the wall to be a vertical barrier that "crosses the lines"
    -- This uses CFrame.fromMatrix for precise control.
    -- X-axis of the wall (its length) will align with the target part's RightVector.
    -- Y-axis of the wall (its height) will align with World Up.
    -- Z-axis of the wall (its thickness) will align with the target part's LookVector.
    wall.CFrame = CFrame.new(initialTargetPart.Position) *
                  CFrame.fromMatrix(
                      Vector3.new(), -- Identity for rotation part
                      initialTargetPart.CFrame.RightVector, -- Wall's X-axis (length)
                      Vector3.new(0, 1, 0), -- Wall's Y-axis (height)
                      initialTargetPart.CFrame.LookVector -- Wall's Z-axis (thickness)
                  ) *
                  CFrame.new(0, WALL_SIZE.Y / 2, 0) -- Lift it up by half its height
    wall.Parent = Workspace
    lastCreatedWall = wall
    print("Initial wall created at: " .. TARGET_PART_PATH)
else
    warn("Could not create initial wall: Target part '" .. TARGET_PART_PATH .. "' not found or not a BasePart.")
end

-- --- END OF INITIAL WALL CREATION ---

-- Update loading text to "Script Loaded" after initial setup
if loadingTextInstance then
    loadingTextInstance.Text = "Script Loaded"
    print("Loading text updated to 'Script Loaded'.")
end


-- Main loop for continuous teleportation and checks.
local teleportationActive: boolean = true
-- New flag to track if the one-time teleport after stopping has occurred.
local hasTeleportedAfterStop: boolean = false

-- Convert the stop time string to seconds once.
local STOP_TIME_SECONDS: number = time_string_to_seconds(STOP_TIME_STRING)

while true do -- Changed from RunService.Heartbeat:Wait() to just 'true' to allow for task.wait() inside
    local character = LocalPlayer.Character
    local humanoidRootPart: BasePart? = character and character:FindFirstChild("HumanoidRootPart")

    -- Get the target part for teleportation (needed for both active and post-stop teleport)
    local targetPart: BasePart? = getDescendantFromPath(Workspace, TARGET_PART_PATH)

    -- Check if the Summerfest container exists in the workspace.
    local summerfestContainer: Instance? = getDescendantFromPath(Workspace, SUMMERFEST_CONTAINER_PATH)

    local shouldBeActive: boolean = false -- Determine if teleportation *should* be active

    if summerfestContainer then
        -- If Summerfest is present, check the timer.
        local currentTimerString: string = get_game_timer_string()
        local currentTimerSeconds: number = time_string_to_seconds(currentTimerString)

        -- Teleportation should be active if current time is NOT less than the stop time.
        shouldBeActive = not (currentTimerSeconds < STOP_TIME_SECONDS)
    else
        -- If Summerfest is not present, teleportation should not be active.
        shouldBeActive = false
        print("Teleportation paused: " .. SUMMERFEST_CONTAINER_PATH .. " not found in Workspace.")
    end

    -- Handle state changes for teleportation
    if shouldBeActive and not teleportationActive then
        -- Teleportation is resuming
        teleportationActive = true
        hasTeleportedAfterStop = false -- Reset the flag when teleportation resumes
        print("Teleportation resumed.")
    elseif not shouldBeActive and teleportationActive then
        -- Teleportation is stopping
        teleportationActive = false
        print("Teleportation paused: Timer went below " .. STOP_TIME_STRING .. " (Current: " .. get_game_timer_string() .. ") or Summerfest not found.")
    end

    -- Perform continuous teleportation if active
    if teleportationActive then
        if humanoidRootPart and targetPart and targetPart:IsA("BasePart") then
            -- Teleport the HumanoidRootPart to the target part's CFrame.
            humanoidRootPart.CFrame = targetPart.CFrame

            -- Destroy loading text if it exists and this is the first teleport
            if not firstTeleportDone and loadingTextInstance then
                -- Use a separate task.spawn for fading out and destroying to not block the main loop
                task.spawn(function()
                    local tweenInfo = TweenInfo.new(LOADING_TEXT_FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local goal = {TextTransparency = 1, BackgroundTransparency = 1}
                    local tween = TweenService:Create(loadingTextInstance, tweenInfo, goal)
                    tween:Play()
                    tween.Completed:Wait()
                    if loadingTextInstance.Parent then -- Check if parent (ScreenGui) still exists before destroying
                        loadingTextInstance.Parent:Destroy() -- Destroy the ScreenGui
                    end
                    loadingTextInstance = nil
                    print("Loading text removed after first successful teleport.")
                end)
                firstTeleportDone = true
            end

            -- Clean up previous wall if it exists
            if lastCreatedWall then
                lastCreatedWall:Destroy()
                lastCreatedWall = nil
            end

            -- Create the new wall at the character's position after teleporting
            local wall = Instance.new("Part")
            wall.Size = WALL_SIZE
            wall.BrickColor = WALL_COLOR
            wall.Transparency = WALL_TRANSPARENCY
            wall.Material = WALL_MATERIAL -- Set material for visibility
            wall.CanCollide = false
            wall.Anchored = true

            -- Position and orient the wall to be a vertical barrier that "crosses the lines"
            wall.CFrame = CFrame.new(humanoidRootPart.Position) *
                          CFrame.fromMatrix(
                              Vector3.new(), -- Identity for rotation part
                              humanoidRootPart.CFrame.RightVector, -- Wall's X-axis (length)
                              Vector3.new(0, 1, 0), -- Wall's Y-axis (height)
                              humanoidRootPart.CFrame.LookVector -- Wall's Z-axis (thickness)
                          ) *
                          CFrame.new(0, WALL_SIZE.Y / 2, 0) -- Lift it up by half its height
            wall.Parent = Workspace
            lastCreatedWall = wall
            print("Teleported and created wall at character's position: " .. TARGET_PART_PATH)
        else
            warn("Continuous teleport failed: HumanoidRootPart or target part not ready.")
            -- Wait for the character and HumanoidRootPart to be available if not already.
            if not humanoidRootPart then
                LocalPlayer.CharacterAdded:Wait()
                character = LocalPlayer.Character
                humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")
            end
        end
        task.wait(TELEPORT_DELAY_SECONDS) -- Add the delay here
    elseif not teleportationActive and not hasTeleportedAfterStop then
        -- Perform one-time teleport after stopping, if it hasn't happened yet
        if humanoidRootPart and targetPart and targetPart:IsA("BasePart") then
            humanoidRootPart.CFrame = targetPart.CFrame
            hasTeleportedAfterStop = true -- Mark that the one-time teleport has occurred
            print("Performed one-time teleport after stopping to: " .. TARGET_PART_PATH)

            -- Destroy loading text if it exists (should already be gone, but safety check)
            if loadingTextInstance then
                -- Use a separate task.spawn for fading out and destroying to not block the main loop
                task.spawn(function()
                    local tweenInfo = TweenInfo.new(LOADING_TEXT_FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local goal = {TextTransparency = 1, BackgroundTransparency = 1}
                    local tween = TweenService:Create(loadingTextInstance, tweenInfo, goal)
                    tween:Play()
                    tween.Completed:Wait()
                    if loadingTextInstance.Parent then
                        loadingTextInstance.Parent:Destroy() -- Destroy the ScreenGui
                    end
                    loadingTextInstance = nil
                end)
            end

            -- Clean up previous wall if it exists from continuous teleport
            if lastCreatedWall then
                lastCreatedWall:Destroy()
                lastCreatedWall = nil
            end

            -- Create the new wall for the final teleport at the character's position
            local wall = Instance.new("Part")
            wall.Size = WALL_SIZE
            wall.BrickColor = WALL_COLOR
            wall.Transparency = WALL_TRANSPARENCY
            wall.Material = Enum.Material.ForceField -- Set material for visibility
            wall.CanCollide = false
            wall.Anchored = true

            wall.CFrame = CFrame.new(humanoidRootPart.Position) *
                          CFrame.fromMatrix(
                              Vector3.new(), -- Identity for rotation part
                              humanoidRootPart.CFrame.RightVector, -- Wall's X-axis (length)
                              Vector3.new(0, 1, 0), -- Wall's Y-axis (height)
                              humanoidRootPart.CFrame.LookVector -- Wall's Z-axis (thickness)
                          ) *
                          CFrame.new(0, WALL_SIZE.Y / 2, 0) -- Lift it up by half its height
            wall.Parent = Workspace
            lastCreatedWall = wall
            print("Created wall for final teleport at character's position.")
        else
            warn("One-time teleport after stopping failed: HumanoidRootPart or target part not ready.")
        end
        task.wait(TELEPORT_DELAY_SECONDS) -- Add a small delay after the final teleport too
    else
        task.wait(0.1) -- Small wait to prevent excessive CPU usage when not actively teleporting
    end
end
-- --- CONTINUOUS TELEPORTATION AND WALL MANAGEMENT SCRIPT END ---
