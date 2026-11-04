local HttpService = game:GetService("HttpService")
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
    UniqueId: string,
    SpawnedAt: number, --time
    DistanceTravelled: number,
    Position: Vector3
}

local enemies = {}

local EnemyService = {}

function EnemyService.GetEnemies()
    return enemies
end

function EnemyService.KillEnemy(uniqueId: string)
    local enemy = enemies[uniqueId]

    if not enemy then
        return
    end

    EnemyPackets.packets.killEnemy.sendToAll(uniqueId)
    
    enemies[uniqueId] = nil
end

function EnemyService.SpawnEnemy()
    local uniqueId = "enemy_" .. HttpService:GenerateGUID(false)
    local newEnemy: Enemy = {
        Name = "Test",
        Health = 6,
        MaxHealth = 6,
        WalkSpeed = 3,
        Id = "test",
        UniqueId = uniqueId,

        SpawnedAt = workspace:GetServerTimeNow(),
        DistanceTravelled = 0,
        Position = mapPath:GetPosition(0)
    }

    enemies[uniqueId] = newEnemy
    EnemyPackets.packets.spawnEnemy.sendToAll(newEnemy)
end

function EnemyService.Init()
    RunService.PostSimulation:Connect(function(dt: number)
        for _, enemy: Enemy in enemies do
            local travelDistance = enemy.WalkSpeed * dt
            enemy.DistanceTravelled += travelDistance

            local alpha = math.clamp(enemy.DistanceTravelled / mapLength, 0, 1)

            if alpha >= 1 then
                print("enemy " .. enemy.Name .. " reached end")
                enemies[enemy.UniqueId] = nil
                continue
            end

            enemy.Position = mapPath:GetPosition(alpha)
        end
    end)
end

return EnemyService
