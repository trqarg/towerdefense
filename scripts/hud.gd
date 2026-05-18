extends CanvasLayer

signal build_tower_pressed(tower_key: String)
signal next_wave_pressed
signal tower_upgrade_pressed
signal tower_sell_pressed
signal ability_pressed(ability_name: String)

@onready var gold_label: Label = $Panel/MarginContainer/HBoxContainer/GoldLabel
@onready var lives_label: Label = $Panel/MarginContainer/HBoxContainer/LivesLabel
@onready var wave_label: Label = $Panel/MarginContainer/HBoxContainer/WaveLabel
@onready var next_wave_button: Button = $Panel/MarginContainer/HBoxContainer/NextWaveButton
@onready var tower_buttons_container: HBoxContainer = $Panel/MarginContainer/HBoxContainer/TowerButtons
@onready var options_button: Button = $Panel/MarginContainer/HBoxContainer/OptionsButton
@onready var game_over_label: Label = $GameOverLabel
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var banner: Label = $Banner

var tower_data: Dictionary = {
	"basic": {"name": "Basic", "cost": 25, "color": Color(0.2, 0.4, 0.9)},
	"sniper": {"name": "Sniper", "cost": 50, "color": Color(0.15, 0.6, 0.2)},
	"cannon": {"name": "Cannon", "cost": 40, "color": Color(0.85, 0.5, 0.1)},
	"frost": {"name": "Frost", "cost": 35, "color": Color(0.3, 0.75, 0.9)},
}

# Speed control
var current_speed: float = 1.0
var speed_button: Button = null

# Rain of Fire ability
var rain_cooldown: float = 0.0
const RAIN_COOLDOWN_MAX: float = 25.0
var rain_button: Button = null

# Tower selection menu
var tower_menu: PanelContainer = null
var tower_menu_target: Node2D = null
var upgrade_btn: Button = null
var sell_btn: Button = null
var info_label: Label = null

func _ready() -> void:
	game_over_label.visible = false
	options_panel.visible = false
	next_wave_button.pressed.connect(func(): next_wave_pressed.emit())
	options_button.pressed.connect(_on_options_pressed)

	# Options panel buttons
	$OptionsPanel/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$OptionsPanel/VBoxContainer/ExitToMenuButton.pressed.connect(_on_exit_to_menu_pressed)

	# Fullscreen toggle
	var fs_check: CheckButton = $OptionsPanel/VBoxContainer/FullscreenCheck
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(_on_fullscreen_toggled)

	# Difficulty selector
	var diff_option: OptionButton = $OptionsPanel/VBoxContainer/DifficultyContainer/DifficultyOption
	for dname in GameState.DIFFICULTY_NAMES:
		diff_option.add_item(dname)
	diff_option.selected = GameState.difficulty
	diff_option.item_selected.connect(_on_difficulty_changed)

	# Tower build buttons
	for key in tower_data:
		var data = tower_data[key]
		var btn = Button.new()
		btn.text = "%s (%dg)" % [data["name"], data["cost"]]
		btn.custom_minimum_size = Vector2(120, 36)
		btn.add_theme_font_size_override("font_size", 16)
		var k = key
		btn.pressed.connect(func(): build_tower_pressed.emit(k))
		tower_buttons_container.add_child(btn)

	# Speed toggle button
	speed_button = Button.new()
	speed_button.text = "1x"
	speed_button.custom_minimum_size = Vector2(50, 36)
	speed_button.add_theme_font_size_override("font_size", 16)
	speed_button.pressed.connect(_on_speed_toggle)
	$Panel/MarginContainer/HBoxContainer.add_child(speed_button)

	# Rain of Fire ability button
	rain_button = Button.new()
	rain_button.text = "Rain of Fire"
	rain_button.custom_minimum_size = Vector2(130, 36)
	rain_button.add_theme_font_size_override("font_size", 16)
	rain_button.pressed.connect(func(): ability_pressed.emit("rain_of_fire"))
	$Panel/MarginContainer/HBoxContainer.add_child(rain_button)

	# Tower selection menu (hidden by default)
	_build_tower_menu()

func _process(delta: float) -> void:
	# Rain of Fire cooldown
	if rain_cooldown > 0.0:
		rain_cooldown -= delta
		if rain_cooldown <= 0.0:
			rain_cooldown = 0.0
			rain_button.text = "Rain of Fire"
			rain_button.disabled = false
		else:
			rain_button.text = "Fire (%.0fs)" % rain_cooldown
			rain_button.disabled = true

	# Keep tower menu positioned
	if tower_menu and tower_menu.visible and tower_menu_target and is_instance_valid(tower_menu_target):
		var screen_pos = tower_menu_target.get_global_transform_with_canvas().origin
		tower_menu.position = Vector2(screen_pos.x - tower_menu.size.x / 2, screen_pos.y - tower_menu.size.y - 30)
		# Clamp to viewport
		var vp = get_viewport().get_visible_rect().size
		tower_menu.position.x = clampf(tower_menu.position.x, 0, vp.x - tower_menu.size.x)
		tower_menu.position.y = clampf(tower_menu.position.y, 55, vp.y - tower_menu.size.y)

