extends CanvasLayer
## 타이틀 화면. var pick := await title.choose()  →  "new" | "continue"

signal picked(choice: String)

var _root := Control.new()
var _options: Array = []
var _sel := 0
var _t := 0.0
var _active := false


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_root)
	_root.visible = false
	add_child(_root)


func choose() -> String:
	_options = [["new", "새 게임"]]
	if Game.has_save():
		_options.push_front(["continue", "이어하기"])
	_sel = 0
	_active = true
	_root.visible = true
	var c: String = await picked
	_active = false
	_root.visible = false
	await get_tree().process_frame
	return c


func _process(delta: float) -> void:
	_t += delta
	if _active:
		_root.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("move_up"):
		_sel = posmod(_sel - 1, _options.size())
	elif event.is_action_pressed("move_down"):
		_sel = posmod(_sel + 1, _options.size())
	elif event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		picked.emit(_options[_sel][0])
	get_viewport().set_input_as_handled()


func _draw_root() -> void:
	_root.draw_rect(Rect2(0, 0, 480, 270), Color("0c1020"))
	# 달무리: 달 둘레의 옅은 고리
	var moon := Vector2(360, 70)
	for i in 4:
		var a := 0.05 + 0.02 * sin(_t * 1.5 + i)
		_root.draw_arc(moon, 30.0 + i * 9.0, 0, TAU, 48, Color(0.8, 0.85, 1.0, a), 2.0)
	_root.draw_circle(moon, 14, Color("e8e4d0"))
	_root.draw_rect(Rect2(0, 200, 480, 70), Color("080a14"))
	for x in range(0, 480, 24):
		_root.draw_rect(Rect2(x, 196 - (x * 7 % 13), 18, 8 + (x * 7 % 13)), Color("080a14"))
	var f := Game.font_main
	var title := "무협 도트 오픈월드"
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	_root.draw_string(f, Vector2(roundf(60), 120), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f0e6cc"))
	_root.draw_string(Game.font_small, Vector2(62 + w - 30, 136), "(가제)", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.SMALL_SIZE, Color("8a8a9a"))
	for i in _options.size():
		var y := 168 + i * 16
		var col := Color("f0e6cc") if i == _sel else Color("7a7a8a")
		if i == _sel:
			_root.draw_string(f, Vector2(62, y), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE, col)
		_root.draw_string(f, Vector2(76, y), _options[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE, col)
	_root.draw_string(Game.font_small, Vector2(62, 252), "↑↓ 선택   E / F 결정", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.SMALL_SIZE, Color("5a5a6a"))
