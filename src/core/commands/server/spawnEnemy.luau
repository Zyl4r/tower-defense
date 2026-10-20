return {
	Name = "spawnEnemy",
	Aliases = { "enemy" },
	Description = "Spawns an enemy in the current map path.",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "id",
			Optional = true,
		},
	},
}
