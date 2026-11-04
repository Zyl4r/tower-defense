local ServerScriptService = game:GetService("ServerScriptService")

local EnemyService = require(ServerScriptService.server.features.enemy.EnemyService)

return function(__context: any, _towerId: string, amount: number, interval: number?): string
    for _ = 1, amount do
        EnemyService.SpawnEnemy()
        task.wait(interval or 0.1)
    end

    return "Spawned successfully"
end
