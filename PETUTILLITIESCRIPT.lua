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
local RefreshButton = nil
local CurrencyDisplayLabel = nil
local SelectedPetAgeLabel = nil 

local AutoNeonToggle = nil
local NeonFusionPetDropdown = nil

-- Consolidated Auto-Buy UI Elements
local AutoBuyItemDropdown = nil
local AutoBuyAmountSlider = nil
local AutoBuyGlobalToggle = nil


local localPlayer = Players.LocalPlayer
repeat task.wait() until localPlayer -- This line will pause the script until localPlayer is not nil
local targetPlayerName = localPlayer.Name

-- GLOBAL STATE VARIABLES (These retain state across UI recreations)
local currentlySelectedPetUniqueId = nil
local potionUseDelay = 1
local autoGiveAgePotionEnabled = false
local currentlySelectedGiftUniqueId = nil
local autoOpenKelpRaiderBoxEnabled = false
local currentlySelectedStickerPackUniqueId = false
local autoOpenStickerPackEnabled = false

local autoNeonEnabled = false
local selectedNeonPetSpeciesId = nil

-- Consolidated list of all buyable items
local allBuyableItems = {
    -- Existing event items (now included here)
    { id = "summerfest_2025_kelp_raider_box", category = "gifts", defaultCount = 1, name = "Kelp Raider Box" },
    { id = "summerfest_2025_sticker_pack", category = "gifts", defaultCount = 1, name = "Sticker Pack" },
    -- User-requested items
    { id = "summerfest_2025_island_tarsier", category = "pets", defaultCount = 16, name = "Island Tarsier" },
    { id = "summerfest_2025_manta_ray", category = "pets", defaultCount = 1, name = "Manta Ray" },
    { id = "summerfest_2025_seabed_creeper", category = "pets", defaultCount = 16, name = "Seabed Creeper" },
    { id = "summer_2025_emperor_shrimp", category = "pets", defaultCount = 16, name = "Emperor Shrimp" },
    { id = "summerfest_2025_coconut_friend", category = "pets", defaultCount = 3, name = "Coconut Friend" },
    { id = "summerfest_2025_pirate_skull_vehicle", category = "transport", defaultCount = 1, name = "Pirate Skull Vehicle" },
    { id = "summerfest_2025_pirate_row_boat", category = "transport", defaultCount = 1, name = "Pirate Row Boat" },
}

-- GLOBAL DATA MAPS (These are populated on each UI refresh cycle)
local uniqueIdToPetDataMap = {}
local uniqueIdToPetDisplayStringMap = {}
local uniqueIdToFoodDataMap = {}
local uniqueIdToFoodDisplayStringMap = {}
local uniqueIdToGiftDataMap = {}
local uniqueIdToGiftDisplayStringMap = {}
local uniqueIdToStickerPackDataMap = {}
local uniqueIdToStickerPackDisplayStringMap = {}

-- NEW: Global state for the consolidated auto-buy system
local autoBuyStates = {} -- Maps item ID to boolean (true if auto-buying, false otherwise)
local autoBuyCounts = {} -- Maps item ID to the desired buy_count
local currentSelectedAutoBuyItemId = nil -- The ID of the item currently selected in the auto-buy dropdown
local currentAutoBuyTask = nil -- Reference to the currently running auto-buy task/thread

-- Initialize autoBuyStates and autoBuyCounts
for _, item in ipairs(allBuyableItems) do
    autoBuyStates[item.id] = false
    autoBuyCounts[item.id] = item.defaultCount
