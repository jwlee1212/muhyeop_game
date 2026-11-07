extends RefCounted
## 다리 밑 뒷골목. 원작 1화에서 서진이 죽는 곳. Q3 지형 파악, Q4 황가 일당 전투의 무대.
## M3: 황가(H)와 패거리(E) 둘. M4에서 Q4 이벤트로 등장하도록 바뀐다.

const Grid := preload("res://scripts/world/region_grid.gd")

const NAME := "다리 밑 뒷골목"
const FLOOR := ";"
const EXITS := {
	"1": {"to": "village", "entry": "e", "floor": "^"},
}


static func make_grid() -> Grid:
	var g := Grid.new(32, 18, ";")
	g.rect("S", 0, 0, 32, 1)          # 위 돌담
	g.rect("S", 0, 17, 32, 1)         # 아래 돌담
	g.rect("S", 0, 0, 1, 18)
	g.rect("S", 31, 0, 1, 18)
	g.rect("~", 1, 1, 30, 2)          # 다리 밑을 흐르는 강
	g.rect("\"", 1, 3, 30, 1)         # 강둑
	g.rect("S", 10, 1, 2, 3)          # 다리 기둥
	g.rect("S", 20, 1, 2, 3)
	g.rect("1", 1, 5, 1, 2)           # 마을로 올라가는 계단
	g.set_c("c", 3, 6)
	g.rect("S", 16, 9, 2, 3)          # 무너진 담
	for p in [Vector2i(8, 9), Vector2i(9, 9), Vector2i(14, 12), Vector2i(15, 6), Vector2i(18, 14), Vector2i(5, 13), Vector2i(26, 15)]:
		g.set_c("x", p.x, p.y)
	for p in [Vector2i(12, 8), Vector2i(27, 6), Vector2i(6, 13), Vector2i(23, 5)]:
		g.set_c("b", p.x, p.y)
	g.set_c("H", 25, 11)
	g.set_c("E", 23, 9)
	g.set_c("E", 23, 14)
	return g
