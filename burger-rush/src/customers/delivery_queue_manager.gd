class_name DeliveryQueueManager
extends Node3D

signal car_spawned(car: Node3D)
signal car_served(car: Node3D)

static var instance: DeliveryQueueManager = null

@export var car_scene: PackedScene = preload("res://src/environment/delivery_car.tscn")
@export var max_queue_size: int = 4
@export var auto_spawn: bool = true
@export var base_spawn_interval: float = 20.0

# Posições da fila de delivery ao longo da rua dos fundos (Z = -11.5)
# Pos 0: Exatamente em frente à janela de atendimento (X = 6.45)
# Pos 1, 2, 3: Alinhados longitudinalmente atrás do primeiro com distância segura (6.2m)
const QUEUE_POSITIONS = [
	Vector3(6.45, 0.0, -11.5),  # Janela de atendimento
	Vector3(12.65, 0.0, -11.5), # 2º Carro
	Vector3(18.85, 0.0, -11.5), # 3º Carro
	Vector3(25.05, 0.0, -11.5)  # 4º Carro
]

const SPAWN_POS = Vector3(38.0, 0.0, -11.5) # Entrada leste
const EXIT_POS = Vector3(-42.0, 0.0, -11.5) # Saída oeste

var car_queue: Array[Node3D] = []
var next_car_id: int = 1
var spawn_timer: float = 0.0
var current_target_interval: float = 20.0
var is_night: bool = false

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	instance = self
	current_target_interval = _calculate_interval_for_time(10.0)
	spawn_timer = current_target_interval - 4.0 # Primeiro carro chega logo após abrir

func static_get() -> DeliveryQueueManager:
	return instance

static func get_instance() -> DeliveryQueueManager:
	return instance

func has_active_cars() -> bool:
	car_queue = car_queue.filter(func(c): return is_instance_valid(c) and c.get("current_state") != 5)
	return not car_queue.is_empty()

func _get_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _process(delta: float) -> void:
	# Limpa instâncias inválidas
	car_queue = car_queue.filter(func(c): return is_instance_valid(c) and c.get("current_state") != 5)

	if not auto_spawn:
		return

	var clock = _get_clock()
	if clock and (clock.get("state") != 1 or clock.get("current_hour") >= 22):
		return

	var current_hour_f = 10.0
	if clock:
		current_hour_f = clock.get("current_hour") + (clock.get("current_minute") / 60.0)

	if car_queue.size() < max_queue_size:
		spawn_timer += delta
		if spawn_timer >= current_target_interval:
			spawn_timer = 0.0
			current_target_interval = _calculate_interval_for_time(current_hour_f)
			spawn_car()

func _calculate_interval_for_time(time_h: float) -> float:
	# CURVA DE INTERVALOS EQUILIBRADOS PARA DRIVE-THRU (Demanda Secundária Reduzida em 50%):
	var base_int: float = 200.0
	if time_h < 11.5:
		base_int = randf_range(220.0, 340.0) # Abertura calma
	elif time_h < 14.0:
		base_int = randf_range(150.0, 220.0) # Almoço moderado
	elif time_h < 17.0:
		base_int = randf_range(200.0, 300.0) # Tarde espaçada
	elif time_h < 19.0:
		base_int = randf_range(170.0, 260.0) # Fim de tarde
	elif time_h <= 22.0:
		base_int = randf_range(145.0, 210.0) # Jantar moderado
	else:
		base_int = randf_range(240.0, 360.0) # Fechamento lento

	# Eventos diários de alta movimentação (chuva, tempestade, etc.) aceleram o fluxo adequadamente
	var event_mgr = DailyEventManager.instance
	if not event_mgr and is_inside_tree() and get_tree() and get_tree().root:
		event_mgr = get_tree().root.find_child("DailyEventManager", true, false) as DailyEventManager

	if event_mgr and event_mgr.has_method("get_drive_thru_multiplier"):
		var mult = event_mgr.get_drive_thru_multiplier()
		if mult > 0.01:
			base_int = base_int / mult

	return base_int

func spawn_car() -> Node3D:
	if not car_scene:
		car_scene = load("res://src/environment/delivery_car.tscn")

	if car_queue.size() >= max_queue_size:
		return null

	var car = car_scene.instantiate() as Node3D
	car.set("car_id", next_car_id)
	next_car_id += 1
	add_child(car)

	car.position = SPAWN_POS
	var target_idx = car_queue.size()
	car_queue.append(car)

	if car.has_method("set_target_position"):
		car.set_target_position(QUEUE_POSITIONS[target_idx], target_idx)
	if car.has_method("set_night_mode"):
		car.set_night_mode(is_night)

	if car.has_signal("order_completed"):
		car.order_completed.connect(_on_car_order_completed.bind(car))
	if car.has_signal("car_left"):
		car.car_left.connect(_on_car_left)

	car_spawned.emit(car)
	return car

func _on_car_order_completed(order: Order, car: Node3D) -> void:
	car_served.emit(car)

func _on_car_left(car: Node3D) -> void:
	if car_queue.has(car):
		car_queue.erase(car)
	_advance_queue()

func _advance_queue() -> void:
	# Limpa referências inválidas
	car_queue = car_queue.filter(func(c): return is_instance_valid(c) and c.get("current_state") != 5)

	# Atualiza o destino de todos os carros na fila
	for i in range(car_queue.size()):
		var c = car_queue[i]
		if is_instance_valid(c) and i < QUEUE_POSITIONS.size() and c.has_method("set_target_position"):
			c.set_target_position(QUEUE_POSITIONS[i], i)

func get_car_at_window() -> Node3D:
	if car_queue.size() > 0 and is_instance_valid(car_queue[0]):
		var first = car_queue[0]
		if first.get("target_queue_index") == 0:
			return first
	return null

func has_waiting_car_for_order() -> bool:
	var car = get_car_at_window()
	if car and is_instance_valid(car):
		# CarState.AT_WINDOW_WAITING_ORDER == 3
		return car.get("current_state") == 3 or (car.get("current_order") == null and car.position.distance_to(QUEUE_POSITIONS[0]) <= 0.5)
	return false

func get_queue_count() -> int:
	return car_queue.size()

func set_night_mode(night: bool) -> void:
	is_night = night
	for car in car_queue:
		if is_instance_valid(car) and car.has_method("set_night_mode"):
			car.set_night_mode(is_night)
