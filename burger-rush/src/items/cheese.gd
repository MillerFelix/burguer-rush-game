class_name Cheese
extends Item

enum CheeseType {
	CHEDDAR,
	MOZZARELLA,
	PRATO
}

@export var cheese_type: CheeseType = CheeseType.CHEDDAR

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D if has_node("MeshInstance3D") else null

const COLOR_CHEDDAR: Color = Color(1.0, 0.68, 0.12, 1.0)
const COLOR_MOZZARELLA: Color = Color(0.98, 0.96, 0.86, 1.0)
const COLOR_PRATO: Color = Color(1.0, 0.86, 0.30, 1.0)

func _ready() -> void:
	match cheese_type:
		CheeseType.MOZZARELLA:
			item_id = "cheese_mozzarella"
			prompt_text = "E — Pegar Queijo Muçarela"
		CheeseType.PRATO:
			item_id = "cheese_prato"
			prompt_text = "E — Pegar Queijo Prato"
		_:
			item_id = "cheese_cheddar"
			prompt_text = "E — Pegar Queijo Cheddar"

	item_type = "ingredient"
	_update_visuals()

func get_ingredient_key() -> String:
	return item_id

func get_display_name() -> String:
	match cheese_type:
		CheeseType.MOZZARELLA:
			return "Queijo Muçarela"
		CheeseType.PRATO:
			return "Queijo Prato"
		_:
			return "Queijo Cheddar"

func _update_visuals() -> void:
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not mesh_instance:
		return

	var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_instance.material_override = mat

	match cheese_type:
		CheeseType.MOZZARELLA:
			mat.albedo_color = COLOR_MOZZARELLA
		CheeseType.PRATO:
			mat.albedo_color = COLOR_PRATO
		_:
			mat.albedo_color = COLOR_CHEDDAR
	mat.roughness = 0.5
