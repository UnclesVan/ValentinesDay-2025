--[[
    Roblox Teleporter Script
    - Finds all load interaction parts inside all cannons.
    - Teleports sequentially to each one.
    - Loops endlessly.
]]

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
