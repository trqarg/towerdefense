extends Area2D

var target: Node2D = null
var damage: float = 10.0
var speed: float = 400.0
var splash_radius: float = 0.0
var slow_amount: float = 0.0
var slow_duration: float = 0.0
var proj_type: String = "basic"

var trail_timer: float = 0.0

func _ready() -> void:
	# Remove default Body node (will be rebuilt per type)
	for child in get_children():
		if child is Polygon2D:
			child.queue_free()
	_build_visuals()

func _build_visuals() -> void:
	match proj_type:
		"basic":
			_build_arrow()
			speed = 450.0
		"sniper":
			_build_bolt()
			speed = 700.0
		"cannon":
			_build_cannonball()
			speed = 280.0
		"frost":
			_build_ice_shard()
			speed = 350.0
		_:
			_build_arrow()
			speed = 400.0

func _build_arrow() -> void:
	# Wooden shaft
	var shaft = Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-10, -1.5), Vector2(4, -1.5), Vector2(4, 1.5), Vector2(-10, 1.5)
	])
	shaft.color = Color(0.6, 0.42, 0.15)
	add_child(shaft)
	# Metal arrowhead
	var head = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(4, -4), Vector2(14, 0), Vector2(4, 4)
	])
	head.color = Color(0.7, 0.72, 0.75)
	add_child(head)
	# Fletching feathers
	var fletch_top = Polygon2D.new()
	fletch_top.polygon = PackedVector2Array([
		Vector2(-10, -1), Vector2(-6, -1), Vector2(-6, -5), Vector2(-12, -2)
	])
	fletch_top.color = Color(0.7, 0.15, 0.1)
	add_child(fletch_top)
	var fletch_bot = Polygon2D.new()
	fletch_bot.polygon = PackedVector2Array([
		Vector2(-10, 1), Vector2(-6, 1), Vector2(-6, 5), Vector2(-12, 2)
	])
	fletch_bot.color = Color(0.7, 0.15, 0.1)
	add_child(fletch_bot)

func _build_bolt() -> void:
	# Long thin steel bolt
	var shaft = Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-14, -1), Vector2(6, -1), Vector2(6, 1), Vector2(-14, 1)
	])
	shaft.color = Color(0.5, 0.52, 0.55)
	add_child(shaft)
	# Sharp pointed tip
	var head = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(6, -3), Vector2(18, 0), Vector2(6, 3)
	])
	head.color = Color(0.8, 0.82, 0.85)
	add_child(head)
	# Small metal fins
	var fin_top = Polygon2D.new()
	fin_top.polygon = PackedVector2Array([
		Vector2(-14, -1), Vector2(-10, -1), Vector2(-10, -4), Vector2(-15, -1)
	])
	fin_top.color = Color(0.35, 0.38, 0.4)
	add_child(fin_top)
	var fin_bot = Polygon2D.new()
	fin_bot.polygon = PackedVector2Array([
		Vector2(-14, 1), Vector2(-10, 1), Vector2(-10, 4), Vector2(-15, 1)
	])
	fin_bot.color = Color(0.35, 0.38, 0.4)
	add_child(fin_bot)

func _build_cannonball() -> void:
	# Dark iron ball (approximated with octagon)
	var ball = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in 8:
		var angle = TAU * i / 8.0
		pts.append(Vector2(cos(angle) * 7, sin(angle) * 7))
	ball.polygon = pts
	ball.color = Color(0.2, 0.2, 0.22)
	add_child(ball)
	# Highlight
	var highlight = Polygon2D.new()
	var hpts = PackedVector2Array()
	for i in 6:
		var angle = TAU * i / 6.0 - 0.5
		hpts.append(Vector2(cos(angle) * 3 - 1, sin(angle) * 3 - 2))
	highlight.polygon = hpts
	highlight.color = Color(0.45, 0.45, 0.5, 0.5)
	add_child(highlight)
	# Smoke trail particle (small gray circle behind)
	var smoke = Polygon2D.new()
	var spts = PackedVector2Array()
	for i in 6:
		var angle = TAU * i / 6.0
		spts.append(Vector2(cos(angle) * 4 - 10, sin(angle) * 4))
	smoke.polygon = spts
	smoke.color = Color(0.5, 0.5, 0.5, 0.3)
	smoke.name = "Smoke"
	add_child(smoke)

func _build_ice_shard() -> void:
	# Crystal ice shard - diamond shape
	var shard = Polygon2D.new()
	shard.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(0, -5), Vector2(12, 0), Vector2(0, 5)
	])
	shard.color = Color(0.4, 0.8, 1.0, 0.9)
	add_child(shard)
	# Inner glow
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(1, -2.5), Vector2(8, 0), Vector2(1, 2.5)
	])
	glow.color = Color(0.7, 0.95, 1.0, 0.7)
	add_child(glow)
	# Sparkle trail
	var trail = Polygon2D.new()
	trail.polygon = PackedVector2Array([
		Vector2(-12, -2), Vector2(-8, 0), Vector2(-12, 2), Vector2(-16, 0)
	])
	trail.color = Color(0.5, 0.85, 1.0, 0.4)
	trail.name = "Trail"
	add_child(trail)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var direction = global_position.direction_to(target.global_position)
	global_position += direction * speed * delta
	rotation = direction.angle()

	# Cannonball smoke fading
	if proj_type == "cannon":
		var smoke = get_node_or_null("Smoke")
		if smoke:
			smoke.color.a = maxf(0.0, smoke.color.a - delta * 0.8)

	# Frost trail sparkle
	if proj_type == "frost":
		trail_timer += delta * 8.0
		var trail = get_node_or_null("Trail")
		if trail:
			trail.color.a = 0.2 + sin(trail_timer) * 0.2

	if global_position.distance_to(target.global_position) < 10.0:
		_hit()
		# Cannonball explosion effect
		if proj_type == "cannon" and splash_radius > 0:
			_spawn_explosion()
		queue_free()

func _hit() -> void:
	if splash_radius > 0.0:
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

func _spawn_explosion() -> void:
	# Create a brief explosion visual at impact point
	var explosion = Node2D.new()
	explosion.global_position = global_position
	get_tree().current_scene.get_node("GameMap/Projectiles").add_child(explosion)

	# Orange flash circle
	var flash = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in 12:
		var angle = TAU * i / 12.0
		pts.append(Vector2(cos(angle) * splash_radius * 0.4, sin(angle) * splash_radius * 0.4))
	flash.polygon = pts
	flash.color = Color(1.0, 0.6, 0.1, 0.6)
	explosion.add_child(flash)

	# Smoke ring
	var smoke_ring = Polygon2D.new()
	var spts = PackedVector2Array()
	for i in 12:
		var angle = TAU * i / 12.0
		spts.append(Vector2(cos(angle) * splash_radius * 0.3, sin(angle) * splash_radius * 0.3))
	smoke_ring.polygon = spts
	smoke_ring.color = Color(0.4, 0.4, 0.4, 0.4)
	explosion.add_child(smoke_ring)

	# Fade out and remove
	var tween = explosion.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.parallel().tween_property(smoke_ring, "color:a", 0.0, 0.4)
	tween.parallel().tween_property(flash, "scale", Vector2(1.8, 1.8), 0.3)
	tween.parallel().tween_property(smoke_ring, "scale", Vector2(2.0, 2.0), 0.4)
	tween.tween_callback(explosion.queue_free)
