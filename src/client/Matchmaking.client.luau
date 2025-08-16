local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")

local Vide = require(Packages:WaitForChild("vide"))
local Matchmaking = require(Modules:WaitForChild("Matchmaking"))
local TeamChoice = require(Components:WaitForChild("TeamChoice"))
local Countdown = require(Components:WaitForChild("Countdown"))

local teamChoiceEnabled = Vide.source(false)
local countdown = Vide.source(0)

Vide.mount(function() return TeamChoice {
    enabled = teamChoiceEnabled,
    callback = function(team)
        Matchmaking.SetTeamByChoice:FireServer(team)
    end,
} end, Players.LocalPlayer:WaitForChild("PlayerGui"))
Vide.mount(function() return Countdown {
    countdown = countdown,
} end, Players.LocalPlayer:WaitForChild("PlayerGui"))

Matchmaking.TeamChoiceEnabled.OnClientEvent:Connect(function(enabled: boolean)
    teamChoiceEnabled(enabled)
end)
Matchmaking.UpdateCountdown.OnClientEvent:Connect(function(newCountdown: number)
    countdown(newCountdown)
end)
