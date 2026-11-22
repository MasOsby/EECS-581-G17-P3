class_name CombatManager
extends Node
## Runs the turn loop. The swordsman acts once, then every living enemy acts.
## Combat ends when the player dies or every enemy is dead.

signal turn_changed(turn: Turn)
signal combat_finished(player_won: bool)
enum Turn { PLAYER_TURN, ENEMY_TURN, FINISHED }
var turn: Turn = Turn.PLAYER_TURN
var turn_indicator: int = 1
var player: Player
var enemies: Array[Enemy] = []

func setup(p: Player, wave: Array[Enemy]) -> void:
	player = p
	enemies = wave
	turn = Turn.PLAYER_TURN
	turn_indicator = 1

func living_enemies() -> Array[Enemy]:
	var living: Array[Enemy] = []
	for enemy in enemies:
		if enemy.alive:
			living.append(enemy)
	return living

func all_enemies_dead() -> bool:
	return living_enemies().is_empty()

func player_attack(target: Enemy) -> void:
	if turn != Turn.PLAYER_TURN or target == null or not target.alive:
		return
	player.attack(target)
	if all_enemies_dead():
		_finish(true)
	else:
		turn = Turn.ENEMY_TURN
		turn_changed.emit(turn)

func enemy_attack(attacker: Enemy) -> void:
	if turn != Turn.ENEMY_TURN or attacker == null or not attacker.alive or not player.alive:
		return
	attacker.attack(player)
	if not player.alive:
		_finish(false)

func end_enemy_round() -> void:
	if turn != Turn.ENEMY_TURN:
		return
	turn_indicator += 1
	turn = Turn.PLAYER_TURN
	turn_changed.emit(turn)

func _finish(player_won: bool) -> void:
	turn = Turn.FINISHED
	combat_finished.emit(player_won)
