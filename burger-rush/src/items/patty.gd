class_name Patty
extends Item

# ================================================================
# HAMBÚRGUER COM COCÇÃO REAL EM DOIS LADOS (VISUAL E FÍSICA APRIMORADOS)
#
# Cada lado possui material e evolução visual independente.
# O flip com a espátula mantém o hambúrguer perfeitamente apoiado
# sobre a chapa, sem afundar ou atravessar a superfície.
# ================================================================

enum State {
	RAW,
	COOKING_SIDE_1,
	READY_SIDE_1,
	COOKING_SIDE_2,
	COOKED,
	BURNT
}

enum MeatType {
	BEEF,
	CHICKEN
}

@export var state: State = State.RAW
@export var meat_type: MeatType = MeatType.BEEF

@export var side_a_cooked: float = 0.0 # 0.0% a 100.0%
@export var side_b_cooked: float = 0.0 # 0.0% a 100.0%
@export var current_side_cooking: int = 1 # 1 = Lado A contra a chapa, 2 = Lado B contra a chapa
@export var is_flipped: bool = false

@onready var visual_model: Node3D = get_node_or_null("VisualModel")
@onready var side_a_mesh: MeshInstance3D = get_node_or_null("VisualModel/SideAFace")
@onready var side_b_mesh: MeshInstance3D = get_node_or_null("VisualModel/SideBFace")
@onready var body_mesh: MeshInstance3D = get_node_or_null("VisualModel/BodyMesh")

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

# Avança o cozimento do lado que está em contato com a chapa quente
func advance_cooking(delta_pct: float) -> void:
	if state == State.BURNT:
		return

	if current_side_cooking == 1:
		side_a_cooked = minf(120.0, side_a_cooked + delta_pct)
		if side_a_cooked >= 100.0 and side_b_cooked < 100.0:
			state = State.READY_SIDE_1
		elif side_a_cooked >= 100.0 and side_b_cooked >= 100.0:
			state = State.COOKED
		else:
			state = State.COOKING_SIDE_1
	else:
		side_b_cooked = minf(120.0, side_b_cooked + delta_pct)
		if side_a_cooked >= 100.0 and side_b_cooked >= 100.0:
			state = State.COOKED
		else:
			state = State.COOKING_SIDE_2

	_update_visuals()

