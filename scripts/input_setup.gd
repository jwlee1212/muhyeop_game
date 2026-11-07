extends Node
## 입력 액션을 코드로 등록한다 (project.godot의 직렬화된 InputEvent를 손으로 쓰지 않기 위해).
## 키보드(WASD/방향키), 마우스, 게임패드를 모두 지원.

func _enter_tree() -> void:
	_add("move_up", [KEY_W, KEY_UP], [], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add("move_down", [KEY_S, KEY_DOWN], [], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add("move_left", [KEY_A, KEY_LEFT], [], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add("move_right", [KEY_D, KEY_RIGHT], [], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add("attack", [KEY_J], [MOUSE_BUTTON_LEFT], [JOY_BUTTON_X])
	_add("dash", [KEY_K, KEY_SPACE], [MOUSE_BUTTON_RIGHT], [JOY_BUTTON_A])
	_add("meditate", [KEY_R], [], [JOY_BUTTON_Y])
	_add("debug_toggle", [KEY_F1])


func _add(action: String, keys: Array, mouse: Array = [], joy_buttons: Array = [], joy_axes: Array = []) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.3)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for m in mouse:
		var e := InputEventMouseButton.new()
		e.button_index = m
		InputMap.action_add_event(action, e)
	for b in joy_buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)
	for a in joy_axes:
		var e := InputEventJoypadMotion.new()
		e.axis = a[0]
		e.axis_value = a[1]
		InputMap.action_add_event(action, e)
