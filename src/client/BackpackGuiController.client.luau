local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

player:GetAttributeChangedSignal("CarryingActor"):Connect(function(...: any)  
    local isCarryingActor = player:GetAttribute("CarryingActor")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, isCarryingActor == false)
end)