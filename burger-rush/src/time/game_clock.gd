class_name GameClock
extends Node

const CalendarManager = preload("res://src/core/calendar_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")

enum State {
	PREPARATION,
	OPEN,
	CLOSING,
	CLOSED
}

signal time_tick(hours: int, minutes: int)
signal state_changed(new_state: State)
signal day_started(day_number: int)
signal day_ended(summary: DaySummary)
signal week_ended(report: WeeklyReport)

static var instance: GameClock = null

# Horário Oficial Burger Rush:
# 09:00 -> Início do dia (Preparação)
# 09:00 - 10:00 -> Preparação e abertura manual
# 10:00 -> Abertura automática
# 10:00 - 22:00 -> Restaurante Aberto
# 22:00 -> Fechamento
@export var start_hour: int = 9
@export var start_minute: int = 0
@export var auto_open_hour: int = 10
@export var auto_open_minute: int = 0
@export var closing_hour: int = 22
@export var closing_minute: int = 0
@export var time_scale: float = 1.0 # 1 segundo real = 1 minuto de jogo
@export var is_paused: bool = false

var day_number: int = 1
var day_of_week: int = 4 # 1 = Segunda, ..., 4 = Quinta (01/01/2026), 7 = Domingo
var week_number: int = 1
var state: State = State.PREPARATION
var current_hour: int = 9
var current_minute: int = 0
var accumulated_seconds: float = 0.0

var starting_day_money: float = 100.0
var day_history: Array[DaySummary] = []

var weekdays: Array[String] = [
	"Segunda-feira",
	"Terça-feira",
	"Quarta-feira",
	"Quinta-feira",
	"Sexta-feira",
	"Sábado",
	"Domingo"
]

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	current_hour = start_hour
	current_minute = start_minute
	state = State.PREPARATION

	var cal = CalendarManager.get_instance()
	if cal:
		day_number = cal.day_number
		day_of_week = cal.day_of_week
	else:
		day_number = 1
		day_of_week = 4

	var economy = EconomyManager.get_instance()
	if economy:
		starting_day_money = economy.get_money()

static func get_instance() -> GameClock:
	return instance

func get_weekday_name() -> String:
	var cal = CalendarManager.get_instance()
	if cal:
		return cal.get_weekday_name()
	var idx = (day_of_week - 1) % 7
	return weekdays[idx]

func _process(delta: float) -> void:
	if is_paused or state == State.CLOSED:
		return

	accumulated_seconds += delta * time_scale
	while accumulated_seconds >= 1.0:
		accumulated_seconds -= 1.0
		_advance_minute()

	# Às 22:00+, o restaurante entra em CLOSING e só fecha o dia quando não houver clientes ou pedidos
	if state == State.CLOSING:
		if can_finish_day():
			close_day()

func can_finish_day() -> bool:
	if state != State.CLOSING:
		return false

	var root_scene = get_parent() if get_parent() else self

	# 1. Clientes no salão, mesas, fila ou em trânsito
	if is_inside_tree() and get_tree():
		var all_customers = get_tree().get_nodes_in_group("customers")
		for c in all_customers:
			if is_instance_valid(c) and not c.is_queued_for_deletion() and c.get("state") != 13: # Customer.State.FINISHED
				return false

	var spawner = root_scene.get_node_or_null("CustomerSpawner")
	if not spawner and is_inside_tree() and get_tree() and get_tree().root:
		spawner = get_tree().root.find_child("CustomerSpawner", true, false)
	if spawner and spawner.has_method("has_active_customers") and spawner.has_active_customers():
		return false

	# 2. Carros no Drive-Thru
	var deliv_mgr = root_scene.get_node_or_null("DeliveryQueueManager")
	if not deliv_mgr and is_inside_tree() and get_tree() and get_tree().root:
		deliv_mgr = get_tree().root.find_child("DeliveryQueueManager", true, false)
	if deliv_mgr and deliv_mgr.has_method("has_active_cars") and deliv_mgr.has_active_cars():
		return false

	# 3. Pedidos em andamento / preparo
	var order_mgr = root_scene.get_node_or_null("OrderManager")
	if not order_mgr:
		order_mgr = OrderManager.instance
	if not order_mgr and is_inside_tree() and get_tree() and get_tree().root:
		order_mgr = get_tree().root.find_child("OrderManager", true, false)
	if order_mgr and order_mgr.has_method("has_pending_orders") and order_mgr.has_pending_orders():
		return false

	# 4. Fila da caixa registradora
	var register = root_scene.get_node_or_null("CashRegister")
	if not register:
		register = CashRegister.instance
	if not register and is_inside_tree() and get_tree() and get_tree().root:
		register = get_tree().root.find_child("CashRegister", true, false)
	if register and register.has_method("has_customers_in_queue") and register.has_customers_in_queue():
		return false

	return true

