extends CanvasLayer
## Botões virtuais translúcidos para celular: D-Pad à esquerda e 6 botões à direita
## (Soco 1, Soco 2, Chute 1, Chute 2, Defesa, Arma).
##
## Cada TouchScreenButton dispara a mesma ação do controle físico (p1_*), então os
## lutadores não sabem se o input veio do toque, do teclado ou do controle.

const DPAD_CENTER := Vector2(260, 740)
const DPAD_OFFSET := 120.0
const DPAD_RADIUS := 70.0
const BUTTON_RADIUS := 72.0

const ATTACK_BUTTONS := [
	{"action": "punch_light", "label": "Soco 1", "pos": Vector2(1450, 660)},
	{"action": "punch_heavy", "label": "Soco 2", "pos": Vector2(1620, 610)},
	{"action": "kick_light", "label": "Chute 1", "pos": Vector2(1450, 830)},
	{"action": "kick_heavy", "label": "Chute 2", "pos": Vector2(1620, 780)},
	{"action": "block", "label": "Defesa", "pos": Vector2(1790, 720)},
	{"action": "toggle_weapon", "label": "Arma", "pos": Vector2(1790, 530)},
]


func _ready() -> void:
	layer = 10
	var dpad := {
		"up": [Vector2(0, -1), "▲"],
		"down": [Vector2(0, 1), "▼"],
		"left": [Vector2(-1, 0), "◀"],
		"right": [Vector2(1, 0), "▶"],
	}
	for action in dpad:
		var offset: Vector2 = dpad[action][0]
		# passby_press: arrastar o dedo entre as direções funciona (meia-lua no touch).
		_add_button(action, dpad[action][1], DPAD_CENTER + offset * DPAD_OFFSET, DPAD_RADIUS, true)
	for b in ATTACK_BUTTONS:
		_add_button(b.action, b.label, b.pos, BUTTON_RADIUS, false)
	_update_visibility()
	InputManager.device_changed.connect(func(_d: String): _update_visibility())


func _update_visibility() -> void:
	visible = GameManager.should_show_touch_controls()
	for child in get_children():
		child.modulate.a = GameManager.mobile_button_opacity


func _add_button(action: String, text: String, at: Vector2, radius: float, passby: bool) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var button := TouchScreenButton.new()
	button.shape = shape
	button.action = InputManager.action_name(0, action)
	button.passby_press = passby
	button.position = at
	var visual := ButtonVisual.new()
	visual.radius = radius
	visual.text = text
	button.add_child(visual)
	button.pressed.connect(visual.set_pressed.bind(true))
	button.released.connect(visual.set_pressed.bind(false))
	add_child(button)


class ButtonVisual extends Node2D:
	var radius := 70.0
	var text := ""
	var _pressed := false

	func set_pressed(value: bool) -> void:
		_pressed = value
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.45 if _pressed else 0.2))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 4.0, true)
		var font := ThemeDB.fallback_font
		var font_size := 28
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, Vector2(-text_size.x / 2.0, font_size / 3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
