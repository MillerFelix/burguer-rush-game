class_name KitchenOrderTV
extends Node3D

@onready var screen_label: Label3D = $Model/ScreenLabel
@onready var header_label: Label3D = $Model/HeaderLabel
@onready var power_led: MeshInstance3D = $Model/PowerLED

var poll_timer: float = 0.0

func _ready() -> void:
	_connect_order_signals()
	_update_display()

func _process(delta: float) -> void:
	poll_timer += delta
	if poll_timer >= 0.4:
		poll_timer = 0.0
		_update_display()

func _connect_order_signals() -> void:
	var order_mgr = _get_order_manager()
	if order_mgr:
		if order_mgr.has_signal("order_created") and not order_mgr.order_created.is_connected(_on_order_changed):
			order_mgr.order_created.connect(_on_order_changed)
		if order_mgr.has_signal("order_updated") and not order_mgr.order_updated.is_connected(_on_order_changed):
			order_mgr.order_updated.connect(_on_order_changed)
		if order_mgr.has_signal("order_completed") and not order_mgr.order_completed.is_connected(_on_order_changed):
			order_mgr.order_completed.connect(_on_order_changed)
		if order_mgr.has_signal("order_cancelled") and not order_mgr.order_cancelled.is_connected(_on_order_changed):
			order_mgr.order_cancelled.connect(_on_order_changed)

func _get_order_manager() -> OrderManager:
	var order_mgr = OrderManager.instance
	if not order_mgr and is_inside_tree() and get_tree() and get_tree().root:
		order_mgr = get_tree().root.find_child("OrderManager", true, false) as OrderManager
	if not order_mgr:
		var curr = self.get_parent()
		while curr:
			if curr.has_node("OrderManager"):
				order_mgr = curr.get_node("OrderManager") as OrderManager
				break
			curr = curr.get_parent()
	return order_mgr

func _on_order_changed(_order = null) -> void:
	_update_display()

func _update_display() -> void:
	if not screen_label:
		screen_label = get_node_or_null("Model/ScreenLabel") as Label3D
	if not screen_label:
		return

	_connect_order_signals()
	var order_mgr = _get_order_manager()
	if not order_mgr:
		screen_label.text = "✓ COZINHA LIVRE\nNenhum pedido pendente no momento."
		screen_label.modulate = Color(0.4, 1.0, 0.6, 0.9)
		return

	var active_orders = order_mgr.get_active_orders()
	# Filtra apenas pedidos ativos que precisam de atenção da cozinha
	var pending_orders: Array = []
	for o in active_orders:
		if o and is_instance_valid(o) and (o.state == Order.State.RECEIVED or o.state == Order.State.WAITING or o.state == Order.State.IN_PROGRESS):
			if not o.is_all_delivered():
				pending_orders.append(o)

	if pending_orders.is_empty():
		screen_label.text = "✓ COZINHA LIVRE\nNenhum pedido pendente no momento."
		screen_label.modulate = Color(0.4, 1.0, 0.6, 0.9)
		return

	screen_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var display_lines: Array[String] = []

	# Exibe de forma ultra limpa e rápida os pedidos ativos (máximo 4 simultâneos)
	var max_display = min(4, pending_orders.size())
	for i in range(max_display):
		var order = pending_orders[i]
		var origin_str = "Mesa %d" % order.table_id if order.source_type != "DELIVERY" else "Drive-Thru"

		var status_str = "NOVO"
		if order.state == Order.State.IN_PROGRESS:
			status_str = "EM ANDAMENTO"

		var pending_item_count = 0
		for item in order.items:
			var qty = item.get("quantity", 1)
			var deliv = item.get("delivered_quantity", 0)
			pending_item_count += max(0, qty - deliv)

		var item_desc = "%d item" % pending_item_count if pending_item_count == 1 else "%d itens" % pending_item_count
		display_lines.append("#%02d (%s) — %s (%s)" % [order.id, origin_str, status_str, item_desc])

	if pending_orders.size() > max_display:
		display_lines.append("+ %d pedido(s) aguardando" % (pending_orders.size() - max_display))

	screen_label.text = "\n".join(display_lines)
