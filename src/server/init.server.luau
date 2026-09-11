local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

Players.RespawnTime = 0.1

local screamRemote = ReplicatedStorage:FindFirstChild("ScreamRemote")
if not screamRemote then
	screamRemote = Instance.new("RemoteEvent")
	screamRemote.Name = "ScreamRemote"
	screamRemote.Parent = ReplicatedStorage
end

local lastScream = {}
local comboHits = {}
local plots = {}
local nextGeneratedPlotIndex = 1
local wasInOwnPlot = {}
local cooldown = 0.5
local comboWindow = 3
local plotSize = Vector3.new(32, 0.5, 32)
local plotSpacing = 42
local wallHeight = 10

local killParts = workspace:FindFirstChild("killParts")

local plotFolder = workspace:FindFirstChild("PlayerPlots")
if not plotFolder then
	plotFolder = Instance.new("Folder")
	plotFolder.Name = "PlayerPlots"
	plotFolder.Parent = workspace
end

for _, oldPlotPart in plotFolder:GetChildren() do
	oldPlotPart:Destroy()
end

local safeZoneFolder = workspace:FindFirstChild("safeZones")
local staticZones = {}
if safeZoneFolder then
	for _, safeZonePart in safeZoneFolder:GetChildren() do
		if safeZonePart:IsA("BasePart") then
			table.insert(staticZones, { part = safeZonePart, owner = nil })
		end
	end
end

local function plotPosition(index: number): Vector3
	local column = (index - 1) % 4
	local row = math.floor((index - 1) / 4)
	return Vector3.new((column - 1.5) * plotSpacing, 0.25, (row - 0.5) * plotSpacing)
end

local function getPlotAtPosition(position: Vector3)
	for _, plot in plots do
		local localPosition = plot.part.CFrame:PointToObjectSpace(position)
		if math.abs(localPosition.X) <= plotSize.X * 0.5 and math.abs(localPosition.Z) <= plotSize.Z * 0.5 then
			return plot
		end
	end
	for _, plot in staticZones do
		local localPosition = plot.part.CFrame:PointToObjectSpace(position)
		if math.abs(localPosition.X) <= plot.part.Size.X * 0.5 and math.abs(localPosition.Z) <= plot.part.Size.Z * 0.5 then
			return plot
		end
	end
	return nil
end