func _build_tower_menu() -> void:
	tower_menu = PanelContainer.new()
	tower_menu.visible = false
	tower_menu.custom_minimum_size = Vector2(180, 0)
	tower_menu.z_index = 10

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.92)
	style.border_color = Color(0.6, 0.55, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	tower_menu.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	tower_menu.add_child(vbox)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	vbox.add_child(info_label)

	upgrade_btn = Button.new()
	upgrade_btn.custom_minimum_size = Vector2(0, 32)
	upgrade_btn.add_theme_font_size_override("font_size", 15)
	upgrade_btn.pressed.connect(func(): tower_upgrade_pressed.emit())
	vbox.add_child(upgrade_btn)

	sell_btn = Button.new()
	sell_btn.custom_minimum_size = Vector2(0, 32)
	sell_btn.add_theme_font_size_override("font_size", 15)
	sell_btn.pressed.connect(func(): tower_sell_pressed.emit())
	vbox.add_child(sell_btn)

	add_child(tower_menu)

func show_tower_menu(tower: Node2D, player_gold: int) -> void:
	tower_menu_target = tower
	_refresh_tower_menu(player_gold)
	tower_menu.visible = true

func _refresh_tower_menu(player_gold: int) -> void:
	if not tower_menu_target or not is_instance_valid(tower_menu_target):
		hide_tower_menu()
		return
	var t = tower_menu_target
	info_label.text = t.get_info_text()
	if t.can_upgrade():
		var ucost = t.get_upgrade_cost()
		upgrade_btn.text = "Upgrade (%dg)" % ucost
		upgrade_btn.disabled = player_gold < ucost
		upgrade_btn.visible = true
	else:
		upgrade_btn.text = "MAX LEVEL"
		upgrade_btn.disabled = true
		upgrade_btn.visible = true
	sell_btn.text = "Sell (+%dg)" % t.get_sell_value()

func hide_tower_menu() -> void:
	tower_menu.visible = false
	tower_menu_target = null

func start_rain_cooldown() -> void:
	rain_cooldown = RAIN_COOLDOWN_MAX

# ── Speed toggle ─────────────────────────────────

func _on_speed_toggle() -> void:
	if current_speed == 1.0:
		current_speed = 2.0
		speed_button.text = "2x"
	else:
		current_speed = 1.0
		speed_button.text = "1x"
	Engine.time_scale = current_speed

# ── Existing functions ───────────────────────────

func update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount
	# Refresh tower menu if open
	if tower_menu and tower_menu.visible:
		_refresh_tower_menu(amount)

func update_lives(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount

func update_wave(current: int, total: int) -> void:
	wave_label.text = "Wave: %d/%d" % [current, total]

func set_next_wave_enabled(enabled: bool) -> void:
	next_wave_button.disabled = not enabled

func set_building_enabled(enabled: bool) -> void:
	for btn in tower_buttons_container.get_children():
		btn.disabled = not enabled

func _on_options_pressed() -> void:
	options_panel.visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	options_panel.visible = false
	get_tree().paused = false

func _on_exit_to_menu_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_difficulty_changed(index: int) -> void:
	GameState.difficulty = index

func show_banner(msg: String) -> void:
	banner.show_message(msg)

func show_game_over(won: bool, stars: int = 0) -> void:
	Engine.time_scale = 1.0
	hide_tower_menu()

	if won:
		var star_filled = "★".repeat(stars)
		var star_empty = "☆".repeat(3 - stars)
		game_over_label.text = "YOU WIN!\n%s%s" % [star_filled, star_empty]
	else:
		game_over_label.text = "GAME OVER"
	game_over_label.visible = true
	next_wave_button.disabled = true
	for btn in tower_buttons_container.get_children():
		btn.disabled = true
	if rain_button:
		rain_button.disabled = true
	if speed_button:
		speed_button.disabled = true

	var menu_btn = Button.new()
	menu_btn.text = "Back to Menu"
	menu_btn.custom_minimum_size = Vector2(140, 40)
	menu_btn.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	game_over_label.add_sibling(menu_btn)
	menu_btn.anchors_preset = Control.PRESET_CENTER
	menu_btn.position = Vector2(-70, 50)
