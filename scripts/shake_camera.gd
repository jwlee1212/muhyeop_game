extends Camera2D
## 플레이어를 부드럽게 따라가는 카메라 + 화면 흔들림.

var _shake := 0.0


func _ready() -> void:
	add_to_group("main_camera")
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	make_current()


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if _shake > 0.0:
		offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)).round()
		_shake = maxf(0.0, _shake - 30.0 * delta)
	else:
		offset = Vector2.ZERO
