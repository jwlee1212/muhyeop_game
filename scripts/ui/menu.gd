extends CanvasLayer
## 메뉴 (Tab / I / Esc). 탭: 무공 · 소지품 · 기억 · 저장.
## 무공 탭이 초식 커맨드를 확인하는 유일한 곳이다 (전투 HUD에는 띄우지 않는다).

const Techniques := preload("res://scripts/combat/techniques.gd")
const Cuts := preload("res://scripts/ui/cuts.gd")

const TABS := ["무공", "소지품", "기억", "저장"]
const INK := Color("1a1614")
const PAPER := Color("f6f2e8")
const DIM := Color("8a8070")
const BOX := Rect2(30, 22, 420, 226)

var main                        # main.gd (저장·불러오기)
var _root := Control.new()
var _open := false
var _tab := 0
var _sel := 0
var _msg := ""
var _msg_t := 0.0


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_root)
	_root.visible = false
	add_child(_root)


func is_open() -> bool:
	return _open


func open(tab := 0) -> void:
	_open = true
	_tab = tab
	_sel = 0
	_msg = ""
	_root.visible = true
	get_tree().paused = true


func close() -> void:
	_open = false
	_root.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = false


func _process(delta: float) -> void:
	_msg_t = maxf(0.0, _msg_t - delta)
	if _open:
		_root.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		if event.is_action_pressed("menu") and main and main.can_open_menu():
			open()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu"):
		close()
	elif event.is_action_pressed("move_left"):
		_tab = posmod(_tab - 1, TABS.size()); _sel = 0
	elif event.is_action_pressed("move_right"):
		_tab = posmod(_tab + 1, TABS.size()); _sel = 0
	elif event.is_action_pressed("move_up"):
		_sel = maxi(0, _sel - 1)
	elif event.is_action_pressed("move_down"):
		_sel = mini(_list_size() - 1, _sel + 1)
	elif event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		_confirm()
	get_viewport().set_input_as_handled()


func _list_size() -> int:
	match _tab:
		0: return maxi(1, main.player.known_techniques.size())
		1: return maxi(1, Game.inventory.size())
		3: return 2
	return 1


func _confirm() -> void:
	if _tab != 3:
		return
	if _sel == 0:
		_msg = "저장했다." if main.save_game() else "저장하지 못했다."
		_msg_t = 2.0
	else:
		if not Game.has_save():
			_msg = "저장된 기록이 없다."
			_msg_t = 2.0
			return
		await close()
		main.load_game(Game.SAVE_PATH)


func _draw_root() -> void:
	_root.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.55))
	_root.draw_rect(BOX.grow(2), INK)
	_root.draw_rect(BOX, PAPER)
	# 탭
	var x := BOX.position.x + 8
	for i in TABS.size():
		var w := Game.font_main.get_string_size(TABS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE).x + 14
		var r := Rect2(x, BOX.position.y + 6, w, 16)
		_root.draw_rect(r, INK if i == _tab else Color("e0d8c6"))
		_s(Vector2(x + 7, r.position.y + 12), TABS[i], PAPER if i == _tab else INK)
		x += w + 4
	_s_small(Vector2(BOX.end.x - 120, BOX.position.y + 18), "←→ 탭  ↑↓ 선택  Tab 닫기", DIM)
	_root.draw_rect(Rect2(BOX.position.x + 6, BOX.position.y + 26, BOX.size.x - 12, 1), INK)
	var area := Rect2(BOX.position.x + 12, BOX.position.y + 34, BOX.size.x - 24, BOX.size.y - 42)
	match _tab:
		0: _draw_techniques(area)
		1: _draw_items(area)
		2: _draw_memory(area)
		3: _draw_save(area)


