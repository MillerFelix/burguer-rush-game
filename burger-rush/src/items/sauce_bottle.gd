class_name SauceBottle
extends Item

# ================================================================
# BISNAGA DE MOLHO PROFISSIONAL COM NÍVEL FÍSICO REAL E JATO ESPESSO
#
# Recursos:
#  - Frasco translúcido fosco: o molho é visualizado 100% fisicamente
#  - Nível de molho interno que sobe e desce em tempo real sem números/textos
#  - Tombamento (~85°) direcionado para o lanche ao segurar Clique Esquerdo
#  - JATO GROSSO, VISÍVEL E VOLUMOSO (Tubo 3D Contínuo) nascendo do bico
#  - Animação de deformação líquida viscosa contínua
#  - Zero porcentagens, zero legendas poluídas
# ================================================================

@export var sauce_type: String = "ketchup":
	set(val):
		var changed = (sauce_type != val)
		sauce_type = val
		if changed or is_node_ready():
			_setup_sauce_properties()
			_update_visuals()

@export var current_amount: float = 100.0:
	set(val):
		current_amount = val
		_update_sauce_level_visual()

@export var max_amount: float = 100.0
@export var consumption_rate: float = 5.0 # % consumido por segundo de aplicação contínua

@onready var model_root: Node3D = get_node_or_null("Model")
@onready var bottle_body: MeshInstance3D = get_node_or_null("Model/BottleBody")
@onready var sauce_fill_pivot: Node3D = get_node_or_null("Model/SauceFillPivot")
@onready var sauce_fill: MeshInstance3D = get_node_or_null("Model/SauceFillPivot/SauceFill")
@onready var bottle_neck: MeshInstance3D = get_node_or_null("Model/BottleNeck")
@onready var nozzle_tip: Node3D = get_node_or_null("Model/NozzleTip")
@onready var stream_mesh: MeshInstance3D = get_node_or_null("StreamMesh")

var is_squeezing: bool = false
var tilt_progress: float = 0.0 # 0.0 (vertical) a 1.0 (tombada ~85°)
var sauce_color: Color = Color(0.88, 0.08, 0.08, 1.0)
var immediate_mesh: ImmediateMesh = null

var home_parent: Node = null
var home_transform: Transform3D

func _ready() -> void:
	item_id = sauce_type
	item_type = "sauce_bottle"
	current_amount = 100.0
	home_parent = get_parent()
	home_transform = transform
	_setup_sauce_properties()
	_update_visuals()

	# Conecta ao relógio para retornar automaticamente ao suporte no fim do dia
	var clock = _get_game_clock()
	if clock and not clock.day_ended.is_connected(_on_day_ended):
		clock.day_ended.connect(_on_day_ended)

func _get_game_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _on_day_ended(_summary = null) -> void:
	reset_to_home_position()

func reset_to_home_position() -> void:
	stop_squeezing()
	var player = _get_player_node()
	if player and player.get("held_item") == self:
		player.take_held_item()

	if home_parent and is_instance_valid(home_parent):
		if get_parent() != home_parent:
			if get_parent():
				get_parent().remove_child(self)
			home_parent.add_child(self)
		transform = home_transform
		location = ItemLocation.WORLD
		visible = true

func setup_bottle(type: String, col: Color = Color(0, 0, 0, 0), d_name: String = "") -> void:
	sauce_type = type
	if col != Color(0, 0, 0, 0):
		sauce_color = col
	if d_name != "":
		display_name = d_name
	item_id = sauce_type
	_update_visuals()

func _setup_sauce_properties() -> void:
	match sauce_type:
		"ketchup", "sauce":
			display_name = "Bisnaga de Ketchup"
			sauce_color = Color(0.88, 0.08, 0.08, 1.0) # Vermelho forte de tomate
		"mustard":
			display_name = "Bisnaga de Mostarda"
			sauce_color = Color(0.96, 0.76, 0.08, 1.0) # Amarelo mostarda vivo
		"mayo":
			display_name = "Bisnaga de Maionese"
			sauce_color = Color(0.96, 0.95, 0.88, 1.0) # Branco cremoso suave
		"special_sauce", "barbecue":
			display_name = "Bisnaga de Molho Especial"
			sauce_color = Color(0.88, 0.40, 0.12, 1.0) # Âmbar barbecue
		_:
			display_name = "Bisnaga de Molho"
			sauce_color = Color(0.88, 0.08, 0.08, 1.0)

	item_id = sauce_type
	prompt_text = "🖱️ [Clique] Pegar %s" % display_name

