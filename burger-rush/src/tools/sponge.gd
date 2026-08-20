class_name Sponge
extends Node3D

# =============================================================================
# BURGER RUSH - BUCHA DE LIMPEZA COM ANIMAÇÃO FÍSICA E PROGRESSÃO REALISTA
# =============================================================================

@export var tool_name: String = "Bucha de Limpeza"
@export var tool_id: String = "sponge"
@export var is_dirty: bool = false:
	set(val):
		is_dirty = val
		_update_visuals()

@onready var model: Node3D = get_node_or_null("Model")
@onready var yellow_body: MeshInstance3D = get_node_or_null("Model/YellowBody")
@onready var green_pad: MeshInstance3D = get_node_or_null("Model/GreenScourPad")

var _is_scrubbing_continuous: bool = false
var _scrub_cycle_time: float = 0.0
var _is_animating_wash: bool = false

var _initial_pos: Vector3 = Vector3.ZERO
var _initial_rot: Vector3 = Vector3.ZERO

func _ready() -> void:
	if model:
		_initial_pos = model.position
		_initial_rot = model.rotation
	_update_visuals()

func _process(delta: float) -> void:
	if _is_scrubbing_continuous and model:
		_scrub_cycle_time += delta
		# Movimento circular e lateral contínuo e vigoroso de esfregação
		var speed = 22.0
		model.position = _initial_pos + Vector3(
			sin(_scrub_cycle_time * speed) * 0.042,
			-0.022 + absf(sin(_scrub_cycle_time * speed * 2.0)) * 0.008,
			cos(_scrub_cycle_time * speed) * 0.032
		)
		model.rotation = _initial_rot + Vector3(
			deg_to_rad(cos(_scrub_cycle_time * speed) * 9.0),
			0.0,
			deg_to_rad(sin(_scrub_cycle_time * speed) * 14.0)
		)
	elif not _is_animating_wash and model and not _is_scrubbing_continuous:
		if model.position != _initial_pos or model.rotation != _initial_rot:
			model.position = model.position.move_toward(_initial_pos, 1.2 * delta)
			model.rotation = model.rotation.move_toward(_initial_rot, 10.0 * delta)

func is_clean() -> bool:
	return not is_dirty

func set_dirty() -> void:
	is_dirty = true
	stop_scrub_continuous()
	var p = get_parent()
	while p != null:
		if p is Player or "sponge_is_dirty" in p:
			p.set("sponge_is_dirty", true)
			break
		p = p.get_parent()

func set_clean() -> void:
	is_dirty = false
	var p = get_parent()
	while p != null:
		if p is Player or "sponge_is_dirty" in p:
			p.set("sponge_is_dirty", false)
			break
		p = p.get_parent()

func _update_visuals() -> void:
	if not yellow_body:
		yellow_body = get_node_or_null("Model/YellowBody")
	if not green_pad:
		green_pad = get_node_or_null("Model/GreenScourPad")

	if yellow_body:
		var mat_yellow = StandardMaterial3D.new()
		if is_dirty:
			# Manchas escuras de gordura e sujeira acumulada
			mat_yellow.albedo_color = Color(0.40, 0.32, 0.20, 1.0)
			mat_yellow.roughness = 0.95
		else:
			# Amarelo vivo e limpo
			mat_yellow.albedo_color = Color(0.95, 0.85, 0.18, 1.0)
			mat_yellow.roughness = 0.80
		yellow_body.material_override = mat_yellow

	if green_pad:
		var mat_green = StandardMaterial3D.new()
		if is_dirty:
			mat_green.albedo_color = Color(0.16, 0.14, 0.09, 1.0)
			mat_green.roughness = 0.98
		else:
			mat_green.albedo_color = Color(0.12, 0.48, 0.18, 1.0)
			mat_green.roughness = 0.88
		green_pad.material_override = mat_green

func start_scrub_continuous() -> void:
	_is_scrubbing_continuous = true

func stop_scrub_continuous() -> void:
	_is_scrubbing_continuous = false

func play_action_animation() -> void:
	play_scrub_animation()

func play_scrub_animation() -> void:
	start_scrub_continuous()

func play_wash_animation() -> void:
	if not model:
		return
	_is_animating_wash = true
	stop_scrub_continuous()
	var tween = create_tween()
	tween.tween_property(model, "position:y", -0.05, 0.15)
	tween.tween_property(model, "position:y", 0.0, 0.15)
	tween.finished.connect(func(): _is_animating_wash = false)
