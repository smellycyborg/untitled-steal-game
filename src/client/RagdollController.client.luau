local loader = game:GetService("ReplicatedStorage"):WaitForChild("NodeModules"):WaitForChild("loader") :: ModuleScript
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("RagdollServiceClient"))
serviceBag:Init()
serviceBag:Start()