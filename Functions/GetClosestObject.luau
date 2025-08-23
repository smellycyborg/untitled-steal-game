local RunService = game:GetService("RunService")

local MAX_ITEM_DISTANCE: number = 10

return function(rootPart: BasePart, objects: {BasePart}, maxDistance: number, errorMessage: string?)
    local closestObject, distanceBetweenCharacter
    local closestDotProduct = -math.huge

    maxDistance = maxDistance or MAX_ITEM_DISTANCE

    for _, object in objects do
        local objectPosition
        if not rootPart.Position then
            continue
        end

        if object:IsA("Model") then
            if object.PrimaryPart then
                objectPosition = object.PrimaryPart.Position
            else
                objectPosition = object:GetBoundingBox().Position

                if not objectPosition and RunService:IsStudio() then
                    print("GetClosestObject():  Object was a model but there was no primary part set AND GetBoundingBox() failed..")

                    continue
                end
            end
        elseif object:IsA("BasePart") then
            objectPosition = object.Position

            if not objectPosition and RunService:IsStudio() then
                print("GetClosestObject():  object was a BasePart but position is nil.")

                continue
            end
        end

        distanceBetweenCharacter = (objectPosition - rootPart.Position).Magnitude
        if distanceBetweenCharacter > maxDistance then
            continue
        end

        local characterLookDirection = rootPart.CFrame.LookVector.Unit
        local otherCharacterDirection = (objectPosition - rootPart.Position).Unit
        local dotProduct = characterLookDirection:Dot(otherCharacterDirection)
        if dotProduct > closestDotProduct then
            closestObject = object
            closestDotProduct = dotProduct
        end
    end

    return closestObject, distanceBetweenCharacter
end