-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Modules
local ClientDataModulePath = ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData")
local ClientDataModuleRef = nil

local function getClientDataModule()
    if not ClientDataModuleRef or type(ClientDataModuleRef) ~= "table" then
        print("DEBUG: Attempting to (re)require ClientDataModule...")
        local success, module = pcall(require, ClientDataModulePath)
        if success and type(module) == "table" then
            ClientDataModuleRef = module
            print("DEBUG: ClientDataModule successfully (re)required.")
        else
            warn("getClientDataModule: Failed to load or invalid module. Error:", module)
            ClientDataModuleRef = nil
        end
    end
    return ClientDataModuleRef
end

local function getLatestServerData()
    local module = getClientDataModule()
    if not module or type(module.get_data) ~= "function" then
        warn("get_data is not a valid function on ClientDataModule.")
        return nil
    end
    local success, data = pcall(module.get_data)
    if not success then
        warn("Failed to call get_data:", data)
        return nil
    end
    return data
end

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Rayfield Example Window",
    Icon = 0,
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by Sirius",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RayfieldConfigs",
        FileName = "Big Hub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- GLOBAL REFERENCES TO RAYFIELD TABS (CREATED ONCE)
local PetTab = Window:CreateTab("Pet Management", 4483362458)
local ExtraTab = Window:CreateTab("Extra", 4483362458)
local EventTab = Window:CreateTab("Event", 4483362458)

-- GLOBAL REFERENCES TO UI ELEMENTS (CREATED ONCE, OPTIONS WILL BE UPDATED)
local PetDropdown = nil
local FoodDropdown = nil
local GiftDropdown = nil
local StickerPackDropdown = nil
local PotionDelaySlider = nil
local AutoAgeToggle = nil
local AutoOpenBoxToggle = nil
local AutoOpenStickerPackToggle = nil
local AutoBuyKelpRaiderBoxToggle = nil
local KelpRaiderBoxBuyCountSlider = nil
local AutoBuyStickerPackToggle = nil
local StickerPackBuyCountSlider = nil
local RefreshButton = nil
local CurrencyDisplayLabel = nil -- Reference for the currency display label


local localPlayer = Players.LocalPlayer
local targetPlayerName = localPlayer.Name

-- GLOBAL STATE VARIABLES (These retain state across UI recreations)
local currentlySelectedPetUniqueId = nil
local potionUseDelay = 1
local autoGiveAgePotionEnabled = false
local currentlySelectedGiftUniqueId = nil
local autoOpenKelpRaiderBoxEnabled = false
local currentlySelectedStickerPackUniqueId = nil
local autoOpenStickerPackEnabled = false

local autoBuyKelpRaiderBoxEnabled = false
local kelpRaiderBoxBuyCount = 1
local autoBuyStickerPackEnabled = false
local stickerPackBuyCount = 1

local TARGET_GIFT_ID = "summerfest_2025_kelp_raider_box"
local TARGET_STICKER_PACK_ID = "summerfest_2025_sticker_pack"

-- GLOBAL DATA MAPS (These are populated on each UI refresh cycle)
local uniqueIdToPetDataMap = {}
local uniqueIdToPetDisplayStringMap = {}
local uniqueIdToFoodDataMap = {}
local uniqueIdToFoodDisplayStringMap = {}
local uniqueIdToGiftDataMap = {}
local uniqueIdToGiftDisplayStringMap = {}
local uniqueIdToStickerPackDataMap = {}
local uniqueIdToStickerPackDisplayStringMap = {}


local function getDisplayId(idValue)
    if type(idValue) == "string" then
        return idValue
    elseif type(idValue) == "number" then
        return tostring(idValue)
    elseif type(idValue) == "table" and idValue then
        if idValue.Name and type(idValue.Name) == "string" then
            return idValue.Name
        elseif idValue.Value and type(idValue.Value) == "string" then
            return idValue.Value
        else
            return "[Complex ID Table]"
        end
    else
        return "UnknownID:" .. tostring(idValue)
    end
end

