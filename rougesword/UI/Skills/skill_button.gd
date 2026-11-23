extends TextureButton
class_name SkillNode

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D

#signal skill_unlocked(skill: SkillData)
#
#@export var skill_data: SkillData
#@export var point_cost: int = 1

func _ready():
	if get_parent() is SkillNode:
		line_2d.add_point(global_position + size / 2)
		line_2d.add_point(get_parent().global_position + size / 2)

var level : int = 0:
	set(value):
		level = value
		label.text = str(level) + "/1"


func _on_pressed() -> void:
	level = min( level + 1, 1)
	#Change color when skill is unlocked
	panel.show_behind_parent = true
	#Change line color when the branch is unlocked	
	line_2d.default_color = Color(0.966, 0.827, 0.502, 1.0)
	
	#Only unlock skills if the previous is already unlocked
	var skills = get_children()
	for skill in skills:
		if skill is SkillNode and level == 1:
			skill.disabled = false
