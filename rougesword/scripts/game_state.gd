extends Node
## Autoload: owns run-wide state (current game state, current map node, player health).
## Any change of game state is announced through the state_changed signal.

signal state_changed(new_state)
enum State { MAIN_MENU, MAP, COMBAT, VICTORY, DEATH }

# Hardcoded straight-line map: start room -> easy enemy room -> hard enemy room.
const MAP_NODES := [
	{"type": "start", "label": "Start"},
	{"type": "enemy", "label": "Easy", "enemy": "res://data/enemy_easy.tres"},
	{"type": "enemy", "label": "Hard", "enemy": "res://data/enemy_hard.tres"},
]

var state: State = State.MAIN_MENU
var current_node: int = 0
var visited: Array[int] = [0]
var player_max_health: int = 10
var player_health: int = 10

func start_run() -> void:
	current_node = 0
	visited = [0]
	player_health = player_max_health
	change_state(State.MAP)

func change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)

func current_enemy_data() -> EnemyData:
	return load(MAP_NODES[current_node]["enemy"]) as EnemyData
