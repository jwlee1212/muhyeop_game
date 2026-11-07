extends RefCounted
## 다리 밑 뒷골목. 원작 1화에서 서진이 죽는 곳. Q3 지형 파악, Q4 황가 일당 전투의 무대.
## 황가 일당은 지도에 두지 않고 Q4 이벤트에서 SPAWNS 자리에 나타난다 (story.gd).

const Grid := preload("res://scripts/world/region_grid.gd")

const NAME := "다리 밑 뒷골목"
const FLOOR := ";"
## Q4: 계단 쪽에서 내려와 주인공을 골목 안쪽으로 몰아넣는다
const SPAWNS := {"hwang": Vector2i(5, 9), "thug_a": Vector2i(4, 6), "thug_b": Vector2i(6, 12)}
## Q3: 이 칸보다 안쪽(오른쪽)까지 들어가면 지형 파악 완료
const SCOUT_X := 18
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
	return g
