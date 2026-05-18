extends Node2D

var gold: int = 100
var lives: int = 20
var game_over: bool = false
var wave_active: bool = false
var auto_wave_timer: float = 0.0
const AUTO_WAVE_DELAY: float = 15.0

@onready var hud: CanvasLayer = $HUD
@onready var game_map: Node2D = $GameMap
@onready var wave_spawner: Node = $WaveSpawner

func _ready() -> void:
	var level = GameState.levels[GameState.selected_level]

	game_map.load_level(level)
	game_map.setup()
	wave_spawner.path_node = game_map.get_node("Path2D")
	wave_spawner.waves = level["waves"].duplicate(true)

	gold = level["start_gold"]
	lives = level["start_lives"]

	hud.update_gold(gold)
	hud.update_lives(lives)
	hud.update_wave(0, wave_spawner.waves.size())
	hud.set_next_wave_enabled(true)
	hud.show_banner("Time to Build!")

	# Connect HUD signals
	hud.build_tower_pressed.connect(_on_build_tower_pressed)
	hud.next_wave_pressed.connect(_on_next_wave_pressed)
	hud.tower_upgrade_pressed.connect(_on_tower_upgrade)
	hud.tower_sell_pressed.connect(_on_tower_sell)
	hud.ability_pressed.connect(_on_ability_pressed)

	# Connect game map signals
	game_map.tower_placed.connect(_on_tower_placed)
	game_map.tower_selected.connect(_on_tower_selected)
	game_map.tower_deselected.connect(_on_tower_deselected)
	game_map.tower_sold.connect(_on_tower_sold)
	game_map.ability_used.connect(_on_ability_used)

	# Connect wave spawner signals
	wave_spawner.wave_started.connect(_on_wave_started)
	wave_spawner.wave_finished.connect(_on_wave_finished)
	wave_spawner.all_waves_complete.connect(_on_all_waves_complete)
	wave_spawner.enemy_died.connect(_on_enemy_died)
	wave_spawner.enemy_reached_end.connect(_on_enemy_reached_end)

func _process(delta: float) -> void:
	if auto_wave_timer > 0.0:
		auto_wave_timer -= delta
		var secs = ceili(auto_wave_timer)
		hud.show_banner("Next wave in %d..." % secs)
		if auto_wave_timer <= 0.0:
			auto_wave_timer = 0.0
			_on_next_wave_pressed()

# ── Tower building ───────────────────────────────

func _on_build_tower_pressed(tower_key: String) -> void:
	if game_over or wave_active:
		return
	var tcost = hud.tower_data[tower_key]["cost"]
	if gold >= tcost:
		game_map.start_placing(tower_key)

func _on_tower_placed(_grid_pos: Vector2i, tcost: int) -> void:
	gold -= tcost
	hud.update_gold(gold)

# ── Tower selection / upgrade / sell ─────────────

func _on_tower_selected(tower: Node2D) -> void:
	hud.show_tower_menu(tower, gold)

func _on_tower_deselected() -> void:
	hud.hide_tower_menu()

func _on_tower_upgrade() -> void:
	var tower = game_map.selected_tower
	if not tower or not is_instance_valid(tower):
		return
	if not tower.can_upgrade():
		return
	var ucost = tower.get_upgrade_cost()
	if gold < ucost:
		return
	gold -= ucost
	tower.upgrade()
	hud.update_gold(gold)
	hud.show_tower_menu(tower, gold)
	game_map.queue_redraw()  # Refresh range circle

func _on_tower_sell() -> void:
	var tower = game_map.selected_tower
	if not tower or not is_instance_valid(tower):
		return
	game_map.sell_tower(tower)

func _on_tower_sold(_grid_pos: Vector2i, refund: int) -> void:
	gold += refund
	hud.update_gold(gold)

# ── Rain of Fire ability ─────────────────────────

func _on_ability_pressed(ability_name: String) -> void:
	if game_over:
		return
	if ability_name == "rain_of_fire":
		game_map.start_ability_targeting("rain_of_fire")

func _on_ability_used(ability_name: String, world_pos: Vector2) -> void:
	if ability_name == "rain_of_fire":
		var fire = Node2D.new()
		fire.set_script(load("res://scripts/rain_of_fire.gd"))
		$GameMap/Projectiles.add_child(fire)
		fire.position = world_pos
		hud.start_rain_cooldown()

# ── Wave management ──────────────────────────────

func _on_next_wave_pressed() -> void:
	if game_over:
		return
	auto_wave_timer = 0.0
	wave_active = true
	hud.set_next_wave_enabled(false)
	hud.set_building_enabled(false)
	game_map.placing_tower = false
	wave_spawner.start_next_wave()

func _on_wave_started(wave_number: int) -> void:
	hud.update_wave(wave_number, wave_spawner.waves.size())
	hud.show_banner("Wave %d!" % wave_number)

func _on_wave_finished(_wave_number: int) -> void:
	wave_active = false
	if not game_over:
		hud.set_next_wave_enabled(true)
		hud.set_building_enabled(true)
		hud.show_banner("Build Phase")
		if wave_spawner.current_wave + 1 < wave_spawner.waves.size():
			auto_wave_timer = AUTO_WAVE_DELAY

func _on_all_waves_complete() -> void:
	auto_wave_timer = 0.0
	if not game_over:
		var stars = _calculate_stars()
		GameState.set_level_stars(GameState.selected_level, stars)
		hud.show_game_over(true, stars)
		game_over = true

func _calculate_stars() -> int:
	var level = GameState.levels[GameState.selected_level]
	var max_lives = level["start_lives"]
	var ratio = float(lives) / float(max_lives)
	if ratio >= 1.0:
		return 3
	elif ratio > 0.5:
		return 2
	else:
		return 1

func _on_enemy_died(gold_reward: int) -> void:
	gold += gold_reward
	hud.update_gold(gold)

func _on_enemy_reached_end() -> void:
	lives -= 1
	hud.update_lives(lives)
	if lives <= 0:
		game_over = true
		hud.show_game_over(false)
