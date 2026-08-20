class_name CustomerSpawner
extends Node3D

enum DayIntensity {
	CALM,
	NORMAL,
	BUSY,
	VERY_BUSY
}

@export var customer_scene: PackedScene = preload("res://src/customers/customer.tscn")
@export var auto_spawn: bool = true

@export var spawn_position: Vector3 = Vector3(0.0, 0.0, 10.5)
@export var exit_position: Vector3 = Vector3(0.0, 0.0, 10.5)
@export var spawn_interval: float = 35.0

var active_customers: Array[Customer] = []
var spawn_timer: float = 0.0
var current_target_interval: float = 35.0

var current_day_intensity: DayIntensity = DayIntensity.CALM
var last_checked_day: int = -1
var target_daily_customers: int = 18
var daily_customers_spawned: int = 0

func _ready() -> void:
	if not customer_scene:
		customer_scene = load("res://src/customers/customer.tscn")
	_update_day_intensity()
	current_target_interval = _calculate_interval_for_time(10.0)
	# Início do dia com pequeno atraso para o jogador respirar e abrir o restaurante
	spawn_timer = 0.0

var _cached_clock: Node = null
var _filter_timer: float = 0.0

func has_active_customers() -> bool:
	active_customers = active_customers.filter(func(c): return is_instance_valid(c) and c.state != Customer.State.FINISHED)
	return not active_customers.is_empty()

func _get_clock() -> Node:
	if _cached_clock and is_instance_valid(_cached_clock):
		return _cached_clock
	if is_inside_tree() and get_tree() and get_tree().root:
		_cached_clock = get_tree().root.find_child("GameClock", true, false)
	return _cached_clock

func _process(delta: float) -> void:
	# Filtra clientes válidos a cada 0.3s em vez de 60 vezes por segundo
	_filter_timer -= delta
	if _filter_timer <= 0.0:
		_filter_timer = 0.3
		active_customers = active_customers.filter(func(c): return is_instance_valid(c) and c.state != Customer.State.FINISHED)

	if not auto_spawn:
		return

	var clock = _get_clock()
	if clock and (clock.get("state") != 1 or clock.get("current_hour") >= 22):
		return

	# Atualiza intensidade e metas caso o dia tenha virado
	if clock and clock.get("day_number") != last_checked_day:
		_update_day_intensity()

	var current_hour_f = 10.0
	if clock:
		current_hour_f = clock.get("current_hour") + (clock.get("current_minute") / 60.0)

	# Limite rigoroso de clientes simultâneos no salão para não sobrecarregar o jogador
	var max_concurrent = _get_max_concurrent_customers(current_hour_f)
	var dining_customers_count = _count_dining_customers()

	if dining_customers_count < max_concurrent:
		spawn_timer += delta

		if spawn_timer >= current_target_interval:
			spawn_timer = 0.0
			current_target_interval = _calculate_interval_for_time(current_hour_f)
			daily_customers_spawned += 1
			spawn_customer_group()

