local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local screamRemote = ReplicatedStorage:WaitForChild("ScreamRemote")
local activeShakes = {}
local plotFolder = workspace:WaitForChild("PlayerPlots")
local safeZoneFolder = workspace:FindFirstChild("safeZones")

local effectFolder = Instance.new("Folder")
effectFolder.Name = "LocalScreamEffects"
effectFolder.Parent = workspace

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "ScreamButton"
buttonGui.ResetOnSpawn = false
buttonGui.DisplayOrder = 10
buttonGui.Parent = player:WaitForChild("PlayerGui")

local healthGui = Instance.new("ScreenGui")
healthGui.Name = "CustomHealthBar"
healthGui.ResetOnSpawn = false
healthGui.DisplayOrder = 9
healthGui.Parent = player.PlayerGui

local healthPanel = Instance.new("Frame")
healthPanel.Name = "HealthPanel"
healthPanel.AnchorPoint = Vector2.new(0, 1)
-- Raised above the money HUD pill/rebirth badge stack so they don't overlap
healthPanel.Position = UDim2.new(0, 18, 1, -114)
healthPanel.Size = UDim2.fromOffset(270, 68)
healthPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
healthPanel.BackgroundTransparency = 0.08
healthPanel.BorderSizePixel = 0
healthPanel.Parent = healthGui

local healthPanelCorner = Instance.new("UICorner")
healthPanelCorner.CornerRadius = UDim.new(0, 8)
healthPanelCorner.Parent = healthPanel

local healthPanelStroke = Instance.new("UIStroke")
healthPanelStroke.Color = Color3.fromRGB(0, 0, 0)
healthPanelStroke.Thickness = 3
healthPanelStroke.Parent = healthPanel

local healthTitle = Instance.new("TextLabel")
healthTitle.Name = "Title"
healthTitle.Position = UDim2.fromOffset(12, 7)
healthTitle.Size = UDim2.fromOffset(90, 18)
healthTitle.BackgroundTransparency = 1
healthTitle.Text = "HEALTH"
healthTitle.TextColor3 = Color3.fromRGB(235, 240, 246)
healthTitle.TextSize = 14
healthTitle.Font = Enum.Font.GothamBold
healthTitle.TextXAlignment = Enum.TextXAlignment.Left
healthTitle.Parent = healthPanel

local healthBar = Instance.new("Frame")
healthBar.Name = "Bar"
healthBar.Position = UDim2.fromOffset(12, 31)
healthBar.Size = UDim2.new(1, -24, 0, 23)
healthBar.BackgroundColor3 = Color3.fromRGB(35, 38, 44)
healthBar.BorderSizePixel = 0
healthBar.ClipsDescendants = true
healthBar.Parent = healthPanel

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 4)
healthBarCorner.Parent = healthBar

local healthBarStroke = Instance.new("UIStroke")
healthBarStroke.Color = Color3.fromRGB(0, 0, 0)
healthBarStroke.Thickness = 2
healthBarStroke.Parent = healthBar

local localDamageFill = Instance.new("Frame")
localDamageFill.Name = "DamageTrail"
localDamageFill.Size = UDim2.fromScale(1, 1)
localDamageFill.BackgroundColor3 = Color3.fromRGB(255, 220, 75)
localDamageFill.BorderSizePixel = 0
localDamageFill.ZIndex = 1
localDamageFill.Parent = healthBar

local localHealthFill = Instance.new("Frame")
localHealthFill.Name = "Fill"
localHealthFill.Size = UDim2.fromScale(1, 1)
localHealthFill.BackgroundColor3 = Color3.fromRGB(55, 210, 90)
localHealthFill.BorderSizePixel = 0
localHealthFill.ZIndex = 2
localHealthFill.Parent = healthBar

local healthValue = Instance.new("TextLabel")
healthValue.Name = "Value"
healthValue.AnchorPoint = Vector2.new(1, 0.5)
healthValue.Position = UDim2.new(1, -7, 0.5, 0)
healthValue.Size = UDim2.fromOffset(82, 22)
healthValue.BackgroundTransparency = 1
healthValue.Text = "0 / 100"
healthValue.TextColor3 = Color3.fromRGB(255, 255, 255)
healthValue.TextSize = 14
healthValue.Font = Enum.Font.GothamBold
healthValue.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
healthValue.TextStrokeTransparency = 0.25
healthValue.TextXAlignment = Enum.TextXAlignment.Right
healthValue.ZIndex = 3
healthValue.Parent = healthBar

local function healthColor(ratio: number): Color3
	if ratio > 0.55 then
		return Color3.fromRGB(55, 210, 90)
	elseif ratio > 0.25 then
		return Color3.fromRGB(245, 195, 55)
	end
	return Color3.fromRGB(225, 55, 55)
end

