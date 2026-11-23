extends CanvasLayer


@onready var gold: Label = $Gold
@onready var level: Label = $Level
@onready var skillpts: Label = $Skillpts

#Attach signals to player stats changing
func bind_player(player: Player) -> void:
	player.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(player.gold)
	
	player.level_changed.connect(_on_level_changed)
	_on_level_changed(player.level)
	
	player.skill_pts_changed.connect(_on_skill_pts_changed)
	_on_skill_pts_changed(player.skill_pts)

func _on_gold_changed(new_gold: int) -> void:
	gold.text = str(new_gold)

func _on_level_changed(new_level: int) -> void:
	level.text = "lvl %d" % [new_level]
	
func _on_skill_pts_changed(new_skill_pts: int) -> void:
	skillpts.text = str(new_skill_pts)
	
