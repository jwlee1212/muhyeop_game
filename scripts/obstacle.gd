extends StaticBody2D
## 나무 / 바위 장애물 (원점 = 밑동, Y정렬용).

@export_enum("tree", "rock") var kind := "tree"


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	if kind == "tree":
		var c := CircleShape2D.new()
		c.radius = 5
		cs.shape = c
	else:
		var r := RectangleShape2D.new()
		r.size = Vector2(14, 7)
		cs.shape = r
		cs.position = Vector2(0, -3)
	add_child(cs)


func _draw() -> void:
	draw_rect(Rect2(-9, -3, 18, 4), Color(0, 0, 0, 0.28))
	if kind == "tree":
		draw_rect(Rect2(-2, -12, 4, 12), Color("5a3a24"))
		draw_rect(Rect2(-2, -12, 1, 12), Color("6e4a2e"))
		var dark := Color("2c5a2a")
		var mid := Color("3a7234")
		var light := Color("58903e")
		draw_rect(Rect2(-11, -30, 22, 16), dark)
		draw_rect(Rect2(-8, -34, 16, 4), dark)
		draw_rect(Rect2(-13, -26, 26, 8), dark)
		draw_rect(Rect2(-9, -32, 16, 14), mid)
		draw_rect(Rect2(-11, -26, 20, 6), mid)
		draw_rect(Rect2(-6, -31, 6, 4), light)
		draw_rect(Rect2(-9, -25, 4, 3), light)
	else:
		draw_rect(Rect2(-8, -9, 16, 9), Color("5a5a62"))
		draw_rect(Rect2(-6, -11, 11, 3), Color("6e6e78"))
		draw_rect(Rect2(-5, -9, 6, 2), Color("8a8a94"))
		draw_rect(Rect2(-8, -2, 16, 2), Color("44444c"))
