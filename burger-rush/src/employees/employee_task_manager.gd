class_name EmployeeTaskManager
extends Node

# =============================================================================
# BURGER RUSH - GERENCIADOR CENTRAL DE TAREFAS DE FUNCIONÁRIOS
#
# Detecta necessidades operacionais do restaurante e distribui tarefas por prioridade:
# 1. Atendimento de mesas (clientes esperando pedido)
# 2. Atendimento de Drive-Thru
# 3. Limpeza de mesas sujas
# 4. Limpeza de poças e manchas no chão
# 5. Limpeza de bancadas / estações de preparo
# 6. Cobrança e checkout no caixa
# 7. Retorno à área de descanso
#
# Garante que dois funcionários ou o jogador não conflitem na mesma tarefa.
# =============================================================================

signal task_created(task: EmployeeTask)
signal task_claimed(task: EmployeeTask, employee: Node)
signal task_completed(task: EmployeeTask)

static var instance: EmployeeTaskManager = null

const EmployeeTask = preload("res://src/employees/employee_task.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")
const Customer = preload("res://src/customers/customer.gd")

var active_tasks: Array[EmployeeTask] = []
var next_task_id: int = 1

# Ponto de descanso padrão no salão próximo à entrada para funcionários livres
@export var default_rest_position: Vector3 = Vector3(2.4, 0.0, 7.5)

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance() -> EmployeeTaskManager:
	return instance

func _ready() -> void:
	instance = self

## Procura e retorna a tarefa de maior prioridade disponível para o funcionário
func get_best_available_task(employee: Node, is_sponge_clean: bool = true) -> EmployeeTask:
	_cleanup_invalid_tasks()
	_scan_world_for_tasks()

	var candidate_tasks = active_tasks.filter(func(t: EmployeeTask):
		return t.is_available() and is_instance_valid(t.target_node)
	)

	# Ordena por prioridade (menor número = maior prioridade)
	candidate_tasks.sort_custom(func(a: EmployeeTask, b: EmployeeTask):
		return a.priority < b.priority
	)

	for task in candidate_tasks:
		# Se a tarefa for de limpeza e a bucha estiver suja, ignora até o funcionário lavar a bucha
		var is_clean_task = task.task_type in [
			EmployeeTask.TaskType.CLEAN_TABLE,
			EmployeeTask.TaskType.CLEAN_PUDDLE,
			EmployeeTask.TaskType.CLEAN_FLOOR_SPOT,
			EmployeeTask.TaskType.CLEAN_STATION
		]
		if is_clean_task and not is_sponge_clean:
			continue

		# Evita roubar tarefa se o jogador estiver muito próximo executando ação
		if _is_player_busy_with_target(task.target_node):
			continue

		return task

	return null

## Reserva uma tarefa exclusivamente para um funcionário
func claim_task(task: EmployeeTask, employee: Node) -> bool:
	if not task or not task.is_available():
		return false

	task.claimed_by = employee
	task_claimed.emit(task, employee)
	return true

## Libera uma tarefa caso o funcionário seja interrompido
func release_task(task: EmployeeTask) -> void:
	if task:
		task.claimed_by = null

## Marca a tarefa como concluída e remove do pool ativo
func complete_task(task: EmployeeTask) -> void:
	if task:
		task.is_completed = true
		task_completed.emit(task)
		active_tasks.erase(task)

