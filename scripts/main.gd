extends Node2D
## 게임 루트. 지역을 불러오고 바꾸며, 주인공·HUD·화면 페이드를 유지한다.

const Region := preload("res://scripts/world/region.gd")
const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/hud.gd")

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
var fade: ColorRect
var transitioning := false


func _ready() -> void:
	player = Player.new()
	_build_fade()
	await change_region(START_REGION, START_ENTRY, false)
	hud = Hud.new()
	hud.player = player
	add_child(hud)
	hud.show_region_name(region.region_name)


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


func change_region(id: String, entry: String, with_fade := true) -> void:
	if transitioning or not REGIONS.has(id):
		if not REGIONS.has(id):
			push_warning("없는 지역: " + id)
		return
	transitioning = true
	player.frozen = true
	if with_fade:
		await _fade_to(1.0)

	if region:
		region.world.remove_child(player)
		region.queue_free()
	region = Region.new()
	add_child(region)
	region.build(id, REGIONS[id])
	region.exit_requested.connect(_on_exit_requested)
	region.world.add_child(player)
	player.place_at(region.entry_position(entry))
	_apply_camera_limits()
	if hud:
		hud.show_region_name(region.region_name)

	if with_fade:
		await _fade_to(0.0)
	player.frozen = false
	transitioning = false


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
