extends Resource
class_name StatusEffect

@export var effect_name: String = "Unknown Effect"
@export var duration: float = 0.0 # 0 = Vĩnh viễn (hoặc cho tới khi bị xóa thủ công)
@export var tags_to_apply: Array[String] = []

var time_remaining: float = 0.0
var target_manager: Node = null

func on_apply(manager: Node) -> void:
	target_manager = manager
	time_remaining = duration
	for tag in tags_to_apply:
		target_manager.add_tag(tag)

func on_remove() -> void:
	if target_manager:
		for tag in tags_to_apply:
			target_manager.remove_tag(tag)

# Trả về true nếu hiệu ứng đã hết thời gian và cần được gỡ bỏ
func process_effect(delta: float) -> bool:
	if duration > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			return true
	return false
