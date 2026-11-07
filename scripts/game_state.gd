extends Node
## 진행 상태 (autoload "Game"): 퀘스트·플래그·시진 시계·소지품·기억 속 컷, 저장/불러오기, 폰트.

signal changed

const SAVE_PATH := "user://save.json"
const AUTOSAVE_PATH := "user://autosave.json"
const FONT_MAIN_PATH := "res://assets/fonts/Galmuri11.ttf"   # 12px에서 선명
const FONT_SMALL_PATH := "res://assets/fonts/Galmuri9.ttf"   # 10px에서 선명
const MAIN_SIZE := 12
const SMALL_SIZE := 10

## 시진 시계: 신시(申時) 초 = 0각 … 8각 = 유시(酉時), 원작에서 서진이 죽는 때
const KAK_END := 8

const ITEMS := {
	"wine": {"name": "술 한 병", "desc": "옥분이 무관의 마 사범에게 갖다 드리라고 준 술."},
	"wooden_sword": {"name": "연습용 목검", "desc": "마 사범이 빌려준 목검. 손때가 묻어 있다."},
}

var flags := {}
var quest := ""             # q0 ~ q5, done
var objective := ""         # HUD에 띄우는 목표
var kak := 0
var inventory: Array = []
var memory_unlocked := false

var font_main: FontFile
var font_small: FontFile


func _ready() -> void:
	font_main = _pixel_font(FONT_MAIN_PATH)
	font_small = _pixel_font(FONT_SMALL_PATH)
	var theme := Theme.new()
	theme.default_font = font_main
	theme.default_font_size = MAIN_SIZE
	get_tree().root.theme = theme


func _pixel_font(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f


func reset() -> void:
	flags = {}
	quest = ""
	objective = ""
	kak = 0
	inventory = []
	memory_unlocked = false
	changed.emit()


# ───────────── 퀘스트·플래그·시계 ─────────────

func set_quest(id: String, objective_text: String, kak_to := -1) -> void:
	quest = id
	objective = objective_text
	if kak_to >= 0:
		kak = kak_to
	changed.emit()


func set_objective(text: String) -> void:
	objective = text
	changed.emit()


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	changed.emit()


func flag(key: String) -> bool:
	return bool(flags.get(key, false))


func clock_text() -> String:
	if kak >= KAK_END:
		return "유시(酉時)"
	return "신시(申時) %d각" % kak


# ───────────── 소지품 ─────────────

func add_item(id: String) -> void:
	if not id in inventory:
		inventory.append(id)
		changed.emit()


func remove_item(id: String) -> void:
	inventory.erase(id)
	changed.emit()


func has_item(id: String) -> bool:
	return id in inventory


# ───────────── 저장 ─────────────

## main(게임 루트)에서 지금 상태를 사전으로 뽑는다.
func snapshot(main: Node) -> Dictionary:
	var p = main.player
	return {
		"version": 1,
		"region": main.region.region_id,
		"pos": [p.global_position.x, p.global_position.y],
		"hp": p.hp, "qi": p.qi,
		"weapon": p.weapon_id,
		"known": p.known_techniques.duplicate(),
		"flags": flags.duplicate(true),
		"quest": quest, "objective": objective, "kak": kak,
		"inventory": inventory.duplicate(),
		"memory": memory_unlocked,
	}


## 게임 상태만 되돌린다. 지역 이동·플레이어 배치는 main.load_game()이 한다.
func restore(data: Dictionary) -> void:
	flags = data.get("flags", {})
	quest = data.get("quest", "")
	objective = data.get("objective", "")
	kak = int(data.get("kak", 0))
	inventory = data.get("inventory", [])
	memory_unlocked = bool(data.get("memory", false))
	changed.emit()


func write(path: String, data: Dictionary) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("저장 실패: " + path)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
