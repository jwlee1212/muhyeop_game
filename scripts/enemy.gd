extends CharacterBody2D
## 산적 (적 AI 1종). 배회 → 추격 → 예비동작(!) → 베기 → 경직. 피격 시 넉백·경직.

signal died(enemy)

const Body := preload("res://scripts/dummy_body.gd")
const Player := preload("res://scripts/player.gd")
const DIRS8 := Body.DIRS8

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }

@export var max_hp := 40.0
@export var move_speed := 50.0
@export var damage := 12.0
@export var detect_range := 110.0
@export var lose_range := 180.0
@export var attack_range := 20.0

var radius := 6.0
var hp := 40.0
var state := State.IDLE
var state_time := 0.0
var facing := 0
var knock := Vector2.ZERO
var wander_dir := Vector2.ZERO
var attack_cd := 0.0
var attack_dir := Vector2.DOWN
var attack_done := false

const DIRECT_RANGE := 24.0      # 이보다 가까우면 길찾기 없이 곧장
const REPATH_INTERVAL := 0.3
var region = null              # 길찾기를 제공하는 지역 (find_path)
var _path := PackedVector2Array()
var _path_i := 0
var _repath_t := 0.0

var body: Body


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	hp = max_hp

	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -2)
	add_child(cs)

	body = Body.new()
	body.palette = {
		"robe": Color("8a5a3a"), "robe_dark": Color("5a3a26"), "trim": Color("b02a2a"),
		"skin": Color("d8a878"), "hair": Color("2a1e18"), "weapon": Color("b8b0a0"),
		"hilt": Color("3a2a1a"), "shoe": Color("1e1814"),
	}
	add_child(body)


## 지역 격자 길찾기로 다음에 갈 방향. 가까우면 곧장 다가간다.
func _chase_dir(target: Vector2, dist: float, delta: float) -> Vector2:
	var goal := target
	if region and dist > DIRECT_RANGE:
		_repath_t -= delta
		if _repath_t <= 0.0:
			_repath_t = REPATH_INTERVAL
			_path = region.find_path(global_position, target)
			_path_i = 1
		while _path_i < _path.size() and global_position.distance_to(_path[_path_i]) < 3.0:
			_path_i += 1
		if _path_i < _path.size():
			goal = _path[_path_i]
	else:
		_path = PackedVector2Array()
		_repath_t = 0.0
	var to_goal := goal - global_position
	return to_goal.normalized() if to_goal.length() > 0.5 else Vector2.ZERO


func can_be_hit() -> bool:
	return state != State.DEAD


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	state_time += delta
	attack_cd = maxf(0.0, attack_cd - delta)
	var p := _player()
	var to_p := Vector2.ZERO
	var dist := INF
	var player_alive := false
	if p:
		to_p = p.global_position - global_position
		dist = to_p.length()
		player_alive = p.state != Player.State.DEAD

	match state:
		State.IDLE:
			if state_time > 1.2:
				state_time = 0.0
				wander_dir = Vector2.ZERO if randf() < 0.4 else Vector2.RIGHT.rotated(randf() * TAU)
			velocity = wander_dir * move_speed * 0.4
			if wander_dir != Vector2.ZERO:
				facing = Player.dir_index(wander_dir)
			if player_alive and dist < detect_range:
				_set_state(State.CHASE)
		State.CHASE:
			if not player_alive or dist > lose_range:
				_set_state(State.IDLE)
			elif dist < attack_range + 4.0 and attack_cd <= 0.0:
				attack_dir = to_p.normalized()
				facing = Player.dir_index(attack_dir)
				_set_state(State.WINDUP)
			else:
				var dir := _chase_dir(p.global_position, dist, delta)
				velocity = dir * move_speed if dist > attack_range - 2.0 else Vector2.ZERO
				facing = Player.dir_index(dir if dir != Vector2.ZERO else to_p)
		State.WINDUP:
			velocity = Vector2.ZERO
			if state_time >= 0.45:
				attack_done = false
				_set_state(State.ATTACK)
		State.ATTACK:
			velocity = attack_dir * 80.0 if state_time < 0.1 else Vector2.ZERO
			if not attack_done and state_time >= 0.06:
				attack_done = true
				if p and player_alive:
					var to_now := p.global_position - global_position
					if to_now.length() < attack_range + 6.0 and absf(attack_dir.angle_to(to_now)) < deg_to_rad(70):
						p.take_damage(damage, to_now.normalized())
			if state_time >= 0.25:
				_set_state(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_time >= 0.5:
				attack_cd = 0.6
				_set_state(State.CHASE)
		State.HURT:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
			if state_time >= 0.3:
				_set_state(State.CHASE)
		State.DEAD:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
			body.modulate.a = maxf(0.0, 1.0 - state_time / 0.6)
			if state_time >= 0.6:
				queue_free()

	move_and_slide()
	_update_body()


func take_hit(amount: float, dir: Vector2, knockback: float) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	knock = dir * knockback
	body.flash = 0.1
	Fx.damage_number(global_position, int(amount))
	if hp <= 0.0:
		knock *= 1.5
		_set_state(State.DEAD)
		died.emit(self)
	else:
		# 예비동작 중에 맞으면 공격이 끊긴다 (기세 시스템은 3단계에서)
		_set_state(State.HURT)


func _set_state(s: State) -> void:
	state = s
	state_time = 0.0


func _update_body() -> void:
	body.facing = facing
	body.moving = velocity.length() > 5.0 and state in [State.IDLE, State.CHASE]
	body.windup = state == State.WINDUP
	if state == State.ATTACK:
		body.attack_t = clampf(state_time / 0.14, 0.0, 1.0)
		body.attack_arc = deg_to_rad(120)
		body.attack_range = attack_range
	else:
		body.attack_t = -1.0
