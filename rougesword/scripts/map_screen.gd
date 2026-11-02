extends Control
## Map state: a straight-line map of rooms. Click the next room to walk there.
## Visited rooms are darkened, hovered rooms are highlighted.

const SWORDSMAN_SCENE := preload("res://Swordsman.tscn")
const NODE_SIZE := Vector2(72, 72)
const NODE_Y := 330.0
const NODE_XS := [120.0, 320.0, 520.0]

var _buttons: Array[Button] = []
var _swordsman: Node2D
var _sprite: AnimatedSprite2D
var _fade: ColorRect
var _moving := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Choose your path"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 30)
	title.size = Vector2(640, 40)
	add_child(title)

	# Connections between rooms
	for i in range(GameState.MAP_NODES.size() - 1):
		var line := Line2D.new()
		line.width = 4.0
		line.default_color = Color(0.5, 0.5, 0.6)
		line.add_point(Vector2(NODE_XS[i], NODE_Y))
		line.add_point(Vector2(NODE_XS[i + 1], NODE_Y))
		add_child(line)

	# Room icons
	for i in range(GameState.MAP_NODES.size()):
		var info: Dictionary = GameState.MAP_NODES[i]
		var b := Button.new()
		b.text = info["label"]
		_style_button(b, Color(0.55, 0.2, 0.2) if info["type"] == "enemy" else Color(0.25, 0.35, 0.55))
		b.size = NODE_SIZE
		b.position = Vector2(NODE_XS[i], NODE_Y) - NODE_SIZE / 2.0
		b.pressed.connect(_on_node_pressed.bind(i))
		b.mouse_entered.connect(_on_node_hover.bind(i, true))
		b.mouse_exited.connect(_on_node_hover.bind(i, false))
		add_child(b)
		_buttons.append(b)

	# Swordsman standing on the current room
	_swordsman = SWORDSMAN_SCENE.instantiate()
	add_child(_swordsman)
	_sprite = _swordsman.get_node("CharacterBody2D/AnimatedSprite2D")
	_sprite.scale = Vector2(2.5, 2.5)
	_sprite.play("Idle")
	_swordsman.position = _stand_position(GameState.current_node)

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 420)
	hint.size = Vector2(640, 30)
	hint.name = "Hint"
	add_child(hint)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_refresh()

func _style_button(b: Button, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_border_width_all(3)
	box.border_color = Color(0.9, 0.9, 0.9)
	box.set_corner_radius_all(10)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, box)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)

func _stand_position(index: int) -> Vector2:
	return Vector2(NODE_XS[index] + 12.0, NODE_Y - 105.0)

func _refresh() -> void:
	var last := GameState.MAP_NODES.size() - 1
	for i in range(_buttons.size()):
		var b := _buttons[i]
		var reachable := i == GameState.current_node + 1
		b.disabled = not reachable
		b.modulate = Color.WHITE
		if i in GameState.visited:
			b.modulate = Color(0.55, 0.55, 0.55)  # visited = darker
		elif not reachable:
			b.modulate = Color(0.75, 0.75, 0.75)
	var hint: Label = get_node("Hint")
	if GameState.current_node == last and GameState.current_node != 0:
		hint.text = "End of the demo map! Press Esc / close the window, or:"
		var back := Button.new()
		back.text = "Return to Main Menu"
		back.position = Vector2(220, 440)
		back.size = Vector2(200, 32)
		back.pressed.connect(func(): GameState.change_state(GameState.State.MAIN_MENU))
		add_child(back)
	else:
		hint.text = "Click the next room to advance"

func _on_node_hover(index: int, hovering: bool) -> void:
	var b := _buttons[index]
	if b.disabled:
		return
	b.modulate = Color(1.4, 1.4, 0.8) if hovering else Color.WHITE

func _on_node_pressed(index: int) -> void:
	if _moving:
		return
	_moving = true
	_sprite.play("Run")
	var tween := create_tween()
	tween.tween_property(_swordsman, "position", _stand_position(index), 1.0)
	tween.tween_callback(func(): _sprite.play("Idle"))
	tween.tween_property(_fade, "color:a", 1.0, 0.5)  # fade to black
	tween.tween_callback(_arrive.bind(index))

func _arrive(index: int) -> void:
	GameState.current_node = index
	if index not in GameState.visited:
		GameState.visited.append(index)
	if GameState.MAP_NODES[index]["type"] == "enemy":
		GameState.change_state(GameState.State.COMBAT)
	else:
		_fade.color.a = 0.0
		_moving = false
		_refresh()
