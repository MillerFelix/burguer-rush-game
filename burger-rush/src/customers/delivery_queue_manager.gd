class_name DeliveryQueueManager
extends Node3D

signal car_spawned(car: Node3D)
signal car_served(car: Node3D)

static var instance: DeliveryQueueManager = null

@export var car_scene: PackedScene = preload("res://src/environment/delivery_car.tscn")
@export var max_queue_size: int = 2
@export var auto_spawn: bool = true

# Posições da fila de delivery ao longo da rua dos fundos (Z = -11.5)
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
var is_night: bool = false

var last_checked_day: int = -1
var daily_scheduled_cars: Array[float] = []
var daily_cars_spawned: int = 0

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	instance = self
	_init_day_demand()

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

func _init_day_demand() -> void:
	var clock = _get_clock()
	var day_num: int = int(clock.get("day_number")) if (clock and clock.get("day_number") != null) else 1
	last_checked_day = day_num
	daily_scheduled_cars.clear()
	daily_cars_spawned = 0

	# Sorteio controlado de demanda de Drive-Thru (Raro e Ocasional: 0 a 4 carros por dia)
	var rand_val = randf()
	var total_cars_today = 0

	if rand_val < 0.25:
		total_cars_today = 0 # 25% dos dias: Nenhum carro no drive-thru
	elif rand_val < 0.65:
		total_cars_today = 1 # 40% dos dias: 1 carro ocasional
	elif rand_val < 0.90:
		total_cars_today = 2 # 25% dos dias: 2 carros
	else:
		total_cars_today = randi_range(3, 4) # 10% dos dias: 3 a 4 carros (pico raro)

	if total_cars_today > 0:
		# Distribui horários aleatórios e não-fixos durante o horário de funcionamento (11:00 às 21:00)
		var possible_windows = [
			randf_range(11.2, 13.8), # Almoço
			randf_range(14.5, 17.2), # Tarde
			randf_range(18.0, 20.8)  # Jantar
		]
		possible_windows.shuffle()

		for i in range(min(total_cars_today, possible_windows.size())):
			daily_scheduled_cars.append(possible_windows[i])

		if total_cars_today > possible_windows.size():
			daily_scheduled_cars.append(randf_range(19.2, 21.2))

		daily_scheduled_cars.sort()

func _process(delta: float) -> void:
	# Limpa instâncias inválidas
	car_queue = car_queue.filter(func(c): return is_instance_valid(c) and c.get("current_state") != 5)

	if not auto_spawn:
		return

	var clock = _get_clock()
	if clock and (clock.get("state") != 1 or clock.get("current_hour") >= 22):
		return

	if clock and clock.get("day_number") != last_checked_day:
		_init_day_demand()

	var current_hour_f = 10.0
	if clock:
		current_hour_f = clock.get("current_hour") + (clock.get("current_minute") / 60.0)

	# Verifica se há carro agendado para o horário atual
	if daily_cars_spawned < daily_scheduled_cars.size():
		var next_time = daily_scheduled_cars[daily_cars_spawned]
		if current_hour_f >= next_time and car_queue.size() < max_queue_size:
			daily_cars_spawned += 1
			spawn_car()

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
		return car.get("current_state") == 3 or (car.get("current_order") == null and car.position.distance_to(QUEUE_POSITIONS[0]) <= 0.5)
	return false

func get_queue_count() -> int:
	return car_queue.size()

func set_night_mode(night: bool) -> void:
	is_night = night
	for car in car_queue:
		if is_instance_valid(car) and car.has_method("set_night_mode"):
			car.set_night_mode(is_night)
