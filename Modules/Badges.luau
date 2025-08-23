local BadgeServiceRoblox = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = ReplicatedStorage:WaitForChild("Config")

local BadgeIds = require(Config:WaitForChild("BadgeIds"))

local Badges = {}

local PlayersWithVisitor: {Player} = {}
local TimePerPlayer: {[Player]: number} = {}

local function rewardBadge(player, badgeId)
    if not RunService:IsServer() then
        return
    end

	local success, hasBadge = pcall(BadgeServiceRoblox.UserHasBadgeAsync, BadgeServiceRoblox, player.UserId, badgeId)

    if not success then
        return warn("Error trying to process if a player then badge")
    else
        if not hasBadge then
			local awarded, errorMessage = pcall(BadgeServiceRoblox.AwardBadge, BadgeServiceRoblox, player.UserId, badgeId)
            if not awarded then
                warn(errorMessage)
            else
                print("Successfully gave ", player.Name, " the 'Visitor' badge.")
            end
        else
            -- table.insert(PlayersWithVisitor, player.UserId)
        end
    end
end

function Badges.InitServer()
    if not RunService:IsServer() then
        return
    end

    local function characterAppearanceLoaded(character)
		local player = Players:GetPlayerFromCharacter(character)

		rewardBadge(player, BadgeIds.Visitor)
	end

	local function playerAdded(player)
		player.CharacterAppearanceLoaded:Connect(characterAppearanceLoaded)

        TimePerPlayer[player] = tick()

        -- UpdateVisitors:Fire(player, PlayersWithVisitor)
	end

    local function playerRemoving(player)
        TimePerPlayer[player] = nil
    end

    task.spawn(function()
        while task.wait(10) do
            for player, timePlayed in TimePerPlayer do
                local hasPlayedTwentyMinutes = (tick() - timePlayed) > (20 * 60)
                if hasPlayedTwentyMinutes then
                    rewardBadge(player, BadgeIds.Player)

                    TimePerPlayer[player] = nil
                end
            end
        end
    end)

    for _, player in Players:GetPlayers() do
        task.spawn(playerAdded, player)
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)
end

function Badges.addBadge(player: Player, badgeType: string)
    local badgeId = 0
    if badgeType == "" then
        return
    else
        badgeId = BadgeIds[badgeType]
    end
    rewardBadge(player, badgeId)
end

return Badges