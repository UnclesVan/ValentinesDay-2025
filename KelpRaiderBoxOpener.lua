--!strict
-- This script creates a simple Gift Opener UI in Roblox and handles the gift opening and buying logic.
-- It is designed to be placed inside StarterPlayerScripts or StarterGui.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Player
local player = Players.LocalPlayer
if not player then
    warn("Player not found. This script should be run on the client.")
    return
end

-- UI Setup
local playerGui = player:WaitForChild("PlayerGui") -- Ensure PlayerGui exists

local ScreenGui: ScreenGui
local guiName = "GiftOpenerUI"

-- Check if a ScreenGui with the desired name already exists in PlayerGui
local existingGui = playerGui:FindFirstChild(guiName)
if existingGui and existingGui:IsA("ScreenGui") then
    ScreenGui = existingGui
else
    -- If not, create a new ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = playerGui
end

ScreenGui.ResetOnSpawn = false -- Keep the UI visible across spawns

-- Main Frame - Mimics the wooden frame from the React UI
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.6, 0, 0.7, 0) -- Responsive size
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(184, 106, 0) -- Amber-700 like
MainFrame.BorderColor3 = Color3.fromRGB(120, 68, 0) -- Amber-900 like
MainFrame.BorderSizePixel = 8
MainFrame.Draggable = true -- Make the UI draggable
MainFrame.Parent = ScreenGui

-- UICorner for MainFrame
local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0.05, 0) -- Rounded corners
MainFrameCorner.Parent = MainFrame

-- UIAspectRatioConstraint to maintain aspect ratio for the main frame
local AspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
AspectRatioConstraint.AspectRatio = 0.7 -- Adjust as needed to maintain desired shape
AspectRatioConstraint.Parent = MainFrame

-- Inner Content Area - Mimics the paper background
local InnerContentFrame = Instance.new("Frame")
InnerContentFrame.Name = "InnerContentFrame"
InnerContentFrame.Size = UDim2.new(1, -20, 1, -20) -- Slightly smaller than parent
InnerContentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
InnerContentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
InnerContentFrame.BackgroundColor3 = Color3.fromRGB(255, 239, 204) -- Orange-200 like
InnerContentFrame.BorderColor3 = Color3.fromRGB(255, 192, 128) -- Orange-300 like
InnerContentFrame.BorderSizePixel = 4
InnerContentFrame.Parent = MainFrame

-- UICorner for InnerContentFrame
local InnerContentFrameCorner = Instance.new("UICorner")
InnerContentFrameCorner.CornerRadius = UDim.new(0.04, 0)
InnerContentFrameCorner.Parent = InnerContentFrame

-- NEW: UIListLayout for vertical stacking of main content sections within InnerContentFrame
local InnerContentLayout = Instance.new("UIListLayout")
InnerContentLayout.Name = "InnerContentLayout"
InnerContentLayout.FillDirection = Enum.FillDirection.Vertical
InnerContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
InnerContentLayout.VerticalAlignment = Enum.VerticalAlignment.Top -- Align items from the top
InnerContentLayout.Padding = UDim.new(0, 5) -- Small padding between sections
InnerContentLayout.Parent = InnerContentFrame
InnerContentLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Ensure elements stack in order of creation/LayoutOrder

-- Header Frame (contains Title and Close button)
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Name = "HeaderFrame"
HeaderFrame.Size = UDim2.new(1, 0, 0.15, 0) -- Occupy 15% of parent height
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Parent = InnerContentFrame
HeaderFrame.LayoutOrder = 1 -- First element in the stack

-- UIListLayout for header elements (horizontal)
local HeaderLayout = Instance.new("UIListLayout")
HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
HeaderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
HeaderLayout.Padding = UDim.new(0, 10)
HeaderLayout.Parent = HeaderFrame

-- Title Label - Mimics the torn paper effect
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 102, 153) -- Pink-400 like
TitleLabel.BorderColor3 = Color3.fromRGB(255, 51, 102) -- Pink-500 like
TitleLabel.BorderSizePixel = 2
TitleLabel.Text = "Gift Opener"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.FredokaOne -- A playful font
TitleLabel.TextScaled = true
TitleLabel.TextWrapped = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
TitleLabel.ZIndex = 2
TitleLabel.Parent = HeaderFrame

-- UICorner for TitleLabel
local TitleLabelCorner = Instance.new("UICorner")
TitleLabelCorner.CornerRadius = UDim.new(0.1, 0)
TitleLabelCorner.Parent = TitleLabel

-- Close Button - Mimics the red 'X' button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0.15, 0, 0.9, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red-500 like
CloseButton.BorderColor3 = Color3.fromRGB(170, 0, 0) -- Red-700 like
CloseButton.BorderSizePixel = 2
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.FredokaOne
CloseButton.TextScaled = true
CloseButton.TextWrapped = true
CloseButton.TextXAlignment = Enum.TextXAlignment.Center
CloseButton.TextYAlignment = Enum.TextYAlignment.Center
CloseButton.ZIndex = 2
CloseButton.Parent = HeaderFrame

