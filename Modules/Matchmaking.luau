local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local typed_remote = require(ReplicatedStorage.Packages["typed-remote"])

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Matchmaking = {}

Matchmaking.Active = false

function Matchmaking.InitServer()
    local function playerAdded(player: Player)
        player.Team = Teams:WaitForChild("Chillin")

        local hasAppearanceLoaded = player:HasAppearanceLoaded()
        if not hasAppearanceLoaded then
            player.CharacterAppearanceLoaded:Wait()
        end

        if Matchmaking.Active == true then
            Matchmaking.TeamChoiceEnabled:FireClient(player, true)
        end
    end

    for _, player in Players:GetPlayers() do
        task.spawn(playerAdded, player)
    end
    Players.PlayerAdded:Connect(playerAdded)
end

function Matchmaking.InitClient()
    
end

function Matchmaking.GetActive()
    return Matchmaking.Active
end

Matchmaking.TeamChoiceEnabled = typed_remote.event("SetTeamChoice", ReplicatedStorage)
Matchmaking.SetTeamByChoice = typed_remote.event("SetTeamByChoice", ReplicatedStorage)
Matchmaking.UpdateCountdown = typed_remote.event("UpdateCountdown", ReplicatedStorage)

return Matchmaking