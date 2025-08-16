local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Config = ReplicatedStorage:WaitForChild("Config")
local Actors = ReplicatedStorage:WaitForChild("Actors")

local Vide = require(Packages:WaitForChild("vide"))
local RarityColors = require(Config:WaitForChild("RarityColors"))

local FONT_ID: number = 12187368625

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

return function(props)
    local model = Actors:FindFirstChild(props.name)
    if not model then
        return {}
    end
    local sizeY = model:GetExtentsSize().Y

    return Vide.create "BillboardGui" {
        Adornee = props.part,
        Name = "ActorInfo",
        Size = UDim2.fromScale(5, 4),
        StudsOffset = Vector3.new(0, sizeY, 0),
        
        Vide.create "Frame" {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),

            Vide.create "UIListLayout" {
                Padding = UDim.new(0.042, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },

            -- Name Label
            Vide.create "TextLabel" {
                FontFace = Font,
                Text = `{props.displayName}`,

                LayoutOrder = 1,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.9, 0.2),
                TextColor3 = Color3.fromRGB(0, 204, 255),
                TextStrokeTransparency = 0.4,
                TextScaled = true,
            },

            -- Rarity Label Holder
            Vide.create "Frame" {
                BackgroundColor3 = RarityColors[props.rarity],

                LayoutOrder = 2,
                Size = UDim2.fromScale(0.7, 0.2),

                Vide.create "UICorner" {
                    CornerRadius = UDim.new(0.4, 0),
                },

                -- Rarity Label
                Vide.create "TextLabel" {
                    Text = `[{props.rarity}]`,

                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0.9, 0.9),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0.4,
                }
            },

            -- Money Per Time Label
            Vide.create "TextLabel" {
                FontFace = Font,
                Text = `${props.moneyPerTime}/{props.timeInterval}/s`,

                LayoutOrder = 3,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.9, 0.2),
                TextColor3 = Color3.fromRGB(229, 255, 0),
                TextStrokeTransparency = 0.4,
                TextScaled = true,
            },
        }
    }
end
