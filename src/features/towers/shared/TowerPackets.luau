local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Packages.ByteNet)

return ByteNet.defineNamespace("towerPackets", function()
	return {
		packets = {
			placeTower = ByteNet.definePacket({
				value = ByteNet.struct({
                    towerId = ByteNet.string,
                    cf = ByteNet.cframe
                }),
			}),
		}
	}
end)
