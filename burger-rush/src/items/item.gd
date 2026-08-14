class_name Item
extends StaticBody3D

@export var item_id: String = "generic"
@export var prompt_text: String = "E — Pegar"

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		return ""
	return prompt_text

func interact(player: Node3D) -> void:
	if player.has_method("pick_up"):
		player.pick_up(self)

func on_picked_up() -> void:
	if collision_shape:
		collision_shape.disabled = true

func on_dropped() -> void:
	if collision_shape:
		collision_shape.disabled = false
