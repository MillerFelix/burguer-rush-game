class_name WasteManager
extends Node

signal waste_registered(item_name: String, amount: float, reason: String)

static var instance: WasteManager = null

var daily_waste_cost: float = 0.0
var total_waste_cost: float = 0.0
var waste_records: Array[Dictionary] = []

func _enter_tree() -> void:
	instance = self

static func get_instance() -> WasteManager:
	return instance

func register_waste(item_id: String, item_name: String, quantity: int, unit_cost: float, reason: String) -> void:
	var cost = quantity * unit_cost
	daily_waste_cost += cost
	total_waste_cost += cost

	var clock = GameClock.get_instance()
	var day = clock.day_number if clock else 1
	var time_str = clock.get_formatted_time() if clock else "00:00"

	var record = {
		"day": day,
		"time": time_str,
		"item_id": item_id,
		"item_name": item_name,
		"quantity": quantity,
		"unit_cost": unit_cost,
		"total_cost": cost,
		"reason": reason
	}
	waste_records.append(record)

	# Registra também no EconomyManager como despesa de desperdício
	var economy = EconomyManager.get_instance()
	if economy:
		var t = Transaction.new()
		t.type = Transaction.Type.PURCHASE
		t.amount = cost
		t.description = "Desperdício: %s (%s)" % [item_name, reason]
		t.day = day
		t.time_string = time_str
		economy.transactions.append(t)

	waste_registered.emit(item_name, cost, reason)

func get_daily_waste_cost() -> float:
	return daily_waste_cost

func get_waste_records() -> Array[Dictionary]:
	return waste_records

func start_new_day() -> void:
	daily_waste_cost = 0.0
