local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")

local Vide = require(Packages:WaitForChild("vide"))
local TeamChoice = require(Components:WaitForChild("TeamChoice"))

return function(target)
    return Vide.mount(function() return TeamChoice {
        enabled = Vide.source(true),
        callback = function(name)
            print(name)
        end,
    } end, target)
end
