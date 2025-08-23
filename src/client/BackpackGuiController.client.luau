local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Animation = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animation"))

local player = Players.LocalPlayer

player:GetAttributeChangedSignal("CarryingActor"):Connect(function(...: any)  
    local isCarryingActor = player:GetAttribute("CarryingActor")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, isCarryingActor == false)
    if isCarryingActor then
        Animation.PlayAnimation:Fire("Carry", tostring(player.UserId))
    else
        Animation.StopAnimations:Fire(tostring(player.UserId))
    end
end)