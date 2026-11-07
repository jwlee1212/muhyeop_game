extends Node
## 타격감 연출 헬퍼: 히트스톱, 화면 흔들림, 데미지 숫자.

var _hitstop_active := false


## 아주 짧게 게임 시간을 멈춘다. 타격 순간의 "묵직함".
func hitstop(duration: float = 0.05) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false


func shake(amount: float) -> void:
	var cam := get_tree().get_first_node_in_group("main_camera")
	if cam and cam.has_method("add_shake"):
		cam.add_shake(amount)


func damage_number(world_pos: Vector2, value: int, color: Color = Color(1, 0.95, 0.8)) -> void:
	var world := get_tree().get_first_node_in_group("fx_layer")
	if world == null:
		return
	var label := Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 2)
	label.position = (world_pos + Vector2(-6, -38)).round()
	label.z_index = 100
	world.add_child(label)
	var tw := label.create_tween()
	tw.tween_property(label, "position:y", label.position.y - 12, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tw.tween_callback(label.queue_free)
