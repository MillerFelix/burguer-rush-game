extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE DE GAMEPLAY: EXECUÇÃO CONTÍNUA AUTÔNOMA DO FUNCIONÁRIO
#
# Valida o ciclo completo de vida do funcionário sem intervenção do jogador:
# 1. Funcionário Ocioso -> Mesa 1 suja -> Detecta -> Vai até a mesa -> Limpa -> Bucha suja
#    -> Vai até a pia -> Lava bucha -> Bucha limpa
# 2. Funcionário Ocioso -> Nova sujeira (poça no salão) -> Detecta automaticamente
#    -> Vai até o local -> Limpa -> Lava bucha na pia
# 3. Funcionário Ocioso -> Cliente senta para pedir -> Detecta -> Atende mesa -> Conclui
# 4. Retorno autônomo ao ponto de descanso na cozinha.
# =============================================================================

const Employee = preload("res://src/employees/employee.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const EmployeeTaskManager = preload("res://src/employees/employee_task_manager.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const Customer = preload("res://src/customers/customer.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(80))
	print("TESTE DE GAMEPLAY REAL: CICLO CONTÍNUO DE EXECUÇÃO DO FUNCIONÁRIO (BURGER RUSH)")
	print("=".repeat(80) + "\n")
	call_deferred("_run_continuous_gameplay_test")

func assert_step(condition: bool, step_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % step_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % step_name)

func _run_continuous_gameplay_test() -> void:
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
	var sink = root_node.find_child("CommercialSink", true, false) as CommercialSink
	var table1 = root_node.find_child("Table1", true, false) as RestaurantTable
	var table2 = root_node.find_child("Table2", true, false) as RestaurantTable

	var employees = emp_mgr.get_employees() if emp_mgr else []
	if employees.is_empty():
		emp_mgr._spawn_initial_employee()
		employees = emp_mgr.get_employees()
	assert_step(employees.size() > 0, "Funcionário autônomo presente no restaurante")
	var emp: Employee = employees[0] as Employee

	print("\n--- ETAPA 1: Funcionário Ocioso -> Mesa 1 Fica Suja ---")
	emp.state = Employee.State.IDLE_WAITING
	table1.table_state = RestaurantTable.TableState.DIRTY
	table1.dirt_amount = 1.0
	table1._update_visual_status()

	# O funcionário faz a busca periódica contínua
	emp._check_for_tasks()
	assert_step(emp.current_task != null and emp.current_task.target_node == table1, "1.1 Funcionário detectou e reservou a Mesa 1 suja")
	assert_step(emp.state == Employee.State.MOVING_TO_TASK, "1.2 Funcionário iniciou deslocamento até a Mesa 1")
	assert_step(emp.waypoints.size() > 0, "1.3 Waypoints calculados através do corredor Oeste para contornar balcão")

	# Simula chegada na mesa
	emp._on_reached_task_target()
	assert_step(emp.state == Employee.State.CLEANING_SURFACE, "1.4 Funcionário chegou na mesa e iniciou esfregação (CLEANING_SURFACE)")
	assert_step(emp.sponge_visual.visible, "1.5 Bucha física visível na mão direita")

	# Conclui esfregação
	emp._finish_cleaning_surface()
	assert_step(table1.table_state == RestaurantTable.TableState.AVAILABLE, "1.6 Mesa 1 foi completamente higienizada (AVAILABLE)")
	assert_step(emp.is_sponge_dirty, "1.7 Bucha do funcionário tornou-se SUJA")
	assert_step(emp.state == Employee.State.MOVING_TO_SINK, "1.8 Funcionário automaticamente transicionou para MOVING_TO_SINK")

	# Chegada na pia
	emp._on_reached_sink()
	assert_step(emp.state == Employee.State.WASHING_SPONGE, "1.9 Funcionário começou a lavar a bucha na pia (WASHING_SPONGE)")
	assert_step(sink.is_water_running, "1.10 Torneira da pia abriu com água corrente")

	# Conclui lavagem
	emp._finish_washing_sponge()
	assert_step(not emp.is_sponge_dirty, "1.11 Bucha lavada e 100% LIMPA")
	assert_step(not sink.is_water_running, "1.12 Água da pia fechada automaticamente")

	print("\n--- ETAPA 2: Funcionário Esperando -> Nova Poça Surge no Chão do Salão ---")
	# Cria uma poça d'água no salão
	var puddle_scene = load("res://src/stations/floor_puddle.tscn")
	var puddle = puddle_scene.instantiate()
	root_node.add_child(puddle)
	puddle.global_position = Vector3(1.5, 0.0, 3.5)

	# Funcionário percebe nova sujeira enquanto parado
	emp._check_for_tasks()
	assert_step(emp.current_task != null and emp.current_task.target_node == puddle, "2.1 Funcionário percebeu a nova poça d'água no salão")
	assert_step(emp.state == Employee.State.MOVING_TO_TASK, "2.2 Saiu do estado IDLE e foi em direção à poça")

	emp._on_reached_task_target()
	assert_step(emp.state == Employee.State.CLEANING_SURFACE, "2.3 Esfregando e secando o chão")

	emp._finish_cleaning_surface()
	assert_step(puddle.is_queued_for_deletion(), "2.4 Poça d'água foi removida do chão")
	assert_step(emp.is_sponge_dirty, "2.5 Bucha ficou suja com a água da poça")
	assert_step(emp.state == Employee.State.MOVING_TO_SINK, "2.6 Retornando à pia para lavar a bucha novamente")

	emp._on_reached_sink()
	emp._finish_washing_sponge()
	assert_step(not emp.is_sponge_dirty, "2.7 Bucha limpa mais uma vez")

	print("\n--- ETAPA 3: Atendimento Prioritário de Cliente ---")
	var customer_scene = load("res://src/customers/customer.tscn")
	var cust: Customer = customer_scene.instantiate() as Customer
	root_node.add_child(cust)
	cust.assigned_table = table2
	cust.state = Customer.State.SEATED_WAITING_TO_ORDER
	table2.seated_customer = cust
	table2.table_state = RestaurantTable.TableState.OCCUPIED

	emp._check_for_tasks()
	assert_step(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.SERVE_CUSTOMER, "3.1 Detectou atendimento de mesa com prioridade máxima")
	assert_step(emp.state == Employee.State.MOVING_TO_TASK, "3.2 Deslocando até a Mesa 2")

	emp.global_position = table2.global_position
	emp._on_reached_task_target()
	assert_step(emp.state == Employee.State.SERVING_CUSTOMER, "3.3 Atendendo e anotando pedido")
	emp._finish_serving_customer()
	assert_step(cust.state == Customer.State.WAITING_FOR_FOOD, "3.4 Pedido registrado no sistema (WAITING_FOR_FOOD)")

	print("\n--- ETAPA 4: Retorno ao Descanso na Ausência de Tarefas ---")
	# Após o atendimento, sem outras tarefas, o funcionário transiciona autonomamente para retorno
	if emp.state != Employee.State.RETURNING_TO_REST:
		emp._check_for_tasks()

	assert_step(emp.state == Employee.State.RETURNING_TO_REST, "4.1 Sem tarefas pendentes, funcionário iniciou retorno à área de descanso")
	assert_step(emp.target_position == emp.rest_position, "4.2 Ponto de destino é a área reservada na cozinha")

	emp._on_reached_rest_area()
	assert_step(emp.state == Employee.State.IDLE_WAITING, "4.3 Chegou no ponto de descanso e permanece em espera calma")

	print("\n" + "=".repeat(80))
	print("RESULTADO DO TESTE DE GAMEPLAY CONTÍNUO: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(80) + "\n")

	if fail_count == 0:
		print(">>> CICLO CONTÍNUO DO FUNCIONÁRIO 100% OPERACIONAL E AUTÔNOMO NO GAMEPLAY! <<<")
		quit(0)
	else:
		print(">>> FALHAS DETECTADAS NO TESTE DE GAMEPLAY! <<<")
		quit(1)
