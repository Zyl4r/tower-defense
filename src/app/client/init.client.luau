--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local EnemyController = require(StarterPlayer.StarterPlayerScripts.client.features.enemy.EnemyController)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local PlacementController = require(StarterPlayer.StarterPlayerScripts.client.features.placement.PlacementController)
local TowerController = require(StarterPlayer.StarterPlayerScripts.client.features.towers.TowerController)

PlacementController.Init()
EnemyController.Init()
TowerController.Init()
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
