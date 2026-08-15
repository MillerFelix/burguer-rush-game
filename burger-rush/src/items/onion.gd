class_name Onion
extends Item

enum OnionType {
	NORMAL,
	RED
}

@export var onion_type: OnionType = OnionType.NORMAL
@export var is_grilled: bool = false

const COLOR_NORMAL: Color = Color(0.95, 0.93, 0.82, 1.0)
const COLOR_RED: Color = Color(0.68, 0.15, 0.38, 1.0)
const COLOR_GRILLED: Color = Color(0.72, 0.55, 0.32, 1.0)

func _ready() -> void:
	if onion_type == OnionType.RED:
		item_id = "red_onion"
		prompt_text = "E — Pegar Cebola Roxa"
		display_name = "Cebola Roxa"
	else:
		item_id = "onion"
		prompt_text = "E — Pegar Cebola Normal"
		display_name = "Cebola Normal"

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
	var tex_path = "res://assets/textures/veg_red_onion.png" if onion_type == OnionType.RED else "res://assets/textures/veg_onion.png"
	var tex = load(tex_path) as Texture2D
	var norm = load("res://assets/textures/veg_normal.png") as Texture2D

	var mat = StandardMaterial3D.new()
	if tex:
		mat.albedo_texture = tex
	else:
		mat.albedo_color = COLOR_RED if onion_type == OnionType.RED else COLOR_NORMAL
	if norm:
		mat.normal_enabled = true
		mat.normal_texture = norm
		mat.normal_scale = 0.4
	mat.roughness = 0.4

	_apply_material_recursive(self, mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)
