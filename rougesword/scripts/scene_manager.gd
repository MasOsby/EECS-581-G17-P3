extends Node
## Autoload: listens for GameState.state_changed and swaps the active scene,
## so no screen needs to know how to load any other screen.

const SCENES := {
	GameState.State.MAIN_MENU: "res://MainMenu.tscn",
	GameState.State.MAP: "res://MapScreen.tscn",
	GameState.State.COMBAT: "res://CombatScene.tscn",
	GameState.State.VICTORY: "res://VictoryScreen.tscn",
	GameState.State.DEATH: "res://DeathScreen.tscn",
}

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: GameState.State) -> void:
	get_tree().change_scene_to_file.call_deferred(SCENES[new_state])
