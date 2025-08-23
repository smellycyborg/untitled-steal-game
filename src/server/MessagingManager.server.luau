local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local Messaging = require(Modules.Messaging)

Messaging.ServerInit()