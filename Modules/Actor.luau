local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Config = ReplicatedStorage:WaitForChild("Config")

local signal = require(Packages:WaitForChild("signal"))
local typed_remote = require(Packages:WaitForChild("typed-remote"))
local Brainrots = require(Config:WaitForChild("Brainrots"))

local DEFAULT_SPEED = 7
local TEST_DISTANCE = 3
local TIME_TO_CHANGE_POSITION = 15
local DEFAULT_STANDING_GOAL_TIME = 30

local DEFAULT_ACTOR_AREA_SIZE = Vector3.new(300, 0, 300)
local DEFAULT_ACTOR_AREA_POSITION = Vector3.new(0, 0, 0)
local DEFAULT_ACTOR_MODEL_SIZE = Vector3.new(3, 3, 3)

local Actor = {}

Actor.HasSpawned = false

local Actors = {}
local TargetPositionPerActor = {}
local TimeElapsedPerActor = {}
local ActorsCarried = {}
local ActorsCaged = {}
local StandingTimeElapsed = {}
local TeamPerActor = {}

local ActorParts: Folder
if RunService:IsServer() then
    ActorParts = Instance.new("Folder", Workspace)
    ActorParts.Name = "ActorParts"
end

function Actor.InitClient()
    if not RunService:IsClient() then
        return
    end

    local player = Players.LocalPlayer

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams:AddToFilter({Workspace:WaitForChild("Robbers"), Workspace:WaitForChild("Burglars")})

    RunService.PreSimulation:Connect(function(a0: number)
        local enteredBase = false
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end
        local currentWeld = rootPart:FindFirstChild("WeldToActor")
        if not currentWeld then
            return
        end

        local raycastResult = Workspace:Raycast(rootPart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -1, 0) * 100, raycastParams)
        if raycastResult and raycastResult.Instance
        and raycastResult.Instance.Name == player.Team.Name then
            Actor.PlayerEnteredTeamBase:FireServer(true)
        else
            if not enteredBase then
                Actor.PlayerEnteredTeamBase:FireServer(false)
            end
        end
    end)
end

function Actor.InitServer()
    if not RunService:IsServer() then
        return
    end

    local function _getRandomPosition(position: Vector3, 
        sizeX: number, 
        sizeZ: number, 
        modelSize: Vector3)
        local minX = position.X - sizeX / 2 + modelSize.X / 2
        local maxX = position.X + sizeX / 2 - modelSize.X / 2
        local minZ = position.Z - sizeZ / 2 + modelSize.Z / 2
        local maxZ = position.Z + sizeZ / 2 - modelSize.Z / 2

        local randomX = math.random(minX, maxX)
        local randomZ = math.random(minZ, maxZ)

        return Vector3.new(randomX, 1 + modelSize.Y / 2, randomZ)
    end

    RunService.PostSimulation:Connect(function(step: number)
        for uniqueKey, _ in ActorsCaged do
            local serverPart = ActorParts:FindFirstChild(uniqueKey)
            if not serverPart or not serverPart:IsA("BasePart") then
                continue
            end
            local targetPosition = TargetPositionPerActor[uniqueKey]
            if typeof(targetPosition) ~= "Vector3" then
                continue
            end
            local distanceBetweenTarget = (targetPosition - serverPart.Position).Magnitude
            if distanceBetweenTarget < 2 then
                if not StandingTimeElapsed[uniqueKey] then
                    StandingTimeElapsed[uniqueKey] = 0
                end
                StandingTimeElapsed[uniqueKey] += step
                if StandingTimeElapsed[uniqueKey] >= DEFAULT_STANDING_GOAL_TIME then
                    StandingTimeElapsed[uniqueKey] = 0

                    Actor.CompletedGoalTime:Fire(uniqueKey, TeamPerActor[uniqueKey])
                end
            end
        end

        for _, part in ActorParts:GetChildren() do
            local uniqueKey = part.Name
            if ActorsCarried[uniqueKey] then
                continue
            end
            local targetPosition = TargetPositionPerActor[uniqueKey]
            if typeof(targetPosition) ~= "Vector3" then
                warn("Invalid target position")
                continue
            end

            local speed = Actors[uniqueKey] and Actors[uniqueKey].speed
            if typeof(speed) ~= "number" then
                speed = DEFAULT_SPEED
            end

            local distanceBetweenTarget = (targetPosition - part.Position).Magnitude
            if distanceBetweenTarget > TEST_DISTANCE then
                if part:GetAttribute("AnimationState") ~= "walking" then
                    part:SetAttribute("AnimationState", "walking") 
                end
                Actor.Move(uniqueKey, step, speed)
            else
                if not TeamPerActor[uniqueKey] 
                or not Teams:FindFirstChild(TeamPerActor[uniqueKey]) then
                    Actor.ClearActorByPart(part)
                    continue
                end
                if part:GetAttribute("AnimationState") ~= "idle" then
                    part:SetAttribute("AnimationState", "idle ") 
                end
            end
        end
    end)
end

