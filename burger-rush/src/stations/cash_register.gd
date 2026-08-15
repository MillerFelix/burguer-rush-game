class_name CashRegister
extends StaticBody3D

static var instance: CashRegister = null

@onready var status_label: Label3D = $StatusLabel
@onready var screen_label: Label3D = $Model/ScreenLabel
@onready var interaction_slot: Node3D = $InteractionSlot

var queue_customers: Array[Customer] = []
var register_balance: float = 0.0

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	_update_visual_status()

static func get_instance() -> CashRegister:
	return instance

# Posições da fila física (alinhadas ao balcão X = 1.8 e estendendo em +Z)
func get_slot_position(index: int) -> Vector3:
	var base_x = global_position.x if is_inside_tree() else position.x
	var base_z = global_position.z if is_inside_tree() else position.z
	var slot_z = base_z + 1.2 + (index * 1.2)
	return Vector3(base_x, 0.0, slot_z)

func join_queue(customer: Customer) -> Vector3:
	# Remove ocorrências inválidas antes de adicionar
	_clean_queue()
	if not queue_customers.has(customer):
		queue_customers.append(customer)

	var slot_idx = queue_customers.find(customer)
	_update_visual_status()
	return get_slot_position(slot_idx)

func leave_queue(customer: Customer) -> void:
	if queue_customers.has(customer):
		queue_customers.erase(customer)
		advance_queue()
	_update_visual_status()

func advance_queue() -> void:
	_clean_queue()
	for i in range(queue_customers.size()):
		var c = queue_customers[i]
		if is_instance_valid(c):
			var new_slot_pos = get_slot_position(i)
			c.update_queue_slot(new_slot_pos, i == 0)
	_update_visual_status()

func _clean_queue() -> void:
	queue_customers = queue_customers.filter(func(c): return is_instance_valid(c) and c.state in [Customer.State.GOING_TO_QUEUE, Customer.State.IN_QUEUE, Customer.State.PAYING])

func get_first_in_queue() -> Customer:
	_clean_queue()
	if queue_customers.is_empty():
		return null
	return queue_customers[0]

func can_checkout() -> bool:
	var first = get_first_in_queue()
	return first != null and (first.state == Customer.State.IN_QUEUE or first.state == Customer.State.PAYING)

func get_interaction_prompt(player: Node = null) -> String:
	var first = get_first_in_queue()
	if first != null:
		var price = first.current_order.total_price if first.current_order else 15.0
		return "E — Receber Pagamento do Caixa (R$ %.2f)" % price
	return "Caixa Registradora (Aguardando clientes)"

func interact(player: Node3D) -> void:
	var first = get_first_in_queue()
	if not first:
		_show_feedback(player, "Nenhum cliente na fila do caixa no momento.")
		return

	if first.state == Customer.State.GOING_TO_QUEUE:
		_show_feedback(player, "Aguarde o cliente chegar ao balcão do caixa.")
		return

	process_checkout(player)

func has_customers_in_queue() -> bool:
	_clean_queue()
	return not queue_customers.is_empty()

func process_checkout(player: Node3D = null) -> void:
	var cust = get_first_in_queue()
	if not cust:
		return

	var order_price = cust.current_order.total_price if cust.current_order else 15.0
	register_balance += order_price

	# Processa pagamento financeiro e XP
	var economy = EconomyManager.get_instance()
	if not economy and is_inside_tree():
		economy = get_tree().root.find_child("EconomyManager", true, false) as EconomyManager
	if economy:
		economy.add_money(order_price)
		economy.register_sale(order_price)

	var prog = ProgressionManager.get_instance()
	if prog:
		prog.register_xp(25)

	# Se houver pedido ativo, finaliza o pedido para não constar mais no sistema
	if cust.current_order and is_instance_valid(cust.current_order):
		cust.current_order.state = Order.State.COMPLETED
		var order_mgr = OrderManager.get_instance()
		if not order_mgr and is_inside_tree():
			order_mgr = get_tree().root.find_child("OrderManager", true, false) as OrderManager
		if order_mgr:
			order_mgr.complete_order(cust.current_order)

	_show_feedback(player, "💰 Pagamento de R$ %.2f recebido no caixa!" % order_price)

	# Notifica o cliente para sair do restaurante (e libera acompanhantes do grupo)
	cust.on_payment_completed()
	queue_customers.erase(cust)

	# Avança o restante da fila
	advance_queue()
	_update_visual_status()

func _show_feedback(player: Node3D, msg: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_feedback"):
			hud.show_feedback(msg)

func _update_visual_status() -> void:
	_clean_queue()
	if status_label:
		if queue_customers.is_empty():
			status_label.text = "💰 CAIXA REGISTRADORA\n[Disponível]"
			status_label.modulate = Color(0.3, 0.9, 0.4)
		else:
			var first = queue_customers[0]
			var price = first.current_order.total_price if (first and first.current_order) else 15.0
			status_label.text = "💰 CAIXA — %d na fila\nCobrar: R$ %.2f" % [queue_customers.size(), price]
			status_label.modulate = Color(1.0, 0.85, 0.2)

	if screen_label:
		if queue_customers.is_empty():
			screen_label.text = "BURGER RUSH\nR$ 0.00"
		else:
			var first = queue_customers[0]
			var price = first.current_order.total_price if (first and first.current_order) else 15.0
			screen_label.text = "TOTAL:\nR$ %.2f" % price
