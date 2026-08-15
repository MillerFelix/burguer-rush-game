class_name AmbientTraffic
extends Node3D

const CAR_SCENE = preload("res://src/environment/ambient_car.tscn")

const CAR_COLORS: Array[Color] = [
	Color(0.85, 0.18, 0.18, 1.0), # Vermelho
	Color(0.18, 0.42, 0.85, 1.0), # Azul Cobalto
	Color(0.92, 0.75, 0.18, 1.0), # Amarelo Táxi
	Color(0.22, 0.58, 0.32, 1.0), # Verde Floresta
	Color(0.94, 0.94, 0.96, 1.0), # Branco Pérola
	Color(0.24, 0.25, 0.28, 1.0), # Cinza Chumbo
	Color(0.88, 0.45, 0.18, 1.0)  # Laranja
]

var spawn_timer: float = 1.5
var next_spawn_interval: float = 2.8

class TrafficVehicle:
	var node: Node3D
	var speed: float
	var direction: float # +1 = indo para +X, -1 = indo para -X

var active_vehicles: Array[TrafficVehicle] = []
var is_night_mode: bool = false

func _enter_tree() -> void:
	if active_vehicles.is_empty():
		_spawn_vehicle(0, randf_range(-15.0, 15.0))
		_spawn_vehicle(2, randf_range(-15.0, 15.0))

func _ready() -> void:
	if active_vehicles.is_empty():
		_spawn_vehicle(randi() % 4, randf_range(-15.0, 15.0))

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= next_spawn_interval:
		spawn_timer = 0.0
		next_spawn_interval = randf_range(2.5, 5.0)
		var lane_idx = randi() % 4
		_spawn_vehicle(lane_idx)

	# Atualiza movimentação dos veículos
	var i = active_vehicles.size() - 1
	while i >= 0:
		var v = active_vehicles[i]
		if not is_instance_valid(v.node):
			active_vehicles.remove_at(i)
			i -= 1
			continue

		v.node.position.x += v.speed * v.direction * delta

		# Despawn fora do mapa
		if (v.direction > 0 and v.node.position.x > 50.0) or (v.direction < 0 and v.node.position.x < -50.0):
			v.node.queue_free()
			active_vehicles.remove_at(i)

		i -= 1

func set_night_mode(enabled: bool) -> void:
	is_night_mode = enabled
	for v in active_vehicles:
		if is_instance_valid(v.node) and v.node.has_method("set_night_mode"):
			v.node.set_night_mode(enabled)

func _spawn_vehicle(lane_type: int, custom_x: float = -999.0) -> void:
	var car = CAR_SCENE.instantiate() as Node3D
	add_child(car)

	if car.has_method("set_night_mode"):
		car.set_night_mode(is_night_mode)

	var color = CAR_COLORS[randi() % CAR_COLORS.size()]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	mat.metallic = 0.2

	var chassis = car.get_node_or_null("Model/Chassis") as MeshInstance3D
	var roof = car.get_node_or_null("Model/Roof") as MeshInstance3D
	if chassis:
		chassis.material_override = mat
	if roof:
		roof.material_override = mat

	var v = TrafficVehicle.new()
	v.node = car
	v.speed = randf_range(8.5, 12.5)

	match lane_type:
		0: # Rua Frontal - Faixa Sul (+X)
			v.direction = 1.0
			var spawn_x = custom_x if custom_x != -999.0 else -48.0
			car.position = Vector3(spawn_x, 0, 15.0)
			car.rotation.y = 0.0
		1: # Rua Frontal - Faixa Norte (-X)
			v.direction = -1.0
			var spawn_x = custom_x if custom_x != -999.0 else 48.0
			car.position = Vector3(spawn_x, 0, 19.8)
			car.rotation.y = PI
		2: # Avenida dos Fundos - Trânsito Urbano Passante (-X)
			v.direction = -1.0
			var spawn_x = custom_x if custom_x != -999.0 else 48.0
			car.position = Vector3(spawn_x, 0, -17.5)
			car.rotation.y = PI
		3: # Avenida dos Fundos - Trânsito Urbano Passante (+X)
			v.direction = 1.0
			var spawn_x = custom_x if custom_x != -999.0 else -48.0
			car.position = Vector3(spawn_x, 0, -20.5)
			car.rotation.y = 0.0

	active_vehicles.append(v)
