class_name WeeklyReportManager
extends Node

signal week_closed(report: WeeklyReport)

static var instance: WeeklyReportManager = null

var reports: Array[WeeklyReport] = []

# Acumuladores da semana em curso
var current_week_sales: float = 0.0
var current_week_purchases: float = 0.0
var current_week_waste: float = 0.0
var current_week_customers: int = 0
var current_week_orders: int = 0
var week_starting_balance: float = 100.0

func _enter_tree() -> void:
	instance = self

static func get_instance() -> WeeklyReportManager:
	return instance

func _ready() -> void:
	var economy = EconomyManager.get_instance()
	if economy:
		week_starting_balance = economy.get_money()

func record_daily_stats(revenue: float, purchases: float, waste: float, orders: int, customers: int) -> void:
	current_week_sales += revenue
	current_week_purchases += purchases
	current_week_waste += waste
	current_week_orders += orders
	current_week_customers += customers

func close_week(week_num: int, ending_bal: float, salaries: float, emp_summaries: Array[Dictionary], avg_stars: float = 5.0) -> WeeklyReport:
	var rep = WeeklyReport.new()
	rep.week_number = week_num
	rep.starting_balance = week_starting_balance
	rep.ending_balance = ending_bal
	rep.total_sales = current_week_sales
	rep.total_purchases = current_week_purchases
	rep.total_waste = current_week_waste
	rep.total_salaries = salaries
	rep.net_profit = rep.total_sales - (rep.total_purchases + rep.total_waste + rep.total_salaries)
	rep.orders_completed = current_week_orders
	rep.customers_served = current_week_customers
	rep.avg_satisfaction = avg_stars
	rep.employees_summary = emp_summaries

	reports.append(rep)
	week_closed.emit(rep)

	# Reseta acumuladores para a nova semana
	current_week_sales = 0.0
	current_week_purchases = 0.0
	current_week_waste = 0.0
	current_week_orders = 0
	current_week_customers = 0
	week_starting_balance = ending_bal

	return rep

func get_reports() -> Array[WeeklyReport]:
	return reports

func get_latest_report() -> WeeklyReport:
	if reports.is_empty():
		return null
	return reports[reports.size() - 1]
