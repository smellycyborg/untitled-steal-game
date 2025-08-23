local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local typed_remote = require(ReplicatedStorage.Packages["typed-remote"])

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Matchmaking = {}

Matchmaking.Active = false

local function _getRandomPointInPart(part: BasePart): Vector3
	local size = part.Size
	local offset = Vector3.new(
		(math.random() - 0.5) * size.X,
		part.Position.Y + 4,
		(math.random() - 0.5) * size.Z
	)
	return part.Position + offset
end

function Matchmaking.InitServer()
    local matchActive = Instance.new("BoolValue", ReplicatedStorage)
    matchActive.Name = "MatchStatus"
    matchActive.Value = false
    
    local function playerAdded(player: Player)
        player.Team = Teams:WaitForChild("Chillin")

        local function characterAdded(character)
            local rootPart = character:WaitForChild("HumanoidRootPart", 5)
            if not rootPart then
                return
            end

            rootPart.CFrame = CFrame.new(_getRandomPointInPart(Workspace:FindFirstChild(player.Team.Name .. "Spawn")))
        end

        local hasAppearanceLoaded = player:HasAppearanceLoaded()
        if not hasAppearanceLoaded then
            player.CharacterAppearanceLoaded:Wait()
        end

        if Matchmaking.Active == true then
            Matchmaking.TeamChoiceEnabled:FireClient(player, true)
        end

        if player.Character then
            characterAdded(player.Character)
        end
        player.CharacterAdded:Connect(characterAdded)
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