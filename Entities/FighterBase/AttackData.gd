class_name AttackData
extends Resource
## Dados de um golpe: frame data, dano e hitbox.
##
## Fica em Resource (.tres) para balancear os 26 lutadores sem mexer em código.
## Os valores aqui são a base; o Fighter aplica os modificadores da stance
## (ex.: +20% de dano e recuperação maior com arma).

@export var id := ""
## Nome da animação tocada no AnimationPlayer (só visual).
@export var animation := ""
@export var damage := 50
## Frames antes do primeiro frame ativo (sem contar o frame em que o botão foi apertado).
@export_range(1, 60) var startup := 5
@export_range(1, 60) var active := 3
@export_range(0, 120) var recovery := 10
@export var hit_stun := 15
@export var block_stun := 8
## Fração do dano que passa pela defesa (dano "chip").
@export_range(0.0, 1.0) var chip_ratio := 0.15
@export var pushback := 0.25
## Área de acerto relativa à posição do lutador, olhando para a direita (x à frente, y para cima).
@export var hitbox := Rect2(0.2, 1.0, 0.6, 0.4)
## Agarrões ignoram a defesa.
@export var unblockable := false


func total_frames() -> int:
	return startup + active + recovery


static func create(
		p_id: String, p_animation: String, p_damage: int,
		p_startup: int, p_active: int, p_recovery: int,
		p_hit_stun: int, p_block_stun: int, p_hitbox: Rect2) -> AttackData:
	var data := AttackData.new()
	data.id = p_id
	data.animation = p_animation
	data.damage = p_damage
	data.startup = p_startup
	data.active = p_active
	data.recovery = p_recovery
	data.hit_stun = p_hit_stun
	data.block_stun = p_block_stun
	data.hitbox = p_hitbox
	return data
