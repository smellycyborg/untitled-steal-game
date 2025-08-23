local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local Leaderstats = require(Modules.Leaderstats)

Leaderstats.ServerInit()
Leaderstats.ServerStart()