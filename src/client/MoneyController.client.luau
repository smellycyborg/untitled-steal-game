local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Vfx = ReplicatedStorage:WaitForChild("Vfx")
local Functions = ReplicatedStorage:WaitForChild("Functions")

local Money = require(Modules:WaitForChild("Money"))
local Sound = require(Modules:WaitForChild("Sound"))
local Vide = require(Packages:WaitForChild("vide"))
local TweenInstance = require(Functions:WaitForChild("TweenInstance"))

local GreenLightning = Vfx:WaitForChild("GreenLightning")

local ActorStandsPerTeam: Folder = Workspace:WaitForChild("ActorStandsPerTeam")
local RobbersStand = ActorStandsPerTeam:WaitForChild("Robbers")
local BurglardsStand = ActorStandsPerTeam:WaitForChild("Burglars")
local MoneyPerTeam = Workspace:WaitForChild("MoneyPerTeam")

local FONT_ID: number = 12187368625
local MAX_PLAYERS = 16
local DEFAULT_COLOR_TWEEN_TIME = 0.6
local DEFAULT_MONEY_GOAL = 100_000

local player = Players.LocalPlayer

local moneyPerActor = Vide.source({})
local moneyPerTeam = Vide.source({})

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

local filterTab = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local function partAdded(child)
    local vfx = GreenLightning:Clone()
    vfx.Position = child.Position
    vfx.Parent = child

    table.insert(filterTab, child)
    raycastParams.FilterDescendantsInstances = filterTab
end

local function initObject(object)
    for _, inst in object:GetDescendants() do
        if table.find(filterTab, inst) then
            continue 
        end

        if inst:IsA("BasePart") and inst.Name == "MoneyButton" then
            partAdded(inst)
        elseif inst:IsA("Folder") then
            inst.ChildAdded:Connect(function(child: Instance)
                if child.Name == "MoneyButton" then
                    partAdded(child)
                end
            end)
        end
    end
end

initObject(RobbersStand)
initObject(BurglardsStand)

BurglardsStand.ChildAdded:Connect(initObject)
RobbersStand.ChildAdded:Connect(initObject)

raycastParams.FilterDescendantsInstances = filterTab

local moneyHighlights = Instance.new("Folder", ReplicatedStorage)
moneyHighlights.Name = "MoneyHighlights"

for i = 1, MAX_PLAYERS do
    local highlight = Instance.new("Highlight", moneyHighlights)
    highlight.FillColor = Color3.fromRGB(81, 255, 0)
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
end

local function _formatMoney(num: number): string
	return tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function moneyPerTeams(props)
    local billboards = Vide.source({})
    local screenElements = Vide.source({})

    Vide.effect(function()
        local currentTeams = moneyPerTeam()
        local tempBillboards = {}
        local tempElements = {}
        for teamName, money in currentTeams do
            local adornee = MoneyPerTeam:FindFirstChild(teamName)
            local sizeX = math.clamp(money / DEFAULT_MONEY_GOAL, 0, 1)

            tempElements[#tempElements+1] = Vide.create "Frame" {
                Size = UDim2.fromScale(1, 0.5),
                BackgroundTransparency = 0.2,
                BackgroundColor3 = Color3.fromRGB(),

                Vide.create "UICorner" {
                    CornerRadius = UDim.new(0.1),
                },

                Vide.create "UIListLayout" {
                    Padding = UDim.new(0, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                },

                -- Team Name
                Vide.create "TextLabel" {
                    FontFace = Font,
                    LayoutOrder = 1,
                    Text = teamName,
                    Size = UDim2.fromScale(0.4, 1),
                    BackgroundTransparency = 1,
                    TextStrokeTransparency = 0.4,
                    TextStrokeColor3 = teamName == "Robbers" 
                    and Color3.fromRGB(0, 110, 255) or Color3.fromRGB(255, 109, 109), 
                    TextScaled = true,
                },

                -- Money Progress Holder
                Vide.create "Frame" {
                    LayoutOrder = 2,
                    Size = UDim2.fromScale(0.6, 1),
                    BackgroundTransparency = 1,

                    Vide.create "TextLabel" {
                        Text = `${_formatMoney(money)}`,
                        FontFace = Font,

                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.9, 0.9),
                        TextColor3 = Color3.fromRGB(9, 255, 0),
                        TextStrokeTransparency = 0.4,
                        TextScaled = true,
                        ZIndex = 2,
                    },

                    Vide.create "UICorner" {
                        CornerRadius = UDim.new(0.1),
                    },

                    -- Progress Bar
                    Vide.create "Frame" {
                        Size = UDim2.fromScale(sizeX, 1),
                        BackgroundColor3 = Color3.fromRGB(117, 255, 4),

                        Vide.create "UICorner" {
                            CornerRadius = UDim.new(0.1),
                        },
                    }
                }
            }

            tempBillboards[#tempBillboards+1] = Vide.create "BillboardGui" {
                Adornee = adornee,
                Name = "TeamMoney",
                Size = UDim2.new(20, 40, 15, 30),
                StudsOffset = Vector3.new(0, 20, 0),

                Vide.create "Frame" {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,

                    Vide.create "UIListLayout" {
                        Padding = UDim.new(0.042, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    -- Money Amount Label
                    Vide.create "TextLabel" {
                        Text = `${_formatMoney(money)}`,
                        FontFace = Font,

                        LayoutOrder = 1,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.9, 0.5),
                        TextColor3 = Color3.fromRGB(9, 255, 0),
                        TextStrokeTransparency = 0.4,
                        TextScaled = true,
                    },

                    -- Money Progress Bar Holder
                    Vide.create "Frame" {
                        LayoutOrder = 2,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0.15),

                        Vide.create "Frame" {
                            BackgroundTransparency = 0.2,
                            BackgroundColor3 = Color3.fromRGB(),
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.fromScale(0.5, 0),
                            Size = UDim2.fromScale(1, 1),

                            Vide.create "UICorner" {
                                CornerRadius = UDim.new(0.1),
                            },

                            Vide.create "Frame" {
                                Size = UDim2.fromScale(sizeX, 1),
                                BackgroundColor3 = Color3.fromRGB(117, 255, 4),

                                Vide.create "UICorner" {
                                    CornerRadius = UDim.new(0.1),
                                },
                            }
                        }
                    }
                }
            }
        end

        billboards(tempBillboards)
        screenElements(tempElements)
    end)
    return Vide.create "Folder" {
        Name = "MoneyPerTeam",

        Vide.create "ScreenGui" {
            ResetOnSpawn = false,
            
            Vide.create "Frame" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                Vide.create "Frame" {
                    Size = UDim2.fromScale(0.2, 0.2),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.02, 0.75),

                    Vide.create "UIListLayout" {
                        Padding = UDim.new(0.042, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    function()
                        return screenElements()
                    end
                }
            }
        },

        function()
            return billboards()
        end
    }
