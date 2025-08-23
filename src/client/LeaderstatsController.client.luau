local Players = game:GetService("Players")
local UserService = game:GetService("UserService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Leaderstats = require(Modules.Leaderstats)
local Vide = require(Packages:WaitForChild("vide"))

local Leaderboards = Workspace:WaitForChild("Leaderboards")

local FONT_ID: number = 12187368625

local player = Players.LocalPlayer

local leaderstats = Vide.source({})

local Font: Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic) :: Font

PlayerLeaderstats = {
    brainrots = {},
    wins = {},
}
GlobalList = {
    brainrots = {},
    wins = {},
}

local function _getPlayerHeadshot(UserID: number): string
	local success, result = pcall(function()
		return Players:GetUserThumbnailAsync(UserID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if success then
		return result
	else
		return "rbxassetid://753015086"
	end
end

local function _getUserInfos(IDs: { number? }): {}
	local success, result = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(IDs)
	end)

	if success then
		return result
    else
        warn(result)
	end

    return {}
end

local function _findUserInfo(userId: number, userInfos: {any}): {[any]: any}
	for _, userInfo in userInfos do
		if tonumber(userId) == userInfo.Id then
			return userInfo
		end
	end
    return {}
end

local function leaderstatsComponent(props)
    local currentScreen = Vide.source("Lobby")
    local surfaces = Vide.source({})

    local categoryButtons = {"Global", "Lobby", "Friends"}

    Vide.effect(function()
        local currentLeaderstats = leaderstats()
        local tempButtons = {}
        local tempSurfaces = {}
        local tempScrollings = {}

        -- creating category buttons per leaderboard type
        for _, category in categoryButtons do
            tempButtons[#tempButtons] = Vide.create "TextButton" {
                FontFace = Font,
                Text = category,

                BackgroundColor3 = Color3.fromRGB(18, 129, 255),
                TextScaled = true,
                TextStrokeTransparency = 0.4,

                Vide.create "UICorner" {
                    CornerRadius = UDim.new(0.2),
                }
            }

            if category ~= "Lobby" then
                continue
            end
        end

        for name, data in currentLeaderstats do
            local adornee = Leaderboards:FindFirstChild(name .. "Part")
            if not adornee then
                continue
            end

            -- creating list of leaderstat per player
            local playerElements = {}
            for index, playerData in data do
                local plr = playerData.player
                local userId = plr.UserId
                if typeof(userId) ~= "number" then
                    continue
                end
                local displayName = plr.DisplayName

                playerElements[#playerElements+1] = Vide.create "Frame" {
                    Size = UDim2.fromScale(1, 0.1),

                    Vide.create "UIListLayout" {
                        Padding = UDim.new(0.042, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    Vide.create "ImageLabel" {
                        LayoutOrder = 1,
                    },

                    -- Display Name
                    Vide.create "TextLabel" {
                        Text = displayName,
                        FontFace = Font,

                        
                    },
                }
            end

            tempSurfaces[#tempSurfaces+1] = Vide.create "SurfaceGui" {
                Face = "Right",

                 Vide.create "Frame" {
                    UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,

                    -- Category Buttons Holder
                    Vide.create "Frame" {
                        Size = UDim2.fromScale(1, 0.1),
                        BackgroundTransparency = 1,

                        Vide.create "UIGridLayout" {
                            CellPadding = UDim2.fromScale(0.025, 0),
                            CellSize = UDim2.fromScale(0.2, 0.7),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                        },

                        function()
                            return tempButtons
                        end,            
                    },

                    -- Page Holder
                    Vide.create "Frame" {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0.9),

                        Vide.create "UIPageLayout" {

                        },

                        function()
                            return tempScrollings
                        end
                    }
                }
            }
        end

        surfaces(tempSurfaces)
    end)

    return Vide.create "ScreenGui" {
        Name = "Leaderstats",

       function()
            return surfaces()
       end
    }
end

Vide.mount(leaderstatsComponent, player:WaitForChild("PlayerGui"))

Leaderstats.SortedLeaderstatsChanged.OnClientEvent:Connect(function(newLeaderstats)
    leaderstats(newLeaderstats)
    warn("Leaderstats", newLeaderstats)
end)

Leaderstats.UpdateGlobalLeaderboard.OnClientEvent:Connect(function(globalData)
    local userIds, infoPerPlayer = {}, {}
    
    for statKey, data in globalData do
        if not GlobalList[statKey] then
            GlobalList[statKey] = {}
        end

        if not next(userIds) then
            for _index, userInfo in data do
                local userId = userInfo.key
                table.insert(userIds, tonumber(userId))
            end
            infoPerPlayer = _getUserInfos(userIds)
        end

        for index, userInfo in data do
            local userId = userInfo.key
            local stat = userInfo.value

            local playerInfo = _findUserInfo(userId, infoPerPlayer)
            GlobalList[statKey][index] = {
                userId = userId,
                username = playerInfo.Username,
                value = stat,
            }
        end
    end
end)