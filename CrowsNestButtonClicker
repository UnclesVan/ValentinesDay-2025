--[[
    Roblox Auto-Clicker Script

    This script is designed to simulate clicks on a specific GUI button
    within a Roblox game. It uses the provided 'clickButton' function
    to fire the necessary events (MouseButton1Down, MouseButton1Click, MouseButton1Up)
    to mimic a user interaction.

    This script should be placed as a LocalScript, typically under
    StarterPlayerScripts or directly within a GUI element if it's meant
    to be triggered by a local event.
]]

-- Function to simulate click events on a GUI button
-- @param button: The GUI button object to click.
local function clickButton(button)
    -- Check if the button object exists
    if button then
        print("Button found! Attempting to click:", button.Name)

        -- Attempt to fire MouseButton1Down connections
        -- This simulates the mouse button being pressed down on the element.
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do
            connection:Fire()
        end
        wait(0.05) -- Small delay to simulate real-world interaction timing (reduced for faster clicking)

        -- Attempt to fire MouseButton1Click connections
        -- This simulates the full click action.
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
        end
        wait(0.05) -- Small delay

        -- Attempt to fire MouseButton1Up connections
        -- This simulates the mouse button being released.
        for _, connection in pairs(getconnections(button.MouseButton1Up)) do
            connection:Fire()
        end
        print("Successfully clicked the button!")
    else
        print("Button not found at the specified path!")
    end
end

-- Get the LocalPlayer and PlayerGui service
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") -- Ensure PlayerGui is loaded

-- Define the path to the target button within PlayerGui
-- We will use WaitForChild for each part of the path to ensure each parent
-- exists before trying to find its child. This is more robust for dynamically
-- loading GUI elements.
local targetButton = nil

print("Attempting to find the target button...")

-- Use pcall to safely attempt to find the button, as WaitForChild can error if the instance is destroyed
local success, foundButton = pcall(function()
    local interactionsApp = PlayerGui:WaitForChild("InteractionsApp", 15) -- Increased timeout to 15 seconds
    if not interactionsApp then return nil end

    local basicSelects = interactionsApp:WaitForChild("BasicSelects", 15)
    if not basicSelects then return nil end

    local template = basicSelects:WaitForChild("Template", 15)
    if not template then return nil end

    local tapButton = template:WaitForChild("TapButton", 15)
    return tapButton
end)

if success and foundButton then
    targetButton = foundButton
    print("Target button found:", targetButton.Name)

    -- Loop to continuously click the button
    -- You can adjust the 'wait(0.5)' value to control the click speed.
    -- Be careful with very small wait times as it might cause performance issues
    -- or be flagged by anti-cheat systems in some games.
    while task.wait(0.5) do -- Use task.wait for better performance and reliability in loops
        if targetButton.Parent then -- Check if the button is still in the game hierarchy
            clickButton(targetButton)
        else
            warn("Target button removed from hierarchy. Stopping auto-clicker.")
            break -- Exit the loop if the button is no longer valid
        end
    end
else
    -- This case should ideally not be reached if the WaitForChild calls are successful
    -- or if the elements eventually load. The pcall makes it safer.
    warn("Could not find the target button after multiple attempts or within timeout. Auto-clicker will not start.")
    if not success then
        warn("Error during button lookup:", foundButton) -- foundButton will contain the error message here
    end
end
