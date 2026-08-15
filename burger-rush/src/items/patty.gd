class_name Patty
extends Item

enum State {
	RAW,
	COOKING,
	COOKED,
	BURNT
}

enum MeatType {
	BEEF,
	CHICKEN
}

@export var state: State = State.RAW
@export var meat_type: MeatType = MeatType.BEEF

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

const COLOR_BEEF_RAW: Color = Color(0.85, 0.28, 0.25, 1.0)
const COLOR_BEEF_COOKED: Color = Color(0.42, 0.22, 0.12, 1.0)
const COLOR_CHICKEN_RAW: Color = Color(0.95, 0.75, 0.65, 1.0)
const COLOR_CHICKEN_COOKED: Color = Color(0.85, 0.58, 0.25, 1.0)
const COLOR_BURNT: Color = Color(0.08, 0.08, 0.08, 1.0)

func _ready() -> void:
	if meat_type == MeatType.CHICKEN:
		item_id = "patty_chicken"
	else:
		item_id = "patty_beef"
	item_type = "ingredient"
	_update_visuals()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func get_ingredient_key() -> String:
	var prefix = "patty_chicken" if meat_type == MeatType.CHICKEN else "patty_beef"
	match state:
		State.RAW:
			return prefix + ":raw"
		State.COOKING:
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
		State.COOKING:
			return meat_name + " (Cozinhando)"
		State.COOKED:
			return meat_name + " (Pronto)"
		State.BURNT:
			return meat_name + " (Queimado)"
		_:
			return meat_name

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		return ""
	var meat_name = "Frango" if meat_type == MeatType.CHICKEN else "Carne"
	match state:
		State.RAW:
			return "E — Pegar %s Cru" % meat_name
		State.COOKING:
			return "E — Pegar %s (Em Preparo)" % meat_name
		State.COOKED:
			return "E — Pegar %s Pronto" % meat_name
		State.BURNT:
			return "E — Pegar %s Queimado" % meat_name
		_:
			return "E — Pegar %s" % meat_name

func _update_visuals() -> void:
	if not mesh_instance:
		return

	var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_instance.material_override = mat

	var raw_color = COLOR_CHICKEN_RAW if meat_type == MeatType.CHICKEN else COLOR_BEEF_RAW
	var cooked_color = COLOR_CHICKEN_COOKED if meat_type == MeatType.CHICKEN else COLOR_BEEF_COOKED

	match state:
		State.RAW:
			mat.albedo_color = raw_color
			mat.roughness = 0.6
		State.COOKING:
			mat.albedo_color = raw_color.lerp(cooked_color, 0.5)
			mat.roughness = 0.5
		State.COOKED:
			mat.albedo_color = cooked_color
			mat.roughness = 0.4
		State.BURNT:
			mat.albedo_color = COLOR_BURNT
			mat.roughness = 0.95
