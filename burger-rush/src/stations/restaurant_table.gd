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

var dirt_amount: float = 0.0

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
	return table_state == TableState.AVAILABLE and seated_customers.is_empty() and not is_dirty()

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

func release(had_meal: bool = true) -> void:
	seated_customers.clear()

	if had_meal:
		# Alimentos consumidos desaparecem, mas bandejas físicas permanecem usadas sobre a mesa
		var remaining_trays: Array[Node3D] = []
		for item in served_items:
			if is_instance_valid(item):
				if item is ServingTray or item is OrderTray or item.name.contains("Tray") or item.name.contains("Bandeja"):
					if item.has_method("consume_food_items"):
						item.consume_food_items()
					item.set("is_held", false)
					item.location = Item.ItemLocation.TABLE
					item.collision_layer = 1
					item.collision_mask = 1
					remaining_trays.append(item)
				else:
					item.queue_free()
		served_items = remaining_trays

		if dirty_dish_instance and is_instance_valid(dirty_dish_instance):
			dirty_dish_instance.queue_free()
			dirty_dish_instance = null

		# Mesa fica suja SOMENTE após o cliente realmente realizar a refeição
		table_state = TableState.DIRTY
		dirt_amount = 1.0
		_update_visual_status()
	else:
		# Cliente foi embora sem comer: mesa permanece LIMPA e livre para outros clientes
		for item in served_items:
			if is_instance_valid(item):
				item.queue_free()
		served_items.clear()

		if dirty_dish_instance and is_instance_valid(dirty_dish_instance):
			dirty_dish_instance.queue_free()
			dirty_dish_instance = null

		table_state = TableState.AVAILABLE
		dirt_amount = 0.0
		_update_visual_status()

func is_dirty() -> bool:
	return table_state == TableState.DIRTY

func has_tray_on_table() -> bool:
	for item in served_items:
		if is_instance_valid(item) and (item is ServingTray or item is OrderTray or item.name.contains("Tray")):
			return true
	var plate_slot = get_node_or_null("PlateSlot")
	if plate_slot:
		for c in plate_slot.get_children():
			if c is ServingTray or c is OrderTray or c.name.contains("Tray"):
				return true
	return false

func clean_progress(delta: float, player: Node3D = null) -> bool:
	if table_state != TableState.DIRTY:
		return true

	if has_tray_on_table():
		if player:
			_show_player_feedback(player, "⚠️ Recolha a bandeja antes de limpar a mesa!")
		return false

	dirt_amount = maxf(0.0, dirt_amount - (delta / 1.2))

	var dirt_mesh = get_node_or_null("Model/TableTop/TableTopDirt")
	if dirt_mesh:
		dirt_mesh.visible = (dirt_amount > 0.0)
		dirt_mesh.scale = Vector3.ONE * clampf(dirt_amount, 0.2, 1.0)

	if dirt_amount <= 0.0:
		table_state = TableState.AVAILABLE
		_update_visual_status()
		if player:
			_show_player_feedback(player, "✨ Mesa #%d limpa e higienizada com sucesso!" % table_id)
		return true

	return false

func clean_table(player: Node3D) -> void:
	if table_state != TableState.DIRTY:
		return

	if has_tray_on_table():
		# Recolhe a bandeja se houver
		for item in served_items:
			if is_instance_valid(item) and (item is ServingTray or item is OrderTray or item.name.contains("Tray")):
				if item.get_parent():
					item.get_parent().remove_child(item)
				served_items.erase(item)
				if player and player.get("held_item") == null and player.has_method("pick_up"):
					player.pick_up(item)
					_show_player_feedback(player, "🍽️ Bandeja usada recolhida da Mesa #%d" % table_id)
				else:
					item.queue_free()
				return

		var plate_slot = get_node_or_null("PlateSlot")
		if plate_slot:
			for c in plate_slot.get_children():
				if c is ServingTray or c is OrderTray or c.name.contains("Tray"):
					plate_slot.remove_child(c)
					if player and player.get("held_item") == null and player.has_method("pick_up"):
						player.pick_up(c)
						_show_player_feedback(player, "🍽️ Bandeja usada recolhida da Mesa #%d" % table_id)
					else:
						c.queue_free()
					return
		return

	dirt_amount = 0.0
	table_state = TableState.AVAILABLE
	_update_visual_status()
	if player:
		_show_player_feedback(player, "✨ Mesa #%d limpa e higienizada!" % table_id)

