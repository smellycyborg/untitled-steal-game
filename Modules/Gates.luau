local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local typed_remote = require(Packages:WaitForChild("typed-remote"))
local Signal = require(Packages:WaitForChild("signal"))

local Buttons = Workspace:WaitForChild("GateButtons")

local DEFAULT_CLOSE_TIME = 30
local SET_TIMER = true

local Gates = {}

local TimeLeftPerGate = {}
local TimeElapsedPerGate = {}

function Gates.InitServer()
    for _, model in Buttons:GetChildren() do
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Close"
        prompt.RequiresLineOfSight = false
        prompt.Triggered:Connect(function(player: Player)  
            if TimeElapsedPerGate[model.Name] then
                return
            end
            if player.Team.Name ~= model.Name then
                return
            end

            prompt.Enabled = false
            Gates.Close({model.Name}, SET_TIMER)
        end)
        prompt.Parent = model:FindFirstChild("Button")
    end

    RunService.PostSimulation:Connect(function(step: number)
        for color, timeElapsed in TimeElapsedPerGate do
            TimeElapsedPerGate[color] += step
            if TimeElapsedPerGate[color] >= 1 then
                TimeElapsedPerGate[color] = 0
                
                TimeLeftPerGate[color] -= 1
                Gates.UpdateTimeLeft:FireAllClients(TimeLeftPerGate)
                if TimeLeftPerGate[color] <= 0 then

                    TimeElapsedPerGate[color] = nil
                    TimeLeftPerGate[color] = nil

                    Gates.Open({color})
                    Gates.ManageGate:FireAllClients(color, "OPEN")
                end
            end
        end
    end)
end

function Gates.Open(gates: {string})
    for _, color in gates do
        Gates.ManageGate:FireAllClients(color, "OPEN")
        Buttons:FindFirstChild(color):FindFirstChild("ProximityPrompt", true).Enabled = true
    end
end

function Gates.Close(gates: {string}, setTimer: boolean)
    for _, color in gates do
        if setTimer == true then
            TimeLeftPerGate[color] = DEFAULT_CLOSE_TIME
            TimeElapsedPerGate[color] = 0
        end
        Gates.ManageGate:FireAllClients(color, "CLOSE", setTimer)
    end
end

Gates.OpenGates = Signal.new()
Gates.CloseGates = Signal.new()

Gates.ManageGate = typed_remote.event("ManageGates", ReplicatedStorage)
Gates.UpdateTimeLeft = typed_remote.event("UpdateTimeLeft", ReplicatedStorage)

return Gates