class_name Onion
extends Item

enum OnionType {
	NORMAL,
	RED
}

@export var onion_type: OnionType = OnionType.NORMAL
@export var is_grilled: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D if has_node("MeshInstance3D") else null

const COLOR_NORMAL: Color = Color(0.95, 0.93, 0.82, 1.0)
const COLOR_RED: Color = Color(0.68, 0.15, 0.38, 1.0)
const COLOR_GRILLED: Color = Color(0.72, 0.55, 0.32, 1.0)

func _ready() -> void:
	if onion_type == OnionType.RED:
		item_id = "red_onion"
		prompt_text = "E — Pegar Cebola Roxa"
	else:
		item_id = "onion"
		prompt_text = "E — Pegar Cebola Normal"

	item_type = "ingredient"
	_update_visuals()

func get_ingredient_key() -> String:
	if onion_type == OnionType.RED:
		return "red_onion"
	return "onion"

func get_display_name() -> String:
	if onion_type == OnionType.RED:
		return "Cebola Roxa"
	return "Cebola Grelhada" if is_grilled else "Cebola Normal"

func _update_visuals() -> void:
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not mesh_instance:
		return

	var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_instance.material_override = mat

	if onion_type == OnionType.RED:
		mat.albedo_color = COLOR_RED
	elif is_grilled:
		mat.albedo_color = COLOR_GRILLED
	else:
		mat.albedo_color = COLOR_NORMAL
	mat.roughness = 0.6
