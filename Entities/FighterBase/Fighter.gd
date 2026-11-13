class_name Fighter
extends Node3D
## Lutador base que todos os personagens herdam.
##
## A lógica é uma máquina de estados determinística avançada 1 frame lógico por vez
## com step() (60 por segundo). Os tempos são contados em frames no código, não pela
## duração das animações: a troca de arma leva exatamente STANCE_SWITCH_FRAMES mesmo
## se a animação mudar. O AnimationPlayer é só visual. Isso também prepara o jogo
## para netcode com rollback no Versus online.
##
## A posição lógica fica em `pos` (plano 2D de luta: x horizontal, y altura);
## sync_visual() copia para o nó 3D.

enum Stance { BARE_HANDS, WEAPON }
enum State { IDLE, WALK, CROUCH, JUMP, ATTACK, HIT, BLOCK, SWITCH_STANCE, SUPER, KO }

signal state_changed(old_state: State, new_state: State)
signal stance_changed(new_stance: Stance)
signal attack_started(attack: AttackData)
signal super_started

const MAX_HEALTH := 1000
const METER_PER_BAR := 100.0
const MAX_BARS := 3
## GDD: a troca leva de 8 a 12 frames e deixa o lutador vulnerável.
const STANCE_SWITCH_FRAMES := 10
const WALK_SPEED := 0.05
## GDD: mão nua anda 15% mais rápido.
const BARE_HANDS_SPEED_MULT := 1.15
## GDD: armado causa 20% mais dano, com recuperação maior.
const WEAPON_DAMAGE_MULT := 1.2
const WEAPON_EXTRA_RECOVERY := 4
const JUMP_VELOCITY := 0.22
const GRAVITY := 0.012
## Frames em que um botão apertado um pouco antes da hora ainda é aceito.
const INPUT_LEEWAY := 4
## Super: Trás, Frente, Trás + Soco Forte (notação numérica: 4, 6, 4).
const SUPER_MOTION: Array[int] = [4, 6, 4]
const SUPER_MOTION_WINDOW := 20
const METER_GAIN_DEALT := 0.6
const METER_GAIN_TAKEN := 0.4
const METER_GAIN_BLOCKED := 2.0
const STANDING_HURTBOX := Rect2(-0.3, 0.0, 0.6, 1.8)
const CROUCHING_HURTBOX := Rect2(-0.3, 0.0, 0.6, 1.1)
const ATTACK_PRIORITY: Array[int] = [
	InputBuffer.PUNCH_HEAVY, InputBuffer.KICK_HEAVY,
	InputBuffer.PUNCH_LIGHT, InputBuffer.KICK_LIGHT,
]
const NEUTRAL_STATES: Array[State] = [State.IDLE, State.WALK, State.CROUCH, State.BLOCK]

@export var display_name := "Lutador"
@export var body_color := Color(0.8, 0.55, 0.3)
## Botão (bit do InputBuffer) -> golpe. Vazio = usa DefaultMoves.
@export var bare_hands_moveset: Dictionary[int, AttackData] = {}
@export var weapon_moveset: Dictionary[int, AttackData] = {}
@export var super_attack: AttackData

var stance: Stance = Stance.BARE_HANDS
var state: State = State.IDLE
## Frames desde que entrou no estado atual (0 no frame da entrada).
var state_frame := 0
var health := MAX_HEALTH
var super_meter := 0.0
var facing_right := true
var pos := Vector2.ZERO
var air_velocity := Vector2.ZERO
var current_attack: AttackData
var attack_has_hit := false
var stun_frames := 0
var input := InputBuffer.new()

var _anim_player: AnimationPlayer
var _body_material: StandardMaterial3D


func _ready() -> void:
	_anim_player = get_node_or_null("AnimationPlayer")
	var body := get_node_or_null("Body") as MeshInstance3D
	if body:
		_body_material = StandardMaterial3D.new()
		_body_material.albedo_color = body_color
		body.material_override = _body_material
	sync_visual()


func reset_for_round(x: float, face_right: bool) -> void:
	health = MAX_HEALTH
	stance = Stance.BARE_HANDS
	pos = Vector2(x, 0.0)
	air_velocity = Vector2.ZERO
	facing_right = face_right
	current_attack = null
	attack_has_hit = false
	stun_frames = 0
	input = InputBuffer.new()
	_set_state(State.IDLE, true)


