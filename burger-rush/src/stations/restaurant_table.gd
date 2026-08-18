class_name RestaurantTable
extends StaticBody3D

enum TableState {
	AVAILABLE,
	RESERVED,
	OCCUPIED,
	DIRTY
}

@export var table_id: int = 1:
	set(val):
		table_id = val
		_update_table_number()
@export var seat_count: int = 4

@onready var seat_node: Node3D = $Seat
@onready var plate_slot: Node3D = $PlateSlot
@onready var number_front: Label3D = get_node_or_null("Model/TableTop/TableNumberHolder/NumberFront")
@onready var number_back: Label3D = get_node_or_null("Model/TableTop/TableNumberHolder/NumberBack")
@onready var status_label: Label3D = get_node_or_null("StatusLabel")

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
	add_to_group("tables")
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

## Retorna um ponto de interação limpo e acessível no corredor para funcionários NPC
func get_employee_interaction_position() -> Vector3:
	var base = global_position if is_inside_tree() else position
	if base.x < -3.0:
		return base + Vector3(1.15, 0.0, 0.0)
	elif base.x > 3.0:
		return base + Vector3(-1.15, 0.0, 0.0)
	elif base.x < 0.0:
		return base + Vector3(0.85, 0.0, 0.6)
	else:
		return base + Vector3(0.0, 0.0, -1.1)

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

	dirt_amount = maxf(0.0, dirt_amount - (delta / 5.0))

	var dirt_mesh = get_node_or_null("Model/TableTop/TableTopDirt")
	if dirt_mesh:
		dirt_mesh.visible = (dirt_amount > 0.0)
		var sc = lerpf(0.20, 1.0, dirt_amount) if dirt_amount > 0.001 else 0.0
		dirt_mesh.scale = Vector3(sc, sc, sc)
		for child in dirt_mesh.get_children():
			if child is MeshInstance3D:
				var mat = child.get_active_material(0)
				if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.albedo_color.a = clampf(dirt_amount * 0.95, 0.0, 0.95)

	if dirt_amount <= 0.0:
		table_state = TableState.AVAILABLE
		_update_visual_status()
		if player:
			_show_player_feedback(player, "✨ Mesa #%d limpa e higienizada com sucesso!" % table_id)
		return true

	return false

func get_dirt_level() -> float:
	return dirt_amount if table_state == TableState.DIRTY else 0.0

func clean_table(player: Node3D) -> void:
	if table_state != TableState.DIRTY:
		return

	# Se tiver bandeja na mesa, recolhe a bandeja primeiro (mantendo a mesa DIRTY para ser esfregada com a bucha)
	if has_tray_on_table():
		for item in served_items:
			if is_instance_valid(item):
				if item.get_parent():
					item.get_parent().remove_child(item)
				item.queue_free()
		served_items.clear()

		var plate_slot = get_node_or_null("PlateSlot")
		if plate_slot:
			for c in plate_slot.get_children():
				if is_instance_valid(c):
					c.queue_free()

		if dirty_dish_instance and is_instance_valid(dirty_dish_instance):
			dirty_dish_instance.queue_free()
			dirty_dish_instance = null

		dirt_amount = 1.0
		_update_visual_status()
		if player:
			_show_player_feedback(player, "🗑️ Bandeja recolhida! Agora higienize a mesa com a bucha.")
		return

	# Se não tiver bandeja, higieniza completamente a mesa
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
			return "E / 🖱️ — Atender Mesa #%d" % table_id
		Customer.State.WAITING_FOR_FOOD:
			var order = primary_cust.current_order
			if order and player and player.get("held_item") != null:
				var held = player.get("held_item")
				if (held is ServingTray or held is OrderTray) and held.has_items():
					return "E / 🖱️ — Entregar Bandeja na Mesa #%d" % table_id
				elif held.has_method("get_product_id") or held.get("item_id") != null:
					return "E / 🖱️ — Entregar Item na Mesa #%d" % table_id
			return "Mesa #%d: Aguardando pedido..." % table_id
		Customer.State.EATING:
			return "Mesa #%d: Clientes comendo..." % table_id

	return ""

func interact_item(player: Node3D) -> void:
	interact(player)

func interact(player: Node3D) -> void:
	if table_state == TableState.DIRTY:
		clean_table(player)
		return

	if seated_customers.is_empty():
		return

	# 1. Se houver algum cliente esperando fazer pedido, anota
	for cust in seated_customers:
		if is_instance_valid(cust) and cust.state == Customer.State.SEATED_WAITING_TO_ORDER:
			cust.place_order(player)
			_show_player_feedback(player, "📝 Pedido recebido da Mesa #%d!" % table_id)
			_update_visual_status()
			return

	# 2. Se estiver aguardando comida e o jogador/funcionário trouxe itens
	for cust in seated_customers:
		if is_instance_valid(cust) and cust.state == Customer.State.WAITING_FOR_FOOD:
			var held = player.get("held_item") if player else null
			if held is ServingTray or held is OrderTray:
				_serve_tray(player, held)
			elif held != null and (held.has_method("get_product_id") or held.get("item_id") != null):
				_serve_single_item(player, held)
			else:
				if player:
					_show_player_feedback(player, "Traga a bandeja com o pedido para servir a Mesa #%d." % table_id)
			return

