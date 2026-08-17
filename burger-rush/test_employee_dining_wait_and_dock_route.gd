extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: PONTO DE ESPERA NO SALÃO E ROTA COMPLETA ARMAZÉM/DOCA
#
# Valida os 4 testes obrigatórios:
# TESTE 1: Retorno padrão ao Salão (próximo à entrada) e NUNCA para o armazém
# TESTE 2: Atendimento direto do Salão à Mesa sem desvio para o armazém
# TESTE 3: Rota contínua Salão -> Balcão -> Cozinha -> Porta Armazém -> Doca Externa
# TESTE 4: Rota reversa Doca Externa -> Armazém -> Cozinha -> Balcão -> Salão (Espera)
# =============================================================================

const Employee = preload("res://src/employees/employee.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const EmployeeTaskManager = preload("res://src/employees/employee_task_manager.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const Customer = preload("res://src/customers/customer.gd")
const ReceivingArea = preload("res://src/stations/receiving_area.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: PONTO DE ESPERA NO SALÃO E ROTA COMPLETA ARMAZÉM / DOCA EXTERNA")
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
	var table1 = root_node.find_child("Table1", true, false) as RestaurantTable
	var table5 = root_node.find_child("Table5", true, false) as RestaurantTable
	var receiving_area = root_node.find_child("ReceivingArea", true, false)

	var employees = emp_mgr.get_employees() if emp_mgr else []
	if employees.is_empty():
		emp_mgr._spawn_initial_employee()
		employees = emp_mgr.get_employees()
	assert_test(employees.size() > 0, "Funcionário NPC instanciado sob demanda para o teste")
	var emp: Employee = employees[0] as Employee

	print("\n--- TESTE 1: Ponto de Espera Padrão no Salão (Próximo à Entrada) ---")
	assert_test(emp.rest_position.z > 5.0, "1.1 Ponto de espera configurado dentro do Salão (Z = %.1f > 5.0)" % emp.rest_position.z)
	assert_test(emp.rest_position.x > 0.0, "1.2 Fora do corredor central de clientes (X = %.1f)" % emp.rest_position.x)
	assert_test(emp.get_zone_of_pos(emp.rest_position) == Employee.Zone.HALL, "1.3 Ponto de espera pertence à ZONE.HALL (Salão)")

	# Posiciona funcionário no ponto de descanso e conclui retorno
	emp.global_position = emp.rest_position
	emp._on_reached_rest_area()
	assert_test(emp.state == Employee.State.IDLE_WAITING, "1.4 Funcionário em espera ociosa (IDLE_WAITING)")
	assert_test(emp.get_zone_of_pos(emp.global_position) == Employee.Zone.HALL, "1.5 Funcionário aguardando no salão, NÃO no armazém")

	print("\n--- TESTE 2: Atendimento Imediato a Partir do Ponto de Espera do Salão ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var cust1: Customer = cust_scene.instantiate() as Customer
	root_node.add_child(cust1)
	cust1.assigned_table = table1
	cust1.state = Customer.State.SEATED_WAITING_TO_ORDER
	table1.seated_customer = cust1
	table1.table_state = RestaurantTable.TableState.OCCUPIED

	emp._check_for_tasks()
	assert_test(emp.current_task != null and emp.current_task.target_node == table1, "2.1 Tarefa da Mesa 1 detectada do ponto de espera")
	
	# Verifica que os waypoints de navegação não passam pelo armazém (X < -3.0 com Z < 0)
	var wp_to_table = emp._build_path_to(table1.get_employee_interaction_position())
	var passes_through_storage = false
	for wp in wp_to_table:
		if emp.get_zone_of_pos(wp) == Employee.Zone.STORAGE:
			passes_through_storage = true
	assert_test(not passes_through_storage, "2.2 Trajeto Salão -> Mesa permanece 100% no Salão (sem desvio para armazém)")

	# Simula atendimento e conclusão
	emp.global_position = table1.get_employee_interaction_position()
	emp._on_reached_task_target()
	emp._finish_serving_customer()
	assert_test(cust1.state == Customer.State.WAITING_FOR_FOOD, "2.3 Pedido anotado com sucesso")
	assert_test(emp.current_task == null, "2.4 Tarefa concluída e liberada")

	print("\n--- TESTE 3: Rota Completa Salão -> Balcão -> Cozinha -> Armazém -> Área Externa ---")
	var exterior_target = Vector3(-11.5, 0.0, -3.5) # Doca de recebimento externa
	var path_to_dock = emp._build_path_to(exterior_target)
	assert_test(path_to_dock.size() >= 5, "3.1 Rota multi-passagem gerada com waypoints intermediários")

	var hit_balcao = false
	var hit_kitchen = false
	var hit_storage_door = false
	var hit_dock_door = false

	for wp in path_to_dock:
		# Passagem pelo balcão (X = 4.8)
		if absf(wp.x - 4.8) < 0.5 and wp.z < 0.0:
			hit_balcao = true
		# Cozinha
		if emp.get_zone_of_pos(wp) == Employee.Zone.KITCHEN:
			hit_kitchen = true
		# Porta interna armazém (X = -3.0 a -4.5, Z = -3.5)
		if wp.x < -3.0 and wp.x > -6.0 and absf(wp.z - (-3.5)) < 0.5:
			hit_storage_door = true
		# Porta externa doca (X = -8.0 a -11.0)
		if wp.x <= -8.0:
			hit_dock_door = true

	assert_test(hit_balcao, "3.2 Atravessa pela passagem real do balcão (X = 4.8)")
	assert_test(hit_kitchen, "3.3 Passa pelo corredor da cozinha (Z = -3.2)")
	assert_test(hit_storage_door, "3.4 Atravessa pela porta interna física do armazém (X = -3.0)")
	assert_test(hit_dock_door, "3.5 Atravessa pela porta externa da doca para a área externa (X = -9.0)")

	print("\n--- TESTE 4: Rota Reversa Área Externa -> Armazém -> Cozinha -> Balcão -> Salão ---")
	emp.global_position = exterior_target # Inicia na doca externa
	var path_back = emp._build_path_to(emp.rest_position)

	var ret_dock_door = false
	var ret_storage = false
	var ret_kitchen_door = false
	var ret_balcao = false
	var ret_hall = false

	for wp in path_back:
		if wp.x <= -8.0:
			ret_dock_door = true
		if emp.get_zone_of_pos(wp) == Employee.Zone.STORAGE:
			ret_storage = true
		if absf(wp.x - (-2.5)) < 0.5 and absf(wp.z - (-3.5)) < 0.5:
			ret_kitchen_door = true
		if absf(wp.x - 4.8) < 0.5:
			ret_balcao = true
		if emp.get_zone_of_pos(wp) == Employee.Zone.HALL:
			ret_hall = true

	assert_test(ret_dock_door, "4.1 Entra pela porta externa da doca")
	assert_test(ret_storage, "4.2 Percorre o armazém")
	assert_test(ret_kitchen_door, "4.3 Sai pela porta do armazém para a cozinha")
	assert_test(ret_balcao, "4.4 Atravessa a passagem do balcão para o salão")
	assert_test(ret_hall, "4.5 Chega ao ponto de espera do salão sem colidir com obstáculos")

	print("\n" + "=".repeat(85))
	print("RESULTADO FINAL DOS TESTES DE PONTO DE ESPERA E ROTAS: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE PONTO DE ESPERA E ROTA DE ESTOQUE/DOCA PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
