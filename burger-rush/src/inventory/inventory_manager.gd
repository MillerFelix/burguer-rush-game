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
	items.clear()

	# =========================================================================
	# 1. PADARIA (BAKERY)
	# =========================================================================
	_register_item("bread_bottom", "Base do Pão", "bakery", 20, 60, 1.0, 5, load("res://src/items/bread_bottom.tscn"))
	_register_item("bread_top", "Tampa do Pão", "bakery", 20, 60, 1.0, 5, load("res://src/items/bread_top.tscn"))

	# =========================================================================
	# 2. CARNES (MEATS)
	# =========================================================================
	_register_item("patty_beef", "Hambúrguer de Carne", "meats", 20, 60, 5.0, 5, load("res://src/items/patty.tscn"))
	_register_item("patty_chicken", "Hambúrguer de Frango", "meats", 15, 50, 4.5, 5, load("res://src/items/patty.tscn"))

	# =========================================================================
	# 3. QUEIJOS (CHEESES) - INGREDIENTES INDIVIDUAIS
	# =========================================================================
	_register_item("cheese_mozzarella", "Queijo Muçarela", "cheeses", 15, 50, 2.0, 5, load("res://src/items/cheese.tscn"))
	_register_item("cheese_cheddar", "Queijo Cheddar", "cheeses", 20, 60, 2.2, 5, load("res://src/items/cheese.tscn"))
	_register_item("cheese_prato", "Queijo Prato", "cheeses", 15, 50, 2.0, 5, load("res://src/items/cheese.tscn"))

	# =========================================================================
	# 4. VERDURAS E VEGETAIS (VEGETABLES)
	# =========================================================================
	_register_item("lettuce", "Alface", "vegetables", 15, 50, 1.5, 5, load("res://src/items/lettuce.tscn"))
	_register_item("tomato", "Tomate", "vegetables", 15, 50, 1.5, 5, load("res://src/items/tomato.tscn"))
	_register_item("red_onion", "Cebola Roxa", "vegetables", 15, 50, 1.2, 5, load("res://src/items/onion.tscn"))
	_register_item("onion", "Cebola Comum", "vegetables", 15, 50, 1.0, 5, load("res://src/items/onion.tscn"))
	_register_item("pickle", "Picles", "vegetables", 15, 50, 1.5, 5, load("res://src/items/pickle.tscn"))

	# =========================================================================
	# 5. EXTRAS & INSUMOS
	# =========================================================================
	_register_item("bacon", "Bacon", "extras", 15, 50, 3.0, 5, load("res://src/items/bacon.tscn"))
	_register_item("egg", "Ovo", "extras", 15, 50, 1.5, 5, load("res://src/items/egg.tscn"))
	_register_item("potato_raw", "Saco de Batata", "vegetables", 25, 80, 20.0, 5, load("res://src/items/potato.tscn"))
	_register_item("onion_rings_raw", "Saco de Cebola", "vegetables", 25, 80, 15.0, 5, load("res://src/items/onion_bag.tscn"))

	# =========================================================================
	# 6. EMBALAGENS E ACOMPANHAMENTOS (SUPPLIES)
	# =========================================================================
	_register_item("burger_box", "Caixa de Lanche", "supplies", 50, 50, 0.5, 10, load("res://src/items/burger_box.tscn"))
	_register_item("potato_box", "Embalagem de Batata", "supplies", 50, 50, 0.3, 10, load("res://src/items/potato_box.tscn"))
	_register_item("cup_empty", "Copo", "supplies", 50, 50, 0.2, 10, load("res://src/items/drink_cup.tscn"))
	_register_item("delivery_bag", "Saco de Delivery", "supplies", 50, 50, 0.4, 10, load("res://src/items/delivery_bag.tscn"))

	# =========================================================================
	# 8. BEBIDAS: CILINDROS RESERVA DE REFRIGERANTE (MÁXIMO 1 UNIDADE RESERVA CADA)
	# =========================================================================
	_register_item("cylinder_cola", "Cilindro Cola", "beverages", 1, 1, 80.0, 0, null)
	_register_item("cylinder_cola_zero", "Cilindro Cola Zero", "beverages", 1, 1, 80.0, 0, null)
	_register_item("cylinder_soda", "Cilindro Soda", "beverages", 1, 1, 80.0, 0, null)
	_register_item("cylinder_citrus", "Cilindro Citrus", "beverages", 1, 1, 80.0, 0, null)

	# =========================================================================
	# 9. BEBIDAS: POLPAS DE FRUTA CONGELADA (FROZEN PULP)
	# =========================================================================
	_register_item("pulp_orange", "Polpa de Laranja", "beverages", 10, 10, 15.0, 3, load("res://src/items/juice_pulp.tscn"))
	_register_item("pulp_grape", "Polpa de Uva", "beverages", 10, 10, 15.0, 3, load("res://src/items/juice_pulp.tscn"))
	_register_item("pulp_strawberry", "Polpa de Morango", "beverages", 10, 10, 15.0, 3, load("res://src/items/juice_pulp.tscn"))

