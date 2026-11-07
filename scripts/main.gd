extends Node2D
## 1단계 테스트 씬: 바닥 + 장애물 + 주인공 + 산적 3명(쓰러지면 재등장) + 카메라 + HUD.

const Ground := preload("res://scripts/ground.gd")
const Obstacle := preload("res://scripts/obstacle.gd")
const Player := preload("res://scripts/player.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Hud := preload("res://scripts/hud.gd")

const ENEMY_COUNT := 3

var world: Node2D
var player: Player
var ground: Ground
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 7
	ground = Ground.new()
	add_child(ground)
	var size := Vector2(ground.tiles * Ground.TILE)

	world = Node2D.new()
	world.y_sort_enabled = true
	world.add_to_group("fx_layer")
	add_child(world)

	_build_walls(size)
	_scatter_obstacles(size)

	player = Player.new()
	player.position = size * 0.5
	world.add_child(player)
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = int(size.x)
	player.camera.limit_bottom = int(size.y)

	for i in ENEMY_COUNT:
		_spawn_enemy()

	var hud := Hud.new()
	hud.player = player
	add_child(hud)


func _build_walls(size: Vector2) -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	var t := 16.0
	var rects := [
		Rect2(-t, -t, size.x + t * 2, t), Rect2(-t, size.y, size.x + t * 2, t),
		Rect2(-t, 0, t, size.y), Rect2(size.x, 0, t, size.y),
	]
	for r: Rect2 in rects:
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = r.get_center()
		walls.add_child(cs)
	add_child(walls)


func _scatter_obstacles(size: Vector2) -> void:
	var center := size * 0.5
	var placed := 0
	var tries := 0
	while placed < 40 and tries < 400:
		tries += 1
		var p := Vector2(rng.randf_range(24, size.x - 24), rng.randf_range(40, size.y - 16)).round()
		if p.distance_to(center) < 70:
			continue
		var tx := int(p.x / Ground.TILE)
		var ty := int(p.y / Ground.TILE)
		if ground.is_path(tx, ty) or ground.is_path(tx, ty - 1):
			continue
		var o := Obstacle.new()
		o.kind = "rock" if rng.randf() < 0.3 else "tree"
		o.position = p
		world.add_child(o)
		placed += 1


func _spawn_enemy() -> void:
	var size := Vector2(ground.tiles * Ground.TILE)
	var p := Vector2.ZERO
	for i in 30:
		p = Vector2(rng.randf_range(40, size.x - 40), rng.randf_range(40, size.y - 40))
		if p.distance_to(player.global_position) > 160:
			break
	var e := Enemy.new()
	e.position = p
	e.died.connect(_on_enemy_died)
	world.add_child(e)


func _on_enemy_died(_e) -> void:
	await get_tree().create_timer(3.0).timeout
	_spawn_enemy()
