extends CanvasLayer

signal build_tower_pressed(tower_key: String)
signal next_wave_pressed
signal tower_upgrade_pressed
signal tower_sell_pressed
signal ability_pressed(ability_name: String)

# ── Theme colors ─────────────────────────────────
const COL_WOOD_DARK := Color(0.14, 0.09, 0.05)
const COL_WOOD := Color(0.22, 0.14, 0.07)
const COL_WOOD_LIGHT := Color(0.32, 0.22, 0.12)
const COL_GOLD := Color(0.85, 0.68, 0.18)
const COL_GOLD_BRIGHT := Color(1.0, 0.88, 0.3)
const COL_PARCHMENT := Color(0.95, 0.9, 0.72)
const COL_RED := Color(0.75, 0.18, 0.12)
const COL_RED_DARK := Color(0.5, 0.1, 0.06)
const COL_GREEN := Color(0.18, 0.55, 0.12)
const COL_GREEN_DARK := Color(0.12, 0.38, 0.08)
const COL_BLUE := Color(0.15, 0.35, 0.7)

# ── Tower data ───────────────────────────────────
var tower_data: Dictionary = {
	"basic": {"name": "Archer", "cost": 25, "color": Color(0.2, 0.4, 0.9), "icon": "bow"},
	"sniper": {"name": "Marksman", "cost": 50, "color": Color(0.15, 0.6, 0.2), "icon": "crosshair"},
	"cannon": {"name": "Artillery", "cost": 40, "color": Color(0.85, 0.5, 0.1), "icon": "bomb"},
	"frost": {"name": "Mage", "cost": 35, "color": Color(0.3, 0.75, 0.9), "icon": "crystal"},
	"laser": {"name": "Laser", "cost": 45, "color": Color(0.9, 0.25, 0.1), "icon": "beam"},
}

# ── Node references (built in code) ─────────────
var gold_label: Label
var lives_label: Label
var wave_label: Label
var next_wave_button: Button
var tower_buttons_container: HBoxContainer
var tower_buttons: Dictionary = {}  # key -> Button
var options_overlay: ColorRect
var options_panel: PanelContainer
var game_over_label: Label
var game_over_panel: PanelContainer

# Speed control
var current_speed: float = 1.0
var speed_button: Button

# Rain of Fire
var rain_cooldown: float = 0.0
const RAIN_COOLDOWN_MAX: float = 25.0
var rain_button: Button
var rain_cooldown_overlay: ColorRect

# Tower menu
var tower_menu: PanelContainer
var tower_menu_target: Node2D = null
var upgrade_btn: Button
var sell_btn: Button
var info_label: Label

@onready var banner: Label = $Banner

func _ready() -> void:
	_build_top_bar()
	_build_bottom_bar()
	_build_options_panel()
	_build_game_over_panel()
	_build_tower_menu()

# ══════════════════════════════════════════════════
# BUILDING THE UI
# ══════════════════════════════════════════════════

