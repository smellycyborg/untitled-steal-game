local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")
local Config = ReplicatedStorage:WaitForChild("Config")

local Actor = require(Modules:WaitForChild("Actor"))
local Vide = require(Packages:WaitForChild("vide"))
local ActorInfo = require(Components:WaitForChild("ActorInfo"))
local Brainrots = require(Config:WaitForChild("Brainrots"))

local ActorParts = Workspace:WaitForChild("ActorParts")

local infoPerActor = Vide.source({})

local ActorClones = Instance.new("Folder", workspace)
ActorClones.Name = "ActorClones"

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {Workspace:WaitForChild("Map")}

Actor.InitClient()

local function childAdded(child)
    local uniqueKey = child.Name
    local displayName = child:GetAttribute("DisplayName")
    local moneyPerTime = child:GetAttribute("MoneyPerTime")
    local timeInterval = child:GetAttribute("TimeInterval")
    local rarity = child:GetAttribute("Rarity")
    local name = child:GetAttribute("Name")
    local animationState = child:GetAttribute("AnimationState")

    local tempData = infoPerActor()
    local data = {}
    data.name = name
    data.displayName = displayName or "Display Name"
    data.moneyPerTime = moneyPerTime or 0
    data.timeInterval = timeInterval or 1
    data.rarity = rarity
    data.part = child

    tempData[uniqueKey] = data
    infoPerActor(tempData)

    local actorModel = ReplicatedStorage:FindFirstChild("Actors"):FindFirstChild(name)
    if not actorModel then
        warn(`Actor model does not exist {name}`)
        return
    end

    local clone = actorModel:Clone()
    clone.Name = uniqueKey

    local animController = clone:FindFirstChildOfClass("AnimationController")
    local animator = Instance.new("Animator", animController)

    local tracks = {}

    child:GetAttributeChangedSignal("AnimationState"):Connect(function(...: any)  
        local currentState = child:GetAttribute("AnimationState")
        local track = tracks[currentState]
        if not track then
            warn("Your track does not exist ", currentState)
            return
        end

        for _, animationTrack in tracks do
            animationTrack:Stop()
        end
        track:Play(0, 1, 1)
    end)

    clone.Parent = ActorClones

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
ActorParts.ChildAdded:Connect(childAdded)
ActorParts.ChildRemoved:Connect(function(child)
    local uniqueKey = child.Name
    local tempData = infoPerActor()
    tempData[uniqueKey] = nil
    infoPerActor(tempData)

    if Workspace:FindFirstChild(uniqueKey) then
        Workspace:FindFirstChild(uniqueKey):Destroy()
    end
end)

local function actors(props)
    local billboards = Vide.source({})

    Vide.effect(function()
        local currentActors = infoPerActor()
        local tempBillboards = {}
        for uniqueKey, data in currentActors do
            tempBillboards[#tempBillboards+1] = ActorInfo(data)
        end
        billboards(tempBillboards)
    end)

    return Vide.create "Folder" {
        Name = "InfoPerActor",

        function()
            return billboards()
        end,
    }
end

Vide.mount(actors, Players.LocalPlayer:WaitForChild("PlayerGui"))

RunService.PreSimulation:Connect(function(step: number)
    for _, part in ActorParts:GetChildren() do
        local uniqueKey = part.Name
        local clone = ActorClones:FindFirstChild(uniqueKey)
        if not clone then
            continue
        end

        local newPosition: Vector3

        local carrierId = part:GetAttribute("CarrierId") -- userId
        if typeof(carrierId) == "number" then
            local playerCarrying = Players:GetPlayerByUserId(carrierId)
            if playerCarrying then
                local rootPartCarrying = playerCarrying.Character and playerCarrying.Character:FindFirstChild("HumanoidRootPart")
                local positionY = rootPartCarrying.Position.Y + clone.PrimaryPart.Size.Z / 2
                newPosition = Vector3.new(part.Position.X, positionY, part.Position.Z)
            end
        else
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
