--!strict
-- This script creates a simple Gift Opener UI in Roblox and handles the gift opening and buying logic.
-- It now includes auto-open and auto-buy features with notifications.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Player
local player = Players.LocalPlayer
if not player then
    warn("Player not found. This script should be run on the client.")
    return
end

-- UI Setup
local playerGui = player:WaitForChild("PlayerGui")

local ScreenGui: ScreenGui
local guiName = "GiftOpenerUI"

local existingGui = playerGui:FindFirstChild(guiName)
if existingGui and existingGui:IsA("ScreenGui") then
    ScreenGui = existingGui
else
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = playerGui
end

ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(184, 106, 0)
MainFrame.BorderColor3 = Color3.fromRGB(120, 68, 0)
MainFrame.BorderSizePixel = 8
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0.05, 0)
MainFrameCorner.Parent = MainFrame

local AspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
AspectRatioConstraint.AspectRatio = 0.7
AspectRatioConstraint.Parent = MainFrame

local InnerContentFrame = Instance.new("Frame")
InnerContentFrame.Name = "InnerContentFrame"
InnerContentFrame.Size = UDim2.new(1, -20, 1, -20)
InnerContentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
InnerContentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
InnerContentFrame.BackgroundColor3 = Color3.fromRGB(255, 239, 204)
InnerContentFrame.BorderColor3 = Color3.fromRGB(255, 192, 128)
InnerContentFrame.BorderSizePixel = 4
InnerContentFrame.Parent = MainFrame

local InnerContentFrameCorner = Instance.new("UICorner")
InnerContentFrameCorner.CornerRadius = UDim.new(0.04, 0)
InnerContentFrameCorner.Parent = InnerContentFrame

local InnerContentLayout = Instance.new("UIListLayout")
InnerContentLayout.Name = "InnerContentLayout"
InnerContentLayout.FillDirection = Enum.FillDirection.Vertical
InnerContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
InnerContentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
InnerContentLayout.Padding = UDim.new(0, 5)
InnerContentLayout.Parent = InnerContentFrame
InnerContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Name = "HeaderFrame"
HeaderFrame.Size = UDim2.new(1, 0, 0.15, 0)
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Parent = InnerContentFrame
HeaderFrame.LayoutOrder = 1

local HeaderLayout = Instance.new("UIListLayout")
HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
HeaderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
HeaderLayout.Padding = UDim.new(0, 10)
HeaderLayout.Parent = HeaderFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 102, 153)
TitleLabel.BorderColor3 = Color3.fromRGB(255, 51, 102)
TitleLabel.BorderSizePixel = 2
TitleLabel.Text = "Gift Opener"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.FredokaOne
TitleLabel.TextScaled = true
TitleLabel.TextWrapped = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
TitleLabel.ZIndex = 2
TitleLabel.Parent = HeaderFrame

local TitleLabelCorner = Instance.new("UICorner")
TitleLabelCorner.CornerRadius = UDim.new(0.1, 0)
TitleLabelCorner.Parent = TitleLabel

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0.15, 0, 0.9, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.BorderColor3 = Color3.fromRGB(170, 0, 0)
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

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(0.5, 0)
CloseButtonCorner.Parent = CloseButton

local ModeControlFrame = Instance.new("Frame")
ModeControlFrame.Name = "ModeControlFrame"
ModeControlFrame.Size = UDim2.new(1, 0, 0.08, 0)
ModeControlFrame.BackgroundTransparency = 1
ModeControlFrame.Parent = InnerContentFrame
ModeControlFrame.LayoutOrder = 1.5

local ModeControlLayout = Instance.new("UIListLayout")
ModeControlLayout.FillDirection = Enum.FillDirection.Horizontal
ModeControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ModeControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ModeControlLayout.Padding = UDim.new(0, 10)
ModeControlLayout.Parent = ModeControlFrame

