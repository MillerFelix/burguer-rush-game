class_name CustomerSpawner
extends Node3D

@export var customer_scene: PackedScene = preload("res://src/customers/customer.tscn")
@export var spawn_interval: float = 12.0
@export var auto_spawn: bool = true

@export var spawn_position: Vector3 = Vector3(0.0, 0.0, 10.5)
@export var exit_position: Vector3 = Vector3(0.0, 0.0, 10.5)

var active_customers: Array[Customer] = []
var spawn_timer: float = 0.0
var current_target_interval: float = 12.0

func _ready() -> void:
	if not customer_scene:
		customer_scene = load("res://src/customers/customer.tscn")
	current_target_interval = _calculate_interval_for_time(9.0)
	spawn_timer = current_target_interval - 3.0

func _process(delta: float) -> void:
	active_customers = active_customers.filter(func(c): return is_instance_valid(c) and c.state != Customer.State.FINISHED)

	if not auto_spawn:
		return

	var clock = GameClock.get_instance()
	if clock and clock.state != GameClock.State.OPEN:
		return

	var table_mgr = TableManager.get_instance()
	if not table_mgr and get_parent():
		table_mgr = get_parent().get_node_or_null("TableManager")
	if not table_mgr or table_mgr.get_available_table_count() <= 0:
		return

	var total_capacity = table_mgr.get_total_seat_capacity()
	if active_customers.size() < total_capacity:
		spawn_timer += delta

		var current_hour_f = 9.0
		if clock:
			current_hour_f = clock.current_hour + (clock.current_minute / 60.0)

		if spawn_timer >= current_target_interval:
			spawn_timer = 0.0
			current_target_interval = _calculate_interval_for_time(current_hour_f)
			spawn_customer_group()

func _calculate_interval_for_time(time_h: float) -> float:
	# CURVA DE INTERVALOS DINÂMICOS:
	# 09:00 - 11:00 (Manhã calma):     16.0s a 22.0s
	# 11:00 - 11:30 (Transição almoço): 10.0s a 14.0s
	# 11:30 - 14:00 (Pico Almoço):      5.0s a 8.0s
	# 14:00 - 17:00 (Tarde calma):      13.0s a 18.0s
	# 17:00 - 18:30 (Fim de Tarde):     8.5s a 12.0s
	# 18:30 - 21:00 (Pico Jantar):      5.5s a 8.5s
	if time_h < 11.0:
		return randf_range(16.0, 22.0)
	elif time_h < 11.5:
		return randf_range(10.0, 14.0)
	elif time_h < 14.0:
		return randf_range(5.0, 8.0)
	elif time_h < 17.0:
		return randf_range(13.0, 18.0)
	elif time_h < 18.5:
		return randf_range(8.5, 12.0)
	elif time_h <= 21.0:
		return randf_range(5.5, 8.5)
	return randf_range(18.0, 25.0)

func _pick_group_size_for_time(time_h: float) -> Dictionary:
	var rand_val = randf()
	var group_size = 1
	var has_child = false

	if time_h < 11.0:
		# Manhã: Predominância de solo (65%) e casais (35%)
		if rand_val < 0.65:
			group_size = 1
		else:
			group_size = 2
			has_child = (randf() < 0.15)

	elif time_h < 11.5:
		# Transição Almoço
		if rand_val < 0.35:
			group_size = 1
		elif rand_val < 0.80:
			group_size = 2
			has_child = (randf() < 0.25)
		else:
			group_size = 3
			has_child = (randf() < 0.40)

	elif time_h < 14.0:
		# Pico Almoço: Casais e Grupos maiores (2 a 4 pessoas)
		if rand_val < 0.10:
			group_size = 1
		elif rand_val < 0.50:
			group_size = 2
			has_child = (randf() < 0.30)
		elif rand_val < 0.80:
			group_size = 3
			has_child = (randf() < 0.55)
		else:
			group_size = 4
			has_child = (randf() < 0.65)

	elif time_h < 17.0:
		# Tarde tranquila: 1 ou 2 pessoas
		if rand_val < 0.55:
			group_size = 1
		elif rand_val < 0.90:
			group_size = 2
			has_child = (randf() < 0.20)
		else:
			group_size = 3
			has_child = (randf() < 0.35)

	elif time_h < 18.5:
		# Fim de tarde: crescendo para grupos
		if rand_val < 0.25:
			group_size = 1
		elif rand_val < 0.70:
			group_size = 2
			has_child = (randf() < 0.30)
		elif rand_val < 0.90:
			group_size = 3
			has_child = (randf() < 0.45)
		else:
			group_size = 4
			has_child = (randf() < 0.50)

	else:
		# Pico Noite (18:30 - 21:00): Grupos de amigos e famílias (2 a 4 pessoas)
		if rand_val < 0.10:
			group_size = 1
		elif rand_val < 0.45:
			group_size = 2
			has_child = (randf() < 0.35)
		elif rand_val < 0.75:
			group_size = 3
			has_child = (randf() < 0.60)
		else:
			group_size = 4
			has_child = (randf() < 0.70)

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
	var time_h = 9.0
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

	if not table:
		return []

	var spawned_group: Array[Customer] = []

	for i in range(group_size):
		var customer = customer_scene.instantiate() as Customer
		add_child(customer)

		var is_kid = (has_child and i >= (group_size - 1)) or (has_child and group_size == 4 and i >= 2)
		var spawn_offset = Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.3, 0.3))
		var member_spawn_pos = spawn_position + spawn_offset

		customer.setup(member_spawn_pos, exit_position, "", is_kid)
		var seat_pos = table.occupy_seat(customer)
		customer.assign_seat(table, seat_pos, i + 1)

		active_customers.append(customer)
		spawned_group.append(customer)

	return spawned_group

func spawn_customer(product_id: String = "") -> Customer:
	if not customer_scene:
		customer_scene = load("res://src/customers/customer.tscn")

	var table_mgr = TableManager.get_instance()
	if not table_mgr and get_parent():
		table_mgr = get_parent().get_node_or_null("TableManager")
	if not table_mgr:
		return null

	var table = table_mgr.get_available_table()
	if not table:
		return null

	var customer = customer_scene.instantiate() as Customer
	add_child(customer)
	customer.setup(spawn_position, exit_position, product_id, false)
	var seat_pos = table.occupy_seat(customer)
	customer.assign_seat(table, seat_pos, 1)

	active_customers.append(customer)
	return customer
