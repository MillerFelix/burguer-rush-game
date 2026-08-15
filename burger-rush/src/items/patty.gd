class_name Patty
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

enum MeatType {
	BEEF,
	CHICKEN
}

@export var state: State = State.RAW
@export var meat_type: MeatType = MeatType.BEEF

@onready var mesh_root: Node = get_node_or_null("MeshInstance3D")

const TEX_BEEF_RAW = preload("res://assets/textures/meat_patty_beef_raw.png")
const TEX_BEEF_COOKED = preload("res://assets/textures/meat_patty_beef_cooked.png")
const TEX_CHICKEN_RAW = preload("res://assets/textures/meat_patty_chicken_raw.png")
const TEX_CHICKEN_COOKED = preload("res://assets/textures/meat_patty_chicken_cooked.png")
const TEX_BURNT = preload("res://assets/textures/meat_patty_burnt.png")
const TEX_NORMAL_RAW = preload("res://assets/textures/meat_patty_normal.png")
const TEX_NORMAL_COOKED = preload("res://assets/textures/meat_patty_cooked_normal.png")

func _ready() -> void:
	if meat_type == MeatType.CHICKEN:
		item_id = "patty_chicken"
	else:
		item_id = "patty_beef"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func get_ingredient_key() -> String:
	var prefix = "patty_chicken" if meat_type == MeatType.CHICKEN else "patty_beef"
	match state:
		State.RAW:
			return prefix + ":raw"
		State.COOKING:
			return prefix + ":cooking"
		State.COOKED:
			return prefix + ":cooked"
		State.BURNT:
			return prefix + ":burnt"
		_:
			return prefix

func get_display_name() -> String:
	var meat_name = "Hambúrguer de Frango" if meat_type == MeatType.CHICKEN else "Carne Bovina"
	match state:
		State.RAW:
			return meat_name + " (Cru)"
		State.COOKING:
			return meat_name + " (Cozinhando)"
		State.COOKED:
			return meat_name + " (Pronto)"
		State.BURNT:
			return meat_name + " (Queimado)"
		_:
			return meat_name

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		return ""
	var meat_name = "Frango" if meat_type == MeatType.CHICKEN else "Carne"
	match state:
		State.RAW:
			return "E — Pegar %s Cru" % meat_name
		State.COOKING:
			return "E — Pegar %s (Em Preparo)" % meat_name
		State.COOKED:
			return "E — Pegar %s Pronto" % meat_name
		State.BURNT:
			return "E — Pegar %s Queimado" % meat_name
		_:
			return "E — Pegar %s" % meat_name

func _update_visuals() -> void:
	if not mesh_root:
		mesh_root = get_node_or_null("MeshInstance3D")
	if not mesh_root:
		return

	var target_tex: Texture2D = null
	var target_norm: Texture2D = TEX_NORMAL_RAW
	var target_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	var target_roughness: float = 0.62
	var target_norm_scale: float = 0.60

	var is_chick = (meat_type == MeatType.CHICKEN)

	match state:
		State.RAW:
			target_tex = TEX_CHICKEN_RAW if is_chick else TEX_BEEF_RAW
			target_norm = TEX_NORMAL_RAW
			target_color = Color(1.0, 1.0, 1.0, 1.0)
			target_roughness = 0.62
			target_norm_scale = 0.60
		State.COOKING:
			target_tex = TEX_CHICKEN_RAW if is_chick else TEX_BEEF_RAW
			target_norm = TEX_NORMAL_RAW
			target_color = Color(0.88, 0.76, 0.65, 1.0) if is_chick else Color(0.80, 0.60, 0.50, 1.0)
			target_roughness = 0.55
			target_norm_scale = 0.55
		State.COOKED:
			target_tex = TEX_CHICKEN_COOKED if is_chick else TEX_BEEF_COOKED
			target_norm = TEX_NORMAL_COOKED
			target_color = Color(1.0, 1.0, 1.0, 1.0)
			target_roughness = 0.45
			target_norm_scale = 0.75
		State.BURNT:
			target_tex = TEX_BURNT
			target_norm = TEX_NORMAL_COOKED
			target_color = Color(0.92, 0.92, 0.92, 1.0)
			target_roughness = 0.95
			target_norm_scale = 0.85

	var meshes = _get_all_mesh_instances(mesh_root)
	for mesh in meshes:
		var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if not mat:
			mat = StandardMaterial3D.new()
			mesh.material_override = mat
		mat.albedo_texture = target_tex
		mat.albedo_color = target_color
		mat.normal_enabled = true
		mat.normal_texture = target_norm
		mat.normal_scale = target_norm_scale
		mat.roughness = target_roughness
		mat.uv1_scale = Vector3(2.0, 2.0, 2.0)

func _get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		result.append_array(_get_all_mesh_instances(child))
	return result
