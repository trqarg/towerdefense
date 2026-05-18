class_name LevelData

static func get_levels() -> Array:
	return [
		{
			"name": "Grasslands",
			"grid_width": 18,
			"grid_height": 12,
			"start_gold": 100,
			"start_lives": 20,
			"path": [
				Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
				Vector2i(5, 3), Vector2i(5, 4),
				Vector2i(4, 4), Vector2i(3, 4), Vector2i(2, 4), Vector2i(1, 4),
				Vector2i(1, 5), Vector2i(1, 6),
				Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6),
				Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6), Vector2i(10, 6),
				Vector2i(10, 5), Vector2i(10, 4), Vector2i(10, 3),
				Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3), Vector2i(14, 3),
				Vector2i(14, 4), Vector2i(14, 5), Vector2i(14, 6), Vector2i(14, 7), Vector2i(14, 8),
				Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8), Vector2i(10, 8), Vector2i(9, 8),
				Vector2i(8, 8), Vector2i(7, 8),
				Vector2i(7, 9), Vector2i(7, 10),
				Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10),
				Vector2i(12, 10), Vector2i(13, 10), Vector2i(14, 10), Vector2i(15, 10),
				Vector2i(16, 10), Vector2i(17, 10),
			],
			"waves": [
				{"count": 5, "speed": 100.0, "health": 50.0, "spawn_interval": 1.0},
				{"count": 8, "speed": 110.0, "health": 60.0, "spawn_interval": 0.9},
				{"count": 10, "speed": 120.0, "health": 75.0, "spawn_interval": 0.8},
				{"count": 12, "speed": 130.0, "health": 90.0, "spawn_interval": 0.7},
				{"count": 15, "speed": 150.0, "health": 120.0, "spawn_interval": 0.6},
			],
		},
	]
