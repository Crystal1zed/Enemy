local enemyClass = {}
enemyClass.__index = enemyClass

local updateTick = .01

--Modules--
local weaponModule = require(game.ReplicatedStorage.Modules.WeaponModule)
local combatService = require(game.ServerStorage.Modules.CombatService)
local walkspeedhandler = require(game.ServerScriptService.Handler.WalkspeedHandler)
local hitboxmodule = require(game.ServerStorage.Modules.TomatoHitbox)
local hitservice = require(game.ServerStorage.Modules.HitService)
local soundService = require(game.ReplicatedStorage.Modules.SoundService)
local ragdollModule = require(game.ServerStorage.Modules.Ragdoll.ModuleScript)

--ClothingFolder--
local clothingFolder = game.ServerStorage.Assets.Clothing

--Vfx--
local vfxhandler = game.ReplicatedStorage.Events.VFX

--Tables--
local grippingMap = {}

local targetEngagementMap = {}
local ENGAGEMENT_TIMEOUT = 3
local STANDBACK_DISTANCE = 15

local clothingColors = {
	["Earth"] = {
		["Shirt"] = {
			["Primary"] = {
				Color3.fromRGB(37, 68, 32),
				Color3.fromRGB(37, 48, 24),
				Color3.fromRGB(52, 90, 42)
			},
			["Secondary"] = {
				Color3.fromRGB(125, 129, 40),
				Color3.fromRGB(191, 195, 60),
				Color3.fromRGB(112, 121, 55),
			}
		},
		["Pants"] = {
			["Primary"] = {
				Color3.fromRGB(50, 54, 43)
			},
			["Secondary"] = {
				Color3.fromRGB(50, 54, 43),
				Color3.fromRGB(72, 77, 61),
				Color3.fromRGB(54, 53, 39)
			}
		}
	},
	["Water"] = {
		["Shirt"] = {
			["Primary"] = {
				Color3.fromRGB(80, 118, 255),
				Color3.fromRGB(37, 47, 138),
			},
			["Secondary"] = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(190, 190, 190),
				Color3.fromRGB(193, 185, 213),
				Color3.fromRGB(50, 41, 35),
			}
		},
		["Pants"] = {
			["Primary"] = {
				Color3.fromRGB(22, 33, 70),
				Color3.fromRGB(28, 42, 88),
			},
			["Secondary"] = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(50, 41, 35),
			}
		}
	},
	["Wind"] = {
		["Shirt"] = {
			["Primary"] = {
				Color3.fromRGB(57, 0, 1),
				Color3.fromRGB(124, 93, 52),
				Color3.fromRGB(139, 93, 29),
				Color3.fromRGB(106, 84, 33),
			},
			["Secondary"] = {
				Color3.fromRGB(113, 82, 51),
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(57, 0, 1),
			}
		},
		["Pants"] = {
			["Primary"] = {Color3.fromRGB(57, 0, 1)},
			["Secondary"] = {Color3.fromRGB(57, 0, 1)}
		}
	},
	["Fire"] = {
		["Shirt"] = {
			["Primary"] = {
				Color3.fromRGB(57, 0, 1),
				Color3.fromRGB(38, 0, 1),
				Color3.fromRGB(86, 0, 3),
			},
			["Secondary"] = {
				Color3.fromRGB(57, 0, 1),
				Color3.fromRGB(38, 0, 1),
				Color3.fromRGB(86, 0, 3),
			}
		},
		["Pants"] = {
			["Primary"] = {
				Color3.fromRGB(57, 0, 1),
				Color3.fromRGB(38, 0, 1),
				Color3.fromRGB(86, 0, 3),
			},
			["Secondary"] = {
				Color3.fromRGB(57, 0, 1),
				Color3.fromRGB(38, 0, 1),
				Color3.fromRGB(86, 0, 3),
			}
		}
	},
	["Misc"] = {
		["Shirt"] = {
			["Primary"] = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(0, 0, 0),
				Color3.fromRGB(81, 72, 67)
			},
			["Secondary"] = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(0, 0, 0),
				Color3.fromRGB(81, 72, 67)
			}
		},
		["Pants"] = {
			["Primary"] = {
				Color3.fromRGB(70, 56, 48)
			},
			["Secondary"] = {
				Color3.fromRGB(70, 56, 48)
			}
		}
	},
}

local EyeColors = {
	Color3.fromRGB(57, 120, 255),
	Color3.fromRGB(55, 145, 42),
	Color3.fromRGB(25, 21, 20),
	Color3.fromRGB(47, 42, 37),
	Color3.fromRGB(83, 160, 255),
	Color3.fromRGB(108, 108, 108),
	Color3.fromRGB(120, 95, 30),
	
}

local SkinColors = {
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(124, 92, 70),
	Color3.fromRGB(86, 66, 54),
	Color3.fromRGB(204, 142, 105),
}

local HairColors = {
	Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(50, 41, 35),
	Color3.fromRGB(47, 37, 29),
	Color3.fromRGB(208, 195, 124),
	Color3.fromRGB(112, 102, 76),
}

local function decimalRandom(minimum, maximum)
	return math.random() * (maximum - minimum) + minimum
end

