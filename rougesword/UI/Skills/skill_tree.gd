extends Control
## Skill tree screen: shows the HUD (gold, level, skill points) and a message
## when the player tries to unlock a skill they can't afford.

const HUD := preload("res://UI/HUD/HUD.tscn")

var _player := Player.new()   # reads gold / level / skill points from GameState
var _message: Label

func _ready() -> void:
	var hud := HUD.instantiate()
	add_child(hud)
	hud.bind_player(_player)
	# The HUD's gold / skill-point readout sits top-right in combat, which is
	# where the Attack branch is drawn. Park it in the empty bottom-right corner.
	for part in ["Gold", "Icon_Gold", "Skillpts", "Icon_Skillpts"]:
		hud.get_node(part).position.y += 390
	GameState.skill_points_changed.connect(_on_skill_points_changed)

	_message = Label.new()
	_message.position = Vector2(100, 438)
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.add_theme_constant_override("outline_size", 6)
	add_child(_message)
	_connect_nodes(self)

func _connect_nodes(node: Node) -> void:
	for child in node.get_children():
		if child is SkillNode:
			child.unlock_failed.connect(_on_unlock_failed)
		_connect_nodes(child)

func _on_skill_points_changed(points: int) -> void:
	_player.skill_pts = points
	_player.skill_pts_changed.emit(points)
	_message.text = ""

func _on_unlock_failed() -> void:
	_message.text = "Not enough skill points"
