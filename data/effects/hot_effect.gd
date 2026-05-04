extends StatusEffect
class_name HOTEffect

@export var hp_per_second: float = 10.0
@export var mp_per_second: float = 5.0
var tick_timer: float = 0.0

func _tick(delta: float):
	if target_manager:
		tick_timer += delta
		if tick_timer >= 1.0:
			tick_timer -= 1.0
			var actual_hp = hp_per_second * current_stacks
			var actual_mp = mp_per_second * current_stacks
			target_manager.current_hp = min(target_manager.current_hp + actual_hp, target_manager.get_stat("max_hp"))
			target_manager.health_changed.emit(target_manager.current_hp, target_manager.get_stat("max_hp"))
			
			target_manager.current_mp = min(target_manager.current_mp + actual_mp, target_manager.get_stat("max_mp"))
			target_manager.mp_changed.emit(target_manager.current_mp, target_manager.get_stat("max_mp"))
