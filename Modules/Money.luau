local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local typed_remote = require(Packages:WaitForChild("typed-remote"))

local Money = {}

local TeamPerPlayer: {[Player]: string} = {}
local MoneyPerTeam: {[string]: number} = {}
local MoneyPerActor: {[string]: number} = {}

function Money.Add(team: string, amount: number): boolean | number
    local success, result = pcall(function()
        if not MoneyPerTeam[team] then
            MoneyPerTeam[team] = 0
        end
        local prevMoney = MoneyPerTeam[team]
        MoneyPerTeam[team] += amount

        Money.UpdateMoney:FireAllClients(prevMoney, MoneyPerTeam)

        return prevMoney
    end)

    if not success then
        warn(result)
    end

    return success and result or false
end

function Money.AddToActor(uniqueKey: string, amount: number)
    if not MoneyPerActor[uniqueKey] then
        MoneyPerActor[uniqueKey] = 0
    end
    MoneyPerActor[uniqueKey] += amount
end

function Money.ClearTeams(): boolean
    local success, result = pcall(function()
        for team, _ in MoneyPerTeam do
            MoneyPerTeam[team] = 0
        end
        for player, _ in TeamPerPlayer do
            TeamPerPlayer[player] = nil
        end

        for key, money in MoneyPerActor do
            MoneyPerActor[key] = nil
        end

        Money.UpdateMoney:FireAllClients(0, MoneyPerTeam)

        return true
    end)

    if not success then
        warn(result)
    end

    return success and result or false
end

function Money.GetActorMoney(uniqueKey: string): number
    local currentMoney = MoneyPerActor[uniqueKey]
    return currentMoney
end

function Money.ZeroActorMoney(uniqueKey: string)
    MoneyPerActor[uniqueKey] = 0
end

function Money.GetTeams(): {[string]: number}
    return MoneyPerTeam
end

function Money.GetMoneyPerActor()
    return MoneyPerActor
end


Money.UpdateMoney = typed_remote.event("UpdateMoney", ReplicatedStorage) :: typed_remote.Event<number, number>
Money.MoneyButtonTriggered = typed_remote.event("MoneyButtonTriggered", ReplicatedStorage) :: typed_remote.Event<BasePart>
Money.UpdateMoneyPerActor = typed_remote.event("UpdateMoneyPerActor", ReplicatedStorage)
Money.CollectedMoney = typed_remote.event("CollectedMoney", ReplicatedStorage)


return Money