--!strict

--[[
    IMPORTANT NOTE REGARDING 'loadstring(game:HttpGet(...))':

    You have repeatedly included the line:
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/UnclesVan/AdoPtMe-/refs/heads/main/dehashwithslashinmiddle')))()

    In standard Roblox environments, 'loadstring' combined with 'game:HttpGet'
    is almost always DISABLED or heavily RESTRICTED for security reasons.
    This means that this line of code will very likely FAIL to execute,
    and any "dehashing" or setup that the external script was supposed to perform
    WILL NOT HAPPEN.

    If this initial 'loadstring' call is crucial for setting up the 'RemoteEvents'
    or other game elements that the rest of the script relies on, then the
    subsequent parts of this script will not function correctly because their
    dependencies are missing.

    The most reliable way to run this script is to embed ALL the necessary Lua code
    directly into a LocalScript in Roblox Studio, as provided in previous responses.
    If you are in a specific environment where 'loadstring' is known to be enabled
    (e.g., a custom client, an exploit context, or a very old game server setup),
    then this full script might work as you intend, but it is not the standard
    or recommended way to develop for Roblox.

    This script below includes the 'loadstring' line as you requested,
    but be aware of the high probability of it failing due to Roblox's security measures.
]]

-- The loadstring call you provided. This is the part most likely to fail.
loadstring(game:HttpGet(('https://raw.githubusercontent.com/UnclesVan/AdoPtMe-/refs/heads/main/dehashwithslashinmiddle')))()

-- Delay between dehashing so the remotes load properly by the RouterClient so the bottom script works.
-- Note: This 'wait' assumes the loadstring call above actually succeeded and did its work.
-- If loadstring failed, this delay won't help.
task.wait(2) -- Added a small delay here as per your comment, using task.wait for modern Roblox.

-- ====================================================================
-- PART 1: AFK Disconnection Prevention (RemoteEvent Destruction)
-- ====================================================================

-- Define a variable to hold the ReplicatedStorage service.
-- This is a core Roblox service used for client-server communication.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Define the path components based on the user's original syntax:
-- game:GetService("ReplicatedStorage").API["SummerfestEventAPI/RequestAFKTeleport"]
-- This means 'API' is a folder, and the object itself is named 'SummerfestEventAPI/RequestAFKTeleport'
-- inside that 'API' folder.
local API_FOLDER_NAME = "API"
local TARGET_OBJECT_FULL_NAME = "SummerfestEventAPI/RequestAFKTeleport" -- This is the literal name of the object

-- Function to attempt to destroy the target object.
-- This function will try to find the target and destroy it.
local function destroyAFKTeleport()
    -- First, try to find the 'API' folder in ReplicatedStorage.
    -- We use WaitForChild to ensure it exists before proceeding.
    local apiFolder = ReplicatedStorage:WaitForChild(API_FOLDER_NAME, 15) -- Increased timeout to 15 seconds
    if not apiFolder then
        warn("AFK Preventer: Failed to find folder named '" .. API_FOLDER_NAME .. "' in ReplicatedStorage. Retrying...")
        return -- Exit the function if the 'API' folder isn't found
    end
    print("AFK Preventer: Found folder named '" .. API_FOLDER_NAME .. "'.")

    -- Now, try to find the target object *by its full literal name* inside the 'API' folder.
    -- This assumes the object's name literally contains the slashes.
    local afkTeleportObject = apiFolder:WaitForChild(TARGET_OBJECT_FULL_NAME, 15) -- Increased timeout
    if not afkTeleportObject then
        warn("AFK Preventer: Failed to find object named '" .. TARGET_OBJECT_FULL_NAME .. "' inside '" .. API_FOLDER_NAME .. "'. Retrying...")
        return -- Exit if the target object isn't found
    end
    print("AFK Preventer: Found object named '" .. TARGET_OBJECT_FULL_NAME .. "'.")

    -- Check if the found object is an Instance and specifically a RemoteEvent.
    if typeof(afkTeleportObject) == "Instance" and afkTeleportObject:IsA("RemoteEvent") then
        -- If it's a RemoteEvent, we can destroy it.
        -- Destroying it will remove it from the DataModel on the client,
        -- making it inaccessible for client-side scripts.
        afkTeleportObject:Destroy()
        print("AFK Preventer: Successfully destroyed RemoteEvent named '" .. TARGET_OBJECT_FULL_NAME .. "'.")
    elseif typeof(afkTeleportObject) == "function" then
        -- This case is less common for objects directly parented in ReplicatedStorage,
        -- as Roblox APIs are typically Instances (RemoteFunction, RemoteEvent).
        warn("AFK Preventer: Object named '" .. TARGET_OBJECT_FULL_NAME .. "' found as a direct function. Direct destruction is not possible for this type.")
        warn("AFK Preventer: This script primarily targets Roblox Instances like RemoteFunctions/RemoteEvents for destruction.")
    else
        -- If the object is found but is not a RemoteEvent or a type that can be destroyed
        -- in this manner, log its actual type for debugging.
        warn("AFK Preventer: Found object named '" .. TARGET_OBJECT_FULL_NAME .. "' but it is not a RemoteEvent or a destructible Instance.")
        warn("AFK Preventer: Its actual type is: " .. typeof(afkTeleportObject) .. ". Its ClassName is: " .. afkTeleportObject.ClassName .. ". Retrying...")
    end
