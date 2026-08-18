class_name DeliveryWindowStation
extends StaticBody3D

# =============================================================================
# BURGER RUSH - JANELA FÍSICA DE DELIVERY (EXTERNAL PICKUP WINDOW)
#
# Detecta a presença física de qualquer Saco de Delivery (DeliveryBag) colocado
# no balcão da janela, vincula ao pedido (seja correto ou incorreto),
# e dispara a chegada autônoma do Motoboy para recolher o pedido pelo lado de fora.
# =============================================================================

const OrderManager = preload("res://src/orders/order_manager.gd")
const Order = preload("res://src/orders/order.gd")
const DeliveryBagScript = preload("res://src/items/delivery_bag.gd")

signal bag_placed(bag: Node, order: Order)
signal bag_collected(bag: Node, courier: Node)

@onready var bag_slot: Node3D = get_node_or_null("BagSlot")
@onready var delivery_zone: Area3D = get_node_or_null("DeliveryZone")

var placed_bag: Node3D = null
var current_delivery_order: Order = null
var active_courier: Node = null

var courier_scene: PackedScene = preload("res://src/customers/delivery_motorcycle_courier.tscn")

var _scan_timer: float = 0.0

func _ready() -> void:
	if not bag_slot:
		bag_slot = get_node_or_null("BagSlot")
	if not delivery_zone:
		delivery_zone = get_node_or_null("DeliveryZone")

	if delivery_zone:
		if not delivery_zone.body_entered.is_connected(_on_delivery_zone_body_entered):
			delivery_zone.body_entered.connect(_on_delivery_zone_body_entered)
		if not delivery_zone.area_entered.is_connected(_on_delivery_zone_area_entered):
			delivery_zone.area_entered.connect(_on_delivery_zone_area_entered)

func _physics_process(delta: float) -> void:
	# Verificação periódica contínua da presença física da sacola no balcão
	_scan_timer += delta
	if _scan_timer >= 0.5:
		_scan_timer = 0.0
		_scan_delivery_zone_for_bags()

func _on_delivery_zone_body_entered(body: Node) -> void:
	_check_and_register_bag(body)

func _on_delivery_zone_area_entered(area: Node) -> void:
	var target = area.get_parent() if area.get_parent() else area
	_check_and_register_bag(target)

func _scan_delivery_zone_for_bags() -> void:
	if placed_bag != null and is_instance_valid(placed_bag):
		# Se a sacola já está no balcão e ainda não há motoboy a caminho, chama
		if active_courier == null or not is_instance_valid(active_courier):
			_summon_motorcycle_courier()
		return

	# Procura por sacolas soltas na área de entrega da janela
	if delivery_zone:
		for body in delivery_zone.get_overlapping_bodies():
			if _check_and_register_bag(body):
				return
		for area in delivery_zone.get_overlapping_areas():
			var target = area.get_parent() if area.get_parent() else area
			if _check_and_register_bag(target):
				return

	# Procura nos filhos de BagSlot
	if bag_slot:
		for child in bag_slot.get_children():
			if _is_delivery_bag(child):
				_place_bag_on_station(child)
				return

func _check_and_register_bag(node: Node) -> bool:
	if not node or not is_instance_valid(node):
		return false
	if node == placed_bag:
		return false

	if _is_delivery_bag(node):
		# Verifica se o item está sendo segurado pelo jogador
		var is_held = node.get("is_held")
		if is_held == true:
			return false

		# Coloca e vincula a sacola na janela
		_place_bag_on_station(node as Node3D)
		return true

	return false

func _is_delivery_bag(node: Node) -> bool:
	if not node:
		return false
	if node is DeliveryBagScript:
		return true
	if node.name.begins_with("DeliveryBag") or node.name.begins_with("delivery_bag"):
		return true
	if str(node.get("item_id")) == "delivery_bag":
		return true
	return false

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")

	if placed_bag != null:
		if held == null:
			var d_name = placed_bag.get_display_name() if placed_bag.has_method("get_display_name") else "Saco de Delivery"
			return "🖱️ / [E] Pegar %s da Janela" % d_name
		return ""

	if held != null and _is_delivery_bag(held):
		return "🖱️ / [E] Colocar Saco na Janela de Delivery"

	return ""

func interact(player: Node3D) -> void:
	_handle_interaction(player)

func interact_item(player: Node3D) -> void:
	_handle_interaction(player)

