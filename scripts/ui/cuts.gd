extends RefCounted
## 원작 웹툰 《달무리 강호》 1화의 컷 그림 (임시, 도형으로 그림). 기억 메뉴와 연출에서 같이 쓴다.
## M5에서 일러스트로 바뀌면 draw_cut()만 텍스처 그리기로 교체한다.

const INK := Color("1a1614")
const PAPER := Color("f6f2e8")

const CAPTIONS := [
	"객잔에서 일하는 아이",
	"보호비를 내놓으라는 황가 일당",
	"돌다리 기둥 아래, 어두운 골목",
	"해 질 녘, 쓰러진 아이 — 1화 끝",
	"서 있는 아이 — 원작에 없는 컷",
]


## rect 안에 idx번 컷을 그린다. 그림은 100x64 기준으로 설계해 rect 크기에 맞춰 늘린다.
static func draw_cut(ci: CanvasItem, rect: Rect2, idx: int) -> void:
	ci.draw_rect(rect.grow(2), INK)
	ci.draw_rect(rect, PAPER)
	var s := rect.size / Vector2(100, 64)
	var o := rect.position
	var r := func(x: float, y: float, w: float, h: float, c: Color) -> void:
		ci.draw_rect(Rect2((o + Vector2(x, y) * s).round(), (Vector2(w, h) * s).round().max(Vector2.ONE)), c)
	match idx:
		0:  # 객잔 안, 쟁반을 든 아이
			r.call(0, 0, 100, 64, Color("8a5e3a"))
			r.call(0, 0, 100, 18, Color("6e4a2e"))
			r.call(10, 30, 22, 8, Color("a06c40")); r.call(64, 34, 22, 8, Color("a06c40"))
			_kid(r, 46, 26, Color("e8e2d0"))
			r.call(40, 30, 16, 2, Color("c8c0b0"))
		1:  # 아이를 둘러싼 세 그림자
			r.call(0, 0, 100, 64, Color("4e463e"))
			_kid(r, 47, 30, Color("e8e2d0"))
			for x in [24, 66, 45]:
				var y := 20 if x == 45 else 26
				r.call(x, y, 12, 26, Color("2a1e1a")); r.call(x + 2, y - 8, 8, 8, Color("2a1e1a"))
			r.call(45, 12, 12, 2, Color("b02a2a"))
		2:  # 돌다리와 기둥 (Q3 단서)
			r.call(0, 0, 100, 64, Color("3e3832"))
			r.call(0, 0, 100, 14, Color("6e6e76"))
			r.call(0, 14, 100, 6, Color("2f6a9a"))
			r.call(22, 0, 10, 34, Color("5a5a62")); r.call(68, 0, 10, 34, Color("5a5a62"))
			r.call(0, 12, 100, 2, Color("44444c"))
			r.call(40, 44, 8, 6, Color("8a6a44")); r.call(56, 50, 8, 6, Color("8a6a44"))
		3:  # 해 질 녘 쓰러진 아이
			r.call(0, 0, 100, 64, Color("d8783a"))
			r.call(0, 0, 100, 20, Color("e8a050"))
			r.call(0, 40, 100, 24, Color("3e3832"))
			r.call(30, 44, 30, 7, Color("e8e2d0")); r.call(60, 44, 8, 7, Color("f0c8a0")); r.call(60, 43, 8, 3, Color("1e1a22"))
			r.call(40, 52, 14, 2, Color("8a1e1e"))
		4:  # 서 있는 아이와 쓰러진 셋
			r.call(0, 0, 100, 64, Color("3e3832"))
			r.call(0, 0, 100, 14, Color("6e6e76"))
			for x in [16, 64, 78]:
				r.call(x, 50, 16, 6, Color("5a3a26"))
			_kid(r, 46, 22, Color("e8e2d0"))
			r.call(56, 26, 2, 16, Color("d8e0e8"))


static func _kid(r: Callable, x: float, y: float, robe: Color) -> void:
	r.call(x, y + 8, 10, 14, robe)
	r.call(x, y + 13, 10, 2, Color("3a6ea5"))
	r.call(x + 1, y, 8, 8, Color("f0c8a0"))
	r.call(x + 1, y - 1, 8, 3, Color("1e1a22"))
	r.call(x + 1, y + 22, 3, 4, Color("a49c86")); r.call(x + 6, y + 22, 3, 4, Color("a49c86"))
