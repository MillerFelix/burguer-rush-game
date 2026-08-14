class_name DeliveryStation
extends StaticBody3D

signal delivery_succeeded(order: Order, product_id: String)
signal delivery_failed(reason: String)

@onready var item_slot: Node3D = $ItemSlot

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var product_id: String = str(held.get("item_id")) if held.get("item_id") != null else ""
		var display_name = held.get_display_name() if held.has_method("get_display_name") else product_id.capitalize()

		var is_final = held.get("item_type") == "final_product" or product_id in ["burger", "cheeseburger"]
		if is_final:
			var order_mgr = OrderManager.get_instance()
			if order_mgr:
				var matching_order = order_mgr.find_order_matching_product(product_id)
				if matching_order:
					return "E — Entregar %s (Pedido #%03d - $%.2f)" % [display_name, matching_order.id, matching_order.total_price]
				else:
					return "Nenhum cliente aguarda %s" % display_name
			return "E — Entregar " + display_name
		else:
			return "Item incompleto (não pode ser entregue)"

	return ""

func interact(player: Node3D) -> void:
	if player.get("held_item") == null:
		return

	if not player.has_method("take_held_item"):
		return

	var held_item = player.get("held_item")
	var product_id: String = str(held_item.get("item_id")) if held_item.get("item_id") != null else ""
	var is_final = held_item.get("item_type") == "final_product" or product_id in ["burger", "cheeseburger"]

	# Apenas produtos finais podem ser entregues
	if not is_final:
		_show_player_feedback(player, "Apenas produtos prontos e montados podem ser entregues!")
		delivery_failed.emit("invalid_item")
		return

	var order_manager = OrderManager.get_instance()
	if not order_manager:
		return

	# Procura um pedido de DELIVERY ativo compatível
	var matching_order = null
	for order in order_manager.get_active_orders():
		if order.source_type == "DELIVERY" and (order.state == Order.State.WAITING or order.state == Order.State.IN_PROGRESS) and order.has_pending_product(product_id):
			matching_order = order
			break

	if matching_order == null:
		var name_str = held_item.get_display_name() if held_item.has_method("get_display_name") else product_id.capitalize()
		_show_player_feedback(player, "Nenhum pedido de delivery aguarda %s! (Entregue pedidos presenciais nas mesas)" % name_str)
		delivery_failed.emit("no_matching_order")
		return

	# Pedido compatível encontrado: consome o produto das mãos do jogador
	var item: Node3D = player.take_held_item()
	if not item:
		return

	# Efetua pagamento
	var economy = EconomyManager.get_instance()
	if economy:
		economy.add_money(matching_order.total_price, "Venda: %s" % matching_order.items[0].get("product_name", product_id))

	# Notifica o cliente
	if matching_order.customer_ref and is_instance_valid(matching_order.customer_ref):
		if matching_order.customer_ref.has_method("receive_order"):
			matching_order.customer_ref.receive_order(product_id)

	# Finaliza o pedido
	order_manager.complete_order(matching_order)

	# Libera o nó do item entregue
	item.queue_free()

	_show_player_feedback(player, "Pedido #%03d entregue com sucesso! +$%.2f" % [matching_order.id, matching_order.total_price])
	delivery_succeeded.emit(matching_order, product_id)

func _show_player_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
