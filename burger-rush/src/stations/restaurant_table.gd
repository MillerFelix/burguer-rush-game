class_name RestaurantTable
extends StaticBody3D

enum TableState {
	AVAILABLE,
	RESERVED,
	OCCUPIED,
	DIRTY
}

@export var table_id: int = 1
@export var seat_count: int = 2

@onready var seat_node: Node3D = $Seat
@onready var plate_slot: Node3D = $PlateSlot
@onready var status_label: Label3D = $StatusLabel

var table_state: TableState = TableState.AVAILABLE
var seated_customer: Customer = null
var served_items: Array[Node3D] = []
var dirty_dishes_scene: PackedScene = preload("res://src/items/dirty_dishes.tscn")
var dirty_dish_instance: Node3D = null

func _ready() -> void:
	var mgr = TableManager.get_instance()
	if mgr:
		mgr.register_table(self)
	_update_visual_status()

func _exit_tree() -> void:
	var mgr = TableManager.get_instance()
	if mgr:
		mgr.unregister_table(self)

func is_available() -> bool:
	return table_state == TableState.AVAILABLE and seated_customer == null

func occupy(customer: Customer) -> Vector3:
	seated_customer = customer
	table_state = TableState.RESERVED
	_update_visual_status()
	if seat_node:
		return seat_node.global_position
	return global_position + Vector3(0, 0, 0.75)

func release() -> void:
	seated_customer = null
	# Remove os itens de comida consumidos
	for item in served_items:
		if is_instance_valid(item):
			item.queue_free()
	served_items.clear()

	# Gera pratos sujos e restos na mesa
	table_state = TableState.DIRTY
	if plate_slot and not dirty_dish_instance:
		dirty_dish_instance = dirty_dishes_scene.instantiate()
		plate_slot.add_child(dirty_dish_instance)
		dirty_dish_instance.position = Vector3.ZERO

	_update_visual_status()

func clean_table(player: Node3D) -> void:
	if table_state != TableState.DIRTY:
		return

	if dirty_dish_instance and is_instance_valid(dirty_dish_instance):
		dirty_dish_instance.queue_free()
		dirty_dish_instance = null

	table_state = TableState.AVAILABLE
	_show_player_feedback(player, "✨ Mesa #%d limpa e higienizada com sucesso!" % table_id)
	_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	# 1. Se a mesa estiver suja
	if table_state == TableState.DIRTY:
		return "E — Limpar Mesa #%d (Recolher Restos)" % table_id

	if not seated_customer or not is_instance_valid(seated_customer):
		return ""

	# 2. Se houver cliente
	match seated_customer.state:
		Customer.State.SEATED_WAITING_TO_ORDER:
			return "E — Atender Mesa #%d" % table_id

		Customer.State.WAITING_FOR_FOOD:
			var order = seated_customer.current_order
			if not order:
				return ""

			var held = player.get("held_item") if player else null
			if held != null:
				if held is OrderTray:
					var tray = held as OrderTray
					var match_count = 0
					for p in tray.get_products():
						var pid = str(p.get("item_id"))
						if order.has_pending_product(pid):
							match_count += 1
					if match_count > 0:
						return "E — Servir %d Itens da Bandeja (Mesa #%d)" % [match_count, table_id]
					else:
						return "❌ Itens da bandeja não pertencem à Mesa #%d" % table_id
				else:
					var pid = str(held.get("item_id"))
					if order.has_pending_product(pid):
						var pname = held.get_display_name() if held.has_method("get_display_name") else "Item"
						return "E — Servir %s (Mesa #%d)" % [pname, table_id]
					else:
						return "❌ Item não pertence ao pedido da Mesa #%d" % table_id
			else:
				var first_item = order.items[0].get("product_name", "Pedido") if not order.items.is_empty() else "Pedido"
				return "Mesa #%d: Aguardando %s" % [table_id, first_item]

		Customer.State.EATING:
			return "Mesa #%d: Cliente saboreando a refeição..." % table_id

		Customer.State.REQUESTING_BILL:
			var total = seated_customer.current_order.total_price if seated_customer.current_order else 0.0
			return "E — Entregar Conta (Mesa #%d - $%.2f)" % [table_id, total]

		_:
			return ""

