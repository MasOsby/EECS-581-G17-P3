class_name CombatManager
extends Node
## Runs the turn loop. Starts on PLAYER_TURN; after one action it switches to
## ENEMY_TURN. Once both sides have acted, turn_indicator increments by 1.

signal turn_changed(turn: Turn)
signal combat_finished(player_won: bool)
enum Turn { PLAYER_TURN, ENEMY_TURN, FINISHED }
var turn: Turn = Turn.PLAYER_TURN
var turn_indicator: int = 1
var player: Player
var enemy: Enemy

func setup(p: Player, e: Enemy) -> void:
	player = p
	enemy = e
	turn = Turn.PLAYER_TURN
	turn_indicator = 1

func player_attack() -> void:
	player.attack(enemy)
	if not enemy.alive:
		_finish(true)
	else:
		turn = Turn.ENEMY_TURN
		turn_changed.emit(turn)

func enemy_attack() -> void:
	enemy.attack(player)
	if not player.alive:
		_finish(false)
	else:
		turn_indicator += 1
		turn = Turn.PLAYER_TURN
		turn_changed.emit(turn)

func _finish(player_won: bool) -> void:
	turn = Turn.FINISHED
	combat_finished.emit(player_won)
