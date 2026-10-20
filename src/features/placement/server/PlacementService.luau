local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacementPackets = require(ReplicatedStorage.shared.features.placement.PlacementPackets)

local PlacementService = {}

function isPointInPart(point: Vector3, part: BasePart)
    local volumeSpacePoint = part.CFrame:PointToObjectSpace(point)
    local padding = 0.05

    return math.abs(volumeSpacePoint.X) <= part.Size.X / 2
       and math.abs(volumeSpacePoint.Y) <= part.Size.Y / 2 + padding
       and math.abs(volumeSpacePoint.Z) <= part.Size.Z / 2
end

function PlacementService.ValidatePlacement(cf: CFrame): boolean
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { workspace.Map.Path.Validating }

    local validatingCF = CFrame.new(Vector3.new(cf.Position.X, 0, cf.Position.Z))

    local validator = Instance.new("Part")
    validator.Size = Vector3.one
    validator.CFrame = validatingCF
    validator.Anchored = true
    validator.Transparency = 1
    validator.Parent = workspace
    
    local overlappingParts = workspace:GetPartsInPart(validator, params)

    validator:Destroy()

    for _, part in overlappingParts do
        if isPointInPart(validatingCF.Position, part) == true then
            return false
        end
    end

    return true
end

function PlacementService.ConfirmPlacement(towerId: string, cf: CFrame, _owner: Player)
	local isValid = PlacementService.ValidatePlacement(cf)

	if isValid then
		PlacementPackets.packets.placeTower.sendToAll({
			towerId = towerId,
			cf = cf,
		})
	end
end

function PlacementService.Init()
	PlacementPackets.packets.placeTower.listen(function(data: { cf: CFrame, towerId: string }, player: Player?)
		if not player then
			return
		end

		PlacementService.PlaceTower(data.towerId, data.cf, player)
	end)
end

return PlacementService
