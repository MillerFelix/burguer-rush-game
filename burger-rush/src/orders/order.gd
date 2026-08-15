class_name Order
extends RefCounted

enum State {
	RECEIVED,
	WAITING,
	IN_PROGRESS,
	READY,
	DELIVERED,
	COMPLETED,
	CANCELLED
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
var source_type: String = "DINE_IN" # DINE_IN ou DELIVERY

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

func get_state_string() -> String:
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
	var table_tag = ("Mesa #%d (%d Pessoas)" % [table_id, group_size]) if table_id > 0 else "Balcão / Delivery"
	var text = "PEDIDO #%03d — %s\n" % [id, table_tag]
	for item in items:
		var qty = item.get("quantity", 1)
		var deliv = item.get("delivered_quantity", 0)
		var icon = "✓" if deliv >= qty else "⏳"
		text += "%s %dx %s (%d/%d)\n" % [icon, qty, item.get("product_name", "Produto"), deliv, qty]
	text += "Total: $%.2f | Status: %s" % [total_price, get_state_string()]
	return text
