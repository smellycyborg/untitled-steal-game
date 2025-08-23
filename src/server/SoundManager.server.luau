local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local SoundModule = require(Modules.Sound)

SoundModule.InitServer()