func _make_panel_style(bg: Color, border: Color, border_w: int = 2, radius: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	return s

func _make_button_style(bg: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(4)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(14)
	return s

func _style_button(btn: Button, bg: Color, border: Color, font_color: Color = COL_PARCHMENT, radius: int = 6) -> void:
	btn.add_theme_stylebox_override("normal", _make_button_style(bg, border, radius))
	btn.add_theme_stylebox_override("hover", _make_button_style(bg.lightened(0.15), border.lightened(0.1), radius))
	btn.add_theme_stylebox_override("pressed", _make_button_style(bg.darkened(0.15), border, radius))
	var dis_style = _make_button_style(bg.darkened(0.3), Color(0.3, 0.3, 0.3), radius)
	btn.add_theme_stylebox_override("disabled", dis_style)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color.lightened(0.15))
	btn.add_theme_color_override("font_pressed_color", font_color.darkened(0.1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.35))

# ── Top Bar ──────────────────────────────────────

func _build_top_bar() -> void:
	var top_bar = PanelContainer.new()
	top_bar.anchor_left = 0.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_bottom = 140
	var style = _make_panel_style(COL_WOOD_DARK, COL_GOLD, 0)
	style.border_width_bottom = 6
	style.border_color = COL_GOLD
	style.set_content_margin_all(20)
	top_bar.add_theme_stylebox_override("panel", style)
	add_child(top_bar)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	top_bar.add_child(hbox)

	# Gold
	var gold_box = _make_info_panel("gold")
	gold_label = gold_box.get_meta("label")
	hbox.add_child(gold_box)

	# Lives
	var lives_box = _make_info_panel("lives")
	lives_label = lives_box.get_meta("label")
	hbox.add_child(lives_box)

	# Wave
	var wave_box = _make_info_panel("wave")
	wave_label = wave_box.get_meta("label")
	hbox.add_child(wave_box)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Speed toggle
	speed_button = Button.new()
	speed_button.text = " 1x "
	speed_button.custom_minimum_size = Vector2(165, 102)
	speed_button.add_theme_font_size_override("font_size", 54)
	_style_button(speed_button, COL_WOOD, COL_GOLD)
	speed_button.pressed.connect(_on_speed_toggle)
	hbox.add_child(speed_button)

	# Options
	var opt_btn = Button.new()
	opt_btn.text = " Options "
	opt_btn.custom_minimum_size = Vector2(270, 102)
	opt_btn.add_theme_font_size_override("font_size", 48)
	_style_button(opt_btn, COL_WOOD, COL_GOLD)
	opt_btn.pressed.connect(_on_options_pressed)
	hbox.add_child(opt_btn)

func _make_info_panel(info_type: String) -> HBoxContainer:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)

	# Icon
	var icon_label = Label.new()
	icon_label.add_theme_font_size_override("font_size", 66)
	match info_type:
		"gold":
			icon_label.text = "coin"
			icon_label.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
		"lives":
			icon_label.text = "heart"
			icon_label.add_theme_color_override("font_color", COL_RED)
		"wave":
			icon_label.text = "flag"
			icon_label.add_theme_color_override("font_color", COL_PARCHMENT)

	# Use a colored polygon as icon
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(84, 84)
	var icon_style = StyleBoxFlat.new()
	icon_style.set_corner_radius_all(12)
	icon_style.set_content_margin_all(0)
	match info_type:
		"gold":
			icon_style.bg_color = Color(0.9, 0.72, 0.1)
			icon_style.border_color = Color(0.7, 0.55, 0.05)
		"lives":
			icon_style.bg_color = Color(0.8, 0.15, 0.1)
			icon_style.border_color = Color(0.6, 0.1, 0.05)
		"wave":
			icon_style.bg_color = Color(0.2, 0.45, 0.7)
			icon_style.border_color = Color(0.15, 0.3, 0.55)
	icon_style.set_border_width_all(4)
	icon_container.add_theme_stylebox_override("panel", icon_style)
	var icon_text = Label.new()
	icon_text.add_theme_font_size_override("font_size", 48)
	icon_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_text.add_theme_color_override("font_color", Color.WHITE)
	match info_type:
		"gold": icon_text.text = "$"
		"lives": icon_text.text = "♥"
		"wave": icon_text.text = "⚑"
	icon_container.add_child(icon_text)
	hb.add_child(icon_container)

	# Value label
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 66)
	lbl.add_theme_color_override("font_color", COL_PARCHMENT)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl)
	hb.set_meta("label", lbl)
	return hb

# ── Bottom Bar ───────────────────────────────────

