extends TextureButton
class_name SkillNode

## Emitted when the player presses a skill they can't afford.
signal unlock_failed

## The ability this node unlocks. Leave empty for a decorative node (a skill
## whose combat effect isn't implemented yet): it just toggles, for free.
@export var skill_data: SkillData

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
	# Re-opening the tree: show skills already unlocked this run.
	if skill_data != null and GameState.has_skill(skill_data):
		_show_unlocked()

var level : int = 0:
	set(value):
		level = value
		label.text = str(level) + "/1"


func _on_pressed() -> void:
	# Unlocking costs skill points. Not enough? Undo the toggle and say so.
	if skill_data != null and not GameState.try_unlock_skill(skill_data):
		button_pressed = false
		unlock_failed.emit()
		return
	_show_unlocked()

func _show_unlocked() -> void:
	level = min( level + 1, 1)
	button_pressed = true
	#Change color when skill is unlocked
	panel.show_behind_parent = true
	#Change line color when the branch is unlocked
	line_2d.default_color = Color(0.966, 0.827, 0.502, 1.0)

	#Only unlock skills if the previous is already unlocked
	var skills = get_children()
	for skill in skills:
		if skill is SkillNode and level == 1:
			skill.disabled = false
