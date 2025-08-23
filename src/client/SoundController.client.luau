local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Music = ReplicatedStorage:WaitForChild("Music")

local SoundModule = require(Modules:WaitForChild("Sound"))

SoundModule.InitClient()
SoundModule.PlaySoundEffect:Connect(function(...)
    SoundModule.PlaySoundUnderInstance(...)
end)
SoundModule.PlaySoundEffectServer.OnClientEvent:Connect(function(...: any)  
    SoundModule.PlaySoundUnderInstance(...)
end)
SoundModule.PlaySong.OnClientEvent:Connect(function(songName, timeLength)  
    local foundSong = ReplicatedStorage:FindFirstChild("Song")
    if foundSong then
        foundSong:Destroy()
    end

    local songClone = Music:FindFirstChild(songName):Clone()
    songClone.Name = "Song"
    songClone.Volume = 0.8

    if timeLength then
        songClone.TimePosition = timeLength
    end
    
    songClone.Parent = ReplicatedStorage

    songClone:Play()
end)