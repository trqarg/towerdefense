extends Control

const COL_WOOD_DARK := Color(0.14, 0.09, 0.05)
const COL_WOOD := Color(0.22, 0.14, 0.07)
const COL_GOLD := Color(0.85, 0.68, 0.18)
const COL_GOLD_BRIGHT := Color(1.0, 0.88, 0.3)
const COL_PARCHMENT := Color(0.95, 0.9, 0.72)
const COL_RED_DARK := Color(0.5, 0.1, 0.06)
const COL_RED := Color(0.75, 0.18, 0.12)

@onready var levels_container: VBoxContainer = $VBoxContainer/LevelsContainer
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	var levels = GameState.levels
	for i in levels.size():
		var level = levels[i]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var btn = Button.new()
		btn.text = "  Level %d  —  %s  " % [i + 1, level["name"]]
		btn.custom_minimum_size = Vector2(360, 55)
		btn.add_theme_font_size_override("font_size", 20)
		_style_button(btn, COL_WOOD, COL_GOLD)
		var idx = i
		btn.pressed.connect(func(): _start_level(idx))
		hbox.add_child(btn)

		# Star display
		var stars = GameState.level_stars.get(i, 0)
		var star_label = Label.new()
		star_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		star_label.add_theme_font_size_override("font_size", 26)
		if stars == 3:
			star_label.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
		elif stars > 0:
			star_label.add_theme_color_override("font_color", COL_GOLD)
		else:
			star_label.add_theme_color_override("font_color", Color(0.35, 0.3, 0.2))
		star_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		star_label.add_theme_constant_override("shadow_offset_x", 1)
		star_label.add_theme_constant_override("shadow_offset_y", 1)
		hbox.add_child(star_label)

		levels_container.add_child(hbox)

	_style_button(back_button, COL_RED_DARK, COL_RED)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _style_button(btn: Button, bg: Color, border: Color) -> void:
	btn.add_theme_stylebox_override("normal", _make_style(bg, border))
	btn.add_theme_stylebox_override("hover", _make_style(bg.lightened(0.15), border.lightened(0.1)))
	btn.add_theme_stylebox_override("pressed", _make_style(bg.darkened(0.15), border))
	btn.add_theme_color_override("font_color", COL_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", COL_PARCHMENT.lightened(0.1))

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(8)
	return s

func _start_level(index: int) -> void:
	GameState.selected_level = index
	get_tree().change_scene_to_file("res://scenes/main.tscn")
