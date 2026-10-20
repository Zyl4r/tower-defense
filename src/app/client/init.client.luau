--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local EnemyController = require(StarterPlayer.StarterPlayerScripts.client.features.enemy.EnemyController)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local PlacementController = require(StarterPlayer.StarterPlayerScripts.client.features.placement.PlacementController)

PlacementController.Init()
EnemyController.Init()
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
