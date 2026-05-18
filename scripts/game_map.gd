extends Node2D

signal tower_placed(grid_pos: Vector2i, cost: int)

var tower_scenes: Dictionary = {
	"basic": preload("res://scenes/towers/tower.tscn"),
	"sniper": preload("res://scenes/towers/sniper_tower.tscn"),
	"cannon": preload("res://scenes/towers/cannon_tower.tscn"),
	"frost": preload("res://scenes/towers/frost_tower.tscn"),
}
var selected_tower_key: String = "basic"

const TILE_SIZE := 64

var grid_width: int = 18
var grid_height: int = 12
var occupied_cells: Dictionary = {}
var path_cells: Array[Vector2i] = []
var terrain_cells: Dictionary = {}
var placing_tower: bool = false
var path_data: Array[Vector2i] = []

const TERRAIN_SPEED_MULT := {
	"mud": 0.5,
	"water": 0.3,
}

@onready var path_2d: Path2D = $Path2D
@onready var preview_tower: Node2D = null

func load_level(level: Dictionary) -> void:
	grid_width = level["grid_width"]
	grid_height = level["grid_height"]
	path_data.clear()
	for p in level["path"]:
		path_data.append(p)
	path_cells = path_data.duplicate()
	occupied_cells.clear()
	terrain_cells.clear()
	if level.has("terrain"):
		for cell in level["terrain"]:
			terrain_cells[cell] = level["terrain"][cell]

func _ready() -> void:
	pass

func setup() -> void:
	# Center the map on screen
	var viewport_size = get_viewport().get_visible_rect().size
	var map_size = Vector2(grid_width * TILE_SIZE, grid_height * TILE_SIZE)
	position = (viewport_size - map_size) / 2.0

	# Build the Path2D curve from grid positions
	var curve = Curve2D.new()
	for cell in path_data:
		var world_pos = grid_to_world(cell)
		curve.add_point(world_pos)
	path_2d.curve = curve

	# Create a simple preview indicator
	preview_tower = Polygon2D.new()
	preview_tower.polygon = PackedVector2Array([
		Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)
	])
	preview_tower.color = Color(0, 1, 0, 0.4)
	preview_tower.visible = false
	add_child(preview_tower)

	queue_redraw()

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func get_terrain_speed_mult(world_pos: Vector2) -> float:
	var cell = world_to_grid(world_pos)
	if cell in terrain_cells:
		return TERRAIN_SPEED_MULT.get(terrain_cells[cell], 1.0)
	return 1.0

func _draw() -> void:
	# Draw ground tiles with subtle checkerboard
	var green_a = Color(0.22, 0.50, 0.18)
	var green_b = Color(0.25, 0.55, 0.20)
	var path_color = Color(0.55, 0.38, 0.22)
	var path_edge = Color(0.45, 0.28, 0.14)

	for x in range(grid_width):
		for y in range(grid_height):
			var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var cell = Vector2i(x, y)
			if cell in path_cells:
				var terrain = terrain_cells.get(cell, "")
				if terrain == "mud":
					draw_rect(rect, Color(0.4, 0.3, 0.15))
					var inner = rect.grow(-4)
					draw_rect(inner, Color(0.5, 0.38, 0.2))
				elif terrain == "water":
					draw_rect(rect, Color(0.15, 0.3, 0.55))
					var inner = rect.grow(-4)
					draw_rect(inner, Color(0.2, 0.4, 0.65))
				else:
					draw_rect(rect, path_color)
					var inner = rect.grow(-4)
					draw_rect(inner, Color(0.62, 0.44, 0.28))
			else:
				var col = green_a if (x + y) % 2 == 0 else green_b
				draw_rect(rect, col)
			# Grid lines
			draw_rect(rect, Color(0, 0, 0, 0.1), false, 1.0)

	# Draw path direction arrows
	for i in range(path_data.size() - 1):
		if i % 3 != 1:
			continue
		var from_pos = grid_to_world(path_data[i])
		var to_pos = grid_to_world(path_data[min(i + 1, path_data.size() - 1)])
		var dir = (to_pos - from_pos).normalized()
		var center = from_pos
		var arrow_size = 8.0
		var tip = center + dir * arrow_size
		var left = center - dir * arrow_size + dir.rotated(PI / 2) * arrow_size * 0.5
		var right = center - dir * arrow_size - dir.rotated(PI / 2) * arrow_size * 0.5
		draw_colored_polygon(PackedVector2Array([tip, left, right]), Color(1, 1, 1, 0.2))

	# Draw start/end markers
	if path_data.size() > 0:
		var start = grid_to_world(path_data[0])
		var end_pos = grid_to_world(path_data[path_data.size() - 1])
		# Start — green ring
		draw_circle(start, 14.0, Color(0, 0.8, 0, 0.5))
		draw_circle(start, 8.0, Color(0, 1, 0, 0.8))
		# End — red ring
		draw_circle(end_pos, 14.0, Color(0.8, 0, 0, 0.5))
		draw_circle(end_pos, 8.0, Color(1, 0, 0, 0.8))

func _process(_delta: float) -> void:
	if preview_tower == null:
		return
	if placing_tower:
		var mouse_pos = get_local_mouse_position()
		var grid_pos = world_to_grid(mouse_pos)
		var snapped_pos = grid_to_world(grid_pos)
		preview_tower.position = snapped_pos
		preview_tower.visible = true
		if can_place_tower(grid_pos):
			preview_tower.color = Color(0, 1, 0, 0.4)
		else:
			preview_tower.color = Color(1, 0, 0, 0.4)
	else:
		preview_tower.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if placing_tower:
			var mouse_pos = get_local_mouse_position()
			var grid_pos = world_to_grid(mouse_pos)
			if can_place_tower(grid_pos):
				place_tower(grid_pos)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if placing_tower:
			placing_tower = false
			get_viewport().set_input_as_handled()

func can_place_tower(grid_pos: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= grid_width:
		return false
	if grid_pos.y < 0 or grid_pos.y >= grid_height:
		return false
	if grid_pos in path_cells:
		return false
	if grid_pos in occupied_cells:
		return false
	return true

func place_tower(grid_pos: Vector2i) -> void:
	var scene = tower_scenes[selected_tower_key]
	var tower = scene.instantiate()
	tower.position = grid_to_world(grid_pos)
	$Towers.add_child(tower)
	occupied_cells[grid_pos] = tower
	tower_placed.emit(grid_pos, tower.cost)
	placing_tower = false

func start_placing(tower_key: String) -> void:
	selected_tower_key = tower_key
	placing_tower = true
