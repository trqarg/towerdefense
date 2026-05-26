extends Control

const COL_WOOD_DARK := Color(0.14, 0.09, 0.05)
const COL_WOOD := Color(0.22, 0.14, 0.07)
const COL_GOLD := Color(0.85, 0.68, 0.18)
const COL_GOLD_BRIGHT := Color(1.0, 0.88, 0.3)
const COL_PARCHMENT := Color(0.95, 0.9, 0.72)
const COL_GREEN_DARK := Color(0.12, 0.38, 0.08)
const COL_GREEN := Color(0.18, 0.55, 0.12)
const COL_RED_DARK := Color(0.5, 0.1, 0.06)
const COL_RED := Color(0.75, 0.18, 0.12)

func _ready() -> void:
	_style_button($VBoxContainer/StartButton, COL_GREEN_DARK, COL_GREEN.lightened(0.2))
	_style_button($VBoxContainer/OptionsButton, COL_WOOD, COL_GOLD)
	_style_button($VBoxContainer/ExitButton, COL_RED_DARK, COL_RED)

	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)

func _style_button(btn: Button, bg: Color, border: Color) -> void:
	var normal = _make_style(bg, border)
	var hover = _make_style(bg.lightened(0.15), border.lightened(0.1))
	var pressed = _make_style(bg.darkened(0.15), border)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", COL_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", COL_PARCHMENT.lightened(0.1))
	btn.add_theme_color_override("font_pressed_color", COL_PARCHMENT.darkened(0.1))

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(10)
	return s

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
