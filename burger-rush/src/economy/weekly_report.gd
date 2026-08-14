class_name WeeklyReport
extends RefCounted

var week_number: int = 1
var starting_balance: float = 100.0
var ending_balance: float = 100.0
var total_sales: float = 0.0
var total_purchases: float = 0.0
var total_waste: float = 0.0
var total_salaries: float = 0.0
var net_profit: float = 0.0

var customers_served: int = 0
var orders_completed: int = 0
var avg_satisfaction: float = 5.0

var employees_summary: Array[Dictionary] = []
