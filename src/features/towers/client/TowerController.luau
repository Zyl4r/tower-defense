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

	return bestEnemy, index -- Returns the enemy data object (or nil if none in range)
end

function TowerController.Init()
	TowerPackets.packets.spawnTower.listen(function(data: { cf: CFrame, towerId: string, spawnTime: number }, _: Player?)
		--Get a tower model from ReplicatedStorage
		local model = Instance.new("Part")
		model.Size = Vector3.new(2, 3, 1)
		model.Name = "TestModel"
		model.Anchored = true
		model.CanCollide = false
		model.CastShadow = false
		model.CanQuery = false
		model.CFrame = data.cf
		model.Parent = workspace.Map.PlacementObjects.Placed

        local towerData = {
            renderedModel = model,
            LastDamage = data.spawnTime,
            Range = 6,
            Position = data.cf.Position,
            TargetMode = "First"
        }

        table.insert(renderedTowers, towerData)
	end)

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

			tower.renderedModel.CFrame = CFrame.lookAt(tower.renderedModel.Position, Vector3.new(target.Position.X, tower.renderedModel.Position.Y, target.Position.Z))
            tower.LastDamage = os.clock()
        end
    end)
end

return TowerController
