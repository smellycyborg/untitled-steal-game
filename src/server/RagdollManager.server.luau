local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.NodeModules:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.NodeModules)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("RagdollService"))
serviceBag:Init()
serviceBag:Start()

local ragdollService = require("RagdollService")
ragdollService:Init(serviceBag)
ragdollService:SetRagdollOnDeath(true)
ragdollService:SetRagdollOnFall(false)
ragdollService:SetUnragdollAutomatically(false)