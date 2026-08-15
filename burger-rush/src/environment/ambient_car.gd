class_name AmbientCar
extends Node3D

@onready var headlight_l: MeshInstance3D = $Model/HeadlightL
@onready var headlight_r: MeshInstance3D = $Model/HeadlightR
@onready var taillight_l: MeshInstance3D = $Model/TaillightL
@onready var taillight_r: MeshInstance3D = $Model/TaillightR

var spot_light: SpotLight3D = null

func _ready() -> void:
	# Cria farol de projeção de luz para a noite
	spot_light = SpotLight3D.new()
	spot_light.light_color = Color(1.0, 0.95, 0.82)
	spot_light.light_energy = 2.0
	spot_light.spot_range = 18.0
	spot_light.spot_angle = 35.0
	spot_light.position = Vector3(2.2, 0.6, 0.0)
	spot_light.rotation_degrees = Vector3(-5.0, 0.0, 0.0) # Aponta para frente no asfalto
	spot_light.visible = false
	add_child(spot_light)

func set_night_mode(is_night: bool) -> void:
	if spot_light:
		spot_light.visible = is_night

	var hl_mat = StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1.0, 0.96, 0.85)
	hl_mat.emission_enabled = is_night
	hl_mat.emission = Color(1.0, 0.95, 0.75) if is_night else Color.BLACK
	hl_mat.emission_energy_multiplier = 3.5 if is_night else 0.0

	var tl_mat = StandardMaterial3D.new()
	tl_mat.albedo_color = Color(0.85, 0.1, 0.1)
	tl_mat.emission_enabled = is_night
	tl_mat.emission = Color(0.9, 0.1, 0.1) if is_night else Color.BLACK
	tl_mat.emission_energy_multiplier = 2.5 if is_night else 0.0

	if headlight_l: headlight_l.material_override = hl_mat
	if headlight_r: headlight_r.material_override = hl_mat
	if taillight_l: taillight_l.material_override = tl_mat
	if taillight_r: taillight_r.material_override = tl_mat
