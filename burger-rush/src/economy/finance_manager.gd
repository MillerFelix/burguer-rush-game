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

## Contas Pendentes Acumuladas
## Array de Dictionaries { id, category, title, amount, original_amount, day_issued, due_day, penalty_applied, is_paid }
var pending_bills: Array[Dictionary] = []

## Custo base de manutenção da Sala dos Funcionários
@export var base_staff_room_maintenance: float = 45.00

## Retorna o custo diário da Sala dos Funcionários (Manutenção + Salários)
func calculate_daily_staff_room_cost() -> float:
	return base_staff_room_maintenance + calculate_daily_salaries_cost()

# =============================================================================
# SISTEMA DE CONTAS (ENERGIA, ÁGUA, SALA DOS FUNCIONÁRIOS)
# =============================================================================

func _ensure_daily_bills() -> void:
	var clock = _get_game_clock()
	var day_num: int = clock.day_number if clock else 1

	# 1. ENERGIA
	var elec_cost = maxf(40.0, calculate_daily_electricity_cost())
	var elec_kwh = get_daily_electricity_kwh()
	var dem = _get_daily_event_manager()
	var elec_details = "Consumo: %.2f kWh (Tarifa R$ %.2f/kWh)" % [elec_kwh, electricity_tariff_kwh]
	if dem and dem.electricity_cost_multiplier > 1.0:
		elec_details += " [⚡ +30%% Regulagem de Rede]"

	if not active_bills.has("electricity"):
		active_bills["electricity"] = {
			"id": "electricity",
			"category": "electricity",
			"title": "Energia",
			"amount": elec_cost,
			"details": elec_details,
			"is_paid": false,
			"paid_day": 0
		}
	elif not active_bills["electricity"].get("is_paid", false):
		active_bills["electricity"]["amount"] = elec_cost
		active_bills["electricity"]["details"] = elec_details

	# 2. ÁGUA
	var water_cost = maxf(25.0, calculate_daily_water_cost())
	var water_liters = get_daily_water_liters()
	var water_details = "Consumo: %.1f Litros (Tarifa R$ %.2f/L)" % [water_liters, water_tariff_liter]

	if not active_bills.has("water"):
		active_bills["water"] = {
			"id": "water",
			"category": "water",
			"title": "Água",
			"amount": water_cost,
			"details": water_details,
			"is_paid": false,
			"paid_day": 0
		}
	elif not active_bills["water"].get("is_paid", false):
		active_bills["water"]["amount"] = water_cost
		active_bills["water"]["details"] = water_details

	# 3. SALA DOS FUNCIONÁRIOS
	var staff_cost = calculate_daily_staff_room_cost()
	var emp_count = get_active_employees_count()
	var staff_details = "Manutenção (R$ %.2f) + %d funcionários (R$ %.2f/dia)" % [base_staff_room_maintenance, emp_count, daily_salary_per_employee]

	if not active_bills.has("staff_room"):
		active_bills["staff_room"] = {
			"id": "staff_room",
			"category": "staff_room",
			"title": "Sala dos Funcionários",
			"amount": staff_cost,
			"details": staff_details,
			"is_paid": false,
			"paid_day": 0
		}
	elif not active_bills["staff_room"].get("is_paid", false):
		active_bills["staff_room"]["amount"] = staff_cost
		active_bills["staff_room"]["details"] = staff_details

	# Compatibilidade com referências antigas a "salaries"
	active_bills["salaries"] = active_bills["staff_room"]

func get_active_bills() -> Dictionary:
	_ensure_daily_bills()
	return active_bills

func get_pending_bills() -> Array[Dictionary]:
	return pending_bills

## Retorna o valor total pendente acumulado para uma categoria específica
func get_category_pending_amount(category: String) -> float:
	var total: float = 0.0
	_ensure_daily_bills()

	# Adiciona conta do dia se não estiver paga
	if active_bills.has(category) and not active_bills[category].get("is_paid", false):
		total += active_bills[category].get("amount", 0.0)

	# Adiciona contas anteriores pendentes acumuladas
	for b in pending_bills:
		if b.get("category", "") == category and not b.get("is_paid", false):
			total += b.get("amount", 0.0)

	return total

## Retorna a dívida total pendente de todas as contas acumuladas
func get_total_pending_debt() -> float:
	return get_category_pending_amount("electricity") + get_category_pending_amount("water") + get_category_pending_amount("staff_room")

