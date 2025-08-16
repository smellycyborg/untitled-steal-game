local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage.Config
local Modules = ReplicatedStorage.Modules

local Brainrots = require(Config.Brainrots)
local Actor = require(Modules.Actor)
local Money = require(Modules.Money)
local Matchmaking = require(Modules.Matchmaking)

local SpawnParts = Workspace.SpawnParts
local ActorSpawnArea = Workspace.ActorSpawnArea

local DEFAULT_SPAWN_TIME = 5
local DEFAULT_TIME_TO_CHANGE_TARGET = 20
local DEFAULT_Y = 3.3
local MAX_ACTORS = 23

local TimeSinceLastTarget = {}

local timeElapsed = 0

local function _getRandomPointInPart(part: BasePart): Vector3
	local size = part.Size
	local offset = Vector3.new(
		(math.random() - 0.5) * size.X,
		DEFAULT_Y,
		(math.random() - 0.5) * size.Z
	)
	return part.Position + offset
end

local function spawnActor(spawnPart, targetPart)
    local uniqueKey = HttpService:GenerateGUID()

    local targetPosition = targetPart.Position

    local brainrotCount = 0
    for name, data in Brainrots do
        brainrotCount += 1
    end
    local randomNumber = math.random(1, brainrotCount)

    local count = 0
    local randomName = ""
    for name, data in Brainrots do
        count += 1
        if count == randomNumber then
            randomName = name
        end
    end
    if randomName then
        Actor.new(uniqueKey, randomName, 50)
        Actor.SetTargetPosition(uniqueKey, targetPosition)
        Actor.Spawn(uniqueKey, spawnPart.Position)

        TimeSinceLastTarget[uniqueKey] = 18
    end
end

Actor.InitServer()
Actor.CompletedGoalTime:Connect(function(uniqueKey: string, team: string)
    local amount = Actor.GetAmount(uniqueKey)
    Money.Add(team, amount)
end)
Actor.PlayerEnteredTeamBase.OnServerEvent:Connect(function(player: Player, hasEnteredBase: boolean)
    warn(hasEnteredBase)
    if not hasEnteredBase then
        return
    end
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end
    local currentWeld = rootPart:FindFirstChild("WeldToActor")
    if not currentWeld then
        return
    end

    local serverPart = currentWeld.Part1
    local uniqueKey = serverPart.Name

    currentWeld:Destroy()
    serverPart.Anchored = true
    serverPart:SetAttribute("CarrierId", nil)

    player:SetAttribute("CarryingActor", false)

    local prompt = serverPart:FindFirstChild("ProximityPrompt")
    prompt.ActionText = "Steal"

    Actor.SetTeam(uniqueKey, player.Team.Name)

    local newTargetPos = _getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name))
    Actor.SetTargetPosition(uniqueKey, newTargetPos)

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end
    local brainrots = leaderstats:FindFirstChild("brainrots")
    brainrots.Value += 1
end)

RunService.PostSimulation:Connect(function(step: number)
    if Matchmaking.Active then
        timeElapsed += step

        if timeElapsed >= DEFAULT_SPAWN_TIME then
            timeElapsed = 0

            for _, folder in SpawnParts:GetChildren() do
                spawnActor(folder.ActorSpawn, folder.ActorTarget)
            end
        end
    end
end)