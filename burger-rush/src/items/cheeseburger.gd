class_name Cheeseburger
extends Item

func _ready() -> void:
	item_id = "cheeseburger"
	prompt_text = "E — Pegar Cheeseburger"

func get_display_name() -> String:
	return "Cheeseburger"