func _update_visuals() -> void:
	# Material do molho interno visível através do plástico translúcido
	if not sauce_fill:
		sauce_fill = get_node_or_null("Model/SauceFillPivot/SauceFill")
	if sauce_fill:
		var mat_sauce = StandardMaterial3D.new()
		mat_sauce.albedo_color = sauce_color
		mat_sauce.roughness = 0.2
		mat_sauce.clearcoat_enabled = true
		mat_sauce.clearcoat = 0.6
		sauce_fill.material_override = mat_sauce

	# Material da tampa e bico dosador
	var mat_cap = StandardMaterial3D.new()
	mat_cap.albedo_color = sauce_color.darkened(0.15)
	mat_cap.roughness = 0.35
	if not bottle_neck:
		bottle_neck = get_node_or_null("Model/BottleNeck")
	if bottle_neck:
		bottle_neck.material_override = mat_cap
	if not nozzle_tip:
		nozzle_tip = get_node_or_null("Model/NozzleTip")
	if nozzle_tip is MeshInstance3D:
		nozzle_tip.material_override = mat_cap

	_update_sauce_level_visual()

func _update_sauce_level_visual() -> void:
	if not sauce_fill_pivot:
		sauce_fill_pivot = get_node_or_null("Model/SauceFillPivot")

	var fraction = clampf(current_amount / max_amount, 0.0, 1.0)
	if sauce_fill_pivot:
		if fraction <= 0.01:
			sauce_fill_pivot.visible = false
		else:
			sauce_fill_pivot.visible = true
			sauce_fill_pivot.scale.y = fraction

func get_display_name() -> String:
	return display_name

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return "🖱️ (Segurar) Aplicar %s no Lanche" % display_name
	if player and player.get("held_item") != null:
		return ""
	return "🖱️ [Clique] Pegar %s" % display_name

func is_empty() -> bool:
	return current_amount <= 0.0

func start_squeezing(player_raycast: RayCast3D = null) -> void:
	if is_empty():
		stop_squeezing()
		return
	is_squeezing = true

func stop_squeezing() -> void:
	is_squeezing = false
	_hide_stream()

func _process(delta: float) -> void:
	if not model_root:
		model_root = get_node_or_null("Model")
	if not nozzle_tip:
		nozzle_tip = get_node_or_null("Model/NozzleTip")
	if not stream_mesh:
		stream_mesh = get_node_or_null("StreamMesh")

	# Animação suave e contida de tombamento da bisnaga (~55° junto à mão, sem se afastar)
	if is_squeezing and location == ItemLocation.PLAYER_HAND and current_amount > 0.0:
		tilt_progress = move_toward(tilt_progress, 1.0, 9.0 * delta)
	else:
		tilt_progress = move_toward(tilt_progress, 0.0, 11.0 * delta)

	if model_root:
		model_root.rotation.x = deg_to_rad(-55.0 * tilt_progress)
		model_root.position.y = -0.02 * tilt_progress
		model_root.position.z = -0.03 * tilt_progress

	# Aplicação contínua de molho
	if is_squeezing and location == ItemLocation.PLAYER_HAND:
		if current_amount > 0.0:
			_process_continuous_flow(delta)
		else:
			stop_squeezing()

func _get_player_node() -> Node3D:
	var n: Node = get_parent()
	while n != null:
		if n is CharacterBody3D or n.has_node("Head/Camera3D") or n.is_in_group("player"):
			return n as Node3D
		n = n.get_parent()
	if is_inside_tree() and get_tree():
		var p = get_tree().get_first_node_in_group("player")
		if p:
			return p as Node3D
	return null

func on_picked_up() -> void:
	stop_squeezing()
	super.on_picked_up()

func on_dropped() -> void:
	stop_squeezing()
	super.on_dropped()

func _find_burger_assembly(col: Object) -> BurgerAssembly:
	if not col:
		return null
	if col is BurgerAssembly:
		return col
	if col.has_meta("burger_assembly"):
		return col.get_meta("burger_assembly") as BurgerAssembly
	if col.has_meta("burger_base"):
		var base = col.get_meta("burger_base")
		if base and base.has_method("_ensure_assembly"):
			base._ensure_assembly()
			return base.assembly
	if col is BreadBottom:
		col._ensure_assembly()
		return col.assembly
	if col.has_method("_ensure_assembly"):
		col._ensure_assembly()
		if col.get("assembly") is BurgerAssembly:
			return col.get("assembly") as BurgerAssembly
	var p = col.get_parent() if (col is Node) else null
	if p:
		if p is BurgerAssembly:
			return p
		if p.has_meta("burger_assembly"):
			return p.get_meta("burger_assembly") as BurgerAssembly
		if p is BreadBottom:
			p._ensure_assembly()
			return p.assembly
		var gp = p.get_parent()
		if gp and gp is BurgerAssembly:
			return gp
	return null

