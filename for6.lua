local ffff = _G.Fire
local ssss = _G.Sword

if _G.UseCustomReanim == true then else
local Vector3_101 = Vector3.new(1000, 0, 1000)
local netless_Y = Vector3.new(0, 25.1, 0)
local function getNetlessVelocity(realPartVelocity) --change this if you have a better method
    local mag = realPartVelocity.Magnitude
    if (mag > 1) and (mag < 100) then
        local unit = realPartVelocity.Unit
        if (unit.Y > 0.25) or (unit.Y < -0.75) then
            return realPartVelocity * (25.1 / realPartVelocity.Y)
        end
        realPartVelocity = unit * 100
    end
    return (realPartVelocity * Vector3_101) + netless_Y
end
local simradius = "shp" --simulation radius (net bypass) method
--"shp" - sethiddenproperty
--"ssr" - setsimulationradius
--false - disable
local noclipAllParts = true --set it to true if you want noclip
local antiragdoll = true --removes hingeConstraints and ballSocketConstraints from your character
local newanimate = true --disables the animate script and enables after reanimation
local discharscripts = true --disables all localScripts parented to your character before reanimation
local R15toR6 = false --tries to convert your character to r6 if its r15
local hatcollide = false --makes hats cancollide (credit to ShownApe) (works only with reanimate method 0)
local humState16 = true --enables collisions for limbs before the humanoid dies (using hum:ChangeState)
local addtools = false --puts all tools from backpack to character and lets you hold them after reanimation
local hedafterneck = true --disable aligns for head and enable after neck or torso is removed
local loadtime = game:GetService("Players").RespawnTime + 0.5 --anti respawn delay
local method = 3 --reanimation method
--methods:
--0 - breakJoints (takes [loadtime] seconds to laod)
--1 - limbs
--2 - limbs + anti respawn
--3 - limbs + breakJoints after [loadtime] seconds
--4 - remove humanoid + breakJoints
--5 - remove humanoid + limbs
local alignmode = 3 --AlignPosition mode
--modes:
--1 - AlignPosition rigidity enabled true
--2 - 2 AlignPositions rigidity enabled both true and false
--3 - AlignPosition rigidity enabled false
local flingpart = "HumanoidRootPart" --name of the part or the hat used for flinging
--the fling function
--usage: fling(target, duration, velocity)
--target can be set to: basePart, CFrame, Vector3, character model or humanoid (flings at mouse.Hit if argument not provided))
--duration (fling time in seconds) can be set to: a number or a string convertable to the number (0.5s if not provided),
--velocity (fling part rotation velocity) can be set to a vector3 value (Vector3.new(20000, 20000, 20000) if not provided)

local lp = game:GetService("Players").LocalPlayer
local rs = game:GetService("RunService")
local stepped = rs.Stepped
local heartbeat = rs.Heartbeat
local renderstepped = rs.RenderStepped
local sg = game:GetService("StarterGui")
local ws = game:GetService("Workspace")
local cf = CFrame.new
local v3 = Vector3.new
local v3_0 = Vector3.zero
local inf = math.huge

local c = lp.Character

if not (c and c.Parent) then
	return
end

c:GetPropertyChangedSignal("Parent"):Connect(function()
    if not (c and c.Parent) then
	    c = nil
	end
end)

local function gp(parent, name, className)
	if typeof(parent) == "Instance" then
		for i, v in pairs(parent:GetChildren()) do
			if (v.Name == name) and v:IsA(className) then
				return v
			end
		end
	end
	return nil
end

if type(getNetlessVelocity) ~= "function" then
    getNetlessVelocity = nil
end

local function align(Part0, Part1)
	Part0.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)

	local att0 = Instance.new("Attachment")
	att0.Orientation = v3_0
	att0.Position = v3_0
	att0.Name = "att0_" .. Part0.Name
	local att1 = Instance.new("Attachment")
	att1.Orientation = v3_0
	att1.Position = v3_0
	att1.Name = "att1_" .. Part1.Name

	if (alignmode == 1) or (alignmode == 2) then
		local ape = Instance.new("AlignPosition", att0)
		ape.ApplyAtCenterOfMass = false
		ape.MaxForce = inf
		ape.MaxVelocity = inf
		ape.ReactionForceEnabled = false
		ape.Responsiveness = 200
		ape.Attachment1 = att1
		ape.Attachment0 = att0
		ape.Name = "AlignPositionRtrue"
		ape.RigidityEnabled = true
	end

	if (alignmode == 2) or (alignmode == 3) then
		local apd = Instance.new("AlignPosition", att0)
		apd.ApplyAtCenterOfMass = false
		apd.MaxForce = inf
		apd.MaxVelocity = inf
		apd.ReactionForceEnabled = false
		apd.Responsiveness = 200
		apd.Attachment1 = att1
		apd.Attachment0 = att0
		apd.Name = "AlignPositionRfalse"
		apd.RigidityEnabled = false
	end

	local ao = Instance.new("AlignOrientation", att0)
	ao.MaxAngularVelocity = inf
	ao.MaxTorque = inf
	ao.PrimaryAxisOnly = false
	ao.ReactionTorqueEnabled = false
	ao.Responsiveness = 200
	ao.Attachment1 = att1
	ao.Attachment0 = att0
	ao.RigidityEnabled = false

	if getNetlessVelocity then
	    local vel = Part0.Velocity
	    local velpart = Part1
        local rsteppedcon = renderstepped:Connect(function()
            Part0.Velocity = vel
        end)
        local heartbeatcon = heartbeat:Connect(function()
            vel = Part0.Velocity
            Part0.Velocity = getNetlessVelocity(velpart.Velocity)
        end)
        local attcon = nil
        Part0:GetPropertyChangedSignal("Parent"):Connect(function()
            if not (Part0 and Part0.Parent) then
                rsteppedcon:Disconnect()
                heartbeatcon:Disconnect()
                attcon:Disconnect()
            end
        end)
        attcon = att1:GetPropertyChangedSignal("Parent"):Connect(function()
	        if not (att1 and att1.Parent) then
	            attcon:Disconnect()
                velpart = Part0
	        else
	            velpart = att1.Parent
	            if not velpart:IsA("BasePart") then
	                velpart = Part0
	            end
	        end
	    end)
	end
	
	att0.Parent = Part0
    att1.Parent = Part1
