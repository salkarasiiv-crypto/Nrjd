extends Control

signal action
signal attack
signal choice(i)

const R := 95.0

var stick := Vector2.ZERO
var look := Vector2.ZERO
var time_text := ""
var quest := ""
var respect := 0
var family := 0
var hp := 100.0
var combat := false
var prompt := ""
var toast_text := ""
var toast_t := 0.0
var flash := 0.0
var end_card := ""
var dlg_open := false
var spk := ""
var txt := ""
var choices: Array = []
var choice_rects: Array = []
var _sid := -1
var _so := Vector2.ZERO
var _lid := -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func open(s: String, t: String, c: Array) -> void:
	spk = s
	txt = t
	choices = c
	dlg_open = true
	_sid = -1
	_lid = -1
	stick = Vector2.ZERO

func close() -> void:
	dlg_open = false

func toast(s: String, d := 3.5) -> void:
	toast_text = s
	toast_t = d

func btn_a() -> Vector2:
	return Vector2(size.x - 120.0, size.y - 135.0)

func btn_b() -> Vector2:
	return Vector2(size.x - 275.0, size.y - 85.0)

func _input(e: InputEvent) -> void:
	if e is InputEventKey:
		var k := e as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_E or k.keycode == KEY_SPACE:
				if dlg_open:
					if choices.size() == 1:
						choice.emit(0)
				else:
					action.emit()
			elif k.keycode == KEY_F:
				attack.emit()
			elif k.keycode >= KEY_1 and k.keycode <= KEY_4 and dlg_open:
				if k.keycode - KEY_1 < choices.size():
					choice.emit(k.keycode - KEY_1)
	elif e is InputEventScreenTouch:
		var tc := e as InputEventScreenTouch
		if tc.pressed:
			_press(tc.index, tc.position)
		else:
			if tc.index == _sid:
				_sid = -1
				stick = Vector2.ZERO
			if tc.index == _lid:
				_lid = -1
	elif e is InputEventScreenDrag:
		var g := e as InputEventScreenDrag
		if g.index == _sid:
			stick = ((g.position - _so) / R).limit_length(1.0)
		elif g.index == _lid:
			look += g.relative

func _press(i: int, p: Vector2) -> void:
	if end_card != "":
		end_card = ""
		return
	if dlg_open:
		for k in choice_rects.size():
			if choice_rects[k].has_point(p):
				choice.emit(k)
				return
		return
	if p.distance_to(btn_a()) < 62.0:
		action.emit()
	elif p.distance_to(btn_b()) < 56.0:
		attack.emit()
	elif p.x < size.x * 0.45 and _sid == -1:
		_sid = i
		_so = p
		stick = Vector2.ZERO
	elif p.x >= size.x * 0.45 and _lid == -1:
		_lid = i

func _process(delta: float) -> void:
	toast_t -= delta
	flash = maxf(0.0, flash - delta)
	queue_redraw()

func _tx(p: Vector2, s: String, sz: int, col: Color, al := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var f := ThemeDB.fallback_font
	draw_string_outline(f, p, s, al, w, sz, 6, Color.BLACK)
	draw_string(f, p, s, al, w, sz, col)

func _draw() -> void:
	var f := ThemeDB.fallback_font
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.0, 0.0, flash * 0.4))
	if end_card != "":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.88))
		draw_multiline_string(f, Vector2(size.x * 0.1, size.y * 0.25), end_card, HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.8, 30, -1, Color.WHITE)
		_tx(Vector2(0, size.y - 60), "Нажми, чтобы продолжить", 22, Color(0.8, 0.8, 0.8), HORIZONTAL_ALIGNMENT_CENTER, size.x)
		return
	if dlg_open:
		var w := size.x * 0.86
		var x := size.x * 0.07
		var th := f.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, w - 40.0, 26).y
		var h := 56.0 + th + 20.0 + choices.size() * 62.0 + 12.0
		var y := size.y - h - 16.0
		draw_rect(Rect2(x, y, w, h), Color(0, 0, 0, 0.8))
		_tx(Vector2(x + 20, y + 38), spk, 28, Color(1, 0.8, 0.3))
		draw_multiline_string(f, Vector2(x + 20, y + 56 + 24), txt, HORIZONTAL_ALIGNMENT_LEFT, w - 40.0, 26, -1, Color.WHITE)
		choice_rects.clear()
		var cy := y + 56.0 + th + 20.0
		for k in choices.size():
			var r := Rect2(x + 16, cy + k * 62.0, w - 32.0, 54.0)
			choice_rects.append(r)
			draw_rect(r, Color(0.25, 0.3, 0.45, 0.92))
			draw_string(f, Vector2(r.position.x + 16, r.position.y + 36), "%d) %s" % [k + 1, choices[k]], HORIZONTAL_ALIGNMENT_LEFT, w - 64.0, 24, Color.WHITE)
		return
	# HUD
	draw_rect(Rect2(14, 12, 600, 112), Color(0, 0, 0, 0.45))
	_tx(Vector2(28, 44), time_text, 26, Color(1, 0.93, 0.65))
	draw_multiline_string(f, Vector2(28, 78), "Задание: " + quest, HORIZONTAL_ALIGNMENT_LEFT, 570.0, 22, 2, Color.WHITE)
	_tx(Vector2(0, 40), "Двор: %d    Семья: %d" % [respect, family], 24, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 24.0)
	if combat:
		var bw := 360.0
		var bx := (size.x - bw) / 2.0
		draw_rect(Rect2(bx, 20, bw, 22), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bx + 2, 22, (bw - 4.0) * clampf(hp / 100.0, 0.0, 1.0), 18), Color(0.85, 0.15, 0.15))
	if prompt != "":
		draw_rect(Rect2(size.x / 2.0 - 230, size.y - 78, 460, 46), Color(0, 0, 0, 0.6))
		_tx(Vector2(0, size.y - 46), prompt, 24, Color(1, 0.9, 0.5), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	if toast_t > 0.0:
		var tw := size.x * 0.7
		var tth := f.get_multiline_string_size(toast_text, HORIZONTAL_ALIGNMENT_CENTER, tw, 24).y
		draw_rect(Rect2((size.x - tw) / 2.0 - 12, 150, tw + 24, tth + 24), Color(0, 0, 0, 0.65))
		draw_multiline_string(f, Vector2((size.x - tw) / 2.0, 150 + 30), toast_text, HORIZONTAL_ALIGNMENT_CENTER, tw, 24, -1, Color.WHITE)
	# джойстик и кнопки
	var base := _so if _sid != -1 else Vector2(170, size.y - 150)
	draw_circle(base, R, Color(1, 1, 1, 0.10))
	draw_arc(base, R, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(base + stick * R, 38.0, Color(1, 1, 1, 0.35))
	draw_circle(btn_a(), 58.0, Color(0.2, 0.6, 0.3, 0.5))
	draw_string(f, btn_a() + Vector2(-58, 8), "Действие", HORIZONTAL_ALIGNMENT_CENTER, 116.0, 20, Color.WHITE)
	draw_circle(btn_b(), 52.0, Color(0.75, 0.2, 0.2, 0.5))
	draw_string(f, btn_b() + Vector2(-52, 8), "Удар", HORIZONTAL_ALIGNMENT_CENTER, 104.0, 22, Color.WHITE)
