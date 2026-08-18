class_name FriesPack
extends Item

@export var side_type: String = "fries"

func _init() -> void:
	_apply_side_type()

func _ready() -> void:
	_apply_side_type()

func set_side_type(new_type: String) -> void:
	side_type = new_type
	_apply_side_type()

func fill_with(food_type: String) -> void:
	if food_type == "onion" or food_type == "onion_rings":
		set_side_type("onion_rings")
	else:
		set_side_type("fries")

func _apply_side_type() -> void:
	if side_type == "onion_rings":
		item_id = "onion_rings"
		display_name = "Cebola Frita"
		item_type = "final_product"
		is_packaged = true
		prompt_text = "🖱️ [Clique] Pegar Cebola Frita"
	elif side_type == "empty" or side_type == "potato_box":
		item_id = "potato_box"
		display_name = "Embalagem de Batata"
		item_type = "packaging"
		is_packaged = false
		prompt_text = "🖱️ Pegar Embalagem de Batata"
	else:
		item_id = "fries"
		display_name = "Batata Frita"
		item_type = "final_product"
		is_packaged = true
		prompt_text = "🖱️ [Clique] Pegar Batata Frita"
	_update_mesh_visuals()

func _update_mesh_visuals() -> void:
	var mesh_root = get_node_or_null("MeshInstance3D")
	if mesh_root:
		var red_container = mesh_root.get_node_or_null("RedContainer")
		if red_container:
			red_container.visible = true

		var fries_node = mesh_root.get_node_or_null("FriesContent")
		var rings_node = mesh_root.get_node_or_null("OnionRingsContent")

		if side_type == "onion_rings":
			if fries_node:
				fries_node.visible = false
			if rings_node:
				rings_node.visible = true
		elif side_type == "empty" or side_type == "potato_box":
			if fries_node:
				fries_node.visible = false
			if rings_node:
				rings_node.visible = false
		else:
			if fries_node:
				fries_node.visible = true
			if rings_node:
				rings_node.visible = false

func get_display_name() -> String:
	return display_name
