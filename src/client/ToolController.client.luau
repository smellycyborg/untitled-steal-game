local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Animation = require(Modules:WaitForChild("Animation"))
local Tool = require(Modules:WaitForChild("Tool"))

local player = Players.LocalPlayer

Tool.InitClient()
Tool.StartedAttacking:Connect(function(toolName: string)  
    Animation.PlayAnimation:Fire("Hack", tostring(player.UserId))
end)
Tool.ClearRegistered.OnClientEvent:Connect(function(hitUserId: number)
    Tool.ClearRegisteredForUserIds(hitUserId)
end)