local function setPlotLabel(part: BasePart, text: string)
	local nameGui = part:FindFirstChild("Username")
	if not nameGui then
		nameGui = Instance.new("BillboardGui")
		nameGui.Name = "Username"
		nameGui.Adornee = part
		nameGui.StudsOffset = Vector3.new(0, part.Size.Y * 0.5 + 3, 0)
		nameGui.AlwaysOnTop = true
		nameGui.Parent = part
	end
	nameGui.Size = UDim2.fromScale(10, 4)
	nameGui.MaxDistance = 100

	local nameLabel = nameGui:FindFirstChild("Label")
	if not nameLabel then
		nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Label"
		nameLabel.Size = UDim2.fromScale(1, 1)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(210, 240, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.Parent = nameGui
	end
	nameLabel.Text = text
end

for _, safeZone in staticZones do
	setPlotLabel(safeZone.part, "UNCLAIMED SAFE ZONE")
end

local function createPlot(player: Player, index: number)
	local part = Instance.new("Part")
	part.Name = player.Name .. "Plot"
	part.Size = plotSize
	part.Position = plotPosition(index)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(95, 180, 255)
	part.Transparency = 0.82
	part:SetAttribute("OwnerUserId", player.UserId)
	part.Parent = plotFolder
	local generatedParts = { part }

	for level = 1, 4 do
		local height = wallHeight / 4
		local wallY = part.Position.Y + part.Size.Y * 0.5 + (level - 0.5) * height
		local transparency = 0.2 + (level - 1) * 0.22
		local wallData = {
			{ Position = Vector3.new(part.Position.X, wallY, part.Position.Z - plotSize.Z * 0.5), Size = Vector3.new(plotSize.X, height, 0.3) },
			{ Position = Vector3.new(part.Position.X, wallY, part.Position.Z + plotSize.Z * 0.5), Size = Vector3.new(plotSize.X, height, 0.3) },
			{ Position = Vector3.new(part.Position.X - plotSize.X * 0.5, wallY, part.Position.Z), Size = Vector3.new(0.3, height, plotSize.Z) },
			{ Position = Vector3.new(part.Position.X + plotSize.X * 0.5, wallY, part.Position.Z), Size = Vector3.new(0.3, height, plotSize.Z) },
		}

		for wallIndex, data in wallData do
			local wall = Instance.new("Part")
			wall.Name = string.format("%sWall%d_%d", player.Name, level, wallIndex)
			wall.Position = data.Position
			wall.Size = data.Size
			wall.Anchored = true
			wall.CanCollide = false
			wall.CanTouch = false
			wall.CanQuery = false
			wall.Material = Enum.Material.Neon
			wall.Color = Color3.fromRGB(100, 195, 255)
			wall.Transparency = transparency
			wall.Parent = plotFolder
			table.insert(generatedParts, wall)
		end
	end

	setPlotLabel(part, player.Name .. "'s SAFE ZONE")

	plots[player] = { part = part, index = index, owner = player, generatedParts = generatedParts }
	return part
end

local function moveToPlot(player: Player, character: Model)
	local plot = plots[player]
	if plot then
		local spawnPosition = plot.part.Position + Vector3.new(0, plot.part.Size.Y * 0.5 + 3, 0)
		character:PivotTo(CFrame.new(spawnPosition))
	end
end

local function isPositionInsidePart(position: Vector3, part: BasePart): boolean
	local localPosition = part.CFrame:PointToObjectSpace(position)
	return math.abs(localPosition.X) <= part.Size.X * 0.5
		and math.abs(localPosition.Z) <= part.Size.Z * 0.5
end

local function setupPlayer(player: Player)
	local customZone
	for _, availableZone in staticZones do
		if availableZone.part:GetAttribute("OwnerUserId") == nil then
			customZone = availableZone
			break
		end
	end
	if customZone then
		customZone.owner = player
		customZone.generatedParts = {}
		customZone.part:SetAttribute("OwnerUserId", player.UserId)
		setPlotLabel(customZone.part, player.Name .. "'s SAFE ZONE")
		plots[player] = customZone
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer ~= player then
				local otherCharacter = otherPlayer.Character
				local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
				if otherRoot and otherRoot:IsA("BasePart") and isPositionInsidePart(otherRoot.Position, customZone.part) then
					moveToPlot(otherPlayer, otherCharacter)
				end
			end
		end
	else
		createPlot(player, nextGeneratedPlotIndex)
		nextGeneratedPlotIndex += 1
	end
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 5)
		moveToPlot(player, character)
	end)
	if player.Character then
		moveToPlot(player, player.Character)
	end
end

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

RunService.Heartbeat:Connect(function(deltaTime)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local plot = root and root:IsA("BasePart") and getPlotAtPosition(root.Position)
		if humanoid and plot and plot.owner == player then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 5 * deltaTime)
		end

		local inOwnPlot = plot and plot.owner == player or false
		if inOwnPlot and not wasInOwnPlot[player] then
			comboHits[player] = nil
			screamRemote:FireClient(player, "ComboClear")
		end
		wasInOwnPlot[player] = inOwnPlot
	end
end)

local function killCharacterFromPart(hitPart: BasePart)
	local character = hitPart:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