end

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

    -- Prepare Pet data (for PetDropdown and NeonFusionPetDropdown)
    local petDropdownOptions = {"No pets found"}
    local initialPetOption = "No pets found"
    local newSelectedPetUid = nil
    
    local neonFusionPetDropdownOptions = {"Select a pet species for fusion"}
    local initialNeonFusionPetOption = "Select a pet species for fusion"

    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.pets then
        local pets = currentPlayerData.inventory.pets
        if next(pets) then
            petDropdownOptions = {}
            local uniqueSpeciesForNeon = {} -- To avoid duplicate species in neon dropdown
            for uid, pet in pairs(pets) do
                local display = getDisplayId(pet.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(petDropdownOptions, display)
                uniqueIdToPetDataMap[tostring(uid)] = {uniqueId=uid, speciesId=pet.id, fullData=pet}
                uniqueIdToPetDisplayStringMap[tostring(uid)] = display
                if not newSelectedPetUid then
                    newSelectedPetUid = tostring(uid)
                    initialPetOption = display
                end

                -- For Neon Fusion Pet Dropdown
                if not uniqueSpeciesForNeon[pet.id] then
                    table.insert(neonFusionPetDropdownOptions, getDisplayId(pet.id))
                    uniqueSpeciesForNeon[pet.id] = true
                end
            end
            -- Sort neon fusion options alphabetically for better UX
            table.sort(neonFusionPetDropdownOptions, function(a, b) return a < b end)
            -- Re-add the placeholder at the top
            table.insert(neonFusionPetDropdownOptions, 1, "Select a pet species for fusion")
        end
    end
    if currentlySelectedPetUniqueId and uniqueIdToPetDisplayStringMap[currentlySelectedPetUniqueId] then
        initialPetOption = uniqueIdToPetDisplayStringMap[currentlySelectedPetUniqueId]
    else
        currentlySelectedPetUniqueId = newSelectedPetUid
    end

    -- Set initial option for Neon Fusion Pet Dropdown
    if selectedNeonPetSpeciesId then
        local found = false
        for _, option in ipairs(neonFusionPetDropdownOptions) do
            if option == selectedNeonPetSpeciesId then
                initialNeonFusionPetOption = option
                found = true
                break
            end 
        end
        if not found then
            selectedNeonPetSpeciesId = nil -- Clear if selected species no longer exists
            initialNeonFusionPetOption = "Select a pet species for fusion"
        end
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

    -- Prepare Gifts data (only for display, auto-open logic is separate)
    local giftDropdownOptions = {"No Kelp Raider Box found"}
    local initialGiftOption = "No Kelp Raider Box found"
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.gifts then
        local gifts = currentPlayerData.inventory.gifts
        for uid, gift in pairs(gifts) do
            if gift.id == "summerfest_2025_kelp_raider_box" then
                local display = getDisplayId(gift.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(giftDropdownOptions, display)
                if initialGiftOption == "No Kelp Raider Box found" then initialGiftOption = display end
            end
        end
    end

    -- Prepare Sticker Packs data (only for display, auto-open logic is separate)
    local stickerPackDropdownOptions = {"No Sticker Pack found"}
    local initialStickerPackOption = "No Sticker Pack found"
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.gifts then
        local gifts = currentPlayerData.inventory.gifts
        for uid, giftData in pairs(gifts) do
            if giftData.id == "summerfest_2025_sticker_pack" then
                local display = getDisplayId(giftData.id) .. " (Unique ID: " .. tostring(uid) .. ")"
                table.insert(stickerPackDropdownOptions, display)
                if initialStickerPackOption == "No Sticker Pack found" then initialStickerPackOption = display end
            end
        end
    end


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
                    -- Update the age display label immediately
                    if SelectedPetAgeLabel then
                        SelectedPetAgeLabel:Set("Selected Pet Age: " .. tostring(petInfo.fullData.age or "N/A"))
                    end
                else
                    if SelectedPetAgeLabel then
                        SelectedPetAgeLabel:Set("Selected Pet Age: N/A")
                    end
                end
            end
        })
    else
        warn("PetDropdown: Dynamic 'UpdateOptions' method not found for Rayfield. Options may not refresh.")
    end

    -- NEW: Label to display the selected pet's age
    if not SelectedPetAgeLabel then
        SelectedPetAgeLabel = ExtraTab:CreateLabel("Selected Pet Age: N/A", "info", Color3.fromRGB(255, 255, 255), false)
        -- Initial update for the label if a pet is already selected on UI load
        if currentlySelectedPetUniqueId and uniqueIdToPetDataMap[currentlySelectedPetUniqueId] then
            SelectedPetAgeLabel:Set("Selected Pet Age: " .. tostring(uniqueIdToPetDataMap[currentlySelectedPetUniqueId].fullData.age or "N/A"))
        end
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

    -- NEW: Auto Neon Fusion Section
    if not NeonFusionPetDropdown then
        NeonFusionPetDropdown = ExtraTab:CreateDropdown({
            Name = "Select Pet Species for Neon Fusion",
            Options = neonFusionPetDropdownOptions,
            CurrentOption = {initialNeonFusionPetOption},
            MultipleOptions = false,
            Flag = "NeonFusionPetSelection",
            Callback = function(selectedOptions)
                local selected = selectedOptions[1]
                if selected and selected ~= "Select a pet species for fusion" then
                    selectedNeonPetSpeciesId = selected
                    print("Selected species for Neon Fusion: " .. selectedNeonPetSpeciesId)
                else
                    selectedNeonPetSpeciesId = nil
                    print("Neon Fusion species selection cleared.")
                end
            end
        })
    end

    if not AutoNeonToggle then
        AutoNeonToggle = ExtraTab:CreateToggle({
            Name = "Enable Auto Neon Fusion",
            CurrentValue = autoNeonEnabled,
            Flag = "AutoNeonToggle",
            Callback = function(val)
                autoNeonEnabled = val
                if val then
                    task.spawn(function()
                        while autoNeonEnabled do
                            if not selectedNeonPetSpeciesId then
                                warn("Auto Neon Fusion: No pet species selected for fusion. Stopping auto-neon.")
                                autoNeonEnabled = false
                                break
                            end

                            local data = getLatestServerData()
                            if not data then
                                warn("Auto Neon Fusion: Failed to get latest server data. Stopping auto-neon.")
                                autoNeonEnabled = false
                                break
                            end

                            local petsInInventory = data[targetPlayerName] and data[targetPlayerName].inventory and data[targetPlayerName].inventory.pets
                            if not petsInInventory then
                                warn("Auto Neon Fusion: Could not retrieve current pet inventory data. Stopping auto-neon.")
                                autoNeonEnabled = false
                                break
                            end

                            local petsOfSelectedSpecies = {}
                            for uid, pet in pairs(petsInInventory) do
                                if pet.id == selectedNeonPetSpeciesId then
                                    table.insert(petsOfSelectedSpecies, tostring(uid))
                                end
                            end

                            if #petsOfSelectedSpecies >= 4 then
                                local fusionPetUids = {}
                                for i = 1, 4 do
                                    table.insert(fusionPetUids, table.remove(petsOfSelectedSpecies, 1))
                                end

                                print("Auto Neon Fusion: Attempting fusion for species '" .. selectedNeonPetSpeciesId .. "' with UIDs: " .. table.concat(fusionPetUids, ", "))
                                local success, err = pcall(function()
                                    game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("PetAPI/DoNeonFusion"):InvokeServer(fusionPetUids)
                                end)

                                if success then
                                    print("Successfully performed Neon Fusion for '" .. selectedNeonPetSpeciesId .. "'.")
                                else
                                    warn("Error during Neon Fusion:", err)
                                end
                            else
                                print("Auto Neon Fusion: Not enough pets of species '" .. selectedNeonPetSpeciesId .. "' found (" .. #petsOfSelectedSpecies .. "/4). Waiting for more...")
                            end
                            wait(2) 
                        end
                        print("Auto Neon Fusion: Loop ended.")
                    end)
                else
                    print("Auto Neon Fusion: Toggle is OFF.")
                end
            end
        })
    end


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

                            local boxesToOpen = {}
                            for uid, gift in pairs(gifts) do
                                if gift.id == "summerfest_2025_kelp_raider_box" then
                                    table.insert(boxesToOpen, tostring(uid))
                                end
                            end

                            if #boxesToOpen > 0 then
                                for _, uidToOpen in ipairs(boxesToOpen) do
                                    print("Auto Open Kelp Raider Box: Opening box with UID: " .. tostring(uidToOpen))
                                    local success, err = pcall(function()
                                        local equipArgs = {
                                            uidToOpen,
                                            {
                                                spawn_cframe = CFrame.new(-2981.871337890625, 4000.499755859375, -9020.67578125, -0.8791548013687134, -6.870826041449618e-08, -0.4765363335609436, -3.3604479199311754e-08, 1, -8.218623293032579e-08, 0.4765363335609436, -5.624066190534904e-08, -0.8791548013687134),
                                                use_sound_delay=false,
                                                equip_as_last=false
                                            }
                                        }
                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(equipArgs))
                                        wait(0.2)

                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({uidToOpen, "START"})
                                        wait(0.2)

                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Unequip"):InvokeServer(uidToOpen)
                                        wait(0.2)

                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({uidToOpen, "END"})
                                        wait(0.2)
                                        
                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("LootBoxAPI/ExchangeItemForReward"):InvokeServer("summerfest_2025_kelp_raider_box", uidToOpen)
                                        
                                        print("Opened Kelp Raider Box: " .. uidToOpen)
                                    end)
                                    if not success then
                                        warn("Error during Kelp Raider Box open sequence for UID " .. uidToOpen .. ":", err)
                                    end
                                    wait(1) -- Short delay between opening each box
                                end
                            else
                                print("Auto Open Box: No more 'summerfest_2025_kelp_raider_box' found in inventory. Stopping auto-open.")
                                autoOpenKelpRaiderBoxEnabled = false
                                break
                            end
                            wait(2) -- Longer delay before re-checking inventory for new boxes
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

                            local packsToOpen = {}
                            for uid, giftData in pairs(gifts) do
                                if giftData.id == "summerfest_2025_sticker_pack" then
                                    table.insert(packsToOpen, tostring(uid))
                                end
                            end

                            if #packsToOpen > 0 then
                                for _, uidToOpen in ipairs(packsToOpen) do
                                    print("Auto Open Sticker Pack: Opening pack with UID: " .. tostring(uidToOpen))
                                    local success, err = pcall(function()
                                        local equipArgs = {
                                            uidToOpen,
                                            {
                                                spawn_cframe = CFrame.new(-2981.871337890625, 4000.499755859375, -9020.67578125, -0.8791548013687134, -6.870826041449618e-08, -0.4765363335609436, -3.3604479199311754e-08, 1, -8.218623293032579e-08, 0.4765363335609436, -5.624066190534904e-08, -0.8791548013687134),
                                                use_sound_delay=false,
                                                equip_as_last=false
                                            }
                                        }
                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Equip"):InvokeServer(unpack(equipArgs))
                                        wait(0.2)

                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({uidToOpen, "START"})
                                        wait(0.2)

                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/Unequip"):InvokeServer(uidToOpen)
                                        wait(0.2)

                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ToolAPI/ServerUseTool"):FireServer({uidToOpen, "END"})
                                        wait(0.2)
                                        
                                        game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("LootBoxAPI/ExchangeItemForReward"):InvokeServer("summerfest_2025_sticker_pack", uidToOpen)
                                        
                                        print("Opened Sticker Pack: " .. uidToOpen)
                                    end)
                                    if not success then
                                        warn("Error during Sticker Pack open sequence for UID " .. uidToOpen .. ":", err)
                                    end
                                    wait(1) -- Short delay between opening each pack
                                end
                            else
                                print("Auto Open Sticker Pack: No more 'summerfest_2025_sticker_pack' packs found in inventory. Stopping auto-open.")
                                autoOpenStickerPackEnabled = false
                                break
                            end
                            wait(2) -- Longer delay before re-checking inventory for new packs
                        end
                        print("Auto Open Sticker Pack: Loop ended.")
                    end)
                else
                    print("Auto Open Sticker Pack: Toggle is OFF.")
                end
            end
        })
    end

    -- --- CONSOLIDATED AUTO-BUY SECTION ---
    local autoBuyDropdownOptions = {}
    for _, item in ipairs(allBuyableItems) do
        table.insert(autoBuyDropdownOptions, item.name)
    end
    local initialAutoBuyOption = autoBuyDropdownOptions[1] or "No items available"

    if not AutoBuyItemDropdown then
        AutoBuyItemDropdown = EventTab:CreateDropdown({
            Name = "Select Item to Auto-Buy",
            Options = autoBuyDropdownOptions,
            CurrentOption = {initialAutoBuyOption},
            MultipleOptions = false,
            Flag = "AutoBuyItemSelection",
            Callback = function(selectedOptions)
                local selectedName = selectedOptions[1]
                local selectedItem = nil
                for _, item in ipairs(allBuyableItems) do
                    if item.name == selectedName then
                        selectedItem = item
                        break
                    end
                end

                if selectedItem then
                    currentSelectedAutoBuyItemId = selectedItem.id
                    print("Selected item for auto-buy: " .. selectedItem.name .. " (ID: " .. selectedItem.id .. ")")
                    
                    -- Update slider and toggle to reflect the newly selected item's state
                    if AutoBuyAmountSlider then
                        AutoBuyAmountSlider:Set(autoBuyCounts[currentSelectedAutoBuyItemId] or selectedItem.defaultCount)
                    end
                    if AutoBuyGlobalToggle then
                        AutoBuyGlobalToggle:Set(autoBuyStates[currentSelectedAutoBuyItemId] or false)
                    end
                else
                    currentSelectedAutoBuyItemId = nil
                    warn("Selected unknown item in auto-buy dropdown: " .. tostring(selectedName))
                    if AutoBuyAmountSlider then AutoBuyAmountSlider:Set(1) end
                    if AutoBuyGlobalToggle then AutoBuyGlobalToggle:Set(false) end
                end
            end
        })
        -- Set initial selected item when dropdown is first created
        local initialSelectedItem = allBuyableItems[1]
        if initialSelectedItem then
            currentSelectedAutoBuyItemId = initialSelectedItem.id
            if AutoBuyAmountSlider then
                AutoBuyAmountSlider:Set(autoBuyCounts[currentSelectedAutoBuyItemId] or initialSelectedItem.defaultCount)
            end
        end
    end

    if not AutoBuyAmountSlider then
        AutoBuyAmountSlider = EventTab:CreateSlider({
            Name = "Amount to Buy (Selected Item)",
            Range = {1, 100}, -- Max amount to buy, adjust as needed
            Increment = 1,
            CurrentValue = (currentSelectedAutoBuyItemId and autoBuyCounts[currentSelectedAutoBuyItemId]) or 1,
            Compact = false,
            Flag = "AutoBuyAmountSlider",
            Callback = function(val)
                if currentSelectedAutoBuyItemId then
                    autoBuyCounts[currentSelectedAutoBuyItemId] = val
                    print("Buy amount for " .. currentSelectedAutoBuyItemId .. " set to: " .. val)
                end
            end,
        })
    else
        -- Ensure slider updates if selected item changes after initial creation
        if currentSelectedAutoBuyItemId then
            AutoBuyAmountSlider:Set(autoBuyCounts[currentSelectedAutoBuyItemId])
        end
    end

    if not AutoBuyGlobalToggle then
        AutoBuyGlobalToggle = EventTab:CreateToggle({
            Name = "Enable Auto-Buy (Selected Item)",
            CurrentValue = (currentSelectedAutoBuyItemId and autoBuyStates[currentSelectedAutoBuyItemId]) or false,
            Flag = "AutoBuyGlobalToggle",
            Callback = function(val)
                -- Stop any previous auto-buy loop
                for itemId, isBuying in pairs(autoBuyStates) do
                    if isBuying and itemId ~= currentSelectedAutoBuyItemId then
                        autoBuyStates[itemId] = false
                    end
                end
                
                if currentAutoBuyTask and currentAutoBuyTask.running then
                    task.cancel(currentAutoBuyTask)
                    currentAutoBuyTask = nil
                end

                autoBuyStates[currentSelectedAutoBuyItemId] = val
                
                if val then
                    if not currentSelectedAutoBuyItemId then
                        warn("Auto-Buy: No item selected in dropdown. Disabling auto-buy.")
                        AutoBuyGlobalToggle:Set(false) -- Turn off UI toggle
                        autoBuyStates[currentSelectedAutoBuyItemId] = false
                        return
                    end

                    local itemToBuy = nil
                    for _, item in ipairs(allBuyableItems) do
                        if item.id == currentSelectedAutoBuyItemId then
                            itemToBuy = item
                            break
                        end
                    end

                    if not itemToBuy then
                        warn("Auto-Buy: Selected item (" .. currentSelectedAutoBuyItemId .. ") not found in definitions. Disabling auto-buy.")
                        AutoBuyGlobalToggle:Set(false)
                        autoBuyStates[currentSelectedAutoBuyItemId] = false
                        return
                    end

                    currentAutoBuyTask = task.spawn(function()
                        while autoBuyStates[itemToBuy.id] do
                            local buyCount = autoBuyCounts[itemToBuy.id] or itemToBuy.defaultCount
                            print("Auto-Buy " .. itemToBuy.name .. ": Attempting to buy " .. buyCount .. " of " .. itemToBuy.category .. " " .. itemToBuy.id .. ".")
                            
                            local success, err = pcall(function()
                                local args = {
                                    itemToBuy.category,
                                    itemToBuy.id,
                                    { buy_count = buyCount }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("ShopAPI/BuyItem"):InvokeServer(unpack(args))
                                print("Successfully bought " .. buyCount .. " " .. itemToBuy.name .. "(s).")
                            end)
                            if not success then
                                warn("Error during Auto-Buy " .. itemToBuy.name .. ":", err)
                                autoBuyStates[itemToBuy.id] = false -- Turn off toggle on error
                                if AutoBuyGlobalToggle then AutoBuyGlobalToggle:Set(false) end -- Update UI toggle
                                break
                            end
                            wait(5) -- Wait 5 seconds between purchases
                        end
                        print("Auto-Buy " .. itemToBuy.name .. ": Loop ended.")
                    end)
                else
                    print("Auto-Buy: Toggle is OFF.")
                end
            end
        })
    else
        -- Ensure toggle updates if selected item changes after initial creation
        if currentSelectedAutoBuyItemId then
            AutoBuyGlobalToggle:Set(autoBuyStates[currentSelectedAutoBuyItemId])
        end
    end
    -- --- END CONSOLIDATED AUTO-BUY SECTION ---


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
