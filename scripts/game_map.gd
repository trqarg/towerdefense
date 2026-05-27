extends Node2D

signal tower_placed(grid_pos: Vector2i, cost: int)
signal tower_selected(tower: Node2D)
signal tower_deselected
signal tower_sold(grid_pos: Vector2i, refund: int)
signal ability_used(ability_name: String, world_pos: Vector2)

var tower_scenes: Dictionary = {
	"basic": preload("res://scenes/towers/tower.tscn"),
	"sniper": preload("res://scenes/towers/sniper_tower.tscn"),
	"cannon": preload("res://scenes/towers/cannon_tower.tscn"),
	"frost": preload("res://scenes/towers/frost_tower.tscn"),
	"laser": preload("res://scenes/towers/laser_tower.tscn"),
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

var selected_tower: Node2D = null
var targeting_ability: String = ""

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
	var viewport_size = get_viewport().get_visible_rect().size
	var map_size = Vector2(grid_width * TILE_SIZE, grid_height * TILE_SIZE)
	position = (viewport_size - map_size) / 2.0

	var curve = Curve2D.new()
	for cell in path_data:
		var world_pos = grid_to_world(cell)
		curve.add_point(world_pos)
	path_2d.curve = curve

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
	# --- Helper: deterministic hash for per-tile variation ---
	# Returns a float 0.0..1.0 seeded by grid position and an extra seed int.
	# Uses a simple integer hash so it is pure and costs almost nothing.

	var map_w: float = grid_width * TILE_SIZE
	var map_h: float = grid_height * TILE_SIZE

	# =====================================================================
	# 1. GRASS TILES
	# =====================================================================
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, y)
			if cell in path_cells:
				continue  # drawn in the path pass
			var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)

			# --- base colour with per-tile variation ---
			var h = ((x * 374761 + y * 668265) & 0x7FFFFFFF)
			var t = float(h % 1000) / 1000.0  # 0..1
			var base_green = Color(
				lerpf(0.20, 0.27, t),
				lerpf(0.47, 0.58, t),
				lerpf(0.15, 0.22, t)
			)
			draw_rect(rect, base_green)

			# --- subtle darker edges for depth ---
			var edge_col = Color(0, 0, 0, 0.06)
			draw_line(Vector2(rect.position.x, rect.position.y),
					  Vector2(rect.position.x + TILE_SIZE, rect.position.y), edge_col, 1.0)
			draw_line(Vector2(rect.position.x, rect.position.y),
					  Vector2(rect.position.x, rect.position.y + TILE_SIZE), edge_col, 1.0)

			# --- grass tuft blades (2-3 per tile) ---
			var blade_count = 2 + (h % 2)  # 2 or 3
			for b in range(blade_count):
				var bh = ((x * 7 + y * 13 + b * 997) * 31) & 0x7FFFFFFF
				var bx: float = rect.position.x + 8.0 + float(bh % 48)
				var by: float = rect.position.y + TILE_SIZE  # bottom of tile
				var blade_h: float = 8.0 + float((bh / 48) % 8)
				var lean: float = (float((bh / 384) % 10) - 5.0) * 0.8
				var blade_col = Color(
					lerpf(0.18, 0.30, float((bh / 3840) % 100) / 100.0),
					lerpf(0.55, 0.70, float((bh / 3840) % 100) / 100.0),
					lerpf(0.10, 0.18, float((bh / 3840) % 100) / 100.0)
				)
				var p0 = Vector2(bx, by)
				var p1 = Vector2(bx + lean, by - blade_h)
				var p2 = Vector2(bx + 3.0, by)
				draw_colored_polygon(PackedVector2Array([p0, p1, p2]), blade_col)

			# --- occasional flower or rock (every ~8th tile) ---
			if (x * 7 + y * 13) % 8 == 0:
				var deco_h = ((x * 509 + y * 1021) * 17) & 0x7FFFFFFF
				var dx: float = rect.position.x + 16.0 + float(deco_h % 32)
				var dy: float = rect.position.y + 16.0 + float((deco_h / 32) % 32)
				if deco_h % 2 == 0:
					# small flower — petals + center
					var petal_col = Color(0.85, 0.25, 0.35) if (deco_h / 2) % 2 == 0 else Color(0.90, 0.80, 0.20)
					for p in range(5):
						var angle = TAU * p / 5.0
						draw_circle(Vector2(dx + cos(angle) * 3.0, dy + sin(angle) * 3.0), 2.0, petal_col)
					draw_circle(Vector2(dx, dy), 1.5, Color(1.0, 0.95, 0.3))
				else:
					# small rock
					draw_circle(Vector2(dx, dy), 3.5, Color(0.45, 0.42, 0.40))
					draw_circle(Vector2(dx + 1, dy - 1), 2.0, Color(0.55, 0.53, 0.50))

	# =====================================================================
	# 2. PATH TILES (dirt / mud / water)
	# =====================================================================
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, y)
			if not (cell in path_cells):
				continue
			var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var terrain: String = terrain_cells.get(cell, "")

			if terrain == "mud":
				# --- Mud: swampy green-brown ---
				draw_rect(rect, Color(0.35, 0.30, 0.12))
				draw_rect(rect.grow(-5), Color(0.45, 0.38, 0.18))
				# bubble-like circles
				var mh = ((x * 311 + y * 617) * 23) & 0x7FFFFFFF
				for mb in range(4):
					var mbh = (mh + mb * 773) & 0x7FFFFFFF
					var mx: float = rect.position.x + 8.0 + float(mbh % 48)
					var my: float = rect.position.y + 8.0 + float((mbh / 48) % 48)
					var mr: float = 2.0 + float((mbh / 2304) % 3)
					draw_circle(Vector2(mx, my), mr, Color(0.38, 0.42, 0.18, 0.5))
					# highlight arc on bubble
					draw_arc(Vector2(mx - 0.5, my - 0.5), mr, -0.3, 1.0, 6, Color(0.55, 0.58, 0.30, 0.4), 1.0)

			elif terrain == "water":
				# --- Water: blue with wave lines ---
				draw_rect(rect, Color(0.12, 0.28, 0.55))
				draw_rect(rect.grow(-4), Color(0.18, 0.38, 0.65))
				# wave pattern lines
				for wl in range(3):
					var wy: float = rect.position.y + 14.0 + wl * 16.0
					var wave_pts = PackedVector2Array()
					for ws in range(9):
						var wx: float = rect.position.x + ws * 8.0
						var wave_off: float = sin(float(ws + x * 3 + wl) * 1.2) * 3.0
						wave_pts.append(Vector2(wx, wy + wave_off))
					draw_polyline(wave_pts, Color(0.35, 0.60, 0.85, 0.45), 1.0)
				# shimmer streaks
				var sh = ((x * 431 + y * 919) * 13) & 0x7FFFFFFF
				for s in range(2):
					var sx: float = rect.position.x + 10.0 + float((sh + s * 500) % 44)
					var sy: float = rect.position.y + 8.0 + float(((sh + s * 500) / 44) % 48)
					draw_line(Vector2(sx, sy), Vector2(sx + 10.0, sy + 2.0), Color(0.6, 0.8, 1.0, 0.3), 1.0)

			else:
				# --- Normal dirt path ---
				var base_dirt = Color(0.55, 0.40, 0.22)
				draw_rect(rect, base_dirt)
				# darker inset border for depth
				draw_rect(rect.grow(-3), Color(0.62, 0.48, 0.30))
				# even lighter centre
				draw_rect(rect.grow(-8), Color(0.68, 0.52, 0.34))

				# darker path edges (check neighbours for grass)
				var edge_dark = Color(0.40, 0.28, 0.14)
				if not (Vector2i(x - 1, y) in path_cells):
					draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x, rect.position.y + TILE_SIZE), edge_dark, 3.0)
				if not (Vector2i(x + 1, y) in path_cells):
					draw_line(Vector2(rect.position.x + TILE_SIZE, rect.position.y), Vector2(rect.position.x + TILE_SIZE, rect.position.y + TILE_SIZE), edge_dark, 3.0)
				if not (Vector2i(x, y - 1) in path_cells):
					draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x + TILE_SIZE, rect.position.y), edge_dark, 3.0)
				if not (Vector2i(x, y + 1) in path_cells):
					draw_line(Vector2(rect.position.x, rect.position.y + TILE_SIZE), Vector2(rect.position.x + TILE_SIZE, rect.position.y + TILE_SIZE), edge_dark, 3.0)

				# worn track marks (two parallel darker lines through centre)
				var cx: float = rect.position.x + TILE_SIZE * 0.5
				var cy: float = rect.position.y + TILE_SIZE * 0.5
				var track_col = Color(0.45, 0.32, 0.18, 0.35)
				# figure out predominant direction for tracks
				var horiz = (Vector2i(x - 1, y) in path_cells) or (Vector2i(x + 1, y) in path_cells)
				var vert = (Vector2i(x, y - 1) in path_cells) or (Vector2i(x, y + 1) in path_cells)
				if horiz and not vert:
					# horizontal tracks
					draw_line(Vector2(rect.position.x, cy - 6), Vector2(rect.position.x + TILE_SIZE, cy - 6), track_col, 1.5)
					draw_line(Vector2(rect.position.x, cy + 6), Vector2(rect.position.x + TILE_SIZE, cy + 6), track_col, 1.5)
				elif vert:
					# vertical tracks
					draw_line(Vector2(cx - 6, rect.position.y), Vector2(cx - 6, rect.position.y + TILE_SIZE), track_col, 1.5)
					draw_line(Vector2(cx + 6, rect.position.y), Vector2(cx + 6, rect.position.y + TILE_SIZE), track_col, 1.5)
				else:
					# isolated or corner — draw cross tracks
					draw_line(Vector2(rect.position.x, cy - 6), Vector2(rect.position.x + TILE_SIZE, cy - 6), track_col, 1.5)
					draw_line(Vector2(rect.position.x, cy + 6), Vector2(rect.position.x + TILE_SIZE, cy + 6), track_col, 1.5)

				# pebble dots (3-4 per tile)
				var ph = ((x * 251 + y * 839) * 41) & 0x7FFFFFFF
				var pebble_count = 3 + (ph % 2)
				for pb in range(pebble_count):
					var pbh = (ph + pb * 613) & 0x7FFFFFFF
					var px: float = rect.position.x + 6.0 + float(pbh % 52)
					var py: float = rect.position.y + 6.0 + float((pbh / 52) % 52)
					var pr: float = 1.0 + float((pbh / 2704) % 2)
					var pebble_shade = lerpf(0.35, 0.50, float((pbh / 5408) % 100) / 100.0)
					draw_circle(Vector2(px, py), pr, Color(pebble_shade, pebble_shade * 0.9, pebble_shade * 0.75, 0.6))

	# =====================================================================
	# 3. BUSHES near path edges (on grass tiles adjacent to path)
	# =====================================================================
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, y)
			if cell in path_cells:
				continue
			# only place bush if adjacent to a path cell and hash allows
			var adj_path = false
			for nb in [Vector2i(x-1,y), Vector2i(x+1,y), Vector2i(x,y-1), Vector2i(x,y+1)]:
				if nb in path_cells:
					adj_path = true
					break
			if not adj_path:
				continue
			var bush_h = ((x * 443 + y * 887) * 29) & 0x7FFFFFFF
			if bush_h % 5 != 0:
				continue  # roughly every 5th adjacent grass tile gets a bush
			var bx: float = x * TILE_SIZE + 16.0 + float(bush_h % 32)
			var by: float = y * TILE_SIZE + TILE_SIZE - 8.0
			# semicircle bush (drawn as arc-filled polygon)
			var bush_col = Color(0.18, 0.52, 0.15, 0.85)
			var bush_r: float = 7.0 + float((bush_h / 32) % 5)
			var bush_pts = PackedVector2Array()
			for i in range(9):
				var angle = PI + PI * i / 8.0
				bush_pts.append(Vector2(bx + cos(angle) * bush_r, by + sin(angle) * bush_r))
			bush_pts.append(Vector2(bx + bush_r, by))
			draw_colored_polygon(bush_pts, bush_col)
			# lighter highlight
			draw_arc(Vector2(bx, by), bush_r * 0.7, PI + 0.4, TAU - 0.4, 8, Color(0.30, 0.65, 0.25, 0.5), 1.5)

	# =====================================================================
	# 4. TREES along top and bottom map edges
	# =====================================================================
	for edge_y in [0, grid_height - 1]:
		for x in range(grid_width):
			var cell = Vector2i(x, edge_y)
			if cell in path_cells:
				continue
			var tree_h = ((x * 569 + edge_y * 1223) * 37) & 0x7FFFFFFF
			if tree_h % 4 != 0:
				continue  # roughly every 4th edge grass tile gets a tree
			var tx: float = x * TILE_SIZE + 16.0 + float(tree_h % 32)
			var ty: float = edge_y * TILE_SIZE + 10.0 + float((tree_h / 32) % 20)
			# trunk (rectangle)
			var trunk_w: float = 5.0
			var trunk_h_val: float = 14.0
			draw_rect(Rect2(tx - trunk_w * 0.5, ty, trunk_w, trunk_h_val), Color(0.45, 0.30, 0.15))
			# foliage (triangle)
			var foliage_w: float = 18.0 + float((tree_h / 640) % 8)
			var foliage_h_val: float = 20.0 + float((tree_h / 5120) % 8)
			var f0 = Vector2(tx, ty - foliage_h_val)
			var f1 = Vector2(tx - foliage_w * 0.5, ty + 2.0)
			var f2 = Vector2(tx + foliage_w * 0.5, ty + 2.0)
			var tree_green = Color(
				lerpf(0.12, 0.22, float((tree_h / 40960) % 100) / 100.0),
				lerpf(0.40, 0.55, float((tree_h / 40960) % 100) / 100.0),
				lerpf(0.10, 0.18, float((tree_h / 40960) % 100) / 100.0)
			)
			draw_colored_polygon(PackedVector2Array([f0, f1, f2]), tree_green)
			# second smaller layer of foliage
			var s0 = Vector2(tx, ty - foliage_h_val - 8.0)
			var s1 = Vector2(tx - foliage_w * 0.35, ty - foliage_h_val + 8.0)
			var s2 = Vector2(tx + foliage_w * 0.35, ty - foliage_h_val + 8.0)
			draw_colored_polygon(PackedVector2Array([s0, s1, s2]), tree_green.lightened(0.1))

	# =====================================================================
	# 5. DECORATIVE WOODEN FRAME around the map
	# =====================================================================
	var frame_thick: float = 6.0
	var frame_col = Color(0.42, 0.28, 0.14)
	var frame_light = Color(0.55, 0.38, 0.22)
	# outer border
	draw_rect(Rect2(-frame_thick, -frame_thick, map_w + frame_thick * 2, map_h + frame_thick * 2), frame_col, false, frame_thick)
	# inner highlight line
	draw_rect(Rect2(-1, -1, map_w + 2, map_h + 2), frame_light, false, 1.5)
	# corner details — small filled squares at each corner
	var corner_size: float = 10.0
	for cx_off in [-frame_thick, map_w - corner_size + frame_thick]:
		for cy_off in [-frame_thick, map_h - corner_size + frame_thick]:
			draw_rect(Rect2(cx_off - 2, cy_off - 2, corner_size, corner_size), frame_light)
			draw_rect(Rect2(cx_off, cy_off, corner_size - 4, corner_size - 4), frame_col)

	# =====================================================================
	# 6. PATH DIRECTION ARROWS (preserved from original)
	# =====================================================================
	for i in range(path_data.size() - 1):
		if i % 3 != 1:
			continue
		var from_pos = grid_to_world(path_data[i])
		var to_pos = grid_to_world(path_data[min(i + 1, path_data.size() - 1)])
		var dir = (to_pos - from_pos).normalized()
		var center = from_pos
		var arrow_size = 8.0
		var tip = center + dir * arrow_size
		var left_pt = center - dir * arrow_size + dir.rotated(PI / 2) * arrow_size * 0.5
		var right_pt = center - dir * arrow_size - dir.rotated(PI / 2) * arrow_size * 0.5
		draw_colored_polygon(PackedVector2Array([tip, left_pt, right_pt]), Color(1, 1, 1, 0.25))

	# =====================================================================
	# 7. START / END MARKERS
	# =====================================================================
	if path_data.size() > 0:
		var start = grid_to_world(path_data[0])
		var end_pos = grid_to_world(path_data[path_data.size() - 1])

		# --- Start: green banner / flag ---
		# flag pole
		draw_line(Vector2(start.x - 10, start.y + 16), Vector2(start.x - 10, start.y - 20), Color(0.35, 0.25, 0.12), 2.5)
		# flag (pentagon shape)
		var flag_col = Color(0.15, 0.70, 0.20, 0.9)
		var fl = Vector2(start.x - 10, start.y - 20)
		var flag_pts = PackedVector2Array([
			fl,
			Vector2(fl.x + 22, fl.y + 4),
			Vector2(fl.x + 18, fl.y + 10),
			Vector2(fl.x + 22, fl.y + 16),
			Vector2(fl.x, fl.y + 16),
		])
		draw_colored_polygon(flag_pts, flag_col)
		# flag emblem — small lighter triangle
		draw_colored_polygon(PackedVector2Array([
			Vector2(fl.x + 6, fl.y + 5),
			Vector2(fl.x + 14, fl.y + 8),
			Vector2(fl.x + 6, fl.y + 11),
		]), Color(0.3, 0.85, 0.35, 0.7))
		# pole base circle
		draw_circle(Vector2(start.x - 10, start.y + 16), 3.0, Color(0.35, 0.25, 0.12))

		# --- End: red castle gate / fortress ---
		var gx: float = end_pos.x
		var gy: float = end_pos.y
		# main gate body
		draw_rect(Rect2(gx - 16, gy - 14, 32, 28), Color(0.60, 0.18, 0.12))
		# battlements (crenellations along top)
		for cr in range(4):
			var crx: float = gx - 14 + cr * 9
			draw_rect(Rect2(crx, gy - 20, 7, 8), Color(0.65, 0.22, 0.15))
		# gate arch (dark opening)
		draw_rect(Rect2(gx - 6, gy, 12, 14), Color(0.15, 0.08, 0.05))
		draw_arc(Vector2(gx, gy), 6.0, PI, TAU, 8, Color(0.15, 0.08, 0.05), 12.0)
		# highlight edges
		draw_rect(Rect2(gx - 16, gy - 14, 32, 28), Color(0.75, 0.30, 0.20), false, 1.5)

	# =====================================================================
	# 8. SELECTED TOWER RANGE CIRCLE (preserved from original)
	# =====================================================================
	if selected_tower and is_instance_valid(selected_tower):
		var pos = selected_tower.position
		var r = selected_tower.tower_range
		draw_circle(pos, r, Color(1, 1, 1, 0.08))
		draw_arc(pos, r, 0, TAU, 64, Color(1, 1, 1, 0.3), 2.0)
		# Selection highlight
		draw_arc(pos, 20.0, 0, TAU, 32, Color(1, 0.9, 0.2, 0.7), 2.0)

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
	elif targeting_ability != "":
		var mouse_pos = get_local_mouse_position()
		preview_tower.position = mouse_pos
		preview_tower.visible = true
		preview_tower.color = Color(1.0, 0.3, 0.0, 0.3)
		preview_tower.polygon = _make_circle_polygon(100.0, 24)
	else:
		preview_tower.visible = false
		preview_tower.polygon = PackedVector2Array([
			Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)
		])

