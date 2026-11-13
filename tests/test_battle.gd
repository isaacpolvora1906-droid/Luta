extends "res://tests/test_case.gd"


func _new_battle() -> BattleManager:
	var battle := track(BattleManager.new()) as BattleManager
	battle.setup(new_fighter(), new_fighter())
	return battle


func _step_n(battle: BattleManager, p1: int, p2: int, frames: int) -> void:
	for i in frames:
		battle.step(p1, p2)


func _place(battle: BattleManager, x1: float, x2: float) -> void:
	battle.fighters[0].pos.x = x1
	battle.fighters[1].pos.x = x2


func test_round_starts_facing_each_other() -> void:
	var battle := _new_battle()
	assert_true(battle.fighters[0].facing_right, "J1 olha para a direita")
	assert_false(battle.fighters[1].facing_right, "J2 olha para a esquerda")
	assert_eq(battle.seconds_left(), 99, "timer")


func test_far_jab_misses() -> void:
	var battle := _new_battle()
	battle.step(InputBuffer.PUNCH_LIGHT, 0)
	_step_n(battle, 0, 0, 20)
	assert_eq(battle.fighters[1].health, Fighter.MAX_HEALTH, "sem dano de longe")


func test_close_jab_hits_and_builds_meter() -> void:
	var battle := _new_battle()
	_place(battle, -0.4, 0.4)
	var hits: Array = []
	battle.hit_landed.connect(func(a: int, blocked: bool, dmg: int): hits.append([a, blocked, dmg]))
	battle.step(InputBuffer.PUNCH_LIGHT, 0)
	_step_n(battle, 0, 0, 10)
	var p1 := battle.fighters[0]
	var p2 := battle.fighters[1]
	assert_eq(p2.health, Fighter.MAX_HEALTH - 50, "dano do jab")
	assert_eq(hits.size(), 1, "acerta uma vez só")
	assert_true(p1.super_meter > 0.0, "quem bate enche a barra")
	assert_true(p2.super_meter > 0.0, "quem apanha enche a barra")
	assert_true(p2.pos.x > 0.4, "empurrão")


func test_weapon_reaches_farther() -> void:
	var battle := _new_battle()
	_place(battle, -0.75, 0.75)
	battle.fighters[0].stance = Fighter.Stance.WEAPON
	battle.step(InputBuffer.PUNCH_LIGHT, 0)
	_step_n(battle, 0, 0, 10)
	assert_eq(battle.fighters[1].health, Fighter.MAX_HEALTH - 60, "corte armado acerta de longe com +20%")


func test_simultaneous_hits_trade() -> void:
	var battle := _new_battle()
	_place(battle, -0.4, 0.4)
	battle.step(InputBuffer.PUNCH_LIGHT, InputBuffer.PUNCH_LIGHT)
	_step_n(battle, 0, 0, 10)
	assert_eq(battle.fighters[0].health, Fighter.MAX_HEALTH - 50, "J1 apanhou")
	assert_eq(battle.fighters[1].health, Fighter.MAX_HEALTH - 50, "J2 apanhou")


func test_knockout_ends_round() -> void:
	var battle := _new_battle()
	var winners: Array = []
	battle.round_ended.connect(func(w: int): winners.append(w))
	_place(battle, -0.4, 0.4)
	battle.fighters[1].health = 40
	battle.step(InputBuffer.PUNCH_LIGHT, 0)
	_step_n(battle, 0, 0, 10)
	assert_eq(battle.fighters[1].state, Fighter.State.KO, "nocaute")
	assert_true(battle.round_over, "round acabou")
	assert_eq(winners, [0], "J1 venceu o round")
	assert_eq(battle.wins, [1, 0] as Array[int], "placar")


func test_time_over_goes_to_more_health() -> void:
	var battle := _new_battle()
	battle.fighters[0].health = 500
	battle.frames_left = 1
	battle.step(0, 0)
	assert_true(battle.round_over, "tempo acabou")
	assert_eq(battle.wins, [0, 1] as Array[int], "J2 tinha mais vida")


func test_match_ends_after_two_round_wins() -> void:
	var battle := _new_battle()
	var match_winner: Array = []
	battle.match_ended.connect(func(w: int): match_winner.append(w))
	for round_index in 2:
		if round_index > 0:
			battle.start_round()
		battle.fighters[0].health = 1
		battle.frames_left = 1
		battle.step(0, 0)
	assert_true(battle.match_over, "partida acabou")
	assert_eq(match_winner, [1], "J2 venceu a partida")
	assert_eq(battle.round_number, 2, "dois rounds")


func test_fighters_turn_around_when_crossing() -> void:
	var battle := _new_battle()
	_place(battle, 2.0, -2.0)
	battle.step(0, 0)
	assert_false(battle.fighters[0].facing_right, "J1 vira")
	assert_true(battle.fighters[1].facing_right, "J2 vira")


func test_fighters_do_not_overlap() -> void:
	var battle := _new_battle()
	_step_n(battle, InputBuffer.RIGHT, InputBuffer.LEFT, 120)
	var gap := battle.fighters[1].pos.x - battle.fighters[0].pos.x
	assert_true(gap >= BattleManager.PUSH_DISTANCE - 0.001, "distância mínima mantida (%f)" % gap)
