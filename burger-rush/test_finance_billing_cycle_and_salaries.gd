extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DO SISTEMA FINANCEIRO, SALÁRIOS E CICLO DE CONTAS
# ==============================================================================

const SaveManager = preload("res://src/core/save_manager.gd")
const FinanceManager = preload("res://src/economy/finance_manager.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")
const PowerManager = preload("res://src/core/power_manager.gd")
const WaterManager = preload("res://src/core/water_manager.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const Employee = preload("res://src/employees/employee.gd")
const GameClock = preload("res://src/time/game_clock.gd")

var passed: int = 0
var failed: int = 0

func assert_test(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % message)
	else:
		failed += 1
		print("  [FAIL] %s" % message)

func _init() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE DE SALÁRIOS E CICLO DE CONTAS ===========")
	print("=================================================================")

	var test_dir = "user://saves_test_finances_cycle"
	_cleanup_test_dir(test_dir)

	var sm = SaveManager.get_instance()
	if not sm:
		sm = SaveManager.new()
		sm.name = "SaveManager"
		root.add_child(sm)
	sm.set_custom_save_dir(test_dir)

	var clock = GameClock.get_instance()
	if not clock:
		clock = GameClock.new()
		clock.name = "GameClock"
		root.add_child(clock)

	var econ = EconomyManager.get_instance()
	if not econ:
		econ = EconomyManager.new()
		econ.name = "EconomyManager"
		root.add_child(econ)
	econ.current_money = 1000.0

	var pm = PowerManager.get_instance()
	if not pm:
		pm = PowerManager.new()
		pm.name = "PowerManager"
		root.add_child(pm)

	var wm = WaterManager.get_instance()
	if not wm:
		wm = WaterManager.new()
		wm.name = "WaterManager"
		root.add_child(wm)

	var em = EmployeeManager.get_instance()
	if not em:
		em = EmployeeManager.new()
		em.name = "EmployeeManager"
		root.add_child(em)

	var fin = FinanceManager.get_instance()
	if not fin:
		fin = FinanceManager.new()
		fin.name = "FinanceManager"
		root.add_child(fin)

	# --- TESTE 1: SALÁRIO DOS FUNCIONÁRIOS (R$ 150/DIA SEM TAXA DE MANUTENÇÃO) ---
	print("\n--- TESTE 1: Salários dos Funcionários ---")
	em.employees.clear()
	assert_test(fin.daily_salary_per_employee == 150.0, "Salário diário configurado para R$ 150.00")
	assert_test(fin.calculate_daily_salaries_cost() == 0.0, "Sem funcionários contratados: Salário = R$ 0.00")
	assert_test(not "base_staff_room_maintenance" in fin or fin.get("base_staff_room_maintenance") == null or fin.get("base_staff_room_maintenance") == 0.0, "Nenhuma cobrança de manutenção aplicada ao salário")

	# Simula 1 funcionário contratado
	var dummy_emp1 = Employee.new()
	dummy_emp1.employee_id = 1
	dummy_emp1.daily_salary = 150.0
	em.employees.append(dummy_emp1)

	assert_test(fin.get_active_employees_count() == 1, "1 funcionário ativo detectado")
	assert_test(fin.calculate_daily_salaries_cost() == 150.0, "1 funcionário ativo: Salário = R$ 150.00")

	# Simula 2 funcionários contratados
	var dummy_emp2 = Employee.new()
	dummy_emp2.employee_id = 2
	dummy_emp2.daily_salary = 150.0
	em.employees.append(dummy_emp2)

	assert_test(fin.get_active_employees_count() == 2, "2 funcionários ativos detectados")
	assert_test(fin.calculate_daily_salaries_cost() == 300.0, "2 funcionários ativos: Salário = R$ 300.00")

	# Reseta para 0 funcionários para testar o Dia 1
	em.employees.clear()

	# --- TESTE 2: DIA 1 — SEM CONTAS ANTECIPADAS E CONSUMO REAL ---
	print("\n--- TESTE 2: Início e Conclusão do Dia 1 ---")
	clock.day_number = 1
	fin.pending_bills.clear()
	fin.start_new_day()

	assert_test(fin.get_total_pending_debt() == 0.0, "Início do Dia 1: Dívida pendente = R$ 0.00 (sem cobrança antecipada)")
	assert_test(fin.get_active_bills()["electricity"]["amount"] == 0.0, "Início do Dia 1: Conta de Energia = R$ 0.00")
	assert_test(fin.get_active_bills()["water"]["amount"] == 0.0, "Início do Dia 1: Conta de Água = R$ 0.00")

	# Simula consumo real de equipamentos durante o Dia 1: 20 kWh e 150 Litros
	pm.total_energy_kwh = 20.0
	wm.daily_water_liters = 150.0
	fin.record_sale(500.0, "dine_in", "Vendas do Dia 1")

	var expected_elec_d1 = 20.0 * 0.85 # R$ 17.00
	var expected_water_d1 = 150.0 * 0.02 # R$ 3.00

	# Encerra o Dia 1
	var rep_d1 = fin.close_current_day()
	assert_test(rep_d1.get("day_number") == 1, "Relatório do Dia 1 fechado com sucesso")
	assert_test(is_equal_approx(rep_d1.get("electricity_cost"), expected_elec_d1), "Energia do Dia 1 calculada com precisão: R$ 17.00")
	assert_test(is_equal_approx(rep_d1.get("water_cost"), expected_water_d1), "Água do Dia 1 calculada com precisão: R$ 3.00")
	assert_test(fin.pending_bills.size() == 2, "2 contas geradas no fechamento do Dia 1 (Energia e Água)")

	# --- TESTE 3: DIA 2 — CONTAS DO DIA 1 DISPONÍVEIS PARA PAGAMENTO ---
	print("\n--- TESTE 3: Disponibilidade e Pagamento de Contas no Dia 2 ---")
	clock.day_number = 2
	pm.total_energy_kwh = 0.0
	wm.daily_water_liters = 0.0
	fin.start_new_day()

	assert_test(is_equal_approx(fin.get_total_pending_debt(), expected_elec_d1 + expected_water_d1), "Início do Dia 2: Contas do Dia 1 disponíveis (Total: R$ 20.00)")
	assert_test(is_equal_approx(fin.get_category_pending_amount("electricity"), expected_elec_d1), "Início do Dia 2: Conta de Energia do Dia 1 pendente no valor de R$ 17.00")
	assert_test(is_equal_approx(fin.get_category_pending_amount("water"), expected_water_d1), "Início do Dia 2: Conta de Água do Dia 1 pendente no valor de R$ 3.00")

	# Jogador paga a conta de energia do Dia 1
	var money_before_pay = econ.get_money()
	var pay_elec_res = fin.pay_bill("electricity")
	assert_test(pay_elec_res.get("success") == true, "Pagamento individual da conta de Energia realizado com sucesso")
	assert_test(is_equal_approx(econ.get_money(), money_before_pay - expected_elec_d1), "Saldo deduzido exatamente em R$ 17.00")
	assert_test(fin.get_category_pending_amount("electricity") == 0.0, "Conta de Energia marcada como quitada")
	assert_test(is_equal_approx(fin.get_total_pending_debt(), expected_water_d1), "Restante pendente: R$ 3.00 (Água)")

	# Jogador quita a conta de água restante via pay_all_bills
	var pay_all_res = fin.pay_all_bills()
	assert_test(pay_all_res.get("success") == true, "Quitação total de contas restantes realizada com sucesso")
	assert_test(fin.get_total_pending_debt() == 0.0, "Todas as contas do Dia 1 100% quitadas (Dívida pendente = R$ 0.00)")

	# --- TESTE 4: DIA 2 → DIA 3: NOVO CONSUMO E DEDUÇÃO DE SALÁRIO ---
	print("\n--- TESTE 4: Ciclo do Dia 2 e Salário do Funcionário ---")
	# Contrata 1 funcionário para trabalhar durante o Dia 2
	em.employees.append(dummy_emp1)

	# Consumo no Dia 2: 40 kWh (R$ 34.00) e 250 Litros (R$ 5.00)
	pm.total_energy_kwh = 40.0
	wm.daily_water_liters = 250.0
	var expected_elec_d2 = 40.0 * 0.85 # R$ 34.00
	var expected_water_d2 = 250.0 * 0.02 # R$ 5.00

	var money_before_day2_close = econ.get_money()
	var rep_d2 = fin.close_current_day()

	assert_test(rep_d2.get("salaries_cost") == 150.0, "Salário de R$ 150.00 registrado no relatório do Dia 2")
	assert_test(is_equal_approx(econ.get_money(), money_before_day2_close - 150.0), "Salário de R$ 150.00 deduzido no fechamento do Dia 2")
	assert_test(is_equal_approx(rep_d2.get("electricity_cost"), expected_elec_d2), "Energia do Dia 2: R$ 34.00")
	assert_test(is_equal_approx(rep_d2.get("water_cost"), expected_water_d2), "Água do Dia 2: R$ 5.00")

	# Início do Dia 3
	clock.day_number = 3
	pm.total_energy_kwh = 0.0
	wm.daily_water_liters = 0.0
	fin.start_new_day()

	assert_test(is_equal_approx(fin.get_total_pending_debt(), expected_elec_d2 + expected_water_d2), "Início do Dia 3: Contas do Dia 2 disponíveis para pagamento (Total: R$ 39.00)")
	assert_test(is_equal_approx(fin.get_category_pending_amount("electricity"), expected_elec_d2), "Conta de Energia do Dia 2: R$ 34.00")
	assert_test(is_equal_approx(fin.get_category_pending_amount("water"), expected_water_d2), "Conta de Água do Dia 2: R$ 5.00")

	# --- TESTE 5: PERSISTÊNCIA NO SAVE SYSTEM ---
	print("\n--- TESTE 5: Persistência no Save System ---")
	sm.has_active_game = true
	sm.active_slot = 1
	sm.pending_save_data["current_day"] = 3
	sm.save_game(1)

	# Modifica o FinanceManager para testar o load
	fin.pending_bills.clear()
	assert_test(fin.pending_bills.size() == 0, "pending_bills limpo em memória")

	sm.load_game(1)
	assert_test(fin.pending_bills.size() == 2, "pending_bills restaurado com sucesso do save")
	assert_test(is_equal_approx(fin.get_total_pending_debt(), 39.0), "Dívida de R$ 39.00 restaurada com precisão")

	# Cleanup
	_cleanup_test_dir(test_dir)
	sm.set_custom_save_dir("")
	dummy_emp1.free()
	dummy_emp2.free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 SISTEMA FINANCEIRO, SALÁRIOS E CICLO DE CONTAS 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)

func _cleanup_test_dir(dir_path: String) -> void:
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var fn = dir.get_next()
			while fn != "":
				if not dir.current_is_dir():
					DirAccess.remove_absolute("%s/%s" % [dir_path, fn])
				fn = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(dir_path)
