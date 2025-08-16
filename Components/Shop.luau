local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Config = ReplicatedStorage:WaitForChild("Config")

local Vide = require(Packages:WaitForChild("vide"))
local RarityColors = require(Config:WaitForChild("RarityColors"))
local ShopItems = require(Config:WaitForChild("ShopItems"))

local player = Players.LocalPlayer

local FONT_ID: number = 12187368625

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

return function(props)
    local toolItems = {}
    for name, data in ShopItems.Tools do
        toolItems[#toolItems+1] = Vide.create "Frame" {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.3,

            Vide.create "UIListLayout" {
                Padding = UDim.new(0.042, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            },

            -- Image Label
            Vide.create "ImageLabel" {
                Image = data.imageId,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0.48, 0.975),
                LayoutOrder = 1,
                ScaleType = Enum.ScaleType.Fit,
            },

            -- Info Holder
            Vide.create "Frame" {
                Image = nil,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0.48, 0.975),
                LayoutOrder = 2,

                -- Name Label
                Vide.create "TextLabel" {
                    FontFace = Font,
                    Text = `[{data.displayName}]`,

                    LayoutOrder = 1,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.9, 0.25),
                    TextColor3 = Color3.fromRGB(0, 204, 255),
                    TextStrokeTransparency = 0.4,
                    TextScaled = true,
                },

                -- Description Label
                Vide.create "TextLabel" {
                    FontFace = Font,
                    Text = `{data.description}`,

                    LayoutOrder = 1,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.9, 0.3),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0.4,
                    TextScaled = true,
                },

                -- Button
                Vide.create "TextButton" {
                    FontFace = Font,
                    Text = `{utf8.char(0xE002) .. data.robuxPrice}`,
                    LayoutOrder = 1,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = Color3.fromRGB(102, 255, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.9, 0.35),
                    TextColor3 = Color3.fromRGB(102, 255, 0),
                    TextStrokeTransparency = 1,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Activated = function()
                        MarketplaceService:PromptGamePassPurchase(player, data.gamepassId)
                    end,

                    Vide.create "UICorner" {
                        CornerRadius = UDim.new(0.1, 0)
                    },
                    Vide.create "UIStroke" {
                        Thickness = 2,
                    },
                    Vide.create "UIStroke" {
                        Thickness = 4,
                        Color = Color3.fromRGB(45, 105, 5),
                    },
                },

                Vide.create "UIListLayout" {
                    Padding = UDim.new(0.042, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                },
            }
        }
    end

    return Vide.create "ScreenGui" {
        Name = "Shop",
        ResetOnSpawn = false,

        Vide.create "Frame" {
            Name = "ScreenHolder",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeXY,

            -- Shop Button
            Vide.create "TextButton" {
                FontFace = Font,
                Text = function()
                    return props.enabled() == false and "Shop" or "Back"
                end,
                LayoutOrder = 1,
                BackgroundTransparency = 0,
                BackgroundColor3 = function()
                    return props.enabled() == false and Color3.fromRGB(102, 255, 0) or Color3.fromRGB(255, 105, 105)
                end,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0.02, 0.5),
                Size = UDim2.fromScale(0.1, 0.1),
                TextColor3 = function()
                    return props.enabled() == false and Color3.fromRGB(102, 255, 0) or Color3.fromRGB(255, 105, 105)
                end,
                TextStrokeTransparency = 1,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                Activated = function()
                    local enabled = not props.enabled()
                    props.enabled(enabled)
                end,
                Vide.create "UICorner" {
                    CornerRadius = UDim.new(0.1, 0)
                },
                Vide.create "UIStroke" {
                    Thickness = 2,
                },
                Vide.create "UIStroke" {
                    Thickness = 4,
                    Color = Color3.fromRGB(45, 105, 5),
                },
            },

            Vide.create "Frame" {
                Visible = function()
                    return props.enabled()
                end,

                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.3,
                Size = UDim2.fromScale(0.7, 0.7),

                Vide.create "UIListLayout" {
                    Padding = UDim.new(0.042, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                },

                -- Tool Items
                Vide.create "Frame" {
                    LayoutOrder = 2,
                    Size = UDim2.fromScale(0.98, 0.35),
                    BackgroundTransparency = 1,

                    Vide.create "UIGridLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        CellSize = UDim2.fromScale(0.485, 0.9),
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    function()
                        return toolItems
                    end
                }
            }
        }
    }
end
