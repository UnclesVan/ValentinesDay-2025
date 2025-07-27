-- --- DEHASHING SCRIPT INTEGRATION START ---
local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys")).load

-- Get the init function from RouterClient
local initFunction = Fsys("RouterClient").init

-- Folder containing the remotes to track
local remoteFolder = game:GetService("ReplicatedStorage"):WaitForChild("API")

-- A flag to ensure we print only once during the initial scan
local printedOnce = false

-- Function to inspect upvalues and identify remotes
local function inspectUpvalues()
    local remotes = {}  -- Table to collect remotes

    for i = 1, math.huge do
        local success, upvalue = pcall(getupvalue, initFunction, i)
        if not success then
            break
        end
        
        -- If the upvalue is a table, let's check its contents
        if typeof(upvalue) == "table" then
            for k, v in pairs(upvalue) do
                -- Check for RemoteEvents, RemoteFunctions, BindableEvents, and BindableFunctions
                if typeof(v) == "Instance" then
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                        -- Log the key, type of value, and value
                        table.insert(remotes, {key = k, remote = v})
                        -- If it's the first time scanning, print remote information
                        if not printedOnce then
                            print("Key: " .. k .. " Type: " .. typeof(k) .. ", Value Type: " .. typeof(v))
                            print("Found remote: " .. v:GetFullName())
                        end
                    end
                end
            end
        end
    end

    return remotes
end

-- Function to rename remotes based on their key
local function rename(remote, key)
    local nameParts = string.split(key, "/")  -- Split the key by "/"
    if #nameParts > 1 then
        local remotename = table.concat(nameParts, "/", 1, 2)  -- Join the first two parts
        remote.Name = remotename
    else
        warn("Invalid key format for remote: " .. key)  -- Notify if the key format is incorrect
    end
end

-- Function to rename all existing remotes in the folder
local function renameExistingRemotes()
    local remotes = inspectUpvalues()

    -- Rename all collected remotes based on the key
    for _, entry in ipairs(remotes) do
        rename(entry.remote, entry.key)
    end
end

-- Function to display dehashed message
local function displayDehashedMessage()
    local uiElement = game:GetService("Players").LocalPlayer.PlayerGui.HintApp.LargeTextLabel
    uiElement.Text = "Remotes has been Dehashed!"
    uiElement.TextColor3 = Color3.fromRGB(0, 255, 0)  -- Set text color to green
    task.wait(3)
    uiElement.Text = ""
    uiElement.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Reset text color to default (white)
end

-- Monitor for new remotes added to the folder
local function monitorForNewRemotes()
    remoteFolder.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") or child:IsA("BindableFunction") then
            print("New remote added: " .. child:GetFullName())
            -- Check and rename the new remote
            local remotes = inspectUpvalues()
            for _, entry in ipairs(remotes) do
                rename(entry.remote, entry.key)
            end
        end
    end)
end

-- Coroutine for periodic check without freezing
local function periodicCheck()
    while true do
        task.wait(10)  -- Check every 10 seconds (can adjust based on your needs)
        -- Scan and rename existing remotes periodically
        pcall(renameExistingRemotes)
    end
end

-- Start the periodic check in a coroutine (non-blocking)
coroutine.wrap(periodicCheck)()

-- Initial scan and rename for all existing remotes (print once)
renameExistingRemotes()

-- Display dehashed message
displayDehashedMessage()

-- Set the flag to prevent printing more than once
printedOnce = true

print("Script initialized and monitoring remotes.")
-- --- DEHASHING SCRIPT INTEGRATION END ---


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

local function clickButton(button: GuiButton?)
    if button then
        print("Button found! Attempting to click:", button.Name)
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do
            connection:Fire()
        end
        task.wait(0.1)
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
        end
        task.wait(0.1)
        for _, connection in pairs(getconnections(button.MouseButton1Up)) do
            connection:Fire()
        end
        print("Successfully clicked the button!")
    else
        print("Button not found!")
    end
end