# Executa o flip com a espátula mantendo a carne apoiada na chapa
func flip() -> void:
	is_flipped = !is_flipped
	current_side_cooking = 2 if is_flipped else 1

	if side_a_cooked >= 100.0 and side_b_cooked >= 100.0:
		state = State.COOKED
	elif is_flipped and side_b_cooked < 100.0:
		state = State.COOKING_SIDE_2
	elif not is_flipped and side_a_cooked < 100.0:
		state = State.COOKING_SIDE_1

	# Animação física suave de virada em arco sem afundar na chapa
	if visual_model:
		var target_rot_z = PI if is_flipped else 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		# Sobe ligeiramente no ar e desce suavemente de volta à chapa
		tween.tween_property(visual_model, "position:y", 0.05, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_model, "rotation:z", target_rot_z, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(visual_model, "position:y", 0.017, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	_update_visuals()

func set_burnt() -> void:
	state = State.BURNT
	_update_visuals()

func is_fully_cooked() -> bool:
	return (side_a_cooked >= 100.0 and side_b_cooked >= 100.0) or state == State.COOKED

func get_ingredient_key() -> String:
	var prefix = "patty_chicken" if meat_type == MeatType.CHICKEN else "patty_beef"
	match state:
		State.RAW, State.COOKING_SIDE_1:
			return prefix + ":raw"
		State.READY_SIDE_1, State.COOKING_SIDE_2:
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
		State.COOKING_SIDE_1:
			return meat_name + " (Lado 1: %d%%)" % int(side_a_cooked)
		State.READY_SIDE_1:
			return meat_name + " (Lado 1 Pronto — Virar!)"
		State.COOKING_SIDE_2:
			return meat_name + " (Lado 2: %d%%)" % int(side_b_cooked)
		State.COOKED:
			return meat_name + " (Pronto / 2 Lados Grelhados)"
		State.BURNT:
			return meat_name + " (Queimado)"
		_:
			return meat_name

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD or is_held:
		return ""

	if player and player.get("held_item") != null:
		return ""

	var tool_slot = player.get("active_tool_slot") if player else 3
	var meat_name = "Hambúrguer" if meat_type == MeatType.BEEF else "Frango"

	# Se estiver com a Espátula (Slot 1)
	if tool_slot == 1:
		match state:
			State.RAW, State.COOKING_SIDE_1:
				return "🍳 Espátula — [Clique] Virar %s (%d%%)" % [meat_name, int(side_a_cooked)]
			State.READY_SIDE_1:
				return "🍳 Espátula — [Clique] VIRAR %s (Lado 1 Pronto!)" % meat_name
			State.COOKING_SIDE_2:
				return "🍳 Espátula — [Clique] Virar/Checar (Lado 2: %d%%)" % int(side_b_cooked)
			State.COOKED:
				return "🍳 Espátula — [Clique] Retirar %s Pronto!" % meat_name
			State.BURNT:
				return "🍳 Espátula — [Clique] Retirar %s Queimado" % meat_name
			_:
				return "🍳 Espátula — Interagir com %s" % meat_name

	# Se estiver com a mão livre (Slot 3)
	match state:
		State.RAW:
			return "✋ [Clique] Pegar %s Cru" % meat_name
		State.READY_SIDE_1:
			return "⚠️ [1] Equipe a Espátula para virar o hambúrguer!"
		State.COOKED:
			return "⚠️ [1] Equipe a Espátula para retirar da grelha!"
		_:
			return "⚠️ Use a Espátula [1] na grelha"

# Atualização de materiais dos dois lados de forma realista e independente
func _update_visuals() -> void:
	if not visual_model:
		visual_model = get_node_or_null("VisualModel")
	if not side_a_mesh:
		side_a_mesh = get_node_or_null("VisualModel/SideAFace")
	if not side_b_mesh:
		side_b_mesh = get_node_or_null("VisualModel/SideBFace")
	if not body_mesh:
		body_mesh = get_node_or_null("VisualModel/BodyMesh")

	if not side_a_mesh or not side_b_mesh:
		return

	_apply_side_visual(side_a_mesh, side_a_cooked)
	_apply_side_visual(side_b_mesh, side_b_cooked)

	# Atualiza o corpo lateral com a média dos dois lados
	var avg_cook = (side_a_cooked + side_b_cooked) * 0.5
	_apply_side_visual(body_mesh, avg_cook)

func _apply_side_visual(mesh_inst: MeshInstance3D, cooked_pct: float) -> void:
	if not mesh_inst:
		return

	var mat = mesh_inst.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_inst.material_override = mat

	var is_chick = (meat_type == MeatType.CHICKEN)
	var raw_tex = TEX_CHICKEN_RAW if is_chick else TEX_BEEF_RAW
	var cooked_tex = TEX_CHICKEN_COOKED if is_chick else TEX_BEEF_COOKED

	mat.normal_enabled = true
	mat.uv1_scale = Vector3(2.0, 2.0, 2.0)

	if state == State.BURNT or cooked_pct > 115.0:
		# Estado queimado
		mat.albedo_texture = TEX_BURNT
		mat.albedo_color = Color(0.85, 0.85, 0.85, 1.0)
		mat.normal_texture = TEX_NORMAL_COOKED
		mat.normal_scale = 0.85
		mat.roughness = 0.95
	elif cooked_pct >= 100.0:
		# Estado perfeitamente grelhado / dourado com marcas de chapa
		mat.albedo_texture = cooked_tex
		mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		mat.normal_texture = TEX_NORMAL_COOKED
		mat.normal_scale = 0.80
		mat.roughness = 0.40
	elif cooked_pct >= 40.0:
		# Em processo de cocção / selamento
		var t = (cooked_pct - 40.0) / 60.0
		mat.albedo_texture = cooked_tex
		mat.albedo_color = Color(0.88, 0.65, 0.55, 1.0) if is_chick else Color(0.82, 0.52, 0.42, 1.0)
		mat.normal_texture = TEX_NORMAL_COOKED
		mat.normal_scale = lerpf(0.55, 0.75, t)
		mat.roughness = lerpf(0.60, 0.45, t)
	else:
		# Estado cru natural fresco
		mat.albedo_texture = raw_tex
		mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		mat.normal_texture = TEX_NORMAL_RAW
		mat.normal_scale = 0.60
		mat.roughness = 0.65