-- UICorner for CloseButton
local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(0.5, 0) -- Fully rounded
CloseButtonCorner.Parent = CloseButton

-- Currency Display Label
local CurrencyLabel = Instance.new("TextLabel")
CurrencyLabel.Name = "CurrencyLabel"
CurrencyLabel.Size = UDim2.new(1, 0, 0.08, 0) -- Takes 8% of InnerContentFrame height
CurrencyLabel.BackgroundTransparency = 1
CurrencyLabel.TextColor3 = Color3.fromRGB(0, 170, 0) -- Green color
CurrencyLabel.Font = Enum.Font.FredokaOne
CurrencyLabel.TextScaled = true
CurrencyLabel.TextWrapped = true
CurrencyLabel.TextXAlignment = Enum.TextXAlignment.Right -- Align text to the right
CurrencyLabel.TextYAlignment = Enum.TextYAlignment.Center -- Center text vertically
CurrencyLabel.Text = "Doubloons: Loading..."
CurrencyLabel.Rotation = -5 -- Slight rotation
CurrencyLabel.ZIndex = 3 -- Ensure it's on top
CurrencyLabel.Parent = InnerContentFrame
CurrencyLabel.LayoutOrder = 2 -- Second element in the stack

-- NEW: Auto Toggles and Buy Amount Frame
local AutoTogglesFrame = Instance.new("Frame")
AutoTogglesFrame.Name = "AutoTogglesFrame"
AutoTogglesFrame.Size = UDim2.new(1, 0, 0.25, 0) -- Occupy 25% of InnerContentFrame height
AutoTogglesFrame.BackgroundTransparency = 1
AutoTogglesFrame.Parent = InnerContentFrame
AutoTogglesFrame.LayoutOrder = 3 -- Third element in the stack

local AutoTogglesLayout = Instance.new("UIListLayout")
AutoTogglesLayout.FillDirection = Enum.FillDirection.Vertical
AutoTogglesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
AutoTogglesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
AutoTogglesLayout.Padding = UDim.new(0, 5) -- Padding between elements in this frame
AutoTogglesLayout.Parent = AutoTogglesFrame

-- Auto Buy Toggle Button (Moved)
local AutoBuyToggle = Instance.new("TextButton")
AutoBuyToggle.Name = "AutoBuyToggle"
AutoBuyToggle.Size = UDim2.new(0.7, 0, 0.3, 0) -- 30% height of AutoTogglesFrame
AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange for Off
AutoBuyToggle.BorderColor3 = Color3.fromRGB(200, 120, 0)
AutoBuyToggle.BorderSizePixel = 3
AutoBuyToggle.Text = "Auto Buy: OFF"
AutoBuyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBuyToggle.Font = Enum.Font.FredokaOne
AutoBuyToggle.TextScaled = true
AutoBuyToggle.TextWrapped = true
AutoBuyToggle.TextXAlignment = Enum.TextXAlignment.Center
AutoBuyToggle.TextYAlignment = Enum.TextYAlignment.Center
AutoBuyToggle.Parent = AutoTogglesFrame

-- UICorner for AutoBuyToggle
local AutoBuyToggleCorner = Instance.new("UICorner")
AutoBuyToggleCorner.CornerRadius = UDim.new(0.5, 0)
AutoBuyToggleCorner.Parent = AutoBuyToggle

-- Buy Amount TextBox (Moved)
local BuyAmountTextBox = Instance.new("TextBox")
BuyAmountTextBox.Name = "BuyAmountTextBox"
BuyAmountTextBox.Size = UDim2.new(0.7, 0, 0.3, 0) -- 30% height of AutoTogglesFrame
BuyAmountTextBox.PlaceholderText = "Amount to buy (e.g., 1)"
BuyAmountTextBox.Text = "1" -- Default buy amount
BuyAmountTextBox.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
BuyAmountTextBox.BorderColor3 = Color3.fromRGB(180, 180, 180)
BuyAmountTextBox.BorderSizePixel = 2
BuyAmountTextBox.TextColor3 = Color3.fromRGB(50, 50, 50)
BuyAmountTextBox.Font = Enum.Font.SourceSans
BuyAmountTextBox.TextScaled = true
BuyAmountTextBox.TextWrapped = true
BuyAmountTextBox.TextXAlignment = Enum.TextXAlignment.Center
BuyAmountTextBox.TextYAlignment = Enum.TextYAlignment.Center
BuyAmountTextBox.Visible = false -- Hidden by default
BuyAmountTextBox.Parent = AutoTogglesFrame

