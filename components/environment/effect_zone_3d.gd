extends Area3D

@export var zone_name: String = "Vùng Ẩn"
@export var zone_effect: StatusEffect
@export var is_instant_zone: bool = true

var active_entities: Dictionary = {}

func _ready():
	$Label3D.text = zone_name
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	# Chỉ xử lý nếu đối tượng có StatsManager
	var stats_manager = body.get_node_or_null("StatsManager")
	if stats_manager and zone_effect:
		var applied_effect = stats_manager.apply_status_effect(zone_effect)
		
		# Nếu là vùng tác dụng liên tục (không mang theo), lưu trữ lại để gỡ khi ra ngoài
		if not is_instant_zone:
			active_entities[body] = applied_effect

func _on_body_exited(body: Node3D):
	if not is_instant_zone and active_entities.has(body):
		var stats_manager = body.get_node_or_null("StatsManager")
		if stats_manager:
			stats_manager.remove_status_effect(active_entities[body])
		active_entities.erase(body)
