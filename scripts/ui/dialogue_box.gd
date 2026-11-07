extends CanvasLayer
## 대화 상자. 웹툰 말풍선처럼 흰 바탕에 검은 테두리, 속마음은 푸른 바탕에 괄호.
## 사용: var choice := await dialogue.play(lines)   (선택지가 없었으면 -1)
## 줄 형식: "문장"(서술) 또는 {"who": 이름, "text": 문장, "thought": true, "sys": true, "choices": [..]}

signal finished(choice: int)

const PANEL := Rect2(14, 188, 452, 74)
const SPEED := 40.0           # 초당 글자 수
const INK := Color("1a1614")
const PAPER := Color("f6f2e8")
const THOUGHT_PAPER := Color("e4ecf6")
const THOUGHT_INK := Color("2e4466")
const SYS_PAPER := Color("1e2430")
const SYS_INK := Color("d8f4ff")

var _root := Control.new()
var _name := Label.new()
var _text := Label.new()
var _lines: Array = []
var _i := 0
var _chars := 0.0
var _typing := false
var _sel := 0
var _choice := -1
var _active := false
var _t := 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_root)
	_root.visible = false
	add_child(_root)
	_name.add_theme_font_override("font", Game.font_small)
	_name.add_theme_font_size_override("font_size", Game.SMALL_SIZE)
	_name.add_theme_color_override("font_color", PAPER)
	_name.position = PANEL.position + Vector2(8, -14)
	_root.add_child(_name)
	_text.position = PANEL.position + Vector2(10, 8)
	_text.size = PANEL.size - Vector2(20, 14)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_constant_override("line_spacing", 2)
	_root.add_child(_text)


func is_active() -> bool:
	return _active


func play(lines: Array) -> int:
	if lines.is_empty():
		return -1
	_lines = lines
	_i = 0
	_choice = -1
	_active = true
	_root.visible = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	_show_line()
	var result: int = await finished
	# 마지막 확인 키가 게임 쪽(공격·상호작용)으로 새지 않게 두 프레임 쉬고 재개
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = was_paused
	return result


func _line(i: int) -> Dictionary:
	var l = _lines[i]
	return {"text": l} if l is String else l


func _show_line() -> void:
	var l := _line(_i)
	var who: String = l.get("who", "")
	_name.text = who
	_name.visible = who != ""
	var text: String = l.text
	if l.get("thought", false):
		text = "(" + text + ")"
	_text.text = text
	var ink := INK
	if l.get("thought", false):
		ink = THOUGHT_INK
	elif l.get("sys", false):
		ink = SYS_INK
	_text.add_theme_color_override("font_color", ink)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if l.get("sys", false) else HORIZONTAL_ALIGNMENT_LEFT
	_chars = 0.0
	_text.visible_characters = 0
	_typing = true
	_sel = 0


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	if _typing:
		_chars += delta * SPEED
		_text.visible_characters = int(_chars)
		if _chars >= _text.get_total_character_count():
			_typing = false
			_text.visible_characters = -1
	_root.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var choices: Array = _line(_i).get("choices", [])
	if not _typing and not choices.is_empty():
		if event.is_action_pressed("move_up"):
			_sel = posmod(_sel - 1, choices.size())
		elif event.is_action_pressed("move_down"):
			_sel = posmod(_sel + 1, choices.size())
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		if _typing:
			_typing = false
			_text.visible_characters = -1
		else:
			if not choices.is_empty():
				_choice = _sel
			_next()
	get_viewport().set_input_as_handled()


func _next() -> void:
	_i += 1
	if _i >= _lines.size():
		_active = false
		_root.visible = false
		finished.emit(_choice)
	else:
		_show_line()


func _draw_root() -> void:
	var l := _line(_i)
	var paper := PAPER
	if l.get("thought", false):
		paper = THOUGHT_PAPER
	elif l.get("sys", false):
		paper = SYS_PAPER
	# 웹툰 컷 느낌: 굵은 검은 테두리 + 그림자
	_root.draw_rect(Rect2(PANEL.position + Vector2(1, 1), PANEL.size + Vector2(2, 2)), Color(0, 0, 0, 0.35))
	_root.draw_rect(PANEL.grow(2), INK)
	_root.draw_rect(PANEL, paper)
	if _name.visible:
		var w := Game.font_small.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.SMALL_SIZE).x
		_root.draw_rect(Rect2(PANEL.position + Vector2(2, -16), Vector2(w + 12, 15)), INK)
	var choices: Array = l.get("choices", [])
	if not _typing and choices.is_empty() and int(_t * 3.0) % 2 == 0:
		var p := PANEL.end - Vector2(12, 8)
		_root.draw_colored_polygon(PackedVector2Array([p, p + Vector2(6, 0), p + Vector2(3, 4)]), INK if paper != SYS_PAPER else SYS_INK)
	if not _typing and not choices.is_empty():
		var font := Game.font_main
		var bw := 0.0
		for c in choices:
			bw = maxf(bw, font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE).x)
		var box := Rect2(PANEL.end.x - bw - 30, PANEL.position.y - 10 - choices.size() * 15, bw + 26, choices.size() * 15 + 6)
		_root.draw_rect(box.grow(2), INK)
		_root.draw_rect(box, PAPER)
		for i in choices.size():
			var y := box.position.y + 15 + i * 15
			if i == _sel:
				_root.draw_rect(Rect2(box.position.x + 2, y - 11, box.size.x - 4, 14), Color("d8cfb8"))
				_root.draw_string(font, Vector2(box.position.x + 5, y), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE, INK)
			_root.draw_string(font, Vector2(box.position.x + 17, y), choices[i], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE, INK)
