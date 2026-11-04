return {
	Name = "spawnEnemies",
	Aliases = { "enemies" },
	Description = "Spawns the specified amount of enemies in the current map path.",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "id",
		},
        {
            Type = "number",
            Name = "amount",
        },
        {
            Type = "number",
            Name = "interval",
            Optional = true,
        }
	},
}
