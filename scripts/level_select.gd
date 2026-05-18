extends Control

@onready var levels_container: VBoxContainer = $VBoxContainer/LevelsContainer
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	var levels = GameState.levels
	for i in levels.size():
		var level = levels[i]
		var btn = Button.new()
		btn.text = "Level %d — %s" % [i + 1, level["name"]]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 20)
		var idx = i
		btn.pressed.connect(func(): _start_level(idx))
		levels_container.add_child(btn)

	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _start_level(index: int) -> void:
	GameState.selected_level = index
	get_tree().change_scene_to_file("res://scenes/main.tscn")
