extends StatusEffect
class_name DOTEffect

@export var damage_per_second: float = 5.0 # Sát thương cơ bản mỗi giây (1 stack)
var tick_timer: float = 0.0

## Sát thương thực tế = base_damage * current_stacks
func get_actual_dps() -> float:
	return damage_per_second * current_stacks

func _tick(delta: float):
	if target_manager:
		tick_timer += delta
		if tick_timer >= 1.0:
			tick_timer -= 1.0
			var dmg = DamageData.new()
			dmg.amount = get_actual_dps()
			dmg.damage_type = DamageData.DamageType.TRUE
			target_manager.take_damage(dmg)
