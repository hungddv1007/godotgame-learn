extends Node
class_name StatsManager

static var show_damage_numbers: bool = true
var floating_text_scene = preload("res://components/ui/floating_text.tscn")

signal health_changed(current_hp, max_hp)
signal mp_changed(current_mp, max_mp)
signal stamina_changed(current_stamina, max_stamina)
signal stat_changed(stat_name, new_total_value)
signal tag_added(tag_name)
signal tag_removed(tag_name)
signal effect_applied(effect)
signal effect_removed(effect)
signal died()

enum ModifierType { FLAT, PERCENT }

class StatData:
	var base_value: float = 0.0
	var flat_bonus: float = 0.0
	var percent_bonus: float = 0.0
	
	func get_total() -> float:
		return (base_value + flat_bonus) * (1.0 + percent_bonus)

# 1. Khối Dữ liệu Chỉ số
var stats: Dictionary = {}

# Vitals
var current_hp: float = 100.0
var current_mp: float = 100.0
var current_stamina: float = 100.0
var current_shield: float = 0.0

# 2. Khối Trạng thái & Tags
var active_tags: Dictionary = {}
var active_effects: Array[StatusEffect] = []
var regen_timer: float = 0.0

func _ready():
	_init_stat("max_hp", 100.0)
	_init_stat("hp_regen", 1.0)
	_init_stat("max_mp", 100.0)
	_init_stat("mp_regen", 1.0)
	_init_stat("max_stamina", 100.0)
	_init_stat("stamina_regen", 5.0)
	
	# Core Combat Stats
	_init_stat("attack_damage", 25.0)
	
	# LoL Stats
	_init_stat("armor", 0.0)
	_init_stat("magic_resist", 0.0)
	_init_stat("ability_haste", 0.0)
	_init_stat("tenacity", 0.0) # Kháng hiệu ứng: 0.0 tới 1.0
	
	current_hp = get_stat("max_hp")
	current_mp = get_stat("max_mp")
	current_stamina = get_stat("max_stamina")

func _init_stat(stat_name: String, base: float):
	var stat = StatData.new()
	stat.base_value = base
	stats[stat_name] = stat

func get_stat(stat_name: String) -> float:
	if stats.has(stat_name):
		return stats[stat_name].get_total()
	return 0.0

func add_modifier(stat_name: String, type: ModifierType, value: float):
	if not stats.has(stat_name): return
	var stat = stats[stat_name]
	
	if type == ModifierType.FLAT:
		stat.flat_bonus += value
	elif type == ModifierType.PERCENT:
		stat.percent_bonus += value
		
	stat_changed.emit(stat_name, stat.get_total())
	if stat_name == "max_hp":
		health_changed.emit(current_hp, get_stat("max_hp"))

func remove_modifier(stat_name: String, type: ModifierType, value: float):
	if not stats.has(stat_name): return
	var stat = stats[stat_name]
	
	if type == ModifierType.FLAT:
		stat.flat_bonus -= value
	elif type == ModifierType.PERCENT:
		stat.percent_bonus -= value
		
	stat_changed.emit(stat_name, stat.get_total())
	if stat_name == "max_hp":
		health_changed.emit(current_hp, get_stat("max_hp"))

# Gameplay Tags Logic
func add_tag(tag_name: String):
	if active_tags.has(tag_name):
		active_tags[tag_name] += 1
	else:
		active_tags[tag_name] = 1
		tag_added.emit(tag_name)

func remove_tag(tag_name: String):
	if active_tags.has(tag_name):
		active_tags[tag_name] -= 1
		if active_tags[tag_name] <= 0:
			active_tags.erase(tag_name)
			tag_removed.emit(tag_name)

func has_tag(tag_name: String) -> bool:
	return active_tags.has(tag_name) and active_tags[tag_name] > 0

# Status Effects Logic

## Tìm hiệu ứng đang hoạt động theo ID
func find_active_effect(effect_id: String) -> StatusEffect:
	for active in active_effects:
		if active.get_effect_id() == effect_id:
			return active
	return null

