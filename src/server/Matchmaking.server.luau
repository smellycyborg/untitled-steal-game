local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage.Modules

local Data = require(ReplicatedStorage.Modules.Data)
local Messaging = require(Modules.Messaging)
local Sound = require(ReplicatedStorage.Modules.Sound)
local Matchmaking = require(Modules.Matchmaking)
local Actor = require(Modules.Actor)
local Gates = require(Modules.Gates)
local Money = require(Modules.Money)
local Tutorial = require(Modules.Tutorial)
local Currency = require(Modules.Currency)

local ActorParts = Workspace:WaitForChild("ActorParts")

local DEFAULT_BREAK_TIME = not RunService:IsStudio() and 16 or 6
local MAX_PLAYERS_PER_TEAM = 6
local DEFAULT_Y = 3.3
local DEFAULT_MATCH_TIME = not RunService:IsStudio() and 300 or 35

local timeElapsed = 0
local countdown = DEFAULT_BREAK_TIME

local notifiedMatchEnd = false

local function _getRandomPointInPart(part: BasePart): Vector3
	local size = part.Size
	local offset = Vector3.new(
		(math.random() - 0.5) * size.X,
		DEFAULT_Y,
		(math.random() - 0.5) * size.Z
	)
	return part.Position + offset
end

Matchmaking.InitServer()
Matchmaking.SetTeamByChoice.OnServerEvent:Connect(function(player: Player, team: string)
    if not Teams:FindFirstChild(team) then
        return
    end
    player.Team = Teams:FindFirstChild(team)
    Matchmaking.TeamChoiceEnabled:FireClient(player, false)

    for _, team in Teams:GetTeams() do
        local gateState = Gates.GetState(team.Name)
        local hasTimer = typeof(Gates.GetTimeLeft(team.Name)) == "number" and true or false
        Gates.ManageGate:FireClient(player, team.Name, gateState, hasTimer)
    end

    local rootPart = player.Character and player.Character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then
        return
    end

    rootPart.CFrame = CFrame.new(_getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name)))
end)

local function playerAdded(player: Player)
    if Matchmaking.Active then
        Matchmaking.TeamChoiceEnabled:FireClient(player, true)
        Matchmaking.TeamChoiceEnabled:FireClient(player, false)
    end
end

for _, player in Players:GetPlayers() do
    task.spawn(playerAdded, player)
end
Players.PlayerAdded:Connect(playerAdded)

RunService.PostSimulation:Connect(function(step)
    timeElapsed += step
    if timeElapsed >= 1 then
        timeElapsed = 0

        countdown -= 1
        Matchmaking.UpdateCountdown:FireAllClients(countdown)

        if Matchmaking.Active 
        and countdown == 30 
        and not notifiedMatchEnd then
            notifiedMatchEnd = true

            Messaging.PostServerMessage:FireAllClients("Match ends in 30 seconds!")
        end

        if countdown <= 0 and Matchmaking.Active == false then
            countdown = DEFAULT_MATCH_TIME
            Matchmaking.UpdateCountdown:FireAllClients(countdown)

            Messaging.PostServerMessage:FireAllClients("Match has started! Start stealing..")

            Matchmaking.Active = true
            ReplicatedStorage:FindFirstChild("MatchStatus").Value = true
            Gates.Open({"Robbers", "Burglars"})

            for _, team in Teams:GetTeams() do
                if team.Name == "Chillin" then
                    continue
                end
                Money.Add(team.Name, 0)
            end

            Sound.SetSong("Match")

            local lastTeam
            for _, player in Players:GetPlayers() do
                Tutorial.SetTask(player, "PICK_UP")

                for _, team in Teams:GetTeams() do
                    if team.Name == "Chillin" then
                        continue
                    end
                    if #team:GetPlayers() >= MAX_PLAYERS_PER_TEAM then
                        continue
                    end
                    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then
                        continue
                    end

                    -- check if there's nobody on the other team
                    if #team:GetPlayers() > 0 then
                        for _, tempTeam in Teams:GetTeams() do
                            if team == tempTeam or tempTeam.Name == "Chillin" then
                                continue
                            end
                            if #tempTeam:GetPlayers() <= 0 and tempTeam.Name ~= lastTeam then
                                team = tempTeam
                            end
                        end
                    end
                    if lastTeam ~= team.Name then
                        player.Team = team
                        lastTeam = team.Name
                    else
                        continue
                    end

                    local randomPosition = _getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name .. "Spawn"))
                    player.Character:PivotTo(CFrame.new(randomPosition))

                    break
                end
            end
        elseif countdown <= 0 and Matchmaking.Active == true then
            countdown = DEFAULT_BREAK_TIME
            notifiedMatchEnd = false

            Matchmaking.UpdateCountdown:FireAllClients(countdown)
            Matchmaking.Active = false

            ReplicatedStorage:FindFirstChild("MatchStatus").Value = false

            Sound.SetSong("Lobby")

            local winningTeam: string, winnerMoney: number
            for teamName, money in Money.GetTeams() do
                if not winningTeam or winnerMoney and winnerMoney < money then
                    winningTeam = teamName
                    winnerMoney = money
                end
            end

            if winningTeam then
                Messaging.PostServerMessage:FireAllClients(`{winningTeam} are the winners!`)
            end

            Money.ClearTeams()
            Money.UpdateMoneyPerActor:FireAllClients({})

            for _, part in ActorParts:GetChildren() do
                if part:GetAttribute("HasMoney") then
                    part:SetAttribute("HasMoney", false)
                end
                Actor.ClearActorByPart(part)
            end

            local teamStandsFolder = Workspace.ActorStandsPerTeam
            for _, teamFolder in teamStandsFolder:GetChildren() do
                for _, standFolder in teamFolder:GetChildren() do
                    if standFolder.Name ~= "Folder" then
                        standFolder.Name = "Folder"
                    end
                end
            end

            for _, player in Players:GetPlayers() do
                if player:GetAttribute("CarryingActor") then
                    player:SetAttribute("CarryingActor", false)
                end

                local currencyToAdd = 125
           
                if winningTeam == player.Team then
                    currencyToAdd = 225

                    local playerWins = player:FindFirstChild("wins", true)
                    if playerWins then
                        playerWins.Value += 1
                    end
                end

                player.Team = Teams:FindFirstChild("Chillin")

                local randomPosition = _getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name .. "Spawn"))
                player.Character:PivotTo(CFrame.new(randomPosition))

                Currency.Add(player, "tickets", currencyToAdd)
                Data.UpdateData(player, "tickets", currencyToAdd, true)

                local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    for _, weld in rootPart:GetChildren() do 
                        if weld.Name == "WeldToActor" then
                            weld:Destroy()
                        end
                    end
                    Sound.PlaySoundEffectServer:FireClient(player, rootPart, "MoneyAdded")
                end
            end
        end
    end
end)
