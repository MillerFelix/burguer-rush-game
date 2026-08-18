extends SceneTree

# =============================================================================
# TESTE COMPLETO: CENTRO FINANCEIRO (ABA FINANÇAS DO PC), ENERGIA, ÁGUA E CONTAS
# =============================================================================

const EconomyManager = preload("res://src/economy/economy_manager.gd")
const PowerManager = preload("res://src/core/power_manager.gd")
const WaterManager = preload("res://src/core/water_manager.gd")
const FinanceManager = preload("res://src/economy/finance_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const ComputerUI = preload("res://src/ui/computer_ui.gd")

var pass_count: int = 0
var fail_count: int = 0

func assert_test(condition: bool, msg: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % msg)
	else:
		fail_count += 1
		printerr("  [FAIL] %s" % msg)

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: ABA FINANÇAS DO PC, ENERGIA REAL, ÁGUA, SALÁRIOS E CONTAS A PAGAR")
	print("===========================================================================\n")

	test_sales_and_revenue_by_channel()
	test_power_and_electricity_costs()
	test_water_consumption_and_sources()
	test_employee_salaries()
	test_bills_generation_and_payment_system()
	test_pc_finances_ui_and_history()

	print("\n===========================================================================")
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("===========================================================================\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! <<<\n")
	else:
		printerr(">>> ALGUNS TESTES FALHARAM! <<<\n")

	quit(0 if fail_count == 0 else 1)

# -----------------------------------------------------------------------------
# 1. TESTE DE VENDAS E ENTRADAS POR CANAL
# -----------------------------------------------------------------------------
func test_sales_and_revenue_by_channel() -> void:
	print("--- TESTE 1: Entradas de Vendas por Canal (Salão, Drive-thru, Delivery) ---")

	var econ = EconomyManager.new()
	econ.name = "EconomyManager"
	econ.starting_money = 200.0
	get_root().add_child(econ)
	econ.current_money = 200.0

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	get_root().add_child(fin)

	# Venda no Salão (Dine-in)
	fin.record_sale(45.0, "dine_in", "Combo Clássico")
	assert_test(fin.get_daily_revenue_by_channel("dine_in") == 45.0, "Venda no salão registrada: R$ 45.00")

	# Venda no Drive-thru
	fin.record_sale(62.50, "drive_thru", "Pedido Drive-thru #001")
	assert_test(fin.get_daily_revenue_by_channel("drive_thru") == 62.50, "Venda no Drive-thru registrada: R$ 62.50")

	# Venda no Delivery
	fin.record_sale(38.00, "delivery", "Pedido App #104")
	assert_test(fin.get_daily_revenue_by_channel("delivery") == 38.00, "Venda no Delivery registrada: R$ 38.00")

	# Total de receita do dia
	var total_rev = fin.get_total_daily_revenue()
	assert_test(is_equal_approx(total_rev, 145.50), "Total de receita consolidado: R$ 145.50 (Salão + Drive + Delivery)")

	# Confirma que o saldo da economia foi incrementado
	assert_test(is_equal_approx(econ.get_money(), 345.50), "Saldo real do restaurante atualizado: R$ 345.50")

	fin.free()
	econ.free()

# -----------------------------------------------------------------------------
# 2. TESTE DE CONSUMO DE ENERGIA E CONDICIONANTES (3x ABERTA, DISJUNTOR, EVENTO)
# -----------------------------------------------------------------------------
func test_power_and_electricity_costs() -> void:
	print("\n--- TESTE 2: Energia Elétrica (kW, Portas Abertas 3x, Desligamento e Evento) ---")

	var pm = PowerManager.new()
	pm.name = "PowerManager"
	get_root().add_child(pm)
	pm.set_main_power(true)

	var dummy_fridge = Node.new()
	pm.register_appliance(dummy_fridge, "fridge_test", "Geladeira Comercial", 1.5, true)

	var dummy_grill = Node.new()
	pm.register_appliance(dummy_grill, "grill_test", "Chapa Dupla", 3.0, true)

	# Consumo normal por 3600 segundos (1 hora)
	# Geladeira (1.5 kW) + Grill (3.0 kW) = 4.5 kW -> 4.5 kWh em 1 hora
	pm._process(3600.0)
	var kwh_normal = pm.get_daily_energy_consumption_kwh()
	assert_test(is_equal_approx(kwh_normal, 4.5), "Consumo de energia normal acumulado: 4.50 kWh em 1 hora")

	# Teste Porta Aberta da Geladeira: Multiplicador 3x
	pm.set_appliance_multiplier(dummy_fridge, 3.0)
	# Próxima 1 hora: Geladeira (1.5 * 3 = 4.5 kW) + Grill (3.0 kW) = 7.5 kW -> +7.5 kWh
	pm._process(3600.0)
	var kwh_open = pm.get_daily_energy_consumption_kwh()
	assert_test(is_equal_approx(kwh_open, 12.0), "Porta de geladeira aberta consome 3x mais (Total: 12.00 kWh)")

	# Teste Disjuntor Geral Desligado: consumo zera e pausa acúmulo
	pm.set_main_power(false)
	pm._process(3600.0)
	assert_test(is_equal_approx(pm.get_daily_energy_consumption_kwh(), 12.0), "Quadro geral desligado não acumula consumo de energia")

	# Teste Evento de Regulagem de Rede (+30% no custo da energia)
	var dem = DailyEventManager.new()
	dem.name = "DailyEventManager"
	get_root().add_child(dem)
	dem.electricity_cost_multiplier = 1.30

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	get_root().add_child(fin)
	fin.electricity_tariff_kwh = 0.85

	# Custo = 12.0 kWh * 0.85 * 1.30 = R$ 13.26
	var cost_with_event = fin.calculate_daily_electricity_cost()
	assert_test(is_equal_approx(cost_with_event, 12.0 * 0.85 * 1.30), "Evento de regulagem tarifária aplica +30%% no custo da energia (R$ 13.26)")

	dummy_fridge.free()
	dummy_grill.free()
	dem.free()
	fin.free()
	pm.free()

# -----------------------------------------------------------------------------
# 3. TESTE DE CONSUMO DE ÁGUA (PIA, MÁQUINA DE REFRI, MÁQUINA DE SUCO, INTERRUPÇÃO)
# -----------------------------------------------------------------------------
func test_water_consumption_and_sources() -> void:
	print("\n--- TESTE 3: Consumo de Água (Pia, Máquinas e Interrupção) ---")

	var wm = WaterManager.new()
	wm.name = "WaterManager"
	get_root().add_child(wm)
	wm.water_tariff_per_liter = 0.02

	# Lavagem de bucha na pia (3 lavagens de 0.50 L = 1.50 L)
	wm.consume_water(0.50, "sink")
	wm.consume_water(0.50, "sink")
	wm.consume_water(0.50, "sink")

	# 10 copos de refrigerante servidos (0.35 L cada = 3.50 L)
	wm.consume_water(3.50, "drink_machine")

	# 5 copos de suco natural preparados (0.35 L cada = 1.75 L)
	wm.consume_water(1.75, "juice_machine")

	var total_liters = wm.get_daily_consumption_liters()
	assert_test(is_equal_approx(total_liters, 6.75), "Consumo total de água acumulado: 6.75 Litros")

	var water_cost = wm.get_daily_water_cost()
	assert_test(is_equal_approx(water_cost, 6.75 * 0.02), "Custo da conta de água: R$ 0.14 (6.75 L x R$ 0.02)")

	var breakdown = wm.get_consumption_breakdown()
	assert_test(is_equal_approx(breakdown["sink"], 1.50), "Pia consumiu exatamente 1.50 Litros")
	assert_test(is_equal_approx(breakdown["drink_machine"], 3.50), "Máquina de refrigerante consumiu 3.50 Litros")
	assert_test(is_equal_approx(breakdown["juice_machine"], 1.75), "Máquina de suco consumiu 1.75 Litros")

	wm.free()

# -----------------------------------------------------------------------------
# 4. TESTE DE SALÁRIOS DE FUNCIONÁRIOS
# -----------------------------------------------------------------------------
func test_employee_salaries() -> void:
	print("\n--- TESTE 4: Salários de Funcionários Operacionais ---")

	var em = EmployeeManager.new()
	em.name = "EmployeeManager"
	get_root().add_child(em)

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	get_root().add_child(fin)
	fin.daily_salary_per_employee = 50.0

	# Sem funcionários contratados -> custo 0
	assert_test(fin.calculate_daily_salaries_cost() == 0.0, "Sem funcionários: custo de salários = R$ 0.00")

	# Simula 2 funcionários contratados
	var emp1 = EmployeeManager.Employee.new()
	emp1.employee_name = "Carlos"
	em.employees.append(emp1)

	var emp2 = EmployeeManager.Employee.new()
	emp2.employee_name = "Mariana"
	em.employees.append(emp2)

	assert_test(fin.calculate_daily_salaries_cost() == 100.0, "2 funcionários contratados: Folha diária = R$ 100.00 (2 x R$ 50.00)")

	emp1.free()
	emp2.free()
	em.free()
	fin.free()

# -----------------------------------------------------------------------------
# 5. TESTE DE GERAÇÃO E PAGAMENTO DE CONTAS A PAGAR NO PC
# -----------------------------------------------------------------------------
func test_bills_generation_and_payment_system() -> void:
	print("\n--- TESTE 5: Geração de Contas e Sistema de Pagamento Interativo ---")

	var econ = EconomyManager.new()
	econ.name = "EconomyManager"
	econ.starting_money = 150.0
	get_root().add_child(econ)
	econ.current_money = 150.0

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	get_root().add_child(fin)

	# Configura valores manuais nas contas
	var bills = fin.get_active_bills()
	bills["electricity"]["amount"] = 30.0
	bills["water"]["amount"] = 15.0
	bills["salaries"]["amount"] = 50.0
	bills["electricity"]["is_paid"] = false
	bills["water"]["is_paid"] = false
	bills["salaries"]["is_paid"] = false

	# 1. Pagar conta de energia (R$ 30.00)
	var res_elec = fin.pay_bill("electricity")
	assert_test(res_elec["success"] == true, "Pagamento da conta de energia realizado com sucesso!")
	assert_test(bills["electricity"]["is_paid"] == true, "Conta de energia marcada como PAGA")
	assert_test(is_equal_approx(econ.get_money(), 120.0), "Saldo descontado para R$ 120.00")

	# 2. Tentativa de pagamento duplicado
	var res_dup = fin.pay_bill("electricity")
	assert_test(res_dup["success"] == false, "Pagamento duplicado bloqueado com sucesso!")

	# 3. Pagar água (R$ 15.00) e salários (R$ 50.00)
	fin.pay_bill("water")
	fin.pay_bill("salaries")
	assert_test(is_equal_approx(econ.get_money(), 55.0), "Saldo após pagar água e salários: R$ 55.00")

	# 4. Tentativa de pagar conta sem saldo
	bills["electricity"]["is_paid"] = false
	bills["electricity"]["amount"] = 100.0 # Saldo atual é 55.0
	var res_fail = fin.pay_bill("electricity")
	assert_test(res_fail["success"] == false, "Pagamento bloqueado por saldo insuficiente sem gerar saldo negativo")
	assert_test(is_equal_approx(econ.get_money(), 55.0), "Saldo permanece inalterado em R$ 55.00")

	fin.free()
	econ.free()

# -----------------------------------------------------------------------------
# 6. TESTE DA INTERFACE DO PC (ABA FINANÇAS, KPIS, RELATÓRIO E HISTÓRICO)
# -----------------------------------------------------------------------------
func test_pc_finances_ui_and_history() -> void:
	print("\n--- TESTE 6: Interface do PC (Aba Finanças, KPIs e Histórico Diário) ---")

	var econ = EconomyManager.new()
	econ.name = "EconomyManager"
	econ.starting_money = 500.0
	get_root().add_child(econ)
	econ.current_money = 500.0

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	get_root().add_child(fin)
	fin.record_sale(300.0, "dine_in", "Vendas do Dia")

	var ui_scene = preload("res://src/ui/computer_ui.tscn")
	var ui = ui_scene.instantiate() as ComputerUI
	get_root().add_child(ui)

	# Abre o PC e navega para a aba Finanças
	ui.open()
	ui._switch_tab(ComputerUI.TabID.FINANCES, "Fluxo Financeiro")

	assert_test(ui.finances_tab != null and ui.finances_tab.visible == true, "Aba Finanças visível no PC ao selecionar na sidebar")
	assert_test(ui.finances_kpi_hbox != null and ui.finances_kpi_hbox.get_child_count() == 4, "4 Cards de KPI renderizados no topo (Saldo, Receita, Despesas, Lucro)")

	# Testa navegação entre sub-seções de Finanças
	ui._set_finances_section("REVENUE")
	assert_test(ui.current_finances_section == "REVENUE", "Sub-seção 'Entradas (Vendas)' acessada")

	ui._set_finances_section("EXPENSES")
	assert_test(ui.current_finances_section == "EXPENSES", "Sub-seção 'Saídas (Custos)' acessada")

	ui._set_finances_section("BILLS")
	assert_test(ui.current_finances_section == "BILLS", "Sub-seção 'Contas a Pagar' acessada")

	# Testa fechamento do dia e histórico
	var day_report = fin.close_current_day()
	assert_test(day_report.get("total_revenue", 0.0) == 300.0, "Relatório do dia fechado com receita de R$ 300.00")
	assert_test(fin.get_reports_history().size() == 1, "Histórico financeiro gravado com 1 dia encerrado")

	ui._set_finances_section("HISTORY")
	assert_test(ui.current_finances_section == "HISTORY", "Sub-seção 'Relatório dos Dias' exibe o histórico persistido")

	ui.free()
	fin.free()
	econ.free()
