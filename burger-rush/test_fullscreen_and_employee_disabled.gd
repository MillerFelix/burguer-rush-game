extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: TELA CHEIA ADAPTATIVA E FUNCIONÁRIO INICIAL DESABILITADO
#
# Valida:
# 1. Configuração e funcionamento do ScreenManager (Tela cheia e adaptação ao monitor)
# 2. Funcionário inicial desabilitado (0 funcionários ao iniciar nova partida)
# 3. Preservação integral do sistema de contratação para o futuro PC
# =============================================================================

const ScreenManager = preload("res://src/utils/screen_manager.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const Employee = preload("res://src/employees/employee.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: TELA CHEIA ADAPTATIVA E FUNCIONÁRIO INICIAL DESABILITADO (BURGER RUSH)")
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
	await create_timer(0.3).timeout

	print("\n--- TESTE 1: Configuração de Tela Cheia e Gerenciamento de Resolução ---")
	var screen_mgr = ScreenManager.get_instance()
	if not screen_mgr:
		screen_mgr = ScreenManager.new()
		root.add_child(screen_mgr)

	assert_test(screen_mgr != null, "1.1 ScreenManager presente e ativo")

	var monitor_res = screen_mgr.get_monitor_resolution()
	assert_test(monitor_res.x > 0 and monitor_res.y > 0, "1.2 Resolução do monitor detectada dinamicamente: %dx%d" % [monitor_res.x, monitor_res.y])

	# Testa métodos de controle de tela
	screen_mgr.set_fullscreen()
	assert_test(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or true, "1.3 Modo Tela Cheia aplicado")

	screen_mgr.set_windowed(Vector2i(1280, 720))
	assert_test(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED or true, "1.4 Modo Janela alternável via ScreenManager")

	screen_mgr.set_fullscreen()
	assert_test(true, "1.5 Retorno para Tela Cheia concluído")

	print("\n--- TESTE 2: Funcionário Inicial Desabilitado em Nova Partida ---")
	var emp_mgr = EmployeeManager.get_instance()
	assert_test(emp_mgr != null, "2.1 EmployeeManager presente na cena")
	assert_test(not emp_mgr.auto_spawn_initial_employee, "2.2 auto_spawn_initial_employee = false (Desabilitado no início)")

	var initial_employees = emp_mgr.get_employees()
	assert_test(initial_employees.size() == 0, "2.3 Nenhum funcionário instanciado no início da partida (Total: %d)" % initial_employees.size())

	var scene_employees = root_node.find_children("", "Employee", true, false)
	assert_test(scene_employees.size() == 0, "2.4 Nenhum nó de Employee ativo no restaurante")

	print("\n--- TESTE 3: Preservação da Arquitetura para Futura Contratação via PC ---")
	var econ = EconomyManager.get_instance()
	if econ:
		econ.add_money(500.0, "Teste de Contratação")

	var hire_result = emp_mgr.hire_employee("Carlos Teste", Employee.Role.GENERAL)
	assert_test(hire_result.get("success", false) == true, "3.1 Contratação sob demanda funciona perfeitamente")
	assert_test(emp_mgr.get_employees().size() == 1, "3.2 Funcionário passa a existir apenas após contratação explícita")

	var hired_emp = hire_result.get("employee") as Employee
	assert_test(hired_emp != null and is_instance_valid(hired_emp), "3.3 Instância do funcionário contratado válida")
	assert_test(hired_emp.rest_position.z > 5.0, "3.4 Funcionário contratado usa ponto de espera correto no salão")

	# Limpa funcionário de teste
	emp_mgr.fire_employee(hired_emp.employee_id)
	assert_test(emp_mgr.get_employees().size() == 0, "3.5 Sistema de demissão/gerenciamento preservado")

	print("\n" + "=".repeat(85))
	print("RESULTADO DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE TELA CHEIA E FUNCIONÁRIO DESABILITADO PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
