local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ReplicatedStorage.Modules

local Knockback = require(Modules.Knockback)
local Tool = require(Modules.Tool)
local Actor = require(Modules.Actor)

local DEFAULT_KNOCKBACK_TIME = 0.8
local DEFAULT_TIME_STAYING_DOWN = 2.5

local Registered = {}

Tool.SendResult.OnServerEvent:Connect(function(playerAttacking: Player, hitUserId: number, direction: Vector3)  
    if Registered[hitUserId] then
        return
    end

    Registered[hitUserId] = true

    local hitPlayer = Players:GetPlayerByUserId(hitUserId)
    if not hitPlayer then
        Registered[hitUserId] = false
        return
    end
    local hitCharacter = hitPlayer.Character
    if not hitCharacter then
        return
    end
    local hitHumanoid = hitCharacter:FindFirstChild("Humanoid")
    if not hitHumanoid then
        return
    end
    local hitRootPart = hitCharacter:FindFirstChild("HumanoidRootPart")
    if not hitRootPart then
        return
    end

    local currentWeld = hitRootPart:FindFirstChild("WeldToActor")
    if currentWeld then
        local serverPart = currentWeld.Part1
        local uniqueKey = serverPart.Name

        Actor.SetTeam(uniqueKey, nil)

        currentWeld:Destroy()
        serverPart.Anchored = true

        hitPlayer:SetAttribute("CarryingActor", false)

        local prompt = serverPart:FindFirstChild("ProximityPrompt")
        prompt.ActionText = "Pick Up"
    end

    hitHumanoid:AddTag("Ragdoll")
    Knockback.ActivateKnockback:FireClient(hitPlayer, DEFAULT_KNOCKBACK_TIME, direction)
    task.delay(DEFAULT_TIME_STAYING_DOWN, function()
        Registered[hitUserId] = false
        hitHumanoid:RemoveTag("Ragdoll")

        Tool.ClearRegistered:FireClient(playerAttacking, hitUserId)
    end)
end)