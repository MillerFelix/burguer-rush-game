extends Node

const Transaction = preload("res://src/economy/transaction.gd")

signal money_changed(new_amount: float, delta: float)
signal transaction_recorded(transaction: Transaction)

static var instance = null

@export var starting_money: float = 100.0

var current_money: float = 100.0
var total_earned: float = 0.0
var total_spent: float = 0.0

var daily_sales: float = 0.0
var daily_purchases: float = 0.0

var transactions: Array[Transaction] = []

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	current_money = starting_money

static func get_instance():
	if instance and is_instance_valid(instance):
		return instance
	return null

func add_money(amount: float, description: String = "Venda") -> void:
	if amount <= 0:
		return
	current_money += amount
	total_earned += amount
	daily_sales += amount

	var t = _create_transaction(Transaction.Type.SALE, amount, description)
	transactions.append(t)
	transaction_recorded.emit(t)
	money_changed.emit(current_money, amount)

## Alias compatível com cash_register.gd — registra uma venda financeira
func register_sale(amount: float) -> void:
	add_money(amount, "Venda no Caixa")

func spend_money(amount: float, description: String = "Compra") -> bool:
	if amount <= 0 or current_money < amount:
		return false
	current_money -= amount
	total_spent += amount
	daily_purchases += amount

	var t = _create_transaction(Transaction.Type.PURCHASE, amount, description)
	transactions.append(t)
	transaction_recorded.emit(t)
	money_changed.emit(current_money, -amount)
	return true

func get_money() -> float:
	return current_money

func get_daily_sales() -> float:
	return daily_sales

func get_daily_purchases() -> float:
	return daily_purchases

func get_daily_net() -> float:
	return daily_sales - daily_purchases

func get_transactions() -> Array[Transaction]:
	return transactions

func start_new_day() -> void:
	daily_sales = 0.0
	daily_purchases = 0.0

func _create_transaction(type: Transaction.Type, amount: float, description: String) -> Transaction:
	var day = 1
	var time_str = "08:00"
	var clock = GameClock.get_instance()
	if clock:
		day = clock.day_number
		time_str = clock.get_formatted_time()
	return Transaction.new(type, amount, description, day, time_str)
