local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Vide = require(Packages:WaitForChild("vide"))

local FONT_ID: number = 12187368625

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

return function(props)
    local trigger = Vide.source("")
    local BlueScale = Vide.source(1)
    local RedScale = Vide.source(1)

    local blueScaleSpring = Vide.spring(BlueScale, 0.4,0.8)
    local redScaleSpring = Vide.spring(RedScale, 0.4,0.8)

    Vide.effect(function()
        local current = trigger()

        if current == "Blue" then
            BlueScale(1.2)
            local thread = task.delay(0.2, function()
                BlueScale(1)
            end)
            Vide.cleanup(function()
                task.cancel(thread)
            end)
        elseif current == "Red" then
            RedScale(1.2)
            local thread = task.delay(0.2, function()
                RedScale(1)
            end)
            Vide.cleanup(function()
                task.cancel(thread)
            end)
        end
    end)
    
    return Vide.create "ScreenGui" {
        Name = "TeamChoice",
        ResetOnSpawn = false,

        Vide.create "Frame" {
            Visible = function()
                return props.enabled()
            end,

            Name = "ScreenHolder",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeXY,

            Vide.create "Frame" {
                Name = "BackgroundAndHolder",
                BackgroundTransparency = 0.2,
                BackgroundColor3 = Color3.fromRGB(),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 0.25),

                Vide.create "Frame" {
                    Name = "ButtonsHodler",
                    BackgroundTransparency = 0.4,
                    BackgroundColor3 = Color3.fromRGB(),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.375, 1),

                    Vide.create "UIListLayout" {
                        Padding = UDim.new(0.042, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    Vide.create "Frame" {
                        Size = UDim2.fromScale(0.44, 0.4),
                        BackgroundColor3 = Color3.fromRGB(0, 89, 255),
                        LayoutOrder = 1,

                        Vide.create "UICorner" {
                            CornerRadius = UDim.new(0.1, 0)
                        },

                        Vide.create "TextButton" {
                            FontFace = Font,
                            Text = `◄ Robbers`,
                            LayoutOrder = 1,
                            BackgroundTransparency = 1,
                            BackgroundColor3 = Color3.fromRGB(0, 89, 255),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromScale(0.9, 0.9),
                            TextColor3 = Color3.fromRGB(0, 89, 255),
                            TextStrokeTransparency = 0.4,
                            TextScaled = true,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            Activated = function()
                                props.callback("Robbers")
                            end,
                            MouseEnter = function()
                                trigger("Blue")
                            end,

                            Vide.create "UICorner" {
                                CornerRadius = UDim.new(0.1, 0)
                            },
                            Vide.create "UIStroke" {
                                Thickness = 2,
                            },
                        },

                        Vide.create "UIScale" {
                            Scale = blueScaleSpring,
                        }
                    },

                    Vide.create "Frame" {
                        Size = UDim2.fromScale(0.44, 0.4),
                        BackgroundColor3 = Color3.fromRGB(255, 106, 106),
                        LayoutOrder = 1,

                        Vide.create "UICorner" {
                            CornerRadius = UDim.new(0.1, 0)
                        },

                        Vide.create "TextButton" {
                            FontFace = Font,
                            Text = `Burglars ►`,
                            LayoutOrder = 2,
                            BackgroundTransparency = 1,
                            BackgroundColor3 = Color3.fromRGB(255, 106, 106),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromScale(0.9, 0.9),
                            TextColor3 = Color3.fromRGB(255, 106, 106),
                            TextStrokeTransparency = 0.4,
                            TextScaled = true,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            Activated = function()
                                props.callback("Burglars")
                            end,
                            MouseEnter = function()
                                trigger("Red")
                            end,

                            Vide.create "UICorner" {
                                CornerRadius = UDim.new(0.1, 0)
                            },
                            Vide.create "UIStroke" {
                                Thickness = 2,
                            }
                        },

                        Vide.create "UIScale" {
                            Scale = redScaleSpring,
                        }
                    },
                }
            }
        }
    }
end
