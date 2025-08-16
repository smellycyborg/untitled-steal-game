local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Signal = require(Packages:WaitForChild("signal"))

local animation = {}
local animationPrototype = {}
local animationPrivate = {}

local function _checkInstance(instance)
    local isModel

    if instance:IsA("Model") then
        isModel = true
        print("This is a model.")
    elseif instance:IsA("Player") then
        print("This is a player.")
    else
        print("This is neither a model nor a player.")
    end

    return isModel
end

function animation.new(id: number, isUrl: boolean, fadeTime: number, weight:number, speed: number)
	assert(id, "Attempt to index nil with id.")

	local self = {}
	local private = {}

	self.stopped = Signal.new()

	private.animation = Instance.new("Animation")
	private.animation.AnimationId = id -- not isUrl and "http://www.roblox.com/asset/?id=" .. id or 
	
	private.fadeTime = fadeTime
	private.weight = weight
	private.speed = speed

	private.track = nil
	private.shutdown = nil
	
	animationPrivate[self] = private

	return setmetatable(self, animationPrototype)
end

function animationPrototype:setTrack(player, priority)
	local private = animationPrivate[self]

    local character
    local isModel = _checkInstance(player)
    if not isModel then
        character = player.Character or player.CharacterAdded:Wait()
    else
        character = player
    end

    if not character then
        error("Error/Npc:  character is nil.")
    end

	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local function trackEnded()
		self.stopped:Fire()
	end

	local track = animator:LoadAnimation(private.animation)
	track.Priority = priority
	track.Stopped:Connect(trackEnded)

	private.track = track
end

function animationPrototype:play(isLooped: boolean)
	local private = animationPrivate[self]

	local track = private.track
	track:Play(private.fadeTime, private.weight, private.speed)

	if isLooped then
		private.task = task.spawn(function()
			while track do
				track:Play()
				track.Stopped:Wait()
			end
		end)
	end
end

function animationPrototype:stop()
	local private = animationPrivate[self]

	if private.track then
		if private.task then
			task.cancel(private.task)
			private.task = nil
		end
		
		self.stopped:DisconnectAll()
		
		private.track:Stop()
		-- private.track:Destroy()
	end
end

function animationPrototype:isPlaying()
	local private = animationPrivate[self]
	return private.track.IsPlaying
end

function animationPrototype:disconnect()
	self.stopped:DisconnectAll()
end

function animationPrototype:destroy()
	local private = animationPrivate[self]

	self.stopped:Destroy()

	self = nil
end

animationPrototype.__index = animationPrototype

return animation