end

local function respawnrequest()
	local ccfr = ws.CurrentCamera.CFrame
	local c = lp.Character
	lp.Character = nil
	lp.Character = c
	local con = nil
	con = ws.CurrentCamera.Changed:Connect(function(prop)
	    if (prop ~= "Parent") and (prop ~= "CFrame") then
	        return
	    end
	    ws.CurrentCamera.CFrame = ccfr
	    con:Disconnect()
    end)
end

local destroyhum = (method == 4) or (method == 5)
local breakjoints = (method == 0) or (method == 4)
local antirespawn = (method == 0) or (method == 2) or (method == 3)

hatcollide = hatcollide and (method == 0)

addtools = addtools and gp(lp, "Backpack", "Backpack")

local fenv = getfenv()
local shp = fenv.sethiddenproperty or fenv.set_hidden_property or fenv.set_hidden_prop or fenv.sethiddenprop
local ssr = fenv.setsimulationradius or fenv.set_simulation_radius or fenv.set_sim_radius or fenv.setsimradius or fenv.set_simulation_rad or fenv.setsimulationrad

if shp and (simradius == "shp") then
	spawn(function()
		while c and heartbeat:Wait() do
			shp(lp, "SimulationRadius", inf)
		end
	end)
elseif ssr and (simradius == "ssr") then
	spawn(function()
		while c and heartbeat:Wait() do
			ssr(inf)
		end
	end)
end

antiragdoll = antiragdoll and function(v)
	if v:IsA("HingeConstraint") or v:IsA("BallSocketConstraint") then
		v.Parent = nil
	end
end

if antiragdoll then
	for i, v in pairs(c:GetDescendants()) do
		antiragdoll(v)
	end
	c.DescendantAdded:Connect(antiragdoll)
end

if antirespawn then
	respawnrequest()
end

if method == 0 then
	wait(loadtime)
	if not c then
		return
	end
end

if discharscripts then
	for i, v in pairs(c:GetChildren()) do
		if v:IsA("LocalScript") then
			v.Disabled = true
		end
	end
elseif newanimate then
	local animate = gp(c, "Animate", "LocalScript")
	if animate and (not animate.Disabled) then
		animate.Disabled = true
	else
		newanimate = false
	end
end