func _cleanup_invalid_tasks() -> void:
	active_tasks = active_tasks.filter(func(t: EmployeeTask):
		if t.is_completed or not is_instance_valid(t.target_node) or t.target_node.is_queued_for_deletion():
			return false

		match t.task_type:
			EmployeeTask.TaskType.SERVE_CUSTOMER:
				var table = t.target_node as RestaurantTable
				if not table or table.seated_customers.is_empty():
					return false
				var c = table.seated_customer
				return is_instance_valid(c) and c.state == Customer.State.SEATED_WAITING_TO_ORDER

			EmployeeTask.TaskType.SERVE_DRIVETHRU:
				var deliv_mgr = DeliveryQueueManager.get_instance()
				if not deliv_mgr and is_inside_tree() and get_tree().root:
					deliv_mgr = get_tree().root.find_child("DeliveryQueueManager", true, false)
				if not deliv_mgr:
					return false
				if deliv_mgr.has_method("has_waiting_car_for_order"):
					return deliv_mgr.has_waiting_car_for_order()
				var car = deliv_mgr.get_car_at_window() if deliv_mgr.has_method("get_car_at_window") else null
				return car != null and is_instance_valid(car) and car.get("current_state") == 3

			EmployeeTask.TaskType.CLEAN_TABLE:
				var table = t.target_node as RestaurantTable
				if not table:
					return false
				var dirty = (table.table_state == RestaurantTable.TableState.DIRTY) or (table.has_method("is_dirty") and table.is_dirty())
				return dirty and table.seated_customers.is_empty()

			EmployeeTask.TaskType.CLEAN_PUDDLE, EmployeeTask.TaskType.CLEAN_FLOOR_SPOT:
				if not is_instance_valid(t.target_node) or t.target_node.is_queued_for_deletion():
					return false
				if t.target_node.has_method("is_dirty"):
					return t.target_node.is_dirty()
				return true

			EmployeeTask.TaskType.CLEAN_STATION:
				if not is_instance_valid(t.target_node) or t.target_node.is_queued_for_deletion():
					return false
				if t.target_node.has_method("is_dirty"):
					return t.target_node.is_dirty()
				return true

			EmployeeTask.TaskType.OPERATE_CASHIER:
				var reg = t.target_node as CashRegister
				return reg != null and reg.can_checkout()

			_:
				return true
	)