func _register_item(
	id: String,
	display_name: String,
	category: String,
	initial_quantity: int,
	max_capacity: int,
	unit_cost: float,
	reorder_level: int,
	item_scene: PackedScene = null
) -> void:
	items[id] = {
		"id": id,
		"display_name": display_name,
		"category": category,
		"quantity": initial_quantity,
		"max_capacity": max_capacity,
		"unit_cost": unit_cost,
		"reorder_level": reorder_level,
		"scene": item_scene
	}

func _resolve_item_id(item_id: String) -> String:
	match item_id:
		"bread":
			return "bread_bottom"
		"patty", "meat", "beef":
			return "patty_beef"
		"cheese":
			return "cheese_cheddar"
		"sauce", "ketchup":
			return "sauce_ketchup"
		"mustard":
			return "sauce_mustard"
		"mayo":
			return "sauce_mayo"
		"special_sauce":
			return "sauce_special"
		"drink_cup", "cup":
			return "cup_empty"
		"french_fries_box", "fries_box":
			return "potato_box"
		"french_fries_bag", "fries_bag", "potato_bag", "potato":
			return "potato_raw"
		"bag":
			return "delivery_bag"
		"syrup_cola", "cola_syrup", "cola_cylinder", "cylinder_cola", "cola":
			return "cylinder_cola"
		"syrup_cola_zero", "cola_zero_syrup", "cola_zero_cylinder", "cylinder_cola_zero", "cola_zero":
			return "cylinder_cola_zero"
		"syrup_lemon", "syrup_soda", "soda_syrup", "soda_cylinder", "cylinder_soda", "soda":
			return "cylinder_soda"
		"syrup_orange", "citrus_syrup", "citrus_cylinder", "cylinder_citrus", "citrus":
			return "cylinder_citrus"
		_:
			return item_id

func get_stock(item_id: String) -> int:
	var real_id = _resolve_item_id(item_id)
	if items.has(real_id):
		return items[real_id]["quantity"]
	return 0

func get_max_capacity(item_id: String) -> int:
	var real_id = _resolve_item_id(item_id)
	if items.has(real_id):
		return items[real_id]["max_capacity"]
	return 0

func has_stock(item_id: String, amount: int = 1) -> bool:
	return get_stock(item_id) >= amount

func add_stock(item_id: String, amount: int) -> bool:
	var real_id = _resolve_item_id(item_id)
	if not items.has(real_id) or amount <= 0:
		return false

	var current = items[real_id]["quantity"]
	var max_cap = items[real_id]["max_capacity"]
	var new_qty = mini(current + amount, max_cap)
	items[real_id]["quantity"] = new_qty
	stock_changed.emit(real_id, new_qty)
	return true

func consume_stock(item_id: String, amount: int = 1) -> bool:
	var real_id = _resolve_item_id(item_id)
	if not items.has(real_id) or amount <= 0:
		return false

	var current = items[real_id]["quantity"]
	if current < amount:
		return false

	items[real_id]["quantity"] = current - amount
	stock_changed.emit(real_id, items[real_id]["quantity"])
	return true

# Consome do estoque todos os ingredientes exatos requeridos por uma receita
func consume_recipe_ingredients(recipe_id: String) -> bool:
	var recipe = RecipeDatabase.get_recipe_by_id(recipe_id)
	if not recipe:
		return false

	var raw_counts = recipe.get_raw_ingredient_consumption()

	# 1. Verifica se há estoque suficiente para TODOS os ingredientes
	for ing_id in raw_counts.keys():
		var required_qty = raw_counts[ing_id] as int
		if not has_stock(ing_id, required_qty):
			return false

	# 2. Desconta as quantidades exatas
	for ing_id in raw_counts.keys():
		var required_qty = raw_counts[ing_id] as int
		consume_stock(ing_id, required_qty)

	return true

func can_craft_recipe(recipe_id: String) -> bool:
	var recipe = RecipeDatabase.get_recipe_by_id(recipe_id)
	if not recipe:
		return false

	var raw_counts = recipe.get_raw_ingredient_consumption()
	for ing_id in raw_counts.keys():
		var required_qty = raw_counts[ing_id] as int
		if not has_stock(ing_id, required_qty):
			return false
	return true

func is_low_stock(item_id: String) -> bool:
	var real_id = _resolve_item_id(item_id)
	if not items.has(real_id):
		return false
	return items[real_id]["quantity"] <= items[real_id]["reorder_level"]

func get_unit_cost(item_id: String) -> float:
	var real_id = _resolve_item_id(item_id)
	if items.has(real_id):
		return items[real_id]["unit_cost"]
	return 0.0

func get_item_data(item_id: String) -> Dictionary:
	var real_id = _resolve_item_id(item_id)
	if items.has(real_id):
		return items[real_id]
	return {}

func get_item(item_id: String):
	var real_id = _resolve_item_id(item_id)
	if items.has(real_id):
		return items[real_id]
	return null

func get_items_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for k in items.keys():
		if items[k].get("category") == category:
			result.append(items[k])
	return result

func get_all_items() -> Dictionary:
	return items

func get_low_stock_alerts() -> Array[String]:
	var alerts: Array[String] = []
	for id in items.keys():
		var item = items[id]
		var qty: int = item.get("quantity", 0)
		var reorder: int = item.get("reorder_level", 5)
		if qty <= reorder:
			alerts.append(item.get("display_name", id))
	return alerts