local function createHealthDisplay(character: Model, humanoid: Humanoid, isLocal: boolean)
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	local fill: Frame
	local damageFill: Frame
	local valueLabel: TextLabel?
	if isLocal then
		fill = localHealthFill
		damageFill = localDamageFill
		valueLabel = healthValue
	else
		local head = character:WaitForChild("Head", 5)
		if not head or not head:IsA("BasePart") then
			return
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "CustomHealthBar"
		billboard.Adornee = head
		billboard.Size = UDim2.fromOffset(142, 42)
		billboard.StudsOffset = Vector3.new(0, 3.2, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 60
		billboard.Parent = head

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = character.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 12
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.TextStrokeTransparency = 0.2
		nameLabel.Parent = billboard

		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.Position = UDim2.fromOffset(4, 19)
		bar.Size = UDim2.new(1, -8, 0, 14)
		bar.BackgroundColor3 = Color3.fromRGB(35, 38, 44)
		bar.BorderSizePixel = 0
		bar.ClipsDescendants = true
		bar.Parent = billboard

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Thickness = 2
		stroke.Parent = bar

		damageFill = Instance.new("Frame")
		damageFill.Name = "DamageTrail"
		damageFill.Size = UDim2.fromScale(1, 1)
		damageFill.BackgroundColor3 = Color3.fromRGB(255, 220, 75)
		damageFill.BorderSizePixel = 0
		damageFill.ZIndex = 1
		damageFill.Parent = bar

		fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(55, 210, 90)
		fill.BorderSizePixel = 0
		fill.ZIndex = 2
		fill.Parent = bar

		local overheadValueLabel = Instance.new("TextLabel")
		overheadValueLabel.Name = "Value"
		overheadValueLabel.AnchorPoint = Vector2.new(1, 0.5)
		overheadValueLabel.Position = UDim2.new(1, -6, 0.5, 0)
		overheadValueLabel.Size = UDim2.fromOffset(50, 16)
		overheadValueLabel.BackgroundTransparency = 1
		overheadValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		overheadValueLabel.TextSize = 10
		overheadValueLabel.Font = Enum.Font.GothamBold
		overheadValueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		overheadValueLabel.TextStrokeTransparency = 0.2
		overheadValueLabel.TextXAlignment = Enum.TextXAlignment.Right
		overheadValueLabel.ZIndex = 3
		overheadValueLabel.Parent = bar
		valueLabel = overheadValueLabel
	end

	local function updateHealth(health: number)
		local maxHealth = math.max(humanoid.MaxHealth, 1)
		local ratio = math.clamp(health / maxHealth, 0, 1)
		local newColor = healthColor(ratio)
		if valueLabel then
			valueLabel.Text = string.format("%d / %d", math.ceil(math.max(health, 0)), math.ceil(maxHealth))
		end

		TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(ratio, 1),
			BackgroundColor3 = newColor,
		}):Play()
		local damageTween = TweenService:Create(damageFill, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(ratio, 1),
		})
		damageTween:Play()
	end

	updateHealth(humanoid.Health)
	humanoid.HealthChanged:Connect(updateHealth)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateHealth(humanoid.Health)
	end)
end

local function setupHealthForPlayer(targetPlayer: Player)
	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			createHealthDisplay(character, humanoid, targetPlayer == player)
		end
	end

	-- Immediately setup health for existing character
	if targetPlayer.Character then
		onCharacter(targetPlayer.Character)
	end

	-- Setup for future respawns
	targetPlayer.CharacterAdded:Connect(onCharacter)
end

-- Setup for all currently connected players at startup
for _, targetPlayer in Players:GetPlayers() do
	setupHealthForPlayer(targetPlayer)
end

-- Setup for new players joining later
Players.PlayerAdded:Connect(setupHealthForPlayer)

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "RingVersion"
versionLabel.AnchorPoint = Vector2.new(1, 1)
versionLabel.Position = UDim2.new(1, -18, 1, -14)
versionLabel.Size = UDim2.fromOffset(90, 22)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "RINGS v28"
versionLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
versionLabel.TextSize = 13
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = buttonGui

local screamButton = Instance.new("TextButton")
screamButton.Name = "Scream"
screamButton.AnchorPoint = Vector2.new(0.5, 1)
screamButton.Position = UDim2.new(0.5, 0, 1, -36)
screamButton.Size = UDim2.fromScale(0.24, 0.08)
screamButton.BackgroundColor3 = Color3.fromRGB(209, 57, 57)
screamButton.TextColor3 = Color3.fromRGB(255, 244, 211)
screamButton.Text = ""
screamButton.Font = Enum.Font.GothamBlack
screamButton.AutoButtonColor = true
screamButton.ZIndex = 2
screamButton.Parent = buttonGui

local buttonSize = Instance.new("UISizeConstraint")
buttonSize.MinSize = Vector2.new(180, 56)
buttonSize.MaxSize = Vector2.new(300, 78)
buttonSize.Parent = screamButton

local buttonRatio = Instance.new("UIAspectRatioConstraint")
buttonRatio.AspectRatio = 3.25
buttonRatio.Parent = screamButton

local buttonLabel = Instance.new("TextLabel")
buttonLabel.Name = "Label"
buttonLabel.Size = UDim2.fromScale(1, 1)
buttonLabel.BackgroundTransparency = 1
buttonLabel.TextColor3 = screamButton.TextColor3
buttonLabel.Text = "SCREAM"
buttonLabel.TextScaled = true
buttonLabel.Font = screamButton.Font
buttonLabel.ZIndex = 4
buttonLabel.Parent = screamButton

local labelSize = Instance.new("UITextSizeConstraint")
labelSize.MinTextSize = 16
labelSize.MaxTextSize = 28
labelSize.Parent = buttonLabel

local buttonScale = Instance.new("UIScale")
buttonScale.Scale = 1
buttonScale.Parent = screamButton