local function findUIElement(playerGui: PlayerGui, path: string, timeout: number): Instance?
    local currentParent: Instance? = playerGui
    local pathParts = path:split(".")
    local foundElement: Instance? = nil

    for i, partName in ipairs(pathParts) do
        if partName == "PlayerGui" then continue end
        print("Attempting to find '" .. partName .. "' as child of '" .. (currentParent and currentParent.Name or "nil") .. "' (Path part " .. i .. "/" .. #pathParts .. ")")
        if partName == "ScrollingFrame" and currentParent then
            local scrollingFrame = currentParent:WaitForChild(partName, timeout)
            if scrollingFrame then
                print("Children of " .. currentParent.Name .. "." .. partName .. ":")
                for _, child in ipairs(scrollingFrame:GetChildren()) do
                    print(" - " .. child.Name .. " (" .. child.ClassName .. ")")
                end
            end
        end
        local child = currentParent:WaitForChild(partName, timeout)
        if child then
            currentParent = child
        else
            print("Could not find part of the path: '" .. partName .. "' in parent '" .. (currentParent and currentParent.Name or "nil") .. "'")
            return nil
        end
        if i == #pathParts then
            foundElement = currentParent
        end
    end
    return foundElement
end

-- --- START OF PLAY BUTTON CLICK ---
local newsAppButtonPath = "PlayerGui.NewsApp.EnclosingFrame.MainFrame.Buttons.PlayButton"
LocalPlayer.PlayerGui:WaitForChild("NewsApp", 20)
local targetNewsAppButton = findUIElement(LocalPlayer.PlayerGui, newsAppButtonPath, 15)
clickButton(targetNewsAppButton)
task.wait(5)
-- --- END OF PLAY BUTTON CLICK ---

-- --- PET UNEQUIP SCRIPT INTEGRATION START ---
local ClientDataModule_Pets = nil
local success_pets, errorMessage_pets = pcall(function()
    ClientDataModule_Pets = require(ReplicatedStorage.ClientModules.Core.ClientData)
end)

if not success_pets then
    warn("Failed to load ClientData module for pets:", errorMessage_pets)
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
        local MAX_RETRIES = 3
        for _, uniqueId in ipairs(allPetUniqueIds) do
            local unequippedSuccessfully = false
            for retryAttempt = 1, MAX_RETRIES do
                print(string.format("Unequipping pet ID: %s (Attempt %d/%d)", uniqueId, retryAttempt, MAX_RETRIES))
                local success_unequip, result_unequip = pcall(function()
                    return ToolAPI_Unequip:InvokeServer(uniqueId, {
                        use_sound_delay = false,
                        equip_as_last = false
                    })
                end)
                if success_unequip then
                    print("Successfully unequipped pet ID: " .. uniqueId)
                    unequippedSuccessfully = true
                    break
                else
                    warn("Failed to unequip pet ID: " .. uniqueId .. " - " .. tostring(result_unequip))
                    if retryAttempt < MAX_RETRIES then
                        task.wait(0.5)
                    end
                end
            end
            if not unequippedSuccessfully then
                warn("Failed to unequip pet ID: " .. uniqueId .. " after " .. MAX_RETRIES .. " attempts.")
            end
            task.wait(0.1)
        end
        print("Finished unequipping pets.")
    end
end
-- --- PET UNEQUIP SCRIPT INTEGRATION END ---

-- --- DAILY REWARD CLAIM LOOP START ---
print("Starting daily reward claim loop...")
task.spawn(function()
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
        task.wait(60)
    end
end)
print("Daily reward claim loop initiated in a separate thread.")
-- --- DAILY REWARD CLAIM LOOP END ---

-- --- LURE PLACEMENT SCRIPT INTEGRATION START ---
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

    local playerName = game.Players.LocalPlayer and game.Players.LocalPlayer.Name
    if not playerName then
        warn("Could not get local player name, cannot place lures.")
    else
        local playerData = serverData[playerName]
        if not playerData or not playerData.inventory or not playerData.inventory.food then
            warn("No inventory data for player: " .. playerName .. ", cannot place lures.")
        else
            local baitId = nil
            for uniqueId, foodData in pairs(playerData.inventory.food) do
                if foodData.id == "ice_dimension_2025_ice_soup_bait" then
                    baitId = uniqueId
                    break
                end
            end
            if not baitId then
                warn("Ice Soup Bait not found in inventory, cannot place lures.")
            else
                local furnitureFolder = Workspace:FindFirstChild("HouseInteriors")
                    and Workspace.HouseInteriors:FindFirstChild("furniture")
                if not furnitureFolder then
                    warn("Furniture folder not found, cannot place lures.")
                else
                    print("Attempting to place lures 2 times...")
                    for activationAttempt = 1, 2 do
                        print(string.format("Lure placement attempt %d/2...", activationAttempt))
                        for _, model in pairs(furnitureFolder:GetChildren()) do
                            if typeof(model) == "Instance" and model.Name:find("^" .. playerName .. "/1/nil/true/f%-") then
                                local fNumber = model.Name:match("f%-(%d+)$")
                                if fNumber then
                                    local lure = model:FindFirstChild("Lures2023NormalLure")
                                    if lure then
                                        print("Found lure in model:", model.Name, "f- number:", fNumber)
                                        local args = {
                                            game:GetService("Players"):WaitForChild(playerName),
                                            "f-" .. fNumber,
                                            "UseBlock",
                                            { bait_unique = baitId },
                                            game.Players.LocalPlayer.Character
                                        }
                                        local success, err = pcall(function()
                                            game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("HousingAPI/ActivateFurniture"):InvokeServer(unpack(args))
                                        end)
                                        if success then
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
                        task.wait(1)
                    end
                    print("Finished lure placement attempts.")
                end
            end
        end
    end
end
-- --- LURE PLACEMENT SCRIPT INTEGRATION END ---

print("Initiating automatic teleport to MainMap.")

local targetDestinationId = "MainMap"
local targetHouseOwner = LocalPlayer.Name

local teleportSettings = {
    fade_in_length = 0.5,
    fade_out_length = 0.4,
    fade_color = Color3.new(1, 1, 1), -- Changed to white
    player_about_to_teleport = function() print("Player is about to teleport...") end,
    teleport_completed_callback = function() print("Teleport completed callback.") end,
    player_to_teleport_to = nil,
    anchor_char_immediately = true,
    post_character_anchored_wait = 0.5,
    spawn_cframe = CFrame.new(-275.9091491699219, 25.812084197998047, -1548.145751953125, -0.9798217415809631, 0.0000227206928684609, 0.19986890256404877, -0.000003862579433189239, 1, -0.00013261348067317158, -0.19986890256404877, -0.00013070966815575957, -0.9798217415317158),
    move_camera = true,
    door_id_for_location_module = nil,
    exiting_door = nil,
}

print("Attempting to trigger automatic door teleport to:", targetDestinationId)
print("Using house owner (now LocalPlayer.Name):", targetHouseOwner)
print("Using spawn_cframe:", teleportSettings.spawn_cframe)

InteriorsM.enter_smooth(targetDestinationId, targetHouseOwner, teleportSettings, nil)

print("Adopt Me automatic teleport script ready.")

-- --- CONTINUOUS TELEPORTATION AND WALL MANAGEMENT SCRIPT START ---
local TARGET_PART_PATH = "Interiors.MainMap!Summerfest.CoconutBonkJoinZone.Ring"
local SUMMERFEST_CONTAINER_PATH = "Interiors.MainMap!Summerfest"
local STOP_TIME_STRING = "00:29"
local TELEPORT_DELAY_SECONDS = 0.5

local RunService = game:GetService("RunService")
local lastCreatedWall = nil
local loadingTextInstance = nil
local firstTeleportDone = false

-- New variable for the toggle state
local ringTeleportEnabled = true

-- Function to update the toggle button text
local toggleButton = nil -- Declare it here to be accessible globally

local function updateToggleButtonText()
    if toggleButton then
        toggleButton.Text = "Ring Teleport: " .. (ringTeleportEnabled and "ON" or "OFF")
        toggleButton.TextColor3 = ringTeleportEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0) -- Green for ON, Red for OFF
    end
