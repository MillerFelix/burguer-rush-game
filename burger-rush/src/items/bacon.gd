class_name Bacon
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

@export var state: State = State.RAW
@export var cooking_progress: float = 0.0

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var mesh_raw_strip: Node3D = get_node_or_null("VisualRoot/BaconRawStrip")
@onready var mesh_cooked_strips: Node3D = get_node_or_null("VisualRoot/BaconCookedStrips")

var TEX_BACON_RAW = load("res://assets/textures/bacon_strip_raw.png")
var TEX_BACON_COOKED = load("res://assets/textures/bacon_strip_cooked.png")

func _ready() -> void:
	item_id = "bacon"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func get_ingredient_key() -> String:
	match state:
		State.RAW:
			return "bacon:raw"
		State.COOKING:
			return "bacon:cooking"
		State.COOKED:
			return "bacon"
		State.BURNT:
			return "bacon:burnt"
		_:
			return "bacon"

func get_display_name() -> String:
	match state:
		State.RAW:
			return "Tirinha de Bacon (Crua)"
		State.COOKING:
			return "Bacon Fritando (%d%%)" % int(cooking_progress) if cooking_progress > 0.0 else "Bacon (Fritando na Chapa)"
		State.COOKED:
			return "Bacon Crocante (Pronto)"
		State.BURNT:
			return "Bacon Queimado"
		_:
			return "Bacon"

func get_interaction_prompt(player: Node = null) -> String:
	if is_held or location == ItemLocation.PLAYER_HAND:
		return ""
	if player and player.get("held_item") != null:
		return ""
	match state:
		State.RAW:
			return "🖱️ Pegar Tirinha de Bacon Crua"
		State.COOKING:
			return "🥓 Bacon Fritando (%d%%)" % int(cooking_progress) if cooking_progress > 0.0 else "🥓 Bacon Fritando"
		State.COOKED:
			return "🥓 [Clique] Pegar Bacon Crocante Pronto"
		State.BURNT:
			return "🗑️ Pegar Bacon Queimado"
		_:
			return "🖱️ Pegar Bacon"

func _update_visuals() -> void:
	if not visual_root:
		visual_root = get_node_or_null("VisualRoot")
	if not mesh_raw_strip:
		mesh_raw_strip = get_node_or_null("VisualRoot/BaconRawStrip")
	if not mesh_cooked_strips:
		mesh_cooked_strips = get_node_or_null("VisualRoot/BaconCookedStrips")

	if not visual_root:
		return

	match state:
		State.RAW:
			if mesh_raw_strip:
				mesh_raw_strip.visible = true
				_apply_strip_material(mesh_raw_strip, TEX_BACON_RAW, Color(1.0, 1.0, 1.0, 1.0), 0.40, 0.25)
			if mesh_cooked_strips:
				mesh_cooked_strips.visible = false
		State.COOKING:
			if mesh_raw_strip:
				mesh_raw_strip.visible = false
			if mesh_cooked_strips:
				mesh_cooked_strips.visible = true
				_apply_strip_material(mesh_cooked_strips, TEX_BACON_RAW, Color(0.92, 0.75, 0.70, 1.0), 0.35, 0.35)
		State.COOKED:
			if mesh_raw_strip:
				mesh_raw_strip.visible = false
			if mesh_cooked_strips:
				mesh_cooked_strips.visible = true
				_apply_strip_material(mesh_cooked_strips, TEX_BACON_COOKED, Color(1.0, 1.0, 1.0, 1.0), 0.45, 0.30)
		State.BURNT:
			if mesh_raw_strip:
				mesh_raw_strip.visible = false
			if mesh_cooked_strips:
				mesh_cooked_strips.visible = true
				_apply_strip_material(mesh_cooked_strips, TEX_BACON_COOKED, Color(0.18, 0.14, 0.12, 1.0), 0.95, 0.05)

func _apply_strip_material(root_node: Node, tex: Texture2D, albedo_col: Color, rough_val: float, rim_val: float) -> void:
	if not root_node:
		return
	for m in _get_all_meshes(root_node):
		var mat = m.material_override as StandardMaterial3D
		if not mat:
			mat = StandardMaterial3D.new()
			m.material_override = mat
		mat.albedo_texture = tex
		mat.albedo_color = albedo_col
		mat.roughness = rough_val
		mat.rim_enabled = true
		mat.rim = rim_val
		mat.uv1_scale = Vector3(1.0, 1.0, 1.0)

func _get_all_meshes(node: Node) -> Array[MeshInstance3D]:
	var res: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		res.append(node as MeshInstance3D)
	for c in node.get_children():
		res.append_array(_get_all_meshes(c))
	return res
