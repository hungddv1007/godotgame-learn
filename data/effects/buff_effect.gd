extends StatusEffect
class_name StatBuffEffect

@export var stat_to_buff: String = "attack_damage"
@export var modifier_type: StatsManager.ModifierType = StatsManager.ModifierType.FLAT
@export var buff_amount: float = 20.0 # Lượng buff cho mỗi stack

var applied_amount: float = 0.0 # Tổng lượng modifier đã thực sự áp dụng

func on_apply(manager: Node) -> void:
	super.on_apply(manager)
	applied_amount = buff_amount # Stack 1
	target_manager.add_modifier(stat_to_buff, modifier_type, applied_amount)

## Khi cộng dồn thêm stack, bổ sung thêm lượng modifier cho stack mới
func _on_stack_changed() -> void:
	if target_manager:
		# Thêm buff_amount cho stack mới (chỉ thêm phần chênh lệch)
		target_manager.add_modifier(stat_to_buff, modifier_type, buff_amount)
		applied_amount += buff_amount

func on_remove() -> void:
	if target_manager:
		target_manager.remove_modifier(stat_to_buff, modifier_type, applied_amount)
	super.on_remove()
