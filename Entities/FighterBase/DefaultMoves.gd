class_name DefaultMoves
extends RefCounted
## Golpes provisórios usados por qualquer lutador que ainda não tenha moveset próprio.
## Cada personagem vai substituir isto por arquivos .tres em Entities/Characters/<UF>_<Animal>/.


static func bare_hands() -> Dictionary[int, AttackData]:
	var moves: Dictionary[int, AttackData] = {
		InputBuffer.PUNCH_LIGHT: AttackData.create("jab", "jab_fast", 50, 4, 2, 7, 12, 6, Rect2(0.2, 1.25, 0.55, 0.25)),
		InputBuffer.PUNCH_HEAVY: AttackData.create("cross", "punch_heavy", 90, 7, 3, 14, 18, 10, Rect2(0.2, 1.15, 0.7, 0.35)),
		InputBuffer.KICK_LIGHT: AttackData.create("low_kick", "kick_light", 60, 5, 3, 9, 14, 7, Rect2(0.2, 0.25, 0.7, 0.35)),
		InputBuffer.KICK_HEAVY: AttackData.create("roundhouse", "kick_heavy", 100, 9, 3, 16, 20, 11, Rect2(0.2, 0.9, 0.85, 0.4)),
	}
	return moves


## Com arma o alcance é bem maior; o Fighter ainda aplica +20% de dano e recuperação maior.
static func weapon() -> Dictionary[int, AttackData]:
	var moves: Dictionary[int, AttackData] = {
		InputBuffer.PUNCH_LIGHT: AttackData.create("slash_light", "weapon_slash_light", 50, 5, 3, 9, 15, 7, Rect2(0.2, 1.1, 1.3, 0.4)),
		InputBuffer.PUNCH_HEAVY: AttackData.create("slash_heavy", "weapon_slash_heavy", 90, 8, 4, 15, 20, 11, Rect2(0.2, 0.9, 1.5, 0.6)),
		InputBuffer.KICK_LIGHT: AttackData.create("sweep", "weapon_sweep", 60, 6, 3, 10, 15, 8, Rect2(0.2, 0.1, 1.1, 0.4)),
		InputBuffer.KICK_HEAVY: AttackData.create("overhead", "weapon_overhead", 100, 10, 4, 17, 22, 12, Rect2(0.2, 0.8, 1.6, 0.9)),
	}
	return moves


static func super_move() -> AttackData:
	var data := AttackData.create("super", "super", 300, 6, 6, 20, 60, 20, Rect2(0.2, 0.0, 1.6, 1.8))
	data.chip_ratio = 0.25
	data.pushback = 0.8
	return data