-- UICorner for BuyAmountTextBox
local BuyAmountTextBoxCorner = Instance.new("UICorner")
BuyAmountTextBoxCorner.CornerRadius = UDim.new(0.1, 0)
BuyAmountTextBoxCorner.Parent = BuyAmountTextBox

-- Auto Open Toggle Button (Moved)
local AutoOpenToggle = Instance.new("TextButton")
AutoOpenToggle.Name = "AutoOpenToggle"
AutoOpenToggle.Size = UDim2.new(0.7, 0, 0.3, 0) -- 30% height of AutoTogglesFrame
AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange for Off
AutoOpenToggle.BorderColor3 = Color3.fromRGB(200, 120, 0)
AutoOpenToggle.BorderSizePixel = 3
AutoOpenToggle.Text = "Auto Open: OFF"
AutoOpenToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoOpenToggle.Font = Enum.Font.FredokaOne
AutoOpenToggle.TextScaled = true
AutoOpenToggle.TextWrapped = true
AutoOpenToggle.TextXAlignment = Enum.TextXAlignment.Center
AutoOpenToggle.TextYAlignment = Enum.TextYAlignment.Center
AutoOpenToggle.Parent = AutoTogglesFrame

-- UICorner for AutoOpenToggle
local AutoOpenToggleCorner = Instance.new("UICorner")
AutoOpenToggleCorner.CornerRadius = UDim.new(0.5, 0)
AutoOpenToggleCorner.Parent = AutoOpenToggle


-- Gift Display Area (Adjusted Size for new layout)
local GiftDisplayFrame = Instance.new("Frame")
GiftDisplayFrame.Name = "GiftDisplayFrame"
GiftDisplayFrame.Size = UDim2.new(0.9, 0, 0.52, 0) -- Remaining height: 1 - 0.15 (Header) - 0.08 (Currency) - 0.25 (AutoToggles) = 0.52
GiftDisplayFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White background
GiftDisplayFrame.BorderColor3 = Color3.fromRGB(220, 220, 220) -- Gray-200 like
GiftDisplayFrame.BorderSizePixel = 2
GiftDisplayFrame.Parent = InnerContentFrame
GiftDisplayFrame.LayoutOrder = 4 -- Fourth element in the stack

-- UICorner for GiftDisplayFrame
local GiftDisplayFrameCorner = Instance.new("UICorner")
GiftDisplayFrameCorner.CornerRadius = UDim.new(0.03, 0)
GiftDisplayFrameCorner.Parent = GiftDisplayFrame

-- UIListLayout for vertical centering in GiftDisplayFrame
local GiftDisplayLayout = Instance.new("UIListLayout")
GiftDisplayLayout.FillDirection = Enum.FillDirection.Vertical
GiftDisplayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
GiftDisplayLayout.VerticalAlignment = Enum.VerticalAlignment.Center
GiftDisplayLayout.Padding = UDim.new(0, 10)
GiftDisplayLayout.Parent = GiftDisplayFrame

-- Gift Image
local GiftImage = Instance.new("ImageLabel")
GiftImage.Name = "GiftImage"
GiftImage.Size = UDim2.new(0.5, 0, 0.5, 0) -- Adjust size as needed
GiftImage.Image = "rbxassetid://83828532069910" -- Specific image ID from user's data
GiftImage.BackgroundTransparency = 1
GiftImage.Parent = GiftDisplayFrame

-- Gift Name/Message
local GiftNameMessage = Instance.new("TextLabel")
GiftNameMessage.Name = "GiftNameMessage"
GiftNameMessage.Size = UDim2.new(0.9, 0, 0.15, 0)
GiftNameMessage.BackgroundTransparency = 1
GiftNameMessage.Text = "Kelp Raider Box" -- Name from user's data
GiftNameMessage.TextColor3 = Color3.fromRGB(50, 50, 50)
GiftNameMessage.Font = Enum.Font.SourceSansBold
GiftNameMessage.TextScaled = true
GiftNameMessage.TextWrapped = true
GiftNameMessage.TextXAlignment = Enum.TextXAlignment.Center
GiftNameMessage.TextYAlignment = Enum.TextYAlignment.Center
GiftNameMessage.Parent = GiftDisplayFrame

-- Gift Cost
local GiftCostLabel = Instance.new("TextLabel")
GiftCostLabel.Name = "GiftCostLabel"
GiftCostLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
GiftCostLabel.BackgroundTransparency = 1
GiftCostLabel.Text = "Cost: 13000 Doubloons" -- Corrected currency
GiftCostLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
GiftCostLabel.Font = Enum.Font.SourceSans
GiftCostLabel.TextScaled = true
GiftCostLabel.TextWrapped = true
GiftCostLabel.TextXAlignment = Enum.TextXAlignment.Center
GiftCostLabel.TextYAlignment = Enum.TextYAlignment.Center
GiftCostLabel.Parent = GiftDisplayFrame

