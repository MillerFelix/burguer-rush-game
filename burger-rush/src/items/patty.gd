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

const COLOR_RAW: Color = Color(0.85, 0.28, 0.25, 1.0)
const COLOR_COOKED: Color = Color(0.42, 0.22, 0.12, 1.0)
const COLOR_BURNT: Color = Color(0.08, 0.08, 0.08, 1.0)

func _ready() -> void:
	item_id = "patty"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func get_ingredient_key() -> String:
	match state:
		State.RAW:
			return "patty:raw"
		State.COOKING:
			return "patty:cooking"
		State.COOKED:
			return "patty:cooked"
		State.BURNT:
			return "patty:burnt"
		_:
			return "patty"

func get_display_name() -> String:
	match state:
		State.RAW:
			return "Carne Crua"
		State.COOKING:
			return "Carne (Cozinhando)"
		State.COOKED:
			return "Carne Pronta"
		State.BURNT:
			return "Carne Queimada"
		_:
			return "Carne"

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		return ""
	match state:
		State.RAW:
			return "E — Pegar Carne Crua"
		State.COOKING:
			return "E — Pegar Carne (Em Preparo)"
		State.COOKED:
			return "E — Pegar Carne Pronta"
		State.BURNT:
			return "E — Pegar Carne Queimada"
		_:
			return "E — Pegar Carne"

func _update_visuals() -> void:
	if not mesh_instance:
		return

	var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_instance.material_override = mat

	match state:
		State.RAW:
			mat.albedo_color = COLOR_RAW
			mat.roughness = 0.6
		State.COOKING:
			mat.albedo_color = COLOR_RAW.lerp(COLOR_COOKED, 0.5)
			mat.roughness = 0.5
		State.COOKED:
			mat.albedo_color = COLOR_COOKED
			mat.roughness = 0.4
		State.BURNT:
			mat.albedo_color = COLOR_BURNT
			mat.roughness = 0.95