function enemyClass.new(args)
	local self = setmetatable({}, enemyClass)

	self.Model = args.Model:Clone()
	self.Rank = args.Rank or 1
	self.Root = self.Model.HumanoidRootPart
	self.Humanoid = self.Model.Humanoid

	self.Humanoid.AutoRotate = false
	
	self.Model:SetAttribute("EnemyNpc", true)

	self.Humanoid.MaxHealth = self.Humanoid.MaxHealth * args.Rank
	self.Humanoid.Health = self.Humanoid.Health * args.Rank

	self.Vision = args.Vision or 100
	self.Area = args.Area or 10

	self.DEBUG = false

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RaycastParams.RespectCanCollide = true
	self.RaycastParams.FilterDescendantsInstances = {self.Model}

	self.MaxStepHeight = self.Humanoid.JumpHeight + 4
	self.StepDistance = 3
	self.LastStepCheck = 0
	self.StepCheckWait = 6

	self.pathParams = {
		WaypointSpacing = 1,
		AgentRadius = 1,
		AgentCanJump = true
	}

	--Create BodyGyro for smooth rotation
	self.BodyGyro = Instance.new("BodyGyro")
	self.BodyGyro.MaxTorque = Vector3.new(0, 400000, 0)
	self.BodyGyro.P = 10000
	self.BodyGyro.D = 500
	self.BodyGyro.Parent = self.Root
	
	self.RandomizeClothes = args.RandomizeClothes or true
	
	self.last_grip = 0
	self.gripCooldown = 6
	self.gripRange = 5

	self.Name = args.Name or self.Name
	self.Village = args.Village or "Fire"
	
	local nameGui = game.ReplicatedStorage.HeadNameGui:Clone()
	nameGui.Parent = self.Model.Head
	nameGui.TextLabel.Text = self.Name
	nameGui.ImageLabel.Image = game.ReplicatedStorage.Logos[self.Village].Texture


	self.CurrentWeapon = args.CurrentWeapon or "Classic Sword"
	self.WeaponEquipped = false
	self.IsTransitioning = false
	
	self.currentTarget = nil
	self.isEngaging = false

	--Get weapon data
	local weaponModuleExists = game.ReplicatedStorage:FindFirstChild("WeaponModules") and game.ReplicatedStorage.WeaponModules:FindFirstChild(self.CurrentWeapon)
	if weaponModuleExists then
		self.WeaponData = require(game.ReplicatedStorage.WeaponModules[self.CurrentWeapon])
	else
		warn("Weapon module not found for:", self.CurrentWeapon)
		self.WeaponData = {Hitbox = Vector3.new(10, 10, 10), damage = 10, heavydamage = 20, hitEffect = "Slash"}
	end

	self.Model:SetAttribute("CurrentWeapon", self.CurrentWeapon)
	self.Model:SetAttribute("Equipped", false)
	self.Model:SetAttribute("Block", 0)

	--Holster weapon
	local weapon = game.ReplicatedStorage.Weapons[self.CurrentWeapon]:Clone()
	weapon.Name = self.CurrentWeapon
	weapon.Parent = self.Model
	weaponModule.HolsterWeapon(self.CurrentWeapon, self.Model)

	self.Model.Parent = workspace.Enemies
	local spawnRadius = args.SpawnRadius or 10
	local randomAngle = math.random() * math.pi * 2
	local randomDistance = math.random() * spawnRadius
	local offset = Vector3.new(
		math.cos(randomAngle) * randomDistance,
		0,
		math.sin(randomAngle) * randomDistance
	)

	self.Root.CFrame = args.SpawnCF + offset
	self.Root:SetNetworkOwner(nil)

	--Combat Cooldowns
	self.last_dash = 0
	self.last_run = 0
	self.last_strafe = 0
	self.last_backtrack = 0
	self.last_feint = 0
	self.last_exefire = 0
	self.last_check = 0
	self.lastAttack = 0
	self.last_attack_time = 0
	self.last_m1_time = 0
	self.last_m2_time = 0
	self.last_block_time = 0

	--Movement State
	self.forceMove = false
	self.forceTime = 0
	self.forceSetTime = 0
	
	--Jump detection setup
	self.lastJumpTime = 0
	self.jumpCooldown = 0.5
	self:SetupJumpDetection()

	--Combat State
	self.Model:SetAttribute("Combo", 1)
	self.isAttacking = false
	
	ragdollModule:Setup(self.Model)

	self.MainThread = coroutine.create(function()

		local success, err = xpcall(function()

			self:Logic()

		end, debug.traceback)

		if not success then
			warn(err)
		end
	end)
	
	if self.RandomizeClothes then
		self:RandomizeAppearence()
	end

	return self
end

function enemyClass:Debug(...)
	if not self.DEBUG then
		return
	end

	local src, line = debug.info(2,"sl")

	warn({self, "["..src..":"..line.."]","-",...})
end

function enemyClass:CheckCombo()
	local combo = self.Model:GetAttribute("Combo")
	if not combo then 
		combo = 1
		self.Model:SetAttribute("Combo", 1)
	end

	if self.lastAttack then
		local lastAttackTime = os.clock() - self.lastAttack
		if lastAttackTime <= 1.5 then
			if combo == 5 then
				combo = 1
			else
				combo += 1
			end
		else
			combo = 1
		end
	else
		combo = 1
	end

	self.lastAttack = os.clock()
	self.Model:SetAttribute("Combo", combo)
	return combo
end

local function CleanupEngagementMap()
	local currentTime = tick()
	for target, data in pairs(targetEngagementMap) do
		if currentTime - data.lastUpdate > ENGAGEMENT_TIMEOUT then
			targetEngagementMap[target] = nil
		elseif not target or not target.Parent or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then
			targetEngagementMap[target] = nil
		end
	end
end

local function IsTargetEngaged(target)
	CleanupEngagementMap()
	return targetEngagementMap[target] ~= nil
end

local function ClaimTarget(npc, target)
	CleanupEngagementMap()
	if not targetEngagementMap[target] then
		targetEngagementMap[target] = {npc = npc, lastUpdate = tick()}
		return true
	end
	return targetEngagementMap[target].npc == npc
end

local function UpdateEngagement(npc, target)
	if targetEngagementMap[target] and targetEngagementMap[target].npc == npc then
		targetEngagementMap[target].lastUpdate = tick()
	end
end

local function ReleaseTarget(npc, target)
	if targetEngagementMap[target] and targetEngagementMap[target].npc == npc then
		targetEngagementMap[target] = nil
	end
end

function enemyClass:GripTarget(target)
	if not target then return end
	if self.Model:GetAttribute("Gripping") then return end
	if self:ActionCheck() then return end

	--Grippable conditions
	if target:GetAttribute("Knocked") ~= true then return end
	if target:GetAttribute("BeingGripped") then return end
	if target:GetAttribute("DeadKnocked") then return end

	local hrp = self.Root
	local hum = self.Humanoid
	local ehrp = target:FindFirstChild("HumanoidRootPart")
	local ehum = target:FindFirstChild("Humanoid")

	if not hrp or not hum or not ehrp or not ehum then return end
	if ehum.Health <= 0 then return end

	--Cooldown
	if os.clock() - (self.last_grip or 0) < 6 then return end
	self.last_grip = os.clock()

	--Stop combat
	self.isAttacking = false
	self.Model:SetAttribute("Attacking", false)
	self.Model:SetAttribute("Swing", false)

	self:StopAnims()

	--Set states
	self.Model:SetAttribute("Gripping", true)
	target:SetAttribute("BeingGripped", true)

	--Cancel ragdoll
	target:SetAttribute("IsRagdoll", false)
	target.RagdollTrigger.Value = false
	ehum.PlatformStand = true

	local gripAnim = hum.Animator:LoadAnimation(
		game.ReplicatedStorage.Animations.GripAndCarry.Grip
	)
	local grippedAnim = ehum.Animator:LoadAnimation(
		game.ReplicatedStorage.Animations.GripAndCarry.Gripped
	)

	gripAnim:Play()
	grippedAnim:Play()

	--Position target
	ehrp.Anchored = true
	ehrp.CFrame =
		hrp.CFrame
		* CFrame.new(0, 0.5, -1.5)
		* CFrame.Angles(0, math.rad(180), 0)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "GripWeld"
	weld.Part0 = hrp
	weld.Part1 = ehrp
	weld.Parent = ehrp

	grippingMap[self] = {
		target = target,
		weld = weld,
		gripAnim = gripAnim,
		grippedAnim = grippedAnim,
		connections = {}
	}

	local function doVfx()
		soundService.PlaySound(game.SoundService.Sounds.Hit, ehrp, 2, false)
		vfxhandler:FireAllClients(
			"CombatEffects",
			game.ReplicatedStorage.Effects.Hit,
			ehrp.CFrame,
			0.3
		)
	end

	local hit1 = gripAnim:GetMarkerReachedSignal("Hit1"):Connect(function()
		if not grippingMap[self] then return end
		doVfx()
	end)

	local hit2 = gripAnim:GetMarkerReachedSignal("Hit2"):Connect(function()
		if not grippingMap[self] then return end
		doVfx()
	end)

	local hit3 = gripAnim:GetMarkerReachedSignal("Hit3"):Connect(function()
		if not grippingMap[self] then return end
		doVfx()

		ehum:TakeDamage(100)

		self:StopGrip()
		target:SetAttribute("DeadKnocked", true)
	end)

	table.insert(grippingMap[self].connections, hit1)
	table.insert(grippingMap[self].connections, hit2)
	table.insert(grippingMap[self].connections, hit3)
