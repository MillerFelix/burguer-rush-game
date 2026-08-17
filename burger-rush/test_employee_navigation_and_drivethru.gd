extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: NAVEGAÇÃO ENTRE SALÃO/COZINHA E ATENDIMENTO DRIVE-THRU
#
# Valida os 4 cenários críticos solicitados:
# TESTE A — MESA: Atendimento com navegação e ponto de interação no corredor
# TESTE B — VÁRIAS MESAS: Atendimento sequencial de mesas em colunas opostas (Oeste, Leste, Centro)
# TESTE C — DRIVE-THRU: Detecção de veículo na janela, deslocamento até o ponto de entrega, tomada de pedido real e liberação da tarefa
# TESTE D — PRIORIDADE MISTA: Cliente na mesa (1) + Drive-thru (2) + Mesa Suja (3)
# =============================================================================

const Employee = preload("res://src/employees/employee.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const EmployeeTaskManager = preload("res://src/employees/employee_task_manager.gd")
const EmployeeTask = preload("res://src/employees/employee_task.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const DeliveryStation = preload("res://src/stations/delivery_station.gd")
const DeliveryQueueManager = preload("res://src/customers/delivery_queue_manager.gd")
const Customer = preload("res://src/customers/customer.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: NAVEGAÇÃO FÍSICA E ATENDIMENTO DE MESAS / DRIVE-THRU (BURGER RUSH)")
	print("=".repeat(85) + "\n")
	call_deferred("_run_tests")

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	var emp_mgr = EmployeeManager.get_instance()
	var task_mgr = EmployeeTaskManager.get_instance()
	var deliv_mgr = DeliveryQueueManager.get_instance()
	var deliv_station = root_node.find_child("DeliveryStation", true, false) as DeliveryStation
	var table1 = root_node.find_child("Table1", true, false) as RestaurantTable
	var table5 = root_node.find_child("Table5", true, false) as RestaurantTable
	var table9 = root_node.find_child("Table9", true, false) as RestaurantTable

	var employees = emp_mgr.get_employees() if emp_mgr else []
	if employees.is_empty():
		emp_mgr._spawn_initial_employee()
		employees = emp_mgr.get_employees()
	assert_test(employees.size() > 0, "Funcionário NPC instanciado sob demanda para o teste")
	var emp: Employee = employees[0] as Employee

	print("\n--- TESTE A: Atendimento de Mesa com Ponto de Interação no Corredor ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var cust1: Customer = cust_scene.instantiate() as Customer
	root_node.add_child(cust1)
	cust1.assigned_table = table1
	cust1.state = Customer.State.SEATED_WAITING_TO_ORDER
	table1.seated_customer = cust1
	table1.table_state = RestaurantTable.TableState.OCCUPIED

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.target_node == table1, "A.1 Tarefa de atendimento da Mesa 1 criada e reservada")
	assert_test(emp.state == Employee.State.MOVING_TO_TASK, "A.2 Funcionário iniciou movimentação para a Mesa 1")

	# Ponto de interação deve estar no corredor (X > -5.0), não em cima da mesa (X = -5.4)
	var interact_pos = table1.get_employee_interaction_position()
	assert_test(interact_pos.x > -4.5, "A.3 Ponto de interação posicionado no corredor livre a leste da mesa")

	# Simula percurso e chegada
	emp.global_position = interact_pos
	emp._on_reached_task_target()
	assert_test(emp.state == Employee.State.SERVING_CUSTOMER, "A.4 Chegou à mesa e iniciou atendimento")

	emp._finish_serving_customer()
	assert_test(cust1.state == Customer.State.WAITING_FOR_FOOD, "A.5 Pedido registrado com sucesso")
	assert_test(emp.current_task == null, "A.6 Tarefa liberada após conclusão")

	print("\n--- TESTE B: Atendimento em Múltiplas Mesas (Coluna Leste e Mesa Central) ---")
	# Mesa 5 (Coluna Leste: X = +5.4)
	var cust5: Customer = cust_scene.instantiate() as Customer
	root_node.add_child(cust5)
	cust5.assigned_table = table5
	cust5.state = Customer.State.SEATED_WAITING_TO_ORDER
	table5.seated_customer = cust5
	table5.table_state = RestaurantTable.TableState.OCCUPIED

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.target_node == table5, "B.1 Detectou atendimento da Mesa 5 (Coluna Leste)")
	var interact_pos5 = table5.get_employee_interaction_position()
	assert_test(interact_pos5.x < 5.0, "B.2 Ponto de interação da Mesa 5 posicionado no corredor oeste livre")

	emp.global_position = interact_pos5
	emp._on_reached_task_target()
	emp._finish_serving_customer()
	assert_test(cust5.state == Customer.State.WAITING_FOR_FOOD, "B.3 Mesa 5 atendida com sucesso")

	# Mesa 9 (Mesa Central: X = 0.0, Z = 5.2)
	var cust9: Customer = cust_scene.instantiate() as Customer
	root_node.add_child(cust9)
	cust9.assigned_table = table9
	cust9.state = Customer.State.SEATED_WAITING_TO_ORDER
	table9.seated_customer = cust9
	table9.table_state = RestaurantTable.TableState.OCCUPIED

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.target_node == table9, "B.4 Detectou atendimento da Mesa 9 Central")
	emp.global_position = table9.get_employee_interaction_position()
	emp._on_reached_task_target()
	emp._finish_serving_customer()
	assert_test(cust9.state == Customer.State.WAITING_FOR_FOOD, "B.5 Mesa 9 Central atendida com sucesso")

	print("\n--- TESTE C: Atendimento Completo no Drive-Thru ---")
	# Spawna um carro e posiciona na janela de atendimento
	var car = deliv_mgr.spawn_car()
	assert_test(car != null, "C.1 Veículo de delivery gerado")
	car.position = DeliveryQueueManager.QUEUE_POSITIONS[0]
	car.set_target_position(DeliveryQueueManager.QUEUE_POSITIONS[0], 0)
	car.current_state = 3 # AT_WINDOW_WAITING_ORDER
	assert_test(deliv_mgr.has_waiting_car_for_order(), "C.2 DeliveryQueueManager reconhece carro aguardando pedido na janela")

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.SERVE_DRIVETHRU, "C.3 Tarefa SERVE_DRIVETHRU detectada e atribuída ao funcionário")
	assert_test(emp.state == Employee.State.MOVING_TO_TASK, "C.4 Funcionário caminhando até a janela de Drive-Thru")

	# Chegada na janela do Drive-Thru
	emp.global_position = deliv_station.global_position + Vector3(0.0, 0.0, 1.1)
	emp._on_reached_task_target()
	assert_test(emp.state == Employee.State.SERVING_DRIVETHRU, "C.5 Funcionário posicionado na janela atendendo veículo (SERVING_DRIVETHRU)")

	emp._finish_serving_drivethru()
	assert_test(car.current_state == 4, "C.6 Pedido do carro registrado (AT_WINDOW_WAITING_FOOD)")
	assert_test(car.current_order != null, "C.7 Ordem de pedido criada fisicamente no OrderManager")
	assert_test(not deliv_mgr.has_waiting_car_for_order(), "C.8 Carro não está mais esperando atendimento")

	print("\n--- TESTE D: Prioridades Mistas (Mesa > Drive-Thru > Mesa Suja) ---")
	# Limpa fila de delivery anterior
	for c in deliv_mgr.car_queue:
		if is_instance_valid(c):
			c.queue_free()
	deliv_mgr.car_queue.clear()

	# 1. Cria mesa suja (Prioridade 3)
	table1.seated_customers.clear()
	table1.table_state = RestaurantTable.TableState.DIRTY

	# 2. Cria carro esperando pedido (Prioridade 2)
	var car2 = deliv_mgr.spawn_car()
	car2.position = DeliveryQueueManager.QUEUE_POSITIONS[0]
	car2.set_target_position(DeliveryQueueManager.QUEUE_POSITIONS[0], 0)
	car2.current_state = 3

	# 3. Cria cliente na mesa esperando pedido (Prioridade 1)
	var cust_p1: Customer = cust_scene.instantiate() as Customer
	root_node.add_child(cust_p1)
	cust_p1.assigned_table = table5
	cust_p1.state = Customer.State.SEATED_WAITING_TO_ORDER
	table5.seated_customer = cust_p1
	table5.table_state = RestaurantTable.TableState.OCCUPIED

	# Escolha 1: Deve escolher Prioridade 1 (Mesa com cliente)
	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.SERVE_CUSTOMER and emp.current_task.target_node == table5, "D.1 Prioridade 1 respeitada: Atendimento de mesa escolhido primeiro")
	emp.global_position = table5.get_employee_interaction_position()
	emp._on_reached_task_target()
	emp._finish_serving_customer()

	# Escolha 2: Deve escolher Prioridade 2 (Drive-Thru)
	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.SERVE_DRIVETHRU, "D.2 Prioridade 2 respeitada: Drive-Thru escolhido antes da limpeza")
	emp.global_position = deliv_station.global_position + Vector3(0.0, 0.0, 1.1)
	emp._on_reached_task_target()
	emp._finish_serving_drivethru()

	# Escolha 3: Deve escolher Prioridade 3 (Limpeza de mesa suja)
	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.CLEAN_TABLE and emp.current_task.target_node == table1, "D.3 Prioridade 3 respeitada: Limpeza da Mesa 1 executada após atendimentos")
	emp.global_position = table1.get_employee_interaction_position()
	emp._on_reached_task_target()
	emp._finish_cleaning_surface()
	assert_test(table1.table_state == RestaurantTable.TableState.AVAILABLE, "D.4 Mesa 1 limpa com sucesso")

	# Lava bucha na pia após limpeza
	emp._on_reached_sink()
	emp._finish_washing_sponge()
	assert_test(not emp.is_sponge_dirty, "D.5 Bucha lavada na pia")

	print("\n" + "=".repeat(85))
	print("RESULTADO FINAL DOS TESTES DE NAVEGAÇÃO E ATENDIMENTO: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE NAVEGAÇÃO, MESAS E DRIVE-THRU PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
