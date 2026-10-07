--!strict
-- Original detailed primitive scooter; no external meshes or protected logos.
local ScooterFactory = {}

export type Assembly = {
	Model: Model,
	Root: Part,
	Seat: VehicleSeat,
	DriveForce: VectorForce,
	Orientation: AlignOrientation,
	Prompt: ProximityPrompt,
}

local function part(
	model: Model,
	root: Part,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	collidable: boolean,
	shape: Enum.PartType?
): Part
	local result = Instance.new("Part")
	result.Name = name
	result.Size = size
	result.CFrame = root.CFrame * offset
	result.Color = color
	result.Material = Enum.Material.SmoothPlastic
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result.CanCollide = collidable
	result.CanTouch = false
	result.CanQuery = false
	result.Massless = true
	if shape then
		result.Shape = shape
	end
	-- Wheels are a welded blockout, so they slide rather than rotate. Low contact
	-- friction lets the force controller drive them; traction is computed on the server.
	result.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.025, 0, 100, 100)
	result.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = result
	weld.Parent = result
	return result
end

function ScooterFactory.Create(id: string, displayName: string, ownerId: number, pivot: CFrame): Assembly
	local model = Instance.new("Model")
	model.Name = "Scooter_" .. tostring(ownerId)
	model:SetAttribute("ScooterId", id)
	model:SetAttribute("OwnerUserId", ownerId)
	model:SetAttribute("Placeholder", true)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	local deck = Instance.new("Part")
	deck.Name = "Chassis"
	deck.Size = Vector3.new(1.7, 0.45, 4)
	deck.CFrame = pivot
	deck.Color = Color3.fromRGB(37, 42, 51)
	deck.Material = Enum.Material.Metal
	deck.TopSurface = Enum.SurfaceType.Smooth
	deck.BottomSurface = Enum.SurfaceType.Smooth
	deck.CanTouch = false
	deck.RootPriority = 127 -- Keep the chassis as the assembly root even while a rider is welded on.
	deck.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.025, 0, 100, 100)
	deck.Anchored = true -- The service releases the complete assembly after parenting it.
	deck.Parent = model
	model.PrimaryPart = deck

	local dark = Color3.fromRGB(24, 28, 34)
    local accents: {[string]: Color3} = {kukirin_g2 = Color3.fromRGB(239, 151, 57), volt_city = Color3.fromRGB(85, 201, 180), kukirin_g3 = Color3.fromRGB(99, 163, 235), volt_dual = Color3.fromRGB(206, 96, 74), kukirin_g4 = Color3.fromRGB(170, 123, 237)}
    local accent = accents[id] or Color3.fromRGB(239, 151, 57)
    local metal = Color3.fromRGB(98, 108, 119)
    local function detail(name: string, size: Vector3, frame: CFrame, color: Color3, shape: Enum.PartType?): Part
        return part(model, deck, name, size, frame, color, false, shape)
    end
    part(model, deck, "RearWheel", Vector3.new(0.65, 1.45, 1.45), CFrame.new(0, -0.35, 1.35), dark, true, Enum.PartType.Cylinder)
    part(model, deck, "FrontWheel", Vector3.new(0.65, 1.45, 1.45), CFrame.new(0, -0.35, -1.45), dark, true, Enum.PartType.Cylinder)
    for _, z in {-1.45, 1.35} do
        for _, side in {-1, 1} do
            detail(if z < 0 then "FrontRim" else "RearRim", Vector3.new(0.07, 1.03, 1.03), CFrame.new(side * 0.34, -0.35, z), metal, Enum.PartType.Cylinder)
            detail("Hub", Vector3.new(0.09, 0.42, 0.42), CFrame.new(side * 0.39, -0.35, z), accent, Enum.PartType.Cylinder)
            detail("BrakeDisc", Vector3.new(0.035, 0.7, 0.7), CFrame.new(side * 0.43, -0.35, z), Color3.fromRGB(166, 173, 177), Enum.PartType.Cylinder)
            detail("Fork", Vector3.new(0.13, 0.95, 0.17), CFrame.new(side * 0.44, 0.12, z), dark, nil)
            detail("Shock", Vector3.new(0.18, 0.5, 0.18), CFrame.new(side * 0.44, 0.34, z) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.PartType.Cylinder)
        end
    end
    detail("Grip", Vector3.new(1.55, 0.07, 3.2), CFrame.new(0, 0.27, 0), dark, nil)
    for _, side in {-1, 1} do
        local strip = detail("DeckTrim", Vector3.new(0.04, 0.16, 3.4), CFrame.new(side * 0.86, 0.08, 0), accent, nil)
        strip.Material = Enum.Material.Neon
    end
    for z = -1.2, 1.2, 0.4 do detail("DeckGroove", Vector3.new(1.4, 0.012, 0.045), CFrame.new(0, 0.32, z), metal, nil) end
    detail("Stem", Vector3.new(0.3, 3.05, 0.3), CFrame.new(0, 1.68, -1.23) * CFrame.Angles(math.rad(8), 0, 0), accent, nil)
    detail("StemSleeve", Vector3.new(0.36, 0.75, 0.36), CFrame.new(0, 0.7, -1.37), dark, nil)
    detail("FoldingLatch", Vector3.new(0.6, 0.25, 0.3), CFrame.new(0, 0.57, -1.16), metal, nil)
    detail("Handlebar", Vector3.new(2.7, 0.2, 0.2), CFrame.new(0, 3.18, -1.03), dark, Enum.PartType.Cylinder)
    for _, side in {-1, 1} do
        detail("RubberGrip", Vector3.new(0.8, 0.27, 0.27), CFrame.new(side * 1.05, 3.18, -1.03), dark, Enum.PartType.Cylinder)
        detail("BrakeLever", Vector3.new(0.7, 0.07, 0.12), CFrame.new(side * 0.95, 3.13, -1.4) * CFrame.Angles(0, side * 0.2, 0), metal, nil)
    end
    local dashboard = detail("Dashboard", Vector3.new(0.65, 0.12, 0.55), CFrame.new(0, 3.32, -1.03), dark, nil)
    local display = Instance.new("SurfaceGui")
    display.Face, display.SizingMode, display.PixelsPerStud, display.Parent = Enum.NormalId.Top, Enum.SurfaceGuiSizingMode.PixelsPerStud, 90, dashboard
    local digits = Instance.new("TextLabel")
    digits.Size, digits.Text, digits.BackgroundTransparency, digits.TextColor3, digits.Font, digits.TextScaled, digits.Parent = UDim2.fromScale(1, 1), "VOLT", 1, accent, Enum.Font.GothamBold, true, display
    local headlight = detail("FrontLightPlaceholder", Vector3.new(0.5, 0.25, 0.15), CFrame.new(0, 2.95, -1.35), Color3.fromRGB(250, 241, 208), nil)
    headlight.Material = Enum.Material.Neon
    local taillight = detail("TailLight", Vector3.new(0.55, 0.1, 0.08), CFrame.new(0, 0.2, 2.02), Color3.fromRGB(249, 88, 71), nil)
    taillight.Material = Enum.Material.Neon
    detail("RearFender", Vector3.new(0.9, 0.15, 1.1), CFrame.new(0, 0.5, 1.5), dark, nil)

    for _, side in {-1, 1} do
        local limb = if side < 0 then "Left" else "Right"
        for _, kind in {"Foot", "Hand"} do
            local target = Instance.new("Attachment")
            target.Name = limb .. kind .. "Target"
            target.Position = if kind == "Foot" then Vector3.new(side * 0.45, 0.6, 0.5) else Vector3.new(side * 1.02, 3.18, -1.03)
            target.Parent = deck
        end
    end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "RiderSeat"
	seat.Size = Vector3.new(1.4, 0.3, 1.4)
	seat.CFrame = deck.CFrame * CFrame.new(0, 1.35, 0.65)
	seat.Transparency = 1
	seat.CanCollide = false
	seat.CanTouch = false -- Mounting is exclusively through the validated server prompt.
	seat.Massless = true
	seat.HeadsUpDisplay = false
	seat.Torque = 0
	seat.MaxSpeed = 0 -- Native VehicleSeat motor fields never determine scooter statistics.
	seat.TurnSpeed = 0
	seat.Parent = model
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = deck
	seatWeld.Part1 = seat
	seatWeld.Parent = seat

	local attachment = Instance.new("Attachment")
	attachment.Name = "PhysicsAttachment"
	attachment.Parent = deck
	local force = Instance.new("VectorForce")
	force.Name = "ServerDriveForce"
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Parent = deck
	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "ServerUprightControl"
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = attachment
	orientation.MaxTorque = 1000000
	orientation.MaxAngularVelocity = math.rad(240)
	orientation.Responsiveness = 25
	orientation.CFrame = pivot.Rotation
	orientation.Parent = deck

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MountPrompt"
	prompt.ActionText = "Wsiądź • jedź"
	prompt.ObjectText = displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false -- Server raycast validates the approach; small decorative parts cannot hide the prompt.
	prompt.Parent = deck
	return { Model = model, Root = deck, Seat = seat, DriveForce = force, Orientation = orientation, Prompt = prompt }
end

return ScooterFactory
