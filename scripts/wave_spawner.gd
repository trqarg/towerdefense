extends Node

signal wave_started(wave_number: int)
signal wave_finished(wave_number: int)
signal all_waves_complete
signal enemy_died(gold_reward: int)
signal enemy_reached_end

@export var enemy_scene: PackedScene
var path_node: Path2D

var waves: Array = []

var current_wave: int = -1
var enemies_alive: int = 0
var spawning: bool = false
var spawn_queue: Array = []  # Flattened list of enemy configs to spawn
var spawn_index: int = 0

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.one_shot = true

func start_next_wave() -> void:
	current_wave += 1
	if current_wave >= waves.size():
		all_waves_complete.emit()
		return

	# Build a flat spawn queue from groups, shuffled so types are mixed
	spawn_queue.clear()
	spawn_index = 0
	var wave_data = waves[current_wave]
	for group in wave_data["groups"]:
		for i in group["count"]:
			spawn_queue.append({
				"type": group["type"],
				"health": group["health"],
				"speed": group["speed"],
			})
	spawn_queue.shuffle()

	spawning = true
	wave_started.emit(current_wave + 1)
	_spawn_next_enemy()

# Gold reward per enemy type
const TYPE_GOLD := {
	"grunt": 10,
	"runner": 12,
	"brute": 20,
	"shaman": 25,
	"warlord": 50,
}

func _spawn_next_enemy() -> void:
	if spawn_index >= spawn_queue.size():
		spawning = false
		return

	var wave_data = waves[current_wave]
	var entry = spawn_queue[spawn_index]
	var diff = GameState.difficulty

	var enemy = enemy_scene.instantiate()
	enemy.configure_type(entry["type"])
	enemy.max_health = entry["health"] * GameState.DIFFICULTY_HEALTH_MULT[diff]
	enemy.speed = entry["speed"] * GameState.DIFFICULTY_SPEED_MULT[diff]
	var base_gold = TYPE_GOLD.get(entry["type"], 10)
	enemy.gold_reward = int(base_gold * GameState.DIFFICULTY_GOLD_MULT[diff])

	path_node.add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)

	spawn_index += 1
	enemies_alive += 1

	if spawn_index < spawn_queue.size():
		spawn_timer.wait_time = wave_data["spawn_interval"]
		spawn_timer.start()
	else:
		spawning = false

func _on_spawn_timer_timeout() -> void:
	if spawning:
		_spawn_next_enemy()

func _on_enemy_died(enemy: PathFollow2D) -> void:
	enemies_alive -= 1
	enemy_died.emit(enemy.gold_reward)
	_check_wave_complete()

func _on_enemy_reached_end(enemy: PathFollow2D) -> void:
	enemies_alive -= 1
	enemy_reached_end.emit()
	_check_wave_complete()

func _check_wave_complete() -> void:
	if not spawning and enemies_alive <= 0:
		wave_finished.emit(current_wave + 1)
