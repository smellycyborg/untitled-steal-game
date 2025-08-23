local MessagingService = game:GetService("MessagingService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local typed_remote = require(Packages:WaitForChild("typed-remote"))

local Messaging = {}

function Messaging.ClientInit()
    Messaging.PostMessageAsPlayer.OnClientEvent:Connect(function(message: any)  
        local success = Messaging.PublishAsPlayer(message)
        if not success then
            warn("Couldn't post a message as player..")
        end
    end)
    Messaging.PostServerMessage.OnClientEvent:Connect(function(message: string)
        local success = Messaging.PublishServerMessage(message)
        if not success then
            warn("Couldn't post a message to server..")
        end
    end)
end

function Messaging.ServerInit()
    local function onPlayerAdded(player: Player)
        local topic = "INFO"
        local connection = MessagingService:SubscribeAsync(topic, function(message)
            print("Received message for", player.Name, message.Data)
        end)

        player.AncestryChanged:Connect(function()
            connection:Disconnect()
        end)
    end

    for _, player in Players:GetPlayers() do
        task.spawn(onPlayerAdded, player)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)
end

function Messaging.PublishServerMessage(message: string)
    local success, result = pcall(function(...)  
        local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            return generalChannel:DisplaySystemMessage(message)
        else
            return false
        end
    end)

    if not success then
        warn(result)
    end

    return success and true or false
end

function Messaging.PublishAsPlayer(message: string)
    local success, result = pcall(function(...)  
        local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            return generalChannel:SendAsync(message)
        else
            return false
        end
    end)

    if not success then
        warn(result)
    end

    return success and true or false
end

function Messaging.PublishAcrossServers(topic: string, message: string)
    local success, result = pcall(function(...)
        return MessagingService:PublishAsync(topic, message)
    end)

    if not success then
        warn(result)
    end

    return success and true or false
end

Messaging.PostMessageAsPlayer = typed_remote.event("PostMessageAsPlayer", ReplicatedStorage) :: typed_remote.Event<string>
Messaging.PostServerMessage = typed_remote.event("PostServerMessage", ReplicatedStorage) :: typed_remote.Event<string>

return Messaging