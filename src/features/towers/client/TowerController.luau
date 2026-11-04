local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local EnemyController = require(StarterPlayer.StarterPlayerScripts.client.features.enemy.EnemyController)
local TowerPackets = require(ReplicatedStorage.shared.features.towers.TowerPackets)

local renderedTowers = {}

local TowerController = {}

local function getTarget(enemies, tower)
	local towerPos = tower.Position
	local rangeSquared = tower.Range ^ 2

	local bestEnemy = nil
	local bestMetric = -1
	local index = nil

	for i, enemy in enemies do
		if not enemy.Position then
			continue
		end

		if enemy.Health <= 0 then
			continue
		end

		-- Fast squared-distance calculation
		local offset = enemy.Position - towerPos
		local distanceSquared = (offset.X * offset.X) + (offset.Y * offset.Y) + (offset.Z * offset.Z)
		local targetingMode = tower.TargetMode

		-- Is the enemy within the tower's circle?
		if distanceSquared <= rangeSquared then
			if targetingMode == "First" then
				-- "First" means the highest DistanceTravelled
				if enemy.DistanceTravelled > bestMetric then
					bestMetric = enemy.DistanceTravelled
					bestEnemy = enemy
					index = i
				end
			elseif targetingMode == "Last" then
				-- "Last" means the lowest DistanceTravelled
				if bestMetric == -1 or enemy.DistanceTravelled < bestMetric then
					bestMetric = enemy.DistanceTravelled
					bestEnemy = enemy
					index = i
				end
			elseif targetingMode == "Strongest" then
				-- "Strongest" looks at enemy health
				if enemy.Health > bestMetric then
					bestMetric = enemy.Health
					bestEnemy = enemy
					index = i
				end
			end
		end
	end

	return bestEnemy, index
end

function TowerController.GetNearTowers(point: Vector3, radius: number, validateOnly: boolean?)
    local foundTowers = {}

    for _, tower in renderedTowers do
        if not tower.Position then
            continue
        end

        local towerRadius = tower.OccupyingRadius
        if not towerRadius then
            warn("Tower missing OccupyingRadius:", tower)
            towerRadius = 1.5
        end

        local minAllowedDistance = radius + towerRadius
        local minAllowedDistanceSquared = (minAllowedDistance ^ 2)

        -- Compare on the ground plane only (ignore height)
        local dx = point.X - tower.Position.X
        local dz = point.Z - tower.Position.Z
        local actualDistanceSquared = (dx * dx + dz * dz)

        if actualDistanceSquared + 0.5 < minAllowedDistanceSquared  then
            if validateOnly == true then
                return false
            end

            table.insert(foundTowers, tower)
        end
    end

    if validateOnly then
        return true
    end

    return foundTowers
end

function TowerController.Init()
	TowerPackets.packets.spawnTower.listen(
		function(data: { cf: CFrame, towerId: string, spawnTime: number }, _: Player?)
			--Get a tower model from ReplicatedStorage
			local newModel = ReplicatedStorage.Assets.Towers.TowerTemplate:Clone()
			newModel:PivotTo(data.cf)
			newModel.RangeDiameter.Inner.Transparency = 1
			newModel.RangeDiameter.Outer.Transparency = 1
			newModel.TowerModel.Highlight.OutlineTransparency = 1
            newModel.OccupyingDiameter.Inner.Transparency = 1

            print(newModel.OccupyingDiameter.Outer.Size.Z)

			newModel.Parent = workspace.Map.PlacementObjects.Placed

			local towerData = {
				renderedModel = newModel,
				LastDamage = data.spawnTime,
				Range = 6,
				Position = data.cf.Position,
				TargetMode = "First",
				OccupyingRadius = 1.5,
			}

			table.insert(renderedTowers, towerData)
		end
	)

	RunService.PreRender:Connect(function(_: number)
		local enemies = EnemyController.GetEnemies()

		for _, tower in renderedTowers do
			if os.clock() - tower.LastDamage < 1 then
				continue
			end

			local target, _ = getTarget(enemies, tower)

			if not target then
				continue
			end

			target.Health -= 2

			tower.renderedModel:PivotTo(
				CFrame.lookAt(
					tower.renderedModel.PrimaryPart.Position,
					Vector3.new(target.Position.X, tower.renderedModel.PrimaryPart.Position.Y, target.Position.Z)
				)
			)
			tower.LastDamage = os.clock()
		end
	end)
end

return TowerController
