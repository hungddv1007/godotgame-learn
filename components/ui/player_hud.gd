extends CanvasLayer

@export var stats_manager: StatsManager

@onready var hp_bar = $MarginContainer/VBoxContainer/HPBar
@onready var mp_bar = $MarginContainer/VBoxContainer/MPBar
@onready var st_bar = $MarginContainer/VBoxContainer/StaminaBar
@onready var effects_container = $MarginContainer/VBoxContainer/ActiveEffects
@onready var weapon_icon = $WeaponDisplay/HBoxContainer/WeaponIcon
@onready var weapon_label = $WeaponDisplay/HBoxContainer/WeaponName
@onready var pickup_prompt = $PickupPrompt
@onready var pickup_name_label = $PickupPrompt/VBoxContainer/ItemName
@onready var pickup_desc_label = $PickupPrompt/VBoxContainer/ItemDesc
@onready var pickup_keys_label = $PickupPrompt/VBoxContainer/KeyHints

var effect_ui_scene = preload("res://components/ui/active_effect_icon.tscn")

func _ready():
	if not stats_manager: return
	stats_manager.health_changed.connect(_on_hp_changed)
	stats_manager.mp_changed.connect(_on_mp_changed)
	stats_manager.stamina_changed.connect(_on_stamina_changed)
	stats_manager.effect_applied.connect(_on_effect_applied)
	stats_manager.effect_removed.connect(_on_effect_removed)
	
	hp_bar.max_value = stats_manager.get_stat("max_hp")
	hp_bar.value = stats_manager.current_hp
	mp_bar.max_value = stats_manager.get_stat("max_mp")
	mp_bar.value = stats_manager.current_mp
	st_bar.max_value = stats_manager.get_stat("max_stamina")
	st_bar.value = stats_manager.current_stamina
	
	# Kết nối signal đổi vũ khí từ Player
	var player = stats_manager.get_parent()
	if player and player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_weapon_changed)
	
	# Ẩn pickup prompt lúc đầu
	pickup_prompt.visible = false

func _on_weapon_changed(weapon_data):
	if weapon_icon:
		weapon_icon.color = weapon_data.weapon_color
	if weapon_label:
		weapon_label.text = weapon_data.weapon_name
	
	# Animation nhấp nháy
	var tween = create_tween()
	if weapon_icon:
		tween.tween_property(weapon_icon, "modulate:a", 0.3, 0.1)
		tween.tween_property(weapon_icon, "modulate:a", 1.0, 0.2)

## === PICKUP PROMPT ===

func show_pickup_prompt(pickup) -> void:
	if not pickup_prompt:
		return
	pickup_prompt.visible = true
	
	# Cập nhật thông tin
	pickup_name_label.text = pickup.item_name
	pickup_name_label.add_theme_color_override("font_color", pickup.item_color)
	pickup_desc_label.text = pickup.get_full_description()
	
	# Key hints khác nhau cho vũ khí vs cường hóa
	if pickup.pickup_type == 0: # WEAPON
		pickup_keys_label.text = "[E] Trang bị   [Q] Phân rã   [Esc] Bỏ qua"
	else: # ENHANCEMENT
		pickup_keys_label.text = "[E] Nhặt   [Q] Phân rã   [Esc] Bỏ qua"
	
	# Animation hiện ra
	pickup_prompt.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(pickup_prompt, "modulate:a", 1.0, 0.15)

func hide_pickup_prompt() -> void:
	if not pickup_prompt:
		return
	var tween = create_tween()
	tween.tween_property(pickup_prompt, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): pickup_prompt.visible = false)

## === BARS ===

func _on_hp_changed(current, max_val):
	_tween_bar(hp_bar, current, max_val)

func _on_mp_changed(current, max_val):
	_tween_bar(mp_bar, current, max_val)

func _on_stamina_changed(current, max_val):
	_tween_bar(st_bar, current, max_val)

func _tween_bar(bar: ProgressBar, value: float, max_val: float):
	bar.max_value = max_val
	var tween = create_tween()
	tween.tween_property(bar, "value", value, 0.2).set_ease(Tween.EASE_OUT)

## === EFFECTS ===

func _on_effect_applied(effect: StatusEffect):
	for child in effects_container.get_children():
		if child.effect == effect:
			child._update_display()
			return
	var icon = effect_ui_scene.instantiate()
	effects_container.add_child(icon)
	icon.setup(effect)

func _on_effect_removed(effect: StatusEffect):
	for child in effects_container.get_children():
		if child.effect == effect:
			child.queue_free()
			break
