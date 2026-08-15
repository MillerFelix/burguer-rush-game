class_name ParkedCar
extends Node3D

@export var custom_paint_color: Color = Color(0, 0, 0, 0)

var paint_colors = [
	Color(0.92, 0.93, 0.96), # Branco Alpino
	Color(0.12, 0.13, 0.15), # Preto Ônix
	Color(0.48, 0.50, 0.54), # Cinza Chumbo
	Color(0.82, 0.84, 0.88), # Prata Metálico
	Color(0.82, 0.16, 0.16), # Vermelho Rubi
	Color(0.18, 0.42, 0.82), # Azul Royal
	Color(0.16, 0.52, 0.32), # Verde Esmeralda
	Color(0.92, 0.78, 0.18), # Amarelo Canário
	Color(0.86, 0.48, 0.16), # Laranja Cobre
	Color(0.24, 0.32, 0.45)  # Azul Ardósia
]

func _ready() -> void:
	_apply_paint()

func _apply_paint() -> void:
	var chosen_color = custom_paint_color
	if chosen_color.a <= 0.01:
		chosen_color = paint_colors[randi() % paint_colors.size()]

	var paint_mat = StandardMaterial3D.new()
	paint_mat.albedo_color = chosen_color
	paint_mat.roughness = 0.30
	paint_mat.metallic = 0.35

	var chassis = get_node_or_null("Model/Chassis") as MeshInstance3D
	var roof = get_node_or_null("Model/Roof") as MeshInstance3D
	if chassis: chassis.material_override = paint_mat
	if roof: roof.material_override = paint_mat
