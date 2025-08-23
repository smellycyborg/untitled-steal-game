local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage.Config
local Modules = ReplicatedStorage.Modules
local Actors = ReplicatedStorage.Actors

local Notifications = require(Modules.Notifications)
local Brainrots = require(Config.Brainrots)
local Actor = require(Modules.Actor)
local Money = require(Modules.Money)
local Matchmaking = require(Modules.Matchmaking)
local Sound = require(Modules.Sound)
local Tutorial = require(Modules.Tutorial)

local SpawnParts: Folder = Workspace.SpawnParts
local ActorStandsPerTeam: Folder = Workspace.ActorStandsPerTeam
local ActorSpawnArea: BasePart = Workspace.ActorSpawnArea

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
        if not Actors:FindFirstChild(randomName) then
            repeat
                RunService.PostSimulation:Wait()

                randomNumber = math.random(1, brainrotCount)

                count = 0
                randomName = ""
                for name, data in Brainrots do
                    count += 1
                    if count == randomNumber then
                        randomName = name
                    end
                end
            until Actors:FindFirstChild(randomName)
        end

        Actor.new(uniqueKey, randomName, Brainrots[randomName].moneyPerTime)
        Actor.SetTargetPosition(uniqueKey, targetPosition)
        Actor.Spawn(uniqueKey, spawnPart.Position)

        TimeSinceLastTarget[uniqueKey] = 18
    end
end

Actor.InitServer()
Actor.Dropped:Connect(function(part)
    Sound.PlaySoundEffectServer:FireAllClients(part, "Exclamation")
end)
Actor.PickedUp:Connect(function(uniqueKey: string, player: Player)
    local part = Workspace.ActorParts:FindFirstChild(uniqueKey)
    if part then
        if not player:GetAttribute("CompletedTutorial") or RunService:IsStudio() then
            Tutorial.SetTask(player, "CAPTURE")
        end
        Sound.PlaySoundEffectServer:FireAllClients(part, "Help")
    end
end)
Actor.Stolen:Connect(function(uniqueKey: string, userId: number)  
    local part = Workspace.ActorParts:FindFirstChild(uniqueKey)
    if part then
        local actorTeam = Actor.GetActorName(uniqueKey)
        local playerStealing = Players:GetPlayerByUserId(userId)
        local displayName = playerStealing.DisplayName

        -- Set actor target (because they are not in a team anymore)
        local targets = {}
        for _, targetPart in SpawnParts:GetDescendants() do
            if part:IsA("BasePart") and string.find(targetPart.Name, "Target") then
                table.insert(targets, targetPart) 
            end
        end
        if not next(targets) then
            error("there are no target parts")
        end
        Actor.SetTargetPosition(uniqueKey, targets[math.random(1, #targets)].Position)

        -- Reset folder name to "Folder" remnoving that it is associated with a key
        for _, team in Teams:GetTeams() do
            if team.Name == "Chillin" then
                continue
            end
            local teamStandsFolder = ActorStandsPerTeam:FindFirstChild(team.Name)
            for _, folder in teamStandsFolder:GetChildren() do
                if folder.Name == uniqueKey then
                    folder.Name = "Folder"
                end
                break
            end
        end

        Sound.PlaySoundEffectServer:FireAllClients(part, "Stealing")
        Notifications.SendFromServer:FireAllClients(
            `{displayName} Stole from [{actorTeam}]`,
            Color3.fromRGB(255, 113, 31),
            true
        )
    end
end)
Actor.PlayerDropped:Connect(function(player: Player)  
    player:SetAttribute("CarryingActor", false)
end)
Actor.CompletedGoalTime:Connect(function(uniqueKey: string, team: string)
    local amount = Actor.GetAmount(uniqueKey)
    if typeof(amount) ~= "number" then
        warn("Invalid amount")
        return
    end

    local teamStandsFolder = ActorStandsPerTeam:FindFirstChild(team)
    for _, folder in teamStandsFolder:GetChildren() do
        if folder.Name == uniqueKey then
            local serverPart = Workspace.ActorParts:FindFirstChild(uniqueKey)
            if serverPart:GetAttribute("HasMoney") == false then
                serverPart:SetAttribute("HasMoney", true)
            end
            Money.AddToActor(uniqueKey, amount)

            local moneyPerActor = {}
            for key, money in Money.GetMoneyPerActor() do
                moneyPerActor[key] = {
                    team = Actor.GetTeam(key),
                    money = money,
                }
            end

            Money.UpdateMoneyPerActor:FireAllClients(moneyPerActor)
            break
        end
    end
end)
Actor.PlayerEnteredTeamBase.OnServerEvent:Connect(function(player: Player, hasEnteredBase: boolean)
    if not hasEnteredBase then
        return
    end
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    local currentWeld = rootPart:FindFirstChild("WeldToActor")
    if not currentWeld then
        return
    end

    local serverPart = currentWeld.Part1
    local uniqueKey = serverPart.Name

    Actor.ClearWeld(player, uniqueKey)

    currentWeld:Destroy()

    serverPart.Anchored = true
    serverPart:SetAttribute("CarrierId", nil)
    serverPart:SetAttribute("Team", player.Team.Name)

    if serverPart:GetAttribute("AnimationState") ~= "running" then
        serverPart:SetAttribute("AnimationState", "running")
    end

    player:SetAttribute("CarryingActor", false)

    Sound.PlaySoundEffectServer:FireAllClients(serverPart, "MagicalWingFlutter")

    humanoid.WalkSpeed = 26

    local prompt = serverPart:FindFirstChild("ProximityPrompt")
    if prompt then
        prompt.ActionText = "Steal"
        prompt.HoldDuration = 0.7
    end

    Actor.SetTeam(uniqueKey, player.Team.Name)

    local teamStandsFolder = ActorStandsPerTeam:FindFirstChild(player.Team.Name)
    local newTargetPos 
    for _, folder in teamStandsFolder:GetChildren() do
        if folder.Name ~= "Folder" then
            continue
        end
        folder.Name = uniqueKey
        newTargetPos = folder:FindFirstChild("ActorStand").Position
        break
    end
    Actor.SetTargetPosition(uniqueKey, newTargetPos)

    if not player:GetAttribute("CompletedTutorial") or RunService:IsStudio() then
        Tutorial.SetTask(player, "COLLECT_MONEY")
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end
    local brainrots = leaderstats:FindFirstChild("brainrots")
    brainrots.Value += 1

    for _, plr in Players:GetPlayers() do
        if plr.Team == player.Team then
            Notifications.SendFromServer:FireClient(
                plr,
                `{player.DisplayName} Captured a Brainrot {Brainrots[Actor.GetActorName(uniqueKey)].displayName}`,
                Color3.fromRGB(255, 238, 0)
            )
        end
    end
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