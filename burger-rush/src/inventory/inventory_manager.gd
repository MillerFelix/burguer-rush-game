class_name InventoryManager
extends Node

signal stock_changed(item_id: String, new_quantity: int)

static var instance: InventoryManager = null

var items: Dictionary = {}

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if items.is_empty():
		_initialize_default_inventory()

static func get_instance() -> InventoryManager:
	return instance

func _initialize_default_inventory() -> void:
	# 1. Pão
	_register_item("bread", "Pão", 10, 50, 2.0, 5, load("res://src/items/bread.tscn"))

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
	_register_item("sauce", "Molho Ketchup", 10, 50, 1.0, 5, load("res://src/items/sauce.tscn"))

	# 9. Embalagem: Caixa de Hambúrguer
	_register_item("burger_box", "Caixa de Hambúrguer", 15, 50, 0.5, 5, load("res://src/items/burger_box.tscn"))

	# 10. Batata Crua
	_register_item("potato_raw", "Batata Crua", 15, 50, 1.0, 5, load("res://src/items/potato.tscn"))

	# 11. Embalagem de Batata
	_register_item("potato_box", "Recipiente de Batata", 15, 50, 0.3, 5, load("res://src/items/potato_box_item.tscn"))

	# 12. Copo Descartável
	_register_item("cup_empty", "Copo Descartável", 15, 50, 0.2, 5, load("res://src/items/drink_cup.tscn"))

	# 13. Tampa de Copo
	_register_item("cup_lid", "Tampa de Copo", 15, 50, 0.1, 5, null)

	# 14. Xarope de Refrigerante
	_register_item("syrup_soda", "Xarope de Refrigerante", 20, 50, 0.5, 5, load("res://src/items/soda_syrup_bottle.tscn"))

	# 15. Galão de Óleo de Cozinha
	_register_item("cooking_oil", "Galão de Óleo", 5, 20, 4.0, 2, load("res://src/items/cooking_oil.tscn"))

func _register_item(id: String, name_str: String, qty: int, cap: int, cost: float, min_alert: int, scn: PackedScene) -> void:
	var it = InventoryItem.new()
	it.id = id
	it.display_name = name_str
	it.quantity = qty
	it.max_capacity = cap
	it.unit_cost = cost
	it.min_stock_alert = min_alert
	it.scene = scn
	items[id] = it

func get_item(item_id: String) -> InventoryItem:
	return items.get(item_id, null)

func get_stock(item_id: String) -> int:
	var item = get_item(item_id)
	return item.quantity if item else 0

func has_stock(item_id: String, amount: int = 1) -> bool:
	return get_stock(item_id) >= amount

func consume_stock(item_id: String, amount: int = 1) -> bool:
	var item = get_item(item_id)
	if not item or item.quantity < amount:
		return false

	item.quantity -= amount
	stock_changed.emit(item_id, item.quantity)
	return true

func add_stock(item_id: String, amount: int) -> int:
	var item = get_item(item_id)
	if not item or amount <= 0:
		return 0

	var added = mini(amount, item.get_available_space())
	item.quantity += added
	stock_changed.emit(item_id, item.quantity)
	return added

func get_all_items() -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for key in items:
		result.append(items[key])
	return result

func get_low_stock_alerts() -> Array[String]:
	var alerts: Array[String] = []
	for key in items:
		var item: InventoryItem = items[key]
		if item.is_empty():
			alerts.append("Estoque de %s ESGOTADO!" % item.display_name)
		elif item.is_low_stock():
			alerts.append("Estoque de %s BAIXO (%d restantes)" % [item.display_name, item.quantity])
	return alerts

func spawn_physical_item(item_id: String) -> Node3D:
	var item = get_item(item_id)
	if not item or not item.scene:
		return null

	if not consume_stock(item_id, 1):
		return null

	return item.scene.instantiate() as Node3D
