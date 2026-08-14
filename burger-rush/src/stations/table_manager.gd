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
	for t in tables:
		if is_instance_valid(t) and t.is_available():
			return t
	return null

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
