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
-- PART 2: Crowsnest Telporting 
-- ====================================================================

local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local mainPath = "Interiors.MainMap!Summerfest.Event.CrowsNestCannons"

local function getAllLoadInteractionParts()
    local container = workspace
    for part in string.gmatch(mainPath, "[^%.]+") do
        container = container:FindFirstChild(part)
        if not container then
            warn("Cannot find part: " .. part)
            return {}
        end
    end

    local loadParts = {}
    for _, cannonModel in ipairs(container:GetChildren()) do
        if cannonModel:IsA("Model") and tonumber(cannonModel.Name) then
            local cannon = cannonModel:FindFirstChild("Cannon")
            if cannon and cannon:IsA("Model") then
                local loadPart = cannon:FindFirstChild("LoadInteractionPart")
                if loadPart and loadPart:IsA("BasePart") then
                    table.insert(loadParts, loadPart)
                end
            end
        end
    end
    print("Found " .. #loadParts .. " load interaction parts.")
    return loadParts
end

local function teleportToAll()
    local hrp = getHRP()
    if not hrp then
        warn("HumanoidRootPart not found.")
        return
    end

    spawn(function()
        while true do
            local loadParts = getAllLoadInteractionParts()
            if #loadParts == 0 then
                warn("No load parts found.")
                wait(5)
                continue
            end

            for i, loadPart in ipairs(loadParts) do
                if loadPart and loadPart.Parent then
                    -- Teleport
                    hrp.CFrame = loadPart.CFrame * CFrame.new(0, 5, 0)
                    print("Teleported to load interaction #" .. i)
                    wait(2) -- wait 2 seconds before moving to next
                else
                    warn("Load interaction #" .. i .. " no longer exists.")
                end
            end
            wait(3) -- wait before starting over
        end
    end)
end

player.CharacterAdded:Connect(function()
    wait(1)
    teleportToAll()
end)

if player.Character then
    teleportToAll()
end
