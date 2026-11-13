extends "res://tests/test_case.gd"


func test_stance_switch_takes_configured_frames() -> void:
	assert_true(Fighter.STANCE_SWITCH_FRAMES >= 8 and Fighter.STANCE_SWITCH_FRAMES <= 12, "GDD: 8 a 12 frames")
	var f := new_fighter()
	f.step(InputBuffer.WEAPON)
	assert_eq(f.state, Fighter.State.SWITCH_STANCE, "entra na troca")
	step_n(f, 0, Fighter.STANCE_SWITCH_FRAMES - 1)
	assert_eq(f.stance, Fighter.Stance.BARE_HANDS, "ainda de mão nua no penúltimo frame")
	f.step(0)
	assert_eq(f.stance, Fighter.Stance.WEAPON, "armado ao fim da troca")
	assert_eq(f.state, Fighter.State.IDLE, "volta ao idle")


func test_hit_during_switch_cancels_it() -> void:
	var f := new_fighter()
	f.step(InputBuffer.WEAPON)
	f.step(0)
	var clean := f.receive_hit(DefaultMoves.bare_hands()[InputBuffer.PUNCH_LIGHT], 50, 1.0)
	assert_true(clean, "acerto limpo durante a troca")
	assert_eq(f.state, Fighter.State.HIT, "leva hitstun")
	step_n(f, 0, 30)
	assert_eq(f.state, Fighter.State.IDLE, "recupera")
	assert_eq(f.stance, Fighter.Stance.BARE_HANDS, "troca cancelada")


func test_bare_hands_walk_is_15_percent_faster() -> void:
	var bare := new_fighter()
	var armed := new_fighter()
	armed.stance = Fighter.Stance.WEAPON
	bare.step(InputBuffer.RIGHT)
	armed.step(InputBuffer.RIGHT)
	assert_almost(armed.pos.x, Fighter.WALK_SPEED, "velocidade armado")
	assert_almost(bare.pos.x / armed.pos.x, 1.15, "mão nua / armado")


func test_weapon_attack_has_more_damage_and_recovery() -> void:
	var bare := new_fighter()
	bare.step(InputBuffer.PUNCH_LIGHT)
	var armed := new_fighter()
	armed.stance = Fighter.Stance.WEAPON
	armed.step(InputBuffer.PUNCH_LIGHT)
	var weapon_jab: AttackData = armed.current_attack
	assert_eq(armed.attack_damage(), roundi(weapon_jab.damage * 1.2), "+20% de dano armado")
	assert_eq(armed.attack_total_frames(), weapon_jab.total_frames() + Fighter.WEAPON_EXTRA_RECOVERY, "recuperação maior armado")
	assert_true(weapon_jab.hitbox.end.x > bare.current_attack.hitbox.end.x, "alcance maior armado")


func test_attack_is_active_only_in_its_window() -> void:
	var f := new_fighter()
	f.step(InputBuffer.PUNCH_LIGHT)
	var data: AttackData = f.current_attack
	var active_frames := 0
	for i in data.total_frames():
		assert_false(f.state == Fighter.State.IDLE, "ainda atacando no frame %d" % i)
		if f.can_hit():
			active_frames += 1
			assert_true(f.state_frame > data.startup, "não ativo durante o startup")
		f.step(0)
	assert_eq(active_frames, data.active, "frames ativos")
	assert_eq(f.state, Fighter.State.IDLE, "volta ao idle no fim")


func test_jump_is_not_controllable_in_the_air() -> void:
	var f := new_fighter()
	f.step(InputBuffer.UP | InputBuffer.RIGHT)
	assert_eq(f.state, Fighter.State.JUMP, "pulou")
	var vx := f.air_velocity.x
	step_n(f, InputBuffer.LEFT, 5)
	assert_almost(f.air_velocity.x, vx, "direção fixa no ar")
	assert_true(f.pos.x > 0.0, "continua indo para a direita")
	step_n(f, 0, 60)
	assert_eq(f.state, Fighter.State.IDLE, "aterrissa")
	assert_eq(f.pos.y, 0.0, "no chão")


func test_block_takes_only_chip_damage() -> void:
	var f := new_fighter()
	f.step(InputBuffer.BLOCK)
	assert_eq(f.state, Fighter.State.BLOCK, "defendendo")
	var data := AttackData.create("t", "", 100, 1, 1, 1, 10, 5, Rect2())
	var clean := f.receive_hit(data, 100, 1.0)
	assert_false(clean, "defendido")
	assert_eq(f.health, Fighter.MAX_HEALTH - 15, "só dano chip")
	assert_eq(f.state, Fighter.State.BLOCK, "continua defendendo")


func test_grab_ignores_block() -> void:
	var f := new_fighter()
	f.step(InputBuffer.BLOCK)
	var grab := AttackData.create("grab", "", 100, 1, 1, 1, 10, 5, Rect2())
	grab.unblockable = true
	assert_true(f.receive_hit(grab, 100, 1.0), "agarrão passa pela defesa")
	assert_eq(f.health, Fighter.MAX_HEALTH - 100, "dano cheio")


func test_super_needs_three_bars_and_motion() -> void:
	var f := new_fighter()
	f.super_meter = 300.0
	for bits in [InputBuffer.LEFT, InputBuffer.RIGHT, InputBuffer.LEFT | InputBuffer.PUNCH_HEAVY]:
		f.step(bits)
	assert_eq(f.state, Fighter.State.SUPER, "Super ativado")
	assert_eq(f.super_meter, 0.0, "gastou 3 barras")


func test_super_without_full_meter_is_normal_attack() -> void:
	var f := new_fighter()
	f.super_meter = 299.0
	for bits in [InputBuffer.LEFT, InputBuffer.RIGHT, InputBuffer.LEFT | InputBuffer.PUNCH_HEAVY]:
		f.step(bits)
	assert_eq(f.state, Fighter.State.ATTACK, "golpe normal")
	assert_eq(f.super_meter, 299.0, "não gastou barra")


func test_super_motion_mirrors_when_facing_left() -> void:
	var f := new_fighter()
	f.facing_right = false
	f.super_meter = 300.0
	for bits in [InputBuffer.RIGHT, InputBuffer.LEFT, InputBuffer.RIGHT | InputBuffer.PUNCH_HEAVY]:
		f.step(bits)
	assert_eq(f.state, Fighter.State.SUPER, "trás = direita olhando à esquerda")


func test_crouch_avoids_high_jab() -> void:
	var defender := new_fighter()
	defender.step(InputBuffer.DOWN)
	var attacker := new_fighter()
	attacker.reset_for_round(-0.6, true)
	attacker.step(InputBuffer.PUNCH_LIGHT)
	assert_false(attacker.get_hitbox().intersects(defender.get_hurtbox()), "jab passa por cima")
	defender.step(0)
	assert_true(attacker.get_hitbox().intersects(defender.get_hurtbox()), "acerta em pé")
