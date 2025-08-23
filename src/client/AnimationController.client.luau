local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Animation = require(Modules:WaitForChild("Animation"))

local player = Players.LocalPlayer

local function characterAdded(character)
    Animation.LoadCharacter(character, tostring(player.UserId))
end

if player.Character then
    characterAdded(player.Character)
end
player.CharacterAdded:Connect(characterAdded)