local PrevModeButton = Instance.new("TextButton")
PrevModeButton.Name = "PrevModeButton"
PrevModeButton.Size = UDim2.new(0.15, 0, 0.8, 0)
PrevModeButton.BackgroundColor3 = Color3.fromRGB(66, 153, 225)
PrevModeButton.BorderColor3 = Color3.fromRGB(49, 130, 206)
PrevModeButton.BorderSizePixel = 2
PrevModeButton.Text = "←"
PrevModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevModeButton.Font = Enum.Font.FredokaOne
PrevModeButton.TextScaled = true
PrevModeButton.Parent = ModeControlFrame
local PrevModeButtonCorner = Instance.new("UICorner")
PrevModeButtonCorner.CornerRadius = UDim.new(0.5, 0)
PrevModeButtonCorner.Parent = PrevModeButton

local ModeDisplayLabel = Instance.new("TextLabel")
ModeDisplayLabel.Name = "ModeDisplayLabel"
ModeDisplayLabel.Size = UDim2.new(0.6, 0, 1, 0)
ModeDisplayLabel.BackgroundTransparency = 1
ModeDisplayLabel.TextColor3 = Color3.fromRGB(99, 179, 237)
ModeDisplayLabel.Font = Enum.Font.FredokaOne
ModeDisplayLabel.TextScaled = true
ModeDisplayLabel.TextWrapped = true
ModeDisplayLabel.TextXAlignment = Enum.TextXAlignment.Center
ModeDisplayLabel.TextYAlignment = Enum.TextYAlignment.Center
ModeDisplayLabel.Text = "Loading Mode..."
ModeDisplayLabel.Parent = ModeControlFrame

local NextModeButton = Instance.new("TextButton")
NextModeButton.Name = "NextModeButton"
NextModeButton.Size = UDim2.new(0.15, 0, 0.8, 0)
NextModeButton.BackgroundColor3 = Color3.fromRGB(66, 153, 225)
NextModeButton.BorderColor3 = Color3.fromRGB(49, 130, 206)
NextModeButton.BorderSizePixel = 2
NextModeButton.Text = "→"
NextModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NextModeButton.Font = Enum.Font.FredokaOne
NextModeButton.TextScaled = true
NextModeButton.Parent = ModeControlFrame
local NextModeButtonCorner = Instance.new("UICorner")
NextModeButtonCorner.CornerRadius = UDim.new(0.5, 0)
NextModeButtonCorner.Parent = NextModeButton


local CurrencyLabel = Instance.new("TextLabel")
CurrencyLabel.Name = "CurrencyLabel"
CurrencyLabel.Size = UDim2.new(1, 0, 0.08, 0)
CurrencyLabel.BackgroundTransparency = 1
CurrencyLabel.TextColor3 = Color3.fromRGB(0, 170, 0)
CurrencyLabel.Font = Enum.Font.FredokaOne
CurrencyLabel.TextScaled = true
CurrencyLabel.TextWrapped = true
CurrencyLabel.TextXAlignment = Enum.TextXAlignment.Right
CurrencyLabel.TextYAlignment = Enum.TextYAlignment.Center
CurrencyLabel.Text = "Doubloons: Loading..."
CurrencyLabel.Rotation = -5
CurrencyLabel.ZIndex = 3
CurrencyLabel.Parent = InnerContentFrame
CurrencyLabel.LayoutOrder = 2.5

local AutoTogglesFrame = Instance.new("Frame")
AutoTogglesFrame.Name = "AutoTogglesFrame"
AutoTogglesFrame.Size = UDim2.new(1, 0, 0.25, 0)
AutoTogglesFrame.BackgroundTransparency = 1
AutoTogglesFrame.Parent = InnerContentFrame
AutoTogglesFrame.LayoutOrder = 3

local AutoTogglesLayout = Instance.new("UIListLayout")
AutoTogglesLayout.FillDirection = Enum.FillDirection.Vertical
AutoTogglesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
AutoTogglesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
AutoTogglesLayout.Padding = UDim.new(0, 5)
AutoTogglesLayout.Parent = AutoTogglesFrame

