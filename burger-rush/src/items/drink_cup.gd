class_name DrinkCup
extends Item

enum State {
	EMPTY,
	FILLED,
	CLOSED
}

@export var state: State = State.EMPTY
@export var beverage_type: String = "soda_cola" # soda_cola, soda_guarana, soda_sprite, soda
@export var flavor: String = "soda_cola"

@onready var cup_mesh: MeshInstance3D = $CupMesh
@onready var liquid_mesh: MeshInstance3D = $LiquidMesh
@onready var lid_mesh: MeshInstance3D = $LidMesh
@onready var straw_mesh: MeshInstance3D = $StrawMesh

func _ready() -> void:
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
		"soda":
			return "Refrigerante"
		_:
			return flavor.capitalize()

func set_state(new_state: State) -> void:
	state = new_state
	item_type = "final_product" if state == State.CLOSED else "tool"
	is_packaged = (state == State.CLOSED)
	_update_visuals()

func _update_visuals() -> void:
	var flavor_name = get_flavor_display_name()
	item_type = "final_product" if state == State.CLOSED else "tool"
	is_packaged = (state == State.CLOSED)

	# Atualiza a cor do material do líquido conforme o sabor
	if liquid_mesh:
		var liquid_color = Color(0.12, 0.04, 0.02, 1.0) # Cola (marrom escuro)
		match flavor:
			"soda_guarana", "guarana":
				liquid_color = Color(0.85, 0.45, 0.1, 1.0) # Âmbar Guaraná
			"soda_sprite", "sprite", "lemon":
				liquid_color = Color(0.8, 0.95, 0.8, 0.8) # Limão transparente
			"soda_cola", "cola", "soda":
				liquid_color = Color(0.12, 0.04, 0.02, 1.0) # Cola

		var mat = StandardMaterial3D.new()
		mat.albedo_color = liquid_color
		mat.roughness = 0.2
		liquid_mesh.material_override = mat

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
