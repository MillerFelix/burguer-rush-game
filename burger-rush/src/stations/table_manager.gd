class_name TableManager
extends Node

static var instance: TableManager = null

var tables: Array[RestaurantTable] = []

func _enter_tree() -> void:
	instance = self

static func get_instance() -> TableManager:
	return instance

func register_table(table: RestaurantTable) -> void:
	if not tables.has(table):
		tables.append(table)

func unregister_table(table: RestaurantTable) -> void:
	tables.erase(table)

func get_available_table() -> RestaurantTable:
	return get_available_table_for_group(1)

func get_available_table_for_group(group_size: int) -> RestaurantTable:
	var best_fit: RestaurantTable = null
	var min_excess_seats = 999

	for t in tables:
		if is_instance_valid(t) and t.is_available():
			if t.seat_count >= group_size:
				var excess = t.seat_count - group_size
				if excess >= 0 and excess < min_excess_seats:
					min_excess_seats = excess
					best_fit = t

	if not best_fit:
		# Fallback para qualquer mesa livre
		for t in tables:
			if is_instance_valid(t) and t.is_available():
				return t

	return best_fit

func get_table_by_id(id: int) -> RestaurantTable:
	for t in tables:
		if is_instance_valid(t) and t.table_id == id:
			return t
	return null

func get_all_tables() -> Array[RestaurantTable]:
	return tables

func get_available_table_count() -> int:
	var count = 0
	for t in tables:
		if is_instance_valid(t) and t.is_available():
			count += 1
	return count

func get_total_seat_capacity() -> int:
	var total = 0
	for t in tables:
		if is_instance_valid(t):
			total += t.seat_count
	return total

func get_total_available_seats() -> int:
	var count = 0
	for t in tables:
		if is_instance_valid(t) and t.is_available():
			count += t.seat_count
	return count
