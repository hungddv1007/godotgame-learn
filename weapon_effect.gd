extends Resource
class_name WeaponEffect

@export var effect_name: String = "Unnamed Effect"

# Hàm được gọi bởi vũ khí để áp dụng hiệu ứng lên mục tiêu
func apply_effect(target: Node, stacks: int) -> void:
	print("Applying effect: ", effect_name, " with ", stacks, " stacks to ", target.name)