func _advance_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1

	time_tick.emit(current_hour, current_minute)

	# Transição automática: PREPARATION -> OPEN (às 10:00 se ainda estiver fechado)
	if state == State.PREPARATION:
		if current_hour > auto_open_hour or (current_hour == auto_open_hour and current_minute >= auto_open_minute):
			open_restaurant()

	# Transição automática: OPEN -> CLOSING (às 22:00 - para novos clientes)
	elif state == State.OPEN:
		if current_hour > closing_hour or (current_hour == closing_hour and current_minute >= closing_minute):
			set_state(State.CLOSING)

func open_restaurant() -> void:
	if state == State.PREPARATION:
		set_state(State.OPEN)

func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)

func close_day() -> DaySummary:
	set_state(State.CLOSED)

	var economy = EconomyManager.get_instance()
	var order_mgr = OrderManager.get_instance()
	var waste_mgr = WasteManager.get_instance()
	var rep_mgr = ReputationManager.get_instance()

	var summary = DaySummary.new()
	summary.day_number = day_number
	summary.starting_balance = starting_day_money
	summary.ending_balance = economy.get_money() if economy else 100.0

	if economy:
		summary.revenue = economy.get_daily_sales()
		summary.purchases = economy.get_daily_purchases()
		summary.net_profit = economy.get_daily_net()
	else:
		summary.revenue = summary.ending_balance - summary.starting_balance
		summary.purchases = 0.0
		summary.net_profit = summary.revenue

	if order_mgr:
		summary.orders_completed = order_mgr.daily_completed_orders
		summary.orders_cancelled = order_mgr.daily_cancelled_orders
		summary.total_orders = summary.orders_completed + summary.orders_cancelled
		summary.avg_wait_time = order_mgr.get_avg_wait_time()

	day_history.append(summary)
	day_ended.emit(summary)

	# Registra estatísticas no WeeklyReportManager
	var weekly_mgr = WeeklyReportManager.get_instance()
	if weekly_mgr:
		var w_loss = waste_mgr.get_daily_waste_cost() if waste_mgr else 0.0
		var c_count = summary.orders_completed
		weekly_mgr.record_daily_stats(summary.revenue, summary.purchases, w_loss, summary.orders_completed, c_count)

	# Se for Domingo (Dia 7 da semana): Processa o Fechamento Semanal
	if day_of_week == 7 and weekly_mgr:
		var emp_mgr = EmployeeManager.get_instance()
		var payroll_info = emp_mgr.process_weekly_payroll() if emp_mgr else {"total_salaries": 0.0, "employees_summary": []}
		var ending_bal = economy.get_money() if economy else 100.0
		var avg_stars = rep_mgr.get_average_rating() if rep_mgr else 5.0

		var weekly_report = weekly_mgr.close_week(
			week_number,
			ending_bal,
			payroll_info.get("total_salaries", 0.0),
			payroll_info.get("employees_summary", []),
			avg_stars
		)
		week_ended.emit(weekly_report)

	return summary

func start_next_day() -> void:
	var cal = CalendarManager.get_instance()
	if cal:
		cal.advance_day()
		day_number = cal.day_number
		day_of_week = cal.day_of_week
	else:
		day_number += 1
		day_of_week = ((day_of_week % 7) + 1)

	if day_of_week == 1:
		week_number += 1

	current_hour = start_hour
	current_minute = start_minute
	accumulated_seconds = 0.0

	var dem = DailyEventManager.get_instance()
	if dem:
		dem.roll_daily_event()

	var economy = EconomyManager.get_instance()
	if economy:
		starting_day_money = economy.get_money()
		if economy.has_method("start_new_day"):
			economy.start_new_day()

	var order_mgr = OrderManager.get_instance()
	if order_mgr and order_mgr.has_method("start_new_day"):
		order_mgr.start_new_day()

	var waste_mgr = WasteManager.get_instance()
	if waste_mgr and waste_mgr.has_method("start_new_day"):
		waste_mgr.start_new_day()

	set_state(State.PREPARATION)
	day_started.emit(day_number)
	time_tick.emit(current_hour, current_minute)

func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_state_string() -> String:
	match state:
		State.PREPARATION:
			return "PREPARAÇÃO"
		State.OPEN:
			return "ABERTO"
		State.CLOSING:
			return "ENCERRANDO"
		State.CLOSED:
			return "FECHADO"
		_:
			return "DESCONHECIDO"