func _update_day_intensity() -> void:
	var clock = _get_clock()
	var day_num: int = int(clock.get("day_number")) if (clock and clock.get("day_number") != null) else 1
	last_checked_day = day_num
	daily_customers_spawned = 0

	# Dia da semana (1 = Segunda, 7 = Domingo)
	var day_of_week: int = int(clock.get("day_of_week")) if (clock and clock.get("day_of_week") != null) else (((day_num - 1) % 7) + 1)
	var rand_val = randf()

	# Distribuição aleatória e variada por dia (evita escada fixa)
	if day_of_week in [1, 2, 3]:
		# Dias de semana tranquilos (Segunda a Quarta): 60% Calmo, 35% Normal, 5% Movimentado
		if rand_val < 0.60:
			current_day_intensity = DayIntensity.CALM
			target_daily_customers = randi_range(12, 16)
		elif rand_val < 0.95:
			current_day_intensity = DayIntensity.NORMAL
			target_daily_customers = randi_range(16, 20)
		else:
			current_day_intensity = DayIntensity.BUSY
			target_daily_customers = randi_range(20, 24)
	elif day_of_week in [4, 5]:
		# Quinta e Sexta: 25% Calmo, 50% Normal, 25% Movimentado
		if rand_val < 0.25:
			current_day_intensity = DayIntensity.CALM
			target_daily_customers = randi_range(14, 17)
		elif rand_val < 0.75:
			current_day_intensity = DayIntensity.NORMAL
			target_daily_customers = randi_range(17, 22)
		else:
			current_day_intensity = DayIntensity.BUSY
			target_daily_customers = randi_range(22, 26)
	else:
		# Fim de semana (Sábado e Domingo): Mais movimento com variação natural
		if rand_val < 0.20:
			current_day_intensity = DayIntensity.NORMAL
			target_daily_customers = randi_range(16, 20)
		elif rand_val < 0.70:
			current_day_intensity = DayIntensity.BUSY
			target_daily_customers = randi_range(20, 25)
		else:
			current_day_intensity = DayIntensity.VERY_BUSY
			target_daily_customers = randi_range(24, 28)

func _get_max_concurrent_customers(time_h: float) -> int:
	# Limite equilibrado de clientes simultâneos no salão (evita sobrecarga no ritmo normal)
	if time_h < 11.5:
		return 2 # Abertura: Máximo 2 pessoas
	elif time_h < 14.5:
		return 3 # Almoço: 3 pessoas simultâneas no salão
	elif time_h < 17.5:
		return 3 # Tarde: 3 pessoas
	elif time_h <= 21.0:
		return 4 # Jantar: 4 pessoas
	return 2 # Encerramento

func _count_dining_customers() -> int:
	var count = 0
	for c in active_customers:
		if is_instance_valid(c) and c.state in [
			Customer.State.ARRIVING,
			Customer.State.GOING_TO_ENTRANCE,
			Customer.State.ENTERING_RESTAURANT,
			Customer.State.GOING_TO_SEAT,
			Customer.State.SITTING,
			Customer.State.SEATED_WAITING_TO_ORDER,
			Customer.State.WAITING_FOR_FOOD,
			Customer.State.EATING
		]:
			count += 1
	return count

func _calculate_interval_for_time(time_h: float) -> float:
	# CURVA DINÂMICA NÃO-LINEAR COM JITTER ALEATÓRIO (10:00 — 22:00):
	var base_interval = 48.0

	if time_h < 11.5:
		base_interval = randf_range(48.0, 72.0) # Abertura calma
	elif time_h < 14.0:
		base_interval = randf_range(32.0, 48.0) # Pico de almoço dinâmico
	elif time_h < 17.5:
		base_interval = randf_range(44.0, 65.0) # Tarde espaçada
	elif time_h <= 20.5:
		base_interval = randf_range(34.0, 50.0) # Pico de jantar dinâmico
	else:
		base_interval = randf_range(55.0, 85.0) # Fechamento lento

	# Multiplicador da Intensidade do Dia
	var intensity_multiplier = 1.0
	match current_day_intensity:
		DayIntensity.CALM:
			intensity_multiplier = 1.25
		DayIntensity.NORMAL:
			intensity_multiplier = 1.0
		DayIntensity.BUSY:
			intensity_multiplier = 0.82
		DayIntensity.VERY_BUSY:
			intensity_multiplier = 0.70

	# Modificadores de Eventos Diários
	var event_demand_mult = 1.0
	if is_inside_tree() and get_tree() and get_tree().root:
		var dem = get_tree().root.find_child("DailyEventManager", true, false)
		if dem and dem.has_method("get_customer_demand_multiplier"):
			event_demand_mult = dem.get_customer_demand_multiplier(time_h) * dem.get_dine_in_multiplier()

	var jitter = randf_range(-4.0, 4.0)
	var final_interval = maxf(24.0, ((base_interval * intensity_multiplier) / maxf(0.2, event_demand_mult)) + jitter)
	return final_interval

