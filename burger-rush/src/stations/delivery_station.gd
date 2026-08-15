class_name DeliveryStation
extends StaticBody3D

signal delivery_succeeded(order: Order, product_id: String)
signal delivery_failed(reason: String)

@onready var item_slot: Node3D = $ItemSlot

func get_interaction_prompt(player: Node = null) -> String:
	# 1. Se o jogador está segurando um item pronto para entrega
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var product_id: String = str(held.get("item_id")) if held.get("item_id") != null else ""
		var display_name = held.get_display_name() if held.has_method("get_display_name") else product_id.capitalize()

		var is_final = held.get("item_type") == "final_product" or product_id in ["burger", "cheeseburger"] or "burger" in product_id or "drink" in product_id or product_id == "fries"
		if is_final:
			var order_mgr = OrderManager.get_instance()
			if order_mgr:
				var matching_order = null
				for order in order_mgr.get_active_orders():
					if order.source_type == "DELIVERY" and (order.state == Order.State.WAITING or order.state == Order.State.IN_PROGRESS) and order.has_pending_product(product_id):
						matching_order = order
						break
				if matching_order:
					return "E — Entregar %s (Drive-Thru #%03d - $%.2f)" % [display_name, matching_order.id, matching_order.total_price]
				else:
					return "Nenhum pedido do drive-thru aguarda %s" % display_name
			return "E — Entregar " + display_name
		else:
			return "Item incompleto (não pode ser entregue)"

	# 2. Se o jogador está de mãos livres, verifica se há um carro na janela esperando para fazer pedido
	var deliv_mgr = null
	if is_inside_tree() and get_tree() and get_tree().root:
		deliv_mgr = get_tree().root.find_child("DeliveryQueueManager", true, false)

	if deliv_mgr and deliv_mgr.has_method("get_car_at_window"):
		var car = deliv_mgr.get_car_at_window()
		if car and car.get("current_state") == 3: # AT_WINDOW_WAITING_ORDER
			var cid = car.get("car_id")
			return "[E] Atender Pedido (Drive-Thru Carro #%s)" % str(cid)
		elif car and car.get("current_state") == 4: # AT_WINDOW_WAITING_FOOD
			var cid = car.get("car_id")
			return "Carro #%s aguardando entrega dos produtos..." % str(cid)

	return ""

func interact(player: Node3D) -> void:
	# Caso 1: Jogador sem item -> Atender pedido do carro que está na janela
	if player.get("held_item") == null:
		var deliv_mgr = null
		if is_inside_tree() and get_tree() and get_tree().root:
			deliv_mgr = get_tree().root.find_child("DeliveryQueueManager", true, false)
		if deliv_mgr and deliv_mgr.has_method("get_car_at_window"):
			var car = deliv_mgr.get_car_at_window()
			if car and car.get("current_state") == 3: # AT_WINDOW_WAITING_ORDER
				if car.has_method("take_order"):
					car.take_order(player)
				return
		return

	# Caso 2: Jogador segurando item -> Entregar produto
	if not player.has_method("take_held_item"):
		return

	var held_item = player.get("held_item")
	var product_id: String = str(held_item.get("item_id")) if held_item.get("item_id") != null else ""
	var is_final = held_item.get("item_type") == "final_product" or product_id in ["burger", "cheeseburger"] or "burger" in product_id or "drink" in product_id or product_id == "fries"

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
		_show_player_feedback(player, "Nenhum pedido do drive-thru aguarda %s! (Entregue pedidos presenciais nas mesas)" % name_str)
		delivery_failed.emit("no_matching_order")
		return

	# Pedido compatível encontrado: consome o produto das mãos do jogador
	var item: Node3D = player.take_held_item()
	if not item:
		return

	# Registra a entrega do item no pedido
	matching_order.register_product_delivered(product_id)

	# Se todos os itens do pedido foram entregues, completa e paga
	if matching_order.is_all_delivered():
		var economy = EconomyManager.get_instance()
		if economy:
			economy.add_money(matching_order.total_price, "Drive-Thru: %s" % matching_order.items[0].get("product_name", product_id))

		if matching_order.customer_ref and is_instance_valid(matching_order.customer_ref):
			if matching_order.customer_ref.has_method("receive_order"):
				matching_order.customer_ref.receive_order(product_id)

		order_manager.complete_order(matching_order)
		_show_player_feedback(player, "Pedido #%03d entregue com sucesso! +$%.2f" % [matching_order.id, matching_order.total_price])
	else:
		_show_player_feedback(player, "Item %s entregue! Faltam %d itens." % [product_id.capitalize(), matching_order.get_total_quantity() - matching_order.get_delivered_count()])

	# Libera o nó do item entregue
	item.queue_free()
	delivery_succeeded.emit(matching_order, product_id)

func _show_player_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