## Paga uma conta específica pendente
func pay_bill(bill_id: String) -> Dictionary:
	_ensure_daily_bills()
	var target_cat = bill_id
	if bill_id == "salaries":
		target_cat = "staff_room"

	var amount_to_pay = get_category_pending_amount(target_cat)
	if amount_to_pay <= 0.0:
		return {"success": false, "message": "Não há contas pendentes nesta categoria!"}

	var economy = _get_economy_manager()
	if not economy or economy.get_money() < amount_to_pay:
		return {"success": false, "message": "Saldo insuficiente para pagar esta conta (R$ %.2f necessário)!" % amount_to_pay}

	var cat_name = "Energia" if target_cat == "electricity" else ("Água" if target_cat == "water" else "Sala dos Funcionários")
	if not economy.spend_money(amount_to_pay, "Pagamento de Contas: %s" % cat_name):
		return {"success": false, "message": "Falha na transação financeira!"}

	# Quita a conta do dia
	if active_bills.has(target_cat):
		active_bills[target_cat]["is_paid"] = true
		var clock = _get_game_clock()
		active_bills[target_cat]["paid_day"] = clock.day_number if clock else 1

	# Quita todas as pendências acumuladas dessa categoria
	for b in pending_bills:
		if b.get("category", "") == target_cat:
			b["is_paid"] = true

	pending_bills = pending_bills.filter(func(b): return not b.get("is_paid", false))

	bill_paid.emit(bill_id, amount_to_pay)
	finances_updated.emit()
	return {"success": true, "message": "Contas de %s quitadas com sucesso (R$ %.2f)!" % [cat_name, amount_to_pay]}

## Paga todas as contas pendentes do restaurante de uma vez
func pay_all_bills() -> Dictionary:
	_ensure_daily_bills()
	var total_debt = get_total_pending_debt()
	if total_debt <= 0.0:
		return {"success": false, "message": "Todas as contas já estão em dia!"}

	var economy = _get_economy_manager()
	if not economy or economy.get_money() < total_debt:
		return {"success": false, "message": "Saldo insuficiente para quitar todas as contas (R$ %.2f necessário)!" % total_debt}

	if not economy.spend_money(total_debt, "Quitação Total de Contas do Restaurante"):
		return {"success": false, "message": "Falha na transação financeira!"}

	for k in active_bills.keys():
		active_bills[k]["is_paid"] = true

	for b in pending_bills:
		b["is_paid"] = true

	pending_bills.clear()
	finances_updated.emit()
	return {"success": true, "message": "Todas as contas pendentes foram quitadas com sucesso (R$ %.2f)!" % total_debt}

# =============================================================================
# FECHAMENTO E HISTÓRICO DE RELATÓRIOS DIÁRIOS
# =============================================================================

func start_new_day() -> void:
	var clock = _get_game_clock()
	var day_num = clock.day_number if clock else 1

	# 1. Reinicializa receitas do dia
	for k in daily_revenue.keys():
		daily_revenue[k] = 0.0
	daily_other_expenses = 0.0

	# 2. Processa contas atrasadas (+25% de juros uma única vez após 7 dias)
	_process_overdue_and_pending_bills(day_num)

	# 3. Reseta status das contas para o novo dia
	active_bills.clear()
	_ensure_daily_bills()
	finances_updated.emit()

func _process_overdue_and_pending_bills(current_day: int) -> void:
	var economy = _get_economy_manager()

	for b in pending_bills:
		if b.get("is_paid", false):
			continue

		var due_day: int = int(b.get("due_day", b.get("day_issued", 1) + 7))
		# Se ultrapassou o prazo de 7 dias
		if current_day >= due_day:
			if not b.get("penalty_applied", false):
				# Aplica 25% de juros uma única vez
				b["amount"] = b["amount"] * 1.25
				b["penalty_applied"] = true

			# Tenta cobrança automática se o jogador tiver dinheiro suficiente
			var amt: float = b["amount"]
			if economy and economy.get_money() >= amt:
				economy.spend_money(amt, "Cobrança Automática (+25%% Multa): %s" % b.get("title", "Conta"))
				b["is_paid"] = true

	# Remove as contas que foram quitadas na cobrança automática
	pending_bills = pending_bills.filter(func(b): return not b.get("is_paid", false))

func close_current_day() -> Dictionary:
	_ensure_daily_bills()

	var clock = _get_game_clock()
	var day_num = clock.day_number if clock else 1
	var weekday = clock.get_weekday_name() if clock else "Segunda-feira"

	# Move contas não pagas do dia para a lista acumulada de pendências
	for cat in ["electricity", "water", "staff_room"]:
		if active_bills.has(cat) and not active_bills[cat].get("is_paid", false):
			var cur_amt: float = active_bills[cat].get("amount", 0.0)
			if cur_amt > 0.0:
				pending_bills.append({
					"id": "%s_d%d" % [cat, day_num],
					"category": cat,
					"title": "%s (Dia %d)" % [active_bills[cat].get("title", cat), day_num],
					"amount": cur_amt,
					"original_amount": cur_amt,
					"day_issued": day_num,
					"due_day": day_num + 7,
					"penalty_applied": false,
					"is_paid": false
				})

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