func _build_bottom_bar() -> void:
	var bottom_bar = PanelContainer.new()
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_top = -280
	var style = _make_panel_style(COL_WOOD_DARK, COL_GOLD, 0)
	style.border_width_top = 6
	style.border_color = COL_GOLD
	style.set_content_margin_all(20)
	style.content_margin_top = 24
	bottom_bar.add_theme_stylebox_override("panel", style)
	add_child(bottom_bar)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_child(hbox)

	# Tower buttons
	tower_buttons_container = HBoxContainer.new()
	tower_buttons_container.add_theme_constant_override("separation", 24)
	hbox.add_child(tower_buttons_container)

	for key in tower_data:
		var data = tower_data[key]
		var btn = _make_tower_button(key, data)
		tower_buttons_container.add_child(btn)
		tower_buttons[key] = btn

	# Separator
	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(40, 0)
	sep.add_theme_color_override("separator", COL_GOLD.darkened(0.3))
	hbox.add_child(sep)

	# Rain of Fire ability
	rain_button = Button.new()
	rain_button.custom_minimum_size = Vector2(180, 168)
	rain_button.add_theme_font_size_override("font_size", 33)
	rain_button.text = "FIRE"
	_style_button(rain_button, COL_RED_DARK, Color(0.9, 0.4, 0.1), COL_PARCHMENT, 16)
	rain_button.tooltip_text = "Rain of Fire — AoE damage ability"
	rain_button.pressed.connect(func(): ability_pressed.emit("rain_of_fire"))
	# Wrap in a VBox with label below
	var fire_vbox = VBoxContainer.new()
	fire_vbox.add_theme_constant_override("separation", 4)
	fire_vbox.add_child(rain_button)
	var fire_lbl = Label.new()
	fire_lbl.text = "Ability"
	fire_lbl.add_theme_font_size_override("font_size", 30)
	fire_lbl.add_theme_color_override("font_color", COL_GOLD.darkened(0.2))
	fire_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire_vbox.add_child(fire_lbl)
	hbox.add_child(fire_vbox)

	# Separator
	var sep2 = VSeparator.new()
	sep2.custom_minimum_size = Vector2(40, 0)
	sep2.add_theme_color_override("separator", COL_GOLD.darkened(0.3))
	hbox.add_child(sep2)

	# Next Wave button
	next_wave_button = Button.new()
	next_wave_button.text = "  SEND WAVE  "
	next_wave_button.custom_minimum_size = Vector2(480, 168)
	next_wave_button.add_theme_font_size_override("font_size", 60)
	_style_button(next_wave_button, COL_GREEN_DARK, COL_GREEN.lightened(0.2), COL_PARCHMENT, 16)
	next_wave_button.pressed.connect(func(): next_wave_pressed.emit())
	hbox.add_child(next_wave_button)

func _make_tower_button(key: String, data: Dictionary) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 168)
	btn.add_theme_font_size_override("font_size", 33)
	_style_button(btn, COL_WOOD, data["color"].darkened(0.3), data["color"].lightened(0.3), 16)

	# Icon text inside button
	match key:
		"basic": btn.text = "↑"
		"sniper": btn.text = "◎"
		"cannon": btn.text = "●"
		"frost": btn.text = "❄"
		"laser": btn.text = "⚡"
	btn.add_theme_font_size_override("font_size", 72)

	var k = key
	btn.pressed.connect(func(): build_tower_pressed.emit(k))
	vbox.add_child(btn)

	# Cost label
	var cost_lbl = Label.new()
	cost_lbl.text = "%dg" % data["cost"]
	cost_lbl.add_theme_font_size_override("font_size", 36)
	cost_lbl.add_theme_color_override("font_color", COL_GOLD)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_lbl)

	return vbox

# ── Options Panel ────────────────────────────────

