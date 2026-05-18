extends Node

var selected_level: int = 0
var difficulty: int = 1  # 0=Easy, 1=Normal, 2=Hard
var levels: Array = []
var level_stars: Dictionary = {}  # {level_index: star_count}

const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]
const DIFFICULTY_HEALTH_MULT := [0.7, 1.0, 1.5]
const DIFFICULTY_SPEED_MULT := [0.8, 1.0, 1.2]
const DIFFICULTY_GOLD_MULT := [1.5, 1.0, 0.7]

func set_level_stars(level_index: int, stars: int) -> void:
	if stars > level_stars.get(level_index, 0):
		level_stars[level_index] = stars

func _ready() -> void:
	levels = [
		# ── Level 1: Grasslands ────────────────────────────
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
			"terrain": {
				Vector2i(2, 6): "mud", Vector2i(3, 6): "mud", Vector2i(4, 6): "mud",
				Vector2i(5, 6): "mud", Vector2i(6, 6): "mud",
				Vector2i(10, 5): "water", Vector2i(10, 4): "water", Vector2i(10, 3): "water",
				Vector2i(13, 8): "mud", Vector2i(12, 8): "mud", Vector2i(11, 8): "mud",
				Vector2i(8, 10): "water", Vector2i(9, 10): "water",
			},
			"waves": [
				{
					"groups": [{"type": "grunt", "count": 5, "health": 50.0, "speed": 100.0}],
					"spawn_interval": 1.0,
				},
				{
					"groups": [
						{"type": "grunt", "count": 5, "health": 60.0, "speed": 110.0},
						{"type": "runner", "count": 3, "health": 35.0, "speed": 170.0},
					],
					"spawn_interval": 0.9,
				},
				{
					"groups": [
						{"type": "grunt", "count": 6, "health": 75.0, "speed": 115.0},
						{"type": "runner", "count": 4, "health": 45.0, "speed": 180.0},
						{"type": "brute", "count": 2, "health": 180.0, "speed": 65.0},
					],
					"spawn_interval": 0.8,
				},
				{
					"groups": [
						{"type": "grunt", "count": 5, "health": 85.0, "speed": 120.0},
						{"type": "runner", "count": 5, "health": 55.0, "speed": 190.0},
						{"type": "brute", "count": 3, "health": 220.0, "speed": 70.0},
						{"type": "shaman", "count": 2, "health": 100.0, "speed": 90.0},
					],
					"spawn_interval": 0.7,
				},
				{
					"groups": [
						{"type": "grunt", "count": 6, "health": 100.0, "speed": 130.0},
						{"type": "runner", "count": 5, "health": 65.0, "speed": 200.0},
						{"type": "brute", "count": 4, "health": 280.0, "speed": 75.0},
						{"type": "shaman", "count": 3, "health": 120.0, "speed": 95.0},
						{"type": "warlord", "count": 1, "health": 500.0, "speed": 55.0},
					],
					"spawn_interval": 0.6,
				},
			],
		},
		# ── Level 2: Serpent River ──────────────────────────
		# S-shaped curves with river crossings
		{
			"name": "Serpent River",
			"grid_width": 18,
			"grid_height": 12,
			"start_gold": 120,
			"start_lives": 18,
			"path": [
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
				Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1),
				Vector2i(8, 2), Vector2i(8, 3),
				Vector2i(7, 3), Vector2i(6, 3), Vector2i(5, 3), Vector2i(4, 3),
				Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3),
				Vector2i(1, 4), Vector2i(1, 5),
				Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
				Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5),
				Vector2i(10, 6), Vector2i(10, 7),
				Vector2i(9, 7), Vector2i(8, 7), Vector2i(7, 7), Vector2i(6, 7),
				Vector2i(5, 7), Vector2i(4, 7), Vector2i(3, 7),
				Vector2i(3, 8), Vector2i(3, 9),
				Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9),
				Vector2i(9, 9), Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 9),
				Vector2i(13, 9), Vector2i(14, 9), Vector2i(15, 9), Vector2i(16, 9), Vector2i(17, 9),
			],
			"terrain": {
				Vector2i(8, 2): "water", Vector2i(8, 3): "water",
				Vector2i(1, 4): "water", Vector2i(1, 5): "water",
				Vector2i(10, 6): "water", Vector2i(10, 7): "water",
				Vector2i(3, 8): "water", Vector2i(3, 9): "water",
				Vector2i(5, 5): "mud", Vector2i(6, 5): "mud", Vector2i(7, 5): "mud",
				Vector2i(5, 7): "mud", Vector2i(6, 7): "mud", Vector2i(7, 7): "mud",
			},
			"waves": [
				{
					"groups": [{"type": "grunt", "count": 6, "health": 60.0, "speed": 105.0}],
					"spawn_interval": 1.0,
				},
				{
					"groups": [
						{"type": "grunt", "count": 5, "health": 70.0, "speed": 115.0},
						{"type": "runner", "count": 4, "health": 40.0, "speed": 180.0},
					],
					"spawn_interval": 0.9,
				},
				{
					"groups": [
						{"type": "grunt", "count": 6, "health": 85.0, "speed": 120.0},
						{"type": "runner", "count": 5, "health": 50.0, "speed": 190.0},
						{"type": "brute", "count": 2, "health": 200.0, "speed": 70.0},
					],
					"spawn_interval": 0.85,
				},
				{
					"groups": [
						{"type": "grunt", "count": 6, "health": 95.0, "speed": 125.0},
						{"type": "runner", "count": 6, "health": 60.0, "speed": 200.0},
						{"type": "brute", "count": 3, "health": 250.0, "speed": 72.0},
						{"type": "shaman", "count": 2, "health": 110.0, "speed": 95.0},
					],
					"spawn_interval": 0.75,
				},
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 110.0, "speed": 130.0},
						{"type": "runner", "count": 6, "health": 70.0, "speed": 210.0},
						{"type": "brute", "count": 4, "health": 300.0, "speed": 75.0},
						{"type": "shaman", "count": 3, "health": 130.0, "speed": 100.0},
					],
					"spawn_interval": 0.65,
				},
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 130.0, "speed": 140.0},
						{"type": "brute", "count": 5, "health": 350.0, "speed": 78.0},
						{"type": "shaman", "count": 4, "health": 150.0, "speed": 105.0},
						{"type": "warlord", "count": 2, "health": 600.0, "speed": 58.0},
					],
					"spawn_interval": 0.55,
				},
			],
		},
		# ── Level 3: The Gauntlet ──────────────────────────
		# Tight zigzag across the full width
		{
			"name": "The Gauntlet",
			"grid_width": 18,
			"grid_height": 12,
			"start_gold": 140,
			"start_lives": 15,
			"path": [
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
				Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1),
				Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1), Vector2i(13, 1),
				Vector2i(14, 1), Vector2i(15, 1), Vector2i(16, 1),
				Vector2i(16, 2), Vector2i(16, 3),
				Vector2i(15, 3), Vector2i(14, 3), Vector2i(13, 3), Vector2i(12, 3),
				Vector2i(11, 3), Vector2i(10, 3), Vector2i(9, 3), Vector2i(8, 3),
				Vector2i(7, 3), Vector2i(6, 3), Vector2i(5, 3), Vector2i(4, 3),
				Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3),
				Vector2i(1, 4), Vector2i(1, 5),
				Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
				Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5),
				Vector2i(11, 5), Vector2i(12, 5), Vector2i(13, 5), Vector2i(14, 5),
				Vector2i(15, 5), Vector2i(16, 5),
				Vector2i(16, 6), Vector2i(16, 7),
				Vector2i(15, 7), Vector2i(14, 7), Vector2i(13, 7), Vector2i(12, 7),
				Vector2i(11, 7), Vector2i(10, 7), Vector2i(9, 7), Vector2i(8, 7),
				Vector2i(7, 7), Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7),
				Vector2i(3, 7), Vector2i(2, 7), Vector2i(1, 7),
				Vector2i(1, 8), Vector2i(1, 9),
				Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9),
				Vector2i(7, 9), Vector2i(8, 9), Vector2i(9, 9), Vector2i(10, 9),
				Vector2i(11, 9), Vector2i(12, 9), Vector2i(13, 9), Vector2i(14, 9),
				Vector2i(15, 9), Vector2i(16, 9), Vector2i(17, 9),
			],
			"terrain": {
				Vector2i(7, 1): "mud", Vector2i(8, 1): "mud", Vector2i(9, 1): "mud",
				Vector2i(7, 3): "mud", Vector2i(8, 3): "mud", Vector2i(9, 3): "mud",
				Vector2i(7, 5): "water", Vector2i(8, 5): "water", Vector2i(9, 5): "water",
				Vector2i(7, 7): "mud", Vector2i(8, 7): "mud", Vector2i(9, 7): "mud",
				Vector2i(7, 9): "water", Vector2i(8, 9): "water", Vector2i(9, 9): "water",
			},
			"waves": [
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 70.0, "speed": 110.0},
						{"type": "runner", "count": 4, "health": 40.0, "speed": 175.0},
					],
					"spawn_interval": 0.9,
				},
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 85.0, "speed": 120.0},
						{"type": "runner", "count": 6, "health": 50.0, "speed": 190.0},
						{"type": "brute", "count": 2, "health": 200.0, "speed": 68.0},
					],
					"spawn_interval": 0.8,
				},
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 100.0, "speed": 130.0},
						{"type": "runner", "count": 6, "health": 60.0, "speed": 200.0},
						{"type": "brute", "count": 3, "health": 260.0, "speed": 72.0},
						{"type": "shaman", "count": 2, "health": 120.0, "speed": 95.0},
					],
					"spawn_interval": 0.75,
				},
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 120.0, "speed": 135.0},
						{"type": "runner", "count": 8, "health": 70.0, "speed": 210.0},
						{"type": "brute", "count": 4, "health": 320.0, "speed": 75.0},
						{"type": "shaman", "count": 3, "health": 140.0, "speed": 100.0},
					],
					"spawn_interval": 0.65,
				},
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 140.0, "speed": 140.0},
						{"type": "runner", "count": 8, "health": 80.0, "speed": 220.0},
						{"type": "brute", "count": 5, "health": 380.0, "speed": 78.0},
						{"type": "shaman", "count": 4, "health": 160.0, "speed": 105.0},
						{"type": "warlord", "count": 1, "health": 700.0, "speed": 60.0},
					],
					"spawn_interval": 0.6,
				},
				{
					"groups": [
						{"type": "runner", "count": 10, "health": 90.0, "speed": 230.0},
						{"type": "brute", "count": 6, "health": 420.0, "speed": 80.0},
						{"type": "shaman", "count": 5, "health": 180.0, "speed": 110.0},
						{"type": "warlord", "count": 2, "health": 800.0, "speed": 62.0},
					],
					"spawn_interval": 0.55,
				},
				{
					"groups": [
						{"type": "brute", "count": 8, "health": 500.0, "speed": 85.0},
						{"type": "shaman", "count": 6, "health": 200.0, "speed": 115.0},
						{"type": "warlord", "count": 3, "health": 900.0, "speed": 65.0},
					],
					"spawn_interval": 0.5,
				},
			],
		},
		# ── Level 4: Frozen Marsh ──────────────────────────
		# Winding path through heavy water/mud terrain
		{
			"name": "Frozen Marsh",
			"grid_width": 18,
			"grid_height": 12,
			"start_gold": 150,
			"start_lives": 15,
			"path": [
				Vector2i(9, 0), Vector2i(9, 1), Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4),
				Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4), Vector2i(14, 4),
				Vector2i(14, 3), Vector2i(14, 2), Vector2i(14, 1),
				Vector2i(15, 1), Vector2i(16, 1),
				Vector2i(16, 2), Vector2i(16, 3), Vector2i(16, 4), Vector2i(16, 5),
				Vector2i(16, 6), Vector2i(16, 7), Vector2i(16, 8),
				Vector2i(15, 8), Vector2i(14, 8), Vector2i(13, 8), Vector2i(12, 8),
				Vector2i(11, 8), Vector2i(10, 8), Vector2i(9, 8), Vector2i(8, 8),
				Vector2i(7, 8), Vector2i(6, 8),
				Vector2i(6, 7), Vector2i(6, 6), Vector2i(6, 5), Vector2i(6, 4), Vector2i(6, 3),
				Vector2i(5, 3), Vector2i(4, 3), Vector2i(3, 3),
				Vector2i(3, 4), Vector2i(3, 5), Vector2i(3, 6), Vector2i(3, 7),
				Vector2i(3, 8), Vector2i(3, 9), Vector2i(3, 10),
				Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10),
				Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10),
				Vector2i(12, 10), Vector2i(13, 10), Vector2i(14, 10), Vector2i(15, 10),
				Vector2i(16, 10), Vector2i(17, 10),
			],
			"terrain": {
				Vector2i(9, 1): "water", Vector2i(9, 2): "water", Vector2i(9, 3): "water",
				Vector2i(16, 4): "water", Vector2i(16, 5): "water", Vector2i(16, 6): "water",
				Vector2i(6, 5): "water", Vector2i(6, 6): "water", Vector2i(6, 7): "water",
				Vector2i(3, 6): "water", Vector2i(3, 7): "water", Vector2i(3, 8): "water",
				Vector2i(10, 8): "mud", Vector2i(11, 8): "mud", Vector2i(12, 8): "mud",
				Vector2i(13, 8): "mud", Vector2i(14, 8): "mud",
				Vector2i(7, 10): "mud", Vector2i(8, 10): "mud", Vector2i(9, 10): "mud",
				Vector2i(10, 10): "mud",
				Vector2i(11, 4): "mud", Vector2i(12, 4): "mud",
			},
			"waves": [
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 80.0, "speed": 115.0},
						{"type": "runner", "count": 5, "health": 50.0, "speed": 185.0},
					],
					"spawn_interval": 0.9,
				},
				{
					"groups": [
						{"type": "grunt", "count": 8, "health": 100.0, "speed": 125.0},
						{"type": "runner", "count": 6, "health": 60.0, "speed": 200.0},
						{"type": "brute", "count": 3, "health": 240.0, "speed": 70.0},
					],
					"spawn_interval": 0.8,
				},
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 120.0, "speed": 130.0},
						{"type": "runner", "count": 8, "health": 70.0, "speed": 210.0},
						{"type": "brute", "count": 4, "health": 300.0, "speed": 75.0},
						{"type": "shaman", "count": 3, "health": 140.0, "speed": 100.0},
					],
					"spawn_interval": 0.7,
				},
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 140.0, "speed": 140.0},
						{"type": "runner", "count": 8, "health": 80.0, "speed": 220.0},
						{"type": "brute", "count": 5, "health": 360.0, "speed": 78.0},
						{"type": "shaman", "count": 4, "health": 160.0, "speed": 105.0},
						{"type": "warlord", "count": 1, "health": 700.0, "speed": 58.0},
					],
					"spawn_interval": 0.6,
				},
				{
					"groups": [
						{"type": "runner", "count": 10, "health": 90.0, "speed": 230.0},
						{"type": "brute", "count": 6, "health": 420.0, "speed": 82.0},
						{"type": "shaman", "count": 5, "health": 180.0, "speed": 110.0},
						{"type": "warlord", "count": 2, "health": 800.0, "speed": 60.0},
					],
					"spawn_interval": 0.55,
				},
				{
					"groups": [
						{"type": "brute", "count": 8, "health": 500.0, "speed": 85.0},
						{"type": "shaman", "count": 6, "health": 220.0, "speed": 115.0},
						{"type": "warlord", "count": 3, "health": 1000.0, "speed": 62.0},
					],
					"spawn_interval": 0.5,
				},
			],
		},
		# ── Level 5: Warlord's Keep ────────────────────────
		# Spiral path inward, longest and hardest
		{
			"name": "Warlord's Keep",
			"grid_width": 18,
			"grid_height": 12,
			"start_gold": 180,
			"start_lives": 12,
			"path": [
				# Outer ring: top right
				Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
				Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0),
				Vector2i(10, 0), Vector2i(11, 0), Vector2i(12, 0), Vector2i(13, 0),
				Vector2i(14, 0), Vector2i(15, 0), Vector2i(16, 0),
				# Outer ring: down right side
				Vector2i(16, 1), Vector2i(16, 2), Vector2i(16, 3), Vector2i(16, 4),
				Vector2i(16, 5), Vector2i(16, 6), Vector2i(16, 7), Vector2i(16, 8),
				Vector2i(16, 9), Vector2i(16, 10),
				# Outer ring: bottom left
				Vector2i(15, 10), Vector2i(14, 10), Vector2i(13, 10), Vector2i(12, 10),
				Vector2i(11, 10), Vector2i(10, 10), Vector2i(9, 10), Vector2i(8, 10),
				Vector2i(7, 10), Vector2i(6, 10), Vector2i(5, 10), Vector2i(4, 10),
				Vector2i(3, 10), Vector2i(2, 10), Vector2i(1, 10),
				# Outer ring: up left side
				Vector2i(1, 9), Vector2i(1, 8), Vector2i(1, 7), Vector2i(1, 6),
				Vector2i(1, 5), Vector2i(1, 4), Vector2i(1, 3), Vector2i(1, 2),
				# Inner ring: top right
				Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
				Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2),
				Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2),
				# Inner ring: down right
				Vector2i(14, 3), Vector2i(14, 4), Vector2i(14, 5),
				Vector2i(14, 6), Vector2i(14, 7), Vector2i(14, 8),
				# Inner ring: bottom left
				Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8), Vector2i(10, 8),
				Vector2i(9, 8), Vector2i(8, 8), Vector2i(7, 8), Vector2i(6, 8),
				Vector2i(5, 8), Vector2i(4, 8), Vector2i(3, 8),
				# Inner ring: up left
				Vector2i(3, 7), Vector2i(3, 6), Vector2i(3, 5), Vector2i(3, 4),
				# Center: right
				Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4),
				Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4),
				# Center: down and left to end
				Vector2i(12, 5), Vector2i(12, 6),
				Vector2i(11, 6), Vector2i(10, 6), Vector2i(9, 6), Vector2i(8, 6),
				Vector2i(7, 6), Vector2i(6, 6), Vector2i(5, 6),
			],
			"terrain": {
				# Water moat at corners
				Vector2i(16, 1): "water", Vector2i(16, 2): "water",
				Vector2i(16, 9): "water", Vector2i(16, 10): "water",
				Vector2i(1, 9): "water", Vector2i(1, 10): "water",
				Vector2i(1, 2): "water", Vector2i(1, 3): "water",
				# Mud in corridors
				Vector2i(7, 0): "mud", Vector2i(8, 0): "mud", Vector2i(9, 0): "mud",
				Vector2i(7, 10): "mud", Vector2i(8, 10): "mud", Vector2i(9, 10): "mud",
				Vector2i(7, 2): "mud", Vector2i(8, 2): "mud", Vector2i(9, 2): "mud",
				Vector2i(7, 8): "mud", Vector2i(8, 8): "mud", Vector2i(9, 8): "mud",
				# Water at center
				Vector2i(8, 4): "water", Vector2i(9, 4): "water",
				Vector2i(8, 6): "water", Vector2i(9, 6): "water",
			},
			"waves": [
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 90.0, "speed": 120.0},
						{"type": "runner", "count": 6, "health": 55.0, "speed": 190.0},
					],
					"spawn_interval": 0.85,
				},
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 110.0, "speed": 130.0},
						{"type": "runner", "count": 8, "health": 65.0, "speed": 200.0},
						{"type": "brute", "count": 3, "health": 250.0, "speed": 72.0},
					],
					"spawn_interval": 0.75,
				},
				{
					"groups": [
						{"type": "grunt", "count": 10, "health": 130.0, "speed": 135.0},
						{"type": "runner", "count": 8, "health": 75.0, "speed": 210.0},
						{"type": "brute", "count": 4, "health": 320.0, "speed": 75.0},
						{"type": "shaman", "count": 3, "health": 150.0, "speed": 100.0},
					],
					"spawn_interval": 0.7,
				},
				{
					"groups": [
						{"type": "grunt", "count": 12, "health": 150.0, "speed": 140.0},
						{"type": "runner", "count": 10, "health": 85.0, "speed": 220.0},
						{"type": "brute", "count": 5, "health": 380.0, "speed": 78.0},
						{"type": "shaman", "count": 4, "health": 170.0, "speed": 105.0},
						{"type": "warlord", "count": 1, "health": 800.0, "speed": 58.0},
					],
					"spawn_interval": 0.6,
				},
				{
					"groups": [
						{"type": "runner", "count": 12, "health": 95.0, "speed": 230.0},
						{"type": "brute", "count": 6, "health": 450.0, "speed": 82.0},
						{"type": "shaman", "count": 5, "health": 200.0, "speed": 110.0},
						{"type": "warlord", "count": 2, "health": 900.0, "speed": 60.0},
					],
					"spawn_interval": 0.55,
				},
				{
					"groups": [
						{"type": "grunt", "count": 15, "health": 180.0, "speed": 150.0},
						{"type": "brute", "count": 8, "health": 520.0, "speed": 85.0},
						{"type": "shaman", "count": 6, "health": 230.0, "speed": 115.0},
						{"type": "warlord", "count": 2, "health": 1000.0, "speed": 62.0},
					],
					"spawn_interval": 0.5,
				},
				{
					"groups": [
						{"type": "runner", "count": 15, "health": 110.0, "speed": 240.0},
						{"type": "brute", "count": 10, "health": 600.0, "speed": 88.0},
						{"type": "shaman", "count": 8, "health": 260.0, "speed": 120.0},
						{"type": "warlord", "count": 3, "health": 1200.0, "speed": 65.0},
					],
					"spawn_interval": 0.45,
				},
				{
					"groups": [
						{"type": "brute", "count": 12, "health": 700.0, "speed": 90.0},
						{"type": "shaman", "count": 10, "health": 300.0, "speed": 125.0},
						{"type": "warlord", "count": 5, "health": 1500.0, "speed": 68.0},
					],
					"spawn_interval": 0.4,
				},
			],
		},
	]