local AutoBuyToggle = Instance.new("TextButton")
AutoBuyToggle.Name = "AutoBuyToggle"
AutoBuyToggle.Size = UDim2.new(0.7, 0, 0.3, 0)
AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
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

local AutoBuyToggleCorner = Instance.new("UICorner")
AutoBuyToggleCorner.CornerRadius = UDim.new(0.5, 0)
AutoBuyToggleCorner.Parent = AutoBuyToggle

local BuyAmountTextBox = Instance.new("TextBox")
BuyAmountTextBox.Name = "BuyAmountTextBox"
BuyAmountTextBox.Size = UDim2.new(0.7, 0, 0.3, 0)
BuyAmountTextBox.PlaceholderText = "Amount to buy (e.g., 1)"
BuyAmountTextBox.Text = "1"
BuyAmountTextBox.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
BuyAmountTextBox.BorderColor3 = Color3.fromRGB(180, 180, 180)
BuyAmountTextBox.BorderSizePixel = 2
BuyAmountTextBox.TextColor3 = Color3.fromRGB(50, 50, 50)
BuyAmountTextBox.Font = Enum.Font.SourceSans
BuyAmountTextBox.TextScaled = true
BuyAmountTextBox.TextWrapped = true
BuyAmountTextBox.TextXAlignment = Enum.TextXAlignment.Center
BuyAmountTextBox.TextYAlignment = Enum.TextYAlignment.Center
BuyAmountTextBox.Visible = false
BuyAmountTextBox.Parent = AutoTogglesFrame

local BuyAmountTextBoxCorner = Instance.new("UICorner")
BuyAmountTextBoxCorner.CornerRadius = UDim.new(0.1, 0)
BuyAmountTextBoxCorner.Parent = BuyAmountTextBox

local AutoOpenToggle = Instance.new("TextButton")
AutoOpenToggle.Name = "AutoOpenToggle"
AutoOpenToggle.Size = UDim2.new(0.7, 0, 0.3, 0)
AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
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

local AutoOpenToggleCorner = Instance.new("UICorner")
AutoOpenToggleCorner.CornerRadius = UDim.new(0.5, 0)
AutoOpenToggleCorner.Parent = AutoOpenToggle


local GiftDisplayFrame = Instance.new("Frame")
GiftDisplayFrame.Name = "GiftDisplayFrame"
GiftDisplayFrame.Size = UDim2.new(0.9, 0, 0.44, 0)
GiftDisplayFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GiftDisplayFrame.BorderColor3 = Color3.fromRGB(220, 220, 220)
GiftDisplayFrame.BorderSizePixel = 2
GiftDisplayFrame.Parent = InnerContentFrame
GiftDisplayFrame.LayoutOrder = 4

local GiftDisplayFrameCorner = Instance.new("UICorner")
GiftDisplayFrameCorner.CornerRadius = UDim.new(0.03, 0)
GiftDisplayFrameCorner.Parent = GiftDisplayFrame

local GiftDisplayLayout = Instance.new("UIListLayout")
GiftDisplayLayout.FillDirection = Enum.FillDirection.Vertical
GiftDisplayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
GiftDisplayLayout.VerticalAlignment = Enum.VerticalAlignment.Center
GiftDisplayLayout.Padding = UDim.new(0, 10)
GiftDisplayLayout.Parent = GiftDisplayFrame

local GiftImage = Instance.new("ImageLabel")
GiftImage.Name = "GiftImage"
GiftImage.Size = UDim2.new(0.5, 0, 0.5, 0)
GiftImage.Image = "rbxassetid://83828532069910"
GiftImage.BackgroundTransparency = 1
GiftImage.Parent = GiftDisplayFrame

local GiftNameMessage = Instance.new("TextLabel")
GiftNameMessage.Name = "GiftNameMessage"
GiftNameMessage.Size = UDim2.new(0.9, 0, 0.15, 0)
GiftNameMessage.BackgroundTransparency = 1
GiftNameMessage.Text = "Kelp Raider Box"
GiftNameMessage.TextColor3 = Color3.fromRGB(50, 50, 50)
GiftNameMessage.Font = Enum.Font.SourceSansBold
GiftNameMessage.TextScaled = true
GiftNameMessage.TextWrapped = true
GiftNameMessage.TextXAlignment = Enum.TextXAlignment.Center
GiftNameMessage.TextYAlignment = Enum.TextYAlignment.Center
GiftNameMessage.Parent = GiftDisplayFrame

