local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Tutorial = require(Modules:WaitForChild("Tutorial"))
local Vide = require(Packages:WaitForChild("vide"))

local FONT_ID: number = 12187368625

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

local TaskStrings = {
    PICK_UP = "Pick up any [Brainrot]",
    CAPTURE = "Bring [Brainrot] to your team's base",
    COLLECT_MONEY = "Step on the [Money Button]",
}

local player = Players.LocalPlayer

local currentTask = Vide.source("")

local function tutorial()
    return Vide.create "ScreenGui" {
        Name = "Tutorial",

        Vide.create "Frame" {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,

            Vide.create "Frame" {
                Visible = function()
                    return string.len(currentTask()) > 0
                end,
                BackgroundTransparency = 0.2,
                Size = UDim2.fromScale(1, 0.15),
                Position = UDim2.fromScale(0.5, 0.55),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(),
    
                Vide.create "TextLabel" {
                    FontFace = Font,
                    Text = function()
                        local task = currentTask()
                        return TaskStrings[task] or ""
                    end,

                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.9, 0.8),
                    TextColor3 = Color3.fromRGB(255, 232, 20),
                    TextStrokeTransparency = 0.4,
                    TextScaled = true,
                }
            }
        }
    }
end

Vide.mount(tutorial, player:WaitForChild("PlayerGui"))

Tutorial.ClientInit()
Tutorial.UpdateTutorialUi.OnClientEvent:Connect(function(...: any)  
    currentTask(...)
end)