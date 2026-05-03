extends Area3D
class_name Hurtbox

@export var stats_manager: StatsManager
@export var damage_multiplier: float = 1.0

func receive_damage(damage: DamageData):
	if stats_manager:
		if damage_multiplier != 1.0:
			var modified_damage = damage.duplicate()
			modified_damage.amount *= damage_multiplier
			stats_manager.take_damage(modified_damage)
			print("Critical Hit! x", damage_multiplier)
		else:
			stats_manager.take_damage(damage)
