extends PathFollow2D

signal died(enemy: PathFollow2D)
signal reached_end(enemy: PathFollow2D)

@export var max_health: float = 50.0
@export var speed: float = 100.0
@export var gold_reward: int = 10
var enemy_type: String = "grunt"

var health: float
var base_speed: float
var slow_timer: float = 0.0
var game_map: Node2D = null
var anim_time: float = 0.0
var is_slowed: bool = false
var skin_color: Color
var skin_dark: Color
var torso_color: Color

# Type color palettes: [skin, skin_dark, torso]
const TYPE_COLORS := {
	"grunt": [Color(0.38, 0.55, 0.2), Color(0.3, 0.45, 0.15), Color(0.35, 0.52, 0.18)],
	"runner": [Color(0.5, 0.55, 0.15), Color(0.42, 0.45, 0.1), Color(0.47, 0.52, 0.12)],
	"brute": [Color(0.3, 0.42, 0.18), Color(0.22, 0.34, 0.12), Color(0.27, 0.4, 0.15)],
	"shaman": [Color(0.35, 0.2, 0.5), Color(0.28, 0.15, 0.42), Color(0.32, 0.18, 0.47)],
	"warlord": [Color(0.5, 0.15, 0.12), Color(0.4, 0.1, 0.08), Color(0.45, 0.12, 0.1)],
}
const SLOW_TINT := Color(0.3, 0.55, 0.75, 1)
const SLOW_TINT_DARK := Color(0.25, 0.45, 0.65, 1)
const SLOW_TORSO := Color(0.28, 0.5, 0.7, 1)

@onready var body: Node2D = $Body
@onready var left_arm: Polygon2D = $Body/LeftArm
@onready var right_arm: Polygon2D = $Body/RightArm
@onready var left_leg: Polygon2D = $Body/LeftLeg
@onready var right_leg: Polygon2D = $Body/RightLeg

func _ready() -> void:
	health = max_health
	base_speed = speed
	loop = false
	add_to_group("enemies")
	$HealthBar.max_value = max_health
	$HealthBar.value = health
	game_map = get_tree().current_scene.get_node("GameMap")
	anim_time = randf() * TAU
	_apply_type_visuals()

func configure_type(type: String) -> void:
	enemy_type = type

func _apply_type_visuals() -> void:
	var colors = TYPE_COLORS.get(enemy_type, TYPE_COLORS["grunt"])
	skin_color = colors[0]
	skin_dark = colors[1]
	torso_color = colors[2]

	# Apply base colors
	$Body/Head.color = skin_color
	$Body/Torso.color = torso_color
	left_arm.color = skin_dark
	right_arm.color = skin_dark
	left_leg.color = skin_dark
	right_leg.color = skin_dark
	$Body/Head/LeftEar.color = skin_dark
	$Body/Head/RightEar.color = skin_dark
	$Body/Head/Brow.color = skin_dark

	# Color new detail nodes
	$Body/Torso/ChestPlate.color = torso_color.darkened(0.15)
	$Body/LeftArm/LeftHand.color = skin_color
	$Body/RightArm/RightHand.color = skin_color
	$Body/Head/Nose.color = skin_color.darkened(0.1)

	match enemy_type:
		"runner":
			# Lean, smaller body, tilted forward for speed
			body.scale = Vector2(0.8, 0.85)
			body.rotation = deg_to_rad(-8.0)
			$HealthBar.offset_top = -25.0
			$HealthBar.offset_bottom = -19.0
		"brute":
			# Big and bulky
			body.scale = Vector2(1.35, 1.3)
			$HealthBar.offset_top = -36.0
			$HealthBar.offset_bottom = -30.0
			$HealthBar.offset_left = -20.0
			$HealthBar.offset_right = 20.0
			# Shoulder armor
			$Body/Belt.color = Color(0.5, 0.5, 0.5)
			$Body/Torso/ChestPlate.color = Color(0.55, 0.55, 0.55)
		"shaman":
			# Normal size, glowing eyes
			$Body/Head/LeftEye.color = Color(0.2, 0.9, 0.3)
			$Body/Head/RightEye.color = Color(0.2, 0.9, 0.3)
			# Staff color on right arm
			right_arm.color = Color(0.45, 0.3, 0.15)
			$Body/RightArm/RightHand.color = Color(0.5, 0.35, 0.18)
			# Mystical chest marking
			$Body/Torso/ChestPlate.color = Color(0.3, 0.15, 0.45)
		"warlord":
			# Large with red tint, armor
			body.scale = Vector2(1.25, 1.25)
			$HealthBar.offset_top = -34.0
			$HealthBar.offset_bottom = -28.0
			$HealthBar.offset_left = -20.0
			$HealthBar.offset_right = 20.0
			$Body/Belt.color = Color(0.6, 0.55, 0.1)
			$Body/Belt/BeltBuckle.color = Color(0.85, 0.75, 0.15)
			$Body/Head/LeftEye.color = Color(1.0, 0.8, 0.1)
			$Body/Head/RightEye.color = Color(1.0, 0.8, 0.1)
			$Body/Head/LeftTusk.color = Color(0.95, 0.9, 0.6)
			$Body/Head/RightTusk.color = Color(0.95, 0.9, 0.6)
			# Heavy armor chest plate
			$Body/Torso/ChestPlate.color = Color(0.55, 0.45, 0.1)

func _process(delta: float) -> void:
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			speed = base_speed
			is_slowed = false
			_set_orc_colors(false)

	var terrain_mult = 1.0
	if game_map:
		terrain_mult = game_map.get_terrain_speed_mult(position)
	progress += speed * terrain_mult * delta

	# Walking animation
	var anim_speed = speed * terrain_mult * 0.06
	anim_time += delta * anim_speed
	var walk_cycle = sin(anim_time)

	# Body bob
	body.position.y = abs(walk_cycle) * -2.0

	# Arm swing (opposite to legs)
	left_arm.rotation = walk_cycle * 0.5
	right_arm.rotation = -walk_cycle * 0.5

	# Leg swing
	left_leg.rotation = -walk_cycle * 0.4
	right_leg.rotation = walk_cycle * 0.4

	if progress_ratio >= 1.0:
		reached_end.emit(self)
		queue_free()

func take_damage(amount: float) -> void:
	health -= amount
	$HealthBar.value = health
	# Flash white on hit
	body.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		died.emit(self)
		queue_free()

func apply_slow(amount: float, duration: float) -> void:
	speed = base_speed * (1.0 - amount)
	slow_timer = duration
	is_slowed = true
	_set_orc_colors(true)

func _set_orc_colors(slowed: bool) -> void:
	if slowed:
		$Body/Head.color = SLOW_TINT
		$Body/Torso.color = SLOW_TORSO
		left_arm.color = SLOW_TINT_DARK
		right_arm.color = SLOW_TINT_DARK
		left_leg.color = SLOW_TINT_DARK
		right_leg.color = SLOW_TINT_DARK
		$Body/Head/LeftEar.color = SLOW_TINT_DARK
		$Body/Head/RightEar.color = SLOW_TINT_DARK
		$Body/Head/Brow.color = SLOW_TINT_DARK
		# Tint new detail nodes when slowed
		$Body/Torso/ChestPlate.color = SLOW_TORSO.darkened(0.15)
		$Body/LeftArm/LeftHand.color = SLOW_TINT
		$Body/RightArm/RightHand.color = SLOW_TINT
		$Body/Head/Nose.color = SLOW_TINT.darkened(0.1)
	else:
		# Restore base colors and re-apply type-specific overrides
		_apply_type_visuals()