function Actor.new(uniqueKey: string, name: string, amount: number)
    local data = Brainrots[name]
    if typeof(data) ~= "table" then
        error("Invalid data for actor")
    end

    local instance = {}

    instance.name = name
    instance.amount = amount

    instance.displayName = data.displayName
    instance.moneyPerTime = data.moneyPerTime
    instance.timeInterval = data.timeInterval
    instance.rarity = data.rarity
    instance.speed = data.speed

    Actors[uniqueKey] = instance
end

function Actor.Spawn(uniqueKey: string, position: Vector3)
    local data = Actors[uniqueKey]
    if typeof(data) ~= "table" then
        error("Invalid data for actor")
    end

    local part = Instance.new("Part")
    part.Name = uniqueKey
    part.Transparency = 1
    part.Anchored = true
    part.Position = position
    part.CanCollide = false
    part.Massless = true

    part:SetAttribute("AnimationState", "idle")
    part:SetAttribute("DisplayName", data.displayName)
    part:SetAttribute("MoneyPerTime", data.moneyPerTime)
    part:SetAttribute("TimeInterval", data.timeInterval)
    part:SetAttribute("Rarity", data.rarity)
    part:SetAttribute("Name", data.name)

    local prompt = Instance.new("ProximityPrompt")
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0.7
    prompt.ActionText = "Pick Up"
    prompt.Triggered:Connect(function(player: Player)
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid then
            return
        end

        local function pickUp()
            player:SetAttribute("CarryingActor", true)

            prompt.ActionText = "Drop"
            
            ActorsCarried[uniqueKey] = true

            local function WeldParts(part0, part1)
                local weld = Instance.new("WeldConstraint")
                weld.Name = "WeldToActor"
                weld.Part0 = part0
                weld.Part1 = part1
                weld.Parent = part0
            end
            WeldParts(rootPart, part)
            part.Anchored = false
            part:SetAttribute("CarrierId", player.UserId)
            part:SetAttribute("AnimationState", "freakOut")
        end

        humanoid:UnequipTools()

        local currentWeld = rootPart:FindFirstChild("WeldToActor")
        if currentWeld then
            local currentPart = currentWeld.Part1
            currentPart.Anchored = true
            currentPart:FindFirstChild("ProximityPrompt").Enabled = true

            ActorsCarried[currentPart.Name] = nil

            currentWeld:Destroy()
        end

        if prompt.ActionText ~= "Drop" then
            pickUp()
        elseif prompt.ActionText == "Drop" then
            player:SetAttribute("CarryingActor", false)
            part:SetAttribute("CarrierId", nil)

            prompt.ActionText = "Pick Up"
        elseif prompt and prompt.ActionText ~= "Steal" then
            if player.Team.Name ~= TeamPerActor[uniqueKey] then
                TeamPerActor[uniqueKey] = nil
                
                pickUp()
            end
        end
    end)

    prompt.Parent = part
    part.Parent = ActorParts

    TimeElapsedPerActor[uniqueKey] = 0
end

function Actor.Move(uniqueKey: string, step: number, speed: number)
    if not RunService:IsServer() then
        return
    end

    if not TargetPositionPerActor[uniqueKey] then
        warn("Doesn't have target")
        return
    end

    local part = ActorParts:FindFirstChild(uniqueKey)
    if not part or not part:IsA("BasePart") then
        warn("Invalid part")
        return
    end

    local targetPosition = TargetPositionPerActor[uniqueKey]
    if typeof(targetPosition) ~= "Vector3" then
        warn("Invalid target position")
        return
    end

    local direction = (targetPosition - part.Position).Unit
    local newPosition = part.Position + (direction * step * speed)

    part.CFrame = CFrame.new(newPosition, targetPosition)
end

function Actor.SetTeam(uniqueKey: string, team: string | nil)
    if ActorsCarried[uniqueKey] then
        ActorsCarried[uniqueKey] = nil
    end
    TeamPerActor[uniqueKey] = team
end

function Actor.SetTargetPosition(uniqueKey: string, position: Vector3)
    TargetPositionPerActor[uniqueKey] = position
end

function Actor.GetAmount(uniqueKey: string)
    return Actors[uniqueKey] and Actors[uniqueKey].amount
end

function Actor.GetTeam(uniqueKey: string)
    return TeamPerActor[uniqueKey]
end

function Actor.ClearActorByPart(part)
    local uniqueKey = part.Name
    if ActorsCaged[uniqueKey] then
        ActorsCaged[uniqueKey] = nil
    end
    if ActorsCarried[uniqueKey] then
        ActorsCarried[uniqueKey] = nil
    end
    if TeamPerActor[uniqueKey] then
        TeamPerActor[uniqueKey] = nil
    end
    if StandingTimeElapsed[uniqueKey] then
        StandingTimeElapsed[uniqueKey] = nil
    end
    if TargetPositionPerActor[uniqueKey] then
        TargetPositionPerActor[uniqueKey] = nil
    end
    if TimeElapsedPerActor[uniqueKey] then
        TimeElapsedPerActor[uniqueKey] = nil
    end
    part:Destroy()
end

Actor.OnTeamSet = signal.new()
Actor.CompletedGoalTime = signal.new()

Actor.PlayerEnteredTeamBase = typed_remote.event("PlayerEnteredTeamBase", ReplicatedStorage)

return Actor