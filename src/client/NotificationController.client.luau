local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Notifications = require(Modules:WaitForChild("Notifications"))
local Vide = require(Packages:WaitForChild("vide"))

local FONT_ID: number = 12187368625
local EXCLAMATION_IMAGE_ID = "rbxassetid://103671673753608"

local player = Players.LocalPlayer

local notifications = Vide.source({})

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

local function noties(props)
    local notificationElements = Vide.source({})

    Vide.effect(function()
        local currentNotifications = notifications()
        local elements = {}
        for index, data in currentNotifications do
            elements[#elements+1] = Vide.create "Frame" {
                LayoutOrder = index,
                Name = "BackgroundAndHolder",
                BackgroundTransparency = 0.4,
                BackgroundColor3 = Color3.fromRGB(),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 0.325),

                Vide.create "Frame" {
                    BackgroundColor3 = Color3.fromRGB(),
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.6, 1),

                    Vide.create "UIListLayout" {
                        Padding = UDim.new(0, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    Vide.create "ImageLabel" {
                        Visible = data.exclamationEnabled ~= nil,
                        Image = EXCLAMATION_IMAGE_ID,

                        LayoutOrder = 1,
                        Size = UDim2.fromScale(0.1, 1),
                        ScaleType = Enum.ScaleType.Fit,
                        BackgroundTransparency = 1,
                    },

                    Vide.create "TextLabel" {
                        FontFace = Font,
                        Text = `{data.message}`,

                        LayoutOrder = 2,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.8, 1),
                        TextColor3 = data.color or Color3.fromRGB(255, 255, 255),
                        TextStrokeTransparency = 0.4,
                        TextScaled = true,
                    },

                    Vide.create "ImageLabel" {
                        Visible = data.exclamationEnabled ~= nil,
                        Image = EXCLAMATION_IMAGE_ID,

                        LayoutOrder = 3,
                        Size = UDim2.fromScale(0.1, 1),
                        ScaleType = Enum.ScaleType.Fit,
                        BackgroundTransparency = 1,
                    },

                }

            }
        end

        notificationElements(elements)
    end)

    return Vide.create "ScreenGui" {
        Name = "Notifications",
        ResetOnSpawn = false,

        Vide.create "Frame" {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,

            -- Holder
            Vide.create "Frame" {
                Size = UDim2.fromScale(1, 0.2),
                Position = UDim2.fromScale(0, 0.085),
                BackgroundTransparency = 1,
                ClipsDescendants = true,

                Vide.create "UIListLayout" {
                    Padding = UDim.new(0, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                },

                function()
                    return notificationElements()
                end
            }
        }
    }
end

Vide.mount(noties, player:WaitForChild("PlayerGui"))

Notifications.InitClient()
Notifications.Update:Connect(function(newNotifications)  
    notifications(newNotifications)
end)
Notifications.SendFromServer.OnClientEvent:Connect(function(...: any)  
    Notifications.Add(...)
end)