local function tweenButtonScale(scale: number, duration: number, easingStyle: Enum.EasingStyle)
	TweenService:Create(
		buttonScale,
		TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out),
		{ Scale = scale }
	):Play()
end

screamButton.MouseEnter:Connect(function()
	if screamButton.Active then
		screamButton.BackgroundColor3 = Color3.fromRGB(232, 72, 72)
		tweenButtonScale(1.06, 0.12, Enum.EasingStyle.Quad)
	end
end)

screamButton.MouseLeave:Connect(function()
	if screamButton.Active then
		screamButton.BackgroundColor3 = Color3.fromRGB(209, 57, 57)
		tweenButtonScale(1, 0.12, Enum.EasingStyle.Quad)
	end
end)

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = screamButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(120, 120, 130)
buttonStroke.Thickness = 3
buttonStroke.Parent = screamButton

local cooldownBar = Instance.new("Frame")
cooldownBar.Name = "CooldownBar"
cooldownBar.AnchorPoint = Vector2.new(1, 0)
cooldownBar.Position = UDim2.fromScale(1, 0)
cooldownBar.Size = UDim2.fromScale(1, 1)
cooldownBar.BackgroundColor3 = Color3.fromRGB(105, 105, 105)
cooldownBar.BackgroundTransparency = 0.08
cooldownBar.BorderSizePixel = 0
cooldownBar.ZIndex = 3
cooldownBar.Visible = false
cooldownBar.Parent = screamButton

local cooldownCorner = Instance.new("UICorner")
cooldownCorner.CornerRadius = UDim.new(0, 12)
cooldownCorner.Parent = cooldownBar

local cooldownProgress = Instance.new("Frame")
cooldownProgress.Name = "Progress"
cooldownProgress.AnchorPoint = Vector2.new(1, 0)
cooldownProgress.Position = UDim2.fromScale(1, 0)
cooldownProgress.Size = UDim2.fromScale(0, 1)
cooldownProgress.BackgroundColor3 = Color3.fromRGB(155, 155, 165)
cooldownProgress.BackgroundTransparency = 0.2
cooldownProgress.BorderSizePixel = 0
cooldownProgress.ZIndex = 3
cooldownProgress.Parent = cooldownBar

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 12)
progressCorner.Parent = cooldownProgress

local comboLabel = Instance.new("TextLabel")
comboLabel.Name = "FlingComboLabel"
comboLabel.AnchorPoint = Vector2.new(0.5, 1)
comboLabel.Position = UDim2.new(0.5, 0, 1, -104)
comboLabel.Size = UDim2.fromScale(0.28, 0.035)
comboLabel.BackgroundTransparency = 1
comboLabel.Text = ""
comboLabel.TextColor3 = Color3.fromRGB(255, 226, 150)
comboLabel.TextScaled = true
comboLabel.Font = Enum.Font.GothamBold
comboLabel.Visible = false
comboLabel.Parent = buttonGui

local comboLabelSize = Instance.new("UITextSizeConstraint")
comboLabelSize.MinTextSize = 12
comboLabelSize.MaxTextSize = 20
comboLabelSize.Parent = comboLabel

local comboBar = Instance.new("Frame")
comboBar.Name = "FlingComboBar"
comboBar.AnchorPoint = Vector2.new(0.5, 1)
comboBar.Position = UDim2.new(0.5, 0, 1, -84)
comboBar.Size = UDim2.fromScale(0.24, 0.012)
comboBar.BackgroundColor3 = Color3.fromRGB(75, 75, 85)
comboBar.BorderSizePixel = 0
comboBar.Visible = false
comboBar.Parent = buttonGui

local comboBarCorner = Instance.new("UICorner")
comboBarCorner.CornerRadius = UDim.new(1, 0)
comboBarCorner.Parent = comboBar

local comboProgress = Instance.new("Frame")
comboProgress.Name = "Progress"
comboProgress.Size = UDim2.fromScale(1, 1)
comboProgress.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
comboProgress.BorderSizePixel = 0
comboProgress.Parent = comboBar

local comboProgressCorner = Instance.new("UICorner")
comboProgressCorner.CornerRadius = UDim.new(1, 0)
comboProgressCorner.Parent = comboProgress

local safeZoneLabel = Instance.new("TextLabel")
safeZoneLabel.Name = "SafeZoneLabel"
safeZoneLabel.AnchorPoint = Vector2.new(0.5, 1)
safeZoneLabel.Position = UDim2.new(0.5, 0, 1, -64)
safeZoneLabel.Size = UDim2.fromScale(0.3, 0.035)
safeZoneLabel.BackgroundTransparency = 1
safeZoneLabel.Text = "SAFE ZONE - WALK OUT TO SCREAM"
safeZoneLabel.TextColor3 = Color3.fromRGB(160, 220, 255)
safeZoneLabel.TextScaled = true
safeZoneLabel.Font = Enum.Font.GothamBold
safeZoneLabel.Visible = false
safeZoneLabel.Parent = buttonGui

local safeZoneLabelSize = Instance.new("UITextSizeConstraint")
safeZoneLabelSize.MinTextSize = 11
safeZoneLabelSize.MaxTextSize = 18
safeZoneLabelSize.Parent = safeZoneLabel

local comboToken = 0

