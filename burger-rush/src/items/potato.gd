class_name Potato
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

@export var state: State = State.RAW

func _ready() -> void:
	item_id = "potato_raw"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func _update_visuals() -> void:
	match state:
		State.RAW:
			display_name = "Saco de Batata Frita Congelada"
			prompt_text = "E — Pegar Saco de Batata"
			item_id = "potato_raw"
		State.COOKING:
			display_name = "Batata Fritando"
			prompt_text = "Batata Fritando"
			item_id = "potato_cooking"
		State.COOKED:
			display_name = "Porção de Batata Frita"
			prompt_text = "E — Pegar Batata Frita"
			item_id = "potato"
		State.BURNT:
			display_name = "Batata Queimada"
			prompt_text = "Batata Queimada"
			item_id = "potato_burnt"

	var mesh_bag = get_node_or_null("MeshBag")
	var mesh_fries = get_node_or_null("MeshFries")

	if mesh_bag and mesh_fries:
		mesh_bag.visible = (state == State.RAW)
		mesh_fries.visible = (state != State.RAW)

		if state != State.RAW:
			var mat = StandardMaterial3D.new()
			if state == State.COOKED:
				mat.albedo_color = Color(0.95, 0.72, 0.20, 1.0)
			elif state == State.COOKING:
				mat.albedo_color = Color(0.92, 0.85, 0.45, 1.0)
			else:
				mat.albedo_color = Color(0.15, 0.12, 0.10, 1.0)
			mat.roughness = 0.5
			mesh_fries.material_override = mat

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
