local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Functions = ReplicatedStorage:WaitForChild("Functions")

local Knockback = require(Modules:WaitForChild("Knockback"))
local TweenInstance = require(Functions:WaitForChild("TweenInstance"))

local DEFAULT_COLOR_TWEEN_TIME = 1
local MAX_PLAYERS = 16

local player = Players.LocalPlayer

local highlights = Instance.new("Folder", ReplicatedStorage)
highlights.Name = "Highlights"

for i = 1, MAX_PLAYERS do
    local highlight = Instance.new("Highlight", highlights)
    highlight.FillColor = Color3.fromRGB(255, 108, 108)
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
end

Knockback.ActivateKnockback.OnClientEvent:Connect(function(knockbackTime: number, direction: Vector3)
    local character = player.Character
    if character then
        Knockback.ApplyToCharacterInDirection(character, direction, knockbackTime)
    end
end)

Knockback.ShowEffects.OnClientEvent:Connect(function(userId: number)
    local otherPlayer = Players:GetPlayerByUserId(userId)
    if not otherPlayer then
        return
    end
    local otherCharacter = otherPlayer.Character
    if not otherCharacter then
        return
    end
    local otherRootPart = otherCharacter:FindFirstChild("HumanoidRootPart")
    if not otherRootPart then
        return
    end

    for _, highlight in highlights:GetChildren() do
        highlight.Parent = otherCharacter
        TweenInstance.Play(highlight, "FillTransparency", 0.6, 1, DEFAULT_COLOR_TWEEN_TIME, Enum.EasingStyle.Cubic, 
            Enum.EasingDirection.Out, true)

        task.delay(DEFAULT_COLOR_TWEEN_TIME * 2, function()
            highlight.Parent = highlights
            highlight.FillTransparency = 1
        end)
        break
    end
end)