end

-- Use a separate coroutine for the AFK prevention loop to run concurrently
-- with the button clicking loop.
task.spawn(function()
    while true do
        -- Wrap the call to destroyAFKTeleport in a pcall.
        -- pcall returns two values: success (boolean) and result/error message.
        local success, errorMessage = pcall(destroyAFKTeleport)

        -- If the pcall was not successful (an error occurred), print the error message.
        if not success then
            warn("AFK Preventer: An error occurred during AFK teleport destruction attempt: " .. tostring(errorMessage))
        end

        -- Wait for a short period before attempting again to avoid excessive resource usage.
        task.wait(1) -- Current delay is 1 second.
    end
end)

-- ====================================================================
-- PART 2: Hotbar Button Clicking
-- ====================================================================

-- Essential Services
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 15) -- Increased timeout for PlayerGui

if not playerGui then
    warn("Hotbar Clicker: PlayerGui not found after 15 seconds. Script cannot proceed with button clicking.")
    -- The AFK prevention part will continue to run in its own task.
    return -- Exit this part of the script if PlayerGui isn't available
end

print("Hotbar Clicker: Script started successfully and PlayerGui found!")
print("Hotbar Clicker: Starting continuous button finding and clicking loop.")

-- Define the paths to the target buttons
local dropButtonPath = "MinigameHotbarApp.Hotbar.DropButton.Button"
local swordButtonPath = "MinigameHotbarApp.Hotbar.SwordButton.Button"

-- Function to safely get a UI element with a timeout and explicit retries
-- Returns the found instance, or nil if not found within all attempts
local function getUIElement(base, fullPathString, timeoutPerAttempt, maxAttempts)
    timeoutPerAttempt = timeoutPerAttempt or 0.2 -- How long to wait per attempt
    maxAttempts = maxAttempts or 3               -- How many times to retry finding each part

    local currentElement = base
    local pathParts = string.split(fullPathString, ".")

    for i, partName in ipairs(pathParts) do
        local found = false
        local attempts = 0
        local elementToFind = partName

        while not found and attempts < maxAttempts do
            attempts = attempts + 1
            local result = currentElement:WaitForChild(elementToFind, timeoutPerAttempt)

            if result then
                currentElement = result
                found = true
            else
                -- No need to print retry messages here; the main loop will handle "Not all buttons found"
            --    if i == #pathParts and attempts < maxAttempts then -- Only print retry if it's the last part and not out of attempts
            --        print("Retrying (" .. attempts .. "/" .. maxAttempts .. ") to find '" .. elementToFind .. "' for path: " .. fullPathString)
            --    elseif i == #pathParts and attempts == maxAttempts then
            --        warn("Failed to find '" .. elementToFind .. "' for path '" .. fullPathString .. "' after " .. maxAttempts .. " attempts.")
            --    end
            end
        end

        if not found then
            return nil -- If any part of the path is not found after maxAttempts, return nil
        end
    end
    return currentElement
end

-- Function to simulate click events
local function clickButton(buttonInstance)
    if buttonInstance and buttonInstance.Parent then -- Check if the button exists and is still in the game hierarchy
        print("Hotbar Clicker: Attempting to click: " .. buttonInstance.Name)
        -- Attempt to fire MouseButton1Down, MouseButton1Click, and MouseButton1Up
        -- This sequence attempts to mimic a full user click action
        for _, connection in pairs(getconnections(buttonInstance.MouseButton1Down)) do
            connection:Fire()
        end
        task.wait(0.05) -- Small delay between firing events for realism
        for _, connection in pairs(getconnections(buttonInstance.MouseButton1Click)) do
            connection:Fire()
        end
        task.wait(0.05)
        for _, connection in pairs(getconnections(buttonInstance.MouseButton1Up)) do
            connection:Fire()
        end
        print("Hotbar Clicker: Successfully sent click events to: " .. buttonInstance.Name)
    else
        warn("Hotbar Clicker: Click aborted: " .. (buttonInstance and buttonInstance.Name or "nil button") .. " is not valid or removed.")
    end
end

local actionDelay = 0.5 -- Delay in seconds between clicking DropButton and SwordButton
local findCycleDelay = 1 -- Delay if buttons are not found in a cycle

-- Main loop to continuously find and click the buttons
while true do
    print("Hotbar Clicker: Finding hotbar button 1...")
    local foundDropButton = getUIElement(playerGui, dropButtonPath)

    print("Hotbar Clicker: Finding hotbar button 2...")
    local foundSwordButton = getUIElement(playerGui, swordButtonPath)

    if foundDropButton and foundSwordButton then
        print("Hotbar Clicker: Found hotbar button 1: " .. foundDropButton.Name)
        print("Hotbar Clicker: Found hotbar button 2: " .. foundSwordButton.Name)

        -- Now that both are confirmed found, perform the clicks
        clickButton(foundDropButton)
        task.wait(actionDelay)

        clickButton(foundSwordButton)
        task.wait(actionDelay) -- Delay before checking again for the next cycle
    else
        -- If one or both buttons are not found, wait and try again
        print("Hotbar Clicker: Not all buttons were found in this attempt. Retrying...")
        task.wait(findCycleDelay)
    end

    task.wait(0.1) -- Small yield to prevent script from hogging resources
end

print("Hotbar Clicker: Script finished or stopped.")