## Avança a lógica um frame com o input (bitmask do InputBuffer) desse frame.
func step(bits: int) -> void:
	input.push(bits)
	state_frame += 1
	match state:
		State.IDLE, State.WALK, State.CROUCH:
			_process_neutral()
		State.BLOCK:
			_process_block()
		State.JUMP:
			_process_jump()
		State.ATTACK, State.SUPER:
			_process_attack()
		State.SWITCH_STANCE:
			_process_stance_switch()
		State.HIT:
			_process_hit()
		State.KO:
			_process_fall()


# --- Estados ---------------------------------------------------------------

func _process_neutral() -> void:
	if _try_super():
		return
	if input.was_pressed_within(InputBuffer.WEAPON, INPUT_LEEWAY):
		start_stance_switch()
		return
	for bit in ATTACK_PRIORITY:
		if input.was_pressed_within(bit, INPUT_LEEWAY) and perform_attack(bit):
			return

	var held := input.current()
	if held & InputBuffer.BLOCK:
		_set_state(State.BLOCK)
		return
	var dir := InputBuffer.horizontal(held)
	if held & InputBuffer.UP:
		# Pulo com peso: a direção é decidida na decolagem e não muda no ar.
		air_velocity = Vector2(dir * walk_speed(), JUMP_VELOCITY)
		_set_state(State.JUMP)
		return
	if held & InputBuffer.DOWN:
		_set_state(State.CROUCH)
		return
	if dir != 0:
		pos.x += dir * walk_speed()
		_set_state(State.WALK)
	else:
		_set_state(State.IDLE)


func _process_block() -> void:
	if stun_frames > 0:
		stun_frames -= 1
		return
	if not input.is_held(InputBuffer.BLOCK):
		_set_state(State.IDLE)


func _process_jump() -> void:
	pos += air_velocity
	air_velocity.y -= GRAVITY
	if pos.y <= 0.0:
		pos.y = 0.0
		air_velocity = Vector2.ZERO
		_set_state(State.IDLE)


func _process_attack() -> void:
	if current_attack == null or state_frame >= attack_total_frames():
		current_attack = null
		_set_state(State.IDLE)


func _process_stance_switch() -> void:
	if state_frame >= STANCE_SWITCH_FRAMES:
		stance = Stance.WEAPON if stance == Stance.BARE_HANDS else Stance.BARE_HANDS
		stance_changed.emit(stance)
		_set_state(State.IDLE)


func _process_hit() -> void:
	_process_fall()
	stun_frames -= 1
	if stun_frames <= 0 and pos.y <= 0.0:
		_set_state(State.IDLE)


func _process_fall() -> void:
	if pos.y > 0.0:
		air_velocity.y -= GRAVITY
		pos.y = maxf(0.0, pos.y + air_velocity.y)
	else:
		air_velocity = Vector2.ZERO


# --- Ações -----------------------------------------------------------------

func start_stance_switch() -> void:
	_set_state(State.SWITCH_STANCE, true)


func perform_attack(button_bit: int) -> bool:
	var data: AttackData = get_moveset().get(button_bit)
	if data == null:
		return false
	_start_attack(data, State.ATTACK)
	return true


func _try_super() -> bool:
	if bars() < MAX_BARS:
		return false
	if not input.is_just_pressed(InputBuffer.PUNCH_HEAVY):
		return false
	if not input.matches_motion(SUPER_MOTION, facing_right, SUPER_MOTION_WINDOW):
		return false
	_ensure_movesets()
	spend_bars(MAX_BARS)
	_start_attack(super_attack, State.SUPER)
	super_started.emit()
	return true


func _start_attack(data: AttackData, attack_state: State) -> void:
	current_attack = data
	attack_has_hit = false
	_set_state(attack_state, true)
	attack_started.emit(data)


## Chamado pelo BattleManager quando um golpe acerta este lutador.
## Retorna true se o acerto foi limpo e false se foi defendido.
func receive_hit(data: AttackData, damage: int, push_dir: float) -> bool:
	if state == State.KO:
		return false
	pos.x += push_dir * data.pushback
	if state == State.BLOCK and not data.unblockable:
		_take_damage(roundi(damage * data.chip_ratio))
		stun_frames = data.block_stun
		gain_meter(METER_GAIN_BLOCKED)
		if health <= 0:
			_set_state(State.KO, true)
		return false
	_take_damage(damage)
	gain_meter(damage * METER_GAIN_TAKEN)
	current_attack = null
	air_velocity = Vector2.ZERO
	stun_frames = data.hit_stun
	# Apanhar no meio da troca de arma cancela a troca: a stance não muda.
	_set_state(State.KO if health <= 0 else State.HIT, true)
	return true


