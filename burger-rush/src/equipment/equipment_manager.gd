class_name EquipmentManager
extends Node

signal equipment_purchased(equipment_id: String)

static var instance: EquipmentManager = null

var available_equipment: Dictionary = {}
var installed_equipment: Array[String] = []

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if available_equipment.is_empty():
		_initialize_equipment_catalog()

static func get_instance() -> EquipmentManager:
	return instance

func _initialize_equipment_catalog() -> void:
	# 1. Segunda Chapa
	register_equipment("second_grill", "Segunda Chapa (Grill 2)", 150.0, 3, "cooking", "res://src/stations/grill.tscn")

	# 2. Segunda Fritadeira
	register_equipment("second_fryer", "Segunda Fritadeira Elétrica", 200.0, 2, "cooking", "res://src/stations/fryer.tscn")

	# 3. Máquina de Bebidas / Refrigerante
	register_equipment("drink_machine", "Máquina de Refrigerante", 250.0, 1, "drinks", "res://src/stations/drink_machine.tscn")

	# 4. Refrigerador Maior (+20 Capacidade de Estoque)
	register_equipment("large_fridge", "Refrigerador Industrial (+20 Espaço)", 250.0, 5, "storage", "")

	# 5. Bancada de Preparação Estendida
	register_equipment("extra_prep_table", "Segunda Mesa de Montagem", 120.0, 2, "prep", "res://src/stations/prep_table.tscn")

func register_equipment(id: String, display_name: String, cost: float, unlock_day: int, category: String, scene_path: String) -> void:
	available_equipment[id] = {
		"id": id,
		"name": display_name,
		"cost": cost,
		"unlock_day": unlock_day,
		"category": category,
		"scene_path": scene_path,
		"installed": false
	}

func is_installed(equipment_id: String) -> bool:
	return installed_equipment.has(equipment_id)

func can_purchase(equipment_id: String) -> Dictionary:
	var equip = available_equipment.get(equipment_id, null)
	if not equip:
		return {"success": false, "message": "Equipamento não cadastrado."}

	if is_installed(equipment_id):
		return {"success": false, "message": "Equipamento já instalado."}

	var economy = EconomyManager.get_instance()
	if not economy or economy.get_money() < equip.cost:
		return {"success": false, "message": "Saldo insuficiente (Necessário $%.2f)." % equip.cost}

	return {"success": true, "message": "Disponível para compra."}

func purchase_equipment(equipment_id: String) -> Dictionary:
	var check = can_purchase(equipment_id)
	if not check.get("success", false):
		return check

	var equip = available_equipment[equipment_id]
	var economy = EconomyManager.get_instance()

	if economy and economy.spend_money(equip.cost, "Equipamento: %s" % equip.name):
		installed_equipment.append(equipment_id)
		equip["installed"] = true

		# Se for upgrade de estoque (ex: refrigerador)
		if equipment_id == "large_fridge":
			var inv = InventoryManager.get_instance()
			if inv:
				for item in inv.get_all_items():
					item.max_capacity += 20

		equipment_purchased.emit(equipment_id)
		return {"success": true, "message": "Equipamento %s adquirido com sucesso!" % equip.name}

	return {"success": false, "message": "Falha na transação financeira."}

func get_all_equipment() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for key in available_equipment:
		var item = available_equipment[key].duplicate()
		item["installed"] = is_installed(key)
		list.append(item)
	return list
