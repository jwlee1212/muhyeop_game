extends Node2D
## 지역 하나. 지역 정의 스크립트(scripts/regions/*.gd)를 읽어 타일맵·출구·NPC·적·길찾기 격자를 만든다.
##
## 지역 정의 스크립트의 상수
##   NAME   화면에 띄울 지역 이름
##   FLOOR  소품·표시 글자 밑에 깔 기본 바닥 글자 (기본 ".")
##   EXITS  {"1": {"to": 지역 id, "entry": 진입 글자, "floor": 출구 칸의 바닥 글자}}
##   MAP    글자 줄 배열  (또는 static func make_grid() 로 격자를 직접 그림)

signal exit_requested(to: String, entry: String)

const Tiles := preload("res://scripts/world/tiles.gd")
const Grid := preload("res://scripts/world/region_grid.gd")
const Npc := preload("res://scripts/world/npc.gd")
const Obstacle := preload("res://scripts/obstacle.gd")
const Enemy := preload("res://scripts/enemy.gd")

const TILE := Tiles.TILE
const VIEW := Vector2i(480, 270)

var region_id := ""
var region_name := ""
var grid: Grid
var floor_layer: TileMapLayer
var decor_layer: TileMapLayer
var ground_fx: Node2D             # 바닥 위·캐릭터 아래 (적 공격 예고)
var world: Node2D                 # y정렬. 캐릭터·나무·이펙트가 여기 들어간다
var astar := AStarGrid2D.new()
var entries := {}                 # 진입 글자 → 발 위치


func build(id: String, def: GDScript) -> void:
	region_id = id
	var consts := def.get_script_constant_map()
	region_name = consts.get("NAME", id)
	var base_floor: String = consts.get("FLOOR", ".")
	var exits: Dictionary = consts.get("EXITS", {})
	if consts.has("MAP"):
		grid = Grid.new()
		grid.load_rows(consts.MAP)
	else:
		grid = def.make_grid()

	var ts := Tiles.get_tileset()
	floor_layer = TileMapLayer.new()
	floor_layer.tile_set = ts
	add_child(floor_layer)
	decor_layer = TileMapLayer.new()
	decor_layer.tile_set = ts
	add_child(decor_layer)
	ground_fx = Node2D.new()
	add_child(ground_fx)
	world = Node2D.new()
	world.y_sort_enabled = true
	world.add_to_group("fx_layer")
	add_child(world)

	astar.region = Rect2i(0, 0, grid.w, grid.h)
	astar.cell_size = Vector2(TILE, TILE)
	astar.offset = Vector2(TILE, TILE) * 0.5
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	var exit_areas := {}
	for y in grid.h:
		for x in grid.w:
			_build_cell(x, y, grid.get_c(x, y), base_floor, exits, exit_areas)
	_build_bounds()


func _build_cell(x: int, y: int, c: String, base_floor: String, exits: Dictionary, exit_areas: Dictionary) -> void:
	var cell := Vector2i(x, y)
	var center := Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
	var feet := center + Vector2(0, 4)
	var floor_c := base_floor
	var blocked := false

	if Tiles.LEGEND.has(c):
		if Tiles.kind(c) == "decor":
			_set_tile(decor_layer, cell, c)
			blocked = true
		else:
			floor_c = c
	elif c.is_valid_int():
		var ex: Dictionary = exits.get(c, {})
		if ex.is_empty():
			push_warning("%s: 출구 %s 정의 없음" % [region_id, c])
		floor_c = ex.get("floor", base_floor)
		_add_exit_cell(exit_areas, c, ex, center)
	elif c in Tiles.ENTRY_CHARS:
		entries[c] = feet
	elif c == "T":
		var tree := Obstacle.new()
		tree.kind = "tree"
		tree.position = feet
		world.add_child(tree)
		blocked = true
	elif Tiles.NPC_CHARS.has(c):
		var npc := Npc.new()
		npc.npc_id = Tiles.NPC_CHARS[c]
		npc.position = feet
		world.add_child(npc)
		blocked = true
	elif Tiles.ENEMY_CHARS.has(c):
		var e := Enemy.new()
		e.kind = Tiles.ENEMY_CHARS[c]
		e.region = self
		e.position = feet
		world.add_child(e)
	elif c != " ":
		push_warning("%s: 모르는 지도 글자 '%s' (%d,%d)" % [region_id, c, x, y])

	_set_tile(floor_layer, cell, floor_c)
	if blocked or Tiles.is_solid(floor_c):
		astar.set_point_solid(cell, true)


func _set_tile(layer: TileMapLayer, cell: Vector2i, c: String) -> void:
	if not Tiles.LEGEND.has(c):
		return
	var coords: Vector2i = Tiles.LEGEND[c][0]
	if c == "." and (cell.x * 7 + cell.y * 13) % 5 == 0:
		coords = Tiles.GRASS_ALT
	layer.set_cell(cell, 0, coords)


func _add_exit_cell(exit_areas: Dictionary, c: String, ex: Dictionary, center: Vector2) -> void:
	if not exit_areas.has(c):
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2   # 플레이어
		area.monitorable = false
		area.body_entered.connect(_on_exit_body_entered.bind(ex))
		add_child(area)
		exit_areas[c] = area
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE - 2, TILE - 2)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = center
	exit_areas[c].add_child(cs)


func _on_exit_body_entered(body: Node, ex: Dictionary) -> void:
	if body.is_in_group("player") and ex.has("to"):
		exit_requested.emit(ex.to, ex.get("entry", "a"))


func _build_bounds() -> void:
	var size := pixel_size()
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	var t := 16.0
	for r: Rect2 in [Rect2(-t, -t, size.x + t * 2, t), Rect2(-t, size.y, size.x + t * 2, t),
			Rect2(-t, 0, t, size.y), Rect2(size.x, 0, t, size.y)]:
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = r.get_center()
		walls.add_child(cs)
	add_child(walls)


func pixel_size() -> Vector2:
	return Vector2(grid.w * TILE, grid.h * TILE)


## 카메라 경계. 지역이 화면보다 작으면 가운데 오도록 경계를 화면 크기로 넓힌다.
func camera_limits() -> Rect2i:
	var size := Vector2i(pixel_size())
	var left := 0
	var top := 0
	var right := size.x
	var bottom := size.y
	if size.x < VIEW.x:
		left = (size.x - VIEW.x) / 2
		right = left + VIEW.x
	if size.y < VIEW.y:
		top = (size.y - VIEW.y) / 2
		bottom = top + VIEW.y
	return Rect2i(left, top, right - left, bottom - top)


func entry_position(entry: String) -> Vector2:
	if entries.has(entry):
		return entries[entry]
	push_warning("%s: 진입 지점 '%s' 없음" % [region_id, entry])
	return entries.values()[0] if not entries.is_empty() else pixel_size() * 0.5


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


## 발 위치 기준 길찾기. 막힌 칸에서 시작하거나 끝나면 빈 배열.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := world_to_cell(from)
	var b := world_to_cell(to)
	if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b):
		return PackedVector2Array()
	if astar.is_point_solid(a) or astar.is_point_solid(b):
		return PackedVector2Array()
	return astar.get_point_path(a, b)
