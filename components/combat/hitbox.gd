extends Area3D
class_name Hitbox

@export var damage_data: DamageData
@export var weapon_effect_manager: WeaponEffectManager

var hit_entities: Array[Node] = []

func clear_hit_history():
	hit_entities.clear()

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	if area is Hurtbox:
		var target = area.owner
		# Không tự gây sát thương cho bản thân
		if target == self.owner:
			return
			
		# Nếu đã đánh trúng mục tiêu này trong cú chém hiện tại rồi thì bỏ qua
		if hit_entities.has(target):
			return
			
		# Lưu lại mục tiêu để không chém trúng lần 2 (ví dụ trúng cả thân và đầu)
		hit_entities.append(target)
			
		if damage_data:
			area.receive_damage(damage_data)
			
		if weapon_effect_manager:
			weapon_effect_manager.apply_all_effects(target)
