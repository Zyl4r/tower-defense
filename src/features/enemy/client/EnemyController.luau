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
	-- FIXED: Changed 'const' javascript typo to local syntax
	local mapLength = mapPath:CalculateTotalLength()

	EnemyPackets.packets.spawnEnemy.listen(function(data)
		-- Ensure your server is providing a unique identifier inside data (e.g. data.Id)
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

		-- Store directly under its unique identifier key
		enemies[id] = data
	end)

	-- FIXED: Server should send the unique ID string instead of a volatile array index
	EnemyPackets.packets.killEnemy.listen(function(id: string)
		local enemy = enemies[id]

        print(enemies, enemy, id)

		if not enemy then
			return
		end

		if enemy.Health > 0 then
            print('sync waitin')
			repeat
				task.wait()
				enemy = enemies[id]
			until not enemy or enemy.Health <= 0
		end

        print('hey u gotta kill')
		-- Safe double-check clean up  
		if enemy and enemy.RenderedModel then
            print('hi')
			enemy.RenderedModel:Destroy()
		end

		-- Wipe out the dictionary reference cleanly without disrupting anyone else
		enemies[id] = nil
	end)

	RunService.PreRender:Connect(function(dt: number)
		for _, enemy in enemies do
			local renderedEnemy = enemy.RenderedModel
			if not renderedEnemy then
				continue
			end

			enemy.DistanceTravelled += enemy.WalkSpeed * dt

			local alpha = math.clamp(enemy.DistanceTravelled / mapLength, 0, 1)

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
