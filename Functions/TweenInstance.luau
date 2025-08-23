local TweenService = game:GetService("TweenService")

local TweenInstance = {}

local tweenPerElement = {}

function TweenInstance.Play(
    instance: Instance, 
    property: string, 
    target: any,
    start: any,

    duration: number, 
    easingStyle: Enum.EasingStyle?, 
    easingDirection: Enum.EasingDirection?,

    reverse: boolean?

)

	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out,
        0,
        reverse or false
	)

	local goal = {}
	goal[property] = target

    if tweenPerElement[instance] then
        tweenPerElement[instance].tween:Cancel()
        if tweenPerElement[instance].completedTask then
            tweenPerElement[instance].completedTask:Disconnect()
        end
        instance[property] = start
    end

	tweenPerElement[instance] = {tween = TweenService:Create(instance, tweenInfo, goal) }
    tweenPerElement[instance].completedTask = tweenPerElement[instance].tween.Completed:Connect(function(a0: Enum.PlaybackState)  
        tweenPerElement[instance] = nil
        if instance:IsA("Camera") then
            TweenInstance.Play(instance, property, 70, 65, (0.6 * 0.4) / 1.4, Enum.EasingStyle.Linear, 
                Enum.EasingDirection.InOut, false)
        end
    end)
	tweenPerElement[instance].tween:Play()

	return tweenPerElement[instance]
end

return TweenInstance