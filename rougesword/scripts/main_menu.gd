extends Control
## MainMenu state: title, Play (-> Map) and Exit.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "Rogue Swordsman"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var play := Button.new()
	play.text = "Play"
	play.custom_minimum_size = Vector2(160, 40)
	play.pressed.connect(GameState.start_run)
	box.add_child(play)

	var quit := Button.new()
	quit.text = "Exit"
	quit.custom_minimum_size = Vector2(160, 40)
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