func _pick_group_size_for_time(time_h: float) -> Dictionary:
	# DISTRIBUIÇÃO EQUILIBRADA DE TAMANHO DE GRUPO:
	# 60% Solo (1 pessoa), 30% Casal (2 pessoas), 8% Trio (3 pessoas), 2% Família (4 pessoas)
	var rand_val = randf()
	var group_size = 1
	var has_child = false

	if time_h < 11.5:
		# Manhã: Predominância de solo (75%) e duplas (25%)
		if rand_val < 0.75:
			group_size = 1
		else:
			group_size = 2
			has_child = (randf() < 0.10)

	elif time_h < 14.5:
		# Almoço: Solo (55%), Duplas (35%), Pequeno grupo (10%)
		if rand_val < 0.55:
			group_size = 1
		elif rand_val < 0.90:
			group_size = 2
			has_child = (randf() < 0.20)
		else:
			group_size = 3
			has_child = (randf() < 0.35)

	elif time_h < 17.5:
		# Tarde: Solo (70%), Duplas (30%)
		if rand_val < 0.70:
			group_size = 1
		else:
			group_size = 2
			has_child = (randf() < 0.15)

	else:
		# Noite / Jantar: Solo (50%), Duplas (38%), Grupos (10%), Família 4p (2%)
		if rand_val < 0.50:
			group_size = 1
		elif rand_val < 0.88:
			group_size = 2
			has_child = (randf() < 0.25)
		elif rand_val < 0.98:
			group_size = 3
			has_child = (randf() < 0.40)
		else:
			group_size = 4
			has_child = (randf() < 0.50)

	return {"group_size": group_size, "has_child": has_child}

func spawn_customer_group() -> Array[Customer]:
	if not customer_scene:
		customer_scene = load("res://src/customers/customer.tscn")

	var table_mgr = TableManager.get_instance()
	if not table_mgr and get_parent():
		table_mgr = get_parent().get_node_or_null("TableManager")
	if not table_mgr:
		return []

	var clock = GameClock.get_instance()
	var time_h = 10.0
	if clock:
		time_h = clock.current_hour + (clock.current_minute / 60.0)

	var group_info = _pick_group_size_for_time(time_h)
	var group_size = group_info.group_size
	var has_child = group_info.has_child

	var table = table_mgr.get_available_table_for_group(group_size)
	if not table:
		table = table_mgr.get_available_table()
		if table:
			group_size = min(group_size, table.seat_count)

	var spawned_group: Array[Customer] = []

	for i in range(group_size):
		var customer = customer_scene.instantiate() as Customer
		add_child(customer)

		var is_kid = (has_child and i >= (group_size - 1)) or (has_child and group_size == 4 and i >= 2)
		var spawn_offset = Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.3, 0.3))
		var member_spawn_pos = spawn_position + spawn_offset

		customer.setup(member_spawn_pos, exit_position, "", is_kid)
		if table and table.is_available():
			var seat_pos = table.occupy_seat(customer)
			customer.assign_seat(table, seat_pos, i + 1)
		else:
			customer.assign_waiting_area()

		active_customers.append(customer)
		spawned_group.append(customer)

	return spawned_group

func spawn_customer(product_id: String = "") -> Customer:
	if not customer_scene:
		customer_scene = load("res://src/customers/customer.tscn")

	var table_mgr = TableManager.get_instance()
	if not table_mgr and get_parent():
		table_mgr = get_parent().get_node_or_null("TableManager")

	var table = table_mgr.get_available_table() if table_mgr else null

	var customer = customer_scene.instantiate() as Customer
	add_child(customer)
	customer.setup(spawn_position, exit_position, product_id, false)
	if table and table.is_available():
		var seat_pos = table.occupy_seat(customer)
		customer.assign_seat(table, seat_pos, 1)
	else:
		customer.assign_waiting_area()

	active_customers.append(customer)
	return customer
