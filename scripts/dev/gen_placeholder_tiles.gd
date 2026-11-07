extends SceneTree
## 임시 타일셋 PNG 생성기 (16x16, 8열).
## 실행: Godot --headless --path . --script res://scripts/dev/gen_placeholder_tiles.gd
## M5에서 SpriteCook 타일셋으로 교체할 때 같은 아틀라스 좌표에 맞춰 그리면 코드는 그대로 쓴다.
## 좌표 목록은 scripts/world/tiles.gd 의 LEGEND 참고.

const OUT := "res://assets/tiles/placeholder_tiles.png"

var img: Image
var ox := 0
var oy := 0
var rng := RandomNumberGenerator.new()


func _init() -> void:
	img = Image.create_empty(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_paint_all()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("saved ", OUT, " err=", err)
	quit()


func at(col: int, row: int) -> void:
	ox = col * 16
	oy = row * 16
	rng.seed = col * 31 + row * 977 + 5


func r(x: int, y: int, w: int, h: int, c: String) -> void:
	img.fill_rect(Rect2i(ox + x, oy + y, w, h), Color(c))


func px(x: int, y: int, c: String) -> void:
	img.set_pixel(ox + x, oy + y, Color(c))


func speckle(c: String, n: int, h := 1) -> void:
	for i in n:
		r(rng.randi_range(0, 15), rng.randi_range(0, 16 - h), 1, h, c)


func _paint_all() -> void:
	# ── 0행: 바닥 (통과 가능)
	at(0, 0); r(0, 0, 16, 16, "#4a7a3a"); speckle("#3a6430", 8, 2); speckle("#6a9a48", 5, 2)          # 풀
	at(1, 0); r(0, 0, 16, 16, "#467536"); speckle("#3a6430", 7, 2); speckle("#6a9a48", 4, 2); px(9, 6, "#e8d870")  # 풀2
	at(2, 0); r(0, 0, 16, 16, "#9a7a52"); speckle("#846848", 10); speckle("#b09060", 5)              # 흙길
	at(3, 0)                                                                                          # 돌길
	r(0, 0, 16, 16, "#8a8680")
	r(0, 7, 16, 1, "#6e6a66"); r(0, 15, 16, 1, "#6e6a66"); r(7, 0, 1, 7, "#6e6a66"); r(3, 8, 1, 7, "#6e6a66"); r(12, 8, 1, 7, "#6e6a66")
	r(1, 1, 5, 1, "#a8a49c"); r(9, 1, 5, 1, "#a8a49c"); r(5, 9, 6, 1, "#a8a49c")
	at(4, 0); r(0, 0, 16, 16, "#8a5e3a")                                                              # 나무 바닥
	for y in [3, 7, 11, 15]:
		r(0, y, 16, 1, "#6e4a2c")
	r(5, 0, 1, 3, "#6e4a2c"); r(11, 4, 1, 3, "#6e4a2c"); r(3, 8, 1, 3, "#6e4a2c"); r(13, 12, 1, 3, "#6e4a2c")
	at(5, 0); r(0, 0, 16, 16, "#4e463e"); speckle("#3e3832", 12); speckle("#5e564c", 6)             # 뒷골목 흙
	at(6, 0); r(0, 0, 16, 16, "#6e6448"); speckle("#5a523a", 10); speckle("#7e7458", 6)             # 강둑
	at(7, 0); _bridge_planks()                                                                        # 다리 판자

	# ── 1행: 구조물 (대부분 막힘)
	at(0, 1); r(0, 0, 16, 16, "#2f6a9a"); speckle("#24547c", 10)                                     # 물
	for i in 4:
		r(rng.randi_range(0, 12), rng.randi_range(0, 15), 3, 1, "#5a9ac8")
	at(1, 1)                                                                                          # 건물 벽(정면)
	r(0, 0, 16, 16, "#d8ccb0"); r(0, 0, 16, 2, "#5a3a24"); r(0, 0, 1, 16, "#5a3a24"); r(15, 0, 1, 16, "#5a3a24")
	r(0, 12, 16, 4, "#8a7a60"); r(0, 12, 16, 1, "#6e604a"); r(4, 4, 8, 5, "#5a3a24"); r(5, 5, 6, 3, "#2a2420")
	at(2, 1); r(0, 0, 16, 16, "#4a4e5a")                                                              # 기와 지붕
	for row in 4:
		r(0, row * 4 + 3, 16, 1, "#34373f")
		for k in 4:
			r(k * 4 + (row % 2) * 2, row * 4, 1, 3, "#5e6370")
	at(3, 1); r(0, 0, 16, 16, "#6e4a2e"); r(0, 0, 16, 2, "#8a5e3a")                                   # 실내 벽
	for x in [3, 7, 11, 15]:
		r(x, 2, 1, 14, "#54381f")
	at(4, 1)                                                                                          # 울타리 (투명 배경)
	r(2, 3, 2, 12, "#7a5a3a"); r(12, 3, 2, 12, "#7a5a3a"); r(0, 6, 16, 1, "#8a6a44"); r(0, 10, 16, 1, "#8a6a44")
	at(5, 1); r(0, 0, 16, 16, "#6e6e76")                                                              # 돌담
	for row in 4:
		r(0, row * 4 + 3, 16, 1, "#55555c")
		var off := (row % 2) * 4
		r(off + 3, row * 4, 1, 3, "#55555c"); r(off + 11, row * 4, 1, 3, "#55555c")
		r(off, row * 4, 3, 1, "#85858e")
	at(6, 1)                                                                                          # 문 (통과 가능)
	r(0, 0, 16, 16, "#d8ccb0"); r(2, 1, 12, 15, "#5a3a24"); r(3, 2, 10, 14, "#4a2e1c"); r(7, 2, 1, 14, "#3a2416")
	px(10, 9, "#c8a040"); px(5, 9, "#c8a040")
	at(7, 1); r(0, 0, 16, 16, "#7a766e")                                                              # 계단 (통과 가능)
	for y in [1, 5, 9, 13]:
		r(0, y, 16, 1, "#9a968e"); r(0, y + 2, 16, 1, "#5a5650")

	# ── 2행: 소품 (투명 배경, 막힘)
	at(0, 2)                                                                                          # 술통
	r(3, 3, 10, 12, "#7a4a2a"); r(4, 2, 8, 2, "#9a6a3a"); r(3, 5, 10, 1, "#3a2a1a"); r(3, 11, 10, 1, "#3a2a1a"); r(4, 6, 1, 5, "#9a6a3a")
	at(1, 2)                                                                                          # 나무 상자
	r(2, 2, 12, 12, "#6e5030"); r(3, 3, 10, 10, "#b08a50")
	for i in 10:
		px(3 + i, 3 + i, "#6e5030"); px(12 - i, 3 + i, "#6e5030")
	at(2, 2); r(1, 4, 14, 7, "#8a5a34"); r(1, 4, 14, 1, "#a06c40"); r(2, 11, 2, 3, "#5a3a20"); r(12, 11, 2, 3, "#5a3a20")  # 탁자
	at(3, 2); r(0, 2, 16, 12, "#8a7438"); r(1, 3, 14, 10, "#c8b060")                                  # 짚 침상
	for i in 10:
		r(rng.randi_range(1, 13), rng.randi_range(3, 12), 2, 1, "#a89040")
	at(4, 2); r(1, 3, 14, 12, "#7a7a82"); r(1, 3, 14, 1, "#9a9aa2"); r(4, 6, 8, 6, "#1e3a5a"); r(5, 7, 3, 1, "#3a6a9a")  # 우물
	at(5, 2); r(2, 6, 12, 9, "#6e6e78"); r(4, 5, 8, 1, "#6e6e78"); r(4, 6, 7, 2, "#8a8a94"); r(2, 13, 12, 2, "#4e4e56")  # 바위
	at(6, 2); r(4, 8, 8, 5, "#8a5a34"); r(5, 13, 6, 1, "#5a3a20"); r(5, 8, 6, 2, "#5a9ac8"); px(6, 8, "#c4ecff")  # 물그릇
	at(7, 2); r(6, 1, 4, 15, "#8a5e3a"); r(6, 1, 1, 15, "#a07048"); r(2, 5, 12, 2, "#6e4a2c"); r(3, 10, 10, 2, "#6e4a2c")  # 목인장

	# ── 3행
	at(0, 3)                                                                                          # 의뢰 게시판
	r(3, 9, 2, 7, "#5a3a24"); r(11, 9, 2, 7, "#5a3a24"); r(1, 1, 14, 10, "#8a5e3a"); r(1, 1, 14, 1, "#a07048")
	r(3, 3, 4, 5, "#e8e0c8"); r(8, 2, 5, 4, "#e8e0c8"); r(9, 7, 3, 3, "#d8c8a0")
	at(1, 3)                                                                                          # 병기 걸이
	r(1, 4, 14, 2, "#6e4a2c"); r(1, 11, 14, 2, "#6e4a2c"); r(1, 4, 2, 10, "#6e4a2c"); r(13, 4, 2, 10, "#6e4a2c")
	for x in [5, 8, 11]:
		r(x, 1, 1, 12, "#b8c0c8"); r(x, 1, 1, 1, "#ffffff")
	at(2, 3); _bridge_planks(); r(0, 4, 16, 3, "#6e4e30"); r(0, 4, 16, 1, "#8a6a44"); r(0, 2, 2, 11, "#5a3e24"); r(14, 2, 2, 11, "#5a3e24")  # 다리 난간


func _bridge_planks() -> void:
	r(0, 0, 16, 16, "#9a7048")
	for x in [3, 7, 11, 15]:
		r(x, 0, 1, 16, "#6e4e30")
	for x in [1, 5, 9, 13]:
		px(x, 2, "#4a3420"); px(x, 13, "#4a3420")
