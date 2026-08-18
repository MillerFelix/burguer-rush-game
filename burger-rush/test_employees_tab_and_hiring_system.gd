extends SceneTree

# ===========================================================================
# TESTE COMPLETO: ABA FUNCIONÁRIO NO PC, CONTRATAÇÃO ÚNICA, STATUS REAL E SALÁRIOS
# ===========================================================================

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: ABA FUNCIONÁRIO DO PC, CONTRATAÇÃO, STATUS REAL E SALÁRIOS")
	print("=".repeat(75) + "\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# SETUP INICIAL DE SINGLETONS E GERENCIADORES
	# -----------------------------------------------------------------------
	var root_node = root

	var clock = GameClock.new()
	clock.name = "GameClock"
	root_node.add_child(clock)

	var econ = EconomyManager.new()
	econ.name = "EconomyManager"
	root_node.add_child(econ)
	econ.current_money = 500.0

	var emp_mgr = EmployeeManager.new()
	emp_mgr.name = "EmployeeManager"
	emp_mgr.auto_spawn_initial_employee = false
	emp_mgr.hiring_cost = 150.0
	emp_mgr.daily_salary = 50.0
	root_node.add_child(emp_mgr)

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	fin.daily_salary_per_employee = 50.0
	root_node.add_child(fin)

	var comp_ui_scene = load("res://src/ui/computer_ui.tscn")
	var comp_ui = comp_ui_scene.instantiate() as ComputerUI
	root_node.add_child(comp_ui)

	# -----------------------------------------------------------------------
	# TESTE 1: ESTADO INICIAL (NENHUM FUNCIONÁRIO CONTRATADO)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Estado Inicial sem Funcionário e Apresentação do Candidato ---")

	total_tests += 1
	if not emp_mgr.has_hired_employee() and emp_mgr.get_employees().is_empty():
		print("  [PASS] 1.1 Nenhum funcionário contratado inicialmente")
		passed_tests += 1
	else:
		print("  [FAIL] 1.1 Funcionário encontrado indevidamente no início")

	total_tests += 1
	comp_ui.open()
	comp_ui._switch_tab(ComputerUI.TabID.EMPLOYEES, "Funcionário")
	if comp_ui.employees_tab and comp_ui.employees_tab.visible:
		print("  [PASS] 1.2 Aba de Funcionário acessada com sucesso no PC")
		passed_tests += 1
	else:
		print("  [FAIL] 1.2 Aba de Funcionário não visível")

	total_tests += 1
	if comp_ui.employees_content_vbox and comp_ui.employees_content_vbox.get_child_count() > 0:
		print("  [PASS] 1.3 Card de apresentação do candidato e termos renderizados")
		passed_tests += 1
	else:
		print("  [FAIL] 1.3 Card de apresentação não foi renderizado")

	# -----------------------------------------------------------------------
	# TESTE 2: CONTRATAÇÃO DO FUNCIONÁRIO E DESCONTO FINANCEIRO
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Fluxo de Contratação e Desconto Financeiro ---")

	var initial_balance = econ.get_money() # 500.0

	total_tests += 1
	var hire_result = emp_mgr.hire_employee("Carlos", Employee.Role.GENERAL)
	if hire_result.get("success", false) and emp_mgr.has_hired_employee():
		print("  [PASS] 2.1 Funcionário 'Carlos' contratado com sucesso!")
		passed_tests += 1
	else:
		print("  [FAIL] 2.1 Falha ao contratar funcionário")

	total_tests += 1
	var balance_after_hire = econ.get_money()
	if is_equal_approx(balance_after_hire, initial_balance - 150.0):
		print("  [PASS] 2.2 Taxa de contratação (R$ 150.00) descontada perfeitamente: R$ %.2f -> R$ %.2f" % [initial_balance, balance_after_hire])
		passed_tests += 1
	else:
		print("  [FAIL] 2.2 Saldo incorreto após contratação: R$ %.2f" % balance_after_hire)

	total_tests += 1
	var hired_emp = emp_mgr.get_hired_employee()
	if hired_emp != null and is_instance_valid(hired_emp) and hired_emp.get_parent() != null:
		print("  [PASS] 2.3 NPC do funcionário instanciado no mundo (Chegando pelo acesso externo)")
		passed_tests += 1
	else:
		print("  [FAIL] 2.3 NPC do funcionário inválido ou fora da árvore")

	# -----------------------------------------------------------------------
	# TESTE 3: REGRA DE FUNCIONÁRIO ÚNICO (MAX 1)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Regra Estrita de 1 Único Funcionário no Restaurante ---")

	total_tests += 1
	var second_hire = emp_mgr.hire_employee("João", Employee.Role.GENERAL)
	if not second_hire.get("success", false) and emp_mgr.get_employees().size() == 1:
		print("  [PASS] 3.1 Segunda contratação bloqueada com sucesso! Mensagem: '%s'" % second_hire.get("message"))
		passed_tests += 1
	else:
		print("  [FAIL] 3.1 Segunda contratação permitida indevidamente!")

	total_tests += 1
	if econ.get_money() == balance_after_hire:
		print("  [PASS] 3.2 Saldo preservado sem cobrança indevida por tentativa duplicada")
		passed_tests += 1
	else:
		print("  [FAIL] 3.2 Saldo alterado em tentativa bloqueada")

	# -----------------------------------------------------------------------
	# TESTE 4: DASHBOARD DO FUNCIONÁRIO, STATUS REAL E TAREFA ATUAL
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Dashboard do Funcionário, Status Real e Tarefa Atual ---")

	comp_ui._refresh_employees_tab()

	total_tests += 1
	if hired_emp.get_current_status_text() == "Aguardando tarefa":
		print("  [PASS] 4.1 Status real inicial mapeado: '%s'" % hired_emp.get_current_status_text())
		passed_tests += 1
	else:
		print("  [FAIL] 4.1 Status inicial incorreto: %s" % hired_emp.get_current_status_text())

	total_tests += 1
	# Simula tarefa de atendimento no Drive-Thru
	hired_emp.state = Employee.State.SERVING_DRIVETHRU
	var status_dt = hired_emp.get_current_status_text()
	var task_dt = hired_emp.get_current_task_text()
	var work_dt = hired_emp.get_work_state_text()
	if status_dt == "Atendendo drive-thru" and work_dt == "Trabalhando":
		print("  [PASS] 4.2 Status real de Drive-Thru mapeado: '%s' | Tarefa: '%s' | Estado: '%s'" % [status_dt, task_dt, work_dt])
		passed_tests += 1
	else:
		print("  [FAIL] 4.2 Status de Drive-Thru incorreto: %s | %s" % [status_dt, work_dt])

	total_tests += 1
	# Simula lavagem de bucha na pia
	hired_emp.state = Employee.State.WASHING_SPONGE
	var status_sink = hired_emp.get_current_status_text()
	var task_sink = hired_emp.get_current_task_text()
	if status_sink == "Lavando a bucha" and task_sink.contains("pia"):
		print("  [PASS] 4.3 Status real de lavagem de bucha mapeado: '%s' | Tarefa: '%s'" % [status_sink, task_sink])
		passed_tests += 1
	else:
		print("  [FAIL] 4.3 Status de lavagem de bucha incorreto: %s" % status_sink)

	total_tests += 1
	# Simula operação no caixa
	hired_emp.state = Employee.State.OPERATING_CASHIER
	var status_cash = hired_emp.get_current_status_text()
	if status_cash == "Trabalhando no caixa":
		print("  [PASS] 4.4 Status real de caixa mapeado: '%s'" % status_cash)
		passed_tests += 1
	else:
		print("  [FAIL] 4.4 Status de caixa incorreto: %s" % status_cash)

	# -----------------------------------------------------------------------
	# TESTE 5: INTEGRAÇÃO DE SALÁRIO E FOLHA COM A ABA FINANÇAS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Folha Salarial Diária e Integração Financeira ---")

	total_tests += 1
	var daily_salary_calc = fin.calculate_daily_salaries_cost()
	if is_equal_approx(daily_salary_calc, 50.0):
		print("  [PASS] 5.1 Custo diário de salários calculado: R$ %.2f (1 funcionário x R$ 50.00)" % daily_salary_calc)
		passed_tests += 1
	else:
		print("  [FAIL] 5.1 Custo diário incorreto: R$ %.2f" % daily_salary_calc)

	# Simula fechamento do dia para gerar a conta de salário
	fin.close_current_day()

	total_tests += 1
	var bills = fin.get_active_bills()
	var salaries_bill = bills.get("salaries", {})
	if not salaries_bill.is_empty() and is_equal_approx(salaries_bill.get("amount", 0.0), 50.0) and not salaries_bill.get("is_paid", false):
		print("  [PASS] 5.2 Conta de Salário gerada como PENDENTE no valor de R$ 50.00")
		passed_tests += 1
	else:
		print("  [FAIL] 5.2 Conta de salário não foi gerada corretamente")

	total_tests += 1
	comp_ui._refresh_employees_tab()
	# Paga o salário pelo PC
	comp_ui._on_pay_bill_clicked("salaries", fin)
	var updated_bills = fin.get_active_bills()
	var updated_salary_bill = updated_bills.get("salaries", {})
	if updated_salary_bill.get("is_paid", false):
		print("  [PASS] 5.3 Salário pago com sucesso pelo PC e marcado como QUITADO")
		passed_tests += 1
	else:
		print("  [FAIL] 5.3 Salário não foi quitado")

	# -----------------------------------------------------------------------
	# TESTE 6: DEMISSÃO E LIBERAÇÃO DE VAGA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 6: Demissão do Funcionário e Liberação da Vaga ---")

	total_tests += 1
	comp_ui._on_fire_employee_clicked(hired_emp.employee_id, emp_mgr)
	if not emp_mgr.has_hired_employee() and emp_mgr.get_employees().is_empty():
		print("  [PASS] 6.1 Funcionário demitido com sucesso e removido do restaurante")
		passed_tests += 1
	else:
		print("  [FAIL] 6.1 Funcionário não foi removido após demissão")

	total_tests += 1
	if comp_ui.employees_summary_label and comp_ui.employees_summary_label.text.contains("Nenhum funcionário contratado"):
		print("  [PASS] 6.2 Interface do PC retornou à tela de contratação de candidato")
		passed_tests += 1
	else:
		print("  [FAIL] 6.2 Interface do PC não retornou à tela de contratação")

	# -----------------------------------------------------------------------
	# RESULTADO FINAL
	# -----------------------------------------------------------------------
	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [passed_tests, total_tests - passed_tests])
	print("=".repeat(75) + "\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DA ABA FUNCIONÁRIO PASSARAM COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
