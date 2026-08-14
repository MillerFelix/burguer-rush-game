class_name InventoryManager
extends Node

signal stock_changed(item_id: String, new_quantity: int)

static var instance: InventoryManager = null

var items: Dictionary = {}

func _init() -> void:
	if instance == null:
		instance = self

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if items.is_empty():
		_initialize_default_inventory()

static func get_instance() -> InventoryManager:
	return instance

func _initialize_default_inventory() -> void:
	# 1. Pão (Base e Tampa)
	_register_item("bread", "Pão Brioche", 15, 50, 2.0, 5, load("res://src/items/bread.tscn"))
	_register_item("bread_bottom", "Base do Pão", 15, 50, 1.0, 5, load("res://src/items/bread_bottom.tscn"))
	_register_item("bread_top", "Tampa do Pão", 15, 50, 1.0, 5, load("res://src/items/bread_top.tscn"))

	# 2. Carne
	_register_item("patty", "Carne", 10, 50, 5.0, 5, load("res://src/items/patty.tscn"))

	# 3. Queijo
	_register_item("cheese", "Queijo", 10, 50, 2.0, 5, load("res://src/items/cheese.tscn"))

	# 4. Alface
	_register_item("lettuce", "Alface", 10, 50, 1.5, 5, load("res://src/items/lettuce.tscn"))

	# 5. Tomate
	_register_item("tomato", "Tomate", 10, 50, 1.5, 5, load("res://src/items/tomato.tscn"))

	# 6. Cebola
	_register_item("onion", "Cebola", 10, 50, 1.0, 5, load("res://src/items/onion.tscn"))

	# 7. Bacon
	_register_item("bacon", "Bacon", 10, 50, 3.0, 5, load("res://src/items/bacon.tscn"))

	# 8. Molho Ketchup
	_register_item("sauce", "Molho Ketchup", 50, 200, 1.0, 5, load("res://src/items/sauce.tscn"))

	# 9. Embalagem: Caixa de Hambúrguer
	_register_item("burger_box", "Caixa de Hambúrguer", 15, 50, 0.5, 5, load("res://src/items/burger_box.tscn"))

	# 10. Batata Crua
	_register_item("potato_raw", "Batata Crua", 15, 50, 1.0, 5, load("res://src/items/potato.tscn"))

	# 11. Embalagem de Batata
	_register_item("potato_box", "Recipiente de Batata", 15, 50, 0.3, 5, load("res://src/items/potato_box_item.tscn"))

	# 12. Copo Descartável
	_register_item("cup_empty", "Copo Descartável", 25, 100, 0.2, 5, load("res://src/items/drink_cup.tscn"))

	# 13. Tampa de Copo
	_register_item("cup_lid", "Tampa de Copo", 25, 100, 0.1, 5, null)

	# 14. Xarope de Refrigerante
	_register_item("syrup_soda", "Xarope de Refrigerante", 25, 100, 0.5, 5, load("res://src/items/soda_syrup_bottle.tscn"))

	# 15. Galão de Óleo de Cozinha
	_register_item("cooking_oil", "Galão de Óleo", 5, 20, 4.0, 2, load("res://src/items/cooking_oil.tscn"))

func _register_item(
	id: String,
	display_name: String,
	initial_quantity: int,
	max_capacity: int,
	unit_cost: float,
	reorder_level: int,
	item_scene: PackedScene = null
) -> void:
	items[id] = {
		"id": id,
		"display_name": display_name,
		"quantity": initial_quantity,
		"max_capacity": max_capacity,
		"unit_cost": unit_cost,
		"reorder_level": reorder_level,
		"scene": item_scene
	}

func get_stock(item_id: String) -> int:
	if items.has(item_id):
		return items[item_id]["quantity"]
	return 0

func get_max_capacity(item_id: String) -> int:
	if items.has(item_id):
		return items[item_id]["max_capacity"]
	return 0

func has_stock(item_id: String, amount: int = 1) -> bool:
	return get_stock(item_id) >= amount

func add_stock(item_id: String, amount: int) -> bool:
	if not items.has(item_id) or amount <= 0:
		return false

	var current = items[item_id]["quantity"]
	var max_cap = items[item_id]["max_capacity"]
	var new_qty = mini(current + amount, max_cap)
	items[item_id]["quantity"] = new_qty
	stock_changed.emit(item_id, new_qty)
	return true

func consume_stock(item_id: String, amount: int = 1) -> bool:
	if not items.has(item_id) or amount <= 0:
		return false

	var current = items[item_id]["quantity"]
	if current < amount:
		return false

	items[item_id]["quantity"] = current - amount
	stock_changed.emit(item_id, items[item_id]["quantity"])
	return true

func is_low_stock(item_id: String) -> bool:
	if not items.has(item_id):
		return false
	return items[item_id]["quantity"] <= items[item_id]["reorder_level"]

func get_unit_cost(item_id: String) -> float:
	if items.has(item_id):
		return items[item_id]["unit_cost"]
	return 0.0

func get_item_data(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}

func get_item(item_id: String):
	if items.has(item_id):
		return items[item_id]
	return null

func get_all_items() -> Dictionary:
	return items
