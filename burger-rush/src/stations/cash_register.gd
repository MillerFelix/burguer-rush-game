class_name CashRegister
extends StaticBody3D

# =============================================================================
# CAIXA REGISTRADORA FÍSICA DO RESTAURANTE BURGER RUSH
#
# Controla a fila física de clientes presenciais, gaveta mecânica abrível com
# interior físico, depósito seguro do dinheiro e integração financeira.
# =============================================================================

const FinanceManager = preload("res://src/economy/finance_manager.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")
const ProgressionManager = preload("res://src/progression/progression_manager.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const Customer = preload("res://src/customers/customer.gd")
const CustomerMoney = preload("res://src/items/customer_money.gd")

static var instance: CashRegister = null

@onready var status_label: Label3D = get_node_or_null("StatusLabel")
@onready var screen_label: Label3D = get_node_or_null("Model/ScreenLabel")
@onready var interaction_slot: Node3D = get_node_or_null("InteractionSlot")
@onready var cash_drawer: Node3D = get_node_or_null("Model/CashDrawer")
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioPlayer")

var queue_customers: Array[Customer] = []
var register_balance: float = 0.0
var is_drawer_open: bool = false
var _drawer_tween: Tween = null

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	if not audio_player:
		audio_player = get_node_or_null("AudioPlayer")
		if not audio_player:
			audio_player = AudioStreamPlayer3D.new()
			audio_player.name = "AudioPlayer"
			audio_player.unit_size = 4.0
			audio_player.max_distance = 18.0
			audio_player.volume_db = -3.0
			add_child(audio_player)

	if cash_drawer:
		cash_drawer.position.z = 0.0

	_update_visual_status()

static func get_instance() -> CashRegister:
	return instance

# Posições da fila física (posicionada à direita da caixa registradora X = 2.30, Z começando em 0.75m perto do balcão)
func get_slot_position(index: int) -> Vector3:
	var queue_x = 2.30
	var slot_z = 0.75 + (index * 1.00)
	return Vector3(queue_x, 0.0, slot_z)

func join_queue(customer: Customer) -> Vector3:
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
	queue_customers = queue_customers.filter(func(c): return is_instance_valid(c) and c.state != Customer.State.LEAVING and c.state != Customer.State.FINISHED)

func get_first_in_queue() -> Customer:
	_clean_queue()
	if queue_customers.is_empty():
		return null
	return queue_customers[0]

func can_checkout() -> bool:
	var first = get_first_in_queue()
	return first != null and (first.state == Customer.State.IN_QUEUE or first.state == Customer.State.PAYING)

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held.get("is_customer_deposit_money") == true or held is CustomerMoney:
			var price = held.amount if "amount" in held else 15.0
			return "E — Abrir Gaveta e Depositar Pagamento (R$ %.2f)" % price

	var first = get_first_in_queue()
	if first != null:
		if first.state == Customer.State.PAYING:
			return "Pegue o dinheiro na mão do cliente para depositar"
		var price = first.current_order.total_price if first.current_order else 15.0
		return "Caixa Registradora (Aguardando cliente R$ %.2f)" % price
	return "Caixa Registradora (Aguardando clientes)"

func interact(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item") if player.get("held_item") != null else null
	if held and (held.get("is_customer_deposit_money") == true or held is CustomerMoney):
		deposit_payment(player, held)
		return

	var first = get_first_in_queue()
	if not first:
		_show_feedback(player, "Nenhum cliente na fila do caixa no momento.")
		return

	if first.state == Customer.State.GOING_TO_QUEUE:
		_show_feedback(player, "Aguarde o cliente chegar ao balcão do caixa.")
		return

	if first.state in [Customer.State.IN_QUEUE, Customer.State.PAYING]:
		_show_feedback(player, "Pegue o dinheiro estendido na mão do cliente.")

func deposit_payment(player: Node3D, money_item: Node) -> void:
	if not money_item:
		return

	var amount: float = money_item.get("amount") if "amount" in money_item else 15.0
	var cust = money_item.get("customer_ref") if "customer_ref" in money_item else get_first_in_queue()

	# Remove o dinheiro da mão do jogador
	if player and player.has_method("take_held_item"):
		player.take_held_item()

	# 1. Abre a gaveta e toca o som mecânico de caixa registradora
	open_drawer()

	# 2. Processa o registro financeiro na economia existente
	register_balance += amount
	var fin = FinanceManager.get_instance()
	if not fin and is_inside_tree():
		fin = get_tree().root.find_child("FinanceManager", true, false) as FinanceManager

	var channel = "dine_in"
	if cust and cust.get("current_order") != null and cust.current_order.source_type:
		channel = cust.current_order.source_type.to_lower()

	if fin:
		fin.record_sale(amount, channel, "Venda no Caixa")
	else:
		var economy = EconomyManager.get_instance()
		if not economy and is_inside_tree():
			economy = get_tree().root.find_child("EconomyManager", true, false) as EconomyManager
		if economy:
			economy.add_money(amount, "Venda no Caixa")

	var prog = ProgressionManager.get_instance()
	if prog:
		prog.register_xp(25)

	# Se houver pedido ativo, finaliza o pedido
	if cust and cust.get("current_order") != null and is_instance_valid(cust.current_order):
		cust.current_order.state = Order.State.COMPLETED
		var order_mgr = OrderManager.get_instance()
		if not order_mgr and is_inside_tree():
			order_mgr = get_tree().root.find_child("OrderManager", true, false) as OrderManager
		if order_mgr:
			order_mgr.complete_order(cust.current_order)

	# 3. Toca som positivo de dinheiro recebido
	_play_sound("payment_success_cash")

	_show_feedback(player, "💰 Pagamento de R$ %.2f depositado no caixa!" % amount)

	# 4. Destrói o item de dinheiro físico recebido
	money_item.queue_free()

	# 5. Notifica o cliente que o pagamento foi concluído e libera a saída
	if cust and is_instance_valid(cust):
		cust.on_payment_completed()
		queue_customers.erase(cust)

	# 6. Fecha a gaveta suavemente após breve momento
	if is_inside_tree() and get_tree():
		var close_timer = get_tree().create_timer(0.6)
		close_timer.timeout.connect(close_drawer)
	else:
		close_drawer()

	# 7. Avança o próximo cliente da fila
	advance_queue()
	_update_visual_status()

func open_drawer() -> void:
	is_drawer_open = true
	_play_sound("register_drawer_open")

	if cash_drawer:
		if is_inside_tree():
			if _drawer_tween and _drawer_tween.is_running():
				_drawer_tween.kill()
			_drawer_tween = create_tween()
			_drawer_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# A caixa registradora está rotacionada em 180° Y, portanto abrir para fora em direção ao operador move em +Z local
			_drawer_tween.tween_property(cash_drawer, "position:z", 0.28, 0.22)
		else:
			cash_drawer.position.z = 0.28

func close_drawer() -> void:
	is_drawer_open = false
	if cash_drawer:
		if is_inside_tree():
			if _drawer_tween and _drawer_tween.is_running():
				_drawer_tween.kill()
			_drawer_tween = create_tween()
			_drawer_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_drawer_tween.tween_property(cash_drawer, "position:z", 0.0, 0.20)
		else:
			cash_drawer.position.z = 0.0

func _play_sound(sound_id: String) -> void:
	if not audio_player:
		audio_player = get_node_or_null("AudioPlayer")
	if audio_player and audio_player.is_inside_tree():
		audio_player.stream = SoundSynthesizer.get_stream(sound_id)
		audio_player.play()

func has_customers_in_queue() -> bool:
	_clean_queue()
	return not queue_customers.is_empty()

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
