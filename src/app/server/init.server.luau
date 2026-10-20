--!nonstrict
local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService.ServerPackages.Cmdr)
local EnemyService = require(ServerScriptService.server.features.enemy.EnemyService)
local TowerService = require(ServerScriptService.server.features.placement.PlacementService)

EnemyService.Init()
TowerService.Init()
Cmdr.Registry:RegisterDefaultCommands()
Cmdr.Registry:RegisterCommandsIn(ServerScriptService.server.core.commands)
