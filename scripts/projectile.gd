extends Area2D

var target: Node2D = null
var damage: float = 10.0
var speed: float = 400.0
var splash_radius: float = 0.0
var slow_amount: float = 0.0
var slow_duration: float = 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var direction := global_position.direction_to(target.global_position)
	global_position += direction * speed * delta
	rotation = direction.angle()

	if global_position.distance_to(target.global_position) < 10.0:
		_hit()
		queue_free()

func _hit() -> void:
	if splash_radius > 0.0:
		# AoE damage to all enemies in splash radius
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy):
				var dist = global_position.distance_to(enemy.global_position)
				if dist <= splash_radius:
					enemy.take_damage(damage)
					if slow_amount > 0.0:
						enemy.apply_slow(slow_amount, slow_duration)
	else:
		if is_instance_valid(target):
			target.take_damage(damage)
			if slow_amount > 0.0:
				target.apply_slow(slow_amount, slow_duration)