local function hideCombo()
	comboToken += 1
	comboLabel.Visible = false
	comboBar.Visible = false
	comboProgress.Size = UDim2.fromScale(0, 1)
end

local function showCombo(remaining: number, duration: number)
	comboToken += 1
	local token = comboToken
	comboLabel.Text = string.format("FLING COMBO LEFT: %d", remaining)
	comboLabel.Visible = true
	comboBar.Visible = true
	comboProgress.Size = UDim2.fromScale(1, 1)
	local tween = TweenService:Create(
		comboProgress,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.fromScale(0, 1) }
	)
	tween:Play()
	task.delay(duration, function()
		if comboToken == token then
			comboLabel.Visible = false
			comboBar.Visible = false
		end
	end)
end

local function configureCharacterAnimations(character: Model)
	local animateScript = character:WaitForChild("Animate", 5)
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = true
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local idleAnimationIds = {}
		local idleFolder = animateScript and animateScript:FindFirstChild("idle")
		if idleFolder then
			for _, animation in idleFolder:GetDescendants() do
				if animation:IsA("Animation") then
					idleAnimationIds[animation.AnimationId] = true
				end
			end
		end

		local function stopIdle(track: AnimationTrack)
			local animation = track.Animation
			if string.find(string.lower(track.Name), "idle")
				or (animation and idleAnimationIds[animation.AnimationId]) then
				track:Stop(0)
			end
		end

		for _, track in animator:GetPlayingAnimationTracks() do
			stopIdle(track)
		end

		animator.AnimationPlayed:Connect(stopIdle)
	end
end

player.CharacterAdded:Connect(configureCharacterAnimations)
if player.Character then
	task.defer(configureCharacterAnimations, player.Character)
end

local function getMouthData(targetPlayer: Player)
	local character = targetPlayer.Character
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not head or not head:IsA("BasePart") then
		return nil
	end

	local attachment = head:FindFirstChild("ScreamMouth")
	if not attachment or not attachment:IsA("Attachment") then
		attachment = Instance.new("Attachment")
		attachment.Name = "ScreamMouth"
		attachment.Position = Vector3.new(0, -head.Size.Y * 0.16, -head.Size.Z * 0.55)
		attachment.Parent = head
	end

	local horizontalVelocity = Vector3.zero
	if root and root:IsA("BasePart") then
		horizontalVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
	end

	local mouthCFrame = attachment.WorldCFrame
	return mouthCFrame.Position, mouthCFrame.LookVector, mouthCFrame.RightVector, mouthCFrame.UpVector, horizontalVelocity
end

local function createRing(targetPlayer: Player, delay: number, radius: number)
	task.delay(delay, function()
		local origin, direction, right, up, horizontalVelocity = getMouthData(targetPlayer)
		if not origin then
			return
		end

		local duration = 0.65 + math.random() * 0.1
		local travelDistance = 10 + radius * 0.5
		local finalRadius = 0.25 + radius
		local finalCenter = origin + direction * travelDistance + horizontalVelocity * (duration + 0.35)
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		for index = 1, 24 do
			local angle = (index / 24) * math.pi * 2
			local radial = right * math.cos(angle) + up * math.sin(angle)
			local tangent = right * -math.sin(angle) + up * math.cos(angle)
			local segment = Instance.new("Part")
			segment.Name = "GhostRingSegment"
			segment.Material = Enum.Material.ForceField
			segment.Color = Color3.fromRGB(245, 248, 255)
			segment.Anchored = true
			segment.CFrame = CFrame.fromMatrix(origin + radial * 0.25, tangent, radial, direction)
			segment.Size = Vector3.new(0.25, 0.14, 0.14)
			segment.Transparency = 0.2
			segment.CanCollide = false
			segment.CanTouch = false
			segment.CanQuery = false
			segment.CastShadow = false
			segment.Parent = effectFolder

			local tween = TweenService:Create(segment, tweenInfo, {
				CFrame = CFrame.fromMatrix(finalCenter + radial * finalRadius, tangent, radial, direction),
				Size = Vector3.new(math.max(0.3, finalRadius * 0.36), 0.2, 0.2),
				Transparency = 1,
			})
			tween:Play()
			Debris:AddItem(segment, duration + 0.05)
		end
	end)
end


screamRemote.OnClientEvent:Connect(function(action: string, value: any, duration: number?)
	if action == "Scream" and typeof(value) == "Instance" and value:IsA("Player") then
		for index = 1, 10 do
			createRing(value, (index - 1) * 0.08, 4.8)
		end
	elseif action == "ComboUpdate" and typeof(value) == "number" and duration then
		showCombo(value, duration)
	elseif action == "ComboClear" then
		hideCombo()
	elseif action == "PlotBlocked" then
		safeZoneLabel.Text = "SAFE ZONE - WALK OUT TO SCREAM"
		safeZoneLabel.Visible = true
		task.delay(2, function()
			safeZoneLabel.Visible = false
		end)
	elseif action == "NoTarget" then
		safeZoneLabel.Text = "SAFE ZONE - WAIT FOR SOMEONE"
		safeZoneLabel.Visible = true
		task.delay(2, function()
			safeZoneLabel.Visible = false
		end)
	end
end)

local function shakeCamera()
	table.insert(activeShakes, {
		startedAt = os.clock(),
		duration = 0.18 + math.random() * 0.14,
		strength = 0.08 + math.random() * 0.13,
	})
