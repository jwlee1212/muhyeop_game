extends CharacterBody2D
## 적. 종류(kind)별 능력치와 공격 패턴을 KINDS / ATTACKS 표에서 읽는다.
##   thug  황가 패거리: 베기 1종, 맞으면 움찔한다
##   hwang 황가(우두머리): 내려찍기·발구르기·돌진, 기세가 무너지기 전엔 움찔하지 않는다(armored),
##         부하가 모두 쓰러지면 분노해 빨라진다
## 공통: 배회 → 추격(격자 길찾기) → 예비동작(바닥 예고) → 공격 → 빈틈.
## 기세: 공격을 받으면 깎이고 0이 되면 "기세 붕괴"(경직, 받는 피해 1.5배). 한동안 안 맞으면 회복.

signal died(enemy)

const Body := preload("res://scripts/dummy_body.gd")
const Player := preload("res://scripts/player.gd")
const PixelFx := preload("res://scripts/pixel_fx.gd")
const Telegraph := preload("res://scripts/combat/telegraph.gd")
const DIRS8 := Body.DIRS8

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, BROKEN, DEAD }

const KINDS := {
	"thug": {
		"name": "황가 패거리", "hp": 40.0, "poise": 24.0, "armored": false, "boss": false,
		"speed": 52.0, "detect": 120.0, "attack_range": 20.0, "broken_time": 1.4, "cooldown": 0.6,
		"attacks": ["slash"], "weapon_len": 11,
		"palette": {"robe": Color("8a5a3a"), "robe_dark": Color("5a3a26"), "trim": Color("b02a2a"),
			"skin": Color("d8a878"), "hair": Color("2a1e18"), "weapon": Color("8a6a44"),
			"hilt": Color("3a2a1a"), "shoe": Color("1e1814")},
	},
	"hwang": {
		"name": "황가", "hp": 200.0, "poise": 90.0, "armored": true, "boss": true,
		"speed": 46.0, "detect": 170.0, "attack_range": 30.0, "broken_time": 2.2, "cooldown": 0.9,
		"attacks": ["slam", "stomp", "charge"], "weapon_len": 14,
		"palette": {"robe": Color("6a2a2e"), "robe_dark": Color("461a1e"), "trim": Color("d8b040"),
			"skin": Color("c89868"), "hair": Color("141014"), "weapon": Color("6e4a2c"),
			"hilt": Color("3a2416"), "shoe": Color("1a1412")},
	},
}

## 공격 패턴. shape: arc(앞쪽 부채꼴) / circle(제자리 원) / line(돌진)
const ATTACKS := {
	"slash":  {"windup": 0.45, "shape": "arc", "radius": 26.0, "arc": 140.0, "dmg": 10.0, "lunge": 80.0, "active": 0.2, "recovery": 0.5},
	"slam":   {"windup": 0.75, "shape": "arc", "radius": 38.0, "arc": 150.0, "dmg": 18.0, "lunge": 40.0, "active": 0.25, "recovery": 0.7, "fx": "impacts/heavy-landing"},
	"stomp":  {"windup": 0.60, "shape": "circle", "radius": 40.0, "dmg": 12.0, "active": 0.25, "recovery": 0.6, "fx": "impacts/heavy-landing"},
	"charge": {"windup": 0.55, "shape": "line", "length": 100.0, "width": 10.0, "dmg": 14.0, "speed": 260.0, "recovery": 0.8},
}

const DIRECT_RANGE := 24.0      # 이보다 가까우면 길찾기 없이 곧장
const REPATH_INTERVAL := 0.3
const POISE_REGEN_DELAY := 1.5

@export var kind := "thug"
var stats: Dictionary
var radius := 6.0
var max_hp := 40.0
var hp := 40.0
var max_poise := 24.0
var poise := 24.0
var move_speed := 50.0
var detect_range := 120.0
var lose_range := 220.0
var attack_range := 20.0
var damage_mult := 1.0          # 시험용 (0이면 무해)
var enraged := false

var state := State.IDLE
var state_time := 0.0
var facing := 0
var knock := Vector2.ZERO
var wander_dir := Vector2.ZERO
var attack_cd := 0.0
var attack_id := ""
var attack_dir := Vector2.DOWN
var attack_done := false
var charge_from := Vector2.ZERO
var _poise_idle := 0.0
var _ally_check := 0.0

var region = null               # 길찾기를 제공하는 지역 (find_path, ground_fx)
var _path := PackedVector2Array()
var _path_i := 0
var _repath_t := 0.0

var body: Body
var telegraph: Node2D


