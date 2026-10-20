local ServerScriptService = game:GetService("ServerScriptService")

local EnemyService = require(ServerScriptService.server.features.enemy.EnemyService)

return function(__context: any, towerId: string): string
    EnemyService.SpawnEnemy()
    return towerId .. " spawned successfully"
end
