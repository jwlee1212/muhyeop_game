extends Node2D
## 적 공격 예고(바닥의 빨간 범위). progress 0→1로 안쪽이 차오르며, 1이 되는 순간 공격이 나간다.

var shape := "circle"     # "circle" | "arc" | "line"
var radius := 30.0
var arc := PI * 0.75      # arc 전체 각도
var length := 80.0        # line 길이
var width := 12.0         # line 반폭
var progress := 0.0

const EDGE := Color(1.0, 0.2, 0.15, 0.55)
const FILL := Color(1.0, 0.2, 0.15, 0.16)
const CORE := Color(1.0, 0.35, 0.25, 0.30)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var p := clampf(progress, 0.0, 1.0)
	match shape:
		"circle":
			draw_circle(Vector2.ZERO, radius, FILL)
			draw_circle(Vector2.ZERO, radius * p, CORE)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 32, EDGE, 1.0)
		"arc":
			_fan(radius, FILL)
			_fan(radius * p, CORE)
			draw_arc(Vector2.ZERO, radius, -arc * 0.5, arc * 0.5, 16, EDGE, 1.0)
		"line":
			draw_rect(Rect2(0, -width, length, width * 2), FILL)
			draw_rect(Rect2(0, -width, length * p, width * 2), CORE)
			draw_rect(Rect2(0, -width, length, width * 2), EDGE, false, 1.0)


func _fan(r: float, col: Color) -> void:
	if r < 1.0:
		return
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		pts.append(Vector2.RIGHT.rotated(-arc * 0.5 + arc * i / 12.0) * r)
	draw_colored_polygon(pts, col)
