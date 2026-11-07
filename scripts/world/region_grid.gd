extends RefCounted
## 지도 글자 격자. 작은 실내는 글자 줄(MAP)로, 큰 바깥 지역은 그리기 명령(make_grid)으로 만든다.

var w := 0
var h := 0
var rows: Array = []   # Array[Array[String]]


func _init(width := 0, height := 0, fill_c := ".") -> void:
	w = width
	h = height
	rows = []
	for y in h:
		var row := []
		row.resize(w)
		row.fill(fill_c)
		rows.append(row)


## 글자 줄 배열로 격자를 채운다. 줄 길이가 다르면 경고하고 빈칸(" ")으로 채운다.
func load_rows(lines: Array) -> void:
	var width := 0
	for line: String in lines:
		width = maxi(width, line.length())
	_init(width, lines.size(), " ")
	for y in lines.size():
		var line: String = lines[y]
		if line.length() != width:
			push_warning("지도 %d번째 줄 길이 %d (최대 %d)" % [y, line.length(), width])
		for x in line.length():
			rows[y][x] = line[x]


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func get_c(x: int, y: int) -> String:
	return rows[y][x] if in_bounds(x, y) else " "


func set_c(c: String, x: int, y: int) -> void:
	if in_bounds(x, y):
		rows[y][x] = c


func rect(c: String, x: int, y: int, rw: int, rh: int) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			set_c(c, xx, yy)


## 지붕 roof_h줄 + 정면 벽 1줄. 문 자리에 door_c (출구 숫자나 "D").
func building(x: int, y: int, bw: int, roof_h: int, door_x: int, door_c: String) -> void:
	rect("R", x, y, bw, roof_h)
	rect("W", x, y + roof_h, bw, 1)
	set_c(door_c, door_x, y + roof_h)


func dump() -> String:
	var out := PackedStringArray()
	for row in rows:
		out.append("".join(PackedStringArray(row)))
	return "\n".join(out)
