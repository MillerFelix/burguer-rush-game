class_name KitchenOrderTV
extends StaticBody3D

const PowerManager = preload("res://src/core/power_manager.gd")

@onready var screen_label: Label3D = $Model/ScreenLabel
@onready var header_label: Label3D = $Model/HeaderLabel
@onready var power_led: MeshInstance3D = $Model/PowerLED

var poll_timer: float = 0.0
var is_turned_on: bool = true
const BASE_KW: float = 0.25

func _ready() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "kitchen_tv", "Monitor de Pedidos da Cozinha", BASE_KW, is_turned_on)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)
	_connect_order_signals()
	_update_display()

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func on_power_state_changed(main_power_on: bool) -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.set_appliance_state(self, is_turned_on and main_power_on)
	_update_display()

func get_interaction_prompt(player: Node = null) -> String:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	if is_turned_on and has_power:
		return "📺 [E] Desligar TV de Pedidos"
	else:
		return "📺 [E] Ligar TV de Pedidos"

func interact_equipment(player: Node3D) -> void:
	toggle_tv(player)

func interact(player: Node3D) -> void:
	toggle_tv(player)

func toggle_tv(player: Node3D = null) -> void:
	is_turned_on = not is_turned_on
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	if pm:
		pm.set_appliance_state(self, is_turned_on and has_power)

	_update_display()

	if player:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			if is_turned_on and has_power:
				hud.show_temporary_feedback("📺 TV de Pedidos Ligada")
			elif is_turned_on:
				hud.show_temporary_feedback("⚠️ TV Ligada (Aguardando energia no quadro geral)")
			else:
				hud.show_temporary_feedback("⚪ TV de Pedidos Desligada")

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
	if not header_label:
		header_label = get_node_or_null("Model/HeaderLabel") as Label3D
	if not power_led:
		power_led = get_node_or_null("Model/PowerLED") as MeshInstance3D

	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	var is_active = is_turned_on and has_power

	if power_led:
		var mat = power_led.get_surface_override_material(0)
		if not mat:
			mat = StandardMaterial3D.new()
			power_led.set_surface_override_material(0, mat)
		if mat is StandardMaterial3D:
			if is_active:
				mat.albedo_color = Color(0.15, 0.95, 0.25, 1.0)
				mat.emission = Color(0.15, 0.95, 0.25, 1.0)
				mat.emission_enabled = true
			else:
				mat.albedo_color = Color(0.95, 0.15, 0.15, 1.0)
				mat.emission = Color(0.95, 0.15, 0.15, 1.0)
				mat.emission_enabled = true

	if not is_active:
		if screen_label:
			screen_label.text = ""
		if header_label:
			header_label.text = ""
		return

	if header_label:
		header_label.text = "📋 PEDIDOS EM ANDAMENTO"

	_connect_order_signals()
	var order_mgr = _get_order_manager()
	if not order_mgr:
		if screen_label:
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