local GiftCostLabel = Instance.new("TextLabel")
GiftCostLabel.Name = "GiftCostLabel"
GiftCostLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
GiftCostLabel.BackgroundTransparency = 1
GiftCostLabel.Text = "Cost: 13000 Doubloons"
GiftCostLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
GiftCostLabel.Font = Enum.Font.SourceSans
GiftCostLabel.TextScaled = true
GiftCostLabel.TextWrapped = true
GiftCostLabel.TextXAlignment = Enum.TextXAlignment.Center
GiftCostLabel.TextYAlignment = Enum.TextYAlignment.Center
GiftCostLabel.Parent = GiftDisplayFrame

local OpenGiftButton = Instance.new("TextButton")
OpenGiftButton.Name = "OpenGiftButton"
OpenGiftButton.Size = UDim2.new(0.7, 0, 0.2, 0)
OpenGiftButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
OpenGiftButton.BorderColor3 = Color3.fromRGB(0, 100, 0)
OpenGiftButton.BorderSizePixel = 4
OpenGiftButton.Text = "Open Gift!"
OpenGiftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenGiftButton.Font = Enum.Font.FredokaOne
OpenGiftButton.TextScaled = true
OpenGiftButton.TextWrapped = true
OpenGiftButton.TextXAlignment = Enum.TextXAlignment.Center
OpenGiftButton.TextYAlignment = Enum.TextYAlignment.Center
OpenGiftButton.Parent = GiftDisplayFrame

local OpenGiftButtonCorner = Instance.new("UICorner")
OpenGiftButtonCorner.CornerRadius = UDim.new(0.5, 0)
OpenGiftButtonCorner.Parent = OpenGiftButton

local AutoOpenStatusLabel = Instance.new("TextLabel")
AutoOpenStatusLabel.Name = "AutoOpenStatusLabel"
AutoOpenStatusLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
AutoOpenStatusLabel.BackgroundTransparency = 1
AutoOpenStatusLabel.Text = ""
AutoOpenStatusLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
AutoOpenStatusLabel.Font = Enum.Font.SourceSans
AutoOpenStatusLabel.TextScaled = true
AutoOpenStatusLabel.TextWrapped = true
AutoOpenStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
AutoOpenStatusLabel.TextYAlignment = Enum.TextYAlignment.Center
AutoOpenStatusLabel.Parent = GiftDisplayFrame
AutoOpenStatusLabel.Visible = false

-- Global Variables for Auto Logic
local autoOpenEnabled = false
local autoBuyEnabled = false
local autoOpenThread: thread? = nil
local TARGET_GIFT_SPECIES_ID = "halloween_2025_sticker_pack" -- Fixed to Sticker Pack
local readableTargetName = "halloween_2025_sticker_pack"          -- Fixed to Sticker Pack
local foundTargetGiftUniqueId = nil
local buyAmount: number = 1




local possibleItems = {
    "Uncommon Pet (Dog)", "Rare Pet (Cat)", "Ultra-Rare Pet (Bee)",
    "Legendary Pet (Dragon)", "Common Toy (Frisbee)", "Uncommon Toy (Balloon)",
    "Rare Toy (Grappling Hook)", "Ultra-Rare Toy (Magic Carpet)",
    "Common Food (Apple)", "Uncommon Food (Pizza)", "Rare Food (Golden Egg)",
    "100 Bucks", "500 Bucks", "1000 Bucks"
}

local popInTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local bounceTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local fadeTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function animatePopIn()
    MainFrame.Size = UDim2.new(0.1, 0, 0.1, 0)
    MainFrame.Transparency = 1
    local tween = TweenService:Create(MainFrame, popInTweenInfo, {Size = UDim2.new(0.6, 0, 0.7, 0), Transparency = 0})
    tween:Play()
