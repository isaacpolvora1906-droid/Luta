class_name InputBuffer
extends RefCounted
## Guarda os últimos N frames de input (um bitmask por frame) para ler comandos.
##
## A máquina de estados lê o buffer de trás para frente para achar sequências
## como "Trás, Frente, Trás + Soco Forte" (Super) ou meia-lua (236).

const UP := 1
const DOWN := 2
const LEFT := 4
const RIGHT := 8
const PUNCH_LIGHT := 16
const PUNCH_HEAVY := 32
const KICK_LIGHT := 64
const KICK_HEAVY := 128
const BLOCK := 256
const WEAPON := 512

const DEFAULT_SIZE := 30

var size: int
var _frames: Array[int] = []


func _init(buffer_size: int = DEFAULT_SIZE) -> void:
	size = buffer_size


## Adiciona o input de um frame. Direções opostas apertadas juntas se anulam (SOCD neutro).
func push(bits: int) -> void:
	_frames.push_back(clean(bits))
	if _frames.size() > size:
		_frames.pop_front()


func frame_count() -> int:
	return _frames.size()


func current() -> int:
	return _frames.back() if not _frames.is_empty() else 0


func previous() -> int:
	return _frames[-2] if _frames.size() >= 2 else 0


func is_held(bit: int) -> bool:
	return current() & bit != 0


func is_just_pressed(bit: int) -> bool:
	return current() & bit != 0 and previous() & bit == 0


## True se o botão foi apertado (borda de subida) em algum dos últimos `frames` frames.
## Permite que um comando apertado um pouco antes da hora ainda seja aceito.
func was_pressed_within(bit: int, frames: int) -> bool:
	var last := _frames.size() - 1
	var first := maxi(0, last - frames + 1)
	for i in range(last, first - 1, -1):
		var before := _frames[i - 1] if i > 0 else 0
		if _frames[i] & bit != 0 and before & bit == 0:
			return true
	return false


## Procura a sequência de direções (notação numérica, relativa a quem olha para a direita)
## nos últimos `window` frames, lendo do frame mais recente para o mais antigo.
func matches_motion(sequence: Array[int], facing_right: bool, window: int = -1) -> bool:
	if sequence.is_empty():
		return true
	if window < 0:
		window = size
	var idx := sequence.size() - 1
	var first := maxi(0, _frames.size() - window)
	for i in range(_frames.size() - 1, first - 1, -1):
		if to_numpad(_frames[i], facing_right) == sequence[idx]:
			idx -= 1
			if idx < 0:
				return true
	return false


## Remove direções opostas simultâneas.
static func clean(bits: int) -> int:
	if bits & LEFT and bits & RIGHT:
		bits &= ~(LEFT | RIGHT)
	if bits & UP and bits & DOWN:
		bits &= ~(UP | DOWN)
	return bits


## -1 (esquerda), 0 ou 1 (direita), no espaço do mundo.
static func horizontal(bits: int) -> int:
	bits = clean(bits)
	return (1 if bits & RIGHT else 0) - (1 if bits & LEFT else 0)


## Converte para notação numérica (teclado numérico): 5 = neutro, 6 = frente,
## 4 = trás, 2 = baixo, 8 = cima, 3 = baixo+frente etc.
static func to_numpad(bits: int, facing_right: bool) -> int:
	var x := horizontal(bits)
	if not facing_right:
		x = -x
	bits = clean(bits)
	var y := 0
	if bits & UP:
		y = 1
	elif bits & DOWN:
		y = -1
	return 5 + x + 3 * y
