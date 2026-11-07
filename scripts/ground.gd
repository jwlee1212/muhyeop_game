extends Node2D
## 임시 바닥 (16x16 타일 격자). 2단계에서 TileMapLayer + SpriteCook 타일셋으로 교체.

const TILE := 16
var tiles := Vector2i(60, 34)

const GRASS := [Color("4a7a3a"), Color("467536"), Color("4e803e")]
const GRASS_DARK := Color("3a6430")
const TUFT := Color("6a9a48")
const DIRT := Color("9a7a52")
const DIRT_DARK := Color("846848")
const FLOWER := [Color("e8d870"), Color("e88aa0"), Color("f0f0e8")]


func _hash(x: int, y: int) -> int:
	var h := x * 374761393 + y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


func is_path(tx: int, ty: int) -> bool:
	# 가로 길 + 세로 길 (마을 앞 갈림길 느낌)
	var py := 17 + int(round(sin(tx * 0.18) * 2.0))
	var px := 30 + int(round(sin(ty * 0.25) * 1.5))
	return absi(ty - py) <= 1 or absi(tx - px) <= 1


func _draw() -> void:
	for ty in tiles.y:
		for tx in tiles.x:
			var h := _hash(tx, ty)
			var pos := Vector2(tx * TILE, ty * TILE)
			if is_path(tx, ty):
				draw_rect(Rect2(pos, Vector2(TILE, TILE)), DIRT)
				for i in 3:
					var hh := _hash(tx * 7 + i, ty * 13)
					draw_rect(Rect2(pos + Vector2(hh % 15, (hh >> 4) % 15), Vector2(1, 1)), DIRT_DARK)
				continue
			draw_rect(Rect2(pos, Vector2(TILE, TILE)), GRASS[h % 3])
			# 풀 디테일
			for i in 2 + h % 3:
				var hh := _hash(tx * 31 + i, ty * 17 + i)
				var p := pos + Vector2(hh % 14 + 1, (hh >> 5) % 13 + 2)
				draw_rect(Rect2(p, Vector2(1, 2)), GRASS_DARK if i % 2 == 0 else TUFT)
			if h % 23 == 0:
				var f: Color = FLOWER[(h >> 3) % 3]
				var fp := pos + Vector2(6 + h % 5, 5 + (h >> 2) % 6)
				draw_rect(Rect2(fp, Vector2(1, 1)), f)
				draw_rect(Rect2(fp + Vector2(2, 1), Vector2(1, 1)), f)
	# 지역 경계(어두운 테두리)
	var size := Vector2(tiles * TILE)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35), false, 4.0)
