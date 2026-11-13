class_name BattleHUD
extends CanvasLayer
## HUD de combate: vida que esvazia das bordas para o centro, timer, ícone de stance,
## barra de Super com 3 níveis e mensagens de round.

const BAR_WIDTH := 760.0
const BAR_HEIGHT := 40.0
const MARGIN := 40.0
const METER_WIDTH := 420.0

var _battle: BattleManager
var _health_bars: Array[ProgressBar] = []
var _meter_bars: Array[ProgressBar] = []
var _name_labels: Array[Label] = []
var _stance_labels: Array[Label] = []
var _meter_labels: Array[Label] = []
var _wins_labels: Array[Label] = []
var _timer_label: Label
var _message_label: Label
var _message_frames := 0


func _ready() -> void:
	for i in 2:
		var left := i == 0
		var health := _make_bar(Color(0.9, 0.75, 0.15), Color(0.35, 0.05, 0.05))
		health.max_value = Fighter.MAX_HEALTH
		# J1 esvazia da esquerda para o centro e J2 da direita para o centro.
		health.fill_mode = ProgressBar.FILL_END_TO_BEGIN if left else ProgressBar.FILL_BEGIN_TO_END
		_place(health, left, MARGIN, BAR_WIDTH, BAR_HEIGHT)
		_health_bars.append(health)

		var name_label := _make_label(26)
		_place(name_label, left, MARGIN + BAR_HEIGHT + 6, BAR_WIDTH)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		_name_labels.append(name_label)

		var stance_label := _make_label(24)
		_place(stance_label, left, MARGIN + BAR_HEIGHT + 40, BAR_WIDTH)
		stance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		_stance_labels.append(stance_label)

		var wins_label := _make_label(24)
		_place(wins_label, left, MARGIN + BAR_HEIGHT + 6, BAR_WIDTH)
		wins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if left else HORIZONTAL_ALIGNMENT_LEFT
		_wins_labels.append(wins_label)

		var meter := _make_bar(Color(0.2, 0.7, 1.0), Color(0.05, 0.08, 0.15))
		meter.max_value = Fighter.METER_PER_BAR * Fighter.MAX_BARS
		meter.fill_mode = ProgressBar.FILL_BEGIN_TO_END if left else ProgressBar.FILL_END_TO_BEGIN
		meter.anchor_top = 1.0
		meter.anchor_bottom = 1.0
		_place(meter, left, -MARGIN - 24, METER_WIDTH, 24)
		_meter_bars.append(meter)

		var meter_label := _make_label(22)
		meter_label.anchor_top = 1.0
		meter_label.anchor_bottom = 1.0
		_place(meter_label, left, -MARGIN - 58, METER_WIDTH)
		meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		_meter_labels.append(meter_label)

	_timer_label = _make_label(56)
	_timer_label.anchor_left = 0.5
	_timer_label.anchor_right = 0.5
	_timer_label.offset_left = -80
	_timer_label.offset_right = 80
	_timer_label.offset_top = MARGIN - 14
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_message_label = _make_label(96)
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.offset_left = -600
	_message_label.offset_right = 600
	_message_label.offset_top = -80
	_message_label.offset_bottom = 80
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func bind(battle: BattleManager) -> void:
	_battle = battle
	battle.round_started.connect(func(n: int): _show_message("ROUND %d\nLUTE!" % n, 90))
	battle.round_ended.connect(_on_round_ended)
	battle.match_ended.connect(func(w: int): _show_message("%s VENCE!" % battle.fighters[w].display_name.to_upper(), 220))


func refresh() -> void:
	if _battle == null or _battle.fighters.is_empty():
		return
	for i in 2:
		var f := _battle.fighters[i]
		_health_bars[i].value = f.health
		_name_labels[i].text = f.display_name
		var armed := f.stance == Fighter.Stance.WEAPON
		_stance_labels[i].text = ("⚔ ARMADO" if armed else "✊ MÃO NUA") + (" (trocando...)" if f.state == Fighter.State.SWITCH_STANCE else "")
		_stance_labels[i].modulate = Color(1.0, 0.45, 0.35) if armed else Color(0.9, 0.9, 0.9)
		_meter_bars[i].value = f.super_meter
		var full := f.bars() >= Fighter.MAX_BARS
		# Pisca quando o Super está disponível.
		var pulse := 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() / 150.0))
		_meter_bars[i].modulate = Color(1.6, 1.4, 0.6) * pulse if full else Color.WHITE
		_meter_labels[i].text = "SUPER MAX!" if full else "SUPER %d" % f.bars()
		_wins_labels[i].text = "● ".repeat(_battle.wins[i]).strip_edges()
	_timer_label.text = str(_battle.seconds_left())
	if _message_frames > 0:
		_message_frames -= 1
		if _message_frames == 0:
			_message_label.text = ""


func _on_round_ended(winner: int) -> void:
	if winner < 0:
		_show_message("EMPATE", 110)
	elif _battle.fighters[1 - winner].health <= 0:
		_show_message("K.O.!", 110)
	else:
		_show_message("TEMPO!", 110)


func _show_message(text: String, frames: int) -> void:
	_message_label.text = text
	_message_frames = frames


func _place(control: Control, left: bool, top: float, width: float, height := 34.0) -> void:
	if left:
		control.anchor_left = 0.0
		control.anchor_right = 0.0
		control.offset_left = MARGIN
		control.offset_right = MARGIN + width
	else:
		control.anchor_left = 1.0
		control.anchor_right = 1.0
		control.offset_left = -MARGIN - width
		control.offset_right = -MARGIN
	control.offset_top = top
	control.offset_bottom = top + height


func _make_bar(fill: Color, background: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = background
	bg_style.border_color = Color(0.05, 0.05, 0.05)
	bg_style.set_border_width_all(3)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", bg_style)
	add_child(bar)
	return bar


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	return label
