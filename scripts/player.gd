extends CharacterBody2D
## 주인공. 8방향 이동, 3타 콤보, 경공(대시, 내공 소모), 피격·무적 시간, 운기조식.

signal stats_changed

const Body := preload("res://scripts/dummy_body.gd")
const ShakeCamera := preload("res://scripts/shake_camera.gd")
const PixelFx := preload("res://scripts/pixel_fx.gd")
const DIRS8 := Body.DIRS8

## pixelfx 시트 안에서 베기 궤적의 중심 픽셀 (소스: cx, cy + pivot)
const SLASH_ANCHOR := Vector2(50, 66)   # melee/sword-slash, pivot (44,92) + (6,-26)
const SPIN_ANCHOR := Vector2(104, 65)   # melee/spin-slash,  pivot (104,94) + (0,-17)

const MOVE_SPEED := 90.0
const DASH_SPEED := 260.0
const DASH_TIME := 0.16
const DASH_COST := 15.0
const QI_PER_HIT := 6.0
const HIT_CENTER := Vector2(0, -10)

## 3타 콤보: 피해, 사거리, 범위각(도), 판정 시점, 전체 길이, 전진량, 넉백
const COMBO := [
	{"dmg": 10, "range": 22.0, "arc": 110.0, "active": 0.06, "duration": 0.24, "lunge": 70.0, "knock": 90.0},
	{"dmg": 12, "range": 22.0, "arc": 110.0, "active": 0.06, "duration": 0.24, "lunge": 70.0, "knock": 90.0},
	{"dmg": 22, "range": 28.0, "arc": 360.0, "active": 0.10, "duration": 0.40, "lunge": 120.0, "knock": 200.0},
]

enum State { MOVE, ATTACK, DASH, HURT, MEDITATE, DEAD }

var max_hp := 100.0
var hp := 100.0
var max_qi := 100.0
var qi := 40.0

var state := State.MOVE
var state_time := 0.0
var facing := 0
var combo := 0
var combo_window := 0.0
var attack_hit := false
var queued_attack := false
var inv_time := 0.0
var knock := Vector2.ZERO
var dash_dir := Vector2.ZERO
var spawn_point := Vector2.ZERO

var body: Body
var camera: ShakeCamera


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	spawn_point = global_position

	var shape := CircleShape2D.new()
	shape.radius = 5
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -2)
	add_child(cs)

	body = Body.new()
	body.draw_trail = false   # 베기 궤적은 pixelfx 이펙트가 그린다
	add_child(body)

	camera = ShakeCamera.new()
	camera.position = Vector2(0, -12)
	add_child(camera)


