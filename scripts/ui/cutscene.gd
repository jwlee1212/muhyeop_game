extends CanvasLayer
## 연출 화면: 오프닝(웹툰 → 뒤로가기 → 암전), 죽었을 때 1화 엔딩 컷과 "뒤로가기", 원작에 없는 장면.

const Cuts := preload("res://scripts/ui/cuts.gd")

signal confirmed

var dialogue                    # dialogue_box.gd
var _root := Control.new()
var _mode := ""                 # "", "phone", "death", "stamp", "black"
var _back_pressed := false
var _flash := 0.0               # 흰 번짐 0..1
var _black := 0.0               # 검은 화면 0..1
var _stamp := 0.0
var _t := 0.0
var _waiting := false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_root)
	add_child(_root)


func _process(delta: float) -> void:
	_t += delta
	_root.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _waiting and (event.is_action_pressed("interact") or event.is_action_pressed("attack")):
		_waiting = false
		get_viewport().set_input_as_handled()
		confirmed.emit()


func _wait_confirm() -> void:
	_waiting = true
	await confirmed


func _tween(prop: String, to: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, prop, to, time)
	await tw.finished


func _sleep(time: float) -> void:
	await get_tree().create_timer(time, true).timeout


func _begin(mode: String) -> bool:
	var was := get_tree().paused
	get_tree().paused = true
	_mode = mode
	_back_pressed = false
	_flash = 0.0
	_stamp = 0.0
	return was


func _end(was_paused: bool) -> void:
	_mode = ""
	_flash = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = was_paused


## 오프닝. 끝나면 검은 화면(_black = 1)으로 남는다. fade_from_black()으로 걷어낸다.
func play_opening() -> void:
	var was := _begin("phone")
	_black = 0.0
	await _sleep(0.6)
	await dialogue.play([
		{"text": "밤. 침대에 누워 처음 보는 무협 웹툰을 넘기고 있다.", "thought": true},
		{"text": "…끝? 주인공이 1화에서 죽는다고?", "thought": true},
		{"who": "나", "text": "이게 뭔 웹툰이야."},
	])
	await _sleep(0.3)
	_back_pressed = true
	await _sleep(0.25)
	await _tween("_flash", 1.0, 0.7)
	await _sleep(0.5)
	_black = 1.0
	_mode = "black"
	await _tween("_flash", 0.0, 0.8)
	await _sleep(0.6)
	await _end(was)


func fade_from_black(time := 1.0) -> void:
	await _tween("_black", 0.0, time)


## 죽었을 때: 1화 엔딩 컷 + "뒤로가기". 누르면 돌아온다 (호출한 쪽이 자동 세이브를 불러온다).
func play_death() -> void:
	var was := _begin("death")
	await _sleep(0.4)
	await _wait_confirm()
	_back_pressed = true
	await _sleep(0.2)
	await _tween("_flash", 1.0, 0.4)
	_black = 1.0
	_mode = "black"
	_flash = 0.0
	await _end(was)


## 황가 일당을 이긴 뒤: 1화 엔딩 컷이 흐려지고 "이 장면은 원작에 없다".
func play_not_in_original() -> void:
	var was := _begin("stamp")
	await _sleep(0.5)
	await _tween("_stamp", 1.0, 1.2)
	Fx.shake(4.0)
	await _sleep(0.4)
	await _wait_confirm()
	await _end(was)


func _draw_root() -> void:
	var view := Vector2(480, 270)
	match _mode:
		"phone":
			_root.draw_rect(Rect2(Vector2.ZERO, view), Color("0a0a10"))
			_root.draw_circle(Vector2(240, 135), 140, Color(0.25, 0.3, 0.45, 0.12))
			var phone := Rect2(178, 22, 124, 226)
			_root.draw_rect(phone.grow(3), Color("2a2a32"))
			_root.draw_rect(phone, Color("101014"))
			var screen := phone.grow(-6)
			_root.draw_rect(screen, Color("f6f2e8"))
			_text(Vector2(240, screen.position.y + 16), "제1화 〈객잔의 아이〉", Color("1a1614"), true, true)
			Cuts.draw_cut(_root, Rect2(screen.position + Vector2(8, 26), Vector2(screen.size.x - 16, 70)), 3)
			_text(Vector2(240, screen.position.y + 118), "- 끝 -", Color("1a1614"), true, true)
			_text(Vector2(240, screen.position.y + 140), "다음 화 보기 ▷", Color("8a8070"), true, true)
			# 뒤로가기 버튼
			var btn := Rect2(screen.position.x + 6, screen.end.y - 22, 34, 16)
			_root.draw_rect(btn, Color("3a6ea5") if _back_pressed else Color("d8d0c0"))
			_text(btn.position + Vector2(17, 12), "◀", Color.WHITE if _back_pressed else Color("1a1614"), true, true)
		"death":
			_root.draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.7))
			var panel := Rect2(140, 40, 200, 128)
			Cuts.draw_cut(_root, panel, 3)
			_text(Vector2(240, 186), "제1화 〈객잔의 아이〉 — 끝", Color("f6f2e8"), true)
			var blink := int(_t * 2.5) % 2 == 0 or _back_pressed
			var btn := Rect2(196, 200, 88, 20)
			_root.draw_rect(btn.grow(2), Color("1a1614"))
			_root.draw_rect(btn, Color("3a6ea5") if _back_pressed else (Color("f6f2e8") if blink else Color("d8d0c0")))
			_text(btn.position + Vector2(44, 15), "◀ 뒤로가기", Color.WHITE if _back_pressed else Color("1a1614"), true)
			_text(Vector2(240, 240), "E / F", Color("8a8070"), true, true)
		"stamp":
			_root.draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.6))
			var panel := Rect2(140, 50, 200, 128)
			Cuts.draw_cut(_root, panel, 3)
			# 원작 컷이 흐려지고 새 컷이 겹친다
			_root.draw_rect(panel, Color(0.96, 0.95, 0.91, _stamp * 0.85))
			if _stamp > 0.5:
				var a := clampf((_stamp - 0.5) * 2.0, 0.0, 1.0)
				Cuts.draw_cut(_root, panel.grow(-int((1.0 - a) * 20)), 4)
			if _stamp >= 1.0:
				var st := Rect2(150, 122, 180, 26)
				_root.draw_rect(st.grow(2), Color("b02a2a"))
				_root.draw_rect(st, Color(0.96, 0.92, 0.88, 0.92))
				_text(st.position + Vector2(90, 18), "이 장면은 원작에 없다", Color("b02a2a"), true)
				_text(Vector2(240, 210), "E / F", Color("8a8070"), true, true)
	if _black > 0.0:
		_root.draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, _black))
	if _flash > 0.0:
		var r := lerpf(10.0, 360.0, _flash)
		_root.draw_circle(Vector2(240, 230) if _mode == "phone" else Vector2(240, 135), r, Color(1, 1, 1, minf(1.0, _flash * 1.4)))
		_root.draw_rect(Rect2(Vector2.ZERO, view), Color(1, 1, 1, _flash * _flash))


func _text(pos: Vector2, text: String, col: Color, centered := false, small := false) -> void:
	var font: Font = Game.font_small if small else Game.font_main
	var size := Game.SMALL_SIZE if small else Game.MAIN_SIZE
	var x := pos.x
	if centered:
		x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	_root.draw_string(font, Vector2(roundf(x), pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
