extends Button


# Called when the node enters the scene tree for the first time.

func _on_pressed() -> void:
		get_tree().change_scene_to_file("res://Gamestate/Victory/VictoryScreen.tscn")
