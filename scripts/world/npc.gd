extends StaticBody2D
## NPC 자리 표시. 대화는 M4. 지금은 서 있다가 주인공이 가까이 오면 그쪽을 본다.

const Body := preload("res://scripts/dummy_body.gd")
const Player := preload("res://scripts/player.gd")

const NPCS := {
	"okbun": {
		"name": "옥분", "facing": 0,
		"palette": {"robe": Color("b0506a"), "robe_dark": Color("7a3448"), "trim": Color("e8d8b0"),
			"skin": Color("f0c8a0"), "hair": Color("2a1e22"), "weapon": Color(0, 0, 0, 0),
			"hilt": Color(0, 0, 0, 0), "shoe": Color("3a2420")},
	},
	"ma": {
		"name": "마 사범", "facing": 0,
		"palette": {"robe": Color("3a4a6a"), "robe_dark": Color("26324a"), "trim": Color("c8a040"),
			"skin": Color("d8a878"), "hair": Color("5a5a5a"), "weapon": Color("8a5e3a"),
			"hilt": Color("5a3a24"), "shoe": Color("1e1a18")},
	},
	"yeop": {
		"name": "엽 노인", "facing": 0,
		"palette": {"robe": Color("8a8470"), "robe_dark": Color("625e4e"), "trim": Color("4a6a5a"),
			"skin": Color("d8b090"), "hair": Color("d8d8d0"), "weapon": Color(0, 0, 0, 0),
			"hilt": Color(0, 0, 0, 0), "shoe": Color("2a2420")},
	},
}

var npc_id := "okbun"
var display_name := ""
var body: Body


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("npcs")
	var shape := CircleShape2D.new()
	shape.radius = 6
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -2)
	add_child(cs)
	var data: Dictionary = NPCS.get(npc_id, NPCS.okbun)
	display_name = data.name
	body = Body.new()
	body.palette = data.palette
	body.facing = data.facing
	add_child(body)


func _process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p and global_position.distance_to(p.global_position) < 48.0:
		body.facing = Player.dir_index(p.global_position - global_position)
