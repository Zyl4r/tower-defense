--biroska
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseUtils = require(StarterPlayer.StarterPlayerScripts.client.utils.MouseUtils)
local TowerPackets = require(ReplicatedStorage.shared.features.towers.TowerPackets)

local inputs = ReplicatedStorage.Inputs.Placement

local TowerController = {}
TowerController.CurrentPreviewTower = nil :: BasePart?

function isPointInPart(point: Vector3, part: BasePart)
    local volumeSpacePoint = part.CFrame:PointToObjectSpace(point)
    local padding = 0.05

    return math.abs(volumeSpacePoint.X) <= part.Size.X / 2 + padding
       and math.abs(volumeSpacePoint.Y) <= part.Size.Y / 2 + padding
       and math.abs(volumeSpacePoint.Z) <= part.Size.Z / 2 + padding
end


function TowerController.RenderPreview(
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

function TowerController.PlaceTower()
	local selectedTower = TowerController.CurrentPreviewTower

	if not selectedTower then
		return
	end

	TowerPackets.packets.placeTower.send({
		towerId = "",
		cf = selectedTower.CFrame,
	})

	TowerController.CancelPreview()
end

function TowerController.PreviewPlacement(_modelName: string)
	if TowerController.CurrentPreviewTower then
		TowerController.CancelPreview()
	end

	local currentTower = TowerController.RenderPreview("", MouseUtils.GetWorldPosition(workspace.Map))
	TowerController.CurrentPreviewTower = currentTower

    workspace.Map.Path.Parts.UnavailableArea.Transparency = 0.5

	local conn: RBXScriptConnection

	conn = RunService.PreRender:Connect(function(_dt)
		if not TowerController.CurrentPreviewTower then
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

function TowerController.RotatePreview()
	local currentTower = TowerController.CurrentPreviewTower

	if not currentTower then
		return
	end

	currentTower.CFrame = currentTower.CFrame * CFrame.Angles(0, math.rad(45), 0)
end

function TowerController.CancelPreview()
	if not TowerController.CurrentPreviewTower then
		return
	end

	TowerController.CurrentPreviewTower:Destroy()
	TowerController.CurrentPreviewTower = nil
    workspace.Map.Path.Parts.UnavailableArea.Transparency = 1
end

function TowerController.Init()
	inputs.SelectTower.Pressed:Connect(function()
		TowerController.PreviewPlacement("")
	end)

	inputs.PlaceTower.Pressed:Connect(TowerController.PlaceTower)
	inputs.RotateTower.Pressed:Connect(TowerController.RotatePreview)
	inputs.CancelPlacement.Pressed:Connect(TowerController.CancelPreview)

	TowerPackets.packets.placeTower.listen(function(data: { cf: CFrame, towerId: string }, _: Player?)
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

return TowerController
