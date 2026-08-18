class_name FinanceManager
extends Node

# =============================================================================
# BURGER RUSH - CENTRO FINANCEIRO CENTRAL (FINANCE MANAGER)
#
# Consolida todas as métricas financeiras reais do restaurante sem criar dados paralelos:
#  - Receitas por canal (Salão/Dine-In, Drive-Thru, Delivery)
#  - Despesas reais (Compras de insumos, Energia Elétrica, Água, Salários)
#  - Sistema de Contas a Pagar / Pagas com quitação interativa pelo PC
#  - Histórico persistente de relatórios diários
# =============================================================================

signal finances_updated()
signal bill_paid(bill_id: String, amount: float)
signal day_report_closed(day_report: Dictionary)


static var instance = null

## Tarifas Operacionais de Utilidades
@export var electricity_tariff_kwh: float = 0.85 # R$ 0,85 por kWh
@export var water_tariff_liter: float = 0.02     # R$ 0,02 por Litro
@export var daily_salary_per_employee: float = 50.00 # R$ 50,00 por dia por funcionário

## Receitas do Dia Atual por Canal
var daily_revenue: Dictionary = {
	"dine_in": 0.0,
	"drive_thru": 0.0,
	"delivery": 0.0,
	"other": 0.0
}

## Despesas Adicionais do Dia Atual
var daily_other_expenses: float = 0.0

## Contas Geradas para o Dia Atual
## Formato: bill_id -> Dictionary { id, title, category, amount, details, is_paid, paid_day }
var active_bills: Dictionary = {}

## Histórico de Relatórios Diários
var daily_reports_history: Array[Dictionary] = []

func _init() -> void:
	instance = self

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance():
	if instance and is_instance_valid(instance):
		return instance
	return null

func _ready() -> void:
	var clock = _get_game_clock()
	if clock:
		if not clock.day_started.is_connected(_on_day_started):
			clock.day_started.connect(_on_day_started)
		if not clock.day_ended.is_connected(_on_day_ended):
			clock.day_ended.connect(_on_day_ended)
	_ensure_daily_bills()

func _get_game_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _get_daily_event_manager():
	var dem = DailyEventManager.get_instance()
	if not dem and is_inside_tree() and get_tree() and get_tree().root:
		if get_tree().root.has_node("DailyEventManager"):
			dem = get_tree().root.get_node("DailyEventManager")
		else:
			dem = get_tree().root.find_child("DailyEventManager", true, false)
	if dem and is_instance_valid(dem):
		return dem
	return null

func _get_economy_manager():
	var econ = EconomyManager.get_instance()
	if not econ and is_inside_tree() and get_tree() and get_tree().root:
		if get_tree().root.has_node("EconomyManager"):
			econ = get_tree().root.get_node("EconomyManager")
		else:
			econ = get_tree().root.find_child("EconomyManager", true, false)
	if econ and is_instance_valid(econ):
		return econ
	return null

func _get_power_manager():
	var pm = PowerManager.get_instance()
	if not pm and is_inside_tree() and get_tree() and get_tree().root:
		if get_tree().root.has_node("PowerManager"):
			pm = get_tree().root.get_node("PowerManager")
		else:
			pm = get_tree().root.find_child("PowerManager", true, false)
	if pm and is_instance_valid(pm):
		return pm
	return null

func _get_water_manager():
	var wm = WaterManager.get_instance()
	if not wm and is_inside_tree() and get_tree() and get_tree().root:
		if get_tree().root.has_node("WaterManager"):
			wm = get_tree().root.get_node("WaterManager")
		else:
			wm = get_tree().root.find_child("WaterManager", true, false)
	if wm and is_instance_valid(wm):
		return wm
	return null

func _get_employee_manager():
	var em = EmployeeManager.get_instance()
	if not em and is_inside_tree() and get_tree() and get_tree().root:
		if get_tree().root.has_node("EmployeeManager"):
			em = get_tree().root.get_node("EmployeeManager")
		else:
			em = get_tree().root.find_child("EmployeeManager", true, false)
	if em and is_instance_valid(em):
		return em
	return null

func _on_day_started(_day_number: int) -> void:
	start_new_day()

func _on_day_ended(_summary = null) -> void:
	close_current_day()

# =============================================================================
# REGISTRO DE RECEITAS POR CANAL
# =============================================================================

## Registra uma venda concluída e efetivamente paga no canal correspondente
func record_sale(amount: float, channel: String = "dine_in", description: String = "Venda") -> void:
	if amount <= 0.0:
		return

	var valid_channel = channel.to_lower()
	if valid_channel.contains("drive"):
		valid_channel = "drive_thru"
	elif valid_channel.contains("delivery") or valid_channel.contains("app"):
		valid_channel = "delivery"
	elif not daily_revenue.has(valid_channel):
		valid_channel = "dine_in"

	daily_revenue[valid_channel] = daily_revenue.get(valid_channel, 0.0) + amount

	var economy = _get_economy_manager()
	if economy:
		# add_money já adiciona no current_money e gera a transação
		economy.add_money(amount, "%s (%s)" % [description, valid_channel.to_upper()])

	finances_updated.emit()