end

local function animateGiftBounce()
    local bounceTween = TweenService:Create(GiftImage, bounceTweenInfo, {Position = UDim2.new(0.5, 0, 0.45, 0)})
    bounceTween:Play()
end

local function resetUIForNewGift()
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
    OpenGiftButton.Visible = true

    AutoOpenToggle.Visible = false
    AutoBuyToggle.Visible = false
    BuyAmountTextBox.Visible = false
    AutoOpenStatusLabel.Visible = false

    animateGiftBounce()
end

local function handleManualOpenGift()
    OpenGiftButton.Visible = false
    GiftImage.Visible = false
    GiftNameMessage.Visible = false
    GiftCostLabel.Visible = false

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

local function autoLogicLoop()
    OpenGiftButton.Visible = false
    GiftImage.Visible = true
    GiftNameMessage.Visible = true
    GiftCostLabel.Visible = true
    AutoOpenStatusLabel.Visible = true
    AutoOpenToggle.Visible = true
    AutoBuyToggle.Visible = true
    BuyAmountTextBox.Visible = autoBuyEnabled

    local apiFolder = ReplicatedStorage:WaitForChild("API", 10)
    if not apiFolder then warn("API folder not found in ReplicatedStorage!"); return end

    local ToolUseStartRemote = apiFolder:WaitForChild("ToolAPI/ServerUseTool", 10)
    local LootBoxExchangeRemote = apiFolder:WaitForChild("LootBoxAPI/ExchangeItemForReward", 10)
    local ShopAPI = apiFolder:WaitForChild("ShopAPI/BuyItem", 10)

    if not ToolUseStartRemote then warn("ToolAPI/ServerUseTool not found!"); return end
    if not LootBoxExchangeRemote then warn("LootBoxAPI/ExchangeItemForReward not found!"); return end
    if not ShopAPI then warn("ShopAPI/BuyItem not found!"); return end

    local startUniqueId = nil
    local tempServerData = waitForData()
    local tempPlayerData = tempServerData[player.Name]
    if tempPlayerData and tempPlayerData.inventory then
        for _, itemsInThisCategory in pairs(tempPlayerData.inventory) do
            for uniqueId, itemData in pairs(itemsInThisCategory) do
                local currentItemDisplayName = itemData.name or itemData.display_name or itemData.id
                if currentItemDisplayName == readableTargetName then
                    startUniqueId = uniqueId
                    break
                end
            end
            if startUniqueId then break end
        end
    end

    if startUniqueId then
        local toolUseStartArgs = {startUniqueId, "START"}
        print("    Sending global ToolAPI/ServerUseTool 'START'...")
        pcall(ToolUseStartRemote.FireServer, ToolUseStartRemote, unpack(toolUseStartArgs))
    else
        warn("    Could not find a '" .. readableTargetName .. "' to use for global START command.")
    end

    while autoOpenEnabled do
        AutoOpenStatusLabel.Text = "Fetching player data..."
        local data = waitForData()
        if not data then
            AutoOpenStatusLabel.Text = "Error: Could not load player data. Retrying..."
            task.wait(2)
            continue
        end

        local localPlayer = Players.LocalPlayer
        local playerData = data[localPlayer.Name]

        if not playerData or not playerData.inventory or not playerData.inventory.gifts then
            AutoOpenStatusLabel.Text = "Error: Inventory data not found. Retrying..."
            task.wait(2)
            continue
        end

        local foundTargetGiftUniqueId = nil
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

            local args = {
                "gifts",
                TARGET_GIFT_SPECIES_ID,
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
                if resultBuy == "success" then
                    AutoOpenStatusLabel.Text = "Successfully bought " .. buyAmount .. " " .. readableTargetName .. "(s)!"
                    task.wait(1)
                else
                    AutoOpenStatusLabel.Text = "Failed to buy gift: " .. tostring(resultBuy)
                    warn("BuyItem failed (server returned non-true):", tostring(resultBuy))
                    task.wait(3)
                    continue
                end
            else
                AutoOpenStatusLabel.Text = "Error during buy: " .. tostring(resultBuy)
                warn("Buy API call failed:", tostring(resultBuy))
                task.wait(3)
                continue
            end
        end

        if autoOpenEnabled then
            data = waitForData()
            if data then
                playerData = data[localPlayer.Name]
                if playerData and playerData.inventory and playerData.inventory.gifts then
                    playerGifts = playerData.inventory.gifts
                    foundTargetGiftUniqueId = nil
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

        if foundTargetGiftUniqueId and autoOpenEnabled then
            AutoOpenStatusLabel.Text = "Found " .. readableTargetName .. "! Opening Unique ID: " .. foundTargetGiftUniqueId .. "..."
            print("\n--- AUTO OPEN ATTEMPT ---")
            print("Attempting to Invoke LootBoxAPI/ExchangeItemForReward for: " .. readableTargetName)
            
            local successInvoke, result = pcall(function()
                return LootBoxExchangeRemote:InvokeServer(TARGET_GIFT_SPECIES_ID, foundTargetGiftUniqueId)
            end)

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
                print(displayResultText)
                
                AutoOpenStatusLabel.Text = displayResultText
                task.wait(3)

            else
                warn("InvokeServer call failed! Error: " .. tostring(result))
                AutoOpenStatusLabel.Text = "Failed to open gift: " .. tostring(result)
                task.wait(3)
            end
            task.wait(1)
        else
            AutoOpenStatusLabel.Text = readableTargetName .. " not found. Waiting..."
            task.wait(2)
        end
    end
    if startUniqueId then
        local toolUseEndArgs = {startUniqueId, "END"}
        print("    Sending global ToolAPI/ServerUseTool 'END'...")
        pcall(ToolUseStartRemote.FireServer, ToolUseStartRemote, unpack(toolUseEndArgs))
    end
    AutoOpenStatusLabel.Text = "Auto Open/Buy: Stopped."
end

-- --- MODE SWITCHING LOGIC ---
local modes = {"Manual Process", "Auto Open Summer Fest Sticker Packs"}
local currentModeIndex = 1
local autoOpenRunning = false

local function updateModeDisplay()
    ModeDisplayLabel.Text = modes[currentModeIndex]
    print("UI Mode set to: " .. modes[currentModeIndex])
end

local function updateUIVisibility(modeName)
    -- Reset UI elements to a default state first
    if GiftDisplayFrame:FindFirstChild("ResultLabel") then GiftDisplayFrame.ResultLabel:Destroy() end
    if GiftDisplayFrame:FindFirstChild("OpeningMessage") then GiftDisplayFrame.OpeningMessage:Destroy() end
    if GiftDisplayFrame:FindFirstChild("OpenAnotherButton") then GiftDisplayFrame.OpenAnotherButton:Destroy() end

    GiftImage.Image = "rbxassetid://83828532069910" -- Default image for both modes
    GiftCostLabel.Text = "Cost: 13000 Doubloons" -- Assuming same cost for display

    if modeName == "Manual Process" then
        GiftImage.Visible = true
        GiftNameMessage.Visible = true
        GiftCostLabel.Visible = true
        OpenGiftButton.Visible = true

        AutoOpenToggle.Visible = false
        AutoBuyToggle.Visible = false
        BuyAmountTextBox.Visible = false
        AutoOpenStatusLabel.Visible = false

        GiftNameMessage.Text = "Kelp Raider Box" -- Specific name for Manual Process
        animateGiftBounce()
    elseif modeName == "Auto Open Summer Fest Sticker Packs" then
        GiftImage.Visible = true
        GiftNameMessage.Visible = true
        GiftCostLabel.Visible = true
        OpenGiftButton.Visible = false

        AutoOpenToggle.Visible = true
        AutoBuyToggle.Visible = true
        BuyAmountTextBox.Visible = autoBuyEnabled
        AutoOpenStatusLabel.Visible = true

        GiftNameMessage.Text = readableTargetName -- Specific name for Auto Open Sticker Packs
    end
end

local function switchMode(direction)
    if autoOpenEnabled then
        autoOpenEnabled = false
        autoOpenRunning = false
        print("Stopping current auto-open process...")
        if autoOpenThread then
            task.cancel(autoOpenThread)
            autoOpenThread = nil
        end
        task.wait(0.5)
    end

    currentModeIndex = currentModeIndex + direction
    if currentModeIndex > #modes then
        currentModeIndex = 1
    elseif currentModeIndex < 1 then
        currentModeIndex = #modes
    end

    updateModeDisplay()
    updateUIVisibility(modes[currentModeIndex])

    if modes[currentModeIndex] == "Manual Process" then
        print("Switched to Manual Process mode. Click 'Open Gift!' to open.")
    elseif modes[currentModeIndex] == "Auto Open Summer Fest Sticker Packs" then
        print("Switched to Auto Open Summer Fest Sticker Packs mode. Toggle 'Auto Open' to start.")
        -- Reset auto toggles to OFF when switching to a new auto mode
        autoOpenEnabled = false
        AutoOpenToggle.Text = "Auto Open: OFF"
        AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)

        autoBuyEnabled = false
        AutoBuyToggle.Text = "Auto Buy: OFF"
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        BuyAmountTextBox.Visible = false
        AutoOpenStatusLabel.Text = ""
    end
