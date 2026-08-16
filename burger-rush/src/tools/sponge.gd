class_name Sponge
extends Node3D

# ================================================================
# BUCHA DE LIMPEZA PESADA (HEAVY-DUTY GRILL SCRUBBER)
#
# Ferramenta para limpeza e remoção de gordura/sujeira da chapa.
# ================================================================

@export var tool_name: String = "Bucha de Limpeza"
@export var tool_id: String = "sponge"

@onready var model: Node3D = get_node_or_null("Model")

func _ready() -> void:
	pass

func play_action_animation() -> void:
	if not model:
		return
	var tween = create_tween()
	tween.tween_property(model, "position:y", -0.04, 0.1)
	tween.tween_property(model, "position:y", 0.0, 0.15)
