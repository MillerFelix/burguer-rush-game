class_name Egg
extends Item

enum State {
	RAW,
	CRACKED,
	COOKING,
	COOKED,
	DRYING,
	BURNT
}

@export var state: State = State.RAW

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var mesh_whole_egg: Node3D = get_node_or_null("VisualRoot/MeshWholeEgg")
@onready var fried_egg_root: Node3D = get_node_or_null("VisualRoot/FriedEggRoot")
@onready var egg_white_mesh: MeshInstance3D = get_node_or_null("VisualRoot/FriedEggRoot/EggWhite")
@onready var egg_yolk_mesh: MeshInstance3D = get_node_or_null("VisualRoot/FriedEggRoot/EggYolk")
@onready var egg_crisp_edge: MeshInstance3D = get_node_or_null("VisualRoot/FriedEggRoot/CrispEdge")

func _ready() -> void:
	item_id = "egg"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func get_ingredient_key() -> String:
	match state:
		State.RAW:
			return "egg:raw"
		State.CRACKED:
			return "egg:cooking"
		State.COOKING:
			return "egg:cooking"
		State.COOKED:
			return "egg"
		State.DRYING:
			return "egg:drying"
		State.BURNT:
			return "egg:burnt"
		_:
			return "egg"

func get_display_name() -> String:
	match state:
		State.RAW:
			return "Ovo Cru (Inteiro)"
		State.CRACKED:
			return "Ovo Quebrado (Na Chapa)"
		State.COOKING:
			return "Ovo Fritando"
		State.COOKED:
			return "Ovo Frito (Pronto)"
		State.DRYING:
			return "Ovo Ressecando (Passando do Ponto)"
		State.BURNT:
			return "Ovo Queimado"
		_:
			return "Ovo"

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		return ""
	match state:
		State.RAW:
			return "🖱️ Pegar Ovo Cru"
		State.CRACKED, State.COOKING:
			return "🖱️ Pegar Ovo (Em Fritura)"
		State.COOKED:
			return "🖱️ Pegar Ovo Frito Pronto"
		State.DRYING:
			return "🖱️ Pegar Ovo Ressecado"
		State.BURNT:
			return "🖱️ Pegar Ovo Queimado"
		_:
			return "🖱️ Pegar Ovo"

func _update_visuals() -> void:
	if not visual_root:
		visual_root = get_node_or_null("VisualRoot")
	if not mesh_whole_egg:
		mesh_whole_egg = get_node_or_null("VisualRoot/MeshWholeEgg")
	if not fried_egg_root:
		fried_egg_root = get_node_or_null("VisualRoot/FriedEggRoot")
	if not egg_white_mesh:
		egg_white_mesh = get_node_or_null("VisualRoot/FriedEggRoot/EggWhite")
	if not egg_yolk_mesh:
		egg_yolk_mesh = get_node_or_null("VisualRoot/FriedEggRoot/EggYolk")
	if not egg_crisp_edge:
		egg_crisp_edge = get_node_or_null("VisualRoot/FriedEggRoot/CrispEdge")

	if not visual_root:
		return

	if state == State.RAW:
		if mesh_whole_egg:
			mesh_whole_egg.visible = true
		if fried_egg_root:
			fried_egg_root.visible = false
		return

	# Para todos os estados na grelha/frito, o ovo inteiro some e a forma aberta aparece
	if mesh_whole_egg:
		mesh_whole_egg.visible = false
	if fried_egg_root:
		fried_egg_root.visible = true

	var white_mat = _get_or_create_material(egg_white_mesh)
	var yolk_mat = _get_or_create_material(egg_yolk_mesh)
	var edge_mat = _get_or_create_material(egg_crisp_edge)

	match state:
		State.CRACKED:
			# Clara translúcida crua, gema brilhante crua
			if white_mat:
				white_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				white_mat.albedo_color = Color(0.92, 0.95, 0.98, 0.55)
				white_mat.roughness = 0.15
			if yolk_mat:
				yolk_mat.albedo_color = Color(0.98, 0.68, 0.08, 1.0)
				yolk_mat.roughness = 0.2
			if edge_mat:
				edge_mat.visible = false if egg_crisp_edge else false
		State.COOKING:
			# Clara começando a opacificar, gema cozinhando
			if white_mat:
				white_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				white_mat.albedo_color = Color(0.96, 0.97, 0.98, 0.85)
				white_mat.roughness = 0.35
			if yolk_mat:
				yolk_mat.albedo_color = Color(0.98, 0.72, 0.10, 1.0)
				yolk_mat.roughness = 0.3
			if edge_mat and egg_crisp_edge:
				egg_crisp_edge.visible = true
				edge_mat.albedo_color = Color(0.90, 0.82, 0.65, 0.7)
				edge_mat.roughness = 0.5
		State.COOKED:
			# Clara branca opaca cozida com bordas douradas, gema perfeita
			if white_mat:
				white_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				white_mat.albedo_color = Color(0.98, 0.98, 0.97, 1.0)
				white_mat.roughness = 0.45
			if yolk_mat:
				yolk_mat.albedo_color = Color(1.0, 0.75, 0.05, 1.0)
				yolk_mat.roughness = 0.35
				yolk_mat.rim_enabled = true
				yolk_mat.rim = 0.3
			if edge_mat and egg_crisp_edge:
				egg_crisp_edge.visible = true
				edge_mat.albedo_color = Color(0.82, 0.58, 0.24, 1.0)
				edge_mat.roughness = 0.6
		State.DRYING:
			# Clara ressecada, bordas tostadas escuras, gema fosca
			if white_mat:
				white_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				white_mat.albedo_color = Color(0.88, 0.82, 0.72, 1.0)
				white_mat.roughness = 0.80
			if yolk_mat:
				yolk_mat.albedo_color = Color(0.85, 0.55, 0.10, 1.0)
				yolk_mat.roughness = 0.85
			if edge_mat and egg_crisp_edge:
				egg_crisp_edge.visible = true
				edge_mat.albedo_color = Color(0.55, 0.30, 0.12, 1.0)
				edge_mat.roughness = 0.9
		State.BURNT:
			# Clara e bordas queimadas pretas, gema destruída
			if white_mat:
				white_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				white_mat.albedo_color = Color(0.20, 0.18, 0.16, 1.0)
				white_mat.roughness = 0.95
			if yolk_mat:
				yolk_mat.albedo_color = Color(0.28, 0.20, 0.10, 1.0)
				yolk_mat.roughness = 0.95
			if edge_mat and egg_crisp_edge:
				egg_crisp_edge.visible = true
				edge_mat.albedo_color = Color(0.12, 0.10, 0.08, 1.0)
				edge_mat.roughness = 0.98

func _get_or_create_material(mesh_node: MeshInstance3D) -> StandardMaterial3D:
	if not mesh_node:
		return null
	var mat = mesh_node.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_node.material_override = mat
	return mat
