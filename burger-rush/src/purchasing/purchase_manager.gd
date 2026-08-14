class_name PurchaseManager
extends Node

static var instance: PurchaseManager = null

func _enter_tree() -> void:
	instance = self

static func get_instance() -> PurchaseManager:
	return instance

func buy_ingredient(item_id: String, amount: int) -> Dictionary:
	if amount <= 0:
		return {"success": false, "message": "Quantidade deve ser maior que zero!", "cost": 0.0, "amount_bought": 0}

	var inv = InventoryManager.get_instance()
	if not inv:
		return {"success": false, "message": "Estoque não disponível!", "cost": 0.0, "amount_bought": 0}

	var item = inv.get_item(item_id)
	if not item:
		return {"success": false, "message": "Ingrediente inexistente!", "cost": 0.0, "amount_bought": 0}

	var available_space = item.get_available_space()
	if available_space <= 0:
		return {"success": false, "message": "Estoque de %s está cheio (máx: %d)!" % [item.display_name, item.max_capacity], "cost": 0.0, "amount_bought": 0}

	var to_buy = mini(amount, available_space)
	var total_cost = to_buy * item.unit_cost

	var economy = EconomyManager.get_instance()
	if not economy:
		return {"success": false, "message": "Caixa não disponível!", "cost": 0.0, "amount_bought": 0}

	if economy.get_money() < total_cost:
		return {"success": false, "message": "Dinheiro insuficiente! Necessário: $%.2f" % total_cost, "cost": total_cost, "amount_bought": 0}

	if not economy.spend_money(total_cost, "Compra: %dx %s" % [to_buy, item.display_name]):
		return {"success": false, "message": "Falha ao processar pagamento!", "cost": total_cost, "amount_bought": 0}

	var recv = ReceivingArea.get_instance()
	if recv:
		recv.add_pending_delivery(item_id, item.display_name, to_buy)
		return {
			"success": true,
			"message": "Compra realizada: %dx %s entregues na Área de Recebimento!" % [to_buy, item.display_name],
			"cost": total_cost,
			"amount_bought": to_buy
		}
	else:
		var added = inv.add_stock(item_id, to_buy)
		return {
			"success": true,
			"message": "Compra realizada: %dx %s por $%.2f" % [added, item.display_name, total_cost],
			"cost": total_cost,
			"amount_bought": added
		}
