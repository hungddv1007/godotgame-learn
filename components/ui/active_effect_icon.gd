extends PanelContainer

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var time_label = $MarginContainer/VBoxContainer/TimeLabel

var effect: StatusEffect

func setup(p_effect: StatusEffect):
	effect = p_effect
	_update_display()

func _update_display():
	if not effect:
		return
	# Hiển thị tên + số stack (nếu > 1)
	var display_name = effect.effect_name
	if effect.current_stacks > 1:
		display_name += " x" + str(effect.current_stacks)
	name_label.text = display_name

func _process(_delta):
	if effect:
		# Cập nhật tên (bao gồm stack count có thể thay đổi)
		_update_display()
		# Cập nhật thời gian
		if effect.duration > 0:
			time_label.text = str(snapped(effect.time_remaining, 0.1)) + "s"
		else:
			time_label.text = "∞"
