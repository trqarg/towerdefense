extends Node2D

@export var damage: float = 10.0
@export var fire_rate: float = 1.0
@export var tower_range: float = 150.0
@export var cost: int = 25
@export var splash_radius: float = 0.0
@export var slow_amount: float = 0.0
@export var slow_duration: float = 0.0

var tower_key: String = "basic"
var upgrade_level: int = 1
var total_gold_invested: int = 0

var base_damage: float
var base_fire_rate: float
var base_tower_range: float
var base_splash_radius: float

var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

# Upgrade costs and stat multipliers per level [1, 2, 3]
const UPGRADE_DATA := {
	"basic":  {"costs": [30, 55],  "damage_mult": [1.0, 1.5, 2.2], "range_mult": [1.0, 1.1, 1.25], "rate_mult": [1.0, 1.2, 1.5]},
	"sniper": {"costs": [60, 100], "damage_mult": [1.0, 1.6, 2.5], "range_mult": [1.0, 1.15, 1.3], "rate_mult": [1.0, 1.15, 1.3]},
	"cannon": {"costs": [50, 85],  "damage_mult": [1.0, 1.5, 2.0], "range_mult": [1.0, 1.1, 1.2], "rate_mult": [1.0, 1.2, 1.4], "splash_mult": [1.0, 1.2, 1.5]},
	"frost":  {"costs": [40, 70],  "damage_mult": [1.0, 1.3, 1.8], "range_mult": [1.0, 1.15, 1.3], "rate_mult": [1.0, 1.3, 1.6]},
}

func _ready() -> void:
	add_to_group("towers")
	base_damage = damage
	base_fire_rate = fire_rate
	base_tower_range = tower_range
	base_splash_radius = splash_radius
	$RangeArea/CollisionShape2D.shape = CircleShape2D.new()
	$RangeArea/CollisionShape2D.shape.radius = tower_range
	$FireTimer.wait_time = 1.0 / fire_rate
	$FireTimer.start()

func _process(_delta: float) -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	current_target = _get_closest_enemy()
	if current_target:
		var angle = global_position.angle_to_point(current_target.global_position)
		$Sprite2D.rotation = angle + PI

func _get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	return closest

func _on_range_area_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy.is_in_group("enemies"):
		enemies_in_range.append(enemy)

func _on_range_area_area_exited(area: Area2D) -> void:
	var enemy = area.get_parent()
	enemies_in_range.erase(enemy)

func _on_fire_timer_timeout() -> void:
	if current_target and is_instance_valid(current_target):
		_fire()

func _fire() -> void:
	var proj = projectile_scene.instantiate()
	proj.target = current_target
	proj.damage = damage
	proj.splash_radius = splash_radius
	proj.slow_amount = slow_amount
	proj.slow_duration = slow_duration
	var proj_container = get_tree().current_scene.get_node("GameMap/Projectiles")
	proj_container.add_child(proj)
	proj.global_position = global_position

# ── Upgrade system ──────────────────────────────────────

func can_upgrade() -> bool:
	return upgrade_level < 3

func get_upgrade_cost() -> int:
	var data = UPGRADE_DATA.get(tower_key, UPGRADE_DATA["basic"])
	return data["costs"][upgrade_level - 1]

func upgrade() -> void:
	if not can_upgrade():
		return
	var cost_to_upgrade = get_upgrade_cost()
	total_gold_invested += cost_to_upgrade
	upgrade_level += 1
	_apply_upgrade_stats()
	_update_upgrade_visuals()

func _apply_upgrade_stats() -> void:
	var data = UPGRADE_DATA.get(tower_key, UPGRADE_DATA["basic"])
	var lvl_idx = upgrade_level - 1
	damage = base_damage * data["damage_mult"][lvl_idx]
	fire_rate = base_fire_rate * data["rate_mult"][lvl_idx]
	tower_range = base_tower_range * data["range_mult"][lvl_idx]
	if data.has("splash_mult"):
		splash_radius = base_splash_radius * data["splash_mult"][lvl_idx]
	$RangeArea/CollisionShape2D.shape.radius = tower_range
	$FireTimer.wait_time = 1.0 / fire_rate

func _update_upgrade_visuals() -> void:
	var scale_factor = 1.0 + (upgrade_level - 1) * 0.15
	$Sprite2D.scale = Vector2(scale_factor, scale_factor)
	# Add level indicator dots
	for child in $Sprite2D.get_children():
		if child.name.begins_with("LevelDot"):
			child.queue_free()
	for i in upgrade_level:
		var dot = Polygon2D.new()
		dot.name = "LevelDot%d" % i
		dot.polygon = PackedVector2Array([
			Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)
		])
		dot.color = Color(1.0, 0.9, 0.2)
		dot.position = Vector2(-8 + i * 8, 10)
		$Sprite2D.add_child(dot)

func get_sell_value() -> int:
	return int(total_gold_invested * 0.7)

func get_info_text() -> String:
	var level_text = "Lv.%d" % upgrade_level
	var dmg_text = "DMG:%.0f" % damage
	var rng_text = "RNG:%.0f" % tower_range
	return "%s %s | %s | %s" % [tower_key.capitalize(), level_text, dmg_text, rng_text]