func interact(player: Node3D) -> void:
	# 1. Limpeza de mesa suja
	if table_state == TableState.DIRTY:
		clean_table(player)
		return

	if not seated_customer or not is_instance_valid(seated_customer):
		return

	match seated_customer.state:
		Customer.State.SEATED_WAITING_TO_ORDER:
			seated_customer.take_order_from_player()
			table_state = TableState.OCCUPIED
			_show_player_feedback(player, "📝 Pedido da Mesa #%d anotado com sucesso!" % table_id)
			_update_visual_status()

		Customer.State.WAITING_FOR_FOOD:
			var order = seated_customer.current_order
			if not order or order.items.is_empty():
				return

			var held = player.get("held_item")
			if not held:
				_show_player_feedback(player, "Você precisa segurar a comida ou bandeja para servir a Mesa #%d!" % table_id)
				return

			# Servir a partir da OrderTray
			if held is OrderTray:
				var tray = held as OrderTray
				var delivered_items = []
				for p in tray.get_products():
					var pid = str(p.get("item_id"))
					if order.has_pending_product(pid):
						order.register_product_delivered(pid)
						delivered_items.append(p)

				if not delivered_items.is_empty():
					for p in delivered_items:
						tray.remove_product(p)
						served_items.append(p)
						if plate_slot:
							plate_slot.add_child(p)
							p.position = Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
							p.rotation = Vector3.ZERO
							if p.get("collision_shape"):
								p.collision_shape.disabled = true

					if order.is_all_delivered():
						seated_customer.serve_food()
						_show_player_feedback(player, "✅ Pedido completo da Mesa #%d servido!" % table_id)
					else:
						_show_player_feedback(player, "📦 %d itens servidos! Faltam %d itens para a Mesa #%d." % [delivered_items.size(), order.get_total_quantity() - order.get_delivered_count(), table_id])
					_update_visual_status()
					return
				else:
					_show_player_feedback(player, "❌ Nenhum item da bandeja pertence ao pedido pendente da Mesa #%d!" % table_id)
					return

			# Servir item individual segurado na mão
			var pid = str(held.get("item_id"))
			if order.has_pending_product(pid) and player.has_method("take_held_item"):
				var item = player.take_held_item()
				served_items.append(item)
				if plate_slot:
					plate_slot.add_child(item)
					item.position = Vector3.ZERO
					item.rotation = Vector3.ZERO
					if item.get("collision_shape"):
						item.collision_shape.disabled = true

				order.register_product_delivered(pid)
				if order.is_all_delivered():
					seated_customer.serve_food()
					_show_player_feedback(player, "✅ Pedido completo da Mesa #%d servido!" % table_id)
				else:
					_show_player_feedback(player, "📦 Item entregue! Faltam %d itens para a Mesa #%d." % [order.get_total_quantity() - order.get_delivered_count(), table_id])
				_update_visual_status()
			else:
				_show_player_feedback(player, "❌ Este item não faz parte do pedido da Mesa #%d!" % table_id)

		Customer.State.REQUESTING_BILL:
			seated_customer.pay_and_leave()
			_update_visual_status()

func _update_visual_status() -> void:
	if not status_label:
		return

	if table_state == TableState.DIRTY:
		status_label.text = "Mesa #%d\n🧹 SUJA (Restos)\n[E] Limpar" % table_id
		status_label.modulate = Color(1.0, 0.4, 0.2, 1.0)
		return

	if not seated_customer or not is_instance_valid(seated_customer):
		status_label.text = "Mesa #%d\n🟢 DISPONÍVEL" % table_id
		status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		return

	match seated_customer.state:
		Customer.State.LOOKING_FOR_TABLE, Customer.State.WALKING_TO_TABLE:
			status_label.text = "Mesa #%d\n🟡 Reservada" % table_id
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Customer.State.SEATED_WAITING_TO_ORDER:
			status_label.text = "Mesa #%d\n📝 [E] Atender" % table_id
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Customer.State.WAITING_FOR_FOOD:
			var name_str = seated_customer.current_order.items[0].get("product_name", "Pedido") if seated_customer.current_order and not seated_customer.current_order.items.is_empty() else "Pedido"
			var count_info = "(%d/%d)" % [seated_customer.current_order.get_delivered_count(), seated_customer.current_order.get_total_quantity()] if seated_customer.current_order else ""
			status_label.text = "Mesa #%d\n⏳ Aguarda: %s %s" % [table_id, name_str, count_info]
			status_label.modulate = Color(0.4, 0.8, 1.0, 1.0)
		Customer.State.EATING:
			status_label.text = "Mesa #%d\n😋 Comendo..." % table_id
			status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		Customer.State.REQUESTING_BILL:
			var total = seated_customer.current_order.total_price if seated_customer.current_order else 0.0
			status_label.text = "Mesa #%d\n💳 [E] Conta ($%.2f)" % [table_id, total]
			status_label.modulate = Color(1.0, 0.5, 0.2, 1.0)
		Customer.State.PAYING, Customer.State.LEAVING:
			status_label.text = "Mesa #%d\n💵 Liberando..." % table_id
			status_label.modulate = Color(0.7, 0.7, 0.7, 1.0)

func _show_player_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
