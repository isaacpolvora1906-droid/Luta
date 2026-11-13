extends "res://tests/test_case.gd"

const InputManagerScript := preload("res://Core/InputManager.gd")


func test_roster_has_26_states_without_df() -> void:
	assert_eq(Roster.CHARACTERS.size(), 26, "26 personagens")
	var ufs := {}
	for character in Roster.CHARACTERS:
		for key in ["uf", "animal", "style", "weapon", "stage"]:
			assert_true(str(character.get(key, "")) != "", "%s sem %s" % [character.get("uf"), key])
		ufs[character.uf] = true
	assert_eq(ufs.size(), 26, "UFs únicas")
	assert_false(ufs.has("DF"), "DF fora por enquanto")
	assert_true(Roster.CHARACTERS.size() <= Roster.GRID_COLUMNS * Roster.GRID_ROWS, "cabe na grade 6x5")
	assert_eq(Roster.find("AM").animal, "Onça-Pintada", "busca por UF")


func test_input_manager_maps_actions_to_bits() -> void:
	var manager: Node = track(InputManagerScript.new())
	manager.register_default_actions()
	for action in InputManagerScript.ACTIONS:
		assert_true(InputMap.has_action("p1_" + action), "ação p1_" + action)
		assert_true(InputMap.has_action("p2_" + action), "ação p2_" + action)
	Input.action_press("p1_punch_light")
	Input.action_press("p1_toggle_weapon")
	assert_eq(manager.read_bits(0), InputBuffer.PUNCH_LIGHT | InputBuffer.WEAPON, "bits do J1")
	assert_eq(manager.read_bits(1), 0, "J2 sem input")
	Input.action_release("p1_punch_light")
	Input.action_release("p1_toggle_weapon")
	assert_eq(manager.read_bits(0), 0, "soltou")
