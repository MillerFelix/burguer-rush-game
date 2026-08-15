class_name Pickle
extends Item

func _ready() -> void:
	item_id = "pickle"
	display_name = "Picles"
	item_type = "ingredient"
	prompt_text = "E — Pegar Picles"

func get_ingredient_key() -> String:
	return "pickle"

func get_display_name() -> String:
	return "Picles"
