local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Config = ReplicatedStorage:WaitForChild("Config")

local signal = require(Packages:WaitForChild("signal"))
local typed_remote = require(Packages:WaitForChild("typed-remote"))

local DEFAULT_NOTIFICATION_TIME = 2.5

local Notifications = {}
local NotificationsList = {}

function Notifications.InitClient()
    RunService.PreSimulation:Connect(function(step: number)
        for index, data in NotificationsList do
            if data.timeElapsed >= DEFAULT_NOTIFICATION_TIME then
                table.remove(NotificationsList, index)
                Notifications.Update:Fire(NotificationsList)
                continue
            end
            NotificationsList[index].timeElapsed += step
        end
    end)
end

function Notifications.Add(message: string, color: Color3, exclamationEnabled: boolean)
    table.insert(NotificationsList, {
        timeElapsed = 0,
        color = color,
        message = message,
        exclamationEnabled = exclamationEnabled,
    })
    Notifications.Update:Fire(NotificationsList)
end

Notifications.Update = signal.new()

Notifications.SendFromServer = typed_remote.event("SendFromServer", ReplicatedStorage)

return Notifications