local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EnemyPackets = require(ReplicatedStorage.shared.features.enemy.EnemyPackets)
local PathUtils = require(ReplicatedStorage.shared.core.helpers.PathSpline)

local waypointsFolder = workspace.Map.Path:WaitForChild("Waypoints")

-- FIXED: Change this to a dictionary structure keyed by unique enemy IDs
local enemies = {}

local EnemyController = {}

function EnemyController.GetEnemies()
	return enemies
end

function EnemyController.Init()
	local mapPath = PathUtils.new(waypointsFolder)
	local mapLength = mapPath:CalculateTotalLength()

	EnemyPackets.packets.spawnEnemy.listen(function(data)
		local id = data.UniqueId

		if not id then
			return
		end

		local newEnemyRender = Instance.new("Part")
		newEnemyRender.Name = data.UniqueId
		newEnemyRender.Anchored = true
		newEnemyRender.Size = Vector3.one
		newEnemyRender.Parent = workspace.RenderedEnemies

		data.RenderedModel = newEnemyRender
		local rng = Random.new()
		data.SideOffset = rng:NextNumber(-0.5, 0.5)

		enemies[id] = data
	end)

	EnemyPackets.packets.killEnemy.listen(function(id: string)
		local enemy = enemies[id]

		if not enemy then
			return
		end

		task.delay(0.05, function()
			if enemy and enemy.RenderedModel then
				enemy.RenderedModel:Destroy()
			end

			enemies[id] = nil
		end)
	end)

	RunService.PreRender:Connect(function(dt: number)
		for _, enemy in enemies do
			local renderedEnemy = enemy.RenderedModel

			if not renderedEnemy then
				continue
			end

			enemy.DistanceTravelled += enemy.WalkSpeed * dt

			local alpha = math.clamp(enemy.DistanceTravelled / mapLength, 0, 1)

			if alpha >= 1 then
				if enemy.RenderedModel then
					enemy.RenderedModel:Destroy()
				end

				enemies[enemy.UniqueId] = nil
				continue
			end

			local currentPos = mapPath:GetPosition(alpha)
			local lookAheadPos = mapPath:GetPosition(alpha + 0.001)

			local targetCFrame = CFrame.lookAt(currentPos, lookAheadPos)
			local offsetPosition = currentPos + (targetCFrame.RightVector * enemy.SideOffset)

			local currentCFrame = renderedEnemy.CFrame
			local smoothRotation = currentCFrame.Rotation:Lerp(targetCFrame.Rotation, math.clamp(15 * dt, 0, 1))

			renderedEnemy.CFrame = CFrame.new(offsetPosition) * smoothRotation
			enemy.Position = currentPos
		end
	end)
end

return EnemyController