func _process_continuous_flow(delta: float) -> void:
	var player = _get_player_node()
	var ray: RayCast3D = null
	if player and player.has_node("Head/Camera3D/RayCast3D"):
		ray = player.get_node("Head/Camera3D/RayCast3D") as RayCast3D

	var tip_pos = nozzle_tip.global_position if (nozzle_tip and nozzle_tip.is_inside_tree()) else (global_position if is_inside_tree() else Vector3.ZERO)
	var target_pt: Vector3
	var hit_assembly: BurgerAssembly = null

	if ray and ray.is_colliding():
		var col_pt = ray.get_collision_point()
		var dist = tip_pos.distance_to(col_pt)
		if dist <= 2.2:
			target_pt = col_pt
			var col = ray.get_collider()
			hit_assembly = _find_burger_assembly(col)
		else:
			var dir = (col_pt - tip_pos).normalized()
			target_pt = tip_pos + dir * 0.4 + Vector3.DOWN * 0.15
	else:
		var forward_dir = Vector3.DOWN
		if player and player.is_inside_tree():
			var cam = player.get_node_or_null("Head/Camera3D")
			if cam and cam.is_inside_tree():
				forward_dir = (-cam.global_transform.basis.z * 0.5 + Vector3.DOWN * 0.8).normalized()
		target_pt = tip_pos + forward_dir * 0.35

	_render_thick_sauce_stream(tip_pos, target_pt)

	if hit_assembly and hit_assembly.state != BurgerAssembly.State.PACKAGED:
		hit_assembly.apply_sauce(sauce_type, sauce_color, target_pt, delta)

	current_amount = 100.0
	_update_sauce_level_visual()

func get_stream_mesh() -> MeshInstance3D:
	if not stream_mesh:
		stream_mesh = get_node_or_null("StreamMesh")
	return stream_mesh

# Renderiza um jato 3D cilíndrico volumoso, espesso (~3cm) e fluido nascendo exatamente do bico
func _render_thick_sauce_stream(start_pos: Vector3, end_pos: Vector3) -> void:
	var sm = get_stream_mesh()
	if not sm:
		return

	if not immediate_mesh:
		immediate_mesh = ImmediateMesh.new()
		sm.mesh = immediate_mesh

	var mat = sm.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.08
		mat.clearcoat_enabled = true
		mat.clearcoat = 1.0
		mat.clearcoat_roughness = 0.05
		sm.material_override = mat
	mat.albedo_color = sauce_color

	immediate_mesh.clear_surfaces()
	sm.visible = true

	var local_start = sm.to_local(start_pos) if sm.is_inside_tree() else start_pos
	var local_end = sm.to_local(end_pos) if sm.is_inside_tree() else end_pos

	var segments = 12
	var radial_segments = 6
	var base_radius = 0.015 # Raio volumoso (~3.0 cm de diâmetro)

	var ring_points: Array[Array] = []
	var time_ms = Time.get_ticks_msec() * 0.015

	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var center = local_start.lerp(local_end, t)

		# Curvatura gravitacional natural parabólica
		center.y -= sin(t * PI) * 0.035

		# Deformação fluida e viscosa ao longo do trajeto
		var ripple = sin(t * 14.0 - time_ms) * 0.0025
		center.x += ripple
		center.z += cos(t * 14.0 - time_ms) * 0.0025

		# Direção do segmento para construir anel perpendicular
		var dir = (local_end - local_start).normalized()
		if dir.length_squared() < 0.001:
			dir = Vector3(0, -1, 0)

		var up_ref = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var side = dir.cross(up_ref).normalized()
		var up = side.cross(dir).normalized()

		# Variação de raio: nasce justo no bico (0.008) e ganha corpo volumoso no percurso
		var cur_radius = base_radius
		if t < 0.15:
			cur_radius = lerpf(0.008, base_radius, t / 0.15)
		else:
			cur_radius = base_radius * (1.0 + 0.12 * sin(t * PI * 2.0 - time_ms))

		var cur_ring: Array[Vector3] = []
		for j in range(radial_segments):
			var angle = float(j) / float(radial_segments) * TAU
			var pt = center + (side * cos(angle) + up * sin(angle)) * cur_radius
			cur_ring.append(pt)
		ring_points.append(cur_ring)

	# Constrói tubo 3D fechado com triângulos
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(segments):
		var ring1 = ring_points[i]
		var ring2 = ring_points[i + 1]

		for j in range(radial_segments):
			var next_j = (j + 1) % radial_segments

			var p1 = ring1[j]
			var p2 = ring1[next_j]
			var p3 = ring2[j]
			var p4 = ring2[next_j]

			# Quad 1
			immediate_mesh.surface_add_vertex(p1)
			immediate_mesh.surface_add_vertex(p2)
			immediate_mesh.surface_add_vertex(p3)

			# Quad 2
			immediate_mesh.surface_add_vertex(p2)
			immediate_mesh.surface_add_vertex(p4)
			immediate_mesh.surface_add_vertex(p3)

	immediate_mesh.surface_end()

func _hide_stream() -> void:
	var sm = get_stream_mesh()
	if sm:
		sm.visible = false
	if immediate_mesh:
		immediate_mesh.clear_surfaces()

func get_ingredient_key() -> String:
	return sauce_type
