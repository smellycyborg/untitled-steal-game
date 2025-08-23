local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local signal = require(Packages:WaitForChild("signal"))
local typed_remote = require(Packages:WaitForChild("typed-remote"))

local Currency = {}

local CurrencyPerPlayer: {[Player]: {[string]: number}} = {}

function Currency.ClientInit()
    local currency = {}
    local tempCurrency = {}

    Currency.UpdateCurrency.OnClientEvent:Connect(function(updatedCurrency)
        for userId, plrCurrency in updatedCurrency do
            currency[userId] = currency[userId] or {}
            tempCurrency[userId] = tempCurrency[userId] or {}

            for currencyType, amount in plrCurrency do
                local current = currency[userId][currencyType] or 0

                -- Update the target value
                currency[userId][currencyType] = amount

                -- If this currencyType isn't tracked yet, start at the old/current value
                if tempCurrency[userId][currencyType] == nil then
                    tempCurrency[userId][currencyType] = current
                end
            end
        end
    end)

    RunService.PreSimulation:Connect(function(dt)
        for userId, plrCurrency in tempCurrency do
            for currencyType, amount in plrCurrency do
                local target = currency[userId][currencyType]
                if amount < target then
                    -- Increment toward the target
                    tempCurrency[userId][currencyType] += 1

                    -- Fire the event (maybe optimize: only fire if any value changed)
                    Currency.TempCurrencyChanged:Fire(tempCurrency)

                    -- If we've reached the target, clean up
                    if tempCurrency[userId][currencyType] >= target then
                        tempCurrency[userId][currencyType] = target
                    end
                end
            end
        end
    end)
end

function Currency.Add(player: Player, currencyType: string, amount: number): boolean
    if not RunService:IsServer() then
        return false
    end

    local success, result = pcall(function(...)
        if not player or not player:IsDescendantOf(game) then
            return false
        end
        
        local playerCurrency = CurrencyPerPlayer[player]
        if not playerCurrency then
            playerCurrency = {}
            CurrencyPerPlayer[player] = playerCurrency
        end

        local currency = playerCurrency[currencyType]
        if not currency then
            currency = 0
            CurrencyPerPlayer[player][currencyType] = 0
        end
        
        CurrencyPerPlayer[player][currencyType] += amount

        local temp: {[string]: {[string]: number}} = {}
        for plr, plrCurrency in CurrencyPerPlayer do
            local userId = plr.UserId
            temp[tostring(userId)] = plrCurrency
        end

        Currency.UpdateCurrency:FireAllClients(temp)

        return true
    end)

    if not success then
        warn(result)
    end

    return success and result or false
end

Currency.TempCurrencyChanged = signal.new()

Currency.UpdateCurrency = typed_remote.event("UpdateCurrency", ReplicatedStorage) :: typed_remote.Event<{[string]: {[string]: number}}>

return Currency