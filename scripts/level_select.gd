extends Control

@onready var levels_container: VBoxContainer = $VBoxContainer/LevelsContainer
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	var levels = GameState.levels
	for i in levels.size():
		var level = levels[i]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var btn = Button.new()
		btn.text = "Level %d — %s" % [i + 1, level["name"]]
		btn.custom_minimum_size = Vector2(300, 50)
		btn.add_theme_font_size_override("font_size", 20)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var idx = i
		btn.pressed.connect(func(): _start_level(idx))
		hbox.add_child(btn)

		# Star display
		var stars = GameState.level_stars.get(i, 0)
		var star_label = Label.new()
		var star_filled = "★".repeat(stars)
		var star_empty = "☆".repeat(3 - stars)
		star_label.text = star_filled + star_empty
		star_label.add_theme_font_size_override("font_size", 22)
		if stars > 0:
			star_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		else:
			star_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		hbox.add_child(star_label)

		levels_container.add_child(hbox)

	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _start_level(index: int) -> void:
	GameState.selected_level = index
	get_tree().change_scene_to_file("res://scenes/main.tscn")
