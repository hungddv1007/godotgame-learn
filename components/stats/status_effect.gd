extends Resource
class_name StatusEffect

@export var effect_name: String = "Unknown Effect"
@export var effect_id: String = "" # ID duy nhất để nhận diện hiệu ứng khi cộng dồn (nếu rỗng, dùng effect_name)
@export var duration: float = 0.0 # 0 = Vĩnh viễn (hoặc cho tới khi bị xóa thủ công)
@export var tags_to_apply: Array[String] = []
@export var max_stacks: int = 5 # Số lượng cộng dồn tối đa
@export var stackable: bool = true # Có cho phép cộng dồn không

var current_stacks: int = 1
var time_remaining: float = 0.0
var target_manager: Node = null

## Lấy ID để so sánh khi cộng dồn
func get_effect_id() -> String:
	return effect_id if effect_id != "" else effect_name

func on_apply(manager: Node) -> void:
	target_manager = manager
	time_remaining = duration
	for tag in tags_to_apply:
		target_manager.add_tag(tag)

func on_remove() -> void:
	if target_manager:
		for tag in tags_to_apply:
			target_manager.remove_tag(tag)

## Cộng dồn thêm 1 stack, reset timer, trả về true nếu thành công
func stack_effect() -> bool:
	if current_stacks < max_stacks:
		current_stacks += 1
		time_remaining = duration # Reset timer
		_on_stack_changed()
		return true
	else:
		# Đã đạt max stacks, chỉ reset timer
		time_remaining = duration
		return false

## Được gọi khi số stack thay đổi - các lớp con override để cập nhật hiệu ứng
func _on_stack_changed() -> void:
	pass

# Trả về true nếu hiệu ứng đã hết thời gian và cần được gỡ bỏ
func process_effect(delta: float) -> bool:
	_tick(delta)
	if duration > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			return true
	return false

# Hàm ảo để các hiệu ứng con override (VD: Rút máu, hồi máu mỗi giây)
func _tick(_delta: float) -> void:
	pass
