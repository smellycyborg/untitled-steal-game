local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage.Modules

local Matchmaking = require(Modules.Matchmaking)
local Actor = require(Modules.Actor)
local Gates = require(Modules.Gates)

local ActorParts = Workspace:WaitForChild("ActorParts")

local DEFAULT_BREAK_TIME = 6
local MAX_PLAYERS_PER_TEAM = 6
local DEFAULT_Y = 3.3

local timeElapsed = 0
local countdown = DEFAULT_BREAK_TIME

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
        if countdown <= 0 and Matchmaking.Active == false then
            countdown = 300
            Matchmaking.UpdateCountdown:FireAllClients(countdown)

            Matchmaking.Active = true
            Gates.Open({"Robbers", "Burglars"})

            for _, player in Players:GetPlayers() do
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
                            if #tempTeam:GetPlayers() <= 0 then
                                team = tempTeam
                            end
                        end
                    end
                    player.Team = team

                    local randomPosition = _getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name))
                    player.Character:PivotTo(CFrame.new(randomPosition))
                    break
                end
            end
        elseif countdown <= 0 and Matchmaking.Active == true then
            countdown = 0
            Matchmaking.UpdateCountdown:FireAllClients(countdown)

            Matchmaking.Active = false

            for _, part in ActorParts:GetChildren() do
                Actor.ClearActorByPart(part)
            end

            for _, player in Players:GetPlayers() do
                player.Team = Teams:FindFirstChild("Chillin")

                local randomPosition = _getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name))
                player.Character:PivotTo(CFrame.new(randomPosition))
                break
            end
        end
    end
end)
