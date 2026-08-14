class_name Potato
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

@export var state: State = State.RAW
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	item_id = "potato"
	display_name = "Batata"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func _update_visuals() -> void:
	if not mesh_instance:
		return

	var mat = StandardMaterial3D.new()
	match state:
		State.RAW:
			mat.albedo_color = Color(0.92, 0.85, 0.55, 1.0) # Amarelo claro da batata cortada
			display_name = "Batata Crua"
		State.COOKING:
			mat.albedo_color = Color(0.95, 0.75, 0.35, 1.0) # Dourando
			display_name = "Batata Fritando"
		State.COOKED:
			mat.albedo_color = Color(0.9, 0.62, 0.15, 1.0) # Dourada crocante
			display_name = "Batata Frita"
		State.BURNT:
			mat.albedo_color = Color(0.15, 0.12, 0.1, 1.0) # Queimada / Carbonizada
			display_name = "Batata Queimada"
	mesh_instance.material_override = mat

func get_ingredient_key() -> String:
	match state:
		State.RAW:
			return "potato:raw"
		State.COOKING:
			return "potato:cooking"
		State.COOKED:
			return "potato:cooked"
		State.BURNT:
			return "potato:burnt"
		_:
			return "potato"
