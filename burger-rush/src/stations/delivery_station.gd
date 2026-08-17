class_name DeliveryStation
extends StaticBody3D

signal delivery_succeeded(order: Order, product_id: String)
signal delivery_failed(reason: String)

@onready var item_slot: Node3D = $ItemSlot

func get_interaction_prompt(player: Node = null) -> String:
	var deliv_mgr = null
	if is_inside_tree() and get_tree() and get_tree().root:
		deliv_mgr = get_tree().root.find_child("DeliveryQueueManager", true, false)

	var car = deliv_mgr.get_car_at_window() if (deliv_mgr and deliv_mgr.has_method("get_car_at_window")) else null

	# 1. Se o jogador está segurando um item e há um carro esperando
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var product_id: String = str(held.get("item_id")) if held.get("item_id") != null else ""
		var display_name = held.get_display_name() if held.has_method("get_display_name") else product_id.capitalize()

		if car and car.get("current_state") == 4: # AT_WINDOW_WAITING_FOOD
			return "E — Entregar %s (Drive-Thru Carro #%s)" % [display_name, str(car.get("car_id"))]
		return "E — Entregar %s" % display_name

	# 2. Se o jogador está de mãos livres, verifica se há um carro na janela esperando para fazer pedido
	if car:
		if car.get("current_state") == 3: # AT_WINDOW_WAITING_ORDER
			var cid = car.get("car_id")
			return "[E] Atender Pedido (Drive-Thru Carro #%s)" % str(cid)
		elif car.get("current_state") == 4: # AT_WINDOW_WAITING_FOOD
			var cid = car.get("car_id")
			return "Carro #%s aguardando entrega dos produtos..." % str(cid)

	return ""

func interact(player: Node3D) -> void:
	var deliv_mgr = null
	if is_inside_tree() and get_tree() and get_tree().root:
		deliv_mgr = get_tree().root.find_child("DeliveryQueueManager", true, false)

	var car = deliv_mgr.get_car_at_window() if (deliv_mgr and deliv_mgr.has_method("get_car_at_window")) else null

	# Caso 1: Jogador sem item -> Atender pedido do carro que está na janela
	if player.get("held_item") == null:
		if car and car.get("current_state") == 3: # AT_WINDOW_WAITING_ORDER
			if car.has_method("take_order"):
				car.take_order(player)
		return

	# Caso 2: Jogador segurando item -> Entregar produto no Drive-Thru
	if not player.has_method("take_held_item"):
		return

	var held_item = player.get("held_item")
	var product_id: String = str(held_item.get("item_id")) if held_item.get("item_id") != null else ""

	var item: Node3D = player.take_held_item()
	if not item:
		return

	var order_manager = OrderManager.get_instance()
	var matching_order = null

	if order_manager:
		for order in order_manager.get_active_orders():
			if order.source_type == "DELIVERY" and order.state in [Order.State.RECEIVED, Order.State.WAITING, Order.State.IN_PROGRESS]:
				if order.has_pending_product(product_id):
					matching_order = order
					break
				elif held_item.has_method("get_products"): # Saco de delivery ou bandeja
					var prods = held_item.get_products()
					var all_match = true
					for pr in prods:
						var pr_id = str(pr.get("item_id")) if pr.get("item_id") != null else ""
						if not order.has_pending_product(pr_id):
							all_match = false
							break
					if all_match and not prods.is_empty():
						matching_order = order
						break

	if matching_order != null and car != null and car.get("current_state") == 4:
		# Pedido CORRETO: registra entrega e conclui pagamento
		matching_order.register_product_delivered(product_id)

		if matching_order.is_all_delivered():
			var economy = EconomyManager.get_instance()
			if economy:
				economy.add_money(matching_order.total_price, "Drive-Thru: %s" % matching_order.items[0].get("product_name", product_id))

			if car and is_instance_valid(car) and car.has_method("receive_order"):
				car.receive_order(product_id)

			order_manager.complete_order(matching_order)
			_show_player_feedback(player, "🚗 Pedido #%03d entregue com sucesso! +$%.2f" % [matching_order.id, matching_order.total_price])
		else:
			_show_player_feedback(player, "Item %s entregue! Faltam %d itens." % [product_id.capitalize(), matching_order.get_total_quantity() - matching_order.get_delivered_count()])

		delivery_succeeded.emit(matching_order, product_id)
	else:
		# Pedido INCORRETO: cliente recebe o item, percebe o erro, reage negativamente e vai embora sem pagar
		if car and is_instance_valid(car) and car.has_method("on_order_wrong"):
			car.on_order_wrong("Pedido incorreto entregue no Drive-Thru!")
		elif car and is_instance_valid(car) and car.has_method("abandon_drive_thru"):
			car.abandon_drive_thru("Pedido incorreto entregue no Drive-Thru!")

		_show_player_feedback(player, "❌ Pedido incorreto no Drive-Thru! O cliente foi embora sem pagar.")
		delivery_failed.emit("wrong_order_delivered")

	# Limpa o item entregue
	item.queue_free()

func _show_player_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