func _ready() -> void:
	stats = KINDS.get(kind, KINDS.thug)
	max_hp = stats.hp
	hp = max_hp
	max_poise = stats.poise
	poise = max_poise
	move_speed = stats.speed
	detect_range = stats.detect
	attack_range = stats.attack_range
	add_to_group("enemies")
	if stats.boss:
		add_to_group("boss")
	collision_layer = 4
	collision_mask = 1 | 4

	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -2)
	add_child(cs)

	body = Body.new()
	body.palette = stats.palette
	body.weapon_len = stats.weapon_len
	add_child(body)


func display_name() -> String:
	return stats.name


func can_be_hit() -> bool:
	return state != State.DEAD


func is_engaged() -> bool:
	return state != State.IDLE and state != State.DEAD


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	state_time += delta
	attack_cd = maxf(0.0, attack_cd - delta)
	_update_poise(delta)
	if stats.boss and not enraged:
		_check_enrage(delta)
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
			else:
				var pick := _choose_attack(dist) if attack_cd <= 0.0 else ""
				if pick != "":
					_start_windup(pick, to_p)
				else:
					var dir := _chase_dir(p.global_position, dist, delta)
					velocity = dir * _speed() if dist > attack_range - 4.0 else Vector2.ZERO
					facing = Player.dir_index(dir if dir != Vector2.ZERO else to_p)
		State.WINDUP:
			velocity = Vector2.ZERO
			var a: Dictionary = ATTACKS[attack_id]
			var w := _windup_time(a)
			if telegraph:
				telegraph.global_position = global_position
				telegraph.progress = state_time / w
			if state_time >= w:
				_clear_telegraph()
				attack_done = false
				charge_from = global_position
				_set_state(State.ATTACK)
		State.ATTACK:
			_process_attack(p, player_alive, delta)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_time >= ATTACKS[attack_id].recovery:
				attack_cd = stats.cooldown * (0.6 if enraged else 1.0)
				_set_state(State.CHASE)
		State.HURT:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
			if state_time >= 0.3:
				_set_state(State.CHASE)
		State.BROKEN:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
			if state_time >= stats.broken_time:
				poise = max_poise
				_set_state(State.CHASE)
		State.DEAD:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
			body.modulate.a = maxf(0.0, 1.0 - state_time / 0.6)
			if state_time >= 0.6:
				queue_free()

	move_and_slide()
	_update_body()


# ───────────── 공격 ─────────────

func _speed() -> float:
	return move_speed * (1.25 if enraged else 1.0)


func _windup_time(a: Dictionary) -> float:
	return a.windup * (0.75 if enraged else 1.0)


func _choose_attack(dist: float) -> String:
	var list: Array = stats.attacks
	if kind == "hwang":
		if dist < 46.0:
			return "stomp" if randf() < 0.3 else "slam"
		if dist < 150.0 and randf() < 0.025:   # 거리가 벌어지면 가끔 돌진
			return "charge"
		return ""
	if "slash" in list and dist < attack_range + 4.0:
		return "slash"
	return ""


func _start_windup(id: String, to_p: Vector2) -> void:
	attack_id = id
	attack_dir = to_p.normalized() if to_p.length() > 0.1 else DIRS8[facing]
	facing = Player.dir_index(attack_dir)
	_set_state(State.WINDUP)
	_spawn_telegraph(ATTACKS[id])


func _process_attack(p: Player, player_alive: bool, delta: float) -> void:
	var a: Dictionary = ATTACKS[attack_id]
	if a.shape == "line":
		# 돌진: 길이만큼 달리거나 벽에 막히면 멈춘다. 닿으면 한 번 피해.
		velocity = attack_dir * a.speed
		if not attack_done and p and player_alive and global_position.distance_to(p.global_position) < radius + 9.0:
			attack_done = true
			p.take_damage(a.dmg * damage_mult, attack_dir)
		var travelled := global_position.distance_to(charge_from)
		var blocked: bool = state_time > 0.08 and get_real_velocity().length() < a.speed * 0.3
		if travelled >= a.length or blocked:
			if blocked:
				Fx.shake(3.0)
			_set_state(State.RECOVER)
		return
	velocity = attack_dir * a.get("lunge", 0.0) if state_time < 0.1 else Vector2.ZERO
	if not attack_done and state_time >= 0.04:
		attack_done = true
		var center := global_position
		if a.has("fx"):
			var fx_pos := center + (attack_dir * 14.0 if a.shape == "arc" else Vector2.ZERO)
			PixelFx.spawn(get_parent(), a.fx, fx_pos, 0.0, Vector2(-1, -1), false, false, 1.6)
			Fx.shake(4.0)
		if p and player_alive and _in_shape(a, p.global_position - center):
			p.take_damage(a.dmg * damage_mult, (p.global_position - center).normalized())
	if state_time >= a.active:
		_set_state(State.RECOVER)


