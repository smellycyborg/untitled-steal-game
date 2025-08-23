local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local Shop = require(Modules.Shop)

Shop.InitServer()
