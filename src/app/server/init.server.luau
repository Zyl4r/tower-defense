--!nonstrict
local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService.ServerPackages.Cmdr)
local TowerService = require(ServerScriptService.server.features.placement.PlacementService)

TowerService.Init()
Cmdr.Registry:RegisterDefaultCommands()
Cmdr.Registry:RegisterCommandsIn(ServerScriptService.server.core.commands)