func register_channel_sale(channel: String, amount: float, description: String = "Venda") -> void:
	record_sale(amount, channel, description)

func get_channel_revenue(channel: String) -> float:
	return get_daily_revenue_by_channel(channel)

func get_total_daily_revenue() -> float:
	var sum: float = 0.0
	for k in daily_revenue.keys():
		sum += daily_revenue[k]
	return sum

func get_daily_revenue_by_channel(channel: String) -> float:
	return daily_revenue.get(channel, 0.0)

# =============================================================================
# CÁLCULO E DETALHAMENTO DE DESPESAS
# =============================================================================

## Retorna o valor das compras realizadas no dia
func get_daily_purchases_cost() -> float:
	var economy = _get_economy_manager()
	if economy:
		return economy.get_daily_purchases()
	return 0.0

## Calcula o custo de energia elétrica do dia (kWh acumulado * tarifa * modificador de evento)
func calculate_daily_electricity_cost() -> float:
	var pm = _get_power_manager()
	var kwh = pm.get_daily_energy_consumption_kwh() if pm else 0.0

	var mult = 1.0
	var dem = _get_daily_event_manager()
	if dem:
		mult = dem.electricity_cost_multiplier

	return kwh * electricity_tariff_kwh * mult

## Retorna o consumo de energia em kWh acumulado no dia
func get_daily_electricity_kwh() -> float:
	var pm = _get_power_manager()
	return pm.get_daily_energy_consumption_kwh() if pm else 0.0

## Calcula o custo de água do dia (Litros * tarifa)
func calculate_daily_water_cost() -> float:
	var wm = _get_water_manager()
	if wm:
		return wm.get_daily_water_cost()
	return 0.0

## Retorna o consumo de água em Litros acumulado no dia
func get_daily_water_liters() -> float:
	var wm = _get_water_manager()
	if wm:
		return wm.get_daily_consumption_liters()
	return 0.0

## Calcula o custo de salários dos funcionários ativos no dia
func calculate_daily_salaries_cost() -> float:
	var em = _get_employee_manager()
	if em:
		var emp_count = em.get_employees().size()
		return emp_count * daily_salary_per_employee
	return 0.0

## Retorna o número de funcionários contratados
func get_active_employees_count() -> int:
	var em = _get_employee_manager()
	return em.get_employees().size() if em else 0

## Retorna o total de despesas calculadas no dia
func get_total_daily_expenses() -> float:
	return get_daily_purchases_cost() + calculate_daily_electricity_cost() + calculate_daily_water_cost() + calculate_daily_salaries_cost() + daily_other_expenses

## Retorna o Lucro Bruto do dia (Receita Total - Compras de Insumos)
func get_daily_gross_profit() -> float:
	return get_total_daily_revenue() - get_daily_purchases_cost()

## Retorna o Lucro Líquido do dia (Receita Total - Total de Despesas)
func get_daily_net_profit() -> float:
	return get_total_daily_revenue() - get_total_daily_expenses()

# =============================================================================
# SISTEMA DE CONTAS DO FINAL DO DIA (CONTAS A PAGAR)
# =============================================================================

func _ensure_daily_bills() -> void:
	# Atualiza os valores em tempo real das contas ativas
	var elec_cost = calculate_daily_electricity_cost()
	var elec_kwh = get_daily_electricity_kwh()
	var dem = _get_daily_event_manager()
	var elec_details = "Consumo: %.2f kWh (Tarifa R$ %.2f/kWh)" % [elec_kwh, electricity_tariff_kwh]
	if dem and dem.electricity_cost_multiplier > 1.0:
		elec_details += " [⚡ +30%% Regulagem de Rede]"

	if not active_bills.has("electricity"):
		active_bills["electricity"] = {
			"id": "electricity",
			"title": "Energia Elétrica",
			"category": "utilities",
			"amount": elec_cost,
			"details": elec_details,
			"is_paid": false,
			"paid_day": 0
		}
	elif not active_bills["electricity"].get("is_paid", false):
		if elec_cost > 0.0 or not active_bills["electricity"].has("amount"):
			active_bills["electricity"]["amount"] = elec_cost
		active_bills["electricity"]["details"] = elec_details

	var water_cost = calculate_daily_water_cost()
	var water_liters = get_daily_water_liters()
	var water_details = "Consumo: %.1f Litros (Tarifa R$ %.2f/L)" % [water_liters, water_tariff_liter]

	if not active_bills.has("water"):
		active_bills["water"] = {
			"id": "water",
			"title": "Água e Saneamento",
			"category": "utilities",
			"amount": water_cost,
			"details": water_details,
			"is_paid": false,
			"paid_day": 0
		}
	elif not active_bills["water"].get("is_paid", false):
		if water_cost > 0.0 or not active_bills["water"].has("amount"):
			active_bills["water"]["amount"] = water_cost
		active_bills["water"]["details"] = water_details

	var salaries_cost = calculate_daily_salaries_cost()
	var emp_count = get_active_employees_count()
	var salaries_details = "%d funcionários contratados (R$ %.2f/dia cada)" % [emp_count, daily_salary_per_employee]

	if not active_bills.has("salaries"):
		active_bills["salaries"] = {
			"id": "salaries",
			"title": "Folha de Salários",
			"category": "payroll",
			"amount": salaries_cost,
			"details": salaries_details,
			"is_paid": (salaries_cost == 0.0),
			"paid_day": 0
		}
	elif not active_bills["salaries"].get("is_paid", false):
		if salaries_cost > 0.0 or not active_bills["salaries"].has("amount"):
			active_bills["salaries"]["amount"] = salaries_cost
		active_bills["salaries"]["details"] = salaries_details
		if salaries_cost == 0.0 and active_bills["salaries"]["amount"] == 0.0:
			active_bills["salaries"]["is_paid"] = true

