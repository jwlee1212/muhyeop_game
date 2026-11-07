extends Node2D
## 말 걸기·살펴보기 대상. 주인공이 가까이 가면 머리 위에 안내가 뜨고, E로 상호작용한다.
## 실제 반응은 story.gd 의 on_interact(id)가 정한다.

var id := ""
var prompt := "살펴보기"
var radius := 22.0
var enabled := true


func _ready() -> void:
	add_to_group("interactables")


func can_interact() -> bool:
	return enabled and visible and is_inside_tree()