end

local function moneys(props)
    local billboards = Vide.source({})

    Vide.effect(function()
        local currentMoneyPerActor = moneyPerActor()
        local tempBillboards = {}
        for uniqueKey, data in currentMoneyPerActor do
            local team = data.team
            if typeof(team) == "nil" then
                continue
            end
            local money = data.money
            local teamActorStands = ActorStandsPerTeam:FindFirstChild(team)
            if not teamActorStands then
                continue
            end

            local adornee = teamActorStands:FindFirstChild(uniqueKey):FindFirstChild("MoneyButton")
            
            tempBillboards[uniqueKey] = Vide.create "BillboardGui" {
                Adornee = adornee,

                StudsOffset = Vector3.new(0, 3.25, 0),
                Size = UDim2.fromScale(3, 3),
                
                Vide.create "TextLabel" {
                    Text = `${_formatMoney(money)}`,
                    FontFace = Font,

                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0.9, 0.9),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(23, 226, 4),
                    TextStrokeTransparency = 0.4,
                }
            }
        end
        billboards(tempBillboards)
    end)    

    return Vide.create "Folder" {
        Name = "MoneyBillboards",

        function()
            return billboards()
        end
    }
end

Vide.mount(moneyPerTeams, player:WaitForChild("PlayerGui"))
Vide.mount(moneys, player:WaitForChild("PlayerGui"))

Money.UpdateMoney.OnClientEvent:Connect(function(_prevMoney, updatedMoneyPerTeam)
    moneyPerTeam(updatedMoneyPerTeam)
end)
Money.UpdateMoneyPerActor.OnClientEvent:Connect(function(updatedMoneyPerActor)
    moneyPerActor(updatedMoneyPerActor)
end)
Money.CollectedMoney.OnClientEvent:Connect(function(userId, actorId)
    local otherPlayer = Players:GetPlayerByUserId(userId)
    local otherCharacter = otherPlayer.Character
    if not otherCharacter then
        return
    end
    local actorStandFolder = ActorStandsPerTeam:FindFirstChild(actorId, true)
    local vfx = actorStandFolder:FindFirstChild("Lightning", true)
    if vfx then
        vfx:Emit(vfx.Rate)
    end

    Sound.PlaySoundEffect:Fire(actorStandFolder:FindFirstChild("MoneyButton"), "MoneyButton")

    TweenInstance.Play(Workspace.CurrentCamera, "FieldOfView", 65, 70, (DEFAULT_COLOR_TWEEN_TIME), Enum.EasingStyle.Linear, 
        Enum.EasingDirection.InOut, false)

    -- task.delay(DEFAULT_COLOR_TWEEN_TIME * 0.4, function()
    --     TweenInstance(Workspace.CurrentCamera, "FieldOfView", 65, 70, (DEFAULT_COLOR_TWEEN_TIME * 0.4) / 1.4, Enum.EasingStyle.Linear, 
    --         Enum.EasingDirection.InOut, false)
    -- end)

    for _, highlight in moneyHighlights:GetChildren() do
        highlight.Parent = otherCharacter
        TweenInstance.Play(highlight, "FillTransparency", 0.6, 1, DEFAULT_COLOR_TWEEN_TIME, Enum.EasingStyle.Cubic, 
            Enum.EasingDirection.Out, true)

        task.delay(DEFAULT_COLOR_TWEEN_TIME * 2, function()
            highlight.Parent = moneyHighlights
            highlight.FillTransparency = 1
        end)
        break
    end
end)

RunService.PreSimulation:Connect(function(step: number)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local raycastResult = Workspace:Raycast(rootPart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -1, 0) * 100, raycastParams)
        if raycastResult and raycastResult.Instance
        and raycastResult.Instance.Name == "MoneyButton" 
        and raycastResult.Instance:FindFirstAncestor(player.Team.Name) then
            Money.MoneyButtonTriggered:FireServer(raycastResult.Instance.Parent.Name)
        end
    end
end)