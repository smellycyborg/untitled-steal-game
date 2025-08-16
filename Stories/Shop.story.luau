local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")

local Vide = require(Packages:WaitForChild("vide"))
local Shop = require(Components:WaitForChild("Shop"))

return function(target)
    return Vide.mount(function() return Shop {
        enabled = Vide.source(false),
    } end, target)
end