end

-- Create the toggle button UI
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
if playerGui then
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RingTeleportToggleGui"
    screenGui.Parent = playerGui

    toggleButton = Instance.new("TextButton")
    toggleButton.Name = "RingTeleportToggleButton"
    toggleButton.Size = UDim2.new(0.2, 0, 0.05, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.9, 0) -- Position at bottom-left
    toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    toggleButton.BorderColor3 = Color3.new(0.1, 0.1, 0.1)
    toggleButton.BorderSizePixel = 2
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextScaled = true
    toggleButton.TextWrapped = true
    toggleButton.ZIndex = 10
    toggleButton.Parent = screenGui

    -- Set initial text
    updateToggleButtonText()

    -- Connect the toggle functionality
    toggleButton.MouseButton1Click:Connect(function()
        ringTeleportEnabled = not ringTeleportEnabled
        updateToggleButtonText()
        print("Ring Teleport Toggled: " .. (ringTeleportEnabled and "ON" or "OFF"))
    end)
    print("Ring Teleport Toggle Button created.")
else
    warn("PlayerGui not found, cannot create Ring Teleport Toggle Button.")
end


local function time_string_to_seconds(time_str)
    local minutes_str, seconds_str = time_str:match("^(%d%d):(%d%d)$")
    if minutes_str and seconds_str then
        return tonumber(minutes_str) * 60 + tonumber(seconds_str)
    end
    warn("Invalid time string format: " .. time_str)
    return 0
