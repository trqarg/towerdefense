extends Label

var fade_timer: float = 0.0
var fade_duration: float = 0.5
var display_duration: float = 1.5
var total_time: float = 0.0

func show_message(msg: String) -> void:
	text = msg
	visible = true
	modulate.a = 1.0
	total_time = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	total_time += delta
	if total_time > display_duration:
		var fade_progress = (total_time - display_duration) / fade_duration
		modulate.a = 1.0 - clampf(fade_progress, 0.0, 1.0)
		if modulate.a <= 0.0:
			visible = false
