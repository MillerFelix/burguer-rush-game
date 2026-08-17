class_name Cheese
extends Item

# =============================================================================
# BURGER RUSH - FATIA DE QUEIJO COM SISTEMA DE COCÇÃO E DERRETIMENTO NA CHAPA
#
# Estados de Cocção (Idêntico ao sistema do Hambúrguer):
# 1. RAW (Cru / Fresco) — Fatia firme original.
# 2. FRYING (Fritando / Derretendo) — Amolecendo, bordas curvando e ganhando brilho.
# 3. READY (Pronto / Derretido) — Completamente derretido, fluido e brilhante.
# 4. BURNT (Queimado / Ressecado) — Passou do ponto, escurecido e carbonizado.
# =============================================================================

enum CheeseType {
	CHEDDAR,
	MOZZARELLA,
	PRATO
}

enum State {
	RAW,
	FRYING,
	READY,
	BURNT
}

const MELTED = State.READY

@export var cheese_type: CheeseType = CheeseType.CHEDDAR
@export var state: State = State.RAW
@export var cook_progress: float = 0.0 # 0.0% a 100.0%

@onready var mesh_root: Node = get_node_or_null("MeshInstance3D")

const TEX_MOZZARELLA = preload("res://assets/textures/cheese_mozzarella.png")
const TEX_CHEDDAR = preload("res://assets/textures/cheese_cheddar.png")
const TEX_PRATO = preload("res://assets/textures/cheese_prato.png")
const TEX_NORMAL = preload("res://assets/textures/cheese_normal.png")

func _ready() -> void:
	is_grillable = true
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

# Avança o progresso contínuo de cocção na chapa quente
func advance_cooking(delta_pct: float) -> void:
	if state == State.BURNT:
		return

	cook_progress = minf(120.0, cook_progress + delta_pct)

	if cook_progress >= 100.0:
		state = State.READY
	elif cook_progress > 0.0:
		state = State.FRYING
	else:
		state = State.RAW

	_update_visuals()

# Método de compatibilidade para processamento direto
func process_cooking(delta: float, grill_temp: float) -> void:
	if grill_temp < 90.0 or state == State.BURNT:
		return
	var heat_factor = clampf((grill_temp - 90.0) / 70.0, 0.5, 1.5)
	var delta_pct = (100.0 / 6.0) * delta * heat_factor
	advance_cooking(delta_pct)

func set_burnt() -> void:
	state = State.BURNT
	_update_visuals()

func is_grill_cookable() -> bool:
	return true

func is_cookable_on_grill() -> bool:
	return true

func is_melted() -> bool:
	return state == State.READY or (state == State.FRYING and cook_progress >= 70.0)

func is_ready() -> bool:
	return state == State.READY

func is_burnt() -> bool:
	return state == State.BURNT

func is_cooked() -> bool:
	return state == State.READY or state == State.RAW

func get_ingredient_key() -> String:
	if state == State.BURNT:
		return item_id + ":burnt"
	elif state == State.READY:
		return item_id + ":cooked"
	return item_id

func get_display_name() -> String:
	var base_nm = ""
	match cheese_type:
		CheeseType.MOZZARELLA: base_nm = "Queijo Muçarela"
		CheeseType.PRATO: base_nm = "Queijo Prato"
		_: base_nm = "Queijo Cheddar"

	match state:
		State.FRYING: return base_nm + " (Derretendo)"
		State.READY: return base_nm + " (Derretido)"
		State.BURNT: return base_nm + " (Queimado)"
		_: return base_nm

func _update_visuals() -> void:
	if not mesh_root:
		mesh_root = get_node_or_null("MeshInstance3D")
	if not mesh_root:
		return

	var target_tex: Texture2D = TEX_CHEDDAR
	var base_roughness: float = 0.42
	var base_color: Color = Color(1.0, 1.0, 1.0, 1.0)

	match cheese_type:
		CheeseType.MOZZARELLA:
			target_tex = TEX_MOZZARELLA
			base_roughness = 0.38
			base_color = Color(0.98, 0.98, 0.94, 1.0)
		CheeseType.PRATO:
			target_tex = TEX_PRATO
			base_roughness = 0.40
			base_color = Color(0.98, 0.88, 0.45, 1.0)
		_:
			target_tex = TEX_CHEDDAR
			base_roughness = 0.42
			base_color = Color(1.0, 0.72, 0.15, 1.0)

	# Fator de interpolação contínua da cocção (0.0 a 1.0)
	var t = clampf(cook_progress / 100.0, 0.0, 1.0)

	var target_roughness = lerpf(base_roughness, 0.08, t)
	var target_color = base_color.lerp(base_color.lightened(0.08), t)
	var target_clearcoat = lerpf(0.0, 1.0, t)
	var target_scale_y = lerpf(1.0, 0.50, t)
	var target_scale_xz = lerpf(1.0, 1.14, t)

	if state == State.BURNT:
		target_roughness = 0.88
		target_color = Color(0.18, 0.12, 0.08, 1.0) # Carbonizado escuro
		target_clearcoat = 0.0
		target_scale_y = 0.35
		target_scale_xz = 1.10

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
		mat.clearcoat_enabled = (target_clearcoat > 0.01)
		mat.clearcoat = target_clearcoat
		mat.clearcoat_roughness = 0.05
		mat.rim_enabled = (state != State.BURNT)
		mat.rim = 0.15
		mat.rim_tint = 0.40

	if mesh_root is Node3D:
		mesh_root.scale = Vector3(target_scale_xz, target_scale_y, target_scale_xz)

	# Curva suave e física das pontas/cantos conforme amolece na chapa quente
	var drop1 = mesh_root.get_node_or_null("CornerDrop1") as Node3D
	var drop2 = mesh_root.get_node_or_null("CornerDrop2") as Node3D
	var drop3 = mesh_root.get_node_or_null("CornerDrop3") as Node3D
	var drop4 = mesh_root.get_node_or_null("CornerDrop4") as Node3D

	var droop_angle = lerpf(deg_to_rad(15.0), deg_to_rad(42.0), t)
	if drop1: drop1.rotation.y = droop_angle * 0.5
	if drop2: drop2.rotation.y = -droop_angle * 0.5
	if drop3: drop3.rotation.y = droop_angle * 0.5
	if drop4: drop4.rotation.y = -droop_angle * 0.5

func _get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		result.append_array(_get_all_mesh_instances(child))
	return result
