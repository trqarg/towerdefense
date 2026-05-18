extends CanvasLayer

signal build_tower_pressed(tower_key: String)
signal next_wave_pressed

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
	for name in GameState.DIFFICULTY_NAMES:
		diff_option.add_item(name)
	diff_option.selected = GameState.difficulty
	diff_option.item_selected.connect(_on_difficulty_changed)

	for key in tower_data:
		var data = tower_data[key]
		var btn = Button.new()
		btn.text = "%s (%dg)" % [data["name"], data["cost"]]
		btn.custom_minimum_size = Vector2(120, 36)
		btn.add_theme_font_size_override("font_size", 16)
		var k = key
		btn.pressed.connect(func(): build_tower_pressed.emit(k))
		tower_buttons_container.add_child(btn)

func update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount

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

func show_game_over(won: bool) -> void:
	game_over_label.text = "YOU WIN!" if won else "GAME OVER"
	game_over_label.visible = true
	next_wave_button.disabled = true
	for btn in tower_buttons_container.get_children():
		btn.disabled = true

	var menu_btn = Button.new()
	menu_btn.text = "Back to Menu"
	menu_btn.custom_minimum_size = Vector2(140, 40)
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	game_over_label.add_sibling(menu_btn)
	menu_btn.anchors_preset = Control.PRESET_CENTER
	menu_btn.position = Vector2(-70, 40)