func _resolve_product_ids(item: Node3D) -> Array[String]:
	var ids: Array[String] = []
	if item.has_method("get_product_id"):
		var pid = str(item.get_product_id())
		if pid != "" and not ids.has(pid): ids.append(pid)
	if item.get("item_id") != null:
		var iid = str(item.get("item_id"))
		if iid != "" and not ids.has(iid): ids.append(iid)
	if item.get("recipe_id") != null:
		var rid = str(item.get("recipe_id"))
		if rid != "" and not ids.has(rid): ids.append(rid)
	if item is PackagedBurger or (item.get("item_id") != null and str(item.get("item_id")) == "packaged_burger"):
		if not ids.has("burger"): ids.append("burger")
		if not ids.has("cheeseburger"): ids.append("cheeseburger")
	if item.get("item_type") != null:
		var itype = str(item.get("item_type"))
		if itype != "" and not ids.has(itype): ids.append(itype)
	return ids

func _serve_single_item(player: Node3D, item: Node3D) -> void:
	var primary_cust = seated_customers[0]
	var order = primary_cust.current_order
	if not order:
		return

	# Transfere fisicamente o item da mão do jogador para a mesa
	if player.has_method("take_held_item"):
		player.take_held_item()
	else:
		player.set("held_item", null)

	if not plate_slot:
		plate_slot = get_node_or_null("PlateSlot")
	if not plate_slot:
		plate_slot = Node3D.new()
		plate_slot.name = "PlateSlot"
		plate_slot.position = Vector3(0, 0.805, 0)
		add_child(plate_slot)

	plate_slot.add_child(item)
	item.position = Vector3.ZERO
	if item is Item:
		item.is_held = false
		item.location = Item.ItemLocation.TABLE
	served_items.append(item)

	var pids = _resolve_product_ids(item)
	var matched_id = ""
	for pid in pids:
		if order.has_pending_product(pid):
			matched_id = pid
			break

	if matched_id != "":
		order.mark_product_delivered(matched_id)
		_show_player_feedback(player, "🍔 Item servido na Mesa #%d!" % table_id)

		if order.is_fully_delivered():
			for c in seated_customers:
				if is_instance_valid(c):
					c.receive_food()
			_show_player_feedback(player, "🎉 Pedido da Mesa #%d completo!" % table_id)
	else:
		# Pedido Errado! Clientes reagem negativamente e vão embora sem pagar
		for c in seated_customers:
			if is_instance_valid(c):
				c.on_order_wrong("Item incorreto servido na mesa!")
		_show_player_feedback(player, "❌ Pedido incorreto! O cliente não aceitou e foi embora sem pagar.")

	_update_visual_status()

func _serve_tray(player: Node3D, tray: Node3D) -> void:
	var primary_cust = seated_customers[0]
	var order = primary_cust.current_order
	if not order:
		return

	# Transfere a bandeja da mão do jogador para a mesa
	if player.has_method("take_held_item"):
		player.take_held_item()
	else:
		player.set("held_item", null)

	if not plate_slot:
		plate_slot = get_node_or_null("PlateSlot")
	if not plate_slot:
		plate_slot = Node3D.new()
		plate_slot.name = "PlateSlot"
		plate_slot.position = Vector3(0, 0.805, 0)
		add_child(plate_slot)

	plate_slot.add_child(tray)
	tray.position = Vector3.ZERO
	tray.rotation = Vector3.ZERO
	if tray is Item:
		tray.is_held = false
		tray.location = Item.ItemLocation.TABLE
		tray.collision_layer = 1
		tray.collision_mask = 1
	served_items.append(tray)

	var products = tray.get_products() if tray.has_method("get_products") else []
	var delivered_count = 0

	# Validação da bandeja
	for p in products:
		var pids = _resolve_product_ids(p)
		for pid in pids:
			if order.has_pending_product(pid):
				order.mark_product_delivered(pid)
				delivered_count += 1
				break

	if order.is_fully_delivered():
		for c in seated_customers:
			if is_instance_valid(c):
				c.receive_food()
		_show_player_feedback(player, "🎉 Pedido da Mesa #%d entregue com sucesso!" % table_id)
	else:
		# Pedido na bandeja incompleto ou incorreto
		for c in seated_customers:
			if is_instance_valid(c):
				c.on_order_wrong("Pedido incorreto na bandeja!")
		_show_player_feedback(player, "❌ Pedido incorreto na bandeja! Os clientes foram embora sem pagar.")

	_update_visual_status()

func _update_table_number() -> void:
	var n_front = number_front if number_front else get_node_or_null("Model/TableTop/TableNumberHolder/NumberFront") as Label3D
	var n_back = number_back if number_back else get_node_or_null("Model/TableTop/TableNumberHolder/NumberBack") as Label3D
	if n_front:
		n_front.text = str(table_id)
	if n_back:
		n_back.text = str(table_id)

func _update_visual_status() -> void:
	_update_table_number()
	var dirt_mesh = get_node_or_null("Model/TableTop/TableTopDirt")
	if dirt_mesh:
		dirt_mesh.visible = (table_state == TableState.DIRTY and dirt_amount > 0.0)
		if table_state == TableState.DIRTY and dirt_amount > 0.0:
			var sc = lerpf(0.20, 1.0, dirt_amount)
			dirt_mesh.scale = Vector3(sc, sc, sc)
			for child in dirt_mesh.get_children():
				if child is MeshInstance3D:
					var mat = child.get_active_material(0)
					if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
						mat.albedo_color.a = clampf(dirt_amount * 0.95, 0.0, 0.95)

	# Se existir Label3D flutuante legado, desativa para manter o ambiente livre de textos flutuantes
	if not status_label:
		status_label = get_node_or_null("StatusLabel")
	if status_label:
		status_label.visible = false

func _show_player_feedback(player: Node, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_feedback"):
			hud.show_feedback(message)
