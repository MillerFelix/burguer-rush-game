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

func interact_item(player: Node3D) -> void:
	interact(player)

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
	var matching_order = car.current_order if (car and "current_order" in car and car.current_order != null) else null

	if not matching_order and order_manager:
		for order in order_manager.get_active_orders():
			if order.source_type == "DELIVERY" and order.state in [Order.State.RECEIVED, Order.State.WAITING, Order.State.IN_PROGRESS]:
				matching_order = order
				break

	var is_valid_delivery = false

	if matching_order != null and car != null and car.get("current_state") == 4:
		if item is DeliveryBag:
			var bag = item as DeliveryBag
			var prods = bag.get_products()
			if not prods.is_empty():
				var all_match = true
				var delivered_items: Array[String] = []

				for itm in prods:
					var p_id = str(itm.get("id", ""))
					var r_id = str(itm.get("recipe_id", ""))
					var matched_id = ""

					if matching_order.has_pending_product(p_id):
						matched_id = p_id
					elif r_id != "" and matching_order.has_pending_product(r_id):
						matched_id = r_id
					elif (p_id == "packaged_burger" or r_id != "") and matching_order.has_pending_product("burger"):
						matched_id = "burger"
					elif (p_id == "packaged_burger" or r_id != "") and matching_order.has_pending_product("cheeseburger"):
						matched_id = "cheeseburger"
					elif p_id in ["fries", "fries_pack", "potato_box"] and matching_order.has_pending_product("fries"):
						matched_id = "fries"
					elif p_id in ["onion_rings", "fried_onions"] and matching_order.has_pending_product("onion_rings"):
						matched_id = "onion_rings"
					elif p_id.begins_with("soda_") or p_id.begins_with("juice_") or p_id == "drink_cup":
						for ord_itm in matching_order.items:
							var oid = str(ord_itm.get("product_id", ""))
							if (oid.begins_with("soda_") or oid.begins_with("juice_") or oid == "drink_cup" or oid == "soda") and matching_order.has_pending_product(oid):
								matched_id = oid
								break

					if matched_id != "":
						matching_order.register_product_delivered(matched_id)
						delivered_items.append(matched_id)
					else:
						all_match = false
						break

				if all_match and not delivered_items.is_empty():
					is_valid_delivery = true
		else:
			# Entrega de item individual
			var matched_id = ""
			if matching_order.has_pending_product(product_id):
				matched_id = product_id
			elif product_id == "packaged_burger" and (matching_order.has_pending_product("burger") or matching_order.has_pending_product("cheeseburger")):
				matched_id = "burger" if matching_order.has_pending_product("burger") else "cheeseburger"
			elif product_id in ["fries", "fries_pack"] and matching_order.has_pending_product("fries"):
				matched_id = "fries"
			elif product_id in ["onion_rings", "fried_onions"] and matching_order.has_pending_product("onion_rings"):
				matched_id = "onion_rings"
			elif (product_id.begins_with("soda_") or product_id.begins_with("juice_")) and matching_order.has_pending_product(product_id):
				matched_id = product_id

			if matched_id != "":
				matching_order.register_product_delivered(matched_id)
				is_valid_delivery = true

	if is_valid_delivery and matching_order != null:
		# Pedido CORRETO: registra entrega e conclui pagamento
			var fin = FinanceManager.get_instance()
			if not fin and is_inside_tree():
				fin = get_tree().root.find_child("FinanceManager", true, false) as FinanceManager
			if fin:
				fin.record_sale(matching_order.total_price, "drive_thru", "Drive-Thru: %s" % matching_order.items[0].get("product_name", product_id))
			else:
				var economy = EconomyManager.get_instance()
				if economy:
					economy.add_money(matching_order.total_price, "Drive-Thru: %s" % matching_order.items[0].get("product_name", product_id))

			if car and is_instance_valid(car) and car.has_method("receive_order"):
				car.receive_order(product_id)

			order_manager.complete_order(matching_order)
			_show_player_feedback(player, "🚗 Pedido #%03d entregue com sucesso! +$%.2f" % [matching_order.id, matching_order.total_price])
		else:
			_show_player_feedback(player, "Item entregue! Faltam %d itens." % [matching_order.get_total_quantity() - matching_order.get_delivered_count()])

		delivery_succeeded.emit(matching_order, product_id)
	else:
		# Pedido INCORRETO: cliente recebe o item/sacola, identifica erro, fala que está errado e vai embora sem pagar
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