## Varre as estações e clientes do restaurante para identificar tarefas
func _scan_world_for_tasks() -> void:
	var tree = get_tree()
	if not tree:
		return

	# 1. PRIORIDADE 1: Clientes esperando para fazer pedido na mesa
	var customers = tree.get_nodes_in_group("customers")
	for c in customers:
		var cust = c as Customer
		if cust and is_instance_valid(cust) and cust.state == Customer.State.SEATED_WAITING_TO_ORDER:
			var table = cust.assigned_table
			if table and not _has_active_task_for_target(table, EmployeeTask.TaskType.SERVE_CUSTOMER):
				var pos = table.get_employee_interaction_position() if table.has_method("get_employee_interaction_position") else (table.global_position + Vector3(0.0, 0.0, 0.8))
				_add_task(EmployeeTask.TaskType.SERVE_CUSTOMER, table, pos, 1)

	# 2. PRIORIDADE 2: Drive-Thru esperando atendimento
	var delivery_station = tree.root.find_child("DeliveryStation", true, false)
	if delivery_station and is_instance_valid(delivery_station):
		var deliv_mgr = DeliveryQueueManager.get_instance()
		if not deliv_mgr and tree.root:
			deliv_mgr = tree.root.find_child("DeliveryQueueManager", true, false)
		if deliv_mgr and is_instance_valid(deliv_mgr):
			var has_car = deliv_mgr.has_waiting_car_for_order() if deliv_mgr.has_method("has_waiting_car_for_order") else false
			if not has_car and deliv_mgr.has_method("get_car_at_window"):
				var car = deliv_mgr.get_car_at_window()
				has_car = (car != null and is_instance_valid(car) and car.get("current_state") == 3)

			if has_car:
				if not _has_active_task_for_target(delivery_station, EmployeeTask.TaskType.SERVE_DRIVETHRU):
					var pos = delivery_station.global_position + Vector3(0.0, 0.0, 1.1)
					_add_task(EmployeeTask.TaskType.SERVE_DRIVETHRU, delivery_station, pos, 2)

	# 3. PRIORIDADE 3: Mesas Sujas e Desocupadas
	var table_mgr = TableManager.get_instance()
	if not table_mgr and tree.root:
		table_mgr = tree.root.find_child("TableManager", true, false)
	var tables: Array = []
	if table_mgr and not table_mgr.tables.is_empty():
		tables = table_mgr.tables
	else:
		tables = tree.get_nodes_in_group("tables")
	if tables.is_empty() and tree.root:
		var found = tree.root.find_children("Table*", "RestaurantTable", true, false)
		for ft in found:
			if ft is RestaurantTable and not tables.has(ft):
				tables.append(ft)

	for t in tables:
		var table = t as RestaurantTable
		if table and is_instance_valid(table):
			var is_table_dirty = (table.table_state == RestaurantTable.TableState.DIRTY) or (table.has_method("is_dirty") and table.is_dirty())
			if is_table_dirty and table.seated_customers.is_empty():
				if not _has_active_task_for_target(table, EmployeeTask.TaskType.CLEAN_TABLE):
					var pos = table.get_employee_interaction_position() if table.has_method("get_employee_interaction_position") else (table.global_position + Vector3(0.0, 0.0, 0.8))
					_add_task(EmployeeTask.TaskType.CLEAN_TABLE, table, pos, 3)

	# 4. PRIORIDADE 4: Poças d'água e Manchas no chão
	var puddles = tree.get_nodes_in_group("floor_puddles")
	for p in puddles:
		var puddle = p as Node3D
		if puddle and is_instance_valid(puddle) and not puddle.is_queued_for_deletion():
			var dirty = puddle.is_dirty() if puddle.has_method("is_dirty") else true
			if dirty:
				if not _has_active_task_for_target(puddle, EmployeeTask.TaskType.CLEAN_PUDDLE):
					_add_task(EmployeeTask.TaskType.CLEAN_PUDDLE, puddle, puddle.global_position, 4)

	var spots = tree.get_nodes_in_group("floor_dirt_spots")
	for s in spots:
		var spot = s as Node3D
		if spot and is_instance_valid(spot) and not spot.is_queued_for_deletion():
			var dirty = spot.is_dirty() if spot.has_method("is_dirty") else true
			if dirty:
				if not _has_active_task_for_target(spot, EmployeeTask.TaskType.CLEAN_FLOOR_SPOT):
					_add_task(EmployeeTask.TaskType.CLEAN_FLOOR_SPOT, spot, spot.global_position, 4)

	# 5. PRIORIDADE 5: Bancadas / Estações Sujas (PrepIsland, Grelha, Fritadeira)
	var dirty_stations = tree.get_nodes_in_group("cleanable_stations")
	if dirty_stations.is_empty() and tree.root:
		var p_island = tree.root.find_child("PrepIsland", true, false)
		if p_island: dirty_stations.append(p_island)
		var p_grill = tree.root.find_child("Grill", true, false)
		if p_grill: dirty_stations.append(p_grill)
		var p_fryer = tree.root.find_child("Fryer", true, false)
		if p_fryer: dirty_stations.append(p_fryer)

	for st in dirty_stations:
		var station = st as Node3D
		if station and is_instance_valid(station) and not station.is_queued_for_deletion():
			var dirty = station.is_dirty() if station.has_method("is_dirty") else (station.get("is_dirty") == true)
			if dirty:
				if not _has_active_task_for_target(station, EmployeeTask.TaskType.CLEAN_STATION):
					var pos = station.global_position + Vector3(0.0, 0.0, 0.8)
					_add_task(EmployeeTask.TaskType.CLEAN_STATION, station, pos, 5)

	# 6. PRIORIDADE 6: Fila de Caixa para Pagamento
	var reg = CashRegister.get_instance()
	if not reg and tree and tree.root:
		reg = tree.root.find_child("CashRegister", true, false) as CashRegister
	if reg and is_instance_valid(reg) and reg.can_checkout():
		if not _has_active_task_for_target(reg, EmployeeTask.TaskType.OPERATE_CASHIER):
			var pos = reg.global_position + Vector3(0.0, 0.0, -0.6) # Atrás do balcão
			_add_task(EmployeeTask.TaskType.OPERATE_CASHIER, reg, pos, 6)

func _has_active_task_for_target(target: Node3D, type: EmployeeTask.TaskType) -> bool:
	for t in active_tasks:
		if t.target_node == target and t.task_type == type and not t.is_completed:
			return true
	return false

func _add_task(type: EmployeeTask.TaskType, target: Node3D, pos: Vector3, priority: int) -> void:
	var task = EmployeeTask.new(type, target, pos, priority)
	task.task_id = next_task_id
	next_task_id += 1
	active_tasks.append(task)
	task_created.emit(task)

func _is_player_busy_with_target(target: Node3D) -> bool:
	if not target or not is_instance_valid(target):
		return false
	var tree = get_tree()
	if not tree:
		return false
	var player = tree.root.find_child("Player", true, false)
	if player and is_instance_valid(player):
		var dist = player.global_position.distance_to(target.global_position)
		if dist <= 1.2:
			return true
	return false
