local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local typed_remote = require(Packages["typed-remote"])

local Money = {}

local TeamPerPlayer: {[Player]: string} = {}
local MoneyPerTeam: {[string]: number} = {}

function Money.Add(team: string, amount: number): boolean | number
    local success, result = pcall(function()
        local prevMoney = MoneyPerTeam
        MoneyPerTeam[team] += amount

        Money.UpdateMoney:FireAllClients(prevMoney, MoneyPerTeam)

        return prevMoney
    end)

    if not success then
        warn(result)
    end

    return success and result or false
end

function Money.ClearTeams(): boolean
    local success, result = pcall(function()
        for team, _ in MoneyPerTeam do
            MoneyPerTeam[team] = 0
        end
        for player, _ in TeamPerPlayer do
            TeamPerPlayer[player] = nil
        end

        return true
    end)

    if not success then
        warn(result)
    end

    return success and result or false
end

function Money.GetTeams(): {[string]: number}
    return MoneyPerTeam
end


Money.UpdateMoney = typed_remote.event("UpdateMoney", ReplicatedStorage) :: typed_remote.Event<number, number>


return Money