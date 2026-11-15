# Skill Tree Kit for Godot 4

Skill and talent trees for your game: **ranks**, **requirements drawn as lines**, **row gates** ("spend 5 points to open the next row"), **stat bonuses**, **active abilities**, **exclusive choices** ("choose A or B"), **unlearn** and **reset** (with an optional item cost), a grid or **free placement with curved links**, and a **ready-to-use tree view** that works with the mouse, the keyboard and a gamepad.

**Pay what you want, from $0.** Code under MIT. Made by Benny, entirely with AI tools. Official page, downloads and playable web demo: https://banc-essai.site-testeurs.workers.dev/skill-tree-kit/
More kits, and our game prototypes waiting for testers: https://banc-essai.site-testeurs.workers.dev/

- **Trees as resources**: skills on a grid, ranks, cost per rank, requirements (`{&"cleave": 1}`), effects per rank (`{&"damage": 2.0}`), descriptions with the value filled in ("+4 damage").
- **Rules that never break**: learning checks points, requirements and row gates; unlearning refuses what would leave another skill or row without what it needs. Points are always conserved.
- **Bonuses**: `get_bonus(&"damage")` sums every learned rank across all trees; plug it into your stats.
- **Active abilities**: a skill can unlock an ability (`skill.ability = &"whirlwind"`, at rank `ability_rank`). `ability_unlocked` / `ability_locked` tell your game when to add it to the hotbar or take it away; `has_ability()`, `get_abilities()`.
- **Exclusive branches**: skills sharing an `exclusive_group` are a choice. Taking one locks the others (`EXCLUSIVE_TAKEN`), unlearning it or a reset frees the choice. The view joins them with a dashed line and greys out the side not taken.
- **Free placement**: `skill.place(Vector2(1.5, 0.5))` puts a skill anywhere (grid units); the view then draws curved links (`line_style`: Auto, Elbow, Curve, Straight). Grid trees made with 1.0 look and load exactly as before.
- **Reset** a tree or everything, free or for a price in items (gold, a respec potion), paid in one Inventory Kit transaction.
- **TKTreeView**: one tab per tree, skills on their grid with lines (gold when met), ranks, details with current and next rank and what is missing, Learn / Unlearn / Reset. Icons can come from your item database (the 120 Inventory Kit icons in 4 art styles) or any texture.
- Saves (`to_data()` / `load_data()`; ranks above a lowered max rank are refunded, and so is the extra side of a choice that became exclusive in an update; 1.0 saves load unchanged), translatable texts, 19 automated tests.

## Install

1. Copy `addons/inventory_kit/` and `addons/skill_tree_kit/` into your project's `addons/` folder (skip Inventory Kit if you already have it).
2. Open `demo/skills/skills_demo.tscn`: a Warrior tree and a Survivor tree.

## Five-minute setup

```gdscript
var warrior := TKSkillTree.new()            # save it as a .tres
warrior.points_per_row = 3                   # 3 points per row to open the next one
warrior.add(TKSkill.make(&"blade", "Blade Training", Vector2i(0, 0), 3, {&"damage": 2.0}, {}, &"sword"))
warrior.add(TKSkill.make(&"cleave", "Cleave", Vector2i(0, 1), 1, {&"damage": 5.0}, {&"blade": 2}, &"axe"))

var skills := TKSkills.new()
skills.trees = [warrior]
skills.reset_cost = {&"gold_coins": 50}      # optional
add_child(skills)

skills.points += 1                           # on level up
var result := skills.learn(&"blade")
if not result.ok:
	status.text = TKText.result_message(result)
var damage := base_damage + skills.get_bonus(&"damage")
```

Abilities, choices and free placement:

```gdscript
var whirlwind := warrior.add(TKSkill.make(&"whirlwind", "Whirlwind", Vector2i(0, 3), 1, {}, {&"cleave": 1}, &"dagger"))
whirlwind.ability = &"whirlwind"             # an active ability, not just numbers
whirlwind.exclusive_group = &"style"         # same group = choose one
var bulwark := warrior.add(TKSkill.make(&"bulwark", "Bulwark", Vector2i(2, 3), 1, {}, {}, &"shield"))
bulwark.exclusive_group = &"style"
bulwark.place(Vector2(2.4, 3.3))             # free position in grid units; the row (3) still counts for row gates

skills.ability_unlocked.connect(func(ability, skill): hotbar.add(ability))
skills.ability_locked.connect(func(ability, skill): hotbar.remove(ability))
```

UI:

```gdscript
var view := TKTreeView.new()
view.skills = skills
view.bag = bag.container                     # pays the reset
view.skin = preload("res://addons/inventory_kit/art/painted/painted_skin.tres")
view.theme = preload("res://addons/inventory_kit/art/painted/painted_theme.tres")
```

Controls: click a skill to select it, click it again (or Enter / A, or Learn) to learn a rank; arrows / d-pad move between skills; Q / E or LB / RB switch trees (`tk_previous_tab` / `tk_next_tab` in your Input Map to rebind); Escape / B emits `close_requested`.

## Classes

| Class | Role |
|---|---|
| `TKSkill`, `TKSkillTree` | Skills and trees as resources (ability, exclusive group, free position), validation (duplicate cells, unknown or upward requirements, exclusive skills requiring each other) |
| `TKSkills` | Points, ranks, `learn()`, `unlearn()`, `reset_tree()`, `reset_all()`, `get_bonus()`, `has_ability()`, `get_abilities()`, `get_exclusive_choice()`, `is_excluded()`, save; signals `skill_learned`, `skill_unlearned`, `ability_unlocked`, `ability_locked`, `points_changed`, `changed` |
| `TKResult`, `TKText` | Outcome codes (`REQUIREMENT_MISSING` with `missing`, `ROW_LOCKED`, `NEEDED_BY_OTHERS`, `CANNOT_PAY`, `EXCLUSIVE_TAKEN` with `excluded_by`...) and player texts |
| `TKTreeView` | The tree screen (grid or free placement, `line_style`) |

## Running the tests

```bash
godot --headless --path <project> --import
godot --headless --path <project> -s res://tests/skill_tree_kit/run_tests.gd
```

## Licenses

- Source code: MIT (`LICENSE.txt`).
- The item art in `addons/inventory_kit/art/` is covered by Inventory Kit's `LICENSE_ART.txt`: free to use in your games, please do not re-upload it; link to the official page instead.
- Found a bug or want a feature? Tell us: https://banc-essai.site-testeurs.workers.dev/
