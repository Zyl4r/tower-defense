--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local EnemyController = require(StarterPlayer.StarterPlayerScripts.client.features.enemy.EnemyController)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local TowerController = require(StarterPlayer.StarterPlayerScripts.client.features.placement.PlacementController)

TowerController.Init()
EnemyController.Init()
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
