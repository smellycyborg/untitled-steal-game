local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Tools = ReplicatedStorage:WaitForChild("Tools")

local TypedRemote = require(Packages:WaitForChild("typed-remote"))
local Signal = require(Packages:WaitForChild("signal"))

local PurchaseItem = TypedRemote.event("PurchaseItem", ReplicatedStorage) :: TypedRemote.Event<string, string>



local Shop = {}
local productFunctions: {[number]: () -> ()} = {}

local GamepassPerPlayer = {}


function Shop.InitClient()
    
end

function Shop.InitServer()
    if not RunService:IsServer() then
        return
    end

    local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

    productFunctions[1411364564] = function(_receipt, player)
        local clone = Tools:FindFirstChild("BigHand"):Clone()
        clone.Parent = player.Backpack
    end

    productFunctions[1412076351] = function(_receipt, player)
        local clone = Tools:FindFirstChild("SpeedCoil"):Clone()
        clone.Parent = player.Backpack
    end

    local function processReceipt(receiptInfo)
        local playerProductKey = receiptInfo.PurchaseId
        local purchased = false
        local success, result, errorMessage
    
        success, errorMessage = pcall(function()
            purchased = purchaseHistoryStore:GetAsync(playerProductKey)
        end)
    
        if success and purchased then
            return Enum.ProductPurchaseDecision.PurchaseGranted
        elseif not success then
            error("Data store error:" .. errorMessage)
        end
    
        local purchaseSuccess, isPurchaseRecorded = pcall(function()
            return purchaseHistoryStore:UpdateAsync(playerProductKey, function(alreadyPurchased)
                if alreadyPurchased then
                    return true
                end
    
                local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
                if not player then
                    return nil
                end
    
                local handler = productFunctions[receiptInfo.ProductId]
                local isSuccess, isResult = pcall(handler, receiptInfo, player)
          
                if not isSuccess or not isResult then
                    error("Failed to process a product purchase for ProductId: " .. tostring(receiptInfo.ProductId) .. " Player: " .. tostring(player) .. " Error: " .. tostring(isResult))
                    return nil
                end
    
                return true
            end)
        end)
    
        if not purchaseSuccess then
            error("Failed to process receipt due to data store error.")
            return Enum.ProductPurchaseDecision.NotProcessedYet
        elseif isPurchaseRecorded == nil then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        else
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end

    for _, player: Player in Players:GetPlayers() do
        task.spawn(function()
            if not player:HasAppearanceLoaded() then
                if not player.Character then
                    player.CharacterAdded:Wait()
                end
                player.CharacterAppearanceLoaded:Wait()
            end
            local success, result = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1411364564)
            end)
            if success then
                if result == true then
                    local clone = Tools:FindFirstChild("BigHand"):Clone()
                    clone.Parent = player:WaitForChild("Backpack")
                end
            else
                warn(result)
            end

            local success, result = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1412076351)
            end)
            if success then
                if result == true then
                    local clone = Tools:FindFirstChild("SpeedCoil"):Clone()
                    clone.Parent = player:WaitForChild("Backpack")
                end
            else
                warn(result)
            end
        end)
    end
    Players.PlayerAdded:Connect(function(player: Player)
        local function characterAdded(character)
            if GamepassPerPlayer[player] and GamepassPerPlayer[player][1411364564] then
                local clone = Tools:FindFirstChild("BigHand"):Clone()
                clone.Parent = player:WaitForChild("Backpack")
            else
                local success, result = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1411364564)
                end)

                if success then
                    if result == true then
                        local clone = Tools:FindFirstChild("BigHand"):Clone()
                        clone.Parent = player:WaitForChild("Backpack")

                        if not GamepassPerPlayer[player] then
                            GamepassPerPlayer[player] = {}
                        end

                        GamepassPerPlayer[player][1411364564] = true
                    end
                end
            end

            if GamepassPerPlayer[player] and GamepassPerPlayer[player][1412076351] then
                local clone = Tools:FindFirstChild("SpeedCoil"):Clone()
                clone.Parent = player:WaitForChild("Backpack")
            else
                local success, result = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1412076351)
                end)

                if success then
                    if result == true then
                        local clone = Tools:FindFirstChild("SpeedCoil"):Clone()
                        clone.Parent = player:WaitForChild("Backpack")

                        if not GamepassPerPlayer[player] then
                            GamepassPerPlayer[player] = {}
                        end

                        GamepassPerPlayer[player][1412076351] = true
                    end
                end
            end
        end

        if player.Character then
            characterAdded(player.Character)
        end
        player.CharacterAdded:Connect(characterAdded)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)  
        if GamepassPerPlayer[player] then
            GamepassPerPlayer[player] = nil
        end
    end)
    MarketplaceService.ProcessReceipt = processReceipt
end

Shop.PurchaseItem = PurchaseItem




return Shop