end

local function get_game_timer_string()
    local timerLabelPath = SUMMERFEST_CONTAINER_PATH .. ".CoconutBonkJoinZone.Billboard.BillboardGui.TimerLabel"
    local timerLabel = getDescendantFromPath(Workspace, timerLabelPath)
    if timerLabel and timerLabel:IsA("TextLabel") then
        local fullText = timerLabel.Text
        local parts = fullText:split("\n")
        if #parts >= 2 then
            return parts[2]:gsub("^%s*(.-)%s*$", "%1")
        end
    end
    return "00:00"
end

local function createLoadingText(text)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
    if not playerGui then
        warn("PlayerGui not found, cannot display loading text.")
        return nil
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadingScreenGui"
    screenGui.Parent = playerGui
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingTextDisplay"
    loadingText.Size = UDim2.new(0.3, 0, 0.1, 0)
    loadingText.Position = UDim2.new(0.35, 0, 0.45, 0)
    loadingText.Text = text
    loadingText.TextColor3 = Color3.new(1, 0, 0)
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.SourceSansBold
    loadingText.TextWrapped = true
    loadingText.BackgroundTransparency = 0
    loadingText.BackgroundColor3 = Color3.new(0, 0, 0)
    loadingText.ZIndex = 10
    loadingText.Parent = screenGui
    return loadingText
end

print("Roblox Teleport Script started. Creating initial loading GUI.")
loadingTextInstance = createLoadingText("Script Loading...")
task.wait(1)

-- Initial wall creation with solid, studs wall properties
local initialTargetPart = getDescendantFromPath(Workspace, TARGET_PART_PATH)
if initialTargetPart and initialTargetPart:IsA("BasePart") then
    local wall = Instance.new("Part")
    wall.Size = Vector3.new(35, 20, 2)
    wall.BrickColor = BrickColor.new("Medium stone grey")
    wall.Transparency = 0 -- fully opaque
    wall.Material = Enum.Material.Plastic -- solid material
    wall.CanCollide = false -- change to true if you want players to collide
    wall.Anchored = true
    -- Position and orient the wall
    wall.CFrame = CFrame.new(initialTargetPart.Position) *
                    CFrame.fromMatrix(
                        Vector3.new(),
                        initialTargetPart.CFrame.RightVector,
                        Vector3.new(0, 1, 0),
                        initialTargetPart.CFrame.LookVector
                    ) *
                    CFrame.new(0, 20 / 2, 0)
    wall.Parent = Workspace
    lastCreatedWall = wall
    print("Initial solid studs wall created at: " .. TARGET_PART_PATH)
else
    warn("Could not create initial wall: Target part '" .. TARGET_PART_PATH .. "' not found or not a BasePart.")
end

-- Update loading text
if loadingTextInstance then
    loadingTextInstance.Text = "Script Loaded"
end

local hasTeleportedAfterStop = false
local STOP_TIME_SECONDS = time_string_to_seconds(STOP_TIME_STRING)

