local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GatesFolder = ReplicatedStorage:WaitForChild("Gates")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Gates = require(Modules:WaitForChild("Gates"))
local Vide = require(Packages:WaitForChild("vide"))

local Buttons = Workspace:WaitForChild("GateButtons")

local DEFAULT_CLOSE_TIME = 30
local FONT_ID: number = 12187368625

local player = Players.LocalPlayer

local teamGatesOpen = Vide.source({})

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

for _, folder in GatesFolder:GetChildren() do
    folder.Parent = Workspace
end

local function _formatTime(seconds: number): string
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60

    return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function timers(props)
    local billboards = Vide.source({})

    Vide.effect(function()
        local currentGatesOpen = teamGatesOpen()
        local tempBillboards = {}
        for teamName, timeLeft in currentGatesOpen do
            local buttonModel = Buttons:FindFirstChild(teamName)
            local adornee = buttonModel:FindFirstChild("Button")
            
            tempBillboards[#tempBillboards+1] = Vide.create "BillboardGui" {
                Adornee = adornee,
                StudsOffset = Vector3.new(0, 3.25, 0),
                Size = UDim2.fromScale(3, 3),
                
                Vide.create "TextLabel" {
                    Text = _formatTime(timeLeft),
                    FontFace = Font,

                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0.9, 0.9),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 235, 179),
                    TextStrokeTransparency = 0.4,
                }
            }
        end
        billboards(tempBillboards)
    end)

    return Vide.create "Folder" {
        function()
            return billboards()
        end
    }
end

Vide.mount(timers, player:WaitForChild("PlayerGui"))

Gates.ManageGate.OnClientEvent:Connect(function(gateName: string, action: string, hasTimer)  -- gatename is the name of the team
    local gateWall = Workspace:FindFirstChild("WallsPerTeam"):FindFirstChild(gateName)
    local bars = Workspace:FindFirstChild("Bars"):FindFirstChild(gateName)

    if action == "CLOSE" then
        if gateName ~= player.Team.Name then
            gateWall.CanCollide = true
            for _, bar in bars:GetChildren() do
                bar.CanCollide = true
            end
        else
            gateWall.CanCollide = false
            for _, bar in bars:GetChildren() do
                bar.CanCollide = false
            end
        end

        for _, bar in bars:GetChildren() do
            bar.Transparency = 0
        end

        local tempTab = teamGatesOpen()
        tempTab[gateName] = nil
        teamGatesOpen(tempTab)
    elseif action == "OPEN" then
        gateWall.CanCollide = false
        
        for _, bar in bars:GetChildren() do
            bar.CanCollide = false
        end
        for _, bar in bars:GetChildren() do
            bar.Transparency = 1
        end

        if hasTimer then
            local tempTab = teamGatesOpen()
            tempTab[gateName] = DEFAULT_CLOSE_TIME
            teamGatesOpen(tempTab)
        end
    end
end)

Gates.UpdateTimeLeft.OnClientEvent:Connect(function(updatedTimeTab: {})
    teamGatesOpen(updatedTimeTab)
end)