end

local function getCurrentPlot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	for _, plot in plotFolder:GetChildren() do
		if plot:IsA("BasePart") and plot:GetAttribute("OwnerUserId") then
			local localPosition = plot.CFrame:PointToObjectSpace(root.Position)
			if math.abs(localPosition.X) <= plot.Size.X * 0.5 and math.abs(localPosition.Z) <= plot.Size.Z * 0.5 then
				return plot
			end
		end
	end
	if safeZoneFolder then
		for _, plot in safeZoneFolder:GetChildren() do
			if plot:IsA("BasePart") then
				local localPosition = plot.CFrame:PointToObjectSpace(root.Position)
				if math.abs(localPosition.X) <= plot.Size.X * 0.5 and math.abs(localPosition.Z) <= plot.Size.Z * 0.5 then
					return plot
				end
			end
		end
	end
	return nil
end

local function hasOtherPlayer(plot: BasePart): boolean
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			local character = otherPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local localPosition = plot.CFrame:PointToObjectSpace(root.Position)
				if math.abs(localPosition.X) <= plot.Size.X * 0.5 and math.abs(localPosition.Z) <= plot.Size.Z * 0.5 then
					return true
				end
			end
		end
	end
	return false
end

RunService.RenderStepped:Connect(function()
	local currentPlot = getCurrentPlot()
	local ownerUserId = currentPlot and currentPlot:GetAttribute("OwnerUserId")
	local isClaimed = ownerUserId ~= nil
	local isOwner = isClaimed and ownerUserId == player.UserId
	local intruderInside = currentPlot and hasOtherPlayer(currentPlot) or false
	screamButton.Visible = currentPlot == nil or not isClaimed or (isOwner and intruderInside)
	if currentPlot and isClaimed and isOwner and not intruderInside then
		safeZoneLabel.Text = "SAFE ZONE - NO ONE ELSE IS INSIDE"
		safeZoneLabel.Visible = true
	elseif currentPlot and isClaimed and isOwner and intruderInside then
		safeZoneLabel.Text = "SCREAM"
		safeZoneLabel.Visible = true
	elseif currentPlot and isClaimed then
		safeZoneLabel.Text = "SAFE ZONE - SCREAMS DISABLED"
		safeZoneLabel.Visible = true
	else
		safeZoneLabel.Visible = false
	end
end)

RunService:BindToRenderStep("ScreamCameraShake", Enum.RenderPriority.Camera.Value + 1, function()
	local now = os.clock()
	local offset = Vector3.zero
	local rotation = Vector3.zero

	for index = #activeShakes, 1, -1 do
		local shake = activeShakes[index]
		local progress = (now - shake.startedAt) / shake.duration
		if progress >= 1 then
			table.remove(activeShakes, index)
		else
			local falloff = 1 - progress
			offset += Vector3.new(
				(math.random() - 0.5) * shake.strength * falloff,
				(math.random() - 0.5) * shake.strength * falloff,
				0
			)
			rotation += Vector3.new(
				(math.random() - 0.5) * shake.strength * 0.35 * falloff,
				(math.random() - 0.5) * shake.strength * 0.35 * falloff,
				(math.random() - 0.5) * shake.strength * 0.2 * falloff
			)
		end
	end

	if #activeShakes > 0 then
		camera.CFrame *= CFrame.new(offset) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
	end
end)

