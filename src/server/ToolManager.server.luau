local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ReplicatedStorage.Modules

local Sound = require(Modules.Sound)
local Knockback = require(Modules.Knockback)
local Tool = require(Modules.Tool)
local Actor = require(Modules.Actor)

local DEFAULT_KNOCKBACK_TIME = 0.8
local DEFAULT_TIME_STAYING_DOWN = 2.5

local Registered = {}

Tool.PlayerAttacked.OnServerEvent:Connect(function(player)
    local character = player.Character
    if not character then
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end
    Sound.PlaySoundEffectServer:FireAllClients(rootPart, "Woosh")
end)
Tool.SendResult.OnServerEvent:Connect(function(playerAttacking: Player, hitUserId: number, direction: Vector3)
    local hitHumanoid: Humanoid | nil
    local success, result = pcall(function(...)  
        if Registered[hitUserId] then
            return false
        end

        Registered[hitUserId] = true

        local hitPlayer = Players:GetPlayerByUserId(hitUserId)
        if not hitPlayer then
            return false
        end
        local hitCharacter = hitPlayer.Character
        if not hitCharacter then
            return false
        end
        hitHumanoid = hitCharacter:FindFirstChild("Humanoid")
        if not hitHumanoid then
            return false
        end
        local hitRootPart = hitCharacter:FindFirstChild("HumanoidRootPart")
        if not hitRootPart then
            return false
        end

        Actor.ClearWelds(hitPlayer)

        for _, weld in hitRootPart:GetDescendants() do
            if weld.Name == "WeldToActor" then
                local serverPart = weld.Part1
                local uniqueKey = serverPart.Name

                if serverPart:GetAttribute("AnimationState") ~= "running" then
                    serverPart:SetAttribute("AnimationState", "running") 
                end

                if serverPart:GetAttribute("CarrierId") then
                    serverPart:SetAttribute("CarrierId", nil)
                end

                Actor.SetTeam(uniqueKey, nil)

                weld:Destroy()
                serverPart.Anchored = true

                hitPlayer:SetAttribute("CarryingActor", false)

                local prompt = serverPart:FindFirstChild("ProximityPrompt")
                prompt.ActionText = "Pick Up"
            end
        end

        hitHumanoid:AddTag("Ragdoll")

        Sound.PlaySoundEffectServer:FireAllClients(hitRootPart, "Club")
        Knockback.ActivateKnockback:FireClient(hitPlayer, DEFAULT_KNOCKBACK_TIME, direction)
        Knockback.ShowEffects:FireAllClients(hitUserId)

        return true
    end)

    task.delay(DEFAULT_TIME_STAYING_DOWN, function()
        if hitHumanoid then
            hitHumanoid:RemoveTag("Ragdoll")
        end

        Tool.ClearRegistered:FireClient(playerAttacking, hitUserId)

        Registered[hitUserId] = false
    end)

    if not success then
        warn(result)
    end
end)