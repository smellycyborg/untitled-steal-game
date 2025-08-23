local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local Data = require(Modules.Data)
local Currency = require(Modules.Currency)

Data.InitServer()
Data.StartServer()
Data.UpdateValue:Connect(function(player: Player, name: string, amount:number)  
    Currency.Add(player, name, amount)
end)