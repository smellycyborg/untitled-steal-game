local ReplicatedStorage = game:GetService("ReplicatedStorage")
local typed_remote = require(ReplicatedStorage.Packages["typed-remote"])
local player = game.Players.LocalPlayer

local basePower = 40
local damagePercent = 55
local comboCount = 0

local currentTask = nil

local Knockback = {}

function Knockback.ApplyToCharacterInDirection(character: Model, direction: Vector3, knockbackTime: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then 
		return
	end
	
	-- comboCount += 1
	if comboCount >= 3 then
		basePower *= 7
		knockbackTime = 3
	end

	local flatDirection = Vector3.new(direction.X, 0, direction.Z).Unit
	direction = flatDirection:Lerp(Vector3.new(0, 1, 0), 0.5).Unit

	if direction.Magnitude < 0.01 then
		direction = (rootPart.Position - Vector3.new(0, 1, 0)).Unit
	end

	if currentTask ~= nil then
		task.cancel(currentTask)

		if rootPart:FindFirstChild("KnockbackOrientation") then
			rootPart:FindFirstChild("KnockbackOrientation").Enabled = false
			rootPart:FindFirstChild("KnockbackOrientation").RigidityEnabled = false
		end
	end

	local align = rootPart:FindFirstChild("KnockbackOrientation")
	local att
	if align then
		att = rootPart:FindFirstChild("KnockbackAtt")
		att.CFrame = CFrame.lookAt(Vector3.zero, -direction)

		align.Enabled = true
		align.RigidityEnabled  = true
	else
		align = Instance.new("AlignOrientation")
		align.Name = "KnockbackOrientation"

		att = Instance.new("Attachment")
		att.Name = "KnockbackAtt"
		att.CFrame = CFrame.lookAt(Vector3.zero, -direction)
		att.Parent = rootPart

		align.Attachment0 = att
		align.Mode = Enum.OrientationAlignmentMode.OneAttachment
		align.RigidityEnabled = true
		align.Enabled = true
		align.Parent = rootPart
	end
	
	-- humanoid.PlatformStand = true
	-- humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.Velocity = Vector3.zero

	rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 3, 0)
	
	-- Play Animation Here

	local knockback = basePower + (damagePercent * 1.1)
	rootPart.AssemblyLinearVelocity = direction * knockback

	currentTask = task.delay(knockbackTime, function()
		if humanoid and humanoid.Parent then
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.Velocity = Vector3.zero

			align.RigidityEnabled = false
			align.Enabled = false

			-- humanoid.PlatformStand = false
			-- humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

Knockback.ActivateKnockback = typed_remote.event("ActivateKnockback", ReplicatedStorage) :: typed_remote.Event<number, Vector3>

return Knockback