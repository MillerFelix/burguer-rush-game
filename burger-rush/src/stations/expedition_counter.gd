class_name ExpeditionCounter
extends StaticBody3D

@onready var slot: Node3D = $TraySlot
@onready var status_label: Label3D = $StatusLabel

var placed_item: Node3D = null

func _ready() -> void:
	var order_mgr = OrderManager.get_instance()
	if order_mgr:
		order_mgr.order_created.connect(_on_orders_updated)
		order_mgr.order_completed.connect(_on_orders_updated)
		order_mgr.order_cancelled.connect(_on_orders_updated)
	_update_status()

func get_interaction_prompt(player: Node = null) -> String:
	if placed_item:
		if player and player.get("held_item") != null:
			return ""
		var name_str = placed_item.get_display_name() if placed_item.has_method("get_display_name") else "Item"
		return "E — Pegar %s da Expedição" % name_str

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var is_valid = held is OrderTray or held.get("item_type") == "final_product"
		if is_valid:
			var name_str = held.get_display_name() if held.has_method("get_display_name") else "Item"
			return "E — Colocar %s na Expedição" % name_str

	return ""

func interact(player: Node3D) -> void:
	if placed_item:
		if player.get("held_item") == null and player.has_method("pick_up"):
			var item = placed_item
			placed_item = null
			slot.remove_child(item)
			player.pick_up(item)
			_update_status()
		return

	if player.get("held_item") != null:
		var held = player.get("held_item")
		var is_valid = held is OrderTray or held.get("item_type") == "final_product"
		if is_valid and player.has_method("take_held_item"):
			var item = player.take_held_item()
			if item:
				placed_item = item
				slot.add_child(item)
				item.position = Vector3.ZERO
				item.rotation = Vector3.ZERO
				if item.has_method("on_picked_up"):
					item.on_picked_up()
				elif item.get("collision_shape"):
					item.collision_shape.disabled = true
				_update_status()

func _on_orders_updated(_order: Order = null) -> void:
	_update_status()

func _update_status() -> void:
	if not status_label:
		return

	var order_mgr = OrderManager.get_instance()
	var count = order_mgr.get_active_orders().size() if order_mgr else 0

	if placed_item:
		var name_str = placed_item.get_display_name() if placed_item.has_method("get_display_name") else "Item"
		status_label.text = "📦 EXPEDIÇÃO\n✨ Pronto: %s\n(%d pedidos pendentes)" % [name_str, count]
		status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		status_label.text = "📦 EXPEDIÇÃO\n%d Pedidos Ativos" % count
		status_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
