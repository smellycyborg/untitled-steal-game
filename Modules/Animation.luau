local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Animations = ReplicatedStorage:WaitForChild("Animations")

local typed_remote = require(Packages:WaitForChild("typed-remote"))
local Signal = require(Packages:WaitForChild("signal"))
local AnimationClass = require(Classes:WaitForChild("AnimationClass"))

local NOT_URL = false

local Animation = {}

local AnimationsPerCharacter = {}

local PlayActivated = {}


function Animation.LoadCharacter(character: Model, uniqueKey: string)
    if not character:IsA("Model") then
        return
    end

    for _, animation: Animation in Animations:GetChildren() do
        if animation:IsA("Animation") then
            local id = animation.AnimationId
            if not AnimationsPerCharacter[uniqueKey] then
                AnimationsPerCharacter[uniqueKey] = {}
            end

            AnimationsPerCharacter[uniqueKey][animation.Name] = AnimationClass.new(id, NOT_URL, 0, 0.9, 2)
            AnimationsPerCharacter[uniqueKey][animation.Name].stopped:Connect(function()  
            
            end)
        end
    end

    for animationName, animationTrack in AnimationsPerCharacter[uniqueKey] do
        task.spawn(function()
            animationTrack:setTrack(character, Enum.AnimationPriority.Action)
        end)
    end
end

Animation.ResumeAnimationByName = Signal.new()
Animation.PlayAnimation = Signal.new()
Animation.StopAnimations = Signal.new()
Animation.PlayAnimation:Connect(function(animationName: string, uniqueKey: string)
    local succes, err = pcall(function(...)  
        local shouldRepeat = true
        if animationName == "Hack" then
            shouldRepeat = false
        end

        for name, anim in AnimationsPerCharacter[uniqueKey] do
            anim:stop()
        end
        
        local animation = AnimationsPerCharacter[uniqueKey][animationName]
        animation:play(shouldRepeat)
    end)
    
    if not succes then
        warn(err)
    end
end)
Animation.StopAnimations:Connect(function(uniqueKey: string)  
    for name, anim in AnimationsPerCharacter[uniqueKey] do
        anim:stop()
    end
end)

return Animation