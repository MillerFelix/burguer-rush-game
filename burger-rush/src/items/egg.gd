class_name Egg
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

@export var state: State = State.COOKED

func _ready() -> void:
	item_id = "egg"
	display_name = "Ovo"
	item_type = "ingredient"
	prompt_text = "E — Pegar Ovo"

func get_ingredient_key() -> String:
	return "egg"

func get_display_name() -> String:
	match state:
		State.RAW:
			return "Ovo Cru"
		State.COOKING:
			return "Ovo (Fritando)"
		State.COOKED:
			return "Ovo Frito"
		State.BURNT:
			return "Ovo Queimado"
		_:
			return "Ovo"
