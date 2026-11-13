extends Node
## Autoload com estado global: opções do jogador e personagens escolhidos.

## "auto" mostra os botões touch só em telas de toque; "on"/"off" força.
var touch_controls := "auto"
## Opacidade dos botões virtuais no celular (Opções > Controles).
var mobile_button_opacity := 0.45
var master_volume_db := 0.0
var selected_characters: Array[String] = ["SP", "RJ"]


func _ready() -> void:
	# `godot -- --touch` força os botões touch (para testar o layout mobile no PC).
	if "--touch" in OS.get_cmdline_user_args():
		touch_controls = "on"


func should_show_touch_controls() -> bool:
	match touch_controls:
		"on":
			return true
		"off":
			return false
	# No PC os botões só aparecem depois de um toque (ou clique, que o projeto emula como toque).
	return OS.has_feature("mobile") or InputManager.primary_device == "touch"


func selected_character(player: int) -> Dictionary:
	return Roster.find(selected_characters[player])
