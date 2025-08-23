local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local signal = require(ReplicatedStorage.Packages.signal)
local typed_remote = require(ReplicatedStorage.Packages["typed-remote"])

local Classes = ReplicatedStorage:WaitForChild("Classes")
local Functions = ReplicatedStorage:WaitForChild("Functions")

local Arrow = require(Classes:WaitForChild("Arrow"))
local GetClosestObject = require(Functions:WaitForChild("GetClosestObject"))

local Tutorial = {}

local TaskPerPlayer = {}

function Tutorial.ClientInit()
    local currentTask
    local arrow
    local connection
    local hasCompleted = false

    local player = Players.LocalPlayer

    player:GetAttributeChangedSignal("CompletedTutorial"):Connect(function()
        if RunService:IsStudio() then
            return
        end
        hasCompleted = player:GetAttribute("CompletedTutorial")
        if hasCompleted then
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
        if arrow then
            arrow:destroy()
            arrow = nil
        end
    end)

    Tutorial.UpdateTutorialUi.OnClientEvent:Connect(function(task: any)  
        currentTask = task
    end)

    connection = RunService.PreSimulation:Connect(function(step)
        if hasCompleted then
            return
        end
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end

        if not currentTask or currentTask == "PICK_UP" then
            local actorParts = Workspace:FindFirstChild("ActorParts")
            if not actorParts then
                return
            end
            local closestActor = GetClosestObject(rootPart, actorParts:GetChildren(), 200)

            if closestActor then
                if not arrow then
                    arrow = Arrow.new(player, rootPart, closestActor)
                elseif arrow:getTarget() ~= closestActor then
                    arrow:updateParts({Zero = rootPart, One = closestActor})
                end
            end
        elseif currentTask == "CAPTURE" then
            if not arrow then
                arrow = Arrow.new(player, rootPart, Workspace:FindFirstChild(player.Team.Name))
            elseif arrow:getTarget() ~= Workspace:FindFirstChild(player.Team.Name) then
                arrow:updateParts({Zero = rootPart, One = Workspace:FindFirstChild(player.Team.Name)})
            end
        elseif currentTask == "COLLECT_MONEY" then
            local actorStands = Workspace:FindFirstChild("ActorStandsPerTeam")
            if not actorStands then
                return
            end
            local teamStands = actorStands:FindFirstChild(player.Team.Name)
            if not teamStands then
                return
            end

            local objects = {}
            for _, folder in teamStands:GetChildren() do
                if folder.Name == "Folder" then
                    continue
                end
                for _, part in folder:GetChildren() do
                    if part.Name == "MoneyButton" then
                        table.insert(objects, part)
                    end
                end
            end
            local closestButton = GetClosestObject(rootPart, objects, 200)
            if closestButton then
                if not arrow then
                    arrow = Arrow.new(player, rootPart, closestButton)
                elseif arrow:getTarget() ~= closestButton then
                    arrow:updateParts({Zero = rootPart, One = closestButton})
                end
            end
        end
    end)
end

function Tutorial.ServerInit()
    local function playerAdded(player)

    end
    local function playerRemoving(player)
        
    end

    for _, player in Players:GetPlayers() do
        task.spawn(playerAdded, player)
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)
end

function Tutorial.SetTask(player, task)
    TaskPerPlayer[player] = task
    Tutorial.UpdateTutorialUi:FireClient(player, TaskPerPlayer[player])
end

Tutorial.HasCompletedTutorial = signal.new()

Tutorial.UpdateTutorialUi = typed_remote.event("UpdateTutorialUi", ReplicatedStorage)

return Tutorial