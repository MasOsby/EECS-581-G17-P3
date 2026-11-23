class_name CombatManager
extends Node
## Runs the turn loop. Starts on PLAYER_TURN; after one action it switches to
## ENEMY_TURN. Once both sides have acted, turn_indicator increments by 1.
signal energy_changed(current: int, maxium: int)
signal turn_changed(turn: Turn)
signal combat_finished(player_won: bool)
enum Turn { PLAYER_TURN, ENEMY_TURN, FINISHED }
var turn: Turn = Turn.PLAYER_TURN
const attack_cost: int = 1
var turn_indicator: int = 1
var player: Player
var enemy: Enemy
@export_range(1,20) var max_energy: int = 3
var energy: int = 0 

func setup(p: Player, e: Enemy) -> void:
	player = p
	enemy = e
	turn_indicator = 1
	_start_player_turn()
	
	
func can_use_move(cost: int) -> bool:
	return turn == Turn.PLAYER_TURN and cost >= 0 and energy >= cost
	
func _try_spend_energy(cost: int) -> bool:
	if not can_use_move(cost):
		return false

	energy -= cost
	energy_changed.emit(energy, max_energy)
	return true

func player_attack() -> void:
	if not _try_spend_energy(attack_cost):
		return

	player.attack(enemy)
	if not enemy.alive:
		_finish(true)
		
func end_player_turn() -> void:
	if turn != Turn.PLAYER_TURN:
		return

	turn = Turn.ENEMY_TURN
	turn_changed.emit(turn)

func enemy_attack() -> void:
	if turn != Turn.ENEMY_TURN:
		return

	enemy.attack(player)
	if not player.alive:
		_finish(false)
		return

	turn_indicator += 1
	_start_player_turn()

func _start_player_turn() -> void:
	turn = Turn.PLAYER_TURN
	energy = max_energy
	energy_changed.emit(energy, max_energy)
	turn_changed.emit(turn)

func _finish(player_won: bool) -> void:
	turn = Turn.FINISHED
	combat_finished.emit(player_won)