-- Open Gift Button (for manual opening)
local OpenGiftButton = Instance.new("TextButton")
OpenGiftButton.Name = "OpenGiftButton"
OpenGiftButton.Size = UDim2.new(0.7, 0, 0.2, 0)
OpenGiftButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green-500 like
OpenGiftButton.BorderColor3 = Color3.fromRGB(0, 100, 0) -- Green-700 like
OpenGiftButton.BorderSizePixel = 4
OpenGiftButton.Text = "Open Gift!"
OpenGiftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenGiftButton.Font = Enum.Font.FredokaOne
OpenGiftButton.TextScaled = true
OpenGiftButton.TextWrapped = true
OpenGiftButton.TextXAlignment = Enum.TextXAlignment.Center
OpenGiftButton.TextYAlignment = Enum.TextYAlignment.Center
OpenGiftButton.Parent = GiftDisplayFrame

-- UICorner for OpenGiftButton
local OpenGiftButtonCorner = Instance.new("UICorner")
OpenGiftButtonCorner.CornerRadius = UDim.new(0.5, 0) -- Fully rounded
OpenGiftButtonCorner.Parent = OpenGiftButton

-- Status Message Label for Auto Open/Buy
local AutoOpenStatusLabel = Instance.new("TextLabel")
AutoOpenStatusLabel.Name = "AutoOpenStatusLabel"
AutoOpenStatusLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
AutoOpenStatusLabel.BackgroundTransparency = 1
AutoOpenStatusLabel.Text = "" -- Will be updated by script
AutoOpenStatusLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
AutoOpenStatusLabel.Font = Enum.Font.SourceSans
AutoOpenStatusLabel.TextScaled = true
AutoOpenStatusLabel.TextWrapped = true
AutoOpenStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
AutoOpenStatusLabel.TextYAlignment = Enum.TextYAlignment.Center
AutoOpenStatusLabel.Parent = GiftDisplayFrame
AutoOpenStatusLabel.Visible = false -- Hidden by default

-- Global Variables for Auto Logic
local autoOpenEnabled = false
local autoBuyEnabled = false
local autoOpenThread: thread? = nil
local TARGET_GIFT_SPECIES_ID = "summerfest_2025_kelp_raider_box" -- Still used for inventory lookup
local readableTargetName = "Summerfest 2025 Kelp Raider Box"
local foundTargetGiftUniqueId = nil
local buyAmount: number = 1 -- Default buy amount

-- Possible items to get from a gift (this remains the same as it's the loot)
local possibleItems = {
    "Uncommon Pet (Dog)", "Rare Pet (Cat)", "Ultra-Rare Pet (Bee)",
    "Legendary Pet (Dragon)", "Common Toy (Frisbee)", "Uncommon Toy (Balloon)",
    "Rare Toy (Grappling Hook)", "Ultra-Rare Toy (Magic Carpet)",
    "Common Food (Apple)", "Uncommon Food (Pizza)", "Rare Food (Golden Egg)",
    "100 Bucks", "500 Bucks", "1000 Bucks"
}

-- TweenInfo for animations
local popInTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local bounceTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true) -- Infinite bounce
local fadeTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Function to animate the UI pop-in
local function animatePopIn()
    MainFrame.Size = UDim2.new(0.1, 0, 0.1, 0)
    MainFrame.Transparency = 1
    local tween = TweenService:Create(MainFrame, popInTweenInfo, {Size = UDim2.new(0.6, 0, 0.7, 0), Transparency = 0})
    tween:Play()
end

-- Function to animate the gift image bounce
local function animateGiftBounce()
    local bounceTween = TweenService:Create(GiftImage, bounceTweenInfo, {Position = UDim2.new(0.5, 0, 0.45, 0)})
    bounceTween:Play()
end

-- Function to reset the UI to its initial state (before opening/buying)
local function resetUIForNewGift()
    -- Destroy any previous result or opening messages
    if GiftDisplayFrame:FindFirstChild("ResultLabel") then
        GiftDisplayFrame.ResultLabel:Destroy()
    end
    if GiftDisplayFrame:FindFirstChild("OpeningMessage") then
        GiftDisplayFrame.OpeningMessage:Destroy()
    end
    if GiftDisplayFrame:FindFirstChild("OpenAnotherButton") then
        GiftDisplayFrame.OpenAnotherButton:Destroy()
    end

    GiftImage.Visible = true
    GiftNameMessage.Visible = true
    GiftCostLabel.Visible = true
    OpenGiftButton.Visible = true -- Manual open button becomes visible again
    AutoOpenToggle.Visible = true -- Auto open toggle visible
    AutoBuyToggle.Visible = true -- Auto buy toggle visible
    BuyAmountTextBox.Visible = autoBuyEnabled -- Show buy amount if auto-buy is enabled
    AutoOpenStatusLabel.Visible = false -- Hide status label initially

    animateGiftBounce() -- Restart bounce animation
