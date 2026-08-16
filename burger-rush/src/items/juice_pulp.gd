class_name JuicePulp
extends Item

# ================================================================
# ITEM: PEDRA DE POLPA DE FRUTA CONGELADA (5 DOSES)
# Identificação puramente visual através do formato e desenho da fruta
# ================================================================

@export var fruit_type: String = "orange":
	set(val):
		fruit_type = val
		_setup_pulp_properties()

const DOSES_PER_PULP: int = 5

@onready var pulp_mesh: MeshInstance3D = get_node_or_null("Model/PulpBlock")
@onready var fruit_emblem: Label3D = get_node_or_null("Model/FruitEmblem")

func _ready() -> void:
	item_type = "ingredient"
	_setup_pulp_properties()

func _setup_pulp_properties() -> void:
	var col = Color(0.98, 0.52, 0.05, 1.0)
	var icon = "🍊"

	match fruit_type:
		"orange", "laranja", "pulp_orange":
			item_id = "pulp_orange"
			display_name = "Polpa de Laranja"
			col = Color(0.98, 0.52, 0.05, 1.0)
			icon = "🍊"
		"grape", "uva", "pulp_grape":
			item_id = "pulp_grape"
			display_name = "Polpa de Uva"
			col = Color(0.48, 0.12, 0.65, 1.0)
			icon = "🍇"
		"strawberry", "morango", "pulp_strawberry":
			item_id = "pulp_strawberry"
			display_name = "Polpa de Morango"
			col = Color(0.92, 0.12, 0.28, 1.0)
			icon = "🍓"
		_:
			item_id = "pulp_%s" % fruit_type
			display_name = "Polpa de %s" % fruit_type.capitalize()
			icon = "🍊"

	if not pulp_mesh:
		pulp_mesh = get_node_or_null("Model/PulpBlock")
	if pulp_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.55
		mat.rim_enabled = true
		mat.rim = 0.6
		mat.clearcoat = 0.4
		pulp_mesh.material_override = mat

	if not fruit_emblem:
		fruit_emblem = get_node_or_null("Model/FruitEmblem")
	if fruit_emblem:
		fruit_emblem.text = icon

func get_fruit_id() -> String:
	match fruit_type:
		"orange", "laranja", "pulp_orange": return "juice_orange"
		"grape", "uva", "pulp_grape": return "juice_grape"
		"strawberry", "morango", "pulp_strawberry": return "juice_strawberry"
	return "juice_orange"
