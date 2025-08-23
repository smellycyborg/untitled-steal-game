local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Currency = require(Modules:WaitForChild("Currency"))
local Vide = require(Packages:WaitForChild("vide"))

local CURRENCY_IMAGE_ID: string = "rbxassetid://122593826580281"
local FONT_ID: number = 12187368625

local player = Players.LocalPlayer

local currencyPerUserId = Vide.source({})
local currency = Vide.source(0)

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

local function currencyPerPlayer(props)
    return Vide.create "ScreenGui" {
        Name = "CurrencyPerPlayer",
        ResetOnSpawn = false,
    }
end

local function playerCurrency(props)
    return Vide.create "ScreenGui" {
        Name = "Currency",
        ResetOnSpawn = false,

        Vide.create "Frame" {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),

            Vide.create "Frame" {
                Size = UDim2.fromScale(0.15, 0.2),
                BackgroundTransparency = 1,
                BackgroundColor3 = Color3.fromRGB(),
                Position = UDim2.fromScale(0.025, 0.3),
                
                Vide.create "UIListLayout" {
                    Padding = UDim.new(0.042, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                },

                -- Currency Label
                Vide.create "TextLabel" {
                    FontFace = Font,
                    Text = function()
                        return tostring(currency())
                    end,

                    Size = UDim2.fromScale(0.5, 0.6),
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    LayoutOrder = 2,
                    TextScaled = true,
                    TextStrokeTransparency = 0.4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                },

                -- Currency Image
                Vide.create "ImageLabel" {
                    Image = CURRENCY_IMAGE_ID,

                    Size = UDim2.fromScale(0.5, 1.2),
                    LayoutOrder = 1,
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                }
            }
        }
    }
end

Vide.mount(playerCurrency, player:WaitForChild("PlayerGui"))

Currency.ClientInit()
Currency.TempCurrencyChanged:Connect(function(tempCurrency: {[string]: { [string]: any }})
    local userId: number = player.UserId
    if tempCurrency[tostring(userId)] then
        local tempAmount = tempCurrency[tostring(userId)]["tickets"] or 0
        currency(tempAmount)
    end
end)
