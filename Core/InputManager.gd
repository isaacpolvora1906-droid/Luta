extends Node
## Autoload que centraliza teclado, controle e toque.
##
## Os lutadores nunca leem o Input direto: o InputManager converte as ações de cada
## jogador num bitmask (InputBuffer). Os botões touch da tela usam as mesmas ações,
## então nada muda nos personagens no celular.

signal device_changed(device: String)

const ACTIONS := {
	"left": InputBuffer.LEFT,
	"right": InputBuffer.RIGHT,
	"up": InputBuffer.UP,
	"down": InputBuffer.DOWN,
	"punch_light": InputBuffer.PUNCH_LIGHT,
	"punch_heavy": InputBuffer.PUNCH_HEAVY,
	"kick_light": InputBuffer.KICK_LIGHT,
	"kick_heavy": InputBuffer.KICK_HEAVY,
	"block": InputBuffer.BLOCK,
	"toggle_weapon": InputBuffer.WEAPON,
}

## Teclado: J1 = WASD + U I J K O L; J2 = setas + teclado numérico.
const KEYBOARD := [
	{
		"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
		"punch_light": KEY_U, "punch_heavy": KEY_I, "kick_light": KEY_J, "kick_heavy": KEY_K,
		"block": KEY_O, "toggle_weapon": KEY_L,
	},
	{
		"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN,
		"punch_light": KEY_KP_4, "punch_heavy": KEY_KP_5, "kick_light": KEY_KP_1, "kick_heavy": KEY_KP_2,
		"block": KEY_KP_6, "toggle_weapon": KEY_KP_3,
	},
]

## Controle (layout Xbox): X/Y socos, A/B chutes, RB defesa, LT ou LB troca de arma.
const JOY_BUTTONS := {
	"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
	"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN,
	"punch_light": JOY_BUTTON_X, "punch_heavy": JOY_BUTTON_Y,
	"kick_light": JOY_BUTTON_A, "kick_heavy": JOY_BUTTON_B,
	"block": JOY_BUTTON_RIGHT_SHOULDER, "toggle_weapon": JOY_BUTTON_LEFT_SHOULDER,
}

const DEADZONE := 0.5

## Dispositivo principal: "keyboard", "gamepad" ou "touch". Definido pelo primeiro input.
var primary_device := ""


func _ready() -> void:
	register_default_actions()


static func action_name(player: int, action: String) -> String:
	return "p%d_%s" % [player + 1, action]


## Cria as ações p1_* e p2_* com os controles padrão (sem sobrescrever as do projeto).
func register_default_actions() -> void:
	for player in 2:
		for action in ACTIONS:
			var action_id := action_name(player, action)
			if InputMap.has_action(action_id):
				continue
			InputMap.add_action(action_id, DEADZONE)
			InputMap.action_add_event(action_id, _key_event(KEYBOARD[player][action]))
			InputMap.action_add_event(action_id, _joy_button_event(player, JOY_BUTTONS[action]))
			for motion in _joy_motion_events(player, action):
				InputMap.action_add_event(action_id, motion)


## Bitmask do InputBuffer com o que o jogador está segurando neste frame.
func read_bits(player: int) -> int:
	var bits := 0
	for action in ACTIONS:
		if Input.is_action_pressed(action_name(player, action)):
			bits |= ACTIONS[action]
	return bits


func _input(event: InputEvent) -> void:
	var device := ""
	if event is InputEventScreenTouch:
		device = "touch"
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > DEADZONE):
		device = "gamepad"
	elif event is InputEventKey:
		device = "keyboard"
	if device != "" and device != primary_device:
		primary_device = device
		device_changed.emit(device)


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


func _joy_button_event(device: int, button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	return event


func _joy_motion_events(device: int, action: String) -> Array[InputEventJoypadMotion]:
	var events: Array[InputEventJoypadMotion] = []
	match action:
		"left":
			events.append(_joy_axis_event(device, JOY_AXIS_LEFT_X, -1.0))
		"right":
			events.append(_joy_axis_event(device, JOY_AXIS_LEFT_X, 1.0))
		"up":
			events.append(_joy_axis_event(device, JOY_AXIS_LEFT_Y, -1.0))
		"down":
			events.append(_joy_axis_event(device, JOY_AXIS_LEFT_Y, 1.0))
		"toggle_weapon":
			events.append(_joy_axis_event(device, JOY_AXIS_TRIGGER_LEFT, 1.0))
	return events


func _joy_axis_event(device: int, axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	return event
