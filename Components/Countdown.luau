local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Vide = require(Packages:WaitForChild("vide"))

local FONT_ID: number = 12187368625

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

local function _formatTime(seconds: number): string
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60

    return string.format("%02d:%02d", minutes, remainingSeconds)
end

return function(props)
    local countdownText =  "Starting in "

    return Vide.create "ScreenGui" {
        Name = "Countdown",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,

        Vide.create "Frame" {
            Name = "ScreenHolder",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeXY,

            Vide.create "TextLabel" {
                Text = function()
                    local matchActive = ReplicatedStorage:FindFirstChild("MatchStatus") and ReplicatedStorage:FindFirstChild("MatchStatus").Value
                    if matchActive == true then
                        countdownText = "Time Left "
                    end
                    return `{countdownText}{_formatTime(props.countdown())}`
                end,

                Name = "CountdownLabel",
                FontFace = Font,
                LayoutOrder = 1,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.fromScale(0.5, 00.05),
                Size = UDim2.fromScale(0.9, 0.085),
                TextColor3 = Color3.fromRGB(201, 207, 255),
                TextStrokeTransparency = 0.4,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
            }
        }
    }
end