end

function enemyClass:StopGrip()
	local gripData = grippingMap[self]
	if not gripData then return end

	local target = gripData.target
	local ehrp = target and target:FindFirstChild("HumanoidRootPart")
	local ehum = target and target:FindFirstChild("Humanoid")

	--Stop animations
	if gripData.gripAnim then gripData.gripAnim:Stop() end
	if gripData.grippedAnim then gripData.grippedAnim:Stop() end

	--Disconnect markers
	for _, conn in pairs(gripData.connections) do
		conn:Disconnect()
	end

	--Remove weld
	if gripData.weld then
		gripData.weld:Destroy()
	end

	--Reset target
	if ehrp then ehrp.Anchored = false end
	if target and ehum then
		target:SetAttribute("BeingGripped", false)
		target:SetAttribute("IsRagdoll", true)
		target.RagdollTrigger.Value = true
		ehum.PlatformStand = false
	end

	self.Model:SetAttribute("Gripping", false)
	grippingMap[self] = nil
end


function enemyClass:RandomizeAppearence()
	local shirtFolder, pantsFolder, shoesFolder, outfitFolder
	repeat
		shirtFolder = self.Model.ClothingFolder:FindFirstChild("Shirt")
		pantsFolder = self.Model.ClothingFolder:FindFirstChild("Pants")
		shoesFolder = self.Model.ClothingFolder:FindFirstChild("Shoes")
		outfitFolder = self.Model.ClothingFolder:FindFirstChild("Outfit")
		task.wait(0.1)
		warn("checking for clothes")
	until shirtFolder and pantsFolder and shoesFolder and outfitFolder
	
	local fakehead = game.ReplicatedStorage:WaitForChild("FakeHead"):Clone()
	fakehead.Name = "FakeHead"
	fakehead.Parent = self.Model
	fakehead.Position = self.Model.Head.Position
	fakehead.Color = self.Model.Head.Color
	fakehead.Transparency = 1
	
	local function getRandomEyeColor()
		local tableFound = EyeColors
		return tableFound[math.random(1, #tableFound)]
	end

	local function getRandomSkinColor()
		local tableFound = SkinColors
		return tableFound[math.random(1, #tableFound)]
	end

	local skincolor = getRandomSkinColor()

	for i,v in pairs(self.Model:GetChildren()) do
		if v:IsA("BasePart") then
			if string.find(v.Name, "Leg") or string.find(v.Name, "Arm") or string.find(v.Name, "Torso") or string.find(v.Name, "Head") then
				v.Color = skincolor
			end
		end
	end

	local eyecolor = getRandomEyeColor()

	fakehead["Pupil Left"].Color3 = eyecolor
	fakehead["Pupil Right"].Color3 = eyecolor

	local weld = Instance.new("Weld")
	weld.Parent = fakehead
	weld.Part0 = self.Model.Head
	weld.Part1 = fakehead
	
	local function getClothingByRank(rank)
		if rank < 10 then
			return nil -- no clothing
		elseif rank < 20 then
			return "Village Clothing" -- 10–19
		elseif rank < 30 then
			return "Army Outfit" -- 20–29
		else
			return "Royal Outfit" -- 30+
		end
	end
	
	if self.Rank >= 10 then
		warn("got higher rank")
		local VillageOutfits = clothingFolder.Outfits[self.Village]
		if not VillageOutfits then return end
		local SelectedClothing = VillageOutfits[self.Village.." "..getClothingByRank(self.Rank)]:Clone()
		SelectedClothing.Parent = outfitFolder
		
		for i, v in pairs(SelectedClothing.Welds:GetChildren()) do
			if string.find(v.Name, "Left Arm") then
				v.Part0 = self.Model["Left Arm"]
			elseif string.find(v.Name, "Right Arm") then
				v.Part0 = self.Model["Right Arm"]
			elseif string.find(v.Name, "Torso") then
				v.Part0 = self.Model.Torso
			elseif string.find(v.Name, "Left Leg") then
				v.Part0 = self.Model["Left Leg"]
			elseif string.find(v.Name, "Right Leg") then
				v.Part0 = self.Model["Right Leg"]
			end
		end
		
		local villPalette = clothingColors[self.Village]
		if not villPalette then return end
		
		local function getRandomColor(primaryOrSecondary, clothing)
			local tableFound = villPalette[clothing] and villPalette[clothing][primaryOrSecondary]
			if not tableFound or #tableFound == 0 then
				warn("Missing color table:", self.Village, clothing, primaryOrSecondary)
				return Color3.fromRGB(255, 0, 255)
			end

			return tableFound[math.random(1, #tableFound)]
		end
		
		local prim = getRandomColor("Primary", "Shirt")
		local sec = getRandomColor("Secondary", "Shirt")
		
		for i,v in pairs(SelectedClothing:GetChildren()) do
			if v:IsA("BasePart") or v:IsA("MeshPart") then
				if v:GetAttribute("Primary") then
					v.Color = prim
				else
					--v.Color = sec
				end
			end
		end
		
	else
		warn("got lower")
		local maxShirts = #clothingFolder.Shirt:GetChildren()
		local maxPants = #clothingFolder.Pants:GetChildren()

		local randomShirt = clothingFolder.Shirt:FindFirstChild("Shirt"..math.random(1,maxShirts)):Clone()
		local randomPants = clothingFolder.Pants:FindFirstChild("Pants"..math.random(1,maxPants)):Clone()

		randomShirt.Parent = shirtFolder
		randomPants.Parent = pantsFolder


		for i, v in pairs(randomShirt.Welds:GetChildren()) do
			if string.find(v.Name, "Left Arm") then
				v.Part0 = self.Model["Left Arm"]
			elseif string.find(v.Name, "Right Arm") then
				v.Part0 = self.Model["Right Arm"]
			elseif string.find(v.Name, "Torso") then
				v.Part0 = self.Model.Torso
			end
		end

		for i,v in pairs(randomPants.Welds:GetChildren()) do
			if string.find(v.Name, "Left Leg") then
				v.Part0 = self.Model["Left Leg"]
			elseif string.find(v.Name, "Right Leg") then
				v.Part0 = self.Model["Right Leg"]
			elseif string.find(v.Name, "Torso") then
				v.Part0 = self.Model.Torso
			end
		end

		local villagePalette = clothingColors[self.Village]
		if not villagePalette then return end

		local function getRandomColor(primaryOrSecondary, clothing)
			local tableFound = villagePalette[clothing] and villagePalette[clothing][primaryOrSecondary]
			if not tableFound or #tableFound == 0 then
				warn("Missing color table:", self.Village, clothing, primaryOrSecondary)
				return Color3.fromRGB(255, 0, 255)
			end

			return tableFound[math.random(1, #tableFound)]
		end


		local Shirt_primaryColor = getRandomColor("Primary", "Shirt")
		local Shirt_secondaryColor = getRandomColor("Secondary", "Shirt")
		local Pants_primaryColor = getRandomColor("Primary", "Pants")
		local Pants_secondaryColor = getRandomColor("Secondary", "Pants")

		for _, part in ipairs(randomShirt:GetChildren()) do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				if part:GetAttribute("Primary") then
					part.Color = Shirt_primaryColor
				else
					part.Color = Shirt_secondaryColor
				end
			end
		end

		for _, part in ipairs(randomPants:GetChildren()) do
			if part:IsA("BasePart") then
				if part:GetAttribute("Primary") then
					part.Color = Pants_primaryColor
				else
					part.Color = Pants_secondaryColor
				end
			end
		end
	end

	task.spawn(function()
		while self.Model and self.Model.Parent do
			wait(math.random(20, 50) / 10)

			if fakehead:FindFirstChild("Left Eyeshine") then
				fakehead["Left Eyeshine"].Transparency = 1
			end
			if fakehead:FindFirstChild("Right Eyeshine") then
				fakehead["Right Eyeshine"].Transparency = 1
			end
			if fakehead:FindFirstChild("Left Closed") then
				fakehead["Left Closed"].Transparency = 0
			end
			if fakehead:FindFirstChild("Right Closed") then
				fakehead["Right Closed"].Transparency = 0
			end
			if fakehead:FindFirstChild("Pupil Left") then
				fakehead["Pupil Left"].Transparency = 1
			end
			if fakehead:FindFirstChild("Pupil Right") then
				fakehead["Pupil Right"].Transparency = 1
			end
			if fakehead:FindFirstChild("Sclera Left") then
				fakehead["Sclera Left"].Transparency = 1
			end
			if fakehead:FindFirstChild("Sclera Right") then
				fakehead["Sclera Right"].Transparency = 1
			end
			if fakehead:FindFirstChild("Socket Left") then
				fakehead["Socket Left"].Transparency = 1
			end
			if fakehead:FindFirstChild("Socket Right") then
				fakehead["Socket Right"].Transparency = 1
			end

			wait(0.15)

			if fakehead:FindFirstChild("Left Eyeshine") then
				fakehead["Left Eyeshine"].Transparency = 0
			end
			if fakehead:FindFirstChild("Right Eyeshine") then
				fakehead["Right Eyeshine"].Transparency = 0
			end
			if fakehead:FindFirstChild("Left Closed") then
				fakehead["Left Closed"].Transparency = 1
			end
			if fakehead:FindFirstChild("Right Closed") then
				fakehead["Right Closed"].Transparency = 1
			end
			if fakehead:FindFirstChild("Pupil Left") then
				fakehead["Pupil Left"].Transparency = 0
			end
			if fakehead:FindFirstChild("Pupil Right") then
				fakehead["Pupil Right"].Transparency = 0
			end
			if fakehead:FindFirstChild("Sclera Left") then
				fakehead["Sclera Left"].Transparency = 0
			end
			if fakehead:FindFirstChild("Sclera Right") then
				fakehead["Sclera Right"].Transparency = 0
			end
			if fakehead:FindFirstChild("Socket Left") then
				fakehead["Socket Left"].Transparency = 0
			end
			if fakehead:FindFirstChild("Socket Right") then
				fakehead["Socket Right"].Transparency = 0
			end
		end
	end)
end

function enemyClass:SetupJumpDetection()
	local torso = self.Model:FindFirstChild("Torso")
	if not torso then 
		warn("No torso found for jump detection")
		return 
	end

	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then 
		warn("No Map folder found in workspace")
		return 
	end

	torso.Touched:Connect(function(hit)

		--Check if touched part is from Map
		if not hit:IsDescendantOf(mapFolder) then 
			return 
		end

		--Check cooldown
		if os.clock() - self.lastJumpTime < self.jumpCooldown then 
			return 
		end

		--Jump immediately when torso touches map object
		self.Humanoid.Jump = true
		self.lastJumpTime = os.clock()
	end)
end

function enemyClass:GetSwingAnimation()
	local combo = self.Model:GetAttribute("Combo")
	local animationTrack = game.ReplicatedStorage.Animations[self.CurrentWeapon].Combo[combo]
	return animationTrack
end

function enemyClass:StopAnims()
	for i, v in pairs(self.Humanoid.Animator:GetPlayingAnimationTracks()) do
		if v.Name ~= "Idle" and v.Name ~= "WalkAnim" then
			v:Stop()
		end
	end
end

function enemyClass:UpdateFunction()
	if self.forceTime ~= nil and (tick() - self.forceTime) >= (self.forceSetTime or 1) then
		self.forceMove = false
	end
end

function enemyClass:PerformAttack(target, Location)
	if self.isAttacking then return end
	if self.Model:GetAttribute("Stunned") then return end

	local combo = self.Model:GetAttribute("Combo") or 1
	local m1Cooldown = combo <= 4 and self.WeaponData.m1cd or self.WeaponData.lasthitcd

	if os.clock() - self.last_m1_time < m1Cooldown then return end

	self.isAttacking = true
	self.last_m1_time = os.clock()

	self:CheckCombo()
	combo = self.Model:GetAttribute("Combo")

	weaponModule.StopAnimation(self.Humanoid, tostring(combo - 1))

	local animationTrack = self.Humanoid.Animator:LoadAnimation(self:GetSwingAnimation())
	soundService.PlaySound(game.SoundService.Sounds.Swing, self.Root, 2, false)
	animationTrack:Play()

	self.Model:SetAttribute("Attacking", true)
	self.Model:SetAttribute("Swing", true)

	task.spawn(function()
		task.wait(0.35)
		self.Model:SetAttribute("Swing", false)
	end)
	
	local newHitbox = hitboxmodule.new()
	newHitbox.Size = self.WeaponData.Hitbox
	newHitbox.CFrame = self.Root
	newHitbox.Offset = Vector3.new(0, 0, 10)
	newHitbox.Visualizer = false

	local hitLanded = false
	
	UpdateEngagement(self, target)

	animationTrack:GetMarkerReachedSignal("Hit"):Connect(function()
		newHitbox.onTouch = function(ehum)
			if ehum ~= self.Humanoid and not hitLanded then
				local echar = ehum.Parent
				if not echar then return end

				if echar:GetAttribute("NPC") then return end
				if echar:GetAttribute("EnemyNpc") then return end

				print("NPC Hitbox touched")

				if echar:GetAttribute("Parrying") and combatService.CheckInFront(echar, self.Model) then
					hitLanded = true
					combatService.Parry(self.Model, echar)

					self:StopAnims()
					self.Model:SetAttribute("Attacking", false)
					self.Model:SetAttribute("Swing", false)
					self.isAttacking = false
					return
				end

				if echar:GetAttribute("Blocking") and combatService.CheckInFront(echar, self.Model) then
					hitLanded = true
					combatService.Block(echar, self.WeaponData.damage)
					return
				end

				if echar:GetAttribute("IsRagdoll") then
					vfxhandler:FireAllClients("Highlight", echar, .3, Color3.fromRGB(112, 109, 110), Color3.fromRGB(62, 62, 62))
					return
				end

				local ehrp = echar:FindFirstChild("HumanoidRootPart")
				if not ehrp then return end

				hitLanded = true

				local center = (ehrp.Position - self.Root.Position).Unit
				local strength = 10
				local ragdoll = false

				if combo == 5 then
					ragdoll = true
					strength = 35
				end

				local kb = center * strength
				hitservice.Hit(ehum, self.WeaponData.damage, 0.25, kb, ragdoll, 1.25)
				
				local hitanim = ehum:LoadAnimation(game.ReplicatedStorage.Animations[self.CurrentWeapon].Hit[combo])
				hitanim:Play()

				echar:SetAttribute("CanAttack", false)
				task.delay(0.5, function()
					if echar and echar.Parent and ehum.Health > 0 then
						echar:SetAttribute("CanAttack", true)
					end
				end)

				vfxhandler:FireAllClients("CombatEffects", game.ReplicatedStorage.Effects[self.WeaponData.hitEffect], ehrp.CFrame, .3)
				if self.WeaponData.hitEffect == "Slash" then
					vfxhandler:FireAllClients("CombatEffects", game.ReplicatedStorage.Effects.Blood, ehrp.CFrame, .3)
				end
				vfxhandler:FireAllClients("Highlight", echar, .3, Color3.fromRGB(112, 0, 2), Color3.fromRGB(75, 0, 0))
				soundService.PlaySound(game.SoundService.Sounds[self.WeaponData.hitEffect], ehrp, 2, false)
			end
		end

		newHitbox:Start()

		task.delay(0.15, function()
			newHitbox:Stop()
			newHitbox:Destroy()
		end)
	end)

	task.delay(0.8, function()
		self.Model:SetAttribute("Attacking", false)
		self.isAttacking = false
	end)

	self.Humanoid:MoveTo(Location)
end

function enemyClass:PerformHeavy(target, Location)
	if self.isAttacking then return end
	if self.Model:GetAttribute("Stunned") then return end

	if os.clock() - self.last_m2_time < 4 then return end

	self.isAttacking = true
	self.last_m2_time = os.clock()

	local animFolder = game.ReplicatedStorage.Animations:FindFirstChild(self.CurrentWeapon)
	if animFolder and animFolder:FindFirstChild("Heavy") then
		vfxhandler:FireAllClients("Highlight", self.Model, 1, Color3.fromRGB(112, 0, 2), Color3.fromRGB(75, 0, 0))

		local heavyVfx = game.ReplicatedStorage.Effects.HeavyStart
		local pos = self.Root.CFrame * CFrame.new(0, 5, 0)
		vfxhandler:FireAllClients("CombatEffects", heavyVfx, pos, 1)
		soundService.PlaySound(game.SoundService.Sounds.Kanji, self.Root, 2, false)

		local heavyAnim = self.Humanoid:LoadAnimation(animFolder.Heavy)
		heavyAnim:AdjustSpeed(0.0005)
		heavyAnim:Play()

		task.spawn(function()
			task.wait(.3)
			soundService.PlaySound(game.SoundService.Sounds.Swing, self.Root, 2, false)
		end)

		task.spawn(function()
			task.wait(1)
			heavyAnim:AdjustSpeed(0.6)
		end)

		self.Model:SetAttribute("Attacking", true)
		self.Model:SetAttribute("Swing", true)

		task.spawn(function()
			task.wait(1)
			self.Model:SetAttribute("Swing", false)
		end)

		local hitCount = 0
		local maxHits = 4
		local hitTargets = {}
		
		UpdateEngagement(self, target)
		
		heavyAnim:GetMarkerReachedSignal("Hit"):Connect(function()
			hitCount += 1

			local HeavyHitbox = hitboxmodule.new()
			HeavyHitbox.Size = self.WeaponData.Hitbox
			HeavyHitbox.CFrame = self.Root
			HeavyHitbox.Offset = Vector3.new(0, 0, 10)
			HeavyHitbox.Visualizer = false

			HeavyHitbox.onTouch = function(ehum)
				if ehum ~= self.Humanoid then
					local echar = ehum.Parent
					if not echar then return end

					if echar:GetAttribute("NPC") then return end
					
					if hitTargets[echar] and tick() - hitTargets[echar] < 0.1 then
						return
					end
					hitTargets[echar] = tick()

					print("NPC Heavy Hitbox touched - Hit #" .. hitCount)

					if echar:GetAttribute("Parrying") and combatService.CheckInFront(self.Model, echar) then
						combatService.Parry(self.Model, echar)
						return
					end

					if echar:GetAttribute("Blocking") and combatService.CheckInFront(self.Model, echar) then
						combatService.Block(echar, self.WeaponData.heavydamage * 1.5)
						return
					end

					if echar:GetAttribute("IsRagdoll") then
						vfxhandler:FireAllClients("Highlight", echar, .3, Color3.fromRGB(112, 109, 110), Color3.fromRGB(62, 62, 62))
						return
					end

					local ehrp = echar:FindFirstChild("HumanoidRootPart")
					if not ehrp then return end

					local center = (ehrp.Position - self.Root.Position).Unit
					local strength = 5
					local damage = self.WeaponData.heavydamage
					local ragdoll = false

					if hitCount == maxHits then
						strength = 35
						damage = self.WeaponData.heavydamage * 1.5
						ragdoll = true
					end

					local kb = center * strength
					hitservice.Hit(ehum, damage, 0.305, kb, ragdoll, 0.2)

					local hitanim = ehum:LoadAnimation(game.ReplicatedStorage.Animations[self.CurrentWeapon].Hit[math.min(hitCount, 5)])
					hitanim:Play()

					echar:SetAttribute("CanAttack", false)
					task.delay(0.5, function()
						if echar and echar.Parent and ehum.Health > 0 then
							echar:SetAttribute("CanAttack", true)
						end
					end)

					vfxhandler:FireAllClients("CombatEffects", game.ReplicatedStorage.Effects[self.WeaponData.hitEffect], ehrp.CFrame, .3)
					if self.WeaponData.hitEffect == "Slash" then
						vfxhandler:FireAllClients("CombatEffects", game.ReplicatedStorage.Effects.Blood, ehrp.CFrame, .3)
					end
					vfxhandler:FireAllClients("Highlight", echar, .3, Color3.fromRGB(112, 0, 2), Color3.fromRGB(75, 0, 0))
					soundService.PlaySound(game.SoundService.Sounds[self.WeaponData.hitEffect], ehrp, 2, false)
				end
			end

			HeavyHitbox:Start()

			task.delay(0.15, function()
				HeavyHitbox:Stop()
				HeavyHitbox:Destroy()
			end)

			if hitCount >= maxHits then
				task.delay(0.5, function()
					self.Model:SetAttribute("Attacking", false)
					self.isAttacking = false
				end)
			end
		end)

		heavyAnim.Ended:Connect(function()
			task.wait(0.1)
			if self.Model:GetAttribute("Attacking") then
				self.Model:SetAttribute("Attacking", false)
				self.isAttacking = false
			end
		end)

		self.Humanoid:MoveTo(Location)
	else
		self.isAttacking = false
	end
end

function enemyClass:ActionCheck()
	return self.Model:GetAttribute("Stunned") or 
		self.Model:GetAttribute("Carrying") or 
		self.Model:GetAttribute("Carried") or 
		self.Model:GetAttribute("BeingGripped") or 
		self.Model:GetAttribute("Gripping") or 
		self.Model:GetAttribute("Blocking") or 
		self.Model:GetAttribute("Attacking") or 
		self.Model:GetAttribute("Knocked") or
		self.Model:GetAttribute("IsRagdoll")
end

function enemyClass:Strafe(enemy)
	if enemy and not self:ActionCheck() then
		if self.last_strafe == nil or (os.clock() - self.last_strafe > 1.25) then
			local eroot = enemy:FindFirstChild("HumanoidRootPart")
			local pos = eroot.Position
			local neg = math.random(10, 15)
			local pos2 = math.random(10, 15)
			local distance = math.random(1, 2) == 2 and -neg or pos2

			local strafePos = pos - CFrame.new(self.Root.Position, pos).RightVector * distance

			self.last_strafe = os.clock()
			self.Humanoid:MoveTo(strafePos)
			self.forceMove = true
			self.forceTime = tick()
			self.forceSetTime = 1
		end
	end
end

function enemyClass:Block()
	if self.Model:GetAttribute("Blocking") then return end

	if os.clock() - self.last_block_time < (self.WeaponData.parryCooldown or 0.5) then return end

	self.Model:SetAttribute("Blocking", true)
	self.last_block_time = os.clock()

	local animFolder = game.ReplicatedStorage.Animations:FindFirstChild(self.CurrentWeapon)
	if animFolder and animFolder:FindFirstChild("Block") then
		local blockAnim = self.Humanoid.Animator:LoadAnimation(animFolder.Block)
		blockAnim:Play()
	end

	walkspeedhandler.RemoveBuff(self.Model, 6)

	local parryWindow = 0.25
	self.Model:SetAttribute("Parrying", true)
	task.delay(parryWindow, function()
		self.Model:SetAttribute("Parrying", false)
	end)

	task.spawn(function()
		while self.Model:GetAttribute("Blocking") do
			task.wait(1)
			local currentBlock = self.Model:GetAttribute("Block")
			if currentBlock > 0 then
				self.Model:SetAttribute("Block", math.max(0, currentBlock - 5))
			end
		end
	end)
end

function enemyClass:BlockStop()
	if not self.Model:GetAttribute("Blocking") then return end

	self.Model:SetAttribute("Blocking", false)
	self.Model:SetAttribute("Parrying", false)

	weaponModule.StopAnimation(self.Humanoid, "Block")
	walkspeedhandler.AddBuff(self.Model, 6)
end

function enemyClass:Logic()
	self:Debug("Logic for", self,"began")

	while true do
		local target = self:FindTarget()

		if self.Model:GetAttribute("Gripping") then
			if self.Model:GetAttribute("Stunned") or self.Model:GetAttribute("IsRagdoll") or self.Humanoid.Health <= 0 then
				self:StopGrip()
			end
		end

		if target then
			local canEngage = ClaimTarget(self, target)

			if self.currentTarget ~= target then
				if self.currentTarget then
					ReleaseTarget(self, self.currentTarget)
				end
				self.currentTarget = target
			end

			self:LookAt(target.HumanoidRootPart.Position)

			if not self.WeaponEquipped and not self.IsTransitioning then
				coroutine.wrap(function()
					self:EquipWeapon()
				end)()
			end

			if self.WeaponEquipped then
				local distance = self:DistanceTo(target.HumanoidRootPart.Position)

				if canEngage then
					if distance > self.Area * .55 then
						if not self.forceMove and not self:ActionCheck() then
							self.Humanoid:MoveTo(target.HumanoidRootPart.Position)
						end
					end
					self.isEngaging = true
					UpdateEngagement(self, target)
				else
					self.isEngaging = false
					if distance < STANDBACK_DISTANCE then
						local direction = (self.Root.Position - target.HumanoidRootPart.Position).Unit
						local standbackPos = target.HumanoidRootPart.Position + (direction * STANDBACK_DISTANCE)
						if not self.forceMove and not self:ActionCheck() then
							self.Humanoid:MoveTo(standbackPos)
						end
					else
						self:CircleTarget(target)
					end
				end

				self:UpdateFunction()
			end

		else
			if self.currentTarget then
				ReleaseTarget(self, self.currentTarget)
				self.currentTarget = nil
			end
			self.isEngaging = false

			if self.WeaponEquipped and not self.IsTransitioning then
				coroutine.wrap(function()
					self:UnequipWeapon()
				end)()
			end
		end

		task.wait(updateTick)
	end
end

function enemyClass:CircleTarget(target)
	if not target or not target:FindFirstChild("HumanoidRootPart") then return end

	local targetPos = target.HumanoidRootPart.Position
	local currentPos = self.Root.Position
	local direction = (currentPos - targetPos).Unit

	local angle = math.rad(30)
	local rotatedDirection = Vector3.new(
		direction.X * math.cos(angle) - direction.Z * math.sin(angle),
		0,
		direction.X * math.sin(angle) + direction.Z * math.cos(angle)
	)

	local circlePos = targetPos + (rotatedDirection * STANDBACK_DISTANCE)

	if not self.forceMove and not self:ActionCheck() then
		self.Humanoid:MoveTo(circlePos)
	end
end

function enemyClass:LookAt(position)
	local currentPos = self.Root.Position
	local targetPos = Vector3.new(position.X, currentPos.Y, position.Z)

	local lookVector = (targetPos - currentPos).Unit
	local newCFrame = CFrame.new(currentPos, targetPos)

	self.BodyGyro.CFrame = newCFrame
end

function enemyClass:FindTarget()
	local players = game:GetService("Players"):GetPlayers()
	local inRangeTargets = {}

	for i, plr in ipairs(players) do
		local char = plr.Character
		if not char then continue end
		if self:IsTargetAlive(char) == false then continue end

		local distToTarget = self:DistanceTo(char.HumanoidRootPart.Position)
		if distToTarget <= self.Vision then

			table.insert(inRangeTargets, {char = char, dist = distToTarget})

		end
	end

	if #inRangeTargets == 0 then
		return
	end

	table.sort(inRangeTargets, function(a,b)
		return a.dist < b.dist
	end)

	for i, targetData in pairs(inRangeTargets) do
		if self:CanSee(targetData.char) then

			if self:DistanceTo(targetData.char.HumanoidRootPart.Position) < self.Area * .55 then
				if self.isEngaging and not self.isAttacking and not self.Model:GetAttribute("Stunned") then
					self:Attack(targetData.char)
				end
			end

			return targetData.char
		end
	end
end

function enemyClass:IsTargetAlive(target)
	local result = (target and 
		target:FindFirstChild("HumanoidRootPart") and 
		target:FindFirstChild("Humanoid") and 
		target.Humanoid.Health > 0 and 
		--not target:GetAttribute("Knocked") and 
		not target:GetAttribute("DeadKnocked") and
		not target:GetAttribute("BeingGripped"))

	return result
end

function enemyClass:DistanceTo(pos)
	return(self.Root.Position - pos).Magnitude
end

function enemyClass:CanSee(target)
	local origin = self.Model.Head.Position
	local dir = (target.HumanoidRootPart.Position - origin).Unit * self.Vision
	local raycast = workspace:Raycast(origin, dir, self.RaycastParams)

	if raycast and raycast.Instance.Parent == target then
		return true
	end

	return false
end

function enemyClass:PathfindTo(target, attempts)
	local start = self.Root.Position + self.Humanoid.MoveDirection * 13
	local destination = target.HumanoidRootPart.Position

	local path = game:GetService("PathfindingService"):CreatePath(self.pathParams)
	path:ComputeAsync(start,destination)

	if path.Status ~= Enum.PathStatus.Success then

		attempts = attempts or 0
		attempts += 1

		if attempts > 3 then
			return 
		end

		self:Debug("Path failed", attempts, "times")
		task.wait(.5)


		self:PathfindTo(target, attempts)
		return
	end

	local allWaypoints = path:GetWaypoints()
	local lastWaypoint = allWaypoints[#allWaypoints]

	for i, waypoint in ipairs(allWaypoints) do
		self.Humanoid:MoveTo(waypoint.Position)

		local moved = self.Humanoid.MoveToFinished:Wait()
		if not moved then
			self:Debug("Move to waypoint failed.")
			self:PathfindTo(target)
			return
		end

		local seenTarget = self:FindTarget()
		if not seenTarget then continue end

		self:LookAt(seenTarget.HumanoidRootPart.Position)

		local shouldPathfindTo = self:ShouldPathfind(target)
		local targetDistFromEnd = (target.HumanoidRootPart.Position - lastWaypoint.Position).Magnitude

		if not shouldPathfindTo then
			return self:Chase(seenTarget)

		elseif seenTarget == target and targetDistFromEnd > 12 then

			return self:PathfindTo(target)

		end
	end
end

function enemyClass:ShouldPathfind(target)
	local selfDownDirection = Vector3.new(0, -self.MaxStepHeight, 0)
	local selfPos = self.Root.Position

	local selfRay = workspace:Raycast(selfPos, selfDownDirection, self.RaycastParams)

	local targetParams = RaycastParams.new()
	targetParams.FilterDescendantsInstances = {target}
	targetParams.FilterType = Enum.RaycastFilterType.Exclude
	targetParams.RespectCanCollide = true

	local targetMaxDrop = 11
	local targetDownDirection = Vector3.new(0,-targetMaxDrop,0)
	local targetPos = target.HumanoidRootPart.Position

	local targetRay = workspace:Raycast(targetPos, targetDownDirection, targetParams)

	if not targetRay or not selfRay then
		self:Debug("Raycasts failed, path needed")
		return true
	end

	local heightDifference = math.abs(targetRay.Position.Y - selfRay.Position.Y)
	if heightDifference > self.Humanoid.JumpHeight then
		self:Debug("Height difference too different, path needed")
		return true
	end

	local lastStepRaycast = (tick() - self.LastStepCheck)
	if lastStepRaycast < self.StepCheckWait then
		self:Debug("Raycasting step too fast, path needed")
		return true
	end

	local stepOrigin = selfPos + CFrame.lookAt(selfPos, targetPos).LookVector * self.StepDistance
	local stepRay = workspace:Raycast(stepOrigin, selfDownDirection, self.RaycastParams)

	if not stepRay then

		self.Humanoid:MoveTo(self.Root.Position)

		self:Debug("Step raycast failed, path needed")
		self.LastStepCheck = tick()

		return true
	end
end

function enemyClass:Chase(target)
	while task.wait(updateTick) do
		if not self:IsTargetAlive(target) then return end

		local seenTarget = self:FindTarget()
		if not seenTarget then

			return self:PathfindTo(target)

		elseif seenTarget ~= target then

			if not self:ShouldPathfind(seenTarget) then
				self:Debug("Chasing easier target")
				return self:Chase(seenTarget)
			end

		elseif self:ShouldPathfind(target) then
			self:Debug("Switching to pathfinding.")

			return self:PathfindTo(target)
		end

		self:LookAt(target.HumanoidRootPart.Position)

		if not self.forceMove then
			self.Humanoid:MoveTo(target.HumanoidRootPart.Position)
		end

		self:UpdateFunction()
	end
end

function enemyClass:EquipWeapon()
	if self.WeaponEquipped or self.IsTransitioning then return end
	self.IsTransitioning = true
	local animFolder = game.ReplicatedStorage.Animations:FindFirstChild(self.CurrentWeapon)

	if animFolder and animFolder:FindFirstChild("Equip") then
		local equipAnim = self.Humanoid:LoadAnimation(animFolder.Equip)
		equipAnim:Play()
		wait(0.6)
	end

	if animFolder and animFolder:FindFirstChild("Idle") then
		self.Humanoid:LoadAnimation(animFolder.Idle):Play()
	end

	weaponModule.EquipWeapon(self.CurrentWeapon, self.Model)

	self.Model:SetAttribute("Equipped", true)

	self.WeaponEquipped = true
	self.IsTransitioning = false
	self:Debug(self.Name, "equipped weapon:", self.CurrentWeapon)
end

function enemyClass:UnequipWeapon()
	if not self.WeaponEquipped or self.IsTransitioning then return end
	self.IsTransitioning = true

	local animFolder = game.ReplicatedStorage.Animations:FindFirstChild(self.CurrentWeapon)
	if animFolder and animFolder:FindFirstChild("Unequip") then
		local unequipAnim = self.Humanoid:LoadAnimation(animFolder.Unequip)
		unequipAnim:Play()
		wait(0.6)
	end

	weaponModule.StopAnimation(self.Humanoid, "Idle")

	weaponModule.UnequipWeapon(self.CurrentWeapon, self.Model)
	weaponModule.HolsterWeapon(self.CurrentWeapon, self.Model)

	self.Model:SetAttribute("Equipped", false)

	self.WeaponEquipped = false
	self.IsTransitioning = false
	self:Debug(self.Name, "unequipped weapon:", self.CurrentWeapon)
end

function enemyClass:Attack(target)
	
	if self.isAttacking then return end
	if self.Model:GetAttribute("Attacking") then return end
	if self.Model:GetAttribute("Stunned") then return end
	if self.Model:GetAttribute("Knocked") then return end
	if self.Model:GetAttribute("DeadKnocked") then return end
	
	if target:GetAttribute("Knocked") then
		self:GripTarget(target)
		return
	end
	
	if os.clock() - self.last_attack_time < 0.5 then return end

	self.last_attack_time = os.clock()

	local Magnitude = self:DistanceTo(target.HumanoidRootPart.Position)
	local Direction = (target.PrimaryPart.Position - self.Model.PrimaryPart.Position).Unit
	local Location = (target.PrimaryPart.CFrame + Direction * (self.Area * 0.5)).Position

	local isAttacking = target:GetAttribute("Attacking")
	local isStunned = target:GetAttribute("Stunned")
	local isParrying = target:GetAttribute("Parrying")
	local isBlocking = target:GetAttribute("Blocking")

	self:UpdateFunction()

	if isStunned or isParrying then

		if math.random(1, 5) == 1 then
			self:PerformHeavy(target, Location)
			if isStunned then
				task.wait(0.3)
				self:PerformAttack(target, Location)
			end
			return
		end

		self:PerformAttack(target, Location)

		if math.random(1, 3) == 1 and self.Model:GetAttribute("Attacking") and 
			(self.last_feint == nil or os.clock() - self.last_feint >= 1.5) and isStunned then

			--Feint logic
			self.last_feint = os.clock()
			task.wait()
			return self:PerformAttack(target, Location)
		else
			return
		end
	end

	--If enemy is blocking then heavy
	if isBlocking and math.random(1, 3) == 2 and not self:ActionCheck() then
		self:PerformHeavy(target, Location)
		if isStunned then
			task.wait(0.3)
			self:PerformAttack(target, Location)
		end
		return
	end

	--If enemy is attacking go defensive
	if isAttacking and not self.Model:GetAttribute("Attacking") then
		local onlyBlock = false

		if math.random(1, 5) == 2 and (self.last_strafe == nil or (os.clock() - self.last_strafe > 1.25)) then
			--Strafe
			self:Strafe(target)
			task.wait(0.20)

		elseif math.random(1, 3) == 1 and (self.last_backtrack == nil or (os.clock() - self.last_backtrack > 1.25)) then
			self.last_backtrack = os.clock()
			onlyBlock = true

			self.forceMove = true
			self.forceTime = tick()
			self.forceSetTime = 0.5

			self.Humanoid:MoveTo((target.PrimaryPart.CFrame + Direction * 5).Position)
		end

		self:Block()

		if target:GetAttribute("Parrying") or target:GetAttribute("Stunned") then
			self:BlockStop()
			task.wait()
			self:PerformAttack(target, Location)
		else
			local randd = math.random(150, 250) / 100

			task.delay(randd, function()
				self:BlockStop()
			end)
		end
		return
	end
	
	if self.Model:GetAttribute("Parrying") or self.Model:GetAttribute("Stunned") then
		local onlyBlock = false
		self:Block()

		if isStunned or isParrying then
			self:BlockStop()
			task.wait()
			self:PerformAttack(target, Location)
		else
			local randd = math.random(80, 200) / 100
			if not onlyBlock then
				self.Humanoid:MoveTo(target.HumanoidRootPart.Position - CFrame.new(self.Root.Position, target.HumanoidRootPart.Position).LookVector * 5)
				self.forceMove = true
				self.forceTime = tick()
				self.forceSetTime = randd + 0.1
			end

			task.delay(randd, function()
				self:BlockStop()
			end)
		end
		return
	end

	--Normal attack
	self:PerformAttack(target, Location)

	--Heavy attack
	if math.random(1, 5) == 1 then
		task.wait(0.2)
		self:PerformHeavy(target, Location)
		if isStunned then
			task.wait(0.3)
			self:PerformAttack(target, Location)
		end
		return
	end

	--Random feint
	if math.random(1, 3) == 1 and self.Model:GetAttribute("Attacking") and 
		(self.last_feint == nil or os.clock() - self.last_feint >= 2) and isStunned then

		self.last_feint = os.clock()
		task.wait()
		return self:PerformAttack(target, Location)
	end
end

return enemyClass