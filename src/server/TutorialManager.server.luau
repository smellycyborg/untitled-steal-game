local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules

local Tutorial = require(Modules.Tutorial)
local Data = require(Modules.Data)

Tutorial.ServerInit()
Tutorial.HasCompletedTutorial:Connect(function(player)
    if RunService:IsStudio() then
        return
    end
    Tutorial.SetTask(player, "")
    player:SetAttribute("CompletedTutorial", true)
    Data.UpdateData(player, "hasCompletedTutorial", true)
end)