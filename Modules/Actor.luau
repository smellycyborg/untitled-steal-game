local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
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
local DEFAULT_STANDING_GOAL_TIME = 5

local DEFAULT_ACTOR_AREA_SIZE = Vector3.new(300, 0, 300)
local DEFAULT_ACTOR_AREA_POSITION = Vector3.new(0, 0, 0)
local DEFAULT_ACTOR_MODEL_SIZE = Vector3.new(3, 3, 3)

local Actor = {}

local Actors = {}
local TargetPositionPerActor = {}
local TimeElapsedPerActor = {}
local ActorsCarried = {}
local ActorsCaged = {}
local StandingTimeElapsed = {}
local TeamPerActor = {}
local HasBeenPickedUp = {}
local WeldsPerPlayer = {}

Actor.HasSpawned = false

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
        for uniqueKey, team in TeamPerActor do
            local serverPart = ActorParts:FindFirstChild(uniqueKey)
            if not serverPart or not serverPart:IsA("BasePart") then
                continue
            end
            local targetPosition = TargetPositionPerActor[uniqueKey]
            if typeof(targetPosition) ~= "Vector3" then
                continue
            end
            local distanceBetweenTarget = (targetPosition - serverPart.Position).Magnitude
            if distanceBetweenTarget < TEST_DISTANCE + 0.4 then
                if not StandingTimeElapsed[uniqueKey] then
                    StandingTimeElapsed[uniqueKey] = 0
                end
                StandingTimeElapsed[uniqueKey] += step
                if StandingTimeElapsed[uniqueKey] >= Actors[uniqueKey].timeInterval then
                    StandingTimeElapsed[uniqueKey] = 0

                    Actor.CompletedGoalTime:Fire(uniqueKey, team)
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
                if not part:GetAttribute("HasBeenCarried") 
                and part:GetAttribute("AnimationState") ~= "walking" then
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
                    part:SetAttribute("AnimationState", "idle") 
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
    part:SetAttribute("HasMoney", false)
    part:SetAttribute("Hovering", false)

    local prompt = Instance.new("ProximityPrompt")
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0.35
    prompt.ActionText = "Pick Up"

    prompt.Triggered:Connect(function(player: Player)
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid then
            return
        end

        if not WeldsPerPlayer[player] then
            WeldsPerPlayer[player] = {}
        end

        local hasPickedUp = false

        local carryCount = 0
        for _ in WeldsPerPlayer[player] do
            carryCount += 1
        end

        local function pickUp()
            if carryCount >= 4 then
                return
            end

            player:SetAttribute("CarryingActor", true)

            prompt.ActionText = "Drop"
            prompt.HoldDuration = 0.35
            
            ActorsCarried[uniqueKey] = true
            HasBeenPickedUp[uniqueKey] = true
            TeamPerActor[uniqueKey] = nil

            humanoid.WalkSpeed = 18

            local function WeldParts(part0, part1)
                local weld = Instance.new("WeldConstraint")
                weld.Name = "WeldToActor"
                weld.Part0 = part0
                weld.Part1 = part1
                weld.Parent = part0
                
                WeldsPerPlayer[player][uniqueKey] = weld
            end
            
            local yOffset = Vector3.new(0, carryCount * 3.5, 0)
            local offset = rootPart.CFrame.Position + yOffset + (rootPart.CFrame.LookVector * 3) -- 3 studs to the side
            part.CFrame = CFrame.lookAt(offset, offset + rootPart.CFrame.LookVector, rootPart.CFrame.UpVector)

            WeldParts(rootPart, part)
            part.Anchored = false

            part:SetAttribute("CarrierId", player.UserId)
            part:SetAttribute("HasBeenCarried", true)
            part:SetAttribute("AnimationState", "freakOut")

            hasPickedUp = true

            Actor.PickedUp:Fire(uniqueKey, player)

            return true
        end

        humanoid:UnequipTools()
 
        for plr, welds in WeldsPerPlayer do
            for key, weld in welds do
                if key == uniqueKey then
                    local currentPart = weld.Part1
                    currentPart.Anchored = true
                    currentPart:FindFirstChild("ProximityPrompt").Enabled = true

                    weld:Destroy()

                    ActorsCarried[key] = nil
                    WeldsPerPlayer[plr][key] = nil

                    Actor.PlayerDropped:Fire(plr)
                end
            end
        end

        if prompt.ActionText == "Pick Up" then
            pickUp()
        elseif prompt.ActionText == "Drop" then
            if part:GetAttribute("AnimationState") ~= "running" then
                part:SetAttribute("AnimationState", "running") 
            end

            if part:GetAttribute("CarrierId") then
                part:SetAttribute("CarrierId", nil)
            end

            part:SetAttribute("CarrierId", nil)

            prompt.ActionText = "Pick Up"

            humanoid.WalkSpeed = 28


            if WeldsPerPlayer[player] and WeldsPerPlayer[player][uniqueKey] then
                WeldsPerPlayer[player][uniqueKey]:Destroy()
                WeldsPerPlayer[player][uniqueKey] = nil
            end

            carryCount = 0
            for _ in WeldsPerPlayer[player] do
                carryCount += 1
            end
            if carryCount <= 0 then
                player:SetAttribute("CarryingActor", false)
            end

            Actor.Dropped:Fire(part)
        elseif prompt.ActionText == "Steal" then
            -- Reset folder name to "Folder" remnoving that it is associated with a key
            for _, team in Teams:GetTeams() do
                if team.Name == "Chillin" then
                    continue
                end
                local teamStandsFolder = Workspace.ActorStandsPerTeam:FindFirstChild(team.Name)
                for _, folder in teamStandsFolder:GetChildren() do
                    if folder.Name == uniqueKey then
                        folder.Name = "Folder"
                    end
                    break
                end
            end

            if player.Team.Name ~= TeamPerActor[uniqueKey] then
                local success = pickUp()
                if success then
                    Actor.Stolen:Fire(uniqueKey, player.UserId)
                end
            else
                if part:GetAttribute("AnimationState") ~= "running" then
                    part:SetAttribute("AnimationState", "running") 
                end

                TeamPerActor[uniqueKey] = nil

                prompt.ActionText = "Pick Up"
                prompt.HoldDuration = 0.35

                local targets = {}
                for _, targetPart in Workspace.SpawnParts:GetDescendants() do
                    if part:IsA("BasePart") and string.find(targetPart.Name, "Target") then
                        table.insert(targets, targetPart) 
                    end
                end
                if not next(targets) then
                    error("there are no target parts")
                end
                Actor.SetTargetPosition(uniqueKey, targets[math.random(1, #targets)].Position)
            end
        end

        Actor.PlayerPickedUp:Fire(player, hasPickedUp)
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

    if HasBeenPickedUp[uniqueKey] then
        speed *= 1.35
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
    local serverPart = ActorParts:FindFirstChild(uniqueKey)
    if serverPart then
        serverPart:SetAttribute("Team", team)
    end
end

function Actor.ClearWelds(player: Player)
    if not WeldsPerPlayer[player] then
        return
    end
    for key, _weld in WeldsPerPlayer[player] do
        WeldsPerPlayer[player][key] = nil
    end
end

function Actor.ClearWeld(player: Player, uniqueKey: string)
    if WeldsPerPlayer[player] then
        WeldsPerPlayer[player][uniqueKey] = nil
    end
end

function Actor.SetTargetPosition(uniqueKey: string, position: Vector3)
    TargetPositionPerActor[uniqueKey] = position
end

function Actor.GetAmount(uniqueKey: string)
    return Actors[uniqueKey] and Actors[uniqueKey].amount
end

function Actor.GetActors()
    return Actors
end

function Actor.GetTeam(uniqueKey: string)
    return TeamPerActor[uniqueKey]
end

function Actor.GetTeams()
    return TeamPerActor
end

function Actor.GetActorName(uniqueKey: string): number
    return Actors[uniqueKey] and Actors[uniqueKey].name
end

function Actor.ClearActorByPart(part)
    local uniqueKey = part.Name
    if ActorsCaged[uniqueKey] then
        ActorsCaged[uniqueKey] = nil
    end
    if HasBeenPickedUp[uniqueKey] then
        HasBeenPickedUp[uniqueKey] = nil
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
Actor.Dropped = signal.new()
Actor.Stolen = signal.new()
Actor.PickedUp = signal.new()
Actor.PlayerPickedUp = signal.new()
Actor.PlayerDropped = signal.new()

Actor.PlayerEnteredTeamBase = typed_remote.event("PlayerEnteredTeamBase", ReplicatedStorage)

return Actor