class_name Player
extends Combatant
## The swordsman. Health persists between fights through GameState.

func _init() -> void:
	combatant_name = "Swordsman"
	max_health = GameState.player_max_health
	health = GameState.player_health
	base_damage = 2
	base_speed = 2
