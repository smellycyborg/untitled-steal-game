local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Ragdoll = require(Modules:WaitForChild("Ragdoll"))

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local animateScript = character:FindFirstChild("Animate")
if animateScript then
    animateScript.Disabled = true
end

local animator = humanoid:WaitForChild("Animator")
for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
    track:Stop(0)
end

humanoid.PlatformStand = true
humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
Ragdoll.RagdollCharacter(character)