## Chamado pelo BattleManager quando o golpe atual deste lutador conecta.
func on_attack_connected(clean_hit: bool, damage: int) -> void:
	attack_has_hit = true
	gain_meter(damage * METER_GAIN_DEALT * (1.0 if clean_hit else 0.5))


func face_towards(x: float) -> void:
	if state not in NEUTRAL_STATES:
		return
	if x > pos.x:
		facing_right = true
	elif x < pos.x:
		facing_right = false


# --- Consultas -------------------------------------------------------------

func walk_speed() -> float:
	return WALK_SPEED * (BARE_HANDS_SPEED_MULT if stance == Stance.BARE_HANDS else 1.0)


func get_moveset() -> Dictionary[int, AttackData]:
	_ensure_movesets()
	return weapon_moveset if stance == Stance.WEAPON else bare_hands_moveset


func attack_total_frames() -> int:
	if current_attack == null:
		return 0
	var extra := WEAPON_EXTRA_RECOVERY if stance == Stance.WEAPON and state == State.ATTACK else 0
	return current_attack.total_frames() + extra


func attack_damage() -> int:
	if current_attack == null:
		return 0
	if stance == Stance.WEAPON and state == State.ATTACK:
		return roundi(current_attack.damage * WEAPON_DAMAGE_MULT)
	return current_attack.damage


## True nos frames ativos do golpe atual, enquanto ele ainda não acertou.
func can_hit() -> bool:
	if state != State.ATTACK and state != State.SUPER:
		return false
	if current_attack == null or attack_has_hit:
		return false
	return state_frame > current_attack.startup and state_frame <= current_attack.startup + current_attack.active


func get_hurtbox() -> Rect2:
	var box := CROUCHING_HURTBOX if state == State.CROUCH else STANDING_HURTBOX
	return Rect2(box.position + pos, box.size)


func get_hitbox() -> Rect2:
	if current_attack == null:
		return Rect2()
	var r := current_attack.hitbox
	if not facing_right:
		r = Rect2(-r.position.x - r.size.x, r.position.y, r.size.x, r.size.y)
	return Rect2(r.position + pos, r.size)


func bars() -> int:
	return int(super_meter / METER_PER_BAR)


func gain_meter(amount: float) -> void:
	super_meter = clampf(super_meter + amount, 0.0, METER_PER_BAR * MAX_BARS)


func spend_bars(count: int) -> bool:
	if bars() < count:
		return false
	super_meter -= count * METER_PER_BAR
	return true


func is_grounded() -> bool:
	return pos.y <= 0.0


# --- Internos e visual -----------------------------------------------------

func _set_state(new_state: State, force := false) -> void:
	if new_state == state and not force:
		return
	var old := state
	state = new_state
	state_frame = 0
	state_changed.emit(old, new_state)


func _take_damage(amount: int) -> void:
	health = maxi(0, health - amount)


func _ensure_movesets() -> void:
	if bare_hands_moveset.is_empty():
		bare_hands_moveset = DefaultMoves.bare_hands()
	if weapon_moveset.is_empty():
		weapon_moveset = DefaultMoves.weapon()
	if super_attack == null:
		super_attack = DefaultMoves.super_move()


## Copia o estado lógico para o nó 3D. Chamado depois de cada step().
func sync_visual() -> void:
	position = Vector3(pos.x, pos.y, 0.0)
	rotation.y = 0.0 if facing_right else PI
	var weapon_node := get_node_or_null("Weapon") as Node3D
	if weapon_node:
		weapon_node.visible = stance == Stance.WEAPON
	if _body_material:
		var flash := state == State.HIT and state_frame < 4
		_body_material.albedo_color = Color.WHITE if flash else body_color
	if _anim_player:
		var anim := animation_name()
		if _anim_player.has_animation(anim) and _anim_player.current_animation != anim:
			_anim_player.play(anim)


func animation_name() -> String:
	var suffix := "weapon" if stance == Stance.WEAPON else "barehands"
	match state:
		State.ATTACK, State.SUPER:
			return current_attack.animation if current_attack else "idle_" + suffix
		State.SWITCH_STANCE:
			return "draw_weapon" if stance == Stance.BARE_HANDS else "holster_weapon"
		State.WALK:
			return "walk_" + suffix
		State.CROUCH:
			return "crouch_" + suffix
		State.JUMP:
			return "jump_" + suffix
		State.BLOCK:
			return "block_" + suffix
		State.HIT:
			return "hit"
		State.KO:
			return "ko"
	return "idle_" + suffix
