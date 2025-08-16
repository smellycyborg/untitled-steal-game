local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Knockback = require(Modules:WaitForChild("Knockback"))

local player = Players.LocalPlayer

Knockback.ActivateKnockback.OnClientEvent:Connect(function(knockbackTime: number, direction: Vector3)
    local character = player.Character
    if character then
        Knockback.ApplyToCharacterInDirection(character, direction, knockbackTime)
    end
end)