func _physics_process(delta: float) -> void:
	state_time += delta
	inv_time = maxf(0.0, inv_time - delta)
	combo_window = maxf(0.0, combo_window - delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	match state:
		State.MOVE:
			velocity = input * MOVE_SPEED
			if input.length() > 0.2:
				facing = dir_index(input)
			if Input.is_action_just_pressed("attack"):
				_start_attack(input)
			elif Input.is_action_just_pressed("dash"):
				_try_dash(input)
			elif Input.is_action_pressed("meditate") and input == Vector2.ZERO:
				_set_state(State.MEDITATE)
		State.ATTACK:
			_process_attack(input)
		State.DASH:
			velocity = dash_dir * DASH_SPEED
			if state_time >= DASH_TIME:
				_set_state(State.MOVE)
		State.HURT:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
			if state_time >= 0.25:
				_set_state(State.MOVE)
		State.MEDITATE:
			# 운기조식: 가만히 서서 내공·기혈 회복. 움직이거나 키를 떼면 중단.
			velocity = Vector2.ZERO
			if state_time > 0.4:
				_add_qi(25.0 * delta)
				_heal(4.0 * delta)
			if not Input.is_action_pressed("meditate") or input != Vector2.ZERO:
				_set_state(State.MOVE)
		State.DEAD:
			velocity = Vector2.ZERO
			if state_time > 1.5:
				_respawn()

	move_and_slide()
	_update_body()


func _process_attack(input: Vector2) -> void:
	var data: Dictionary = COMBO[combo]
	var dur: float = data.duration
	# 판정 직전까지 짧게 전진
	velocity = DIRS8[facing] * data.lunge if state_time < data.active + 0.04 else Vector2.ZERO
	if not attack_hit and state_time >= data.active:
		attack_hit = true
		_do_hit(data)
	if Input.is_action_just_pressed("attack"):
		queued_attack = true
	# 판정 이후에는 경공으로 캔슬 가능
	if attack_hit and Input.is_action_just_pressed("dash"):
		_try_dash(input)
		return
	if state_time >= dur:
		if queued_attack and combo < COMBO.size() - 1:
			combo += 1
			if input.length() > 0.2:
				facing = dir_index(input)
			_begin_attack_step()
		else:
			combo_window = 0.0 if combo == COMBO.size() - 1 else 0.3
			_set_state(State.MOVE)


func _start_attack(input: Vector2) -> void:
	if combo_window > 0.0 and combo < COMBO.size() - 1:
		combo += 1
	else:
		combo = 0
	if input.length() > 0.2:
		facing = dir_index(input)
	_begin_attack_step()


func _begin_attack_step() -> void:
	attack_hit = false
	queued_attack = false
	_set_state(State.ATTACK)
	_spawn_slash_fx()


func _spawn_slash_fx() -> void:
	var parent := get_parent()
	if combo == COMBO.size() - 1:
		# 3타: 허리를 도는 회전베기
		PixelFx.spawn(parent, "melee/spin-slash", global_position + Vector2(0, -8), 0.0, SPIN_ANCHOR, false, false, 1.4)
		return
	var aim: Vector2 = DIRS8[facing]
	# 2타는 반대 방향으로 휘두른다. 왼쪽을 볼 때는 상하를 뒤집어 궤적이 위에서 아래로 떨어지게.
	var flip := (combo == 1) != (aim.x < -0.1)
	PixelFx.spawn(parent, "melee/sword-slash", global_position + HIT_CENTER, aim.angle(), SLASH_ANCHOR, false, flip, 1.5)


func _do_hit(data: Dictionary) -> void:
	var origin := global_position + HIT_CENTER
	var aim: Vector2 = DIRS8[facing]
	var half_arc := deg_to_rad(data.arc) * 0.5
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.can_be_hit():
			continue
		var to: Vector2 = (e.global_position + HIT_CENTER) - origin
		var reach: float = data.range + e.radius
		if to.length() > reach:
			continue
		if to.length() > 8.0 and absf(aim.angle_to(to)) > half_arc:
			continue
		var hit_dir: Vector2 = to.normalized() if to.length() > 0.1 else aim
		e.take_hit(data.dmg, hit_dir, data.knock)
		PixelFx.spawn(get_parent(), "impacts/hit-spark", e.global_position, 0.0, Vector2(-1, -1), hit_dir.x < 0.0)
		hit_any = true
	if hit_any:
		_add_qi(QI_PER_HIT)
		Fx.hitstop(0.07 if combo == 2 else 0.045)
		Fx.shake(3.0 if combo == 2 else 1.5)


func _try_dash(input: Vector2) -> void:
	if qi < DASH_COST:
		body.flash = 0.05
		return
	_add_qi(-DASH_COST)
	dash_dir = input.normalized() if input.length() > 0.2 else DIRS8[facing]
	facing = dir_index(dash_dir)
	inv_time = maxf(inv_time, DASH_TIME + 0.05)
	_set_state(State.DASH)
	_spawn_afterimages()


func _spawn_afterimages() -> void:
	for i in range(3):
		await get_tree().create_timer(0.04 * i).timeout
		if not is_inside_tree():
			return
		var ghost := Body.new()
		ghost.facing = facing
		ghost.palette = body.palette
		ghost.global_position = global_position
		ghost.modulate = Color(0.6, 0.8, 1.0, 0.5)
		ghost.z_index = -1
		get_parent().add_child(ghost)
		var tw := ghost.create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
		tw.tween_callback(ghost.queue_free)


func take_damage(amount: float, from_dir: Vector2) -> void:
	if inv_time > 0.0 or state == State.DEAD:
		return
	hp = maxf(0.0, hp - amount)
	inv_time = 0.8
	knock = from_dir * 150.0
	body.flash = 0.1
	Fx.damage_number(global_position, int(amount), Color(1, 0.4, 0.35))
	Fx.shake(4.0)
	Fx.hitstop(0.06)
	stats_changed.emit()
	_set_state(State.DEAD if hp <= 0.0 else State.HURT)


func _respawn() -> void:
	global_position = spawn_point
	hp = max_hp
	qi = 40.0
	inv_time = 1.5
	stats_changed.emit()
	_set_state(State.MOVE)


func _set_state(s: State) -> void:
	state = s
	state_time = 0.0


func _add_qi(v: float) -> void:
	qi = clampf(qi + v, 0.0, max_qi)
	stats_changed.emit()


func _heal(v: float) -> void:
	hp = clampf(hp + v, 0.0, max_hp)
	stats_changed.emit()


func _update_body() -> void:
	body.facing = facing
	body.moving = state == State.MOVE and velocity.length() > 5.0
	if state == State.ATTACK:
		var data: Dictionary = COMBO[combo]
		body.attack_t = clampf(state_time / (data.active + 0.08), 0.0, 1.0)
		body.attack_arc = deg_to_rad(data.arc)
		body.attack_range = data.range
		body.swing_sign = -1.0 if combo == 1 else 1.0
		body.weapon_len = 13 if combo == 2 else 11
	else:
		body.attack_t = -1.0
	# 무적 시간 깜빡임, 운기조식 중 푸른 기운
	var blink := inv_time > 0.0 and state != State.DASH and int(inv_time * 20.0) % 2 == 0
	if state == State.DEAD:
		body.modulate = Color(1, 1, 1, maxf(0.0, 1.0 - state_time))
	elif state == State.MEDITATE:
		var p := 0.5 + 0.5 * sin(state_time * 6.0)
		body.modulate = Color(0.8 + 0.2 * p, 0.9 + 0.1 * p, 1.0, 1.0)
	else:
		body.modulate = Color(1, 1, 1, 0.4 if blink else 1.0)


static func dir_index(v: Vector2) -> int:
	# 화면 좌표(y가 아래) 기준 S=0부터 반시계 방향 8분할
	var a := atan2(v.x, v.y)  # S=0, E=+90도
	var idx := int(round(a / (PI / 4.0)))
	return posmod(idx, 8)
