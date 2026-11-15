extends Control
## Victory state: "Victory!" and a Go Onward button (-> Map).


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.12, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var title := Label.new()
	title.text = "Victory!"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var button := Button.new()
	button.text = "Go Onward"
	button.custom_minimum_size = Vector2(180, 40)
	button.pressed.connect(func(): GameState.change_state(GameState.State.MAP))
	box.add_child(button)
	
	var skill_tree := Button.new()
	skill_tree.text = "Skills"
	skill_tree.custom_minimum_size = Vector2(180, 40)
	skill_tree.pressed.connect(func(): GameState.change_state(GameState.State.SKILLS))
	box.add_child(skill_tree)
