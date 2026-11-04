--biroska
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseUtils = require(StarterPlayer.StarterPlayerScripts.client.core.utils.MouseUtils)
local TowerController = require(StarterPlayer.StarterPlayerScripts.client.features.towers.TowerController)
local PlacementPackets = require(ReplicatedStorage.shared.features.placement.PlacementPackets)

local inputs = ReplicatedStorage.Inputs.Placement

local PlacementController = {}
PlacementController.CurrentPreviewTower = nil :: Model?

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
	local newModel = ReplicatedStorage.Assets.Towers.TowerTemplate:Clone()
    newModel.Parent = workspace.Map.PlacementObjects.Preview

	return newModel
end

function PlacementController.PlaceTower()
	local selectedTower = PlacementController.CurrentPreviewTower

	if not selectedTower then
		return
	end

	PlacementPackets.packets.ValidatePlacement.send({
		towerId = "",
		cf = selectedTower:GetPivot(),
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
		local newPos = Vector3.new(worldPos.X, worldPos.Y + currentTower.PrimaryPart.Size.Y / 2, worldPos.Z)
		currentTower:PivotTo(CFrame.new(newPos) * currentTower:GetPivot().Rotation)

        local target = MouseUtils.GetMouseTarget(workspace.Map.PlacementObjects)

        if not target or not target:IsA("BasePart") then
            return
        end

        local isValid = target:HasTag("InvalidPlacement") and isPointInPart(worldPos, target) or not TowerController.GetNearTowers(worldPos, 1.5, true)
        local hightlightColor = if isValid then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(255, 255, 255)

        for _, item in currentTower:GetDescendants() do
            if item.Name == "TowerModel" then
                continue
            end

            if item:IsA("Highlight") then
                item.FillColor = hightlightColor
                item.OutlineColor = hightlightColor
                continue
            end

            if item:IsA("BasePart") then
                item.Color = hightlightColor
            end
        end
	end)
end

function PlacementController.RotatePreview()
	local currentTower = PlacementController.CurrentPreviewTower

	if not currentTower then
		return
	end

	currentTower:PivotTo(currentTower:GetPivot() * CFrame.Angles(0, math.rad(45), 0))
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
end

return PlacementController
