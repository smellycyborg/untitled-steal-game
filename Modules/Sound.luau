local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundFolder = ReplicatedStorage:WaitForChild("Sounds")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Music = ReplicatedStorage:WaitForChild("Music")

local typed_remote = require(Packages:WaitForChild("typed-remote"))
local signal = require(Packages:WaitForChild("signal"))
local Sift = require(Packages:WaitForChild("sift"))

local Sound = {}

PlayersMutedMusic = {}
PlayersMutedPlayers = {}
PlayersMutedWeather = {}

PlayingSong = false

TimePlaying = 0

CurrentSong = nil

local SoundEffects
if RunService:IsClient() then
    SoundEffects = Instance.new("Folder", ReplicatedStorage)
    SoundEffects.Name = "SoundEffects"
end

function Sound.InitClient()
    for _, sound in SoundFolder:GetChildren() do
        if string.find(sound.Name, "NOT") then
            continue
        end
        local poolAmount = sound:GetAttribute("PoolAmount")
        if not poolAmount then
            continue
        end
        Sound.CreateSound(sound.Name, poolAmount)
    end
end

function Sound.InitServer()
    local function playerAdded(player: Player)
        if CurrentSong then
            Sound.PlaySong:FireClient(player, CurrentSong.Name, TimePlaying)
        else
            Sound.PlaySong:FireClient(player, "Lobby", TimePlaying)
        end
    end
    local function playerRemoving(player)
        local index = Sift.Array.find(PlayersMutedMusic, player)
        if index then
            PlayersMutedMusic = Sift.Array.removeIndex(PlayersMutedMusic, index)
        end
    end

    local function onHeartbeat(step)
        if not CurrentSong then
            return
        end

        if PlayingSong then
            TimePlaying += step

            if TimePlaying + 15 >= CurrentSong.TimeLength then
                TimePlaying = 0

                Sound.SetSong("Match")
            end
        end
    end
    
    for _, player in Players:GetPlayers() do
        task.spawn(playerAdded, player)
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)
    RunService.PostSimulation:Connect(onHeartbeat)
end

function Sound.CreateSound(soundName: string, amount: number)
    local sound = SoundFolder:WaitForChild(soundName)
    for i = 1, amount do
        local clone: Sound = sound:Clone()
        clone.Name = soundName
        clone.Parent = SoundEffects
        clone.Ended:Connect(function(a0: string)  
            clone.Parent = SoundEffects
        end)
    end
end

function Sound.PlaySoundUnderInstance(instance: Model | BasePart, soundName: string)
    local sound = SoundEffects:FindFirstChild(soundName)
    if sound then
        sound.Parent = instance
        sound:Play()
        -- warn(`Played sound on client {soundName}`)
    end
end

function Sound.PlaySongForPlayers()
    for _, player in Players:GetPlayers() do
        task.spawn(function()
            if not Sift.Array.find(PlayersMutedMusic, player) then
                Sound.PlaySong:FireClient(player, CurrentSong.Name, TimePlaying)
            end
        end)
    end
end

function Sound.SetSong(songName: string)
    local song = Music:FindFirstChild(songName)
    if not song then
        error("That song does not exist.")
    end

    CurrentSong = song
    TimePlaying = 0
    PlayingSong = true

    Sound.PlaySongForPlayers()
end

Sound.PlaySoundEffect = signal.new()

Sound.PlaySoundEffectServer = typed_remote.event("PlaySoundEffectServer", ReplicatedStorage)
Sound.PlaySong = typed_remote.event("PlaySong", ReplicatedStorage)

return Sound