local function connectKillPart(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end

	instance.Touched:Connect(killCharacterFromPart)
end

if killParts then
	for _, instance in killParts:GetDescendants() do
		connectKillPart(instance)
	end

	killParts.DescendantAdded:Connect(connectKillPart)
end

local function ensureMouthAttachment(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local attachment = head:FindFirstChild("ScreamMouth")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "ScreamMouth"
		attachment.Position = Vector3.new(0, -head.Size.Y * 0.16, -head.Size.Z * 0.55)
		attachment.Parent = head
	end
end

local function damagePlayersInScream(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local mouthAttachment = head and head:FindFirstChild("ScreamMouth")
	if not head or not head:IsA("BasePart") or not mouthAttachment or not mouthAttachment:IsA("Attachment") then
		return
	end

	local mouthPosition = mouthAttachment.WorldPosition
	local screamDirection = mouthAttachment.WorldCFrame.LookVector
	local maximumDistance = 25
	local minimumDot = 0.55
	local hits = comboHits[player] or {}
	local sourcePlot = getPlotAtPosition(mouthPosition)
	if sourcePlot and sourcePlot.owner and sourcePlot.owner ~= player then
		return
	end

	for _, targetPlayer in Players:GetPlayers() do
		if targetPlayer ~= player then
			local targetCharacter = targetPlayer.Character
			local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
			if targetHumanoid and targetHumanoid.Health > 0 and targetHead and targetHead:IsA("BasePart") then
				local targetOffset = targetHead.Position - mouthPosition
				local distance = targetOffset.Magnitude
				if distance <= maximumDistance and distance > 0 then
					local directionToTarget = targetOffset.Unit
					local targetPlot = getPlotAtPosition(targetHead.Position)
					local targetIsAllowed = if sourcePlot then targetPlot == sourcePlot else targetPlot == nil
					if screamDirection:Dot(directionToTarget) >= minimumDot and targetIsAllowed then
						targetHumanoid:TakeDamage(5)
						local previous = hits[targetPlayer]
						local hitCount = if previous and os.clock() - previous.time <= comboWindow then previous.count + 1 else 1
						hits[targetPlayer] = { count = hitCount, time = os.clock() }
						local remaining = 4 - hitCount
						if hitCount >= 4 then
							local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
							if targetRoot and targetRoot:IsA("BasePart") then
								targetRoot:SetNetworkOwner(nil)
								targetHumanoid.PlatformStand = true
								targetHumanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
								targetRoot.AssemblyAngularVelocity = Vector3.new(-10, 8, 12)
								targetRoot:ApplyImpulse((screamDirection * 85 + Vector3.new(0, 70, 0)) * targetRoot.AssemblyMass)
								task.delay(3.5, function()
									if targetRoot.Parent and targetHumanoid.Health > 0 then
										targetHumanoid.PlatformStand = false
										targetHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
										targetRoot:SetNetworkOwner(targetPlayer)
									end
								end)
							end
							hits[targetPlayer] = nil
							screamRemote:FireClient(player, "ComboClear")
						else
							screamRemote:FireClient(player, "ComboUpdate", remaining, comboWindow)
						end
					end
				end
			end
		end
	end
	comboHits[player] = hits
end

local function hasIntruderInPlot(plot, owner: Player): boolean
	for _, targetPlayer in Players:GetPlayers() do
		if targetPlayer ~= owner then
			local character = targetPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local localPosition = plot.part.CFrame:PointToObjectSpace(root.Position)
				if math.abs(localPosition.X) <= plotSize.X * 0.5 and math.abs(localPosition.Z) <= plotSize.Z * 0.5 then
					return true
				end
			end
		end
	end
	return false
end

screamRemote.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if now - (lastScream[player] or 0) < cooldown then
		return
	end

	ensureMouthAttachment(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local sourcePlot = root and root:IsA("BasePart") and getPlotAtPosition(root.Position)
	if sourcePlot and sourcePlot.owner and sourcePlot.owner ~= player then
		screamRemote:FireClient(player, "PlotBlocked")
		return
	end
	if sourcePlot and sourcePlot.owner == player and not hasIntruderInPlot(sourcePlot, player) then
		screamRemote:FireClient(player, "NoTarget")
		return
	end
	lastScream[player] = now
	damagePlayersInScream(player)
	screamRemote:FireAllClients("Scream", player)
end)

Players.PlayerRemoving:Connect(function(player)
	lastScream[player] = nil
	comboHits[player] = nil
	wasInOwnPlot[player] = nil
	local plot = plots[player]
	if plot then
		-- Clear the player entry first
		plots[player] = nil
		
		-- Destroy any generated parts (for generated plots)
		for _, generatedPart in plot.generatedParts do
			generatedPart:Destroy()
		end
		
		-- Reset safe zone if applicable
		if plot.part.Parent == safeZoneFolder then
			plot.owner = nil
			plot.part:SetAttribute("OwnerUserId", nil)
			setPlotLabel(plot.part, "UNCLAIMED SAFE ZONE")
		end
	end
end)

-- ============================================
-- LEADERBOARD & MONEY SYSTEM
-- ============================================

local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerData")

-- Economy Config
local INITIAL_CASH = 100
local INITIAL_REBIRTHS = 0
local REBIRTH_COST = 1000

-- Create remotes for money system
local addCashRemote = Instance.new("RemoteFunction")
addCashRemote.Name = "AddCash"
addCashRemote.Parent = ReplicatedStorage

local rebirthRemote = Instance.new("RemoteFunction")
rebirthRemote.Name = "Rebirth"
rebirthRemote.Parent = ReplicatedStorage

local getCashRemote = Instance.new("RemoteFunction")
getCashRemote.Name = "GetCash"
getCashRemote.Parent = ReplicatedStorage

local getRebirthsRemote = Instance.new("RemoteFunction")
getRebirthsRemote.Name = "GetRebirths"
getRebirthsRemote.Parent = ReplicatedStorage

-- Create leaderboard for player
local function createLeaderboard(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = INITIAL_CASH
	cashValue.Parent = leaderstats

	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name = "Rebirths"
	rebirthsValue.Value = INITIAL_REBIRTHS
	rebirthsValue.Parent = leaderstats
	
	return leaderstats
end

-- Get the Cash/Rebirths IntValues for a player, or nil if not ready yet
local function getStats(player: Player)
	local leaderstatsFolder = player:FindFirstChild("leaderstats")
	if not leaderstatsFolder then
		return nil
	end
	local cash = leaderstatsFolder:FindFirstChild("Cash")
	local rebirths = leaderstatsFolder:FindFirstChild("Rebirths")
	if not (cash and cash:IsA("IntValue") and rebirths and rebirths:IsA("IntValue")) then
		return nil
	end
	return cash, rebirths
end

-- Load player data from DataStore
local function loadPlayerData(player: Player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	local cash, rebirths = getStats(player)
	if success and data and cash and rebirths then
		cash.Value = data.cash or INITIAL_CASH
		rebirths.Value = data.rebirths or INITIAL_REBIRTHS
	end
end

-- Save player data to DataStore
local function savePlayerData(player: Player)
	local cash, rebirths = getStats(player)
	if not (cash and rebirths) then return end

	local data = {
		cash = cash.Value,
		rebirths = rebirths.Value,
	}

	pcall(function()
		playerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)
end

-- Remote function handlers
function addCashRemote.OnServerInvoke(player: Player, amount: number)
	local cash = getStats(player)
	if not cash then return false end
	if amount < 0 then return false end
	cash.Value = cash.Value + amount
	return true
end

function rebirthRemote.OnServerInvoke(player: Player)
	local cash, rebirths = getStats(player)
	if not (cash and rebirths) then return false end
	if cash.Value < REBIRTH_COST then
		return false
	end
	cash.Value = INITIAL_CASH
	rebirths.Value = rebirths.Value + 1
	return true
end

function getCashRemote.OnServerInvoke(player: Player)
	local cash = getStats(player)
	if not cash then return 0 end
	return cash.Value
end

function getRebirthsRemote.OnServerInvoke(player: Player)
	local _, rebirths = getStats(player)
	if not rebirths then return 0 end
	return rebirths.Value
end

-- Player leaderboard setup - runs alongside the existing PlayerAdded/PlayerRemoving connections above
Players.PlayerAdded:Connect(function(player: Player)
	createLeaderboard(player)
	task.wait(0.5)
	loadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	savePlayerData(player)
end)

-- Auto-save every 30 seconds
task.spawn(function()
	while true do
		task.wait(30)
		for _, activePlayer in pairs(Players:GetPlayers()) do
			savePlayerData(activePlayer)
		end
	end
end)