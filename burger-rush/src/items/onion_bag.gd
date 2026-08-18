class_name OnionBag
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

@export var state: State = State.RAW

func _init() -> void:
	item_id = "onion_rings_raw"
	display_name = "Saco de Cebola"
	item_type = "ingredient"

func _ready() -> void:
	item_id = "onion_rings_raw"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func get_display_name() -> String:
	if state == State.RAW:
		return "Saco de Cebola"
	return display_name

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD or is_held:
		return ""
	if state == State.RAW:
		return "🖱️ [Clique] Pegar Saco de Cebola"
	return "🖱️ [Clique] Pegar %s" % display_name

func _update_visuals() -> void:
	match state:
		State.RAW:
			display_name = "Saco de Cebola"
			prompt_text = "🖱️ [Clique] Pegar Saco de Cebola"
			item_id = "onion_rings_raw"
		State.COOKING:
			display_name = "Cebola Fritando"
			prompt_text = "Cebola Fritando"
			item_id = "onion_rings_cooking"
		State.COOKED:
			display_name = "Porção de Cebola Frita"
			prompt_text = "🖱️ [Clique] Pegar Cebola Frita"
			item_id = "onion_rings"
		State.BURNT:
			display_name = "Cebola Queimada"
			prompt_text = "🗑️ [Clique] Pegar Cebola Queimada"
			item_id = "onion_rings_burnt"

	var mesh_bag = get_node_or_null("MeshBag")
	var mesh_rings = get_node_or_null("MeshRings")

	if mesh_bag and mesh_rings:
		mesh_bag.visible = (state == State.RAW)
		mesh_rings.visible = (state != State.RAW)

		if state != State.RAW:
			var mat = StandardMaterial3D.new()
			if state == State.COOKED:
				mat.albedo_color = Color(0.95, 0.72, 0.20, 1.0)
			elif state == State.COOKING:
				mat.albedo_color = Color(0.92, 0.85, 0.45, 1.0)
			else:
				mat.albedo_color = Color(0.15, 0.12, 0.10, 1.0)
			mat.roughness = 0.5
			mesh_rings.material_override = mat

func get_ingredient_key() -> String:
	match state:
		State.RAW:
			return "onion_rings:raw"
		State.COOKING:
			return "onion_rings:cooking"
		State.COOKED:
			return "onion_rings:cooked"
		State.BURNT:
			return "onion_rings:burnt"
		_:
			return "onion_rings"