func get_active_bills() -> Dictionary:
	_ensure_daily_bills()
	return active_bills

## Paga uma conta específica pendente
func pay_bill(bill_id: String) -> Dictionary:
	_ensure_daily_bills()
	if not active_bills.has(bill_id):
		return {"success": false, "message": "Conta não encontrada!"}

	var bill = active_bills[bill_id]
	if bill.get("is_paid", false):
		return {"success": false, "message": "Esta conta já foi paga!"}

	var amount: float = bill.get("amount", 0.0)
	if amount <= 0.0:
		bill["is_paid"] = true
		finances_updated.emit()
		return {"success": true, "message": "Conta zerada marcada como paga."}

	var economy = _get_economy_manager()
	if not economy or economy.get_money() < amount:
		return {"success": false, "message": "Saldo insuficiente para pagar esta conta (R$ %.2f necessário)!" % amount}

	if not economy.spend_money(amount, "Pagamento: %s" % bill.get("title", bill_id)):
		return {"success": false, "message": "Falha na transação financeira!"}

	bill["is_paid"] = true
	var clock = _get_game_clock()
	bill["paid_day"] = clock.day_number if clock else 1

	bill_paid.emit(bill_id, amount)
	finances_updated.emit()
	return {"success": true, "message": "Conta de %s paga com sucesso (R$ %.2f)!" % [bill.get("title", bill_id), amount]}

# =============================================================================
# FECHAMENTO E HISTÓRICO DE RELATÓRIOS DIÁRIOS
# =============================================================================

func start_new_day() -> void:
	# Reinicializa receitas do dia
	for k in daily_revenue.keys():
		daily_revenue[k] = 0.0
	daily_other_expenses = 0.0

	# Reseta o status das contas para o novo dia
	active_bills.clear()
	_ensure_daily_bills()
	finances_updated.emit()

func close_current_day() -> Dictionary:
	_ensure_daily_bills()

	var clock = _get_game_clock()
	var day_num = clock.day_number if clock else 1
	var weekday = clock.get_weekday_name() if clock else "Segunda-feira"

	var total_rev = get_total_daily_revenue()
	var pur_cost = get_daily_purchases_cost()
	var elec_cost = calculate_daily_electricity_cost()
	var water_cost = calculate_daily_water_cost()
	var sal_cost = calculate_daily_salaries_cost()
	var total_exp = get_total_daily_expenses()
	var gross_prof = total_rev - pur_cost
	var net_prof = total_rev - total_exp

	var report = {
		"day_number": day_num,
		"weekday": weekday,
		"total_revenue": total_rev,
		"revenue_breakdown": daily_revenue.duplicate(),
		"purchases_cost": pur_cost,
		"electricity_cost": elec_cost,
		"electricity_kwh": get_daily_electricity_kwh(),
		"water_cost": water_cost,
		"water_liters": get_daily_water_liters(),
		"salaries_cost": sal_cost,
		"employees_count": get_active_employees_count(),
		"other_expenses": daily_other_expenses,
		"total_expenses": total_exp,
		"gross_profit": gross_prof,
		"net_profit": net_prof,
		"bills_status": {
			"electricity_paid": active_bills.get("electricity", {}).get("is_paid", false),
			"water_paid": active_bills.get("water", {}).get("is_paid", false),
			"salaries_paid": active_bills.get("salaries", {}).get("is_paid", false)
		}
	}

	daily_reports_history.append(report)
	day_report_closed.emit(report)
	finances_updated.emit()
	return report

func get_reports_history() -> Array[Dictionary]:
	return daily_reports_history

func get_report_for_day(day_number: int) -> Dictionary:
	for rep in daily_reports_history:
		if rep.get("day_number", 0) == day_number:
			return rep
	return {}

## Retorna dados agregados para o Calendário e Dashboard
func get_financial_data() -> Dictionary:
	return {
		"daily_revenue": get_total_daily_revenue(),
		"daily_expenses": get_total_daily_expenses(),
		"daily_profit": get_daily_net_profit(),
		"daily_channels": {
			"dine_in": get_daily_revenue_by_channel("dine_in"),
			"drive_thru": get_daily_revenue_by_channel("drive_thru"),
			"delivery": get_daily_revenue_by_channel("delivery")
		}
	}
