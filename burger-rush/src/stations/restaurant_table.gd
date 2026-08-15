class_name RestaurantTable
extends StaticBody3D

enum TableState {
	AVAILABLE,
	RESERVED,
	OCCUPIED,
	DIRTY
}

@export var table_id: int = 1
@export var seat_count: int = 4

@onready var seat_node: Node3D = $Seat
@onready var plate_slot: Node3D = $PlateSlot
@onready var status_label: Label3D = $StatusLabel

var table_state: TableState = TableState.AVAILABLE
var seated_customers: Array[Customer] = []
var served_items: Array[Node3D] = []
var dirty_dishes_scene: PackedScene = preload("res://src/items/dirty_dishes.tscn")
var dirty_dish_instance: Node3D = null

# Compatibilidade para código que acessa seated_customer diretamente
var seated_customer: Customer:
	get:
		return seated_customers[0] if not seated_customers.is_empty() else null
	set(val):
		if val == null:
			seated_customers.clear()
		elif not seated_customers.has(val):
			seated_customers.append(val)

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
	return table_state == TableState.AVAILABLE and seated_customers.is_empty()

func is_available_for_group(group_size: int) -> bool:
	return is_available() and seat_count >= group_size

func get_available_seats() -> int:
	if table_state != TableState.AVAILABLE:
		return 0
	return max(0, seat_count - seated_customers.size())

func get_seat_position(seat_idx: int) -> Vector3:
	var seat_node_name = "Seat%d" % seat_idx
	var target = get_node_or_null(seat_node_name) as Node3D
	if target:
		return target.global_position if is_inside_tree() else (position + target.position)

	var angle = (seat_idx - 1) * (PI * 0.5)
	var base_pos = global_position if is_inside_tree() else position
	return base_pos + Vector3(sin(angle) * 0.68, 0, cos(angle) * 0.68)

func occupy(customer: Customer) -> Vector3:
	return occupy_seat(customer)

func occupy_seat(customer: Customer) -> Vector3:
	if not seated_customers.has(customer):
		seated_customers.append(customer)

	table_state = TableState.RESERVED
	_update_visual_status()

	var seat_idx = seated_customers.find(customer) + 1
	return get_seat_position(seat_idx)

# Chamado pelo cliente quando ele fisicamente chega e senta na cadeira
func on_customer_seated(customer: Customer) -> void:
	table_state = TableState.OCCUPIED
	_update_visual_status()

func release() -> void:
	seated_customers.clear()
	for item in served_items:
		if is_instance_valid(item):
			item.queue_free()
	served_items.clear()

	if dirty_dish_instance and is_instance_valid(dirty_dish_instance):
		dirty_dish_instance.queue_free()
		dirty_dish_instance = null

	table_state = TableState.AVAILABLE
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
	if table_state == TableState.DIRTY:
		return "E — Limpar Mesa #%d (Recolher Restos)" % table_id

	if seated_customers.is_empty():
		return ""

	var primary_cust = seated_customers[0]
	if not is_instance_valid(primary_cust):
		return ""

	match primary_cust.state:
		Customer.State.SEATED_WAITING_TO_ORDER:
			return "E — Atender Mesa #%d" % table_id
		Customer.State.WAITING_FOR_FOOD:
			var order = primary_cust.current_order
			if order and player and player.get("held_item") is OrderTray:
				var tray = player.get("held_item") as OrderTray
				if tray.has_items():
					return "E — Entregar Pedido na Mesa #%d" % table_id
			return "Mesa #%d: Aguardando pedido..." % table_id
		Customer.State.EATING:
			return "Mesa #%d: Clientes comendo..." % table_id

	return ""

func interact(player: Node3D) -> void:
	if table_state == TableState.DIRTY:
		clean_table(player)
		return

	if seated_customers.is_empty():
		return

	var primary_cust = seated_customers[0]
	if not is_instance_valid(primary_cust):
		return

	match primary_cust.state:
		Customer.State.SEATED_WAITING_TO_ORDER:
			primary_cust.place_order(player)
			_show_player_feedback(player, "📝 Pedido recebido da Mesa #%d!" % table_id)
			_update_visual_status()

		Customer.State.WAITING_FOR_FOOD:
			var held = player.get("held_item")
			if held is OrderTray:
				_serve_tray(player, held as OrderTray)
			elif held != null and held.has_method("get_product_id"):
				_serve_single_item(player, held)
			else:
				_show_player_feedback(player, "Traga o pedido pronto para servir a Mesa #%d." % table_id)

func _serve_single_item(player: Node3D, item: Node3D) -> void:
	var primary_cust = seated_customers[0]
	var order = primary_cust.current_order
	if not order:
		return

	var pid = item.get_product_id() if item.has_method("get_product_id") else ""
	if pid != "" and order.has_pending_product(pid):
		order.mark_product_delivered(pid)
		player.set("held_item", null)
		plate_slot.add_child(item)
		item.position = Vector3.ZERO
		served_items.append(item)

		_show_player_feedback(player, "🍔 Item servido na Mesa #%d!" % table_id)

		if order.is_fully_delivered():
			for c in seated_customers:
				if is_instance_valid(c):
					c.receive_food()
			_show_player_feedback(player, "🎉 Pedido da Mesa #%d completo!" % table_id)

	_update_visual_status()

func _serve_tray(player: Node3D, tray: OrderTray) -> void:
	var primary_cust = seated_customers[0]
	var order = primary_cust.current_order
	if not order:
		return

	var products = tray.get_products()
	var delivered_count = 0

	for p in products:
		var pid = str(p.get("item_id"))
		if order.has_pending_product(pid):
			order.mark_product_delivered(pid)
			delivered_count += 1

	if delivered_count > 0:
		tray.clear_tray()
		player.set("held_item", null)
		plate_slot.add_child(tray)
		tray.position = Vector3.ZERO
		served_items.append(tray)

		_show_player_feedback(player, "🍽️ Bandeja com %d itens servida na Mesa #%d!" % [delivered_count, table_id])

		if order.is_fully_delivered():
			for c in seated_customers:
				if is_instance_valid(c):
					c.receive_food()
			_show_player_feedback(player, "🎉 Pedido da Mesa #%d entregue!" % table_id)

	_update_visual_status()

func _update_visual_status() -> void:
	if not status_label:
		status_label = get_node_or_null("StatusLabel")
	if not status_label:
		return

	match table_state:
		TableState.AVAILABLE:
			status_label.text = "Mesa %d (%d Lugares)\n🟢 Livre" % [table_id, seat_count]
			status_label.modulate = Color(0.3, 0.9, 0.4)
		TableState.RESERVED:
			status_label.text = "Mesa %d\n🟡 A Caminho..." % table_id
			status_label.modulate = Color(0.95, 0.85, 0.2)
		TableState.OCCUPIED:
			var cust_count = seated_customers.size()
			status_label.text = "Mesa %d (%d Clientes)\n🔵 Ocupada" % [table_id, cust_count]
			status_label.modulate = Color(0.4, 0.7, 1.0)
		TableState.DIRTY:
			status_label.text = "Mesa %d\n🔴 Pratos Sujos" % table_id
			status_label.modulate = Color(0.9, 0.3, 0.3)

func _show_player_feedback(player: Node, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud.has_method("show_feedback"):
			hud.show_feedback(message)
