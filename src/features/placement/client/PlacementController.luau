--biroska
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseUtils = require(StarterPlayer.StarterPlayerScripts.client.utils.MouseUtils)
local PlacementPackets = require(ReplicatedStorage.shared.features.placement.PlacementPackets)

local inputs = ReplicatedStorage.Inputs.Placement

local PlacementController = {}
PlacementController.CurrentPreviewTower = nil :: BasePart?

function isPointInPart(point: Vector3, part: BasePart)
    local volumeSpacePoint = part.CFrame:PointToObjectSpace(point)
    local padding = 0.05

    return math.abs(volumeSpacePoint.X) <= part.Size.X / 2 + padding
       and math.abs(volumeSpacePoint.Y) <= part.Size.Y / 2 + padding
       and math.abs(volumeSpacePoint.Z) <= part.Size.Z / 2 + padding
end


function PlacementController.RenderPreview(
	_modelName: string,
	_initialPosition: Vector3
): BasePart --Make it return a model later
	local model = Instance.new("Part")
	model.Size = Vector3.new(1, 3, 2)
	model.Name = "TestModel"
	model.Anchored = true
	model.CanCollide = false
	model.CastShadow = false
	model.CanQuery = false
	model.Parent = workspace.Map.PlacementObjects.Preview

	return model
end

function PlacementController.PlaceTower()
	local selectedTower = PlacementController.CurrentPreviewTower

	if not selectedTower then
		return
	end

	PlacementPackets.packets.placeTower.send({
		towerId = "",
		cf = selectedTower.CFrame,
	})

	PlacementController.CancelPreview()
end

function PlacementController.PreviewPlacement(_modelName: string)
	if PlacementController.CurrentPreviewTower then
		PlacementController.CancelPreview()
	end

	local currentTower = PlacementController.RenderPreview("", MouseUtils.GetWorldPosition(workspace.Map))
	PlacementController.CurrentPreviewTower = currentTower

    workspace.Map.Path.Parts.UnavailableArea.Transparency = 0.5

	local conn: RBXScriptConnection

	conn = RunService.PreRender:Connect(function(_dt)
		if not PlacementController.CurrentPreviewTower then
			conn:Disconnect()
			return
		end

		local worldPos = MouseUtils.GetWorldPosition(workspace.Map)
		local newPos = Vector3.new(worldPos.X, worldPos.Y + currentTower.Size.Y / 2, worldPos.Z)
		currentTower.CFrame = CFrame.new(newPos) * currentTower.CFrame.Rotation

        local target = MouseUtils.GetMouseTarget(workspace.Map.PlacementObjects)

        if not target or not target:IsA("BasePart") then
            return
        end

		if target:HasTag("InvalidPlacement") and isPointInPart(worldPos, target) then
			currentTower.BrickColor = BrickColor.new("Really red")
		else
			currentTower.BrickColor = BrickColor.new("Lime green")
		end
	end)
end

function PlacementController.RotatePreview()
	local currentTower = PlacementController.CurrentPreviewTower

	if not currentTower then
		return
	end

	currentTower.CFrame = currentTower.CFrame * CFrame.Angles(0, math.rad(45), 0)
end

function PlacementController.CancelPreview()
	if not PlacementController.CurrentPreviewTower then
		return
	end

	PlacementController.CurrentPreviewTower:Destroy()
	PlacementController.CurrentPreviewTower = nil
    workspace.Map.Path.Parts.UnavailableArea.Transparency = 1
end

function PlacementController.Init()
	inputs.SelectTower.Pressed:Connect(function()
		PlacementController.PreviewPlacement("")
	end)

	inputs.PlaceTower.Pressed:Connect(PlacementController.PlaceTower)
	inputs.RotateTower.Pressed:Connect(PlacementController.RotatePreview)
	inputs.CancelPlacement.Pressed:Connect(PlacementController.CancelPreview)

	PlacementPackets.packets.placeTower.listen(function(data: { cf: CFrame, towerId: string }, _: Player?)
		--Get a tower model from ReplicatedStorage
		local model = Instance.new("Part")
		model.Size = Vector3.new(1, 3, 2)
		model.Name = "TestModel"
		model.Anchored = true
		model.CanCollide = false
		model.CastShadow = false
		model.CanQuery = false
		model.CFrame = data.cf
		model.Parent = workspace.Map.PlacementObjects.Placed
	end)
end

return PlacementController