local function scream()
	if not screamButton.Active then
		return
	end
	local currentPlot = getCurrentPlot()
	local ownerUserId = currentPlot and currentPlot:GetAttribute("OwnerUserId")
	local isClaimed = ownerUserId ~= nil
	local isOwner = isClaimed and ownerUserId == player.UserId
	if currentPlot and isClaimed and not isOwner then
		safeZoneLabel.Visible = true
		task.delay(2, function()
			safeZoneLabel.Visible = false
		end)
		return
	end

	screamRemote:FireServer()

	shakeCamera()
	screamButton.Active = false
	screamButton.AutoButtonColor = false
	screamButton.BackgroundColor3 = Color3.fromRGB(105, 105, 105)
	buttonLabel.Text = "COOLDOWN: 0.5s"
	cooldownProgress.Size = UDim2.fromScale(0, 1)
	cooldownBar.Visible = true

	local shrinkTween = TweenService:Create(
		buttonScale,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0.84 }
	)
	local popTween = TweenService:Create(
		buttonScale,
		TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	shrinkTween:Play()
	shrinkTween.Completed:Wait()
	popTween:Play()
	task.delay(0.1, function()
		if not screamButton.Active then
			buttonStroke.Color = Color3.fromRGB(135, 135, 135)
		end
	end)

	local cooldown = 0.5
	local startedAt = os.clock()
	while os.clock() - startedAt < cooldown do
		local progress = math.clamp((os.clock() - startedAt) / cooldown, 0, 1)
		local remaining = math.max(0, cooldown - (os.clock() - startedAt))
		cooldownProgress.Size = UDim2.fromScale(progress, 1)
		buttonLabel.Text = string.format("COOLDOWN: %.1fs", remaining)
		task.wait()
	end

	cooldownBar.Visible = false
	screamButton.Active = true
	screamButton.AutoButtonColor = true
	screamButton.BackgroundColor3 = Color3.fromRGB(209, 57, 57)
	buttonLabel.Text = "SCREAM"
end

screamButton.Activated:Connect(scream)

-- ============================================
-- MONEY HUD (small pill, bottom-left) + ANIMATED MENU
-- ============================================

local leaderstats = player:WaitForChild("leaderstats", 30)
if not leaderstats then
	warn("GameUI: Failed to load leaderstats!")
else
	local addCashRemote = ReplicatedStorage:WaitForChild("AddCash", 30)
	local rebirthRemote = ReplicatedStorage:WaitForChild("Rebirth", 30)
	local getCashRemote = ReplicatedStorage:WaitForChild("GetCash", 30)
	local getRebirthsRemote = ReplicatedStorage:WaitForChild("GetRebirths", 30)

	if not (addCashRemote and rebirthRemote and getCashRemote and getRebirthsRemote) then
		warn("GameUI: Failed to load remotes!")
	else
		local GREEN = Color3.fromRGB(87, 227, 118)
		local WHITE = Color3.fromRGB(245, 245, 245)
		local BLACK = Color3.fromRGB(18, 18, 20)
		local PURPLE = Color3.fromRGB(170, 110, 255)
		local REBIRTH_COST = 1000

		local hud = Instance.new("ScreenGui")
		hud.Name = "MoneyHUD"
		hud.ResetOnSpawn = false
		hud.IgnoreGuiInset = true
		hud.DisplayOrder = 100
		hud.Parent = player:WaitForChild("PlayerGui")

		-- Scales the whole HUD to fit phones/tablets/desktop consistently
		local uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = hud

		local function fitScale()
			local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local scale = math.clamp(viewport.Y / 720, 0.7, 1.15)
			uiScale.Scale = scale
		end
		fitScale()
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fitScale)
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)
		end

		-- ===== Cash pill (small, left side) =====
		local pill = Instance.new("Frame")
		pill.Name = "CashPill"
		pill.AnchorPoint = Vector2.new(0, 1)
		pill.Position = UDim2.new(0, 16, 1, -16)
		pill.Size = UDim2.fromOffset(150, 44)
		pill.BackgroundColor3 = BLACK
		pill.BorderSizePixel = 0
		pill.Parent = hud

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(1, 0)
		pillCorner.Parent = pill

		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color = GREEN
		pillStroke.Thickness = 2
		pillStroke.Transparency = 0.2
		pillStroke.Parent = pill

		local cashIcon = Instance.new("Frame")
		cashIcon.Name = "Icon"
		cashIcon.AnchorPoint = Vector2.new(0, 0.5)
		cashIcon.Position = UDim2.new(0, 4, 0.5, 0)
		cashIcon.Size = UDim2.fromOffset(36, 36)
		cashIcon.BackgroundColor3 = GREEN
		cashIcon.BorderSizePixel = 0
		cashIcon.Parent = pill

		local cashIconCorner = Instance.new("UICorner")
		cashIconCorner.CornerRadius = UDim.new(1, 0)
		cashIconCorner.Parent = cashIcon

		local cashIconLabel = Instance.new("TextLabel")
		cashIconLabel.BackgroundTransparency = 1
		cashIconLabel.Size = UDim2.fromScale(1, 1)
		cashIconLabel.Text = "$"
		cashIconLabel.TextColor3 = BLACK
		cashIconLabel.Font = Enum.Font.GothamBlack
		cashIconLabel.TextSize = 20
		cashIconLabel.Parent = cashIcon

		local cashText = Instance.new("TextLabel")
		cashText.Name = "CashText"
		cashText.BackgroundTransparency = 1
		cashText.AnchorPoint = Vector2.new(0, 0.5)
		cashText.Position = UDim2.new(0, 46, 0.5, 0)
		cashText.Size = UDim2.new(1, -80, 1, 0)
		cashText.Text = "100"
		cashText.TextColor3 = WHITE
		cashText.Font = Enum.Font.GothamBold
		cashText.TextSize = 20
		cashText.TextXAlignment = Enum.TextXAlignment.Left
		cashText.Parent = pill

		-- Plus button that opens the menu
		local plusButton = Instance.new("TextButton")
		plusButton.Name = "PlusButton"
		plusButton.AnchorPoint = Vector2.new(1, 0.5)
		plusButton.Position = UDim2.new(1, -4, 0.5, 0)
		plusButton.Size = UDim2.fromOffset(34, 34)
		plusButton.BackgroundColor3 = GREEN
		plusButton.BorderSizePixel = 0
		plusButton.Text = "+"
		plusButton.TextColor3 = BLACK
		plusButton.Font = Enum.Font.GothamBlack
		plusButton.TextSize = 22
		plusButton.AutoButtonColor = false
		plusButton.Parent = pill

		local plusCorner = Instance.new("UICorner")
		plusCorner.CornerRadius = UDim.new(1, 0)
		plusCorner.Parent = plusButton

		-- ===== Rebirths mini badge (above pill) =====
		local rebirthBadge = Instance.new("Frame")
		rebirthBadge.Name = "RebirthBadge"
		rebirthBadge.AnchorPoint = Vector2.new(0, 1)
		rebirthBadge.Position = UDim2.new(0, 16, 1, -66)
		rebirthBadge.Size = UDim2.fromOffset(120, 32)
		rebirthBadge.BackgroundColor3 = BLACK
		rebirthBadge.BorderSizePixel = 0
		rebirthBadge.Parent = hud

		local rebirthBadgeCorner = Instance.new("UICorner")
		rebirthBadgeCorner.CornerRadius = UDim.new(1, 0)
		rebirthBadgeCorner.Parent = rebirthBadge

		local rebirthBadgeStroke = Instance.new("UIStroke")
		rebirthBadgeStroke.Color = PURPLE
		rebirthBadgeStroke.Thickness = 2
		rebirthBadgeStroke.Transparency = 0.2
		rebirthBadgeStroke.Parent = rebirthBadge

		local rebirthText = Instance.new("TextLabel")
		rebirthText.BackgroundTransparency = 1
		rebirthText.Size = UDim2.fromScale(1, 1)
		rebirthText.Text = "✦ 0 Rebirths"
		rebirthText.TextColor3 = PURPLE
		rebirthText.Font = Enum.Font.GothamBold
		rebirthText.TextSize = 14
		rebirthText.Parent = rebirthBadge

		-- ===== Menu overlay (gamepasses + rebirth), animated open/close =====
		local menuOverlay = Instance.new("Frame")
		menuOverlay.Name = "MenuOverlay"
		menuOverlay.BackgroundColor3 = BLACK
		menuOverlay.BackgroundTransparency = 1
		menuOverlay.Size = UDim2.fromScale(1, 1)
		menuOverlay.Visible = false
		menuOverlay.ZIndex = 10
		menuOverlay.Parent = hud

		local menuCard = Instance.new("Frame")
		menuCard.Name = "MenuCard"
		menuCard.AnchorPoint = Vector2.new(0, 1)
		menuCard.Position = UDim2.new(0, 16, 1, -16)
		menuCard.Size = UDim2.fromOffset(280, 0)
		menuCard.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
		menuCard.BorderSizePixel = 0
		menuCard.ClipsDescendants = true
		menuCard.ZIndex = 11
		menuCard.Parent = menuOverlay

		local menuCorner = Instance.new("UICorner")
		menuCorner.CornerRadius = UDim.new(0, 16)
		menuCorner.Parent = menuCard

		local menuStroke = Instance.new("UIStroke")
		menuStroke.Color = GREEN
		menuStroke.Thickness = 2
		menuStroke.Transparency = 0.3
		menuStroke.Parent = menuCard

		local menuList = Instance.new("UIListLayout")
		menuList.Padding = UDim.new(0, 8)
		menuList.SortOrder = Enum.SortOrder.LayoutOrder
		menuList.Parent = menuCard

		local menuPadding = Instance.new("UIPadding")
		menuPadding.PaddingTop = UDim.new(0, 14)
		menuPadding.PaddingBottom = UDim.new(0, 14)
		menuPadding.PaddingLeft = UDim.new(0, 14)
		menuPadding.PaddingRight = UDim.new(0, 14)
		menuPadding.Parent = menuCard

		local menuTitle = Instance.new("TextLabel")
		menuTitle.Name = "Title"
		menuTitle.LayoutOrder = 1
		menuTitle.BackgroundTransparency = 1
		menuTitle.Size = UDim2.new(1, 0, 0, 26)
		menuTitle.Text = "SHOP"
		menuTitle.TextColor3 = WHITE
		menuTitle.Font = Enum.Font.GothamBlack
		menuTitle.TextSize = 20
		menuTitle.TextXAlignment = Enum.TextXAlignment.Left
		menuTitle.Parent = menuCard

		-- Rebirth row inside the menu
		local rebirthRow = Instance.new("TextButton")
		rebirthRow.Name = "RebirthRow"
		rebirthRow.LayoutOrder = 2
		rebirthRow.Size = UDim2.new(1, 0, 0, 52)
		rebirthRow.BackgroundColor3 = PURPLE
		rebirthRow.BorderSizePixel = 0
		rebirthRow.AutoButtonColor = false
		rebirthRow.Text = ""
		rebirthRow.Parent = menuCard

		local rebirthRowCorner = Instance.new("UICorner")
		rebirthRowCorner.CornerRadius = UDim.new(0, 10)
		rebirthRowCorner.Parent = rebirthRow

		local rebirthRowLabel = Instance.new("TextLabel")
		rebirthRowLabel.BackgroundTransparency = 1
		rebirthRowLabel.Size = UDim2.fromScale(1, 1)
		rebirthRowLabel.Text = "✦ REBIRTH — Cost $" .. tostring(REBIRTH_COST)
		rebirthRowLabel.TextColor3 = WHITE
		rebirthRowLabel.Font = Enum.Font.GothamBold
		rebirthRowLabel.TextSize = 15
		rebirthRowLabel.Parent = rebirthRow

		-- Example gamepass row (placeholder, easy to duplicate for more passes)
		local gamepassRow = Instance.new("TextButton")
		gamepassRow.Name = "GamepassRow"
		gamepassRow.LayoutOrder = 3
		gamepassRow.Size = UDim2.new(1, 0, 0, 52)
		gamepassRow.BackgroundColor3 = GREEN
		gamepassRow.BorderSizePixel = 0
		gamepassRow.AutoButtonColor = false
		gamepassRow.Text = ""
		gamepassRow.Parent = menuCard

		local gamepassRowCorner = Instance.new("UICorner")
		gamepassRowCorner.CornerRadius = UDim.new(0, 10)
		gamepassRowCorner.Parent = gamepassRow

		local gamepassRowLabel = Instance.new("TextLabel")
		gamepassRowLabel.BackgroundTransparency = 1
		gamepassRowLabel.Size = UDim2.fromScale(1, 1)
		gamepassRowLabel.Text = "💎 2x CASH GAMEPASS"
		gamepassRowLabel.TextColor3 = BLACK
		gamepassRowLabel.Font = Enum.Font.GothamBold
		gamepassRowLabel.TextSize = 15
		gamepassRowLabel.Parent = gamepassRow

		local closeButton = Instance.new("TextButton")
		closeButton.Name = "CloseButton"
		closeButton.LayoutOrder = 4
		closeButton.Size = UDim2.new(1, 0, 0, 36)
		closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
		closeButton.BorderSizePixel = 0
		closeButton.Text = "CLOSE"
		closeButton.TextColor3 = WHITE
		closeButton.Font = Enum.Font.GothamBold
		closeButton.TextSize = 14
		closeButton.Parent = menuCard

		local closeButtonCorner = Instance.new("UICorner")
		closeButtonCorner.CornerRadius = UDim.new(0, 8)
		closeButtonCorner.Parent = closeButton

		local MENU_OPEN_HEIGHT = 226
		local menuOpen = false

		local function setMenuOpen(open: boolean)
			if open == menuOpen then return end
			menuOpen = open

			if open then
				menuOverlay.Visible = true
			end

			local cardGoal = { Size = UDim2.fromOffset(280, open and MENU_OPEN_HEIGHT or 0) }
			local overlayGoal = { BackgroundTransparency = open and 0.55 or 1 }
			local plusGoal = { Rotation = open and 45 or 0 }

			local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(menuCard, tweenInfo, cardGoal):Play()
			TweenService:Create(menuOverlay, TweenInfo.new(0.2), overlayGoal):Play()
			TweenService:Create(plusButton, TweenInfo.new(0.2), plusGoal):Play()

			if not open then
				task.delay(0.28, function()
					if not menuOpen then
						menuOverlay.Visible = false
					end
				end)
			end
		end

		plusButton.MouseButton1Click:Connect(function()
			setMenuOpen(not menuOpen)
		end)

		menuOverlay.MouseButton1Click:Connect(function()
			setMenuOpen(false)
		end)
		closeButton.MouseButton1Click:Connect(function()
			setMenuOpen(false)
		end)

		-- Small press animation, common in "brainrot" style game UIs
		local function bounce(target: TextButton)
			target.MouseButton1Down:Connect(function()
				TweenService:Create(target, TweenInfo.new(0.08), { Size = target.Size - UDim2.fromOffset(4, 4) }):Play()
			end)
			target.MouseButton1Up:Connect(function()
				TweenService:Create(target, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = target.Size + UDim2.fromOffset(4, 4) }):Play()
			end)
		end
		bounce(plusButton)
		bounce(rebirthRow)
		bounce(gamepassRow)

		-- Pop-in entrance animation for the whole HUD
		pill.Size = UDim2.fromOffset(0, 44)
		rebirthBadge.Size = UDim2.fromOffset(0, 32)
		TweenService:Create(pill, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(150, 44) }):Play()
		TweenService:Create(rebirthBadge, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(120, 32) }):Play()

		-- Cash pop animation whenever cash increases
		local lastCash = leaderstats.Cash.Value
		local function updateDisplay()
			local cash = getCashRemote:InvokeServer()
			local rebirths = getRebirthsRemote:InvokeServer()

			cashText.Text = tostring(cash)
			rebirthText.Text = "✦ " .. tostring(rebirths) .. " Rebirths"
			rebirthRowLabel.Text = "✦ REBIRTH — Cost $" .. tostring(REBIRTH_COST)

			if cash > lastCash then
				TweenService:Create(cashIcon, TweenInfo.new(0.1), { Size = UDim2.fromOffset(42, 42) }):Play()
				task.delay(0.1, function()
					TweenService:Create(cashIcon, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(36, 36) }):Play()
				end)
			end
			lastCash = cash

			local canRebirth = cash >= REBIRTH_COST
			rebirthRow.BackgroundTransparency = canRebirth and 0 or 0.55
			rebirthRowLabel.TextTransparency = canRebirth and 0 or 0.4
		end

		leaderstats.Cash:GetPropertyChangedSignal("Value"):Connect(updateDisplay)
		leaderstats.Rebirths:GetPropertyChangedSignal("Value"):Connect(updateDisplay)

		local isRebirthProcessing = false
		rebirthRow.MouseButton1Click:Connect(function()
			if isRebirthProcessing then return end
			local cash = getCashRemote:InvokeServer()
			if cash < REBIRTH_COST then return end
			isRebirthProcessing = true
			rebirthRemote:InvokeServer()
			setMenuOpen(false)
			task.wait(0.3)
			isRebirthProcessing = false
		end)

		gamepassRow.MouseButton1Click:Connect(function()
			-- Hook up MarketplaceService:PromptGamePassPurchase here once gamepass IDs exist
			print("[GameUI] Gamepass row clicked - wire up gamepass id here")
		end)

		updateDisplay()
	end
end