end

OpenGiftButton.MouseButton1Click:Connect(handleManualOpenGift)
CloseButton.MouseButton1Click:Connect(function()
    if autoOpenThread then
        task.cancel(autoOpenThread)
        autoOpenThread = nil
    end
    autoOpenEnabled = false
    autoBuyEnabled = false

    local fadeOutTween = TweenService:Create(MainFrame, fadeTweenInfo, {Transparency = 1})
    fadeOutTween:Play()
    fadeOutTween.Completed:Wait()
    ScreenGui:Destroy()
end)

AutoOpenToggle.MouseButton1Click:Connect(function()
    autoOpenEnabled = not autoOpenEnabled

    if autoOpenEnabled then
        AutoOpenToggle.Text = "Auto Open: ON"
        AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        
        AutoOpenStatusLabel.Visible = true
        AutoBuyToggle.Visible = true
        BuyAmountTextBox.Visible = autoBuyEnabled

        AutoOpenStatusLabel.Text = "Starting auto open/buy for " .. readableTargetName .. "..."
        autoOpenThread = task.spawn(autoLogicLoop)
    else
        AutoOpenToggle.Text = "Auto Open: OFF"
        AutoOpenToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        AutoOpenStatusLabel.Text = "Auto Open: Paused."
    end
end)

AutoBuyToggle.MouseButton1Click:Connect(function()
    autoBuyEnabled = not autoBuyEnabled

    if autoBuyEnabled then
        AutoBuyToggle.Text = "Auto Buy: ON"
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        BuyAmountTextBox.Visible = true
    else
        AutoBuyToggle.Text = "Auto Buy: OFF"
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        BuyAmountTextBox.Visible = false
    end
end)

BuyAmountTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newAmount = tonumber(BuyAmountTextBox.Text)
        if newAmount and newAmount >= 1 then
            buyAmount = math.floor(newAmount)
            print("Buy amount set to: " .. buyAmount)
        else
            warn("Invalid buy amount. Must be a number >= 1. Resetting to 1.")
            BuyAmountTextBox.Text = "1"
            buyAmount = 1
        end
    end
end)

PrevModeButton.MouseButton1Click:Connect(function()
    switchMode(-1)
end)

NextModeButton.MouseButton1Click:Connect(function()
    switchMode(1)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.Left then
        switchMode(-1)
    elseif input.KeyCode == Enum.KeyCode.Right then
        switchMode(1)
    end
end)

animatePopIn()
updateModeDisplay()
updateUIVisibility(modes[currentModeIndex])
