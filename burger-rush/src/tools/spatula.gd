class_name Spatula
extends Node3D

# ================================================================
# ESPÁTULA PROFISSIONAL DE GRELHA (DETALHADA & FUNCIONAL)
#
# Ferramenta para virar e transportar alimentos na chapa.
# Possui BladeRestPoint dedicado para que o hambúrguer descanse
# perfeitamente SOBRE a lâmina, sem clipping.
# ================================================================

@export var tool_name: String = "Espátula"
@export var tool_id: String = "spatula"

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var model: Node3D = get_node_or_null("Model")
@onready var blade_rest_point: Node3D = get_node_or_null("Model/BladeRestPoint")

func _ready() -> void:
	pass

func get_blade_rest_point() -> Node3D:
	if not blade_rest_point:
		blade_rest_point = get_node_or_null("Model/BladeRestPoint")
	return blade_rest_point

# Animação de virar / manipular alimento
func play_action_animation() -> void:
	if not model:
		model = get_node_or_null("Model")
	if not model:
		return

	var tween = create_tween()
	tween.tween_property(model, "rotation:x", deg_to_rad(-22.0), 0.09).set_trans(Tween.TRANS_SINE)
	tween.tween_property(model, "rotation:x", deg_to_rad(18.0), 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(model, "rotation:x", deg_to_rad(15.0), 0.14)
