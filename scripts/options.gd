extends Control

const COL_WOOD := Color(0.22, 0.14, 0.07)
const COL_GOLD := Color(0.85, 0.68, 0.18)
const COL_PARCHMENT := Color(0.95, 0.9, 0.72)
const COL_RED_DARK := Color(0.5, 0.1, 0.06)
const COL_RED := Color(0.75, 0.18, 0.12)

func _ready() -> void:
	$VBoxContainer/FullscreenCheck.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	$VBoxContainer/FullscreenCheck.toggled.connect(_on_fullscreen_toggled)

	var back_btn = $VBoxContainer/BackButton
	_style_button(back_btn, COL_RED_DARK, COL_RED)
	back_btn.pressed.connect(_on_back_pressed)

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
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(10)
	return s

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
