local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local signal = require(Packages:WaitForChild("signal"))
local typed_remote = require(Packages:WaitForChild("typed-remote"))

local TIME_UNTIL_NEXT_ATTACK = 0.4

local Tool = {}

local childAddedConn: RBXScriptConnection?
local childRemovedConn: RBXScriptConnection?
local activatedConns: {[string]: RBXScriptConnection} = {}

local Registered = {}
local PlayersAttacking = {}

function Tool.InitClient()
    local player = Players.LocalPlayer

    local function characterAdded(character: Model)
        childAddedConn = character.ChildAdded:Connect(function(child: Instance)
            if not child:IsA("Tool") then
                return
            end

            if child.Name == "SpeedCoil" then
                local humanoid = character:FindFirstChild("Humanoid")
                if not humanoid then
                    return
                end

                humanoid.WalkSpeed = 40
                humanoid.JumpPower = 100
            end
            activatedConns[child.Name] = child.Activated:Connect(function(...: any)
                if child.Name == "Club" or child.Name == "BigHand" then
                    if not PlayersAttacking[player.UserId] then
                        PlayersAttacking[player.UserId] = child
                        task.delay(TIME_UNTIL_NEXT_ATTACK, function()
                            PlayersAttacking[player.UserId] = nil
                        end)

                        Tool.StartedAttacking:Fire(child.Name)
                        Tool.PlayerAttacked:FireServer()

                        -- print(`{child.Name} Activated.  Player is Attacking.`)
                    end
                end
            end)
        end)

        childRemovedConn = character.ChildRemoved:Connect(function(child: Instance)  
            if activatedConns[child.Name] then
                activatedConns[child.Name]:Disconnect()
                activatedConns[child.Name] = nil
            end

            if child.Name == "SpeedCoil" then
                local humanoid = character:FindFirstChild("Humanoid")
                if not humanoid then
                    return
                end

                humanoid.WalkSpeed = 28
                humanoid.JumpPower = 50
            end
        end)
    end

    if player.Character then
        characterAdded(player.Character)
    end
    player.CharacterAdded:Connect(characterAdded)
    player.CharacterRemoving:Connect(function(character: Model) 
        for key, _conn in activatedConns do
            activatedConns[key]:Disconnect()
            activatedConns[key] = nil
        end 
        
        if childAddedConn then
            childAddedConn:Disconnect()
            childAddedConn = nil
        end
        if childRemovedConn then
            childRemovedConn:Disconnect()
            childRemovedConn = nil
        end
    end)

    RunService.PreSimulation:Connect(function(step)
        for attackingUserId, model in PlayersAttacking do
            local plr = Players:GetPlayerByUserId(attackingUserId)
            if not plr then
                continue
            end
            local character = plr.Character
            if not character then
                continue
            end

            local roothPart = character:FindFirstChild("HumanoidRootPart")
            if not roothPart then
                continue
            end

            local hitUserId = Tool.PerformRaycastOnModel(plr, model)
            if hitUserId and not Registered[hitUserId] then
                print("Should be registerring hit.")
                Registered[hitUserId] = true

                local hitPlayer = Players:GetPlayerByUserId(hitUserId)
                if not hitPlayer then
                    Registered[hitUserId] = false
                    continue
                end
                local hitCharacter = hitPlayer.Character
                if not hitCharacter then
                    Registered[hitUserId] = false
                    continue
                end

                local hitRootPart = hitCharacter:FindFirstChild("HumanoidRootPart")
                if not hitRootPart then
                    Registered[hitUserId] = false
                    continue
                end

                local direction = (hitRootPart.Position - roothPart.Position).Unit
                Tool.SendResult:FireServer(hitUserId, direction)
            end
        end
    end)

    --[[
    local Backpack = player:WaitForChild("Backpack")

    local function toolAdded(tool: Tool?)
        if tool then
            print(tool.Name)
        end
    end
    for _, tool in Backpack:GetChildren() do
        task.spawn(toolAdded, tool)
    end
    Backpack.ChildAdded:Connect(toolAdded)
    ]]
end

function Tool.PerformRaycastOnModel(playerPerforming: Player, tool: Tool)
    if not playerPerforming.Character then
        return false
    end
    local handle = tool:FindFirstChild("Handle") -- base of the sword
    local tip = tool:FindFirstChild("Tip", true) -- tip of the sword
    if not handle or not tip then
        warn("Invalid handle or tip")
        return false
    end

    local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {playerPerforming.Character, tool}

    local result = workspace:Blockcast(handle.CFrame, Vector3.new(1, 1, 1), (tip.Position - handle.Position).Unit * 5, raycastParams)

    if result then
        if result.Instance.Parent and Players:GetPlayerFromCharacter(result.Instance.Parent) then
            local userId = Players:GetPlayerFromCharacter(result.Instance.Parent).UserId
            return userId
        else
            return false
        end
    else
        return false
    end
end

function Tool.ClearRegisteredForUserIds(hitUserId: number)
    Registered[hitUserId] = nil
end

Tool.StartedAttacking = signal.new()

Tool.SendResult = typed_remote.event("SendResult", ReplicatedStorage) :: typed_remote.Event<number, Vector3>
Tool.ClearRegistered = typed_remote.event("ClearRegisteredForUserId", ReplicatedStorage) :: typed_remote.Event<number>
Tool.PlayerAttacked = typed_remote.event("PlayerAttacked", ReplicatedStorage) :: typed_remote.Event<>

return Tool