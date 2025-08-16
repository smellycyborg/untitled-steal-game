local Players = game:GetService("Players")

local function playerAdded(player: Player)
    local function characterAdded(character)
        character:WaitForChild("Humanoid").WalkSpeed = 26
    end
    if player.Character then
        characterAdded(player.Character)
    end
    player.CharacterAdded:Connect(characterAdded)
end

Players.PlayerAdded:Connect(playerAdded)