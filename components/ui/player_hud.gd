extends CanvasLayer

@export var stats_manager: StatsManager

@onready var hp_bar = $MarginContainer/VBoxContainer/HPBar
@onready var mp_bar = $MarginContainer/VBoxContainer/MPBar
@onready var st_bar = $MarginContainer/VBoxContainer/StaminaBar
@onready var effects_container = $MarginContainer/VBoxContainer/ActiveEffects

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

func _on_effect_applied(effect: StatusEffect):
	# Kiểm tra xem đã có icon cho hiệu ứng này chưa (trường hợp cộng dồn)
	for child in effects_container.get_children():
		if child.effect == effect:
			# Đã có icon - chỉ cập nhật hiển thị (stack count đã tăng)
			child._update_display()
			return
	
	# Chưa có icon - tạo mới
	var icon = effect_ui_scene.instantiate()
	effects_container.add_child(icon)
	icon.setup(effect)

func _on_effect_removed(effect: StatusEffect):
	for child in effects_container.get_children():
		if child.effect == effect:
			child.queue_free()
			break