end

-- Function to simulate opening a gift (manual trigger)
local function handleManualOpenGift()
    OpenGiftButton.Visible = false
    AutoOpenToggle.Visible = false
    AutoBuyToggle.Visible = false
    BuyAmountTextBox.Visible = false
    GiftImage.Visible = false
    GiftNameMessage.Visible = false
    GiftCostLabel.Visible = false
    AutoOpenStatusLabel.Visible = false

    local OpeningMessage = Instance.new("TextLabel")
    OpeningMessage.Name = "OpeningMessage"
    OpeningMessage.Size = UDim2.new(0.9, 0, 0.2, 0)
    OpeningMessage.BackgroundTransparency = 1
    OpeningMessage.Text = "Opening gift..."
    OpeningMessage.TextColor3 = Color3.fromRGB(100, 100, 100)
    OpeningMessage.Font = Enum.Font.SourceSansBold
    OpeningMessage.TextScaled = true
    OpeningMessage.TextWrapped = true
    OpeningMessage.TextXAlignment = Enum.TextXAlignment.Center
    OpeningMessage.TextYAlignment = Enum.TextYAlignment.Center
    OpeningMessage.Parent = GiftDisplayFrame

    task.wait(1.5)

    local randomIndex = math.random(1, #possibleItems)
    local openedItem = possibleItems[randomIndex]

    OpeningMessage.Text = "Congratulations! You got:"
    OpeningMessage.TextColor3 = Color3.fromRGB(0, 170, 0)

    local ResultLabel = Instance.new("TextLabel")
    ResultLabel.Name = "ResultLabel"
    ResultLabel.Size = UDim2.new(0.1, 0, 0.05, 0)
    ResultLabel.BackgroundTransparency = 1
    ResultLabel.Text = openedItem
    ResultLabel.TextColor3 = Color3.fromRGB(128, 0, 128)
    ResultLabel.Font = Enum.Font.FredokaOne
    ResultLabel.TextScaled = true
    ResultLabel.TextWrapped = true
    ResultLabel.TextXAlignment = Enum.TextXAlignment.Center
    ResultLabel.TextYAlignment = Enum.TextYAlignment.Center
    ResultLabel.Parent = GiftDisplayFrame

    local targetSize = UDim2.new(0.9, 0, 0.3, 0)
    local resultTween = TweenService:Create(ResultLabel, fadeTweenInfo, {Size = targetSize, Transparency = 0})
    resultTween:Play()

    local OpenAnotherButton = Instance.new("TextButton")
    OpenAnotherButton.Name = "OpenAnotherButton"
    OpenAnotherButton.Size = UDim2.new(0.8, 0, 0.2, 0)
    OpenAnotherButton.BackgroundColor3 = Color3.fromRGB(0, 102, 255)
    OpenAnotherButton.BorderColor3 = Color3.fromRGB(0, 51, 153)
    OpenAnotherButton.BorderSizePixel = 2
    OpenAnotherButton.Text = "Open Another Gift"
    OpenAnotherButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenAnotherButton.Font = Enum.Font.FredokaOne
    OpenAnotherButton.TextScaled = true
    OpenAnotherButton.TextWrapped = true
    OpenAnotherButton.TextXAlignment = Enum.TextXAlignment.Center
    OpenAnotherButton.TextYAlignment = Enum.TextYAlignment.Center
    OpenAnotherButton.Parent = GiftDisplayFrame

    local OpenAnotherButtonCorner = Instance.new("UICorner")
    OpenAnotherButtonCorner.CornerRadius = UDim.new(0.5, 0)
    OpenAnotherButtonCorner.Parent = OpenAnotherButton

    OpenAnotherButton.MouseButton1Click:Connect(function()
        resetUIForNewGift()
    end)
end

-- Function to fetch player data
local function waitForData()
    local ClientDataModule = nil
    local success, err = pcall(function()
        ClientDataModule = require(ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
    end)

    if not success then
        warn("Failed to load ClientData module:", err)
        return nil
    end

    local data = ClientDataModule.get_data()
    while not data do
        task.wait(0.5)
        data = ClientDataModule.get_data()
    end
    return data
end

-- Main auto-open/auto-buy loop
local function autoLogicLoop()
    -- Ensure UI is in auto-mode visuals
    OpenGiftButton.Visible = false
    GiftImage.Visible = false
    GiftNameMessage.Visible = false
    GiftCostLabel.Visible = false
    AutoOpenStatusLabel.Visible = true
    AutoBuyToggle.Visible = true -- Ensure auto-buy toggle is visible
    BuyAmountTextBox.Visible = autoBuyEnabled -- Keep visible if auto-buy is on

    while autoOpenEnabled do -- Loop continues as long as auto-open is enabled
        AutoOpenStatusLabel.Text = "Fetching player data..."
        local data = waitForData()
        if not data then
            AutoOpenStatusLabel.Text = "Error: Could not load player data. Retrying..."
            task.wait(2)
            continue
        end

        local localPlayer = game:GetService("Players").LocalPlayer -- Re-get LocalPlayer for robustness
        local playerData = data[localPlayer.Name]

        if not playerData or not playerData.inventory or not playerData.inventory.gifts then
            AutoOpenStatusLabel.Text = "Error: Inventory data not found. Retrying..."
            task.wait(2)
            continue
        end

        foundTargetGiftUniqueId = nil
        local playerGifts = playerData.inventory.gifts

        if next(playerGifts) then
            for uniqueId, giftData in pairs(playerGifts) do
                local speciesId = giftData.id
                if speciesId == TARGET_GIFT_SPECIES_ID then
                    foundTargetGiftUniqueId = uniqueId
                    break
                end
            end
        end

        if not foundTargetGiftUniqueId and autoBuyEnabled then
            AutoOpenStatusLabel.Text = "Gift not found. Attempting to buy " .. buyAmount .. "..."
            local ShopAPI = nil
            local successAPI, errAPI = pcall(function()
                ShopAPI = ReplicatedStorage:WaitForChild("API"):WaitForChild("ShopAPI/BuyItem")
            end)

            if not successAPI then
                AutoOpenStatusLabel.Text = "Error: ShopAPI not found. Retrying..."
                warn("Failed to load ShopAPI:", errAPI)
                task.wait(3)
                continue
            end

            -- User's provided buying logic starts here
            local args = {
                "gifts",
                "summerfest_2025_kelp_raider_box",
                {
                    buy_count = buyAmount
                }
            }

            print("--- AUTO BUY ATTEMPT ---")
            print("Sending args to ShopAPI/BuyItem:", unpack(args))

            local successBuy, resultBuy = pcall(function()
                return ShopAPI:InvokeServer(unpack(args))
            end)

            print("ShopAPI/BuyItem InvokeServer pcall result: success=", successBuy, " raw_result=", tostring(resultBuy))

            if successBuy then
                if resultBuy == true then
                    AutoOpenStatusLabel.Text = "Successfully bought " .. buyAmount .. " " .. readableTargetName .. "(s)!"
                    task.wait(1) -- Short wait after buying to allow inventory update
                    -- Loop will re-check inventory in next iteration and should find the gift
                else
                    AutoOpenStatusLabel.Text = "Failed to buy gift: " .. tostring(resultBuy)
                    warn("BuyItem failed (server returned non-true):", tostring(resultBuy))
                    task.wait(3) -- Wait before trying again after a failed purchase
                    continue
                end
            else
                AutoOpenStatusLabel.Text = "Error during buy: " .. tostring(resultBuy)
                warn("Buy API call failed:", tostring(resultBuy))
                task.wait(3)
                continue
            end
            -- User's provided buying logic ends here
        end

        -- Re-check inventory after potential purchase or if auto-buy is off
        -- This ensures we always try to open if a gift is available
        if autoOpenEnabled then -- Double check if auto-open is still enabled after potential wait
            data = waitForData() -- Re-fetch data to get updated inventory
            if data then
                playerData = data[localPlayer.Name]
                if playerData and playerData.inventory and playerData.inventory.gifts then
                    playerGifts = playerData.inventory.gifts
                    foundTargetGiftUniqueId = nil -- Reset before re-searching
                    if next(playerGifts) then
                        for uniqueId, giftData in pairs(playerGifts) do
                            local speciesId = giftData.id
                            if speciesId == TARGET_GIFT_SPECIES_ID then
                                foundTargetGiftUniqueId = uniqueId
                                break
                            end
                        end
                    end
                end
            end
        end


        if foundTargetGiftUniqueId and autoOpenEnabled then -- Proceed to open if found and auto-open is still on
            AutoOpenStatusLabel.Text = "Found " .. readableTargetName .. "! Auto-opening..."
            print("\n--- AUTO OPEN ATTEMPT ---")
            print("Attempting to Invoke LootBoxAPI/ExchangeItemForReward for: " .. readableTargetName)
            
            local LootBoxAPI = nil
            local successLootAPI, errLootAPI = pcall(function()
                LootBoxAPI = ReplicatedStorage:WaitForChild("API"):WaitForChild("LootBoxAPI/ExchangeItemForReward")
            end)

            if not successLootAPI then
                AutoOpenStatusLabel.Text = "Error: LootBoxAPI not found. Retrying..."
                warn("Failed to load LootBoxAPI:", errLootAPI)
                task.wait(2)
                continue
            end

            local successInvoke, result = pcall(function()
                return LootBoxAPI:InvokeServer(TARGET_GIFT_SPECIES_ID, foundTargetGiftUniqueId)
            end)

            print("LootBoxAPI/ExchangeItemForReward InvokeServer pcall result: success=", successInvoke, " raw_result=", tostring(result))

            if successInvoke then
                local displayResultText = ""
                if type(result) == "table" then
                    displayResultText = "Auto-opened! You got:\n"
                    for k, v in pairs(result) do
                        displayResultText = displayResultText .. tostring(k) .. ": " .. tostring(v) .. "\n"
                    end
                else
                    displayResultText = "Auto-opened! You got:\n" .. tostring(result)
                end
                print(displayResultText) -- Print to console
                
                -- Update UI for auto-opened result
                AutoOpenToggle.Visible = false
                AutoBuyToggle.Visible = false
                BuyAmountTextBox.Visible = false
                AutoOpenStatusLabel.Visible = false

                local ResultLabel = Instance.new("TextLabel")
                ResultLabel.Name = "ResultLabel"
                ResultLabel.Size = UDim2.new(0.1, 0, 0.05, 0)
                ResultLabel.BackgroundTransparency = 1
                ResultLabel.Text = displayResultText -- Set text from server response
                ResultLabel.TextColor3 = Color3.fromRGB(128, 0, 128)
                ResultLabel.Font = Enum.Font.FredokaOne
                ResultLabel.TextScaled = true
                ResultLabel.TextWrapped = true
                ResultLabel.TextXAlignment = Enum.TextXAlignment.Center
                ResultLabel.TextYAlignment = Enum.TextYAlignment.Center
                ResultLabel.Parent = GiftDisplayFrame

                local targetSize = UDim2.new(0.9, 0, 0.3, 0)
                local resultTween = TweenService:Create(ResultLabel, fadeTweenInfo, {Size = targetSize, Transparency = 0})
                resultTween:Play()

                task.wait(3) -- Wait for a few seconds to display the result before searching again
                
                ResultLabel:Destroy()
                AutoOpenToggle.Visible = true
                AutoBuyToggle.Visible = true
                BuyAmountTextBox.Visible = autoBuyEnabled
                AutoOpenStatusLabel.Visible = true

            else
                warn("InvokeServer call failed! Error: " .. tostring(result))
                AutoOpenStatusLabel.Text = "Failed to open gift: " .. tostring(result)
                task.wait(3) -- Wait before trying again after failure
            end
            task.wait(1) -- Small delay after an attempt (success or failure) before next loop iteration
        else
            AutoOpenStatusLabel.Text = readableTargetName .. " not found. Waiting..."
            task.wait(2) -- Wait before checking again if not found
        end
    end
    AutoOpenStatusLabel.Text = "Auto Open/Buy: Stopped."
    resetUIForNewGift() -- Reset UI to initial state when auto-open stops
end

-- Connect button events
OpenGiftButton.MouseButton1Click:Connect(handleManualOpenGift)
CloseButton.MouseButton1Click:Connect(function()
    -- Stop auto-open loop if active before closing
    if autoOpenThread then
        task.cancel(autoOpenThread)
        autoOpenThread = nil
    end
    autoOpenEnabled = false -- Ensure the flag is false
    autoBuyEnabled = false -- Also disable auto-buy on close

    -- Animate UI fade out before destroying
    local fadeOutTween = TweenService:Create(MainFrame, fadeTweenInfo, {Transparency = 1})
    fadeOutTween:Play()
    fadeOutTween.Completed:Wait()
    ScreenGui:Destroy() -- Destroy the entire UI
end)

-- Auto Open Toggle Button Click Handler
AutoOpenToggle.MouseButton1Click:Connect(function()
    autoOpenEnabled = not autoOpenEnabled -- Toggle the state

    if autoOpenEnabled then
        AutoOpenToggle.Text = "Auto Open: ON"
        AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green for On
        
        -- Hide manual elements and show auto-open/buy status elements
        OpenGiftButton.Visible = false
        GiftImage.Visible = false
        GiftNameMessage.Visible = false
        GiftCostLabel.Visible = false
        AutoOpenStatusLabel.Visible = true
        AutoBuyToggle.Visible = true -- Ensure auto-buy toggle is visible
        BuyAmountTextBox.Visible = autoBuyEnabled -- Show buy amount if auto-buy is enabled

        -- Clean up any previous result/opening messages
        if GiftDisplayFrame:FindFirstChild("ResultLabel") then GiftDisplayFrame.ResultLabel:Destroy() end
        if GiftDisplayFrame:FindFirstChild("OpeningMessage") then GiftDisplayFrame.OpeningMessage:Destroy() end
        if GiftDisplayFrame:FindFirstChild("OpenAnotherButton") then GiftDisplayFrame.OpenAnotherButton:Destroy() end

        AutoOpenStatusLabel.Text = "Starting auto open/buy..."
        autoOpenThread = task.spawn(autoLogicLoop) -- Start the main auto loop
    else
        AutoOpenToggle.Text = "Auto Open: OFF"
        AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange for Off
        
        AutoOpenStatusLabel.Text = "Auto Open/Buy: Stopping..."
        if autoOpenThread then
            task.cancel(autoOpenThread) -- Stop the running loop
            autoOpenThread = nil
        end
        -- The autoLogicLoop itself will set "Auto Open/Buy: Stopped." and call resetUIForNewGift()
        -- after it fully terminates, ensuring a clean state.
    end
end)

-- Auto Buy Toggle Button Click Handler
AutoBuyToggle.MouseButton1Click:Connect(function()
    autoBuyEnabled = not autoBuyEnabled -- Toggle the state

    if autoBuyEnabled then
        AutoBuyToggle.Text = "Auto Buy: ON"
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green for On
        BuyAmountTextBox.Visible = true -- Show buy amount input
    else
        AutoBuyToggle.Text = "Auto Buy: OFF"
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange for Off
        BuyAmountTextBox.Visible = false -- Hide buy amount input
    end
end)

-- Update buyAmount and filter input when TextBox text changes
BuyAmountTextBox.Changed:Connect(function(property)
    if property == "Text" then
        -- Filter out non-numeric characters
        local filteredText = BuyAmountTextBox.Text:gsub("[^0-9]", "")
        
        -- Handle empty string case explicitly to prevent basic_string error
        if filteredText == "" then
            buyAmount = 1
            -- Use a pcall here to defensively set the text, as this is the problematic line
            local success, err = pcall(function()
                BuyAmountTextBox.Text = "1"
            end)
            if not success then
                warn("Error setting BuyAmountTextBox.Text to '1':", err)
            end
            return -- Exit the function early
        end

        -- If not empty, proceed with normal parsing and assignment
        -- Use a pcall here too for robustness
        local success, err = pcall(function()
            BuyAmountTextBox.Text = filteredText 
        end)
        if not success then
            warn("Error setting BuyAmountTextBox.Text to filteredText:", err)
        end

        local newAmount = tonumber(filteredText)
        if newAmount and newAmount >= 1 then
            buyAmount = math.floor(newAmount) -- Ensure it's an integer
        else
            -- This case should ideally be caught by the empty string check, but as a fallback
            buyAmount = 1
            -- Use a pcall here to defensively set the text
            local successFallback, errFallback = pcall(function()
                BuyAmountTextBox.Text = "1" -- Ensure a valid number is always displayed
            end)
            if not successFallback then
                warn("Error setting BuyAmountTextBox.Text to '1' in fallback:", errFallback)
            end
        end
    end
end)

-- Function to update the currency display
local function updateCurrencyDisplay()
    local currencyAmountLabel = playerGui:FindFirstChild("AltCurrencyIndicatorApp")
        and playerGui.AltCurrencyIndicatorApp:FindFirstChild("CurrencyIndicator")
        and playerGui.AltCurrencyIndicatorApp.CurrencyIndicator:FindFirstChild("Container")
        and playerGui.AltCurrencyIndicatorApp.CurrencyIndicator.Container:FindFirstChild("Amount")

    if currencyAmountLabel and currencyAmountLabel:IsA("TextLabel") then
        CurrencyLabel.Text = "Doubloons: " .. currencyAmountLabel.Text
    else
        CurrencyLabel.Text = "Doubloons: N/A"
        warn("Could not find AltCurrencyIndicatorApp.CurrencyIndicator.Container.Amount")
    end
end

-- Initial call to update currency display
updateCurrencyDisplay()

-- Listen for changes to the currency amount
local currencyAmountLabel = playerGui:FindFirstChild("AltCurrencyIndicatorApp")
    and playerGui.AltCurrencyIndicatorApp:FindFirstChild("CurrencyIndicator")
    and playerGui.AltCurrencyIndicatorApp.CurrencyIndicator:FindFirstChild("Container")
    and playerGui.AltCurrencyIndicatorApp.CurrencyIndicator.Container:FindFirstChild("Amount")

if currencyAmountLabel and currencyAmountLabel:IsA("TextLabel") then
    currencyAmountLabel:GetPropertyChangedSignal("Text"):Connect(updateCurrencyDisplay)
else
    warn("Could not connect to currency TextLabel's PropertyChangedSignal. Path might be incorrect or element not a TextLabel.")
end

-- Initial animations when the UI loads
animatePopIn()
animateGiftBounce()

-- Ensure the UI is visible initially
MainFrame.Visible = true

-- Debug print to confirm OpenGiftButton text at initialization
print("OpenGiftButton.Text at initialization: " .. OpenGiftButton.Text)
