local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages

local typed_remote = require(Packages:WaitForChild("typed-remote"))

local UPDATE_LEADERSTATS_INTERVAL = 5
local UPDATE_GLOBAL_PER_PLAYER_INTERVAL = 5
local UPDATE_GLOBAL_INTERVAL = 1.5 * 60
local MAX_PAGE = 14

local GLOBAL_DATA
if RunService:IsServer() then
    local DataStoreService = game:GetService("DataStoreService")
    GLOBAL_DATA = {
        brainrots = DataStoreService:GetOrderedDataStore("KILLS_GLOBAL_1"),
        wins = DataStoreService:GetOrderedDataStore("WINS_GLOBAL_1"),
    }
end

local Leaderstats = {}

local LeaderstatsPerPlayer = {}
local SortedLeaderstats = {}
local GlobalLeaderstats = {}

function Leaderstats.ServerInit()
    SortedLeaderstats["brainrots"] = {}
    SortedLeaderstats["wins"] = {}

    local function playerAdded(player)
        LeaderstatsPerPlayer[player] = {}

        local leaderstats = player:WaitForChild("leaderstats")

        LeaderstatsPerPlayer[player]["brainrots"] = leaderstats:WaitForChild("brainrots").Value
        LeaderstatsPerPlayer[player]["wins"] = leaderstats:WaitForChild("wins").Value
    end

    local function playerRemoving(player)
        LeaderstatsPerPlayer[player] = nil
    end

    for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)

    --print("LeaderstatsService initialized.")
end

function Leaderstats.updateLeaderstats()
    for _, player in Players:GetPlayers() do
        local playerLeaderstats = player:FindFirstChild("leaderstats")
        if not playerLeaderstats then
            continue
        end

        for _, leaderStat in playerLeaderstats:GetChildren() do
            LeaderstatsPerPlayer[player][leaderStat.Name] = leaderStat.Value
        end
    end
end

function Leaderstats.sortLeaderstats(...)
    for _, value in {...} do
        local convertedValueTable = {}
        for playerKey, valueKeys in LeaderstatsPerPlayer do
            for valueKey, valueKeyValue in valueKeys do
                if valueKey == value then
                    table.insert(convertedValueTable, {player = playerKey, value = valueKeyValue})
                end
            end
        end

        table.sort(convertedValueTable, function(a, b)
            return a.value > b.value
        end)

        SortedLeaderstats[value] = convertedValueTable
        
        Leaderstats.SortedLeaderstatsChanged:FireAllClients(SortedLeaderstats)
    end
end

function Leaderstats.ServerStart()
    task.spawn(function()
        while task.wait(UPDATE_LEADERSTATS_INTERVAL) do

            Leaderstats.updateLeaderstats()
            Leaderstats.sortLeaderstats("brainrots", "wins") -- add whatever leaderstats you have

            -- print("Updated Leaderstats:  ", self.SortedLeaderstats)
        end
    end)

    task.spawn(function()
        Leaderstats.updateGlobalData()

        while task.wait(UPDATE_GLOBAL_INTERVAL) do
            
            Leaderstats.updateGlobalData()

        end
    end)

    -- print("LeaderstatsService started.")
end

function Leaderstats.updatePlayerGlobalData(player, dataName, dataValue)
    -- warn("Player:  ", player)
    -- warn("DataName:  ", dataName)
    -- warn("DataValue:  ", dataValue)

    if not player or not dataName or not dataValue then
        return -- warn("attempt to index nil with argument/s player: ", player, "  dataName: ", dataName, "  dataValue: ", dataValue)
    end

    if not GLOBAL_DATA[dataName] then
        return -- warn("data name ", dataName, " does not exist for global data")
    end

    local DatastoreToGlobal: OrderedDataStore = GLOBAL_DATA[dataName]
    if not DatastoreToGlobal then
        return false
    end

    local success, result = pcall(function()
        return DatastoreToGlobal:SetAsync(player.UserId, dataValue)
    end)

    if success then
        -- print("Success setting player data in global leaderboard: ", player.Name, dataValue)
        return true
    end
end

function Leaderstats.getGlobalData(dataName: string)
	if not GLOBAL_DATA[dataName] then
        return
    end
	
	local Data: OrderedDataStore = GLOBAL_DATA[dataName]
	local Pages = Data:GetSortedAsync(false, MAX_PAGE, 1)
	local Top = Pages:GetCurrentPage()
	
	return Top
end

function Leaderstats.pdateGlobalData()
    local globalData = {}
	for statKey, _ in GLOBAL_DATA do
		local Data: {} = Leaderstats.getGlobalData(statKey)
		if not Data then
            continue
        end

        globalData[statKey] = Data
	end
    Leaderstats.UpdateGlobalLeaderboard:FireAll(globalData)
end

function Leaderstats.updateGlobalData()
    local globalData = {}
	for statKey, _ in GLOBAL_DATA do
		local Data: {} = Leaderstats.getGlobalData(statKey)
		if not Data then
            continue
        end

        globalData[statKey] = Data
	end
    Leaderstats.UpdateGlobalLeaderboard:FireAllClients(globalData)
end

Leaderstats.SortedLeaderstatsChanged = typed_remote.event("SortedLeaderstatsChanged", ReplicatedStorage)
Leaderstats.UpdateGlobalLeaderboard = typed_remote.event("UpdateGlobalLeaderboard", ReplicatedStorage)

return Leaderstats