func apply_status_effect(effect: StatusEffect) -> StatusEffect:
	# Kiểm tra xem hiệu ứng cùng ID đã tồn tại trong mảng chưa
	if effect.stackable:
		var existing = find_active_effect(effect.get_effect_id())
		if existing:
			# CÓ: Cộng dồn - tăng stack, reset timer
			existing.stack_effect()
			effect_applied.emit(existing) # Emit lại để UI cập nhật
			return existing
	
	# CHƯA CÓ hoặc không cho phép cộng dồn: Thêm mới vào mảng
	var new_effect = effect.duplicate()
	new_effect.current_stacks = 1
	new_effect.on_apply(self)
	active_effects.append(new_effect)
	effect_applied.emit(new_effect)
	return new_effect

func remove_status_effect(effect: StatusEffect):
	var index = active_effects.find(effect)
	if index != -1:
		effect.on_remove()
		active_effects.remove_at(index)
		effect_removed.emit(effect)

func _process(delta: float):
	# Xử lý Hồi phục Vitals (10 lần mỗi giây để tránh spam bộ nhớ)
	regen_timer += delta
	if regen_timer >= 0.1:
		var tick_delta = regen_timer
		regen_timer = 0.0
		
		if current_hp < get_stat("max_hp") and current_hp > 0:
			current_hp = min(current_hp + get_stat("hp_regen") * tick_delta, get_stat("max_hp"))
			health_changed.emit(current_hp, get_stat("max_hp"))
			
		if current_mp < get_stat("max_mp"):
			current_mp = min(current_mp + get_stat("mp_regen") * tick_delta, get_stat("max_mp"))
			mp_changed.emit(current_mp, get_stat("max_mp"))
			
		if current_stamina < get_stat("max_stamina"):
			current_stamina = min(current_stamina + get_stat("stamina_regen") * tick_delta, get_stat("max_stamina"))
			stamina_changed.emit(current_stamina, get_stat("max_stamina"))
	
	# Xử lý Thời gian Status Effects (Vẫn duy trì từng frame)
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		if effect.process_effect(delta):
			effect.on_remove()
			active_effects.remove_at(i)
			effect_removed.emit(effect)

# 3. Khối Đường ống Sát thương (Damage Pipeline)
func take_damage(damage_data: DamageData):
	if current_hp <= 0:
		return
		
	var multiplier = 1.0
	
	if damage_data.damage_type == DamageData.DamageType.PHYSICAL:
		# Giáp thực tế = (Giáp * (1 - Xuyên %)) - Xuyên thẳng
		var effective_armor = max(0.0, (get_stat("armor") * (1.0 - damage_data.percent_pen)) - damage_data.flat_pen)
		multiplier = 100.0 / (100.0 + effective_armor)
	elif damage_data.damage_type == DamageData.DamageType.MAGIC:
		# Kháng phép thực tế = (Kháng phép * (1 - Xuyên %)) - Xuyên thẳng
		var effective_mr = max(0.0, (get_stat("magic_resist") * (1.0 - damage_data.percent_pen)) - damage_data.flat_pen)
		multiplier = 100.0 / (100.0 + effective_mr)
	# Đối với TRUE DAMAGE, multiplier luôn là 1.0 (giữ nguyên)
		
	var final_damage = damage_data.amount * multiplier
	
	# Xử lý trừ Khiên ảo (Shield) trước
	if current_shield > 0:
		if current_shield >= final_damage:
			current_shield -= final_damage
			final_damage = 0.0
		else:
			final_damage -= current_shield
			current_shield = 0.0
			
	# Trừ HP thật
	if final_damage > 0:
		current_hp -= final_damage
		health_changed.emit(current_hp, get_stat("max_hp"))
		
		# Hiện sát thương nhảy số
		if show_damage_numbers and get_parent() is Node3D:
			var text_node = floating_text_scene.instantiate()
			get_parent().get_tree().current_scene.add_child(text_node)
			var random_offset = Vector3(randf_range(-0.3, 0.3), randf_range(1.0, 1.5), randf_range(-0.3, 0.3))
			text_node.global_position = get_parent().global_position + random_offset
			text_node.setup(final_damage, damage_data.is_critical)
		
		if current_hp <= 0:
			current_hp = 0
			died.emit()
