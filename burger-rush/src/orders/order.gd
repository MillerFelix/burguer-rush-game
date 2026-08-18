class_name Order
extends RefCounted

enum State {
	RECEIVED,
	WAITING,
	IN_PROGRESS,
	READY,
	DELIVERED,
	COMPLETED,
	CANCELLED,
	NOT_ACCEPTED
}

var id: int = 1
var items: Array[Dictionary] = []
var state: State = State.RECEIVED
var total_price: float = 0.0
var created_time: float = 0.0
var wait_time: float = 0.0
var customer_ref: Node = null
var table_id: int = 0
var group_size: int = 1
var source_type: String = "DINE_IN" # DINE_IN, DRIVE_THRU ou DELIVERY

# Campos específicos de Delivery e Fechamento
var is_accepted: bool = false
var delivery_stage: String = "NEW_RECEIVED" # NEW_RECEIVED, PREPARING, WAITING_COURIER, IN_DELIVERY, COMPLETED_PAID, COMPLETED_WRONG, CANCELLED, NOT_ACCEPTED
var delivery_accept_timeout: float = 60.0
var delivery_accept_timer: float = 60.0
var prep_elapsed_time: float = 0.0
var elapsed_time: float = 0.0
var is_paid: bool = false
var payment_amount: float = 0.0
var is_wrong_delivery: bool = false
var created_clock_time: String = "12:00"
var result_status_text: String = ""

func add_item(product_id: String, product_name: String, quantity: int, unit_price: float) -> void:
	# Agrupa itens idênticos para exibição limpa (ex: 2x Cheeseburger)
	for item in items:
		if item.get("product_id") == product_id and is_equal_approx(item.get("unit_price", 0.0), unit_price):
			item["quantity"] = item.get("quantity", 1) + quantity
			total_price += unit_price * quantity
			return

	items.append({
		"product_id": product_id,
		"product_name": product_name,
		"quantity": quantity,
		"delivered_quantity": 0,
		"unit_price": unit_price
	})
	total_price += unit_price * quantity

func matches_product(product_id: String) -> bool:
	for item in items:
		if item.get("product_id") == product_id:
			return true
	return false

func has_pending_product(product_id: String) -> bool:
	for item in items:
		if item.get("product_id") == product_id:
			var qty = item.get("quantity", 1)
			var deliv = item.get("delivered_quantity", 0)
			if deliv < qty:
				return true
	return false

func register_product_delivered(product_id: String) -> bool:
	for item in items:
		if item.get("product_id") == product_id:
			var qty = item.get("quantity", 1)
			var deliv = item.get("delivered_quantity", 0)
			if deliv < qty:
				item["delivered_quantity"] = deliv + 1
				if is_all_delivered():
					state = State.DELIVERED
				else:
					state = State.IN_PROGRESS
				return true
	return false

func mark_product_delivered(product_id: String) -> bool:
	return register_product_delivered(product_id)

func is_all_delivered() -> bool:
	for item in items:
		var qty = item.get("quantity", 1)
		var deliv = item.get("delivered_quantity", 0)
		if deliv < qty:
			return false
	return true

func is_fully_delivered() -> bool:
	return is_all_delivered()

func get_total_quantity() -> int:
	var count = 0
	for item in items:
		count += item.get("quantity", 1)
	return count

func get_delivered_count() -> int:
	var count = 0
	for item in items:
		count += item.get("delivered_quantity", 0)
	return count

func get_formatted_wait_time() -> String:
	var total_sec = int(wait_time)
	var m = total_sec / 60
	var s = total_sec % 60
	return "%02d:%02d" % [m, s]

func get_source_display_name() -> String:
	match source_type.to_upper():
		"DINE_IN", "RESTAURANT":
			return "🍽️ Restaurante (Mesa #%d)" % table_id if table_id > 0 else "🍽️ Restaurante (Balcão)"
		"DRIVE_THRU", "DRIVETHRU":
			return "🚗 Drive-Thru"
		"DELIVERY":
			return "🛵 Delivery"
		_:
			return "📋 %s" % source_type.capitalize()

