extends Node2D

const DAMAGE := 120.0
const RADIUS := 100.0
const DURATION := 1.8
const PARTICLE_COUNT := 14

var elapsed: float = 0.0
var particles: Array = []

func _ready() -> void:
	_deal_damage()
	_create_particles()

func _deal_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= RADIUS:
				enemy.take_damage(DAMAGE)

func _create_particles() -> void:
	for i in PARTICLE_COUNT:
		var p = Polygon2D.new()
		# Flame shape
		p.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(5, -2), Vector2(3, 6), Vector2(-3, 6), Vector2(-5, -2)
		])
		p.color = Color(1.0, randf_range(0.25, 0.65), 0.0, 1.0)
		var angle = randf() * TAU
		var dist = randf() * RADIUS
		var target_x = cos(angle) * dist
		var target_y = sin(angle) * dist
		p.position = Vector2(target_x, -180 - randf() * 80)
		p.scale = Vector2.ONE * randf_range(0.8, 1.6)
		p.rotation = randf() * TAU
		add_child(p)
		particles.append({
			"node": p,
			"target_y": target_y,
			"speed": randf_range(350, 550),
		})
	# Ground scorch circle
	var scorch = Polygon2D.new()
	scorch.polygon = _make_circle(RADIUS, 32)
	scorch.color = Color(0.3, 0.1, 0.0, 0.3)
	scorch.z_index = -1
	add_child(scorch)
	particles.append({"node": scorch, "target_y": 0.0, "speed": 0.0, "is_scorch": true})

func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in segments:
		var a = TAU * i / segments
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

func _process(delta: float) -> void:
	elapsed += delta
	for data in particles:
		if data.get("is_scorch", false):
			if elapsed > DURATION * 0.5:
				data["node"].color.a -= delta * 0.8
			continue
		var p = data["node"] as Polygon2D
		if p.position.y < data["target_y"]:
			p.position.y += data["speed"] * delta
		else:
			p.color.a -= delta * 2.5
			p.scale *= (1.0 - delta * 2.0)
	if elapsed > DURATION:
		queue_free()
