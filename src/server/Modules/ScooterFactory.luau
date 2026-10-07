--!strict
-- Original blockout model: no external mesh, sound, animation or brand logo is required.
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

	local dark = Color3.fromRGB(22, 24, 28)
	local accent = Color3.fromRGB(230, 158, 52)
	part(model, deck, "RearWheel", Vector3.new(0.55, 1.3, 1.3), CFrame.new(0, -0.35, 1.35), dark, true, Enum.PartType.Cylinder)
	part(model, deck, "FrontWheel", Vector3.new(0.55, 1.3, 1.3), CFrame.new(0, -0.35, -1.45), dark, true, Enum.PartType.Cylinder)
	part(model, deck, "Grip", Vector3.new(1.55, 0.05, 3.5), CFrame.new(0, 0.25, 0.05), dark, false, nil)
	part(model, deck, "Stem", Vector3.new(0.2, 3.3, 0.2), CFrame.new(0, 1.65, -1.45), accent, false, nil)
	part(model, deck, "Handlebar", Vector3.new(2.5, 0.2, 0.2), CFrame.new(0, 3.2, -1.45), dark, false, nil)
	part(model, deck, "FrontLightPlaceholder", Vector3.new(0.4, 0.2, 0.1), CFrame.new(0, 2.9, -1.58), Color3.fromRGB(246, 238, 201), false, nil)

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
	prompt.ActionText = "Jedź"
	prompt.ObjectText = displayName .. " • placeholder"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = true
	prompt.Parent = deck
	return { Model = model, Root = deck, Seat = seat, DriveForce = force, Orientation = orientation, Prompt = prompt }
end

return ScooterFactory
