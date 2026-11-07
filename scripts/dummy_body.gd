extends Node2D
## 더미 도트 캐릭터 (32x32, 발끝이 원점).
## 5단계에서 SpriteCook 에셋이 나오면 이 노드를 AnimatedSprite2D로 교체한다.
## 인터페이스(facing / moving / attack_t / flash / windup)만 맞추면 Player·Enemy 코드는 그대로 쓴다.
## 애니메이션 이름 규칙: "{동작}_{방향}" 예) walk_s, attack_ne  → 파일명 hero_walk_s_01.png

const DIRS8 := [
	Vector2(0, 1), Vector2(0.7071, 0.7071), Vector2(1, 0), Vector2(0.7071, -0.7071),
	Vector2(0, -1), Vector2(-0.7071, -0.7071), Vector2(-1, 0), Vector2(-0.7071, 0.7071),
]
const DIR_NAMES := ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
const SHADOW := Color(0, 0, 0, 0.28)

var palette := {
	"robe": Color("e8e2d0"), "robe_dark": Color("a49c86"), "trim": Color("3a6ea5"),
	"skin": Color("f0c8a0"), "hair": Color("1e1a22"), "weapon": Color("d8e0e8"),
	"hilt": Color("6b4a2a"), "shoe": Color("2a2420"),
}
var facing := 0
var moving := false
var anim_time := 0.0
var attack_t := -1.0          # 0..1 공격 진행도, -1이면 공격 아님
var attack_arc := 2.0         # 라디안
var attack_range := 22.0
var swing_sign := 1.0
var flash := 0.0
var windup := false
var weapon_len := 11
var draw_trail := true        # false면 코드로 그린 베기 궤적을 생략 (pixelfx 이펙트 사용 시)


func _process(delta: float) -> void:
	anim_time += delta
	flash = maxf(0.0, flash - delta)
	queue_redraw()


func _c(col: Color) -> Color:
	if flash > 0.0:
		return Color(1, 1, 1, col.a)
	if windup and int(anim_time * 16.0) % 2 == 0:
		return col.lerp(Color(1, 0.2, 0.15), 0.45)
	return col


func _r(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(x, y, w, h), _c(col))


func _px(p: Vector2, col: Color) -> void:
	draw_rect(Rect2(p.round(), Vector2.ONE), col)


func _draw() -> void:
	var d: Vector2 = DIRS8[facing]
	var step := int(anim_time * 8.0) % 2 if moving else 0
	var bob := -1 if (moving and step == 1) else 0
	var north := facing in [3, 4, 5]

	# 그림자
	draw_rect(Rect2(-6, -2, 12, 3), SHADOW)
	draw_rect(Rect2(-4, -3, 8, 1), SHADOW)

	if north:
		_draw_weapon(d, bob)

	# 다리 / 신발
	var lh := 4 if step == 0 else 3
	var rh := 3 if (moving and step == 0) else 4
	_r(-4, -1 - lh, 3, lh, palette.robe_dark)
	_r(1, -1 - rh, 3, rh, palette.robe_dark)
	_r(-4, -2, 3, 1, palette.shoe)
	_r(1, -2, 3, 1, palette.shoe)

	# 몸통(도포)
	_r(-6, -17 + bob, 12, 12, palette.robe)
	_r(-6, -6 + bob, 12, 1, palette.robe_dark)
	_r(-6, -11 + bob, 12, 2, palette.trim)        # 허리띠
	if facing in [0, 1, 7]:
		_r(-1, -17 + bob, 2, 3, palette.robe_dark)  # 깃
	# 팔
	var arm_fwd := int(round(d.x * 2.0))
	_r(-8 + min(arm_fwd, 0), -16 + bob, 2, 6, palette.robe_dark)
	_r(6 + max(arm_fwd, 0), -16 + bob, 2, 6, palette.robe_dark)

	# 머리
	_r(-4, -25 + bob, 8, 8, palette.skin)
	if north:
		_r(-4, -25 + bob, 8, 7, palette.hair)
	else:
		_r(-4, -26 + bob, 8, 3, palette.hair)
		if facing == 2:
			_r(-4, -24 + bob, 3, 4, palette.hair)
		elif facing == 6:
			_r(1, -24 + bob, 3, 4, palette.hair)
		var eyes := {0: [-2, 1], 1: [0, 2], 2: [2], 7: [-3, -1], 6: [-3]}
		for ex in eyes.get(facing, []):
			_r(ex, -21 + bob, 1, 1, Color("201818"))
	_r(-1, -28 + bob, 3, 2, palette.hair)          # 상투

	if not north:
		_draw_weapon(d, bob)

	if attack_t >= 0.0 and draw_trail:
		_draw_slash_trail(d)

	if windup:
		var c := Color(1, 0.25, 0.2)
		draw_rect(Rect2(0, -36 + bob, 1, 4), c)
		draw_rect(Rect2(0, -31 + bob, 1, 1), c)


func _swing_angle(d: Vector2, t: float) -> float:
	var e := 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)
	return d.angle() + swing_sign * lerpf(-attack_arc * 0.5, attack_arc * 0.5, e)


func _draw_weapon(d: Vector2, bob: int) -> void:
	var hand := Vector2(roundf(d.x * 5.0), -12 + bob + roundf(d.y * 2.0))
	var dir: Vector2
	if attack_t >= 0.0:
		dir = Vector2.RIGHT.rotated(_swing_angle(d, attack_t))
	else:
		dir = (d + Vector2(0, 0.9)).normalized()
	for i in range(2):
		_px(hand + dir * i, _c(palette.hilt))
	for i in range(2, weapon_len + 2):
		_px(hand + dir * i, _c(palette.weapon))


func _draw_slash_trail(d: Vector2) -> void:
	if attack_t > 0.85:
		return
	var center := Vector2(0, -10)
	var a0 := _swing_angle(d, 0.0)
	var a1 := _swing_angle(d, attack_t)
	var steps := int(absf(a1 - a0) / 0.07) + 1
	var r_out := attack_range
	var r_in := attack_range * 0.55
	for i in range(steps):
		var t := float(i) / float(maxi(1, steps - 1))
		var a := lerpf(a0, a1, t)
		var alpha := t * (1.0 - attack_t)
		var col := Color(1, 1, 0.95, alpha)
		var dir := Vector2.RIGHT.rotated(a)
		var r := r_in
		while r <= r_out:
			_px(center + dir * r, col)
			r += 1.5