func _build_options_panel() -> void:
	# Dim overlay behind options (separate node so it covers full screen)
	options_overlay = ColorRect.new()
	options_overlay.visible = false
	options_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	options_overlay.color = Color(0, 0, 0, 0.5)
	options_overlay.anchor_left = 0.0
	options_overlay.anchor_top = 0.0
	options_overlay.anchor_right = 1.0
	options_overlay.anchor_bottom = 1.0
	options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(options_overlay)

	options_panel = PanelContainer.new()
	options_panel.visible = false
	options_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	options_panel.anchor_left = 0.5
	options_panel.anchor_top = 0.5
	options_panel.anchor_right = 0.5
	options_panel.anchor_bottom = 0.5
	options_panel.offset_left = -400
	options_panel.offset_top = -350
	options_panel.offset_right = 400
	options_panel.offset_bottom = 350

	var style = _make_panel_style(COL_WOOD_DARK, COL_GOLD, 6, 24)
	style.set_content_margin_all(50)
	options_panel.add_theme_stylebox_override("panel", style)
	add_child(options_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	options_panel.add_child(vbox)

	var title = Label.new()
	title.text = "OPTIONS"
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Fullscreen
	var fs = CheckButton.new()
	fs.text = "Fullscreen"
	fs.add_theme_font_size_override("font_size", 54)
	fs.add_theme_color_override("font_color", COL_PARCHMENT)
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fs)

	# Difficulty
	var diff_hbox = HBoxContainer.new()
	diff_hbox.add_theme_constant_override("separation", 30)
	var diff_lbl = Label.new()
	diff_lbl.text = "Difficulty:"
	diff_lbl.add_theme_font_size_override("font_size", 54)
	diff_lbl.add_theme_color_override("font_color", COL_PARCHMENT)
	diff_hbox.add_child(diff_lbl)
	var diff_opt = OptionButton.new()
	diff_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_opt.add_theme_font_size_override("font_size", 48)
	for dname in GameState.DIFFICULTY_NAMES:
		diff_opt.add_item(dname)
	diff_opt.selected = GameState.difficulty
	diff_opt.item_selected.connect(_on_difficulty_changed)
	diff_hbox.add_child(diff_opt)
	vbox.add_child(diff_hbox)

	# Resume
	var resume = Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(0, 126)
	resume.add_theme_font_size_override("font_size", 60)
	_style_button(resume, COL_GREEN_DARK, COL_GREEN.lightened(0.2))
	resume.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume)

	# Exit
	var exit_btn = Button.new()
	exit_btn.text = "Exit to Menu"
	exit_btn.custom_minimum_size = Vector2(0, 126)
	exit_btn.add_theme_font_size_override("font_size", 60)
	_style_button(exit_btn, COL_RED_DARK, COL_RED)
	exit_btn.pressed.connect(_on_exit_to_menu_pressed)
	vbox.add_child(exit_btn)

# ── Game Over Panel ──────────────────────────────

func _build_game_over_panel() -> void:
	# Background dim
	game_over_panel = PanelContainer.new()
	game_over_panel.visible = false
	game_over_panel.anchor_left = 0.5
	game_over_panel.anchor_top = 0.5
	game_over_panel.anchor_right = 0.5
	game_over_panel.anchor_bottom = 0.5
	game_over_panel.offset_left = -500
	game_over_panel.offset_top = -300
	game_over_panel.offset_right = 500
	game_over_panel.offset_bottom = 300

	var style = _make_panel_style(COL_WOOD_DARK, COL_GOLD, 6, 24)
	style.set_content_margin_all(60)
	game_over_panel.add_theme_stylebox_override("panel", style)
	add_child(game_over_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 36)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(vbox)

	game_over_label = Label.new()
	game_over_label.add_theme_font_size_override("font_size", 114)
	game_over_label.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
	game_over_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	game_over_label.add_theme_constant_override("shadow_offset_x", 4)
	game_over_label.add_theme_constant_override("shadow_offset_y", 4)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(game_over_label)

	# Stars label (will be updated on game over)
	var stars_lbl = Label.new()
	stars_lbl.name = "StarsLabel"
	stars_lbl.add_theme_font_size_override("font_size", 126)
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
	vbox.add_child(stars_lbl)

	var menu_btn = Button.new()
	menu_btn.text = "Back to Menu"
	menu_btn.custom_minimum_size = Vector2(600, 144)
	menu_btn.add_theme_font_size_override("font_size", 60)
	_style_button(menu_btn, COL_WOOD, COL_GOLD)
	menu_btn.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

# ── Tower Selection Menu ─────────────────────────

func _build_tower_menu() -> void:
	tower_menu = PanelContainer.new()
	tower_menu.visible = false
	tower_menu.custom_minimum_size = Vector2(600, 0)
	tower_menu.z_index = 10

	var style = _make_panel_style(Color(0.1, 0.07, 0.03, 0.95), COL_GOLD, 4, 20)
	style.set_content_margin_all(30)
	tower_menu.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	tower_menu.add_child(vbox)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 42)
	info_label.add_theme_color_override("font_color", COL_PARCHMENT)
	vbox.add_child(info_label)

	# Separator line
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", COL_GOLD.darkened(0.3))
	vbox.add_child(sep)

	upgrade_btn = Button.new()
	upgrade_btn.custom_minimum_size = Vector2(0, 108)
	upgrade_btn.add_theme_font_size_override("font_size", 48)
	_style_button(upgrade_btn, COL_GREEN_DARK, COL_GREEN.lightened(0.2))
	upgrade_btn.pressed.connect(func(): tower_upgrade_pressed.emit())
	vbox.add_child(upgrade_btn)

	sell_btn = Button.new()
	sell_btn.custom_minimum_size = Vector2(0, 108)
	sell_btn.add_theme_font_size_override("font_size", 48)
	_style_button(sell_btn, COL_RED_DARK, COL_RED)
	sell_btn.pressed.connect(func(): tower_sell_pressed.emit())
	vbox.add_child(sell_btn)

	add_child(tower_menu)

