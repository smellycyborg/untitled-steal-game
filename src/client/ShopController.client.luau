local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Components = ReplicatedStorage:WaitForChild("Components")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Shop = require(Components:WaitForChild("Shop"))
local Vide = require(Packages:WaitForChild("vide"))

local enabled = Vide.source(false)

Vide.mount(function()
    return Shop {
        enabled = enabled,
    }
end, Players.LocalPlayer:WaitForChild("PlayerGui"))
