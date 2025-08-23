local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")
local Config = ReplicatedStorage:WaitForChild("Config")
local Models = ReplicatedStorage:WaitForChild('Models')
local Vfx = ReplicatedStorage:WaitForChild("Vfx")
local Functions = ReplicatedStorage:WaitForChild("Functions")

local Actor = require(Modules:WaitForChild("Actor"))
local Vide = require(Packages:WaitForChild("vide"))
local ActorInfo = require(Components:WaitForChild("ActorInfo"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local TweenInstance = require(Functions:WaitForChild("TweenInstance"))

local ExclamationModel = Models:WaitForChild("Exclamation")
local Hitbox = Vfx:WaitForChild("Hitbox")

local ActorParts = Workspace:WaitForChild("ActorParts")

local DEFAULT_COLOR_TWEEN_TIME = 0.6

local GREEN_COLOR = Color3.fromRGB(17, 172, 22)
local RED_COLOR = Color3.fromRGB(17, 172, 22)
local YELLOW_COLOR = Color3.fromRGB(252, 255, 98)

local player = Players.LocalPlayer

local infoPerActor = Vide.source({})

local conns = {}
local tasks = {}

local cloneModelHovering, hitboxTask, originalSize, carrying

local ActorClones = Instance.new("Folder", workspace)
ActorClones.Name = "ActorClones"

local ExclamationClones = Instance.new("Folder", Workspace)
ExclamationClones.Name = "ExclamationClones"

local exclamations = Instance.new("Folder", ReplicatedStorage)
exclamations.Name = "Exclamations"

local highlights = Instance.new("Folder", ReplicatedStorage)
highlights.Name = "ActorHighlights"

for i = 1, 5 do
    local highlight = Instance.new("Highlight", highlights)
    highlight.FillTransparency = 1
    highlight.FillColor = Color3.fromRGB(251, 255, 13)
    highlight.OutlineTransparency = 1
end

for i = 1, 20 do
    local clone = ExclamationModel:Clone()
    clone.Parent = exclamations
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {Workspace:WaitForChild("Map")}

local function TweenZAxis(part: BasePart, goalZ: number, duration: number)
    originalSize = cloneModelHovering.PrimaryPart.Size
    local shrinking = true

    while true do
        local newZ = shrinking and goalZ or originalSize.Z
        local newSize = Vector3.new(originalSize.X, originalSize.Y, newZ)

        local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
            Size = newSize
        })

        tween:Play()
        tween.Completed:Wait()
        tween:Destroy()
        tween = nil

        shrinking = not shrinking
    end
end