# ══════════════════════════════════════════════════
# RUNTIME LOGIC
# ══════════════════════════════════════════════════

func _process(delta: float) -> void:
	# Rain of Fire cooldown
	if rain_cooldown > 0.0:
		rain_cooldown -= delta
		if rain_cooldown <= 0.0:
			rain_cooldown = 0.0
			rain_button.text = "FIRE"
			rain_button.disabled = false
		else:
			rain_button.text = "%.0fs" % rain_cooldown
			rain_button.disabled = true

	# Tower menu tracking
	if tower_menu.visible and tower_menu_target and is_instance_valid(tower_menu_target):
		var screen_pos = tower_menu_target.get_global_transform_with_canvas().origin
		tower_menu.position = Vector2(screen_pos.x - tower_menu.size.x / 2, screen_pos.y - tower_menu.size.y - 35)
		var vp = get_viewport().get_visible_rect().size
		tower_menu.position.x = clampf(tower_menu.position.x, 4, vp.x - tower_menu.size.x - 4)
		tower_menu.position.y = clampf(tower_menu.position.y, 145, vp.y - tower_menu.size.y - 285)

# ── Tower Menu ───────────────────────────────────

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
		upgrade_btn.text = "⬆ Upgrade (%dg)" % ucost
		upgrade_btn.disabled = player_gold < ucost
	else:
		upgrade_btn.text = "★ MAX LEVEL"
		upgrade_btn.disabled = true
	sell_btn.text = "Sell (+%dg)" % t.get_sell_value()

func hide_tower_menu() -> void:
	tower_menu.visible = false
	tower_menu_target = null

func start_rain_cooldown() -> void:
	rain_cooldown = RAIN_COOLDOWN_MAX

# ── Speed ────────────────────────────────────────

func _on_speed_toggle() -> void:
	if current_speed == 1.0:
		current_speed = 2.0
		speed_button.text = " 2x "
	else:
		current_speed = 1.0
		speed_button.text = " 1x "
	Engine.time_scale = current_speed

# ── Updates ──────────────────────────────────────

func update_gold(amount: int) -> void:
	gold_label.text = "%d" % amount
	if tower_menu.visible:
		_refresh_tower_menu(amount)

func update_lives(amount: int) -> void:
	lives_label.text = "%d" % amount

func update_wave(current: int, total: int) -> void:
	wave_label.text = "%d / %d" % [current, total]

func set_next_wave_enabled(enabled: bool) -> void:
	next_wave_button.disabled = not enabled

func set_building_enabled(enabled: bool) -> void:
	for key in tower_buttons:
		# The button is inside a VBoxContainer, first child
		var vbox = tower_buttons[key]
		var btn = vbox.get_child(0) as Button
		btn.disabled = not enabled

# ── Options ──────────────────────────────────────

func _on_options_pressed() -> void:
	options_overlay.visible = true
	options_panel.visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	options_overlay.visible = false
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

# ── Banner ───────────────────────────────────────

func show_banner(msg: String) -> void:
	banner.show_message(msg)

# ── Game Over ────────────────────────────────────

func show_game_over(won: bool, stars: int = 0) -> void:
	Engine.time_scale = 1.0
	hide_tower_menu()

	if won:
		game_over_label.text = "VICTORY!"
		game_over_label.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
		var stars_lbl = game_over_panel.get_node("VBoxContainer/StarsLabel") as Label
		stars_lbl.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	else:
		game_over_label.text = "DEFEAT"
		game_over_label.add_theme_color_override("font_color", COL_RED)
		var stars_lbl = game_over_panel.get_node("VBoxContainer/StarsLabel") as Label
		stars_lbl.text = ""

	game_over_panel.visible = true
	next_wave_button.disabled = true
	rain_button.disabled = true
	speed_button.disabled = true
	set_building_enabled(false)
