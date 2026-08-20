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

var held_food: Node3D = null

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var model: Node3D = get_node_or_null("Model")
@onready var blade_rest_point: Node3D = get_node_or_null("Model/BladeRestPoint")

func _ready() -> void:
	pass

func get_blade_rest_point() -> Node3D:
	if not blade_rest_point:
		blade_rest_point = get_node_or_null("Model/BladeRestPoint")
	return blade_rest_point

func has_patty() -> bool:
	return held_food != null and is_instance_valid(held_food)

func has_item() -> bool:
	return has_patty()

func get_held_patty() -> Node3D:
	if has_patty():
		return held_food
	return null

func attach_patty(patty: Node3D) -> void:
	if not patty or not is_instance_valid(patty):
		return
	held_food = patty
	if patty.get_parent():
		patty.get_parent().remove_child(patty)
	
	var rest_pt = get_blade_rest_point()
	if rest_pt:
		rest_pt.add_child(patty)
		patty.position = Vector3.ZERO
		patty.rotation = Vector3.ZERO
		patty.scale = Vector3.ONE
	
	if "is_held" in patty:
		patty.is_held = true
	if "location" in patty:
		patty.location = 1 # ItemLocation.HELD

func detach_patty() -> Node3D:
	var p = held_food
	held_food = null
	if p and is_instance_valid(p) and p.get_parent():
		p.get_parent().remove_child(p)
	return p

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
