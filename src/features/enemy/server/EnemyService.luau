export type Enemy = {
    Name: string,
    Health: number,
    MaxHealth: number,
    WalkSpeed: number,
    Id: string
}

local EnemyService = {}
EnemyService.Enemies = {}

function EnemyService.SpawnEnemy()
    local newEnemy: Enemy = {
        Name = "Test",
        Health = 100,
        MaxHealth = 100,
        WalkSpeed = 16,
        Id = "test"
    }
end

return EnemyService
