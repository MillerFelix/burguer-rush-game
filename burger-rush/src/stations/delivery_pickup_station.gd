class_name DeliveryPickupStation
extends StaticBody3D

const OrderManager = preload("res://src/orders/order_manager.gd")
const Order = preload("res://src/orders/order.gd")
const DeliveryBagScript = preload("res://src/items/delivery_bag.gd")

# =============================================================================
# BURGER RUSH - BALCÃO DE EXPEDIÇÃO & COLETA DE DELIVERY
#
# Área dedicada no balcão principal para colocar o Saco de Delivery pronto.
# O saco permanece fisicamente no restaurante até o Motoboy chegar,
# identificar o pedido, recolher o saco e sair para entrega.
# =============================================================================

signal bag_placed(bag: Node, order: Order)
signal bag_collected(bag: Node, courier: Node)

@onready var bag_slot: Node3D = get_node_or_null("BagSlot")
@onready var status_label: Label3D = get_node_or_null("StatusLabel")
@onready var pickup_mat: MeshInstance3D = get_node_or_null("PickupMat")

var placed_bag: Node3D = null
var current_delivery_order: Order = null

var courier_scene: PackedScene = preload("res://src/customers/delivery_courier.tscn")

func _ready() -> void:
	if not bag_slot:
		bag_slot = get_node_or_null("BagSlot")
	if not status_label:
		status_label = get_node_or_null("StatusLabel")
	_update_status()

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")

	if placed_bag != null:
		if held == null:
			var d_name = placed_bag.get_display_name() if placed_bag.has_method("get_display_name") else "Saco de Delivery"
			return "🖱️ / [E] Pegar %s da Coleta" % d_name
		return ""

	if held != null:
		if held is DeliveryBagScript or held.name.begins_with("DeliveryBag") or str(held.get("item_id")) == "delivery_bag":
			if held.has_method("is_empty") and held.is_empty():
				return "⚠️ Coloque os itens do pedido dentro do Saco antes de entregar!"
			return "🖱️ / [E] Colocar Saco de Delivery na Área de Entrega"

	return ""

func interact(player: Node3D) -> void:
	_handle_interaction(player)

func interact_item(player: Node3D) -> void:
	_handle_interaction(player)

func _handle_interaction(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")

	# 1. Se já houver um saco colocado e o jogador estiver de mãos livres: retira
	if placed_bag != null and held == null:
		var bag = placed_bag
		placed_bag = null
		if bag_slot and bag.get_parent() == bag_slot:
			bag_slot.remove_child(bag)
		if player.has_method("pick_up"):
			player.pick_up(bag)

		if current_delivery_order and current_delivery_order.delivery_stage == "WAITING_COURIER":
			current_delivery_order.delivery_stage = "PREPARING"
			current_delivery_order.state = Order.State.IN_PROGRESS
			var om = OrderManager.get_instance()
			if om:
				om.order_updated.emit(current_delivery_order)

		current_delivery_order = null
		_update_status()
		_show_feedback(player, "🛍️ Retirou saco de delivery do balcão.")
		return

	# 2. Se o jogador estiver segurando um Saco de Delivery: coloca no balcão
	if held != null and (held is DeliveryBagScript or held.name.begins_with("DeliveryBag") or str(held.get("item_id")) == "delivery_bag"):
		if placed_bag != null:
			_show_feedback(player, "⚠️ Área de coleta ocupada! Aguarde o motoboy retirar o pedido atual.")
			return

		if held.has_method("is_empty") and held.is_empty():
			_show_feedback(player, "⚠️ O saco de delivery está vazio! Embale o hambúrguer, batata e bebida.")
			return

		if player.has_method("take_held_item"):
			var bag_item = player.take_held_item()
			if bag_item:
				_place_bag_on_station(bag_item)
				_show_feedback(player, "🛵 Saco de Delivery pronto! Aguardando motoboy.")

func _place_bag_on_station(bag_item: Node3D) -> void:
	placed_bag = bag_item
	if not bag_slot:
		bag_slot = get_node_or_null("BagSlot")

	var prev_parent = bag_item.get_parent()
	if prev_parent:
		prev_parent.remove_child(bag_item)

	if bag_slot:
		bag_slot.add_child(bag_item)
		bag_item.position = Vector3.ZERO
		bag_item.rotation = Vector3.ZERO
	else:
		add_child(bag_item)
		bag_item.position = Vector3(0, 0.1, 0)

	if bag_item.get("collision_shape"):
		bag_item.collision_shape.disabled = true

	# Vincula ao pedido de delivery ativo mais antigo em preparo ou aceito
	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	if om:
		var target_order: Order = null
		for o in om.get_active_orders():
			if o.source_type == "DELIVERY" and (o.delivery_stage == "PREPARING" or o.delivery_stage == "NEW_RECEIVED"):
				target_order = o
				break

		if not target_order:
			# Se não houver, pega qualquer delivery ativo
			for o in om.get_active_orders():
				if o.source_type == "DELIVERY":
					target_order = o
					break

		if target_order:
			current_delivery_order = target_order
			om.mark_delivery_ready_for_pickup(target_order, bag_item)

	_update_status()
	bag_placed.emit(bag_item, current_delivery_order)

	# Aciona a chegada do Motoboy
	_summon_delivery_courier()

func _summon_delivery_courier() -> void:
	if not courier_scene:
		return

	var parent_node: Node = get_parent() if get_parent() else (get_tree().current_scene if get_tree() else null)
	if not parent_node and is_inside_tree() and get_tree() and get_tree().root:
		parent_node = get_tree().root

	if parent_node:
		var courier = courier_scene.instantiate()
		courier.target_pickup_station = self
		parent_node.add_child(courier)
		if courier.is_inside_tree():
			courier.global_position = Vector3(2.4, 0.0, 13.5)
		else:
			courier.position = Vector3(2.4, 0.0, 13.5)

func courier_pickup_bag(courier: Node) -> Node3D:
	if not placed_bag:
		return null

	var bag = placed_bag
	placed_bag = null
	if bag.get_parent():
		bag.get_parent().remove_child(bag)

	var order = current_delivery_order
	current_delivery_order = null

	if order:
		order.delivery_stage = "IN_DELIVERY"
		var om = OrderManager.get_instance()
		if om:
			om.order_updated.emit(order)

	_update_status()
	bag_collected.emit(bag, courier)
	return bag

func _update_status() -> void:
	if not status_label:
		status_label = get_node_or_null("StatusLabel")
	if not status_label:
		return

	if placed_bag != null:
		var order_id_str = "#%03d" % current_delivery_order.id if current_delivery_order else ""
		status_label.text = "🛵 EXPEDIÇÃO DELIVERY\n✨ Pedido %s Pronto\n⏳ Aguardando Motoboy" % order_id_str
		status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		status_label.text = "🛵 EXPEDIÇÃO DELIVERY\n[Coloque o Saco Pronto]"
		status_label.modulate = Color(1.0, 0.85, 0.3, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
