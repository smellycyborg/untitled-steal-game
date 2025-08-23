local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Messaging = require(Modules:WaitForChild("Messaging"))

Messaging.ClientInit()