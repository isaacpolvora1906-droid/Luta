class_name BattleManager
extends Node
## Controla uma luta: vida, rounds, timer, colisão de golpes e distância entre lutadores.
##
## step() avança um frame lógico com o input dos dois jogadores. Os acertos dos dois
## lados são calculados antes de qualquer um ser aplicado, então golpes simultâneos trocam dano.

signal round_started(round_number: int)
## winner: 0 ou 1, ou -1 em empate.
signal round_ended(winner: int)
signal match_ended(winner: int)
signal hit_landed(attacker: int, blocked: bool, damage: int)

const ROUNDS_TO_WIN := 2
const ROUND_SECONDS := 99
const TICKS_PER_SECOND := 60
const STAGE_HALF_WIDTH := 6.0
const START_OFFSET := 1.5
## Distância mínima entre os lutadores (eles não se atravessam).
const PUSH_DISTANCE := 0.6

var fighters: Array[Fighter] = []
var wins: Array[int] = [0, 0]
var round_number := 0
var frames_left := 0
var round_over := true
var match_over := false


func setup(p1: Fighter, p2: Fighter) -> void:
	fighters = [p1, p2]
	reset_match()


func reset_match() -> void:
	wins = [0, 0]
	round_number = 0
	match_over = false
	for f in fighters:
		f.super_meter = 0.0
	start_round()


## A barra de Super é mantida entre rounds.
func start_round() -> void:
	round_number += 1
	frames_left = ROUND_SECONDS * TICKS_PER_SECOND
	round_over = false
	fighters[0].reset_for_round(-START_OFFSET, true)
	fighters[1].reset_for_round(START_OFFSET, false)
	round_started.emit(round_number)


func seconds_left() -> int:
	return ceili(frames_left / float(TICKS_PER_SECOND))


func step(p1_bits: int, p2_bits: int) -> void:
	if round_over:
		return
	fighters[0].face_towards(fighters[1].pos.x)
	fighters[1].face_towards(fighters[0].pos.x)
	fighters[0].step(p1_bits)
	fighters[1].step(p2_bits)
	_resolve_hits()
	_separate()
	for f in fighters:
		f.pos.x = clampf(f.pos.x, -STAGE_HALF_WIDTH, STAGE_HALF_WIDTH)
	frames_left -= 1
	_check_round_end()


func _resolve_hits() -> void:
	var pending: Array[Dictionary] = []
	for i in 2:
		var attacker := fighters[i]
		var defender := fighters[1 - i]
		if attacker.can_hit() and attacker.get_hitbox().intersects(defender.get_hurtbox()):
			pending.append({"attacker": i, "data": attacker.current_attack, "damage": attacker.attack_damage()})
	for hit in pending:
		var attacker := fighters[hit.attacker]
		var defender := fighters[1 - hit.attacker]
		var push_dir := 1.0 if attacker.facing_right else -1.0
		var clean := defender.receive_hit(hit.data, hit.damage, push_dir)
		attacker.on_attack_connected(clean, hit.damage)
		hit_landed.emit(hit.attacker, not clean, hit.damage)


func _separate() -> void:
	var a := fighters[0]
	var b := fighters[1]
	var dx := b.pos.x - a.pos.x
	if absf(dx) >= PUSH_DISTANCE or absf(b.pos.y - a.pos.y) >= 1.0:
		return
	var side := signf(dx)
	if side == 0.0:
		side = 1.0 if a.facing_right else -1.0
	var overlap := (PUSH_DISTANCE - absf(dx)) / 2.0
	a.pos.x -= side * overlap
	b.pos.x += side * overlap


func _check_round_end() -> void:
	var knockout := fighters[0].health <= 0 or fighters[1].health <= 0
	if not knockout and frames_left > 0:
		return
	var winner := -1
	if fighters[0].health > fighters[1].health:
		winner = 0
	elif fighters[1].health > fighters[0].health:
		winner = 1
	round_over = true
	if winner >= 0:
		wins[winner] += 1
	round_ended.emit(winner)
	if winner >= 0 and wins[winner] >= ROUNDS_TO_WIN:
		match_over = true
		match_ended.emit(winner)
