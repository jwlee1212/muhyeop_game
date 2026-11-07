extends Node2D
## 게임 루트. 타이틀 → 새 게임(오프닝)/이어하기, 지역 전환, 저장·불러오기, UI와 이야기 진행을 묶는다.

const Region := preload("res://scripts/world/region.gd")
const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/hud.gd")
const DialogueBox := preload("res://scripts/ui/dialogue_box.gd")
const Cutscene := preload("res://scripts/ui/cutscene.gd")
const Menu := preload("res://scripts/ui/menu.gd")
const Title := preload("res://scripts/ui/title.gd")
const Story := preload("res://scripts/story/story.gd")

const REGIONS := {
	"shed": preload("res://scripts/regions/shed.gd"),
	"inn": preload("res://scripts/regions/inn.gd"),
	"village": preload("res://scripts/regions/village.gd"),
	"dojo": preload("res://scripts/regions/dojo.gd"),
	"alley": preload("res://scripts/regions/alley.gd"),
}
const START_REGION := "shed"
const START_ENTRY := "a"
const FADE_TIME := 0.25

var region: Region
var player: Player
var hud: Hud
var dialogue: DialogueBox
var cutscene: Cutscene
var menu: Menu
var title: Title
var story: Story
var fade: ColorRect
var transitioning := false
var started := false


func _ready() -> void:
	player = Player.new()
	_build_fade()
	dialogue = DialogueBox.new()
	add_child(dialogue)
	cutscene = Cutscene.new()
	cutscene.dialogue = dialogue
	add_child(cutscene)
	menu = Menu.new()
	menu.main = self
	add_child(menu)
	title = Title.new()
	add_child(title)
	story = Story.new()
	story.main = self
	add_child(story)
	player.interact_requested.connect(story.on_interact)
	player.died.connect(story.on_player_died)

	var pick := await title.choose()
	if pick == "continue":
		await load_game(Game.SAVE_PATH)
	else:
		await new_game()


func _exit_tree() -> void:
	# 타이틀에서 바로 종료하면 주인공 노드가 트리에 붙기 전이라 직접 지운다
	if player and not player.is_inside_tree():
		player.free()


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	fade = ColorRect.new()
	fade.color = Color(0.04, 0.03, 0.03)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	layer.add_child(fade)


func _ensure_hud() -> void:
	if hud == null:
		hud = Hud.new()
		hud.player = player
		add_child(hud)


func new_game() -> void:
	Game.reset()
	player.known_techniques = []
	player.weapon_id = "fist"
	player.hp = player.max_hp
	player.qi = 40.0
	await cutscene.play_opening()
	await change_region(START_REGION, START_ENTRY, false)
	_ensure_hud()
	started = true
	await cutscene.fade_from_black(1.2)
	story.start_new_game()


## 저장 파일을 불러온다. retry = 죽은 뒤 "뒤로가기"로 자동 세이브에서 돌아오는 경우.
func load_game(path: String, retry := false) -> void:
	var data := Game.read(path)
	if data.is_empty():
		push_warning("불러올 기록 없음: " + path)
		if not started:
			await new_game()
		return
	Game.restore(data)
	player.hp = float(data.get("hp", player.max_hp))
	player.qi = float(data.get("qi", 40.0))
	player.weapon_id = data.get("weapon", "fist")
	player.known_techniques = data.get("known", [])
	var pos_arr: Array = data.get("pos", [])
	var pos = Vector2(pos_arr[0], pos_arr[1]) if pos_arr.size() == 2 else null
	await change_region(data.get("region", START_REGION), START_ENTRY, not retry and started, pos)
	player.reset_after_load()
	_ensure_hud()
	started = true
	if retry or cutscene._black > 0.0:
		await cutscene.fade_from_black(0.6)


func save_game() -> bool:
	return Game.write(Game.SAVE_PATH, Game.snapshot(self))


func autosave() -> void:
	Game.write(Game.AUTOSAVE_PATH, Game.snapshot(self))


func can_open_menu() -> bool:
	return started and hud != null and not transitioning and not dialogue.is_active() \
		and cutscene._mode == "" and not story._busy and player.state != Player.State.DEAD


func change_region(id: String, entry: String, with_fade := true, pos = null) -> void:
	if transitioning or not REGIONS.has(id):
		if not REGIONS.has(id):
			push_warning("없는 지역: " + id)
		return
	transitioning = true
	player.frozen = true
	if with_fade:
		await _fade_to(1.0)

	if region:
		if player.get_parent() == region.world:
			region.world.remove_child(player)
		region.queue_free()
	region = Region.new()
	add_child(region)
	move_child(region, 0)
	region.build(id, REGIONS[id])
	region.exit_requested.connect(_on_exit_requested)
	if player.get_parent():
		player.get_parent().remove_child(player)
	region.world.add_child(player)
	player.place_at(pos if pos is Vector2 else region.entry_position(entry))
	_apply_camera_limits()
	story.apply_presence(region)
	if hud:
		hud.show_region_name(region.region_name)

	if with_fade:
		await _fade_to(0.0)
	player.frozen = false
	transitioning = false
	story.on_region_entered(region)


func _apply_camera_limits() -> void:
	var lim := region.camera_limits()
	var cam := player.camera
	cam.limit_left = lim.position.x
	cam.limit_top = lim.position.y
	cam.limit_right = lim.end.x
	cam.limit_bottom = lim.end.y
	cam.make_current()
	cam.reset_smoothing()


func _fade_to(a: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", a, FADE_TIME)
	await tw.finished


func _on_exit_requested(to: String, entry: String) -> void:
	change_region(to, entry)
