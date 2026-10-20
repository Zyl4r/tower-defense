local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PathUtils = require(ReplicatedStorage.shared.core.helpers.PathSpline)
local EnemyPackets = require(ReplicatedStorage.shared.features.enemy.EnemyPackets)

local mapPath = PathUtils.new(workspace.Map.Path.Waypoints)
const mapLength = mapPath:CalculateTotalLength()

export type Enemy = {
    Name: string,
    Health: number,
    MaxHealth: number,
    WalkSpeed: number,
    Id: string,
    SpawnedAt: number, --time
    DistanceTravelled: number,
    Position: Vector3
}

local enemies = {}

local EnemyService = {}

function EnemyService.SpawnEnemy()
    local newEnemy: Enemy = {
        Name = "Test",
        Health = 100,
        MaxHealth = 100,
        WalkSpeed = 16,
        Id = "test",

        SpawnedAt = workspace:GetServerTimeNow(),
        DistanceTravelled = 0,
        Position = mapPath:GetPosition(0)
    }

    table.insert(enemies, newEnemy)
    EnemyPackets.packets.spawnEnemy.sendToAll(newEnemy)
end

function EnemyService.Init()
    RunService.PostSimulation:Connect(function(dt: number)
        for i, enemy: Enemy in enemies do
            local travelDistance = enemy.WalkSpeed * dt
            enemy.DistanceTravelled += travelDistance

            local alpha = math.clamp(enemy.DistanceTravelled / mapLength, 0, 1)

            if alpha >= 1 then
                print("enemy " .. enemy.Name .. " reached end")
                table.remove(enemies, i)
            end

            enemy.Position = mapPath:GetPosition(alpha)
        end
    end)
end

return EnemyService
