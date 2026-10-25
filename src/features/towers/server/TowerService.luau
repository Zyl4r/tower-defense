local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EnemyService = require(ServerScriptService.server.features.enemy.EnemyService)
local TowerPackets = require(ReplicatedStorage.shared.features.towers.TowerPackets)

export type Tower = {
	Name: string,
	Id: string,
	Damage: number,
	Rate: number,
	Range: number,
	Position: Vector3,
	TargetMode: "First" | "Last" | "Strongest" | "Weakest",
	LastDamage: number,
}

local towers: { Tower } = {}

local TowerService = {}

local function getTarget(enemies, tower: Tower): (EnemyService.Enemy?, string?)
	local towerPos = tower.Position
	local rangeSquared = tower.Range ^ 2

	local bestEnemy = nil
	local bestMetric = -1
    local index = nil

	for id, enemy in enemies do
		if not enemy.Position then
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
                    index = id
				end
			elseif targetingMode == "Last" then
				-- "Last" means the lowest DistanceTravelled
				if bestMetric == -1 or enemy.DistanceTravelled < bestMetric then
					bestMetric = enemy.DistanceTravelled
					bestEnemy = enemy
                    index = id
				end
			elseif targetingMode == "Strongest" then
				-- "Strongest" looks at enemy health
				if enemy.Health > bestMetric then
					bestMetric = enemy.Health
					bestEnemy = enemy
                    index = id
				end
			end
		end
	end

	return bestEnemy, index -- Returns the enemy data object (or nil if none in range)
end

function TowerService.SpawnTower(towerId: string, cf: CFrame)
	local newTower: Tower = {
		Name = "Test",
		Id = towerId,
		Damage = 2,
		Rate = 1,
		Range = 6,
		Position = cf.Position,
		TargetMode = "First",
		LastDamage = os.clock(),
	}

	table.insert(towers, newTower)

	TowerPackets.packets.spawnTower.sendToAll({
		towerId = towerId,
		cf = cf,
	})
end

function TowerService.Init()
	RunService.PostSimulation:Connect(function(_: number)
		local enemies = EnemyService.GetEnemies()

		for _, tower in towers do
			if os.clock() - tower.LastDamage < tower.Rate then
				continue
			end

			local target, uniqueId = getTarget(enemies, tower)

			if not target then
				continue
			end

            target.Health -= tower.Damage

            if target.Health <= 0 then
                print(target, uniqueId)
                EnemyService.KillEnemy(uniqueId)
            end

			tower.LastDamage = os.clock()
		end
	end)
end

return TowerService
