class_name Combatant
extends RefCounted
## Base class for everything that fights (the swordsman and every enemy).

signal health_changed(current: int, maximum: int)

var combatant_name: String = "Combatant"
var max_health: int = 1
var health: int = 1
var base_damage: int = 1
var base_speed: int = 1
var alive: bool = true

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		die()

func attack(target: Combatant) -> void:
	target.take_damage(base_damage)

func die() -> void:
	alive = false
