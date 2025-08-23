local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage.Packages

local Signal = require(Packages:WaitForChild("signal"))
local ProfileService = require(Packages:WaitForChild("profileservice"))

local TEST_KEY = "214"
local LIVE_KEY = "4"

local Data = {}

local Profiles = {}
local tasks = {}
local DataTaskPerPlayer = {}

function Data.InitServer()
    if not RunService:IsServer() then
        return
    end

    local DataTemplate = {
        wins = 0,
        brainrots = 0,
    }

    -- profile service profile store
   gameProfileStore = ProfileService.GetProfileStore(RunService:IsStudio() and TEST_KEY or LIVE_KEY, DataTemplate)
end

function Data.StartServer()
    if not RunService:IsServer() then
        return
    end
    -- local BadgeService = Knit.GetService("BadgesService")
    -- local LeaderstatService = Knit.GetService("LeaderstatsService")
    
    local function playerAdded(player)
        local playerProfile = gameProfileStore:LoadProfileAsync("Player_" .. player.UserId)

        local leaderstats = Instance.new("Folder", player)
        leaderstats.Name = "leaderstats"

        local wins = Instance.new("IntValue", leaderstats)
        wins.Name = "wins"
        wins.Value = 0

        local brainrots = Instance.new("IntValue", leaderstats)
        brainrots.Name = "brainrots"
        brainrots.Value = 0

        if playerProfile then
            playerProfile:AddUserId(player.UserId)
            playerProfile:Reconcile()
    
            playerProfile:ListenToRelease(function()
                Profiles[player] = nil
                player:Kick("Profile released")
            end)
    
            if player:IsDescendantOf(Players) then
                tasks[player] = task.spawn(function()
                    Profiles[player] = playerProfile

                    local playerData = Profiles[player].Data

                    local playerPoints = playerData.Points or 0
                    local playerCurrency = playerData.tickets
                    if playerCurrency then
                        Data.UpdateValue:Fire(player, "tickets", playerCurrency)
                    end

                    if playerData.hasCompletedTutorial then
                        player:SetAttribute("CompletedTutorial", true)
                    end

                    warn(player.Name .. " points " .. playerPoints)

                    -- update player values
                    wins.Value = playerData.wins or 0
                    brainrots.Value = playerData.brainrots or 0

                    local function updateValue(valueObject, key)
                        valueObject:GetPropertyChangedSignal("Value"):Connect(function()
                            if not Profiles[player] then
                                return
                            end

                            Profiles[player].Data[key] = valueObject.Value
                        end)
                    end
                    updateValue(wins, "wins")
                    updateValue(brainrots, "brainrots")
        
                    -- print("Profile loaded.")
                    print("Player Data:  ", Profiles[player].Data)
                    tasks[player] = nil
                end)
            else
                playerProfile:Release()
            end
        else
            player:Kick("Profile failed to load. Please rejoin")
        end
    end

    local function playerRemoving(player)
        if DataTaskPerPlayer[player] then
            task.cancel(DataTaskPerPlayer[player])
            DataTaskPerPlayer[player] = nil
        end

        local playerProfile = Profiles[player]
        if playerProfile then
            playerProfile:Release()
        end

        if tasks[player] then
            task.cancel(tasks[player])
            tasks[player] = nil
        end
    end

    for _, player in Players:GetChildren() do
        task.spawn(playerAdded, player)
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)
end

function Data.UpdateData(player, key, value, isAdd)
	local function waitForProfile()
		local profile = Profiles[player]
		if profile then return profile end

		repeat
			RunService.PostSimulation:Wait()
			profile = Profiles[player]
		until profile

		return profile
	end

	DataTaskPerPlayer[player] = task.spawn(function()
		local playerProfile = waitForProfile()

		if not playerProfile or typeof(playerProfile.Data) ~= "table" then
			warn(`UpdateData() -> No profile or data table for {player.Name}`)
			return
		end

		if typeof(value) ~= typeof(playerProfile.Data[key]) and playerProfile.Data[key] ~= nil then
			warn(`UpdateData() -> Type mismatch on {key} for {player.Name}`)
			return
		end

		if isAdd then
			local before = playerProfile.Data[key] or 0
			playerProfile.Data[key] = before + value
			print(`UpdateData() -> Added {value} to {key} → total: {playerProfile.Data[key]}`)
		else
			playerProfile.Data[key] = value
			print(`UpdateData() -> Set {key} to {value}`)
		end
	end)
end

function Data.Get(player)
    return Profiles[player]
end

Data.PointsObserver = Signal.new()
Data.UpdateValue = Signal.new()

return Data