func _in_shape(a: Dictionary, to: Vector2) -> bool:
	var reach: float = a.radius + 5.0
	if to.length() > reach:
		return false
	if a.shape == "arc" and to.length() > 6.0:
		return absf(attack_dir.angle_to(to)) <= deg_to_rad(a.arc) * 0.5
	return true


func _spawn_telegraph(a: Dictionary) -> void:
	_clear_telegraph()
	telegraph = Telegraph.new()
	telegraph.shape = a.shape
	telegraph.radius = a.get("radius", 30.0)
	telegraph.arc = deg_to_rad(a.get("arc", 120.0))
	telegraph.length = a.get("length", 80.0)
	telegraph.width = a.get("width", 10.0)
	telegraph.rotation = attack_dir.angle() if a.shape != "circle" else 0.0
	var parent: Node = region.ground_fx if region and region.get("ground_fx") else get_parent()
	parent.add_child(telegraph)
	telegraph.global_position = global_position


func _clear_telegraph() -> void:
	if telegraph and is_instance_valid(telegraph):
		telegraph.queue_free()
	telegraph = null


func _check_enrage(delta: float) -> void:
	_ally_check -= delta
	if _ally_check > 0.0:
		return
	_ally_check = 0.5
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and e.kind == "thug" and e.state != State.DEAD:
			return
	if state == State.IDLE:
		return
	enraged = true
	Fx.popup_text(global_position, "황가가 분노했다", Color("ff8a6a"))


# ───────────── 길찾기 ─────────────

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


# ───────────── 피격·기세 ─────────────

func take_hit(amount: float, dir: Vector2, knockback: float, poise_dmg := 0.0) -> void:
	if state == State.DEAD:
		return
	var broken := state == State.BROKEN
	if broken:
		amount *= 1.5
	hp -= amount
	body.flash = 0.1
	Fx.damage_number(global_position, int(amount), Color("ffd060") if broken else Color(1, 0.95, 0.8))
	if hp <= 0.0:
		knock = dir * knockback * 1.5
		_clear_telegraph()
		_set_state(State.DEAD)
		died.emit(self)
		if stats.boss:
			Fx.popup_text(global_position, stats.name + " 쓰러짐", Color("ffe0a0"))
		return
	if broken:
		knock = dir * knockback * 0.5
		return
	poise -= poise_dmg
	_poise_idle = 0.0
	if poise <= 0.0:
		_break(dir, knockback)
	elif stats.armored:
		knock = Vector2.ZERO      # 움찔하지 않고 하던 동작을 계속한다
	else:
		knock = dir * knockback
		_clear_telegraph()
		_set_state(State.HURT)


func _break(dir: Vector2, knockback: float) -> void:
	poise = 0.0
	knock = dir * knockback * 0.7
	_clear_telegraph()
	_set_state(State.BROKEN)
	PixelFx.spawn(get_parent(), "impacts/crit-hit", global_position, 0.0, Vector2(-1, -1), dir.x < 0.0, false, 1.3)
	Fx.popup_text(global_position, "기세 붕괴", Color("ffd060"))
	Fx.hitstop(0.12)
	Fx.shake(5.0)


func _update_poise(delta: float) -> void:
	if state == State.BROKEN or state == State.DEAD:
		return
	_poise_idle += delta
	if _poise_idle > POISE_REGEN_DELAY and poise < max_poise:
		poise = minf(max_poise, poise + max_poise * 0.3 * delta)


func _set_state(s: State) -> void:
	state = s
	state_time = 0.0


func _update_body() -> void:
	body.facing = facing
	body.moving = velocity.length() > 5.0 and state in [State.IDLE, State.CHASE, State.ATTACK]
	body.windup = state == State.WINDUP
	body.stunned = state == State.BROKEN
	body.poise_ratio = poise / max_poise if (poise < max_poise and state != State.DEAD) else -1.0
	if state == State.ATTACK and attack_id != "charge":
		var a: Dictionary = ATTACKS[attack_id]
		body.attack_t = clampf(state_time / 0.14, 0.0, 1.0)
		body.attack_arc = deg_to_rad(a.get("arc", 120.0))
		body.attack_range = a.get("radius", attack_range)
	else:
		body.attack_t = -1.0
	if enraged and state != State.DEAD:
		body.modulate = Color(1.0, 0.8, 0.8, body.modulate.a)
