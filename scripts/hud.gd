extends CanvasLayer
## 기혈(체력) / 내공 바 + F1 조작 안내.

const Player := preload("res://scripts/player.gd")

var player: Player
var _canvas := Control.new()
var _help := Label.new()


func _ready() -> void:
	layer = 10
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)

	_help.text = "이동 WASD  공격 J  경공 K  운기조식 R(유지)  F1 도움말"
	_help.add_theme_font_size_override("font_size", 8)
	_help.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_help.add_theme_constant_override("outline_size", 2)
	_help.position = Vector2(6, 256)
	add_child(_help)

	if player:
		player.stats_changed.connect(_canvas.queue_redraw)


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
