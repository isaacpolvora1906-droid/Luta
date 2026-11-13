extends Node3D
## Cena de luta de protótipo: dois lutadores provisórios (cápsulas), HUD e controles touch.
## Serve para testar o combate até os modelos e cenários reais chegarem.

const FIGHTER_SCENE := preload("res://Entities/FighterBase/FighterBase.tscn")
const HUD_SCENE := preload("res://Scenes/BattleHUD.tscn")
const MobileControls := preload("res://Scenes/MobileControls.gd")
const ROUND_END_DELAY := 120
const MATCH_END_DELAY := 240

var battle: BattleManager
var fighters: Array[Fighter] = []
var hud: BattleHUD
var camera: Camera3D
var _delay := 0


func _ready() -> void:
	_build_environment()
	var colors: Array[Color] = [Color(0.85, 0.6, 0.25), Color(0.3, 0.55, 0.9)]
	for i in 2:
		var fighter := FIGHTER_SCENE.instantiate() as Fighter
		var data := GameManager.selected_character(i)
		fighter.display_name = "%s (%s)" % [data.get("animal", "Lutador"), data.get("uf", "?")]
		fighter.body_color = colors[i]
		add_child(fighter)
		fighters.append(fighter)

	battle = BattleManager.new()
	battle.name = "BattleManager"
	add_child(battle)
	battle.round_ended.connect(_on_round_ended)

	hud = HUD_SCENE.instantiate() as BattleHUD
	add_child(hud)
	hud.bind(battle)
	add_child(MobileControls.new())

	battle.setup(fighters[0], fighters[1])
	_sync()


func _physics_process(_delta: float) -> void:
	if _delay > 0:
		_delay -= 1
		if _delay == 0:
			if battle.match_over:
				battle.reset_match()
			else:
				battle.start_round()
	else:
		battle.step(InputManager.read_bits(0), InputManager.read_bits(1))
	_sync()


func _sync() -> void:
	for fighter in fighters:
		fighter.sync_visual()
	var mid_x := (fighters[0].pos.x + fighters[1].pos.x) / 2.0
	camera.position.x = lerpf(camera.position.x, mid_x, 0.15)
	hud.refresh()


func _on_round_ended(_winner: int) -> void:
	_delay = MATCH_END_DELAY if battle.match_over else ROUND_END_DELAY


func _build_environment() -> void:
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.position = Vector3(0, 1.6, 8.0)
	camera.rotation_degrees.x = -4.0
	add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.shadow_enabled = true
	add_child(light)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.07, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.5)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(BattleManager.STAGE_HALF_WIDTH * 2.0 + 4.0, 6.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.25, 0.22, 0.2)
	floor_mesh.material = floor_material
	var ground := MeshInstance3D.new()
	ground.mesh = floor_mesh
	add_child(ground)
