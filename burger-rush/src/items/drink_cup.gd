class_name DrinkCup
extends Item

enum State { EMPTY, FILLED, CLOSED }

@export var state: State = State.EMPTY
@export var beverage_type: String = "soda_cola" # soda_cola, soda_guarana, soda_sprite, juice_orange, juice_grape, etc.
@export var fill_amount: float = 0.0 # 0.0 a 1.0 (para animação contínua de enchimento)

@onready var liquid_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D/LiquidMesh")
@onready var lid_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D/LidMesh")
@onready var straw_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D/StrawMesh")

var flavor: String = "soda_cola"

func _ready() -> void:
	if state == State.CLOSED or state == State.FILLED:
		fill_amount = 1.0
	set_flavor(beverage_type)

func set_flavor(new_flavor: String) -> void:
	flavor = new_flavor
	beverage_type = new_flavor
	item_id = new_flavor
	_update_visuals()

func get_flavor_display_name() -> String:
	match flavor:
		"soda_cola", "cola":
			return "Refrigerante Cola"
		"soda_guarana", "guarana":
			return "Refrigerante Guaraná"
		"soda_sprite", "sprite", "lemon":
			return "Refrigerante Limão"
		"soda_grape", "grape", "uva":
			return "Refrigerante Uva"
		"soda_cola_zero", "cola_zero", "zero":
			return "Refrigerante Cola Zero"
		"soda":
			return "Refrigerante"
		"juice_orange", "orange":
			return "Suco de Laranja"
		"juice_grape", "grape_juice":
			return "Suco de Uva"
		"juice_passion", "passion":
			return "Suco de Maracujá"
		_:
			return flavor.capitalize()

func has_lid() -> bool:
	return state == State.CLOSED

func seal_cup() -> void:
	set_state(State.CLOSED)

func set_state(new_state: State) -> void:
	state = new_state
	item_type = "final_product" if state == State.CLOSED else "tool"
	is_packaged = (state == State.CLOSED)
	if state == State.EMPTY:
		fill_amount = 0.0
	elif state == State.FILLED or state == State.CLOSED:
		fill_amount = 1.0
	_update_visuals()

func _update_visuals() -> void:
	var flavor_name = get_flavor_display_name()
	item_type = "final_product" if state == State.CLOSED else "tool"
	is_packaged = (state == State.CLOSED)

	if liquid_mesh:
		var liquid_color = Color(0.12, 0.04, 0.02, 1.0) # Cola
		match flavor:
			"soda_guarana", "guarana":
				liquid_color = Color(0.85, 0.45, 0.1, 1.0) # Âmbar Guaraná
			"soda_sprite", "sprite", "lemon":
				liquid_color = Color(0.75, 0.95, 0.65, 0.85) # Limão refrescante
			"soda_grape", "grape", "uva":
				liquid_color = Color(0.45, 0.12, 0.65, 1.0) # Uva
			"soda_cola_zero", "cola_zero", "zero":
				liquid_color = Color(0.08, 0.08, 0.10, 1.0) # Cola Zero
			"soda_cola", "cola", "soda":
				liquid_color = Color(0.12, 0.04, 0.02, 1.0) # Cola clássica
			"juice_orange", "orange":
				liquid_color = Color(0.95, 0.55, 0.08, 1.0) # Laranja natural
			"juice_grape", "grape_juice":
				liquid_color = Color(0.42, 0.10, 0.55, 1.0) # Uva integral
			"juice_passion", "passion":
				liquid_color = Color(0.96, 0.82, 0.14, 1.0) # Maracujá dourado

		var mat = StandardMaterial3D.new()
		mat.albedo_color = liquid_color
		mat.roughness = 0.18
		liquid_mesh.material_override = mat

		var f_scale = clampf(fill_amount, 0.1, 1.0)
		liquid_mesh.scale = Vector3(1.0, f_scale, 1.0)

	match state:
		State.EMPTY:
			display_name = "Copo Vazio"
			prompt_text = "E — Pegar Copo Vazio"
			if liquid_mesh:
				liquid_mesh.visible = false
			if lid_mesh:
				lid_mesh.visible = false
			if straw_mesh:
				straw_mesh.visible = false
		State.FILLED:
			display_name = "%s (Sem Tampa)" % flavor_name
			prompt_text = "E — Pegar %s Aberto" % flavor_name
			if liquid_mesh:
				liquid_mesh.visible = true
			if lid_mesh:
				lid_mesh.visible = false
			if straw_mesh:
				straw_mesh.visible = false
		State.CLOSED:
			display_name = flavor_name
			prompt_text = "E — Pegar %s" % flavor_name
			if liquid_mesh:
				liquid_mesh.visible = true
			if lid_mesh:
				lid_mesh.visible = true
			if straw_mesh:
				straw_mesh.visible = true
