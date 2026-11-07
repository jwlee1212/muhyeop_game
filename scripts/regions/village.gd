extends RefCounted
## 돌다리 마을 바깥. 객잔 앞, 큰길, 무관 앞, 돌다리, 뒷골목으로 내려가는 계단.

const Grid := preload("res://scripts/world/region_grid.gd")

const NAME := "돌다리 마을"
const FLOOR := "."
const EXITS := {
	"1": {"to": "inn", "entry": "a", "floor": "D"},
	"2": {"to": "dojo", "entry": "a", "floor": "D"},
	"3": {"to": "alley", "entry": "c", "floor": "^"},
}

const TREES := [
	Vector2i(1, 2), Vector2i(2, 10), Vector2i(1, 17), Vector2i(2, 24), Vector2i(1, 30),
	Vector2i(20, 2), Vector2i(23, 4), Vector2i(45, 3), Vector2i(47, 6), Vector2i(44, 10),
	Vector2i(46, 23), Vector2i(30, 29), Vector2i(16, 30), Vector2i(9, 31), Vector2i(25, 32),
	Vector2i(38, 31), Vector2i(43, 28), Vector2i(56, 2), Vector2i(58, 7), Vector2i(56, 11),
	Vector2i(57, 19), Vector2i(55, 24), Vector2i(58, 28), Vector2i(56, 32), Vector2i(12, 18),
	Vector2i(28, 18), Vector2i(40, 18), Vector2i(18, 28), Vector2i(31, 25),
]


static func make_grid() -> Grid:
	var g := Grid.new(60, 34, ".")
	# 강과 돌다리 (동쪽)
	g.rect("\"", 49, 0, 1, 34)
	g.rect("~", 50, 0, 4, 34)
	g.rect("\"", 54, 0, 1, 34)
	g.rect("=", 0, 13, 50, 3)         # 큰길
	g.rect("=", 54, 13, 6, 3)
	g.rect("-", 50, 13, 4, 3)         # 다리
	g.rect("L", 50, 12, 4, 1)         # 난간
	g.rect("L", 50, 16, 4, 1)
	# 객잔 (서쪽)
	g.building(4, 3, 14, 5, 10, "1")
	g.rect("=", 9, 9, 3, 4)           # 객잔 앞 마당길
	g.set_c("c", 10, 9)
	g.set_c("w", 6, 10)
	g.set_c("b", 15, 9)
	g.set_c("b", 16, 9)
	g.set_c("x", 17, 10)
	g.set_c("n", 21, 10)              # 의뢰 게시판
	g.set_c("Y", 22, 11)              # 엽 노인 (Q5 전에는 숨김 예정)
	# 무관
	g.building(27, 2, 16, 6, 34, "2")
	g.rect(":", 33, 9, 3, 4)          # 무관 마당 돌길
	g.set_c("d", 34, 9)
	g.rect("F", 26, 11, 7, 1)
	g.rect("F", 36, 11, 8, 1)
	g.rect("F", 26, 9, 1, 2)
	g.rect("F", 43, 9, 1, 2)
	g.set_c("u", 29, 10)
	g.set_c("u", 40, 10)
	# 뒷골목으로 내려가는 길
	g.rect("=", 46, 16, 2, 4)
	g.rect("3", 48, 18, 1, 2)
	g.set_c("e", 46, 18)
	# 남쪽 민가
	g.building(6, 21, 8, 4, 9, "D")
	g.building(20, 22, 8, 3, 23, "D")
	g.building(34, 21, 8, 4, 37, "D")
	for p: Vector2i in TREES:
		g.set_c("T", p.x, p.y)
	g.set_c("r", 24, 19)
	g.set_c("r", 44, 20)
	g.set_c("r", 5, 28)
	return g
