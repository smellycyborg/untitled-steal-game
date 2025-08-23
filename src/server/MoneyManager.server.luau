local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage.Modules

local Tutorial = require(Modules.Tutorial)
local Money = require(Modules.Money)
local Actor = require(Modules.Actor)
local Notifications = require(Modules.Notifications)

local MoneyActivatedPerKey = {}

local function _formatMoney(num: number): string
	return tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

Money.MoneyButtonTriggered.OnServerEvent:Connect(function(player: Player, actorKey: string)
    if typeof(actorKey) ~= "string" then
        warn("Invalid actor key")
        return
    end

    if MoneyActivatedPerKey[actorKey] then
        return
    end
    MoneyActivatedPerKey[actorKey] = true

    local actorMoney = Money.GetActorMoney(actorKey)
    if typeof(actorMoney) ~= "number" then
        MoneyActivatedPerKey[actorKey] = nil
        return
    end
    if actorMoney <= 0 then
        MoneyActivatedPerKey[actorKey] = nil
        return
    end

    local serverPart = Workspace.ActorParts:FindFirstChild(actorKey)
    if serverPart:GetAttribute("HasMoney") == true then
        serverPart:SetAttribute("HasMoney", false)
    end

    Money.Add(player.Team.Name, actorMoney)
    Money.ZeroActorMoney(actorKey)

    Tutorial.HasCompletedTutorial:Fire(player)
    Tutorial.SetTask(player, "")

    local moneyPerActor = {}
    for key, money in Money.GetMoneyPerActor() do
        moneyPerActor[key] = {
            team = Actor.GetTeam(key),
            money = money,
        }
    end
    Money.UpdateMoneyPerActor:FireAllClients(moneyPerActor)
    Money.CollectedMoney:FireAllClients(player.UserId, actorKey)

    for _, plr in Players:GetPlayers() do
        if plr.Team == player.Team then
            Notifications.SendFromServer:FireClient(
                plr,
                `{player.DisplayName} Collected ${_formatMoney(actorMoney)}`,
                Color3.fromRGB(115, 255, 0)
            )
        end
    end

    task.delay(0.5, function()
        MoneyActivatedPerKey[actorKey] = nil
    end)
end)
