extends Node
class_name WeaponEffectManager

@export var max_effect_slots: int = 3
@export var effect_slots: Array[WeaponEffectSlot] = []

# Thêm hiệu ứng mới hoặc cộng dồn nếu đã tồn tại
func add_effect(effect_resource: WeaponEffect, stacks: int = 1) -> void:
	# Tìm xem hiệu ứng đã tồn tại chưa để cộng dồn (stacks)
	for slot in effect_slots:
		if slot.effect == effect_resource:
			slot.stacks += stacks
			return
			
	# Nếu chưa có và còn chỗ trống thì thêm vào
	if effect_slots.size() < max_effect_slots:
		var new_slot = WeaponEffectSlot.new()
		new_slot.effect = effect_resource
		new_slot.stacks = stacks
		effect_slots.append(new_slot)
	else:
		push_warning("Không thể thêm hiệu ứng. Đã đạt tối đa số slot hiệu ứng của vũ khí!")

# Gọi tất cả các hiệu ứng đang có lên mục tiêu
func apply_all_effects(target: Node) -> void:
	for slot in effect_slots:
		if slot.effect:
			slot.effect.apply_effect(target, slot.stacks)
