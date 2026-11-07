extends RefCounted
## 지도 글자 → 타일 대응표와 TileSet 생성.
## 타일 이미지는 assets/tiles/placeholder_tiles.png (scripts/dev/gen_placeholder_tiles.gd 로 생성).
##
## 종류
##   floor : 바닥 레이어, 통과 가능
##   solid : 바닥 레이어, 막힘 (물·벽·지붕)
##   decor : 소품 레이어(투명 배경), 막힘. 밑에는 지역의 기본 바닥(FLOOR)이 깔린다
##
## 표시 글자 (타일이 아님)
##   1~9   출구. 지역 EXITS에 {to, entry, floor} 정의
##   a c d e f g  진입 지점 (다른 지역에서 들어올 때 서는 곳)
##   O M Y  NPC (옥분, 마 사범, 엽 노인)
##   E     적 (황가 일당 자리 표시)
##   T     나무 (y정렬 장애물 노드)

const ATLAS_PATH := "res://assets/tiles/placeholder_tiles.png"
const TILE := 16

const LEGEND := {
	".": [Vector2i(0, 0), "floor"],   # 풀
	"=": [Vector2i(2, 0), "floor"],   # 흙길
	":": [Vector2i(3, 0), "floor"],   # 돌길
	"_": [Vector2i(4, 0), "floor"],   # 나무 바닥
	";": [Vector2i(5, 0), "floor"],   # 뒷골목 흙
	"\"": [Vector2i(6, 0), "floor"],  # 강둑
	"-": [Vector2i(7, 0), "floor"],   # 다리 판자
	"~": [Vector2i(0, 1), "solid"],   # 물
	"W": [Vector2i(1, 1), "solid"],   # 건물 벽(정면)
	"R": [Vector2i(2, 1), "solid"],   # 기와 지붕
	"I": [Vector2i(3, 1), "solid"],   # 실내 벽
	"F": [Vector2i(4, 1), "decor"],   # 울타리
	"S": [Vector2i(5, 1), "solid"],   # 돌담
	"D": [Vector2i(6, 1), "floor"],   # 문
	"^": [Vector2i(7, 1), "floor"],   # 계단
	"b": [Vector2i(0, 2), "decor"],   # 술통
	"x": [Vector2i(1, 2), "decor"],   # 나무 상자
	"t": [Vector2i(2, 2), "decor"],   # 탁자
	"k": [Vector2i(3, 2), "decor"],   # 짚 침상
	"w": [Vector2i(4, 2), "decor"],   # 우물
	"r": [Vector2i(5, 2), "decor"],   # 바위
	"p": [Vector2i(6, 2), "decor"],   # 물그릇 (Q0)
	"u": [Vector2i(7, 2), "decor"],   # 목인장
	"n": [Vector2i(0, 3), "decor"],   # 의뢰 게시판
	"v": [Vector2i(1, 3), "decor"],   # 병기 걸이
	"L": [Vector2i(2, 3), "solid"],   # 다리 난간
}
const GRASS_ALT := Vector2i(1, 0)
const ENTRY_CHARS := ["a", "c", "d", "e", "f", "g"]
const NPC_CHARS := {"O": "okbun", "M": "ma", "Y": "yeop"}

static var _tileset: TileSet


static func kind(c: String) -> String:
	return LEGEND[c][1] if LEGEND.has(c) else ""


static func is_solid(c: String) -> bool:
	var k := kind(c)
	return k == "solid" or k == "decor"


static func get_tileset() -> TileSet:
	if _tileset:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load(ATLAS_PATH)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var square := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var coords_done := {}
	for c in LEGEND:
		var coords: Vector2i = LEGEND[c][0]
		if not coords_done.has(coords):
			src.create_tile(coords)
			coords_done[coords] = true
		if is_solid(c):
			var td := src.get_tile_data(coords, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, square)
	src.create_tile(GRASS_ALT)
	_tileset = ts
	return ts
