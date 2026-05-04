extends CanvasLayer

@export var stats_manager: StatsManager

@onready var panel = $PanelContainer
@onready var vbox = $PanelContainer/MarginContainer/VBoxContainer

var labels: Dictionary = {}

func _ready():
	if not stats_manager:
		return
		
	# Tạo Label cho Vitals
	_create_label("HP", stats_manager.current_hp, stats_manager.get_stat("max_hp"))
	_create_label("MP", stats_manager.current_mp, stats_manager.get_stat("max_mp"))
	_create_label("Stamina", stats_manager.current_stamina, stats_manager.get_stat("max_stamina"))
	
	# Tạo Label cho Stats chung
	for stat_name in stats_manager.stats.keys():
		if not stat_name.begins_with("max_"): # max_ được gộp chung rồi
			_create_label(stat_name.capitalize(), stats_manager.get_stat(stat_name), -1)
			
	stats_manager.health_changed.connect(_on_health_changed)
	stats_manager.mp_changed.connect(_on_mp_changed)
	stats_manager.stamina_changed.connect(_on_stamina_changed)
	stats_manager.stat_changed.connect(_on_stat_changed)

func _create_label(id: String, value: float, max_val: float):
	var lbl = Label.new()
	if max_val >= 0:
		lbl.text = id + ": " + str(snapped(value, 0.1)) + " / " + str(snapped(max_val, 0.1))
	else:
		lbl.text = id + ": " + str(snapped(value, 0.1))
	vbox.add_child(lbl)
	labels[id] = lbl

func _on_health_changed(current, max_hp):
	if labels.has("HP"):
		labels["HP"].text = "HP: " + str(snapped(current, 0.1)) + " / " + str(snapped(max_hp, 0.1))

func _on_mp_changed(current, max_hp):
	if labels.has("MP"):
		labels["MP"].text = "MP: " + str(snapped(current, 0.1)) + " / " + str(snapped(max_hp, 0.1))

func _on_stamina_changed(current, max_hp):
	if labels.has("Stamina"):
		labels["Stamina"].text = "Stamina: " + str(snapped(current, 0.1)) + " / " + str(snapped(max_hp, 0.1))

func _on_stat_changed(stat_name, total_value):
	var cap_name = stat_name.capitalize()
	if labels.has(cap_name):
		labels[cap_name].text = cap_name + ": " + str(snapped(total_value, 0.1))
		
	# Update max string for Vitals
	if stat_name == "max_hp" and labels.has("HP"):
		labels["HP"].text = "HP: " + str(snapped(stats_manager.current_hp, 0.1)) + " / " + str(snapped(total_value, 0.1))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		panel.visible = not panel.visible
