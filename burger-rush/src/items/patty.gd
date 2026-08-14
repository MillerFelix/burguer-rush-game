class_name Patty
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

@export var state: State = State.RAW

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

const COLOR_RAW := Color(0.85, 0.25, 0.25, 1.0)
const COLOR_COOKING := Color(0.65, 0.40, 0.25, 1.0)
const COLOR_COOKED := Color(0.38, 0.20, 0.10, 1.0)
const COLOR_BURNT := Color(0.12, 0.12, 0.12, 1.0)

func _ready() -> void:
	item_id = "patty"
	_update_state_properties()

func set_state(new_state: State) -> void:
	state = new_state
	_update_state_properties()

func _update_state_properties() -> void:
	match state:
		State.RAW:
			prompt_text = "E — Pegar Carne Crua"
			_apply_material_color(COLOR_RAW)
		State.COOKING:
			prompt_text = "E — Pegar Carne (Em Preparo)"
			_apply_material_color(COLOR_COOKING)
		State.COOKED:
			prompt_text = "E — Pegar Carne Pronta"
			_apply_material_color(COLOR_COOKED)
		State.BURNT:
			prompt_text = "E — Pegar Carne Queimada"
			_apply_material_color(COLOR_BURNT)

func _apply_material_color(color: Color) -> void:
	if not mesh_instance:
		return

	var mat: StandardMaterial3D = mesh_instance.get_surface_override_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(0, mat)
	else:
		mat = mat.duplicate()
		mesh_instance.set_surface_override_material(0, mat)

	mat.albedo_color = color
	mat.roughness = 0.6