func get_interaction_prompt(player: Node = null) -> String:
	if table_state == TableState.DIRTY:
		if has_tray_on_table():
			return "🖱️ [Clique Esquerdo] Recolher Bandeja Usada"
		var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder") if player else null
		var sponge = tool_holder.get_node_or_null("Sponge") if tool_holder else null
		if sponge:
			if sponge.is_dirty:
				return "⚠️ Bucha suja! Lave na pia antes de limpar a mesa"
			else:
				return "🖱️ [Segurar Clique Esquerdo] Limpar Mesa com a Bucha"
		else:
			return "Equipe a Bucha (tecla 2) para limpar a mesa"

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
			if order and player and player.get("held_item") != null:
				var held = player.get("held_item")
				if (held is ServingTray or held is OrderTray) and held.has_items():
					return "E — Entregar Bandeja na Mesa #%d" % table_id
				elif held.has_method("get_product_id") or held.get("item_id") != null:
					return "E — Entregar Item na Mesa #%d" % table_id
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
			if held is ServingTray or held is OrderTray:
				_serve_tray(player, held)
			elif held != null and (held.has_method("get_product_id") or held.get("item_id") != null):
				_serve_single_item(player, held)
			else:
				_show_player_feedback(player, "Traga a bandeja com o pedido para servir a Mesa #%d." % table_id)

func _resolve_product_ids(item: Node3D) -> Array[String]:
	var ids: Array[String] = []
	if item.has_method("get_product_id"):
		var pid = str(item.get_product_id())
		if pid != "" and not ids.has(pid): ids.append(pid)
	if item.get("item_id") != null:
		var iid = str(item.get("item_id"))
		if iid != "" and not ids.has(iid): ids.append(iid)
	if item.get("item_type") != null:
		var itype = str(item.get("item_type"))
		if itype != "" and not ids.has(itype): ids.append(itype)
	return ids

func _serve_single_item(player: Node3D, item: Node3D) -> void:
	var primary_cust = seated_customers[0]
	var order = primary_cust.current_order
	if not order:
		return

	var pids = _resolve_product_ids(item)
	var matched_id = ""
	for pid in pids:
		if order.has_pending_product(pid):
			matched_id = pid
			break

	if matched_id != "":
		order.mark_product_delivered(matched_id)
		if player.has_method("take_held_item"):
			player.take_held_item()
		else:
			player.set("held_item", null)

		plate_slot.add_child(item)
		item.position = Vector3.ZERO
		if item is Item:
			item.is_held = false
			item.location = Item.ItemLocation.TABLE
		served_items.append(item)

		_show_player_feedback(player, "🍔 Item servido na Mesa #%d!" % table_id)

		if order.is_fully_delivered():
			for c in seated_customers:
				if is_instance_valid(c):
					c.receive_food()
			_show_player_feedback(player, "🎉 Pedido da Mesa #%d completo!" % table_id)

	_update_visual_status()

func _serve_tray(player: Node3D, tray: Node3D) -> void:
	var primary_cust = seated_customers[0]
	var order = primary_cust.current_order
	if not order:
		return

	var products = tray.get_products() if tray.has_method("get_products") else []
	var delivered_count = 0

	for p in products:
		var pids = _resolve_product_ids(p)
		for pid in pids:
			if order.has_pending_product(pid):
				order.mark_product_delivered(pid)
				delivered_count += 1
				break

	if delivered_count > 0 or products.is_empty():
		# Transfere a bandeja da mão do jogador para a mesa
		if player.has_method("take_held_item"):
			player.take_held_item()
		else:
			player.set("held_item", null)

		plate_slot.add_child(tray)
		tray.position = Vector3.ZERO
		tray.rotation = Vector3.ZERO
		if tray is Item:
			tray.is_held = false
			tray.location = Item.ItemLocation.TABLE
			tray.collision_layer = 1
			tray.collision_mask = 1
		served_items.append(tray)

		_show_player_feedback(player, "🍽️ Bandeja de serviço entregue na Mesa #%d!" % table_id)

		if order.is_fully_delivered():
			for c in seated_customers:
				if is_instance_valid(c):
					c.receive_food()
			_show_player_feedback(player, "🎉 Pedido da Mesa #%d entregue!" % table_id)

	_update_visual_status()

func _update_visual_status() -> void:
	var dirt_mesh = get_node_or_null("Model/TableTop/TableTopDirt")
	if dirt_mesh:
		dirt_mesh.visible = (table_state == TableState.DIRTY)
		if table_state == TableState.DIRTY:
			dirt_mesh.scale = Vector3.ONE * clampf(dirt_amount if dirt_amount > 0.0 else 1.0, 0.2, 1.0)

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
			status_label.text = "Mesa %d\n🔴 Bandeja / Pratos Sujos" % table_id
			status_label.modulate = Color(0.9, 0.3, 0.3)

func _show_player_feedback(player: Node, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_feedback"):
			hud.show_feedback(message)
