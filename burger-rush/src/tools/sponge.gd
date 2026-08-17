class_name Sponge
extends Node3D

# ================================================================
# BUCHA DE LIMPEZA (SISTEMA DE HIGIENIZAÇÃO)
#
# Estados:
#  - BUCHA LIMPA: Capaz de limpar 1 objeto sujo (mesa, grelha, etc.)
#  - BUCHA SUJA: Impede nova limpeza até ser lavada na pia
# ================================================================

@export var tool_name: String = "Bucha de Limpeza"
@export var tool_id: String = "sponge"
@export var is_dirty: bool = false:
	set(val):
		is_dirty = val
		_update_visuals()

@onready var model: Node3D = get_node_or_null("Model")
@onready var yellow_body: MeshInstance3D = get_node_or_null("Model/YellowBody")
@onready var green_pad: MeshInstance3D = get_node_or_null("Model/GreenScourPad")

var _is_animating: bool = false

func _ready() -> void:
	_update_visuals()

func is_clean() -> bool:
	return not is_dirty

func set_dirty() -> void:
	is_dirty = true

func set_clean() -> void:
	is_dirty = false

func _update_visuals() -> void:
	if not yellow_body:
		yellow_body = get_node_or_null("Model/YellowBody")
	if not green_pad:
		green_pad = get_node_or_null("Model/GreenScourPad")

	if yellow_body:
		var mat_yellow = StandardMaterial3D.new()
		if is_dirty:
			# Manchas escuras de gordura e sujeira acumulada
			mat_yellow.albedo_color = Color(0.42, 0.35, 0.22, 1.0)
			mat_yellow.roughness = 0.95
		else:
			# Amarelo vivo e limpo
			mat_yellow.albedo_color = Color(0.94, 0.84, 0.18, 1.0)
			mat_yellow.roughness = 0.85
		yellow_body.material_override = mat_yellow

	if green_pad:
		var mat_green = StandardMaterial3D.new()
		if is_dirty:
			mat_green.albedo_color = Color(0.18, 0.15, 0.10, 1.0)
			mat_green.roughness = 0.98
		else:
			mat_green.albedo_color = Color(0.12, 0.44, 0.18, 1.0)
			mat_green.roughness = 0.92
		green_pad.material_override = mat_green

func play_action_animation() -> void:
	play_scrub_animation()

func play_scrub_animation() -> void:
	if not model or _is_animating:
		return
	_is_animating = true
	var tween = create_tween()
	tween.tween_property(model, "position:x", -0.025, 0.08)
	tween.parallel().tween_property(model, "position:y", -0.015, 0.08)
	tween.parallel().tween_property(model, "rotation_degrees:z", 8.0, 0.08)

	tween.tween_property(model, "position:x", 0.025, 0.10)
	tween.parallel().tween_property(model, "rotation_degrees:z", -8.0, 0.10)

	tween.tween_property(model, "position:x", 0.0, 0.08)
	tween.parallel().tween_property(model, "position:y", 0.0, 0.08)
	tween.parallel().tween_property(model, "rotation_degrees:z", 0.0, 0.08)
	tween.finished.connect(func(): _is_animating = false)

func play_wash_animation() -> void:
	if not model:
		return
	var tween = create_tween()
	tween.tween_property(model, "position:y", -0.04, 0.15)
	tween.tween_property(model, "position:y", 0.0, 0.15)