local function childAdded(child)
    local uniqueKey = child.Name
    local displayName = child:GetAttribute("DisplayName")
    local moneyPerTime = child:GetAttribute("MoneyPerTime")
    local timeInterval = child:GetAttribute("TimeInterval")
    local rarity = child:GetAttribute("Rarity")
    local name = child:GetAttribute("Name")
    local animationState = child:GetAttribute("AnimationState")
    local hasMoney = child:GetAttribute("HasMoney")

    local tempData = infoPerActor()
    local data = {}
    data.name = name
    data.displayName = displayName or "Display Name"
    data.moneyPerTime = moneyPerTime or 0
    data.timeInterval = timeInterval or 1
    data.rarity = rarity
    data.part = child

    if not conns[uniqueKey] then
        conns[uniqueKey] = {}
    end

    tempData[uniqueKey] = data
    infoPerActor(tempData)

    local actorModel = ReplicatedStorage:FindFirstChild("Actors"):FindFirstChild(name)
    if not actorModel then
        return
    end

    local clone = actorModel:Clone()
    clone.Name = uniqueKey

    local moneyVfx = Vfx:FindFirstChild("Money"):Clone()
    local runningVfx = Vfx:FindFirstChild("RunningDust"):Clone()

    local animController = clone:FindFirstChildOfClass("AnimationController")
    local animator = Instance.new("Animator", animController)

    local tracks = {}

    conns[#conns+1] = child:GetAttributeChangedSignal("AnimationState"):Connect(function(...: any)  
        local currentState = child:GetAttribute("AnimationState")
        local isRunning = currentState == "running"
        runningVfx:FindFirstChild("RunningEmitter").Enabled = isRunning

        local track = tracks[currentState]
        if not track then
            return
        end

        for _, animationTrack in tracks do
            animationTrack:Stop()
        end
        track:Play(0, 1, 1)
    end)
    conns[uniqueKey][#conns[uniqueKey]+1] = child:GetAttributeChangedSignal("CarrierId"):Connect(function()
        carrying = clone

        if child:GetAttribute("CarrierId") == nil 
        and carrying == clone then
            carrying = nil
        end

        if cloneModelHovering == clone then
            if Hitbox.Parent ~= ReplicatedStorage then
                Hitbox.Parent = ReplicatedStorage
            end
        end

        local tempTab = infoPerActor()
        tempTab.clockThat = os.clock()
        infoPerActor(tempTab)
    end)
    conns[uniqueKey][#conns[uniqueKey]+1] = child:GetAttributeChangedSignal("HasMoney"):Connect(function(...: any)  
        local hasMoney = child:GetAttribute("HasMoney")
        moneyVfx:FindFirstChild("MoneyEmitter").Enabled = hasMoney
    end)

    local prompt = child:FindFirstChild("ProximityPrompt", true)
    if not prompt then
        return
    end
    conns[uniqueKey][#conns[uniqueKey]+1] = prompt.PromptShown:Connect(function(inputType)
        if child:GetAttribute("CarrierId") then
            return
        end

        cloneModelHovering = clone
        local color = YELLOW_COLOR
        if child:GetAttribute("Team") then
            color = RED_COLOR
        elseif child:GetAttribute("HasMoney") then
            color = GREEN_COLOR
        end
        Hitbox.SelectionBox.SurfaceColor3 = color
    end)
    conns[uniqueKey][#conns[uniqueKey]+1] = prompt.PromptHidden:Connect(function()
        if cloneModelHovering == clone then
            cloneModelHovering = nil
        end
    end)
    conns[uniqueKey][#conns[uniqueKey]+1] = prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
        local current = prompt.ActionText
        local team = child:GetAttribute("Team")
        if current == "Steal" then
            if team then
                if team == player.Team.Name then
                    prompt.ActionText = "Release"
                else
                    prompt.ActionText = "Steal"
                end
            end
        end
    end)

    clone.Parent = ActorClones

    moneyVfx.CFrame = clone.PrimaryPart.CFrame
    moneyVfx.Parent = clone.PrimaryPart

    runningVfx.CFrame = CFrame.new(Vector3.new(
        clone.PrimaryPart.Position.X, 
        (clone.PrimaryPart.Position.Y -  (clone.PrimaryPart.Size.Y / 2)) + 1,
        clone.PrimaryPart.Position.Z
    ))
    runningVfx.Parent = clone.PrimaryPart

    moneyVfx:FindFirstChild("MoneyEmitter").Enabled = hasMoney

    local function WeldParts(part0, part1)
        local weld = Instance.new("WeldConstraint")
        weld.Name = "WeldToActor"
        weld.Part0 = part0
        weld.Part1 = part1
        weld.Parent = part0
    end
    WeldParts(clone.PrimaryPart, moneyVfx)
    WeldParts(clone.PrimaryPart, runningVfx)

    local animationIds = Brainrots[name].animationIds
    for animationName, animationId in animationIds do
        if animationId == 1 then
            continue
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = `rbxassetid://{animationId}`
        tracks[animationName] = animator:LoadAnimation(anim)
    end
    tracks[animationState]:Play()
end

for _, part in ActorParts:GetChildren() do
    task.spawn(childAdded, part)
end
ActorParts.ChildAdded:Connect(function(child)
    local uniqueKey = child.Name
    tasks[uniqueKey] = task.spawn(function()
        childAdded(child)
    end)
end)
ActorParts.ChildRemoved:Connect(function(child)
    local uniqueKey = child.Name

    if cloneModelHovering == ActorClones:FindFirstChild(uniqueKey) then
        cloneModelHovering = nil
    end

    if tasks[uniqueKey] then
        task.cancel(tasks[uniqueKey])
    end

    for _, conn in conns[uniqueKey] do
        conn:Disconnect()
    end
    conns[uniqueKey] = nil

    local tempData = infoPerActor()
    tempData[uniqueKey] = nil
    infoPerActor(tempData)

    if ExclamationClones:FindFirstChild(uniqueKey) then
        ExclamationClones:FindFirstChild(uniqueKey).Parent = exclamations
    end

    if ActorClones:FindFirstChild(uniqueKey) then
        ActorClones:FindFirstChild(uniqueKey):Destroy()
    end
end)

