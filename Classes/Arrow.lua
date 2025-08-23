local ARROW_IMAGE_ID = "rbxassetid://14361077799"

local arrow = {}
local arrowPrototype = {}
local arrowPrivate = {}

function arrow.new(player, part0, part1)
	local instance = {}
	local private = {}
	
	private.owner = player
	private.target = part1
	
	private.attachment0 = Instance.new("Attachment")
	private.attachment1 = Instance.new("Attachment")
	private.beam = Instance.new("Beam")
	
	local attachment0 = private.attachment0
	local attachment1 = private.attachment1
	local beam = private.beam
	
	attachment0.CFrame = CFrame.new(Vector3.new(part0.Position))
	attachment0.Parent = part0
	
	attachment1.CFrame = CFrame.new(Vector3.new(part1.Position))
	attachment1.Parent = part1
	
	beam.Texture = ARROW_IMAGE_ID
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureSpeed = 2.5
	beam.TextureLength = 3
	beam.Width0 = 1
	beam.Width1 = 1
	beam.Transparency = NumberSequence.new(0)
	beam.FaceCamera = true
	beam.Attachment0 = private.attachment0
	beam.Attachment1 = private.attachment1
	beam.Parent = workspace
	
	arrowPrivate[instance] = private
	
	return setmetatable(instance, arrowPrototype)
end

function arrowPrototype:updateParts(parts)
	local private = arrowPrivate[self]

	for partName, part in parts do
		if partName == "Zero" then
			private.beam.Attachment0.Parent = part
		elseif partName == "One" then
			private.beam.Attachment1.Parent = part
		end
	end
end

function arrowPrototype:getTarget()
	return arrowPrivate[self].target
end

function arrowPrototype:getOwner()
	local private = arrowPrivate[self]
	
	return private.owner
end

function arrowPrototype:destroy()
	local private = arrowPrivate[self]
	
	private.attachment0:Destroy()
	private.attachment1:Destroy()
	private.beam:Destroy()
	
	self = nil
end

arrowPrototype.__index = arrowPrototype
arrowPrototype.__metatable = "This metatable is locked."
arrowPrototype.__newindex = function(_, _, _)
	error("This metatable is locked.")
end

return arrow