local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")

local Vide = require(Packages:WaitForChild("vide"))
local Countdown = require(Components:WaitForChild("Countdown"))

return function(target)
    return Vide.mount(function() return Countdown {
        countdown = Vide.source(124),
    } end, target)
end
