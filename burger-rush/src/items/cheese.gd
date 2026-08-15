class_name Cheese
extends Item

enum CheeseType {
	CHEDDAR,
	MOZZARELLA,
	PRATO
}

@export var cheese_type: CheeseType = CheeseType.CHEDDAR

@onready var mesh_root: Node = get_node_or_null("MeshInstance3D")

const TEX_MOZZARELLA = preload("res://assets/textures/cheese_mozzarella.png")
const TEX_CHEDDAR = preload("res://assets/textures/cheese_cheddar.png")
const TEX_PRATO = preload("res://assets/textures/cheese_prato.png")
const TEX_NORMAL = preload("res://assets/textures/cheese_normal.png")

func _ready() -> void:
	match cheese_type:
		CheeseType.MOZZARELLA:
			item_id = "cheese_mozzarella"
			display_name = "Queijo Muçarela"
			prompt_text = "E — Pegar Queijo Muçarela"
		CheeseType.PRATO:
			item_id = "cheese_prato"
			display_name = "Queijo Prato"
			prompt_text = "E — Pegar Queijo Prato"
		_:
			item_id = "cheese_cheddar"
			display_name = "Queijo Cheddar"
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
	if not mesh_root:
		mesh_root = get_node_or_null("MeshInstance3D")
	if not mesh_root:
		return

	var target_tex: Texture2D = TEX_CHEDDAR
	var target_roughness: float = 0.42
	var target_color: Color = Color(1.0, 1.0, 1.0, 1.0)

	match cheese_type:
		CheeseType.MOZZARELLA:
			target_tex = TEX_MOZZARELLA
			target_roughness = 0.38
		CheeseType.PRATO:
			target_tex = TEX_PRATO
			target_roughness = 0.40
		_:
			target_tex = TEX_CHEDDAR
			target_roughness = 0.42

	var meshes = _get_all_mesh_instances(mesh_root)
	for mesh in meshes:
		var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if not mat:
			mat = StandardMaterial3D.new()
			mesh.material_override = mat
		mat.albedo_texture = target_tex
		mat.albedo_color = target_color
		mat.normal_enabled = true
		mat.normal_texture = TEX_NORMAL
		mat.normal_scale = 0.50
		mat.roughness = target_roughness
		mat.rim_enabled = true
		mat.rim = 0.15
		mat.rim_tint = 0.40

func _get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		result.append_array(_get_all_mesh_instances(child))
	return result
