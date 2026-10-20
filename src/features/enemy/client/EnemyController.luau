
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EnemyPackets = require(ReplicatedStorage.shared.features.enemy.EnemyPackets)
local PathUtils = require(ReplicatedStorage.shared.core.helpers.PathSpline)

local waypointsFolder = workspace.Map.Path:WaitForChild("Waypoints")
local enemies = {}
local renderedEnemies = {}

local EnemyController = {}

function EnemyController.Init()
    local mapPath = PathUtils.new(waypointsFolder)
    const mapLength = mapPath:CalculateTotalLength()

	EnemyPackets.packets.spawnEnemy.listen(function(data)
		local newEnemyRender = Instance.new("Part")
		newEnemyRender.Name = data.Name
		newEnemyRender.Anchored = true
		newEnemyRender.Size = Vector3.one
		newEnemyRender.Parent = workspace.RenderedEnemies

		table.insert(renderedEnemies, newEnemyRender)
		table.insert(enemies, data)
	end)

	RunService.PreRender:Connect(function(dt: number)
		for i, enemy in enemies do
            local renderedEnemy = renderedEnemies[i]
            enemy.DistanceTravelled += enemy.WalkSpeed * dt
            
            local alpha = math.clamp(enemy.DistanceTravelled / mapLength, 0, 1)
            
            local currentPos = mapPath:GetPosition(alpha)
            local lookAheadPos = mapPath:GetPosition(alpha + 0.001)
            
            renderedEnemy.CFrame = CFrame.lookAt(currentPos, lookAheadPos)
		end
	end)
end

return EnemyController