-- Function to create/update UI elements
local function createOrUpdateUIData(dataToUse)
    -- Reset maps with fresh data from each refresh
    uniqueIdToPetDataMap = {}
    uniqueIdToPetDisplayStringMap = {}
    uniqueIdToFoodDataMap = {}
    uniqueIdToFoodDisplayStringMap = {}
    uniqueIdToGiftDataMap = {}
    uniqueIdToGiftDisplayStringMap = {}
    uniqueIdToStickerPackDataMap = {}
    uniqueIdToStickerPackDisplayStringMap = {}

    local currentPlayerData = dataToUse and dataToUse[targetPlayerName]

    -- Prepare Pet data
    local petDropdownOptions = {"No pets found"}
    local initialPetOption = "No pets found"
    local newSelectedPetUid = nil
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.pets then
        local pets = currentPlayerData.inventory.pets
        if next(pets) then
            petDropdownOptions = {}
            for uid, pet in pairs(pets) do
                local display = getDisplayId(pet.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(petDropdownOptions, display)
                uniqueIdToPetDataMap[tostring(uid)] = {uniqueId=uid, speciesId=pet.id, fullData=pet}
                uniqueIdToPetDisplayStringMap[tostring(uid)] = display
                if not newSelectedPetUid then
                    newSelectedPetUid = tostring(uid)
                    initialPetOption = display
                end
            end
        end
    end
    if currentlySelectedPetUniqueId and uniqueIdToPetDisplayStringMap[currentlySelectedPetUniqueId] then
        initialPetOption = uniqueIdToPetDisplayStringMap[currentlySelectedPetUniqueId]
    else
        currentlySelectedPetUniqueId = newSelectedPetUid
    end

    -- Prepare Food data (not used for auto-potion selection anymore, but still for dropdown)
    local foodDropdownOptions = {"No food found"}
    local initialFoodOption = "No food found"
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.food then
        local foods = currentPlayerData.inventory.food
        if next(foods) then
            foodDropdownOptions = {}
            for uid, food in pairs(foods) do
                local display = getDisplayId(food.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(foodDropdownOptions, display)
                uniqueIdToFoodDataMap[tostring(uid)] = {uniqueId=uid, itemId=food.id, fullData=food}
                uniqueIdToFoodDisplayStringMap[tostring(uid)] = display
                if initialFoodOption == "No food found" then initialFoodOption = display end
            end
        end
    end

    -- Prepare Gifts data
    local giftDropdownOptions = {"No '" .. TARGET_GIFT_ID .. "' found"}
    local initialGiftOption = "No '" .. TARGET_GIFT_ID .. "' found"
    local newSelectedGiftUid = nil
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.gifts then
        local gifts = currentPlayerData.inventory.gifts
        for uid, gift in pairs(gifts) do
            if gift.id == TARGET_GIFT_ID then
                local display = getDisplayId(gift.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(giftDropdownOptions, display)
                uniqueIdToGiftDataMap[tostring(uid)] = {fullData=gift, itemId=gift.id, uniqueId=uid}
                uniqueIdToGiftDisplayStringMap[tostring(uid)] = display
                if not newSelectedGiftUid then
                    newSelectedGiftUid = tostring(uid)
                    initialGiftOption = display
                end
            end
        end
    end
    currentlySelectedGiftUniqueId = newSelectedGiftUid

    -- Prepare Sticker Packs data (using Gift inventory logic)
    local stickerPackDropdownOptions = {"No '" .. TARGET_STICKER_PACK_ID .. "' packs found"}
    local initialStickerPackOption = "No '" .. TARGET_STICKER_PACK_ID .. "' packs found"
    local newSelectedStickerPackUid = nil
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.gifts then
        local gifts = currentPlayerData.inventory.gifts
        for uid, giftData in pairs(gifts) do
            if giftData.id == TARGET_STICKER_PACK_ID then
                local display = getDisplayId(giftData.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(stickerPackDropdownOptions, display)
                uniqueIdToStickerPackDataMap[tostring(uid)] = {uniqueId=uid, itemId=giftData.id, fullData=giftData}
                uniqueIdToStickerPackDisplayStringMap[tostring(uid)] = display
                if not newSelectedStickerPackUid then
                    newSelectedStickerPackUid = tostring(uid)
                    initialStickerPackOption = display
                end
            end
        end
    end
    currentlySelectedStickerPackUniqueId = newSelectedStickerPackUid


    -- --- Create or Update UI Elements ---

    if not PetDropdown then
        PetDropdown = PetTab:CreateDropdown({
            Name = "Select Pet",
            Options = petDropdownOptions,
            CurrentOption = {initialPetOption},
            MultipleOptions = false,
            Flag = "PetDropdownSelection",
            Callback = function(selectedOptions)
                local selected = selectedOptions[1]
                local targetUid = nil
                if type(selected) == "string" then
                    local match = selected:match("Unique ID: ([%w_]+)")
                    if match then targetUid = match end
                end
                currentlySelectedPetUniqueId = targetUid
                local petInfo = uniqueIdToPetDataMap[targetUid]
                local displayName = uniqueIdToPetDisplayStringMap[targetUid] or "Unknown Pet"
                if petInfo then
                    print("--- Selected Pet ---")
                    print("Name: " .. displayName)
                    print("Species ID: " .. tostring(getDisplayId(petInfo.speciesId)))
                    print("Unique ID: " .. tostring(petInfo.uniqueId))
                    local args = {petInfo.uniqueId, {use_sound_delay=false, equip_as_last=false}}
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(args))
                    end)
                end
            end
        })
    else
        warn("PetDropdown: Dynamic 'UpdateOptions' method not found for Rayfield. Options may not refresh.")
    end

    if not FoodDropdown then
        FoodDropdown = ExtraTab:CreateDropdown({
            Name = "Select Food (Display Only)",
            Options = foodDropdownOptions,
            CurrentOption = {initialFoodOption},
            MultipleOptions = false,
            Flag = "FoodDropdownSelection",
            Callback = function(selectedOptions)
                -- This dropdown primarily for display; auto-potion finds all potions
            end
        })
    else
        warn("FoodDropdown: Dynamic 'UpdateOptions' method not found for Rayfield. Options may not refresh.")
    end

    -- --- AGE POTION ELEMENTS ---
    if not PotionDelaySlider then
        PotionDelaySlider = ExtraTab:CreateSlider({
            Name = "Potion Use Delay (Seconds)",
            Range = {0.1, 10},
            Increment = 0.1,
            CurrentValue = potionUseDelay,
            Compact = false,
            Flag = "PotionDelaySlider",
            Callback = function(val) potionUseDelay=val end,
        })
    end

    if not AutoAgeToggle then
        AutoAgeToggle = ExtraTab:CreateToggle({
            Name = "Enable Auto Age-Potion (Use All)",
            CurrentValue = autoGiveAgePotionEnabled,
            Flag = "AutoAgeToggle",
            Callback = function(val)
                autoGiveAgePotionEnabled = val
                if val then
                    task.spawn(function()
                        while autoGiveAgePotionEnabled do
                            if not currentlySelectedPetUniqueId then
                                warn("Auto Age-Potion: No pet selected. Stopping auto-age.")
                                autoGiveAgePotionEnabled = false
                                break
                            end
                            
                            local data = getLatestServerData()
                            if not data then
                                warn("Auto Age-Potion: Failed to get latest server data. Stopping auto-age.")
                                autoGiveAgePotionEnabled = false
                                break
                            end

                            local foods = data[targetPlayerName] and data[targetPlayerName].inventory and data[targetPlayerName].inventory.food
                            if not foods then
                                warn("Auto Age-Potion: Could not retrieve current food inventory data. Stopping auto-age.")
                                autoGiveAgePotionEnabled = false
                                break
                            end

                            local agePotions = {}
                            for uid, food in pairs(foods) do
                                if food.id == "pet_age_potion" then
                                    table.insert(agePotions, tostring(uid))
                                end
                            end

                            if #agePotions > 0 then
                                local firstUID = table.remove(agePotions, 1)
                                local additionalUids = agePotions

                                local args = {
                                    "__Enum_PetObjectCreatorType_2",
                                    {
                                        additional_consume_uniques = additionalUids,
                                        pet_unique = currentlySelectedPetUniqueId,
                                        unique_id = firstUID
                                    }
                                }

                                local success, err = pcall(function()
                                    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetObjectAPI/CreatePetObject"):InvokeServer(unpack(args))
                                end)
                                
                                if success then
                                    print("Auto gave " .. tostring(#additionalUids + 1) .. " age potion(s) to pet " .. (uniqueIdToPetDisplayStringMap[currentlySelectedPetUniqueId] or currentlySelectedPetUniqueId) .. ".")
                                else
                                    warn("Error giving age potion(s):", err)
                                end
                            else
                                print("Auto Age-Potion: No age potions found in inventory. Stopping auto-age.")
                                autoGiveAgePotionEnabled = false
                                break
                            end
                            wait(potionUseDelay)
                        end
                        print("Auto Age-Potion: Loop ended.")
                    end)
                end
            end
        })
    end
    -- --- END AGE POTION ELEMENTS ---

    -- NEW: Currency Display Label (moved to top of EventTab)
    if not CurrencyDisplayLabel then
        CurrencyDisplayLabel = EventTab:CreateLabel("Current Currency: Loading...", "wallet", Color3.fromRGB(255, 255, 255), false)
        
        -- Start a task to update the currency display
        task.spawn(function()
            while true do
                local success, amountText = pcall(function()
                    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
                    local currencyIndicatorApp = playerGui:WaitForChild("AltCurrencyIndicatorApp", 5)
                    local currencyIndicator = currencyIndicatorApp:WaitForChild("CurrencyIndicator", 5)
                    local container = currencyIndicator:WaitForChild("Container", 5)
                    local amountLabel = container:WaitForChild("Amount", 5)
                    return amountLabel.Text
                end)

                if success and CurrencyDisplayLabel then
                    -- Rayfield labels don't update with new ImageId or Color, only text.
                    -- So we just update the title string.
                    CurrencyDisplayLabel:Set("Current Currency: " .. amountText)
                else
                    warn("Failed to update currency display:", amountText or "Path not found")
                    if CurrencyDisplayLabel then
                        CurrencyDisplayLabel:Set("Current Currency: Error")
                    end
                end
                wait(1) -- Update every 1 second
            end
        end)
    end

    -- Kelp Raider Box Dropdown (primarily for display now)
    if not GiftDropdown then
        GiftDropdown = EventTab:CreateDropdown({
            Name = "Selected Kelp Raider Box (Display Only)",
            Options = giftDropdownOptions,
            CurrentOption = {initialGiftOption},
            MultipleOptions = false,
            Flag = "GiftDropdown",
            Callback = function(selectedOptions)
                -- This dropdown primarily for display; auto-open finds all boxes dynamically
            end
        })
    else
        warn("GiftDropdown: Dynamic 'UpdateOptions' method not found for Rayfield. Options may not refresh.")
    end

    -- Sticker Pack Dropdown (primarily for display now)
    if not StickerPackDropdown then
        StickerPackDropdown = EventTab:CreateDropdown({
            Name = "Selected Sticker Pack (Display Only)",
            Options = stickerPackDropdownOptions,
            CurrentOption = {initialStickerPackOption},
            MultipleOptions = false,
            Flag = "StickerPackDropdown",
            Callback = function(selectedOptions)
                -- This dropdown primarily for display; auto-open finds all packs dynamically
            end
        })
    else
        warn("StickerPackDropdown: Dynamic 'UpdateOptions' method not found for Rayfield. Options may not refresh.")
    end

    if not AutoOpenBoxToggle then
        AutoOpenBoxToggle = EventTab:CreateToggle({
            Name = "Auto Open All Kelp Raider Boxes",
            CurrentValue = autoOpenKelpRaiderBoxEnabled,
            Flag = "AutoOpenBox",
            Callback = function(val)
                print("Toggle Callback Fired for Auto Open Kelp Raider Box. Value: " .. tostring(val))
                autoOpenKelpRaiderBoxEnabled = val
                if val then
                    task.spawn(function()
                        while autoOpenKelpRaiderBoxEnabled do
                            local data = getLatestServerData()
                            if not data then
                                warn("Auto Open Box: Failed to get latest server data. Stopping auto-open.")
                                autoOpenKelpRaiderBoxEnabled = false
                                break
                            end
                            
                            local gifts = data[targetPlayerName] and data[targetPlayerName].inventory and data[targetPlayerName].inventory.gifts
                            if not gifts then
                                warn("Auto Open Box: Could not retrieve current gift inventory data. Stopping auto-open.")
                                autoOpenKelpRaiderBoxEnabled = false
                                break
                            end

                            local foundBoxUid = nil
                            for uid, gift in pairs(gifts) do
                                if gift.id == TARGET_GIFT_ID then
                                    foundBoxUid = tostring(uid)
                                    break
                                end
                            end

                            if not foundBoxUid then
                                print("Auto Open Box: No more '" .. TARGET_GIFT_ID .. "' found in inventory. Stopping auto-open.")
                                autoOpenKelpRaiderBoxEnabled = false
                                break
                            end
                            
                            currentlySelectedGiftUniqueId = foundBoxUid

                            print("Auto Open Kelp Raider Box: Opening box with UID: " .. tostring(currentlySelectedGiftUniqueId))
                            local success, err = pcall(function()
                                local equipArgs = {
                                    currentlySelectedGiftUniqueId,
                                    {
                                        spawn_cframe = CFrame.new(-2981.871337890625, 4000.499755859375, -9020.67578125, -0.8791548013687134, -6.870826041449618e-08, -0.4765363335609436, -3.3604479199311754e-08, 1, -8.218623293032579e-08, 0.4765363335609436, -5.624066190534904e-08, -0.8791548013687134),
                                        use_sound_delay=false,
                                        equip_as_last=false
                                    }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(equipArgs))
                                wait(0.2)

                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({currentlySelectedGiftUniqueId, "START"})
                                wait(0.2)

                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Unequip"):InvokeServer(currentlySelectedGiftUniqueId)
                                wait(0.2)

                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({currentlySelectedGiftUniqueId, "END"})
                                wait(0.2)
                                
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("LootBoxAPI/ExchangeItemForReward"):InvokeServer(TARGET_GIFT_ID, currentlySelectedGiftUniqueId)
                                
                                print("Opened Kelp Raider Box: " .. currentlySelectedGiftUniqueId)
                            end)
                            if not success then
                                warn("Error during Kelp Raider Box open sequence:", err)
                                autoOpenKelpRaiderBoxEnabled = false 
                                break
                            end
                            wait(2)
                        end
                        print("Auto Open Kelp Raider Box: Loop ended.")
                    end)
                else
                    print("Auto Open Kelp Raider Box: Toggle is OFF.")
                end
            end
        })
    end

    if not AutoOpenStickerPackToggle then
        AutoOpenStickerPackToggle = EventTab:CreateToggle({
            Name = "Auto Open All Sticker Packs",
            CurrentValue = autoOpenStickerPackEnabled,
            Flag = "AutoOpenStickerPack",
            Callback = function(val)
                print("Toggle Callback Fired for Auto Open Sticker Pack. Value: " .. tostring(val))
                autoOpenStickerPackEnabled = val
                if val then
                    task.spawn(function()
                        while autoOpenStickerPackEnabled do
                            local data = getLatestServerData()
                            if not data then
                                warn("Auto Open Sticker Pack: Failed to get latest server data. Stopping auto-open.")
                                autoOpenStickerPackEnabled = false
                                break
                            end
                            
                            local gifts = data[targetPlayerName] and data[targetPlayerName].inventory and data[targetPlayerName].inventory.gifts
                            if not gifts then
                                warn("Auto Open Sticker Pack: Could not retrieve current gift inventory data. Stopping auto-open.")
                                autoOpenStickerPackEnabled = false
                                break
                            end

                            local foundPackUid = nil
                            for uid, giftData in pairs(gifts) do
                                if giftData.id == TARGET_STICKER_PACK_ID then
                                    foundPackUid = tostring(uid)
                                    break
                                end
                            end

                            if not foundPackUid then
                                print("Auto Open Sticker Pack: No more '" .. TARGET_STICKER_PACK_ID .. "' packs found in inventory. Stopping auto-open.")
                                autoOpenStickerPackEnabled = false
                                break
                            end
                            
                            currentlySelectedStickerPackUniqueId = foundPackUid

                            print("Auto Open Sticker Pack: Opening pack with UID: " .. tostring(currentlySelectedStickerPackUniqueId))
                            local success, err = pcall(function()
                                local equipArgs = {
                                    currentlySelectedStickerPackUniqueId,
                                    {
                                        spawn_cframe = CFrame.new(-2981.871337890625, 4000.499755859375, -9020.67578125, -0.8791548013687134, -6.870826041449618e-08, -0.4765363335609436, -3.3604479199311754e-08, 1, -8.218623293032579e-08, 0.4765363335609436, -5.624066190534904e-08, -0.8791548013687134),
                                        use_sound_delay=false,
                                        equip_as_last=false
                                    }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(equipArgs))
                                wait(0.2)

                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({currentlySelectedStickerPackUniqueId, "START"})
                                wait(0.2)

                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Unequip"):InvokeServer(currentlySelectedStickerPackUniqueId)
                                wait(0.2)

                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({currentlySelectedStickerPackUniqueId, "END"})
                                wait(0.2)
                                
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("LootBoxAPI/ExchangeItemForReward"):InvokeServer(TARGET_STICKER_PACK_ID, currentlySelectedStickerPackUniqueId)
                                
                                print("Opened Sticker Pack: " .. currentlySelectedStickerPackUniqueId)
                            end)
                            if not success then
                                warn("Error during Sticker Pack open sequence:", err)
                                autoOpenStickerPackEnabled = false
                                break
                            end
                            wait(2)
                        end
                        print("Auto Open Sticker Pack: Loop ended.")
                    end)
                else
                    print("Auto Open Sticker Pack: Toggle is OFF.")
                end
            end
        })
    end

    -- Auto-Buy Kelp Raider Box Toggle and Slider
    if not KelpRaiderBoxBuyCountSlider then
        KelpRaiderBoxBuyCountSlider = EventTab:CreateSlider({
            Name = "Kelp Raider Boxes to Buy",
            Range = {1, 100},
            Increment = 1,
            CurrentValue = kelpRaiderBoxBuyCount,
            Compact = false,
            Flag = "KelpRaiderBoxBuyCount",
            Callback = function(val) kelpRaiderBoxBuyCount = val end,
        })
    end

    if not AutoBuyKelpRaiderBoxToggle then
        AutoBuyKelpRaiderBoxToggle = EventTab:CreateToggle({
            Name = "Auto-Buy summerfest_2025_kelp_raider_box",
            CurrentValue = autoBuyKelpRaiderBoxEnabled,
            Flag = "AutoBuyKelpRaiderBox",
            Callback = function(val)
                print("Toggle Callback Fired for Auto-Buy Kelp Raider Box. Value: " .. tostring(val))
                autoBuyKelpRaiderBoxEnabled = val
                if val then
                    task.spawn(function()
                        while autoBuyKelpRaiderBoxEnabled do
                            print("Auto-Buy Kelp Raider Box: Attempting to buy " .. kelpRaiderBoxBuyCount .. " boxes.")
                            local success, err = pcall(function()
                                local args = {
                                    "gifts",
                                    TARGET_GIFT_ID,
                                    { buy_count = kelpRaiderBoxBuyCount }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ShopAPI/BuyItem"):InvokeServer(unpack(args))
                                print("Successfully bought " .. kelpRaiderBoxBuyCount .. " Kelp Raider Box(es).")
                            end)
                            if not success then
                                warn("Error during Auto-Buy Kelp Raider Box:", err)
                                autoBuyKelpRaiderBoxEnabled = false
                                break
                            end
                            wait(5)
                        end
                        print("Auto-Buy Kelp Raider Box: Loop ended.")
                    end)
                else
                    print("Auto-Buy Kelp Raider Box: Toggle is OFF.")
                end
            end
        })
    end

    -- Auto-Buy Sticker Pack Toggle and Slider
    if not StickerPackBuyCountSlider then
        StickerPackBuyCountSlider = EventTab:CreateSlider({
            Name = "Sticker Packs to Buy",
            Range = {1, 100},
            Increment = 1,
            CurrentValue = stickerPackBuyCount,
            Compact = false,
            Flag = "StickerPackBuyCount",
            Callback = function(val) stickerPackBuyCount = val end,
        })
    end

    if not AutoBuyStickerPackToggle then
        AutoBuyStickerPackToggle = EventTab:CreateToggle({
            Name = "Auto-Buy summerfest_2025_sticker_pack",
            CurrentValue = autoBuyStickerPackEnabled,
            Flag = "AutoBuyStickerPack",
            Callback = function(val)
                print("Toggle Callback Fired for Auto-Buy Sticker Pack. Value: " .. tostring(val))
                autoBuyStickerPackEnabled = val
                if val then
                    task.spawn(function()
                        while autoBuyStickerPackEnabled do
                            print("Auto-Buy Sticker Pack: Attempting to buy " .. stickerPackBuyCount .. " packs.")
                            local success, err = pcall(function()
                                local args = {
                                    "gifts",
                                    TARGET_STICKER_PACK_ID,
                                    { buy_count = stickerPackBuyCount }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ShopAPI/BuyItem"):InvokeServer(unpack(args))
                                print("Successfully bought " .. stickerPackBuyCount .. " Sticker Pack(s).")
                            end)
                            if not success then
                                warn("Error during Auto-Buy Sticker Pack:", err)
                                autoBuyStickerPackEnabled = false
                                break
                            end
                            wait(5)
                        end
                        print("Auto-Buy Sticker Pack: Loop ended.")
                    end)
                else
                    print("Auto-Buy Sticker Pack: Toggle is OFF.")
                end
            end
        })
    end


    if not RefreshButton then
        RefreshButton = ExtraTab:CreateButton({
            Name = "Refresh All Data",
            Callback = function()
                print("Manually refreshing UI data...")
                local data = getLatestServerData()
                if data then
                    createOrUpdateUIData(data)
                end
            end,
        })
    end
end


-- Fetch initial data and call the function to create UI for the first time
local initialServerData = getLatestServerData()
createOrUpdateUIData(initialServerData)

-- Load configuration (if saving/loading UI settings)
Rayfield:LoadConfiguration()
