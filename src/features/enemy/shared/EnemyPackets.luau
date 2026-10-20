local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Packages.ByteNet)

return ByteNet.defineNamespace("enemyPackets", function()
	return {
		packets = {
			spawnEnemy = ByteNet.definePacket({
				value = ByteNet.struct({
					Name = ByteNet.string,
					Health = ByteNet.uint32,
					MaxHealth = ByteNet.uint32,
					WalkSpeed = ByteNet.uint8,
					Id = ByteNet.string,

					SpawnedAt = ByteNet.uint16,
					DistanceTravelled = ByteNet.uint16,
                    Position = ByteNet.vec3
				}),
			}),
		},
	}
end)