func _handle_interaction(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")

	# 1. Se já houver um saco colocado e o jogador estiver com as mãos livres: retira
	if placed_bag != null and held == null:
		var bag = placed_bag
		placed_bag = null
		if bag.get_parent():
			bag.get_parent().remove_child(bag)
		if player.has_method("pick_up"):
			player.pick_up(bag)

		if current_delivery_order and current_delivery_order.delivery_stage == "WAITING_COURIER":
			current_delivery_order.delivery_stage = "PREPARING"
			current_delivery_order.state = Order.State.IN_PROGRESS
			var om = OrderManager.get_instance()
			if om:
				om.order_updated.emit(current_delivery_order)

		current_delivery_order = null
		_show_feedback(player, "🛍️ Retirou o saco de delivery da janela.")
		return

	# 2. Se o jogador estiver segurando um Saco de Delivery: coloca na janela (mesmo que com pedido errado)
	if held != null and _is_delivery_bag(held):
		if placed_bag != null:
			_show_feedback(player, "⚠️ Janela ocupada! Aguarde o motoboy retirar o pedido atual.")
			return

		if player.has_method("take_held_item"):
			var bag_item = player.take_held_item()
			if bag_item:
				_place_bag_on_station(bag_item)
				_show_feedback(player, "🛵 Pedido na Janela de Delivery! Aguardando retirada do motoboy.")

func _place_bag_on_station(bag_item: Node3D) -> void:
	placed_bag = bag_item
	if not bag_slot:
		bag_slot = get_node_or_null("BagSlot")

	var prev_parent = bag_item.get_parent()
	if prev_parent and prev_parent != bag_slot:
		prev_parent.remove_child(bag_item)

	if bag_slot:
		if bag_item.get_parent() != bag_slot:
			bag_slot.add_child(bag_item)
		bag_item.position = Vector3.ZERO
		bag_item.rotation = Vector3.ZERO
	else:
		if bag_item.get_parent() != self:
			add_child(bag_item)
		bag_item.position = Vector3(0, 0.93, 0)

	if bag_item.get("collision_shape") and is_instance_valid(bag_item.get("collision_shape")):
		bag_item.collision_shape.disabled = true

	# Vincula ao pedido de delivery ativo
	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	if om:
		var target_order: Order = null
		# 1. Procura pedido em preparo ou recém-recebido
		for o in om.get_active_orders():
			if o.source_type == "DELIVERY" and (o.delivery_stage == "PREPARING" or o.delivery_stage == "NEW_RECEIVED"):
				target_order = o
				break

		# 2. Se não houver, procura qualquer delivery ativo
		if not target_order:
			for o in om.get_active_orders():
				if o.source_type == "DELIVERY":
					target_order = o
					break

		# 3. Se ainda não houver (ex: teste sandbox sem pedido prévio), cria um pedido de teste
		if not target_order:
			target_order = om.create_delivery_order()
			target_order.is_accepted = true

		if target_order:
			current_delivery_order = target_order
			om.mark_delivery_ready_for_pickup(target_order, bag_item)

	bag_placed.emit(bag_item, current_delivery_order)

	# Aciona a chegada externa do Motoboy
	_summon_motorcycle_courier()

func _summon_motorcycle_courier() -> void:
	if not courier_scene:
		return
	if active_courier and is_instance_valid(active_courier):
		return # Já existe um motoboy a caminho para este pedido

	var parent_node: Node = get_parent() if get_parent() else (get_tree().current_scene if get_tree() else null)
	if not parent_node and is_inside_tree() and get_tree() and get_tree().root:
		parent_node = get_tree().root

	if parent_node:
		var courier = courier_scene.instantiate()
		courier.target_window_station = self
		var spawn_pos = Vector3(24.0, 0.0, 16.0)
		courier.position = spawn_pos
		parent_node.add_child(courier)
		if courier.is_inside_tree():
			courier.global_position = spawn_pos
		active_courier = courier

func courier_pickup_bag(courier: Node) -> Node3D:
	var bag = placed_bag
	if not bag:
		# Se placed_bag estava nulo mas há uma sacola na zona, pega ela
		if delivery_zone:
			for b in delivery_zone.get_overlapping_bodies():
				if _is_delivery_bag(b):
					bag = b
					break

	if not bag:
		return null

	placed_bag = null
	if bag.get_parent():
		bag.get_parent().remove_child(bag)

	var order = current_delivery_order
	current_delivery_order = null
	active_courier = null

	if order:
		order.delivery_stage = "IN_DELIVERY"
		var om = OrderManager.get_instance()
		if om:
			om.order_updated.emit(order)

	bag_collected.emit(bag, courier)
	return bag

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
