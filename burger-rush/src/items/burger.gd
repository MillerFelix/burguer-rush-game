class_name Burger
extends Item

func _ready() -> void:
	item_id = "burger"
	prompt_text = "E — Pegar Hambúrguer"

func get_display_name() -> String:
	return "Hambúrguer"