if addtools then
	for i, v in pairs(addtools:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = c
		end
	end
end

pcall(function()
	settings().Physics.AllowSleep = false
	settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
end)

local OLDscripts = {}

for i, v in pairs(c:GetDescendants()) do
	if v.ClassName == "Script" then
		table.insert(OLDscripts, v)
	end
end

local scriptNames = {}

for i, v in pairs(c:GetDescendants()) do
	if v:IsA("BasePart") then
		local newName = tostring(i)
		local exists = true
		while exists do
			exists = false
			for i, v in pairs(OLDscripts) do
				if v.Name == newName then
					exists = true
				end
			end
			if exists then
				newName = newName .. "_"    
			end
		end
		table.insert(scriptNames, newName)
		Instance.new("Script", v).Name = newName
	end
end

c.Archivable = true
local hum = c:FindFirstChildOfClass("Humanoid")
if hum then
	for i, v in pairs(hum:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end
local cl = c:Clone()
if hum and humState16 then
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    if destroyhum then
        wait(1.6)
    end
end
if hum and hum.Parent and destroyhum then
    hum:Destroy()
end

if not c then
    return
end

local head = gp(c, "Head", "BasePart")
local torso = gp(c, "Torso", "BasePart") or gp(c, "UpperTorso", "BasePart")
local root = gp(c, "HumanoidRootPart", "BasePart")
if hatcollide and c:FindFirstChildOfClass("Accessory") then
    local anything = c:FindFirstChildOfClass("BodyColors") or gp(c, "Health", "Script")
    if not (torso and root and anything) then
        return
    end
    torso:Destroy()
    root:Destroy()
    if shp then
        for i,v in pairs(c:GetChildren()) do
            if v:IsA("Accessory") then
                shp(v, "BackendAccoutrementState", 0)
            end 
        end
    end
    anything:Destroy()
end

local model = Instance.new("Model", c)
model.Name = model.ClassName

model:GetPropertyChangedSignal("Parent"):Connect(function()
    if not (model and model.Parent) then
	    model = nil
    end
end)

for i, v in pairs(c:GetChildren()) do
	if v ~= model then
		if addtools and v:IsA("Tool") then
			for i1, v1 in pairs(v:GetDescendants()) do
				if v1 and v1.Parent and v1:IsA("BasePart") then
					local bv = Instance.new("BodyVelocity", v1)
					bv.Velocity = v3_0
					bv.MaxForce = v3(1000, 1000, 1000)
					bv.P = 1250
					bv.Name = "bv_" .. v.Name
				end
			end
		end
		v.Parent = model
	end
end

if breakjoints then
	model:BreakJoints()
else
	if head and torso then
		for i, v in pairs(model:GetDescendants()) do
			if v:IsA("Weld") or v:IsA("Snap") or v:IsA("Glue") or v:IsA("Motor") or v:IsA("Motor6D") then
				local save = false
				if (v.Part0 == torso) and (v.Part1 == head) then
					save = true
				end
				if (v.Part0 == head) and (v.Part1 == torso) then
					save = true
				end
				if save then
					if hedafterneck then
						hedafterneck = v
					end
				else
					v:Destroy()
				end
			end
		end
	end
	if method == 3 then
		spawn(function()
			wait(loadtime)
			if model then
				model:BreakJoints()
			end
		end)
	end
end

cl.Parent = c
for i, v in pairs(cl:GetChildren()) do
	v.Parent = c
end
cl:Destroy()

local noclipmodel = (noclipAllParts and c) or model
local noclipcon = nil
local function uncollide()
	if noclipmodel then
		for i, v in pairs(noclipmodel:GetDescendants()) do
		    if v:IsA("BasePart") then
			    v.CanCollide = false
		    end
		end
	else
		noclipcon:Disconnect()
	end
end
noclipcon = stepped:Connect(uncollide)
uncollide()

for i, scr in pairs(model:GetDescendants()) do
	if (scr.ClassName == "Script") and table.find(scriptNames, scr.Name) then
		local Part0 = scr.Parent
		if Part0:IsA("BasePart") then
			for i1, scr1 in pairs(c:GetDescendants()) do
				if (scr1.ClassName == "Script") and (scr1.Name == scr.Name) and (not scr1:IsDescendantOf(model)) then
					local Part1 = scr1.Parent
					if (Part1.ClassName == Part0.ClassName) and (Part1.Name == Part0.Name) then
						align(Part0, Part1)
						scr:Destroy()
						scr1:Destroy()
						break
					end
				end
			end
		end
	end
end

for i, v in pairs(c:GetDescendants()) do
	if v and v.Parent and (not v:IsDescendantOf(model)) then
		if v:IsA("Decal") then
		    v.Transparency = 1
		elseif v:IsA("BasePart") then
			v.Transparency = 1
			v.Anchored = false
		elseif v:IsA("ForceField") then
			v.Visible = false
		elseif v:IsA("Sound") then
			v.Playing = false
		elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
			v.Enabled = false
		end
	end
end

if newanimate then
	local animate = gp(c, "Animate", "LocalScript")
	if animate then
		animate.Disabled = false
	end
end

if addtools then
	for i, v in pairs(c:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = addtools
		end
	end
end

local hum0 = model:FindFirstChildOfClass("Humanoid")
if hum0 then
    hum0:GetPropertyChangedSignal("Parent"):Connect(function()
        if not (hum0 and hum0.Parent) then
            hum0 = nil
        end
    end)
end

local hum1 = c:FindFirstChildOfClass("Humanoid")
if hum1 then
    hum1:GetPropertyChangedSignal("Parent"):Connect(function()
        if not (hum1 and hum1.Parent) then
            hum1 = nil
        end
    end)
    
	ws.CurrentCamera.CameraSubject = hum1
	local camSubCon = nil
	local function camSubFunc()
		camSubCon:Disconnect()
		if c and hum1 then
			ws.CurrentCamera.CameraSubject = hum1
		end
	end
	camSubCon = renderstepped:Connect(camSubFunc)
	if hum0 then
		hum0:GetPropertyChangedSignal("Jump"):Connect(function()
			if hum1 then
				hum1.Jump = hum0.Jump
			end
		end)
	else
		respawnrequest()
	end
end

local rb = Instance.new("BindableEvent", c)
rb.Event:Connect(function()
	rb:Destroy()
	sg:SetCore("ResetButtonCallback", true)
	if destroyhum then
		c:BreakJoints()
		return
	end
	if hum0 and (hum0.Health > 0) then
		model:BreakJoints()
		hum0.Health = 0
	end
	if antirespawn then
	    respawnrequest()
	end
end)
sg:SetCore("ResetButtonCallback", rb)

spawn(function()
	while c do
		if hum0 and hum1 then
			hum1.Jump = hum0.Jump
		end
		wait()
	end
	sg:SetCore("ResetButtonCallback", true)
end)

R15toR6 = R15toR6 and hum1 and (hum1.RigType == Enum.HumanoidRigType.R15)
if R15toR6 then
    local part = gp(c, "HumanoidRootPart", "BasePart") or gp(c, "UpperTorso", "BasePart") or gp(c, "LowerTorso", "BasePart") or gp(c, "Head", "BasePart") or c:FindFirstChildWhichIsA("BasePart")
	if part then
	    local cfr = part.CFrame
		local R6parts = { 
			head = {
				Name = "Head",
				Size = v3(2, 1, 1),
				R15 = {
					Head = 0
				}
			},
			torso = {
				Name = "Torso",
				Size = v3(2, 2, 1),
				R15 = {
					UpperTorso = 0.2,
					LowerTorso = -0.8
				}
			},
			root = {
				Name = "HumanoidRootPart",
				Size = v3(2, 2, 1),
				R15 = {
					HumanoidRootPart = 0
				}
			},
			leftArm = {
				Name = "Left Arm",
				Size = v3(1, 2, 1),
				R15 = {
					LeftHand = -0.849,
					LeftLowerArm = -0.174,
					LeftUpperArm = 0.415
				}
			},
			rightArm = {
				Name = "Right Arm",
				Size = v3(1, 2, 1),
				R15 = {
					RightHand = -0.849,
					RightLowerArm = -0.174,
					RightUpperArm = 0.415
				}
			},
			leftLeg = {
				Name = "Left Leg",
				Size = v3(1, 2, 1),
				R15 = {
					LeftFoot = -0.85,
					LeftLowerLeg = -0.29,
					LeftUpperLeg = 0.49
				}
			},
			rightLeg = {
				Name = "Right Leg",
				Size = v3(1, 2, 1),
				R15 = {
					RightFoot = -0.85,
					RightLowerLeg = -0.29,
					RightUpperLeg = 0.49
				}
			}
		}
		for i, v in pairs(c:GetChildren()) do
			if v:IsA("BasePart") then
				for i1, v1 in pairs(v:GetChildren()) do
					if v1:IsA("Motor6D") then
						v1.Part0 = nil
					end
				end
			end
		end
		part.Archivable = true
		for i, v in pairs(R6parts) do
			local part = part:Clone()
			part:ClearAllChildren()
			part.Name = v.Name
			part.Size = v.Size
			part.CFrame = cfr
			part.Anchored = false
			part.Transparency = 1
			part.CanCollide = false
			for i1, v1 in pairs(v.R15) do
				local R15part = gp(c, i1, "BasePart")
				local att = gp(R15part, "att1_" .. i1, "Attachment")
				if R15part then
					local weld = Instance.new("Weld", R15part)
					weld.Name = "Weld_" .. i1
					weld.Part0 = part
					weld.Part1 = R15part
					weld.C0 = cf(0, v1, 0)
					weld.C1 = cf(0, 0, 0)
					R15part.Massless = true
					R15part.Name = "R15_" .. i1
					R15part.Parent = part
					if att then
						att.Parent = part
						att.Position = v3(0, v1, 0)
					end
				end
			end
			part.Parent = c
			R6parts[i] = part
		end
		local R6joints = {
			neck = {
				Parent = R6parts.torso,
				Name = "Neck",
				Part0 = R6parts.torso,
				Part1 = R6parts.head,
				C0 = cf(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
				C1 = cf(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
			},
			rootJoint = {
				Parent = R6parts.root,
				Name = "RootJoint" ,
				Part0 = R6parts.root,
				Part1 = R6parts.torso,
				C0 = cf(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
				C1 = cf(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
			},
			rightShoulder = {
				Parent = R6parts.torso,
				Name = "Right Shoulder",
				Part0 = R6parts.torso,
				Part1 = R6parts.rightArm,
				C0 = cf(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
				C1 = cf(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)
			},
			leftShoulder = {
				Parent = R6parts.torso,
				Name = "Left Shoulder",
				Part0 = R6parts.torso,
				Part1 = R6parts.leftArm,
				C0 = cf(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
				C1 = cf(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
			},
			rightHip = {
				Parent = R6parts.torso,
				Name = "Right Hip",
				Part0 = R6parts.torso,
				Part1 = R6parts.rightLeg,
				C0 = cf(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
				C1 = cf(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)
			},
			leftHip = {
				Parent = R6parts.torso,
				Name = "Left Hip" ,
				Part0 = R6parts.torso,
				Part1 = R6parts.leftLeg,
				C0 = cf(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
				C1 = cf(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
			}
		}
		for i, v in pairs(R6joints) do
			local joint = Instance.new("Motor6D")
			for prop, val in pairs(v) do
				joint[prop] = val
			end
			R6joints[i] = joint
		end
		if hum1 then
    		hum1.RigType = Enum.HumanoidRigType.R6
    		hum1.HipHeight = 0
		end
	end
end

local torso1 = torso
torso = gp(c, "Torso", "BasePart") or ((not R15toR6) and gp(c, torso.Name, "BasePart"))
if (typeof(hedafterneck) == "Instance") and head and torso and torso1 then
	local conNeck = nil
	local conTorso = nil
	local contorso1 = nil
	local aligns = {}
	local function enableAligns()
	    conNeck:Disconnect()
        conTorso:Disconnect()
        conTorso1:Disconnect()
		for i, v in pairs(aligns) do
			v.Enabled = true
		end
	end
	conNeck = hedafterneck.Changed:Connect(function(prop)
	    if table.find({"Part0", "Part1", "Parent"}, prop) then
	        enableAligns()
		end
	end)
	conTorso = torso:GetPropertyChangedSignal("Parent"):Connect(enableAligns)
	conTorso1 = torso1:GetPropertyChangedSignal("Parent"):Connect(enableAligns)
	for i, v in pairs(head:GetDescendants()) do
		if v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
			i = tostring(i)
			aligns[i] = v
			v:GetPropertyChangedSignal("Parent"):Connect(function()
			    aligns[i] = nil
			end)
			v.Enabled = false
		end
	end
end

local flingpart0 = gp(model, flingpart, "BasePart") or gp(gp(model, flingpart, "Accessory"), "Handle", "BasePart")
local flingpart1 = gp(c, flingpart, "BasePart") or gp(gp(c, flingpart, "Accessory"), "Handle", "BasePart")

local fling = function() end
if flingpart0 and flingpart1 then
    flingpart0:GetPropertyChangedSignal("Parent"):Connect(function()
        if not (flingpart0 and flingpart0.Parent) then
            flingpart0 = nil
            fling = function() end
        end
    end)
    flingpart0.Archivable = true
    flingpart1:GetPropertyChangedSignal("Parent"):Connect(function()
        if not (flingpart1 and flingpart1.Parent) then
            flingpart1 = nil
            fling = function() end
        end
    end)
    local att0 = gp(flingpart0, "att0_" .. flingpart0.Name, "Attachment")
    local att1 = gp(flingpart1, "att1_" .. flingpart1.Name, "Attachment")
    if att0 and att1 then
        att0:GetPropertyChangedSignal("Parent"):Connect(function()
            if not (att0 and att0.Parent) then
                att0 = nil
                fling = function() end
            end
        end)
        att1:GetPropertyChangedSignal("Parent"):Connect(function()
            if not (att1 and att1.Parent) then
                att1 = nil
                fling = function() end
            end
        end)
        local lastfling = nil
        local mouse = lp:GetMouse()
        fling = function(target, duration, rotVelocity)
            if typeof(target) == "Instance" then
                if target:IsA("BasePart") then
                    target = target.Position
                elseif target:IsA("Model") then
                    target = gp(target, "HumanoidRootPart", "BasePart") or gp(target, "Torso", "BasePart") or gp(target, "UpperTorso", "BasePart") or target:FindFirstChildWhichIsA("BasePart")
                    if target then
                        target = target.Position
                    else
                        return
                    end
                elseif target:IsA("Humanoid") then
                    local parent = target.Parent
                    if not (parent and parent:IsA("Model")) then
                        return
                    end
                    target = gp(target, "HumanoidRootPart", "BasePart") or gp(target, "Torso", "BasePart") or gp(target, "UpperTorso", "BasePart") or target:FindFirstChildWhichIsA("BasePart")
                    if target then
                        target = target.Position
                    else
                        return
                    end
                else
                    return
                end
            elseif typeof(target) == "CFrame" then
                target = target.Position
            elseif typeof(target) ~= "Vector3" then
                target = mouse.Hit
                if target then
                    target = target.Position
                else
                    return
                end
            end
            lastfling = target
            if type(duration) ~= "number" then
                duration = tonumber(duration) or 0.5
            end
            if typeof(rotVelocity) ~= "Vector3" then
                rotVelocity = v3(20000, 20000, 20000)
            end
            if not (target and flingpart0 and flingpart1 and att0 and att1) then
                return
            end
            local flingpart = flingpart0:Clone()
            flingpart.Transparency = 1
            flingpart.Size = v3(0.01, 0.01, 0.01)
            flingpart.CanCollide = false
            flingpart.Name = "flingpart_" .. flingpart0.Name
            flingpart.Anchored = true
            flingpart.Velocity = v3_0
            flingpart.RotVelocity = v3_0
            flingpart:GetPropertyChangedSignal("Parent"):Connect(function()
                if not (flingpart and flingpart.Parent) then
                    flingpart = nil
                end
            end)
            flingpart.Parent = flingpart1
            if flingpart0.Transparency > 0.5 then
                flingpart0.Transparency = 0.5
            end
            att1.Parent = flingpart
            for i, v in pairs(att0:GetChildren()) do
                if v:IsA("AlignOrientation") then
                    v.Enabled = false
                end
            end
            local con = nil
            con = heartbeat:Connect(function()
                if target and (lastfling == target) and flingpart and flingpart0 and flingpart1 and att0 and att1 then
                    flingpart0.RotVelocity = rotVelocity
                    flingpart.Position = target
                else
                    con:Disconnect()
                end
            end)
            local rsteppedRotVel = v3(
                ((rotVelocity.X > 0) and -1) or 1,
                ((rotVelocity.Y > 0) and -1) or 1,
                ((rotVelocity.Z > 0) and -1) or 1
            )
            local con = nil
            con = renderstepped:Connect(function()
                if target and (lastfling == target) and flingpart and flingpart0 and flingpart1 and att0 and att1 then
                    flingpart0.RotVelocity = rsteppedRotVel
                    flingpart.Position = target
                else
                    con:Disconnect()
                end
            end)
            wait(duration)
            if lastfling ~= target then
                if flingpart then
                    if att1 and (att1.Parent == flingpart) then
                        att1.Parent = flingpart1
                    end
                    flingpart:Destroy()
                end
                return
            end
            target = nil
            if not (flingpart and flingpart0 and flingpart1 and att0 and att1) then
                return
            end
            flingpart0.RotVelocity = v3_0
            att1.Parent = flingpart1
            for i, v in pairs(att0:GetChildren()) do
                if v:IsA("AlignOrientation") then
                    v.Enabled = true
                end
            end
            if flingpart then
                flingpart:Destroy()
            end
        end
    end
end
end

local Character = game.Players.LocalPlayer.Character
local Humanoid = Character.Humanoid
local UserInputService = game:GetService("UserInputService")
local Head = Character.Head
local UpperTorso = Character.UpperTorso
local LowerTorso = Character.LowerTorso
local RightUpperArm = Character.RightUpperArm
local LeftUpperArm = Character.LeftUpperArm
local RightLowerArm = Character.RightLowerArm
local LeftLowerArm = Character.LeftLowerArm
local RightHand = Character.RightHand
local LeftHand = Character.LeftHand
local RightUpperLeg = Character.RightUpperLeg
local LeftUpperLeg = Character.LeftUpperLeg
local RightLowerLeg = Character.RightLowerLeg
local LeftLowerLeg = Character.LeftLowerLeg
local RightFoot = Character.RightFoot
local LeftFoot = Character.LeftFoot
local HumanoidRootPart = Character.HumanoidRootPart
local LeftAnkle = LeftFoot.LeftAnkle
local LeftWrist = LeftHand.LeftWrist
local LeftElbow = LeftLowerArm.LeftElbow
local LeftKnee = LeftLowerLeg.LeftKnee
local LeftShoulder = LeftUpperArm.LeftShoulder
local LeftHip = LeftUpperLeg.LeftHip
local Root = LowerTorso.Root
local RightAnkle = RightFoot.RightAnkle
local RightWrist = RightHand.RightWrist
local RightElbow = RightLowerArm.RightElbow
local RightKnee = RightLowerLeg.RightKnee
local RightShoulder = RightUpperArm.RightShoulder
local RightHip = RightUpperLeg.RightHip
local Waist = UpperTorso.Waist
local Neck = Head.Neck
local LeftAnkleC0 = LeftAnkle.C0
local LeftWristC0 = LeftWrist.C0
local LeftElbowC0 = LeftElbow.C0
local LeftKneeC0 = LeftKnee.C0
local LeftShoulderC0 = LeftShoulder.C0
local LeftHipC0 = LeftHip.C0
local RootC0 = Root.C0
local RightAnkleC0 = RightAnkle.C0
local RightWristC0 = RightWrist.C0
local RightElbowC0 = RightElbow.C0
local RightKneeC0 = RightKnee.C0
local RightShoulderC0 = RightShoulder.C0
local RightHipC0 = RightHip.C0
local WaistC0 = Waist.C0
local NeckC0 = Neck.C0
local sine = 0
local change = 1
local CF = {N=CFrame.new,A=CFrame.Angles}
local M = {R=math.rad,C=math.cos,S=math.sin}
local V3 = {N=Vector3.new,FNI=Vector3.FromNormalId,A=Vector3.FromAxis}
Character.Animate:Destroy()
Character.Humanoid.Animator:Destroy()
IT = Instance.new
CF = CFrame.new
VT = Vector3.new
RAD = math.rad
C3 = Color3.new
UD2 = UDim2.new
BRICKC = BrickColor.new
ANGLES = CFrame.Angles
EULER = CFrame.fromEulerAnglesXYZ
COS = math.cos
ACOS = math.acos
SIN = math.sin
ASIN = math.asin
ABS = math.abs
MRANDOM = math.random
FLOOR = math.floor
RightShoulder.C0 = CFrame.new(1.5,.5,0)
RightShoulder.C1 = CFrame.new(0,.5,0)
LeftShoulder.C0 = CFrame.new(-1.5,.5,0)
LeftShoulder.C1 = CFrame.new(0,.5,0)
root = CFrame.fromEulerAnglesXYZ(-1.57,0,3.14)
necko = CFrame.new(0,1,0,-1,0,0,0,0,1,0,1,0)
function swait()
	game:GetService("RunService").Heartbeat:wait()
end
function clerp(uno,dos,tres)
	return uno:lerp(dos,tres)
end
function Clerp(a, b, t)
	return a:lerp(b,t)
end
local MODE = 1

local dsound = Instance.new("Sound",game.Players.LocalPlayer.Character.Model.UpperTorso)
dsound.SoundId = "rbxassetid://5951797902"
dsound.Looped = false

local dashsound = Instance.new("Sound",game.Players.LocalPlayer.Character.Model.UpperTorso)
dashsound.SoundId = "rbxassetid://5989939664"
dashsound.Looped = false
dashsound.Volume = 10


local m = game:GetService("Players").LocalPlayer:GetMouse()
m.Button1Down:Connect(function()
if MODE == 1 then 
if _G.UseCustomReanim == true then else
Vector3_101 = Vector3.new(1000, 0, 1000)
end
MODE = 2 
wait(0.5)
if _G.UseSounds == false then else
dsound:Play()
end
MODE = 3 
wait(0.5)
MODE = 1
if _G.UseCustomReanim == true then else
Vector3_101 = Vector3.new(1, 0, 1)
end
end
end)

local character = game:GetService("Players").LocalPlayer.Character
local humanoid = character:WaitForChild("Humanoid")
local rootPart = humanoid.RootPart


m.KeyDown:Connect(function(k)
if k == "e" or k == "E" then 
if MODE == 1 then 
if _G.UseCustomReanim == true then else
Vector3_101 = Vector3.new(1000, 0, 1000)
end
MODE = 4 
wait(0.25)
if _G.UseSounds == false then else
dashsound:Play()
end
    local startPosition = rootPart.CFrame
local endPosition = rootPart.CFrame * CFrame.new(0, 0, -30)

local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
local tween = game:GetService("TweenService"):Create(rootPart, tweenInfo, {CFrame = endPosition})

tween:Play()
wait(0.5)
MODE = 1
if _G.UseCustomReanim == true then else
Vector3_101 = Vector3.new(1, 0, 1)
end
tween.Completed:Connect(function()
    rootPart.CFrame = endPosition
end)

end
end
end)


while true do
swait()
sine = sine + change
local torvel = (HumanoidRootPart.Velocity * Vector3.new(1, 0, 1)).magnitude
if MODE == 1 then 
if torvel < 1 then
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.10000000000000003+0*math.cos(sine/60),-0.30000000000000004+0*math.cos(sine/60),-0.4+0*math.cos(sine/60))*CFrame.Angles(math.rad(45+1*math.sin(sine/60)),math.rad(0+0*math.sin(sine/60)),math.rad(25+0*math.sin(sine/60))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(40+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(2.7755575615628914e-17+0*math.cos(sine/60),-0.1+0*math.cos(sine/60),-0.09999999999999998+0*math.cos(sine/60))*CFrame.Angles(math.rad(50+1*math.sin(sine/60)),math.rad(0+0*math.sin(sine/60)),math.rad(0+0*math.sin(sine/60))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(-40+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(5+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(35+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(-90+0*math.cos(sine/13)),RAD(60+0*math.cos(sine/13)),RAD(230+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["HumanoidRootPart"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(0+0*math.cos(sine/13),18+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
else
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.10000000000000003+0*math.cos(sine/60),-0.30000000000000004+0*math.cos(sine/60),-0.4+0*math.cos(sine/60))*CFrame.Angles(math.rad(90+1*math.sin(sine/60)),math.rad(0+0*math.sin(sine/60)),math.rad(35+0*math.sin(sine/60))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(25+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(2.7755575615628914e-17+0*math.cos(sine/60),-0.1+0*math.cos(sine/60),-0.09999999999999998+0*math.cos(sine/60))*CFrame.Angles(math.rad(85+1*math.sin(sine/60)),math.rad(0+0*math.sin(sine/60)),math.rad(10+0*math.sin(sine/60))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(-45+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+-0.2*math.cos(sine/13),0+-0.10000000000000003*math.cos(sine/13))*CFrame.Angles(math.rad(0+-45*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-15+-25*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0.2*math.cos(sine/13),0+-0.2*math.cos(sine/13))*CFrame.Angles(math.rad(0+55*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-15+25*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(-90+0*math.cos(sine/13)),RAD(60+0*math.cos(sine/13)),RAD(230+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["HumanoidRootPart"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(0+0*math.cos(sine/13),18+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
end
end

if MODE == 2 then --Attack 1
if torvel < 1 then
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(30+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(-30+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.5+0*math.cos(sine/13),-0.5+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(90+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(60+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(-0.8999999999999997+0*math.cos(sine/13),0+0*math.cos(sine/13),-0.6+0*math.cos(sine/13))*CFrame.Angles(math.rad(100+0*math.sin(sine/13)),math.rad(25+0*math.sin(sine/13)),math.rad(-35+0*math.sin(sine/13))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(55+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(-15+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(5+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(45+0*math.cos(sine/13)),RAD(105+0*math.cos(sine/13)),RAD(50+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),1+0*math.cos(sine/13),3+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
else
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(30+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(-30+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.5+0*math.cos(sine/13),-0.5+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(90+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(60+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(-0.8999999999999997+0*math.cos(sine/13),0+0*math.cos(sine/13),-0.6+0*math.cos(sine/13))*CFrame.Angles(math.rad(100+0*math.sin(sine/13)),math.rad(25+0*math.sin(sine/13)),math.rad(-35+0*math.sin(sine/13))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(55+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(-15+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+-0.2*math.cos(sine/13),0+-0.10000000000000003*math.cos(sine/13))*CFrame.Angles(math.rad(0+-45*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-15+-25*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0.2*math.cos(sine/13),0+-0.2*math.cos(sine/13))*CFrame.Angles(math.rad(0+55*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-15+25*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(45+0*math.cos(sine/13)),RAD(105+0*math.cos(sine/13)),RAD(50+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),1+0*math.cos(sine/13),3+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
end
end

if MODE == 3 then --attack 2
if torvel < 1 then
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(-15+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.5+0*math.cos(sine/13),-0.5+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(75+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(15+0*math.sin(sine/13))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(0.40000000000000024+0*math.cos(sine/13),0+0*math.cos(sine/13),-2.7755575615628914e-17+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(-20+0*math.sin(sine/13)),math.rad(50+0*math.sin(sine/13))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(5+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(65+0*math.cos(sine/13)),RAD(125+0*math.cos(sine/13)),RAD(90+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(0.9999999999999992+0*math.cos(sine/13),0.5000000000000001+0*math.cos(sine/13),4.3+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
else
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(-15+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(10+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.5+0*math.cos(sine/13),-0.5+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(75+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(15+0*math.sin(sine/13))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(0.40000000000000024+0*math.cos(sine/13),0+0*math.cos(sine/13),-2.7755575615628914e-17+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(-20+0*math.sin(sine/13)),math.rad(50+0*math.sin(sine/13))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+-0.2*math.cos(sine/13),0+-0.10000000000000003*math.cos(sine/13))*CFrame.Angles(math.rad(0+-45*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-15+-25*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0.2*math.cos(sine/13),0+-0.2*math.cos(sine/13))*CFrame.Angles(math.rad(0+55*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-15+25*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(65+0*math.cos(sine/13)),RAD(125+0*math.cos(sine/13)),RAD(90+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(0.9999999999999992+0*math.cos(sine/13),0.5000000000000001+0*math.cos(sine/13),4.3+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
end
end

if MODE == 4 then 
if torvel < 1 then
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-35+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.5+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(90+0*math.sin(sine/13)),math.rad(5+0*math.sin(sine/13)),math.rad(50+0*math.sin(sine/13))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(10+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(0.5+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-65+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(10+0*math.sin(sine/13))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-65+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-5+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),1.5+0*math.cos(sine/13),-0.5+0*math.cos(sine/13))*ANGLES(RAD(180+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(-195+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(-3+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
else
Root.C0 = clerp(Root.C0,RootC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Waist.C0 = clerp(Waist.C0,WaistC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-35+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Neck.C0 = clerp(Neck.C0,NeckC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftShoulder.C0 = clerp(LeftShoulder.C0,LeftShoulderC0*CFrame.new(-0.5+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(90+0*math.sin(sine/13)),math.rad(5+0*math.sin(sine/13)),math.rad(50+0*math.sin(sine/13))),.1)
LeftElbow.C0 = clerp(LeftElbow.C0,LeftElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(10+0*math.sin(sine/13))),.1)
LeftWrist.C0 = clerp(LeftWrist.C0,LeftWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightShoulder.C0 = clerp(RightShoulder.C0,RightShoulderC0*CFrame.new(0.5+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-65+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(10+0*math.sin(sine/13))),.1)
RightElbow.C0 = clerp(RightElbow.C0,RightElbowC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightWrist.C0 =clerp(RightWrist.C0,RightWristC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftHip.C0 = Clerp(LeftHip.C0,LeftHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-65+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftAnkle.C0 = Clerp(LeftAnkle.C0,LeftAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
LeftKnee.C0 = Clerp(LeftKnee.C0,LeftKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-25+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightHip.C0 = Clerp(RightHip.C0,RightHipC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightAnkle.C0 = Clerp(RightAnkle.C0,RightAnkleC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
RightKnee.C0 = Clerp(RightKnee.C0,RightKneeC0*CFrame.new(0+0*math.cos(sine/13),0+0*math.cos(sine/13),0+0*math.cos(sine/13))*CFrame.Angles(math.rad(-5+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13)),math.rad(0+0*math.sin(sine/13))),.1)
Character[ssss].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ssss].Handle.AccessoryWeld.C0 = Character[ssss].Handle.AccessoryWeld.C0:Lerp(CF(2+0*math.cos(sine/13),1.5+0*math.cos(sine/13),-0.5+0*math.cos(sine/13))*ANGLES(RAD(180+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(-195+0*math.cos(sine/13))),.1)
if _G.UseFire == false then else
Character[ffff].Handle.AccessoryWeld.Part1 = Character["RightHand"]
Character[ffff].Handle.AccessoryWeld.C0 = Character[ffff].Handle.AccessoryWeld.C0:Lerp(CF(-3+0*math.cos(sine/13),2+0*math.cos(sine/13),0+0*math.cos(sine/13))*ANGLES(RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13)),RAD(0+0*math.cos(sine/13))),.1)
end
end
end
end
