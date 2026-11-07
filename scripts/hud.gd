extends CanvasLayer
## 기혈(체력) / 내공 바, 지역 이름, 기수식 커맨드 표시, 보스 체력·기세 바, F1 조작 안내.

const Player := preload("res://scripts/player.gd")
const Techniques := preload("res://scripts/combat/techniques.gd")

const TOKEN_ANGLE := {"U": 0.0, "R": PI * 0.5, "D": PI, "L": -PI * 0.5}

var player: Player
var _canvas := Control.new()
var _help := Label.new()
var _region_label := Label.new()
var _region_tween: Tween
var _fail_text := ""
var _fail_time := 0.0


func _ready() -> void:
	layer = 10
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)

	_help.text = "이동 WASD  공격 J  경공 K  기수식 Q(유지)  운기조식 R(유지)  F1"
	_help.add_theme_font_size_override("font_size", 8)
	_help.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_help.add_theme_constant_override("outline_size", 2)
	_help.position = Vector2(6, 256)
	add_child(_help)

	_region_label.add_theme_font_size_override("font_size", 16)
	_region_label.add_theme_color_override("font_color", Color("f0e6cc"))
	_region_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04))
	_region_label.add_theme_constant_override("outline_size", 4)
	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_label.position = Vector2(0, 34)
	_region_label.size = Vector2(480, 20)
	_region_label.modulate.a = 0.0
	add_child(_region_label)

	if player:
		player.stats_changed.connect(_canvas.queue_redraw)
		player.technique_failed.connect(_on_technique_failed)


func _process(delta: float) -> void:
	_fail_time = maxf(0.0, _fail_time - delta)
	_canvas.queue_redraw()


func _on_technique_failed(reason: String) -> void:
	_fail_text = reason
	_fail_time = 0.9


## 지역에 들어올 때 지역 이름을 잠깐 띄운다.
func show_region_name(region_name: String) -> void:
	_region_label.text = region_name
	if _region_tween:
		_region_tween.kill()
	_region_label.modulate.a = 0.0
	_region_tween = create_tween()
	_region_tween.tween_property(_region_label, "modulate:a", 1.0, 0.3)
	_region_tween.tween_interval(1.4)
	_region_tween.tween_property(_region_label, "modulate:a", 0.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_help.visible = not _help.visible


func _bar(pos: Vector2, w: int, ratio: float, fill: Color, back: Color) -> void:
	_canvas.draw_rect(Rect2(pos - Vector2.ONE, Vector2(w + 2, 6)), Color("14100c"))
	_canvas.draw_rect(Rect2(pos, Vector2(w, 4)), back)
	_canvas.draw_rect(Rect2(pos, Vector2(roundf(w * clampf(ratio, 0, 1)), 4)), fill)
	_canvas.draw_rect(Rect2(pos, Vector2(roundf(w * clampf(ratio, 0, 1)), 1)), fill.lightened(0.35))


func _on_draw() -> void:
	if player == null:
		return
	# 아이콘: 붉은 점 = 기혈, 푸른 점 = 내공
	_canvas.draw_rect(Rect2(6, 6, 4, 4), Color("c83c34"))
	_bar(Vector2(13, 6), 70, player.hp / player.max_hp, Color("c83c34"), Color("401614"))
	_canvas.draw_rect(Rect2(6, 13, 4, 4), Color("3c8ac8"))
	_bar(Vector2(13, 13), 70, player.qi / player.max_qi, Color("3c8ac8"), Color("142840"))
	# 경공 사용 가능선 표시
	var mark := 13 + roundf(70 * Player.DASH_COST / player.max_qi)
	_canvas.draw_rect(Rect2(mark, 12, 1, 6), Color(1, 1, 1, 0.6))
	_draw_stance()
	_draw_boss()
	if _fail_time > 0.0:
		_text(Vector2(240, 214), _fail_text, Color(1, 0.6, 0.5, minf(1.0, _fail_time * 3.0)), true)


func _text(pos: Vector2, text: String, col: Color, centered := false, size := 8) -> void:
	var font := ThemeDB.fallback_font
	var x := pos.x
	if centered:
		x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	var p := Vector2(roundf(x), pos.y)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_canvas.draw_string(font, p + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.05, 0.04, 0.06, col.a))
	_canvas.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## 방향 화살표 (화면 기준).
func _arrow(center: Vector2, tok: String, col: Color) -> void:
	var a: float = TOKEN_ANGLE.get(tok, 0.0)
	var pts := PackedVector2Array()
	for v in [Vector2(0, -4), Vector2(4, 0), Vector2(1, 0), Vector2(1, 4), Vector2(-1, 4), Vector2(-1, 0), Vector2(-4, 0)]:
		pts.append(center + v.rotated(a))
	_canvas.draw_colored_polygon(pts, col)


func _draw_stance() -> void:
	if player.state != Player.State.STANCE:
		return
	var base := Vector2(240, 226)
	_text(base + Vector2(0, -10), "기수식", Color("bfe4ff"), true)
	var n := Techniques.MAX_TOKENS
	for i in n:
		var c := base + Vector2((i - (n - 1) * 0.5) * 13.0, 4)
		_canvas.draw_rect(Rect2(c - Vector2(5, 5), Vector2(11, 11)), Color(0.05, 0.08, 0.14, 0.75))
		_canvas.draw_rect(Rect2(c - Vector2(5, 5), Vector2(11, 11)), Color(0.5, 0.75, 1.0, 0.5), false, 1.0)
		if i < player.tokens.size():
			_arrow(c + Vector2(0.5, 0.5), player.tokens[i], Color("e8f6ff"))
	# 커맨드 목록은 띄우지 않는다. 무공 메뉴(M4)에서 보고 외워서 쓴다.


func _draw_boss() -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null or not boss.is_engaged():
		return
	# 화면 위 가운데: 이름, 체력(빨강), 기세(노랑)
	var x := 140.0
	var y := 8.0
	_text(Vector2(240, y + 3), boss.display_name(), Color("f0e0c0"), true)
	_bar(Vector2(x, y + 6), 200, boss.hp / boss.max_hp, Color("c83c34"), Color("401614"))
	_canvas.draw_rect(Rect2(x, y + 12, 200, 2), Color(0.1, 0.08, 0.04))
	var pr: float = 0.0 if boss.state == boss.State.BROKEN else boss.poise / boss.max_poise
	_canvas.draw_rect(Rect2(x, y + 12, roundf(200 * pr), 2), Color("f0c040"))