local function actors(props)
    local billboards = Vide.source({})

    Vide.effect(function()
        local currentActors = infoPerActor()
        local tempBillboards = {}
        for uniqueKey, data in currentActors do
            if typeof(data) ~= "table" then
                continue
            end
            tempBillboards[#tempBillboards+1] = ActorInfo(data)
        end
        billboards(tempBillboards)
    end)

    return Vide.create "ScreenGui" {
        Name = "InfoPerActor",
        ResetOnSpawn = false,

        function()
            return billboards()
        end,
    }
end

Vide.mount(actors, Players.LocalPlayer:WaitForChild("PlayerGui"))

Actor.InitClient()

RunService.PreSimulation:Connect(function(step: number)
    if cloneModelHovering and cloneModelHovering ~= carrying then
        if Hitbox.Parent ~= Workspace then
            Hitbox.Parent = Workspace
        end
        if not hitboxTask or originalSize ~= cloneModelHovering.PrimaryPart.Size then
            if hitboxTask then
                task.cancel(hitboxTask)
            end
            hitboxTask = task.spawn(function()
                TweenZAxis(Hitbox, cloneModelHovering.PrimaryPart.Size.Z / 1.2, 0.35)
            end)
        end
        Hitbox.CFrame = cloneModelHovering.PrimaryPart.CFrame
    else
        if Hitbox.Parent ~= ReplicatedStorage then
            Hitbox.Parent = ReplicatedStorage
        end
    end

    for _, part in ActorParts:GetChildren() do
        local uniqueKey = part.Name
        local clone = ActorClones:FindFirstChild(uniqueKey)
        if not clone then
            continue
        end

        local newPosition: Vector3

        local carrierId = part:GetAttribute("CarrierId") -- userId
        if typeof(carrierId) == "number" then
            local exclamationModel = ExclamationClones:FindFirstChild(uniqueKey)
            if exclamationModel then
                exclamationModel.Parent = exclamations
            end
            local playerCarrying = Players:GetPlayerByUserId(carrierId)
            if playerCarrying then
                local rootPartCarrying = playerCarrying.Character and playerCarrying.Character:FindFirstChild("HumanoidRootPart")
                local positionY = rootPartCarrying.Position.Y + clone.PrimaryPart.Size.Z / 2
                newPosition = Vector3.new(part.Position.X, part.Position.Y, part.Position.Z)
            end
        else
            if part:GetAttribute("HasBeenCarried") and not part:GetAttribute("Team") then
                local exclamationModel = ExclamationClones:FindFirstChild(uniqueKey)
                if not exclamationModel then
                    for _, model in exclamations:GetChildren() do
                        exclamationModel = model
                        model.Name = uniqueKey
                        model.Parent = ExclamationClones
                        break
                    end
                end
                if exclamationModel then
                    local yPos = clone.PrimaryPart.Position.Y + (clone.PrimaryPart.Size.Y / 2) + (exclamationModel:GetExtentsSize().Y / 2) + 0.25
                    exclamationModel:PivotTo(CFrame.new(part.Position.X, yPos, part.Position.Z))
                end
            else
                local exclamationModel = ExclamationClones:FindFirstChild(uniqueKey)
                if exclamationModel then
                    exclamationModel.Parent = exclamations
                end
            end
            local raycast = workspace:Raycast(part.Position + Vector3.new(0, 10, 0), Vector3.new(0, -1, 0) * 100, raycastParams)
            if raycast then
                local positionY = raycast.Position.Y + (clone.PrimaryPart.Size.Y / 2)
                newPosition = Vector3.new(part.Position.X, positionY, part.Position.Z)
            end
        end
        clone:SetPrimaryPartCFrame(
            CFrame.new(newPosition) * CFrame.fromOrientation(
            part.Orientation.X * math.pi/180,
            part.Orientation.Y * math.pi/180,
            part.Orientation.Z * math.pi/180
            )
        )      
    end
end)