while true do
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local targetPart = getDescendantFromPath(Workspace, TARGET_PART_PATH)
    local summerfestContainer = getDescendantFromPath(Workspace, SUMMERFEST_CONTAINER_PATH)
    local shouldBeActive = false

    if summerfestContainer then
        local currentTimerString = get_game_timer_string()
        local currentTimerSeconds = time_string_to_seconds(currentTimerString)
        shouldBeActive = not (currentTimerSeconds < STOP_TIME_SECONDS)
    else
        shouldBeActive = false
        print("Teleportation paused: " .. SUMMERFEST_CONTAINER_PATH .. " not found.")
    end

    -- Combine the game timer logic with the new toggle
    local actualTeleportActive = shouldBeActive and ringTeleportEnabled

    if actualTeleportActive and not (teleportationActive == true) then -- Check if state changed to active
        teleportationActive = true
        hasTeleportedAfterStop = false
        print("Teleportation resumed (by game timer and toggle).")
    elseif not actualTeleportActive and (teleportationActive == true) then -- Check if state changed to inactive
        teleportationActive = false
        print("Teleportation paused (by game timer or toggle).")
    end

    if actualTeleportActive then
        if humanoidRootPart and targetPart and targetPart:IsA("BasePart") then
            humanoidRootPart.CFrame = targetPart.CFrame
            if not firstTeleportDone and loadingTextInstance then
                task.spawn(function()
                    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local goal = {TextTransparency = 1, BackgroundTransparency = 1}
                    local tween = TweenService:Create(loadingTextInstance, tweenInfo, goal)
                    tween:Play()
                    tween.Completed:Wait()
                    if loadingTextInstance.Parent then loadingTextInstance.Parent:Destroy() end
                    loadingTextInstance = nil
                end)
                firstTeleportDone = true
            end
            -- Destroy previous wall
            if lastCreatedWall then
                lastCreatedWall:Destroy()
                lastCreatedWall = nil
            end
            -- Create new solid wall at teleport position
            local wall = Instance.new("Part")
            wall.Size = Vector3.new(35, 20, 2)
            wall.BrickColor = BrickColor.new("Medium stone grey")
            wall.Transparency = 0
            wall.Material = Enum.Material.Plastic
            wall.CanCollide = false
            wall.Anchored = true
            wall.CFrame = CFrame.new(humanoidRootPart.Position) *
                            CFrame.fromMatrix(
                                Vector3.new(),
                                humanoidRootPart.CFrame.RightVector,
                                Vector3.new(0,1,0),
                                humanoidRootPart.CFrame.LookVector
                            ) *
                            CFrame.new(0, 20/2, 0)
            wall.Parent = Workspace
            lastCreatedWall = wall
            print("Teleported and created solid wall at character's position: " .. TARGET_PART_PATH)
        else
            warn("Continuous teleport failed: HumanoidRootPart or target part not ready.")
        end
        task.wait(TELEPORT_DELAY_SECONDS)
    elseif not actualTeleportActive and not hasTeleportedAfterStop then
        if humanoidRootPart and targetPart and targetPart:IsA("BasePart") then
            humanoidRootPart.CFrame = targetPart.CFrame
            hasTeleportedAfterStop = true
            print("Performed one-time teleport after stopping.")
            if loadingTextInstance then
                task.spawn(function()
                    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local goal = {TextTransparency = 1, BackgroundTransparency = 1}
                    local tween = TweenService:Create(loadingTextInstance, tweenInfo, goal)
                    tween:Play()
                    tween.Completed:Wait()
                    if loadingTextInstance.Parent then loadingTextInstance.Parent:Destroy() end
                    loadingTextInstance = nil
                end)
            end
            -- create final wall (solid)
            local wall = Instance.new("Part")
            wall.Size = Vector3.new(35, 20, 2)
            wall.BrickColor = BrickColor.new("Medium stone grey")
            wall.Transparency = 0
            wall.Material = Enum.Material.Plastic
            wall.CanCollide = false
            wall.Anchored = true
            wall.CFrame = CFrame.new(humanoidRootPart.Position) *
                            CFrame.fromMatrix(
                                Vector3.new(),
                                humanoidRootPart.CFrame.RightVector,
                                Vector3.new(0,1,0),
                                humanoidRootPart.CFrame.LookVector
                            ) *
                            CFrame.new(0, 20/2, 0)
            wall.Parent = Workspace
            lastCreatedWall = wall
            print("Created final solid wall after last teleport.")
        else
            warn("One-time teleport after stopping failed: HumanoidRootPart or target part not ready.")
        end
        task.wait(TELEPORT_DELAY_SECONDS)
    else
        task.wait(0.1)
    end
end
-- --- END OF SCRIPT ---
