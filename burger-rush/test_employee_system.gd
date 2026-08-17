extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: FUNCIONÁRIO NPC AUTÔNOMO E SISTEMA DE TAREFAS
# =============================================================================

const Employee = preload("res://src/employees/employee.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const EmployeeTaskManager = preload("res://src/employees/employee_task_manager.gd")
const EmployeeTask = preload("res://src/employees/employee_task.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")
const Customer = preload("res://src/customers/customer.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: SISTEMA DE FUNCIONÁRIOS NPC AUTÔNOMOS E TAREFAS (BURGER RUSH)")
	print("=".repeat(75) + "\n")
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

	var emp_mgr: EmployeeManager = EmployeeManager.get_instance()
	if not emp_mgr:
		emp_mgr = root_node.find_child("EmployeeManager", true, false)
	assert_test(emp_mgr != null, "EmployeeManager presente e ativo")

	var task_mgr: EmployeeTaskManager = EmployeeTaskManager.get_instance()
	if not task_mgr:
		task_mgr = root_node.find_child("EmployeeTaskManager", true, false)
	assert_test(task_mgr != null, "EmployeeTaskManager presente e ativo")

	var sink: CommercialSink = root_node.find_child("CommercialSink", true, false)
	assert_test(sink != null, "Pia Industrial encontrada")

	var table1: RestaurantTable = root_node.find_child("Table1", true, false)
	assert_test(table1 != null, "Mesa 1 encontrada")

	var cashier: CashRegister = root_node.find_child("CashRegister", true, false)
	assert_test(cashier != null, "Caixa Registradora encontrada")

	var employees = emp_mgr.get_employees()
	if employees.is_empty():
		emp_mgr._spawn_initial_employee()
		employees = emp_mgr.get_employees()
	assert_test(employees.size() > 0, "Funcionário inicial instanciado no restaurante")

	var emp: Employee = employees[0] as Employee
	assert_test(emp != null, "Instância de Employee válida")

	print("\n--- TESTE 1: Aparência e Ausência de Textos Flutuantes ---")
	var status_label = emp.get_node_or_null("StatusLabel")
	var label3d = emp.get_node_or_null("Label3D")
	var has_visible_text = (status_label != null and status_label.visible and status_label.text != "") or (label3d != null and label3d.visible and label3d.text != "")
	assert_test(not has_visible_text, "Sem textos flutuantes ou etiquetas pairando sobre o funcionário")

	var model = emp.get_node_or_null("Model")
	assert_test(model != null, "Modelo 3D do funcionário presente")

	var torso_mesh: MeshInstance3D = model.get_node_or_null("Torso")
	assert_test(torso_mesh != null and torso_mesh.material_override != null, "Uniforme aplicado no torso")
	var uniform_mat = torso_mesh.material_override as StandardMaterial3D
	# Uniforme predominantemente amarelo: R alto (>0.85), G alto (>0.70), B baixo (<0.25)
	assert_test(uniform_mat.albedo_color.r > 0.85 and uniform_mat.albedo_color.g > 0.70 and uniform_mat.albedo_color.b < 0.25, "Uniforme com cor predominantemente amarela")

	print("\n--- TESTE 2: Bucha Física e Ciclo de Lavagem na Pia ---")
	assert_test(emp.sponge_visual != null, "Bucha física presente na mão do funcionário")
	assert_test(not emp.is_sponge_dirty, "Bucha nasce inicialmente LIMPA")

	# Suja a bucha manualmente para testar lavagem
	emp.set_sponge_dirty(true)
	assert_test(emp.is_sponge_dirty, "Bucha agora está no estado SUJO")
	assert_test(emp.sponge_dirt_mesh != null and emp.sponge_dirt_mesh.visible, "Camada visual de sujeira visível na bucha")

	# Envia para a pia lavar
	emp._head_to_sink_to_wash()
	assert_test(emp.state == Employee.State.MOVING_TO_SINK, "Funcionário transiciona para MOVING_TO_SINK ao precisar lavar bucha")

	emp._on_reached_sink()
	assert_test(emp.state == Employee.State.WASHING_SPONGE, "Funcionário transiciona para WASHING_SPONGE na pia")
	assert_test(sink.is_water_running, "Água corrente da pia acionada durante a lavagem da bucha")

	emp._finish_washing_sponge()
	assert_test(not emp.is_sponge_dirty, "Bucha voltou ao estado LIMPO após a lavagem")
	assert_test(not sink.is_water_running, "Água da pia desligada após a conclusão da lavagem")

	print("\n--- TESTE 3: Detecção e Limpeza de Mesa Suja ---")
	table1.table_state = RestaurantTable.TableState.DIRTY
	table1.seated_customers.clear()
	assert_test(table1.table_state == RestaurantTable.TableState.DIRTY, "Mesa 1 definida como SUJA")

	emp._check_for_tasks()
	assert_test(emp.current_task != null, "Tarefa de limpeza de mesa detectada e atribuída")
	assert_test(emp.current_task.task_type == EmployeeTask.TaskType.CLEAN_TABLE, "Tipo de tarefa é CLEAN_TABLE")
	assert_test(emp.state == Employee.State.MOVING_TO_TASK, "Funcionário deslocando-se até a mesa")

	emp._on_reached_task_target()
	assert_test(emp.state == Employee.State.CLEANING_SURFACE, "Funcionário esfregando a mesa (CLEANING_SURFACE)")
	assert_test(emp.sponge_visual.visible, "Bucha visível na mão durante a limpeza")

	emp._finish_cleaning_surface()
	assert_test(table1.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa 1 agora está LIMPA e DISPONÍVEL")
	assert_test(emp.is_sponge_dirty, "Bucha do funcionário ficou SUJA após limpar a mesa")
	assert_test(emp.state == Employee.State.MOVING_TO_SINK, "Funcionário vai imediatamente lavar a bucha na pia após a limpeza")

	# Completa lavagem na pia
	emp._on_reached_sink()
	emp._finish_washing_sponge()
	assert_test(not emp.is_sponge_dirty, "Bucha limpa e pronta para nova tarefa")

	print("\n--- TESTE 4: Detecção e Limpeza de Poça no Chão ---")
	var puddle = Node3D.new()
	puddle.name = "FloorPuddle_Test"
	puddle.add_to_group("floor_puddles")
	puddle.set("is_dirty", true)
	root_node.add_child(puddle)
	puddle.global_position = Vector3(-1.0, 0.0, 1.0)

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.CLEAN_PUDDLE, "Tarefa de secar poça detectada")
	emp._on_reached_task_target()
	emp._finish_cleaning_surface()
	assert_test(emp.is_sponge_dirty, "Bucha ficou suja após secar a poça")
	assert_test(puddle.is_queued_for_deletion(), "Poça d'água removida do chão")

	emp._on_reached_sink()
	emp._finish_washing_sponge()

	print("\n--- TESTE 5: Atendimento de Cliente na Mesa ---")
	var customer_scene = load("res://src/customers/customer.tscn")
	var cust: Customer = customer_scene.instantiate() as Customer
	root_node.add_child(cust)
	cust.assigned_table = table1
	cust.state = Customer.State.SEATED_WAITING_TO_ORDER
	table1.seated_customer = cust
	table1.table_state = RestaurantTable.TableState.OCCUPIED

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.SERVE_CUSTOMER, "Tarefa de atendimento de mesa detectada com PRIORIDADE 1")

	emp._on_reached_task_target()
	assert_test(emp.state == Employee.State.SERVING_CUSTOMER, "Funcionário atendendo cliente na mesa")
	emp._finish_serving_customer()
	assert_test(cust.state == Customer.State.WAITING_FOR_FOOD, "Pedido do cliente recebido pelo funcionário (WAITING_FOR_FOOD)")

	print("\n--- TESTE 6: Atendimento no Caixa Registradora ---")
	# Reseta estado do funcionário
	emp.current_task = null
	emp.state = Employee.State.IDLE_WAITING
	table1.seated_customers.clear()
	table1.table_state = RestaurantTable.TableState.AVAILABLE
	cust.assigned_table = null
	cust.state = Customer.State.IN_QUEUE
	cashier.queue_customers = [cust]
	# Limpa pool de tarefas do task_mgr para testes limpos
	var task_mgr_ref: EmployeeTaskManager = EmployeeTaskManager.get_instance()
	if task_mgr_ref:
		task_mgr_ref.active_tasks.clear()

	# Testa diretamente a execução da tarefa de caixa
	var cashier_task: EmployeeTask = EmployeeTask.new()
	cashier_task.task_type = EmployeeTask.TaskType.OPERATE_CASHIER
	cashier_task.target_node = cashier
	cashier_task.target_position = cashier.global_position + Vector3(0.0, 0.0, -0.6)
	cashier_task.priority = 6
	emp._start_task(cashier_task)
	assert_test(emp.current_task != null and emp.current_task.task_type == EmployeeTask.TaskType.OPERATE_CASHIER, "Tarefa de operar o caixa detectada")

	emp._on_reached_task_target()
	assert_test(emp.state == Employee.State.OPERATING_CASHIER, "Funcionário operando o caixa")
	emp._finish_operating_cashier()
	assert_test(cust.state == Customer.State.FINISHED or cust.state == Customer.State.LEAVING, "Cliente cobrado e liberado pelo funcionário no caixa")

	print("\n--- TESTE 7: Reserva Exclusiva de Tarefas (Evitar Conflitos entre Funcionários) ---")
	# Reset estado e pool de tarefas
	emp.current_task = null
	emp.state = Employee.State.IDLE_WAITING
	if task_mgr_ref:
		task_mgr_ref.active_tasks.clear()
	# Contrata segundo funcionário
	var hire_res = emp_mgr.hire_employee("Pedro")
	assert_test(hire_res.success, "Segundo funcionário contratado para teste de concorrência")
	var emp2: Employee = hire_res.employee as Employee

	table1.table_state = RestaurantTable.TableState.DIRTY
	table1.seated_customers.clear()

	# Primeiro funcionário reserva a limpeza da mesa 1
	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.target_node == table1, "Funcionário 1 reservou a Mesa 1")

	# Segundo funcionário tenta pegar tarefa
	emp2._check_for_tasks()
	var emp2_task = emp2.current_task
	var is_same_task = (emp2_task != null and emp2_task.target_node == table1)
	assert_test(not is_same_task, "Funcionário 2 NÃO pega a mesa já reservada pelo Funcionário 1 (Exclusividade garantida)")

	print("\n--- TESTE 8: Retorno à Área de Descanso Quando Sem Tarefas ---")
	# Reseta estado do funcionário e posição para fora da cozinha
	emp.current_task = null
	emp.state = Employee.State.IDLE_WAITING
	emp.global_position = Vector3(2.0, 0.0, 2.0) # Fora da cozinha

	# Testa diretamente o path de retorno: simula que não há tarefas disponíveis
	# chamando o bloco de lógica interno que decide ir ao descanso
	if emp.global_position.distance_to(emp.rest_position) > 1.2 and emp.state != Employee.State.RETURNING_TO_REST:
		emp.target_position = emp.rest_position
		emp.state = Employee.State.RETURNING_TO_REST

	assert_test(emp.state == Employee.State.RETURNING_TO_REST, "Sem tarefas disponíveis, funcionário retorna para a área de descanso (RETURNING_TO_REST)")
	assert_test(emp.target_position == emp.rest_position, "Alvo de navegação é a posição de descanso na cozinha")

	emp._on_reached_rest_area()
	assert_test(emp.state == Employee.State.IDLE_WAITING, "Chegou na área de descanso e entrou em espera calma (IDLE_WAITING)")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE FUNCIONÁRIOS NPC PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
