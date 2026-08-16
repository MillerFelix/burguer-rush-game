class_name DrinkCup
extends Item

# ================================================================
# COPO DE BEBIDA TRANSPARENTE COM LÍQUIDO 3D INTERNO RENTE ÀS PAREDES
# ================================================================

enum State { EMPTY, FILLED, CLOSED }

@export var state: State = State.EMPTY
@export var beverage_type: String = "soda_cola"
@export var fill_amount: float = 0.0 # 0.0 (Vazio) a 1.0 (Cheio)

# Nós Visuais
@onready var cup_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D/CupBody")
@onready var liquid_pivot: Node3D = get_node_or_null("MeshInstance3D/LiquidPivot")
@onready var liquid_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D/LiquidPivot/LiquidMesh")
@onready var liquid_surface: MeshInstance3D = get_node_or_null("MeshInstance3D/LiquidPivot/LiquidSurface")

var flavor: String = "soda_cola"

func _ready() -> void:
	if state == State.FILLED or state == State.CLOSED:
		fill_amount = 1.0
	set_flavor(beverage_type)
	_update_visuals()

func set_flavor(new_flavor: String) -> void:
	flavor = new_flavor
	beverage_type = new_flavor
	item_id = new_flavor
	_update_visuals()

func get_flavor_display_name() -> String:
	match flavor:
		"soda_cola", "cola":
			return "Copo de Cola"
		"soda_cola_zero", "cola_zero", "zero":
			return "Copo de Zero"
		"soda_lime", "soda", "soda_sprite", "sprite", "lemon", "limao":
			return "Copo de Soda"
		"soda_citrus", "citrus", "soda_citrix", "citrix":
			return "Copo de Citrus"
		"juice_orange", "orange", "suco_laranja":
			return "Copo de Suco de Laranja"
		"juice_grape", "grape", "suco_uva":
			return "Copo de Suco de Uva"
		"juice_strawberry", "strawberry", "suco_morango":
			return "Copo de Suco de Morango"
		_:
			return "Copo de %s" % flavor.capitalize()

func set_state(new_state: State) -> void:
	state = new_state
	item_type = "final_product" if (state == State.FILLED or state == State.CLOSED) else "tool"
	is_packaged = (state == State.FILLED or state == State.CLOSED)
	if state == State.EMPTY:
		fill_amount = 0.0
	elif state == State.FILLED or state == State.CLOSED:
		fill_amount = 1.0
	_update_visuals()

func has_lid() -> bool:
	return state == State.CLOSED or state == State.FILLED

func seal_cup() -> void:
	if state == State.FILLED:
		set_state(State.CLOSED)

func _get_flavor_color() -> Color:
	match flavor:
		"soda_cola", "cola":
			return Color(0.12, 0.05, 0.03, 0.98) # Cola
		"soda_cola_zero", "cola_zero", "zero":
			return Color(0.06, 0.06, 0.08, 0.98) # Zero
		"soda_lime", "soda", "soda_sprite", "sprite":
			return Color(0.75, 0.95, 0.65, 0.90) # Soda
		"soda_citrus", "citrus", "soda_citrix":
			return Color(0.95, 0.55, 0.08, 0.98) # Citrus
		"juice_orange", "orange", "suco_laranja":
			return Color(0.98, 0.52, 0.05, 0.98) # Suco Laranja
		"juice_grape", "grape", "suco_uva":
			return Color(0.48, 0.12, 0.65, 0.98) # Suco Uva
		"juice_strawberry", "strawberry", "suco_morango":
			return Color(0.92, 0.12, 0.28, 0.98) # Suco Morango
		_:
			return Color(0.15, 0.1, 0.08, 0.95)

func _update_visuals() -> void:
	var f_name = get_flavor_display_name()
	item_type = "final_product" if (state == State.FILLED or state == State.CLOSED) else "tool"
	is_packaged = (state == State.FILLED or state == State.CLOSED)

	if not liquid_pivot:
		liquid_pivot = get_node_or_null("MeshInstance3D/LiquidPivot")
	if not liquid_mesh:
		liquid_mesh = get_node_or_null("MeshInstance3D/LiquidPivot/LiquidMesh")
	if not liquid_surface:
		liquid_surface = get_node_or_null("MeshInstance3D/LiquidPivot/LiquidSurface")

	# Garante que o pivô do líquido permaneça perfeitamente alinhado e estável
	if liquid_pivot:
		liquid_pivot.rotation = Vector3.ZERO
		liquid_pivot.position = Vector3.ZERO

	# Atualiza cor do líquido e dimensões exatas que encostam nas paredes internas
	if fill_amount <= 0.001:
		if liquid_mesh:
			liquid_mesh.visible = false
		if liquid_surface:
			liquid_surface.visible = false
	else:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = _get_flavor_color()
		mat.roughness = 0.06
		mat.metallic_specular = 0.9
		mat.clearcoat = 0.9

		# Altura e raios correspondentes ao cone interno do copo
		# Fundo interno: y = 0.012, raio = 0.0468. Topo interno: y = 0.172, raio = 0.0630.
		var f_clamped = clampf(fill_amount, 0.02, 1.0)
		var h = 0.160 * f_clamped
		var r_bottom = 0.0468
		var r_top = lerpf(0.0468, 0.0630, f_clamped)

		if liquid_mesh:
			liquid_mesh.visible = true
			liquid_mesh.material_override = mat

			var cyl_mesh = CylinderMesh.new()
			cyl_mesh.bottom_radius = r_bottom
			cyl_mesh.top_radius = r_top
			cyl_mesh.height = h
			cyl_mesh.radial_segments = 22
			liquid_mesh.mesh = cyl_mesh
			liquid_mesh.scale = Vector3.ONE
			# Centro do cilindro posicionado a partir do fundo interno
			liquid_mesh.position.y = 0.012 + h * 0.5

		if liquid_surface:
			liquid_surface.visible = true
			liquid_surface.material_override = mat

			var surf_mesh = CylinderMesh.new()
			surf_mesh.top_radius = r_top
			surf_mesh.bottom_radius = r_top
			surf_mesh.height = 0.002
			surf_mesh.radial_segments = 22
			liquid_surface.mesh = surf_mesh
			liquid_surface.scale = Vector3.ONE
			liquid_surface.position.y = 0.012 + h

	# Nomes e prompts de interação
	if state == State.EMPTY or fill_amount <= 0.001:
		display_name = "Copo Vazio"
		prompt_text = "🖱️ [Clique Esquerdo] Pegar Copo Vazio"
	else:
		display_name = f_name
		prompt_text = "🖱️ [Clique Esquerdo] Pegar %s" % f_name