func _draw_techniques(a: Rect2) -> void:
	var known: Array = main.player.known_techniques
	if known.is_empty():
		_s(a.position + Vector2(0, 14), "아직 익힌 초식이 없다.", DIM)
		return
	var y := a.position.y + 12
	for i in known.size():
		var t: Dictionary = Techniques.TECHNIQUES[known[i]]
		if i == _sel:
			_root.draw_rect(Rect2(a.position.x - 4, y - 11, a.size.x + 8, 46), Color("e8e0cc"))
		_s(Vector2(a.position.x, y), t.name, INK)
		# 커맨드: Shift 유지 + 화살표 + F
		var cx := a.position.x + 70
		_s_small(Vector2(cx, y), "Shift 유지", DIM)
		cx += 54
		for tok in t.command:
			_s(Vector2(cx, y), Techniques.TOKEN_ARROW[tok], INK)
			cx += 14
		_s(Vector2(cx, y), "+ F", INK)
		_s_small(Vector2(a.end.x - 60, y), "내공 %d" % int(t.qi), Color("3c6a9a"))
		_s_small(Vector2(a.position.x, y + 16), t.get("desc", ""), Color("4a4238"))
		y += 50
	_s_small(Vector2(a.position.x, a.end.y - 2), "커맨드는 외워 두자. 싸울 때는 보여 주지 않는다.", DIM)


func _draw_items(a: Rect2) -> void:
	var weapon: Dictionary = Techniques.WEAPONS.get(main.player.weapon_id, Techniques.WEAPONS.fist)
	_s_small(Vector2(a.position.x, a.position.y + 8), "무기: " + weapon.name, Color("3c6a9a"))
	if Game.inventory.is_empty():
		_s(a.position + Vector2(0, 28), "가진 것이 없다.", DIM)
		return
	var y := a.position.y + 28
	for i in Game.inventory.size():
		var it: Dictionary = Game.ITEMS.get(Game.inventory[i], {"name": Game.inventory[i], "desc": ""})
		if i == _sel:
			_root.draw_rect(Rect2(a.position.x - 4, y - 11, a.size.x + 8, 30), Color("e8e0cc"))
		_s(Vector2(a.position.x, y), it.name, INK)
		_s_small(Vector2(a.position.x + 8, y + 13), it.desc, Color("4a4238"))
		y += 34


func _draw_memory(a: Rect2) -> void:
	if not Game.memory_unlocked:
		_s(a.position + Vector2(0, 14), "아직 떠오르는 것이 없다.", DIM)
		return
	_s_small(Vector2(a.position.x, a.position.y + 6), "기억 속 컷 — 《달무리 강호》 제1화 〈객잔의 아이〉", Color("4a4238"))
	var cw := 88.0
	var chh := 56.0
	for i in 4:
		var r := Rect2(a.position.x + 4 + i * (cw + 12), a.position.y + 20, cw, chh)
		Cuts.draw_cut(_root, r, i)
		_root.draw_multiline_string(Game.font_small, Vector2(r.position.x, r.end.y + 14), Cuts.CAPTIONS[i], HORIZONTAL_ALIGNMENT_LEFT, cw + 6, Game.SMALL_SIZE, 3, INK)
	if Game.flag("q4_won"):
		_s_small(Vector2(a.position.x, a.end.y - 2), "…하지만 이제 이야기는 1화와 다르게 흘러간다.", Color("b02a2a"))


func _draw_save(a: Rect2) -> void:
	var items := ["저장하기", "불러오기"]
	for i in items.size():
		var y := a.position.y + 14 + i * 20
		if i == _sel:
			_s(Vector2(a.position.x, y), "▶", INK)
		_s(Vector2(a.position.x + 14, y), items[i], INK)
	_s_small(Vector2(a.position.x, a.position.y + 64), "지금: " + main.region.region_name + " · " + Game.clock_text(), DIM)
	if _msg_t > 0.0:
		_s(Vector2(a.position.x, a.position.y + 90), _msg, Color("3c6a9a"))


func _s(pos: Vector2, text: String, col: Color) -> void:
	_root.draw_string(Game.font_main, pos.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.MAIN_SIZE, col)


func _s_small(pos: Vector2, text: String, col: Color) -> void:
	_root.draw_string(Game.font_small, pos.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.SMALL_SIZE, col)
