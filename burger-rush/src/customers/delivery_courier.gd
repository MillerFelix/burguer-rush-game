class_name DeliveryCourier
extends CharacterBody3D

const OrderManager = preload("res://src/orders/order_manager.gd")
const Order = preload("res://src/orders/order.gd")

# =============================================================================
# BURGER RUSH - MOTOBOY / ENTREGADOR DE DELIVERY
#
# NPC autônomo que chega ao restaurante quando há um saco de delivery pronto
# na área de expedição, caminha até o balcão, recolhe fisicamente a sacola,
# sai do restaurante e finaliza a entrega processando a validação e o pagamento.
# =============================================================================

enum CourierState {
	ENTERING,
	COLLECTING,
	LEAVING,
	FINISHED
}

@export var move_speed: float = 3.2
var state: CourierState = CourierState.ENTERING

var target_pickup_station: Node = null
var held_bag: Node3D = null
var target_order: Order = null

var waypoints: Array[Vector3] = []
var current_waypoint_idx: int = 0

@onready var hold_slot: Node3D = get_node_or_null("HoldPosition")
@onready var status_balloon: Label3D = get_node_or_null("StatusBalloon")
@onready var animator: Node = get_node_or_null("HumanoidAnimator")

var _collect_timer: float = 0.0

func _ready() -> void:
	if not hold_slot:
		hold_slot = get_node_or_null("HoldPosition")
	if not status_balloon:
		status_balloon = get_node_or_null("StatusBalloon")
	if not animator:
		animator = get_node_or_null("HumanoidAnimator")

	_build_entry_path()
	_show_balloon("🛵 Cheguei para retirar o delivery!")

func _physics_process(delta: float) -> void:
	match state:
		CourierState.ENTERING:
			_process_movement(delta)
			if _has_reached_destination():
				state = CourierState.COLLECTING
				_collect_timer = 1.0
				velocity = Vector3.ZERO
				if animator and animator.has_method("set_movement_state"):
					animator.set_movement_state(false)

		CourierState.COLLECTING:
			_collect_timer -= delta
			if _collect_timer <= 0.0:
				_perform_pickup()

		CourierState.LEAVING:
			_process_movement(delta)
			if _has_reached_destination():
				_finalize_delivery()

func _build_entry_path() -> void:
	waypoints.clear()
	current_waypoint_idx = 0

	var dest_pos = Vector3(-2.2, 0.0, 1.2)
	if target_pickup_station and is_instance_valid(target_pickup_station):
		dest_pos = target_pickup_station.global_position + Vector3(0.0, 0.0, 1.1)
		dest_pos.y = 0.0

	# Caminho: Fora -> Porta Principal -> Corredor Salão -> Balcão de Coleta
	waypoints.append(Vector3(2.4, 0.0, 8.8))
	waypoints.append(Vector3(2.4, 0.0, 1.5))
	waypoints.append(Vector3(dest_pos.x, 0.0, 1.5))
	waypoints.append(dest_pos)

func _build_exit_path() -> void:
	waypoints.clear()
	current_waypoint_idx = 0

	var pos_x = global_position.x if is_inside_tree() else position.x
	# Caminho de saída: Balcão -> Corredor Salão -> Porta -> Calçada Externa
	waypoints.append(Vector3(pos_x, 0.0, 1.5))
	waypoints.append(Vector3(2.4, 0.0, 1.5))
	waypoints.append(Vector3(2.4, 0.0, 8.8))
	waypoints.append(Vector3(2.4, 0.0, 14.5))

func _process_movement(delta: float) -> void:
	if current_waypoint_idx >= waypoints.size():
		velocity = Vector3.ZERO
		return

	var target = waypoints[current_waypoint_idx]
	var current_pos = global_position if is_inside_tree() else position
	var dir = target - current_pos
	dir.y = 0.0

	if dir.length() < 0.35:
		current_waypoint_idx += 1
		if current_waypoint_idx >= waypoints.size():
			velocity = Vector3.ZERO
			if animator and animator.has_method("set_movement_state"):
				animator.set_movement_state(false)
			return

	var move_dir = dir.normalized()
	velocity = move_dir * move_speed
	move_and_slide()

	# Rotação suave olhando na direção do movimento
	if move_dir.length_squared() > 0.01:
		var target_rot_y = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 10.0 * delta)

	if animator and animator.has_method("set_movement_state"):
		animator.set_movement_state(true)

func _has_reached_destination() -> bool:
	return current_waypoint_idx >= waypoints.size()

func _perform_pickup() -> void:
	if target_pickup_station and is_instance_valid(target_pickup_station) and target_pickup_station.has_method("courier_pickup_bag"):
		target_order = target_pickup_station.current_delivery_order
		held_bag = target_pickup_station.courier_pickup_bag(self)

		if held_bag:
			if hold_slot:
				hold_slot.add_child(held_bag)
				held_bag.position = Vector3.ZERO
				held_bag.rotation = Vector3.ZERO
			else:
				add_child(held_bag)
				held_bag.position = Vector3(0.0, 0.8, -0.4)

			var order_num = target_order.id if target_order else 0
			_show_balloon("📦 Pedido #%03d coletado! Partiu entrega." % order_num)

	state = CourierState.LEAVING
	_build_exit_path()

func _finalize_delivery() -> void:
	state = CourierState.FINISHED

	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	if om and target_order:
		om.process_delivery_handover(target_order, held_bag)

	if is_inside_tree():
		queue_free()

func _show_balloon(text: String) -> void:
	if status_balloon:
		status_balloon.text = text
		status_balloon.visible = true