func get_state_string() -> String:
	if source_type.to_upper() == "DELIVERY":
		match delivery_stage:
			"NEW_RECEIVED":
				return "Novo Pedido (Pendente de Aceite)"
			"PREPARING":
				return "Em Preparo"
			"WAITING_COURIER", "WAITING_PICKUP", "READY":
				return "Aguardando Retirada"
			"IN_DELIVERY":
				return "Em Entrega"
			"COMPLETED_PAID":
				return "Finalizado — Pago"
			"COMPLETED_WRONG":
				return "Entregue Incorretamente"
			"CANCELLED":
				return "Cancelado"

	match state:
		State.RECEIVED:
			return "Recebido"
		State.WAITING:
			return "Aguardando"
		State.IN_PROGRESS:
			return "Em Preparo (%d/%d)" % [get_delivered_count(), get_total_quantity()]
		State.READY:
			return "Pronto"
		State.DELIVERED:
			return "Entregue"
		State.COMPLETED:
			return "Concluído"
		State.CANCELLED:
			return "Cancelado"
		_:
			return "Desconhecido"

func get_summary_text() -> String:
	var tag = get_source_display_name()
	var text = "PEDIDO #%03d — %s\n" % [id, tag]
	for item in items:
		var qty = item.get("quantity", 1)
		var deliv = item.get("delivered_quantity", 0)
		var icon = "✓" if deliv >= qty else "⏳"
		text += "%s %dx %s (%d/%d)\n" % [icon, qty, item.get("product_name", "Produto"), deliv, qty]
	text += "Total: R$ %.2f | Status: %s" % [total_price, get_state_string()]
	return text

## Valida se o saco de delivery contém rigorosamente os itens do pedido
func matches_delivery_bag(bag: Node) -> Dictionary:
	if not bag or not bag.has_method("get_products"):
		return {"matches": false, "reason": "Saco de delivery inválido ou vazio"}

	var bag_products: Array = bag.get_products()
	if bag_products.is_empty():
		return {"matches": false, "reason": "Saco de delivery vazio"}

	# Clona a lista de itens esperados com quantidades restantes
	var expected_counts: Dictionary = {}
	for item in items:
		var p_id = str(item.get("product_id", ""))
		expected_counts[p_id] = expected_counts.get(p_id, 0) + item.get("quantity", 1)

	var bag_counts: Dictionary = {}
	for prod in bag_products:
		var prod_id = str(prod.get("id", ""))
		var rec_id = str(prod.get("recipe_id", ""))

		var matched_key = ""
		# 1. Correspondência exata por recipe_id ou product_id
		if rec_id != "" and expected_counts.has(rec_id) and expected_counts[rec_id] > 0:
			matched_key = rec_id
		elif expected_counts.has(prod_id) and expected_counts[prod_id] > 0:
			matched_key = prod_id
		elif prod_id.begins_with("soda_") or prod_id.begins_with("juice_"):
			# Bebidas específicas
			if expected_counts.has(prod_id) and expected_counts[prod_id] > 0:
				matched_key = prod_id
			elif expected_counts.has("drink_cup") and expected_counts["drink_cup"] > 0:
				matched_key = "drink_cup"
		elif prod_id in ["fries_pack", "potato_box", "fries"]:
			if expected_counts.has("fries") and expected_counts["fries"] > 0:
				matched_key = "fries"
			elif expected_counts.has("fries_pack") and expected_counts["fries_pack"] > 0:
				matched_key = "fries_pack"
		elif prod_id in ["onion_rings", "fried_onions"]:
			if expected_counts.has("onion_rings") and expected_counts["onion_rings"] > 0:
				matched_key = "onion_rings"

		if matched_key != "":
			bag_counts[matched_key] = bag_counts.get(matched_key, 0) + 1
		else:
			# Item incorreto ou não solicitado pelo cliente
			var err_name = prod.get("name", prod_id)
			bag_counts["_unexpected_" + str(err_name)] = bag_counts.get("_unexpected_" + str(err_name), 0) + 1

	# Verifica se todas as quantidades bateram perfeitamente
	for req_id in expected_counts.keys():
		var req_qty = expected_counts[req_id]
		var got_qty = bag_counts.get(req_id, 0)
		if got_qty < req_qty:
			return {
				"matches": false,
				"reason": "Itens faltantes no pedido de delivery (Esperava %d de %s, recebeu %d)" % [req_qty, req_id, got_qty]
			}

	# Verifica se não há itens excedentes ou incorretos
	for bag_key in bag_counts.keys():
		if bag_key.begins_with("_unexpected_"):
			return {
				"matches": false,
				"reason": "Item incorreto colocado no saco: %s" % bag_key.replace("_unexpected_", "")
			}
		if bag_counts[bag_key] > expected_counts.get(bag_key, 0):
			return {
				"matches": false,
				"reason": "Quantidade excedente no saco para %s" % bag_key
			}

	return {"matches": true, "reason": "Pedido completo e correto!"}

