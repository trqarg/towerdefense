extends Node2D

@export var damage: float = 10.0
@export var fire_rate: float = 1.0
@export var tower_range: float = 150.0
@export var cost: int = 25
@export var splash_radius: float = 0.0
@export var slow_amount: float = 0.0
@export var slow_duration: float = 0.0

var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

func _ready() -> void:
	add_to_group("towers")
	$RangeArea/CollisionShape2D.shape = CircleShape2D.new()
	$RangeArea/CollisionShape2D.shape.radius = tower_range
	$FireTimer.wait_time = 1.0 / fire_rate
	$FireTimer.start()

func _process(_delta: float) -> void:
	# Clean up dead references
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))

	# Pick closest target
	current_target = _get_closest_enemy()

	# Rotate turret toward target
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
