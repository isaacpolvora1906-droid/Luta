extends "res://tests/test_case.gd"


func test_keeps_only_last_frames() -> void:
	var buffer := InputBuffer.new(30)
	for i in 45:
		buffer.push(0)
	assert_eq(buffer.frame_count(), 30, "tamanho do buffer")


func test_just_pressed_and_held() -> void:
	var buffer := InputBuffer.new()
	buffer.push(0)
	buffer.push(InputBuffer.PUNCH_LIGHT)
	assert_true(buffer.is_just_pressed(InputBuffer.PUNCH_LIGHT), "acabou de apertar")
	buffer.push(InputBuffer.PUNCH_LIGHT)
	assert_false(buffer.is_just_pressed(InputBuffer.PUNCH_LIGHT), "segurando não é novo aperto")
	assert_true(buffer.is_held(InputBuffer.PUNCH_LIGHT), "segurando")


func test_pressed_within_window() -> void:
	var buffer := InputBuffer.new()
	buffer.push(InputBuffer.KICK_LIGHT)
	buffer.push(0)
	buffer.push(0)
	assert_true(buffer.was_pressed_within(InputBuffer.KICK_LIGHT, 3), "dentro da janela")
	assert_false(buffer.was_pressed_within(InputBuffer.KICK_LIGHT, 2), "fora da janela")


func test_opposite_directions_cancel() -> void:
	assert_eq(InputBuffer.horizontal(InputBuffer.LEFT | InputBuffer.RIGHT), 0, "esquerda+direita")
	assert_eq(InputBuffer.to_numpad(InputBuffer.UP | InputBuffer.DOWN, true), 5, "cima+baixo")


func test_numpad_is_relative_to_facing() -> void:
	assert_eq(InputBuffer.to_numpad(InputBuffer.DOWN | InputBuffer.RIGHT, true), 3, "baixo+frente olhando à direita")
	assert_eq(InputBuffer.to_numpad(InputBuffer.DOWN | InputBuffer.RIGHT, false), 1, "baixo+trás olhando à esquerda")
	assert_eq(InputBuffer.to_numpad(InputBuffer.LEFT, true), 4, "trás")
	assert_eq(InputBuffer.to_numpad(InputBuffer.UP | InputBuffer.LEFT, false), 9, "cima+frente olhando à esquerda")


func test_quarter_circle_motion() -> void:
	var buffer := InputBuffer.new()
	for bits in [InputBuffer.DOWN, InputBuffer.DOWN | InputBuffer.RIGHT, InputBuffer.RIGHT | InputBuffer.PUNCH_LIGHT]:
		buffer.push(bits)
	var qcf: Array[int] = [2, 3, 6]
	assert_true(buffer.matches_motion(qcf, true), "meia-lua para frente")
	var qcb: Array[int] = [2, 1, 4]
	assert_false(buffer.matches_motion(qcb, true), "meia-lua para trás não confere")


func test_motion_outside_window_is_ignored() -> void:
	var buffer := InputBuffer.new()
	buffer.push(InputBuffer.LEFT)
	buffer.push(InputBuffer.RIGHT)
	for i in 10:
		buffer.push(0)
	buffer.push(InputBuffer.LEFT)
	var motion: Array[int] = [4, 6, 4]
	assert_true(buffer.matches_motion(motion, true, 13), "dentro da janela")
	assert_false(buffer.matches_motion(motion, true, 5), "fora da janela")