func _make_circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in segments:
		var angle = TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if placing_tower:
			var mouse_pos = get_local_mouse_position()
			var grid_pos = world_to_grid(mouse_pos)
			if can_place_tower(grid_pos):
				place_tower(grid_pos)
			get_viewport().set_input_as_handled()
		elif targeting_ability != "":
			var mouse_pos = get_local_mouse_position()
			ability_used.emit(targeting_ability, mouse_pos)
			targeting_ability = ""
			get_viewport().set_input_as_handled()
		else:
			# Check if clicking on a tower to select it
			var mouse_pos = get_local_mouse_position()
			var grid_pos = world_to_grid(mouse_pos)
			if grid_pos in occupied_cells:
				var tower = occupied_cells[grid_pos]
				if is_instance_valid(tower):
					selected_tower = tower
					tower_selected.emit(tower)
					queue_redraw()
					get_viewport().set_input_as_handled()
					return
			# Clicked empty space — deselect
			if selected_tower:
				_deselect_tower()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if placing_tower:
			placing_tower = false
			get_viewport().set_input_as_handled()
		elif targeting_ability != "":
			targeting_ability = ""
			get_viewport().set_input_as_handled()
		elif selected_tower:
			_deselect_tower()
			get_viewport().set_input_as_handled()

func _deselect_tower() -> void:
	selected_tower = null
	tower_deselected.emit()
	queue_redraw()

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
	tower.tower_key = selected_tower_key
	tower.total_gold_invested = tower.cost
	$Towers.add_child(tower)
	occupied_cells[grid_pos] = tower
	tower_placed.emit(grid_pos, tower.cost)
	placing_tower = false

func sell_tower(tower: Node2D) -> void:
	# Find and remove from occupied_cells
	for cell in occupied_cells:
		if occupied_cells[cell] == tower:
			var refund = tower.get_sell_value()
			occupied_cells.erase(cell)
			tower.queue_free()
			tower_sold.emit(cell, refund)
			_deselect_tower()
			break

func start_placing(tower_key: String) -> void:
	if selected_tower:
		_deselect_tower()
	selected_tower_key = tower_key
	placing_tower = true

func start_ability_targeting(ability_name: String) -> void:
	if selected_tower:
		_deselect_tower()
	placing_tower = false
	targeting_ability = ability_name
