extends Control

func _ready() -> void:
	$VBoxContainer/FullscreenCheck.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	$VBoxContainer/FullscreenCheck.toggled.connect(_on_fullscreen_toggled)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
