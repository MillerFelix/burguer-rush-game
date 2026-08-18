class_name DeliveryMotorcycleCourier
extends CharacterBody3D

# =============================================================================
# BURGER RUSH - MOTOBOY COM MOTO (OPERAÇÃO EXTERNA / DRIVE-THRU DE MOTOBOYS)
#
# NPC motorizado que chega pela rua externa leste, percorre o pátio, para
# ao lado da janela de delivery, recolhe a sacola pelo balcão sem entrar no
# restaurante, faz a curva e parte de moto pela avenida externa.
# =============================================================================

const OrderManager = preload("res://src/orders/order_manager.gd")
const Order = preload("res://src/orders/order.gd")

enum State {
	ARRIVING,
	COLLECTING,
	LEAVING,
	FINISHED
}

@export var ride_speed: float = 6.5
var state: State = State.ARRIVING

var target_window_station: Node = null
var held_bag: Node3D = null
var target_order: Order = null

var waypoints: Array[Vector3] = []
var current_waypoint_idx: int = 0

@onready var cargo_slot: Node3D = get_node_or_null("Visuals/Motorcycle/CargoBox/CargoSlot")
var _collect_timer: float = 0.0

func _ready() -> void:
	if not cargo_slot:
		cargo_slot = get_node_or_null("Visuals/Motorcycle/CargoBox/CargoSlot")
	_build_arrival_path()

func _physics_process(delta: float) -> void:
	match state:
		State.ARRIVING:
			_process_movement(delta)
			if _has_reached_destination():
				state = State.COLLECTING
				_collect_timer = 1.0
				velocity = Vector3.ZERO

		State.COLLECTING:
			_collect_timer -= delta
			if _collect_timer <= 0.0:
				_perform_pickup()

		State.LEAVING:
			_process_movement(delta)
			if _has_reached_destination():
				_finalize_delivery()

func _build_arrival_path() -> void:
	waypoints.clear()
	current_waypoint_idx = 0

	var stop_pos = Vector3(10.0, 0.0, -1.2)
	if target_window_station and is_instance_valid(target_window_station):
		var station_pos = target_window_station.global_position if target_window_station.is_inside_tree() else target_window_station.position
		stop_pos = Vector3(station_pos.x + 1.0, 0.0, station_pos.z)

	# Rota de Chegada pela Área Externa / Rua:
	# 1. Rua Frontal -> Entrada lateral leste do restaurante
	waypoints.append(Vector3(12.5, 0.0, 15.0))
	# 2. Pátio lateral leste
	waypoints.append(Vector3(11.0, 0.0, 8.0))
	# 3. Aproximação da janela de atendimento
	waypoints.append(Vector3(10.2, 0.0, 3.0))
	# 4. Parada exatamente ao lado da Janela de Delivery
	waypoints.append(stop_pos)

func _build_exit_path() -> void:
	waypoints.clear()
	current_waypoint_idx = 0

	# Rota de Saída:
	# 1. Avança além da janela de delivery
	waypoints.append(Vector3(10.5, 0.0, -6.5))
	# 2. Faz a curva em direção à saída externa dos fundos
	waypoints.append(Vector3(13.5, 0.0, -11.5))
	# 3. Entra na avenida externa
	waypoints.append(Vector3(26.0, 0.0, -17.5))
	# 4. Acelera pela avenida e sai do mapa jogável
	waypoints.append(Vector3(55.0, 0.0, -17.5))

func _process_movement(delta: float) -> void:
	if current_waypoint_idx >= waypoints.size():
		velocity = Vector3.ZERO
		return

	var target = waypoints[current_waypoint_idx]
	var current_pos = global_position if is_inside_tree() else position
	var dir = target - current_pos
	dir.y = 0.0

	if dir.length() < 0.6:
		current_waypoint_idx += 1
		if current_waypoint_idx >= waypoints.size():
			velocity = Vector3.ZERO
			return

	var move_dir = dir.normalized()
	velocity = move_dir * ride_speed
	move_and_slide()

	# Rotação suave da moto acompanhando a curva da rota
	if move_dir.length_squared() > 0.01:
		var target_rot_y = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 9.0 * delta)

func _has_reached_destination() -> bool:
	return current_waypoint_idx >= waypoints.size()

func _perform_pickup() -> void:
	if target_window_station and is_instance_valid(target_window_station) and target_window_station.has_method("courier_pickup_bag"):
		target_order = target_window_station.current_delivery_order
		held_bag = target_window_station.courier_pickup_bag(self)

		if held_bag:
			if not cargo_slot:
				cargo_slot = get_node_or_null("Visuals/Motorcycle/CargoBox/CargoSlot")

			if cargo_slot:
				cargo_slot.add_child(held_bag)
				held_bag.position = Vector3.ZERO
				held_bag.rotation = Vector3.ZERO
			else:
				add_child(held_bag)
				held_bag.position = Vector3(0.0, 0.8, -0.6)

	state = State.LEAVING
	_build_exit_path()

func _finalize_delivery() -> void:
	state = State.FINISHED

	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	if om and target_order:
		om.process_delivery_handover(target_order, held_bag)

	if is_inside_tree():
		queue_free()
