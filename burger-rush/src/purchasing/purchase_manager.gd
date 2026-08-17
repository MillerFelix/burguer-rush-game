class_name PurchaseManager
extends Node

# =============================================================================
# BURGER RUSH - CENTRAL DE COMPRAS E MERCADO DE INSUMOS
#
# Gerencia:
# 1. Catálogo centralizado de produtos com Preço Base e Mercado Volátil diário (-15% a +20%)
# 2. Disponibilidade diária dinâmica e notícias contextuais de mercado
# 3. Três fornecedores: Rápido (⚡), Normal (🚚), Atacado (📦)
# 4. Carrinho de compras integrado com limite físico de estoque
# 5. Fluxo de entrega temporizada (com suporte ao evento de transporte +25%)
# 6. Chegada de caixas físicas no pallet da ReceivingArea
# =============================================================================

signal cart_updated()
signal market_updated()
signal order_confirmed(order_data: Dictionary)
signal delivery_arrived(order_data: Dictionary)
signal delivery_progress_updated(active_deliveries: Array[Dictionary])

static var instance: PurchaseManager = null

enum SupplierType {
	FAST,
	NORMAL,
	WHOLESALE
}

const SUPPLIERS = {
	"FAST": {
		"id": "FAST",
		"name": "Fornecedor Rápido (Expresso)",
		"icon": "⚡",
		"base_time_sec": 210.0, # 3.5 min
		"price_multiplier": 1.15, # +15% taxa emergencial
		"description": "Entrega expressa prioritária. Ideal para reposição emergencial."
	},
	"NORMAL": {
		"id": "NORMAL",
		"name": "Fornecedor Normal (Padrão)",
		"icon": "🚚",
		"base_time_sec": 360.0, # 6.0 min
		"price_multiplier": 1.00, # Preço padrão
		"description": "Preço equilibrado e prazo intermediário. Fornecedor padrão do dia a dia."
	},
	"WHOLESALE": {
		"id": "WHOLESALE",
		"name": "Fornecedor Atacado (Econômico)",
		"icon": "📦",
		"base_time_sec": 570.0, # 9.5 min
		"price_multiplier": 0.88, # -12% desconto por volume
		"description": "Melhores preços para compras maiores. Entrega mais lenta."
	}
}

# Catálogo centralizado de produtos para compra
var catalog: Dictionary = {}

# Carrinho atual: { item_id: { "item_id": id, "name": name, "quantity": qty, "unit_price": price } }
var cart: Dictionary = {}
var selected_supplier_id: String = "NORMAL"

# Entregas ativas e histórico
var active_deliveries: Array[Dictionary] = []
var order_history: Array[Dictionary] = []
var next_order_id: int = 1001

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_initialize_catalog()
	roll_daily_market()

	var clock = _get_game_clock()
	if clock:
		if not clock.day_started.is_connected(_on_day_started):
			clock.day_started.connect(_on_day_started)

static func get_instance() -> PurchaseManager:
	return instance

func _get_game_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _on_day_started(_day_number: int) -> void:
	roll_daily_market()

func _initialize_catalog() -> void:
	catalog.clear()

	# 1. INGREDIENTES
	_register_catalog_item("bread_bottom", "Base do Pão", "ingredients", 1.00, 30)
	_register_catalog_item("bread_top", "Tampa do Pão", "ingredients", 1.00, 30)
	_register_catalog_item("patty_beef", "Hambúrguer de Carne", "ingredients", 5.00, 25)
	_register_catalog_item("patty_chicken", "Hambúrguer de Frango", "ingredients", 4.50, 25)
	_register_catalog_item("cheese_mozzarella", "Queijo Muçarela", "ingredients", 2.00, 25)
	_register_catalog_item("cheese_cheddar", "Queijo Cheddar", "ingredients", 2.20, 25)
	_register_catalog_item("cheese_prato", "Queijo Prato", "ingredients", 2.00, 25)
	_register_catalog_item("lettuce", "Alface", "ingredients", 1.50, 20)
	_register_catalog_item("tomato", "Tomate", "ingredients", 1.50, 20)
	_register_catalog_item("red_onion", "Cebola Roxa", "ingredients", 1.20, 20)
	_register_catalog_item("onion", "Cebola Comum", "ingredients", 1.00, 20)
	_register_catalog_item("pickle", "Picles", "ingredients", 1.50, 20)
	_register_catalog_item("bacon", "Bacon", "ingredients", 3.00, 20)
	_register_catalog_item("egg", "Ovo", "ingredients", 1.50, 20)

	# 2. BATATAS
	_register_catalog_item("potato_raw", "Saco de Batata", "fries", 1.00, 25)

	# 3. BEBIDAS (CILINDROS RESERVA - MÁXIMO 1 UNIDADE RESERVA)
	_register_catalog_item("cylinder_cola", "Cilindro Cola", "beverages", 15.00, 1)
	_register_catalog_item("cylinder_cola_zero", "Cilindro Cola Zero", "beverages", 15.00, 1)
	_register_catalog_item("cylinder_soda", "Cilindro Soda", "beverages", 15.00, 1)
	_register_catalog_item("cylinder_citrus", "Cilindro Citrus", "beverages", 15.00, 1)

	# BEBIDAS (POLPAS DE FRUTA)
	_register_catalog_item("pulp_orange", "Polpa de Laranja", "beverages", 2.50, 10)
	_register_catalog_item("pulp_grape", "Polpa de Uva", "beverages", 2.50, 10)
	_register_catalog_item("pulp_strawberry", "Polpa de Morango", "beverages", 2.80, 10)

	# 4. EMBALAGENS
	_register_catalog_item("burger_box", "Caixa de Lanche", "supplies", 0.50, 30)
	_register_catalog_item("potato_box", "Embalagem de Batata", "supplies", 0.30, 30)
	_register_catalog_item("cup_empty", "Copo", "supplies", 0.20, 40)
	_register_catalog_item("delivery_bag", "Saco de Delivery", "supplies", 0.40, 30)

func _register_catalog_item(
	id: String,
	display_name: String,
	category: String,
	base_price: float,
	default_market_qty: int
) -> void:
	catalog[id] = {
		"id": id,
		"display_name": display_name,
		"category": category,
		"base_price": base_price,
		"market_price": base_price,
		"market_variation_pct": 0.0,
		"market_available_qty": default_market_qty,
		"default_qty": default_market_qty,
		"market_news": ""
	}

## Rola a variação diária de preços (-15% a +20%) e disponibilidade
func roll_daily_market() -> void:
	var rand = RandomNumberGenerator.new()
	rand.randomize()

	for id in catalog.keys():
		var item = catalog[id]
		var base = item["base_price"] as float
		var default_qty = item["default_qty"] as int

		# Variação moderada de -15% a +20%
		var variation = rand.randf_range(-0.15, 0.20)
		# Arredonda para múltiplos de 2% para visual limpo
		variation = snappedf(variation, 0.02)
		var current_price = maxf(0.10, snappedf(base * (1.0 + variation), 0.05))

		item["market_price"] = current_price
		item["market_variation_pct"] = variation

		# Disponibilidade do dia
		if default_qty > 1:
			var qty_mult = rand.randf_range(0.60, 1.25)
			item["market_available_qty"] = maxi(5, int(default_qty * qty_mult))
		else:
			item["market_available_qty"] = 1

		# Notícias contextuais para variações significativas
		var news = ""
		if variation >= 0.12:
			if item["category"] == "ingredients":
				news = "Alta demanda regional elevou os preços de %s." % item["display_name"]
			elif item["category"] == "fries":
				news = "Problemas na colheita reduziram temporariamente a oferta de batatas."
			elif item["category"] == "beverages":
				news = "Aumento nos custos de envase impactou as bebidas hoje."
			else:
				news = "Escassez temporária de matéria-prima no mercado."
		elif variation <= -0.10:
			news = "Excedente de produção resultou em ótimos descontos para %s!" % item["display_name"]

		item["market_news"] = news

	market_updated.emit()

func get_catalog_items() -> Dictionary:
	return catalog

func get_catalog_item(item_id: String) -> Dictionary:
	return catalog.get(item_id, {})

# =============================================================================
# GESTÃO DO CARRINHO DE COMPRAS
# =============================================================================

func get_cart() -> Dictionary:
	return cart

func get_selected_supplier() -> Dictionary:
	return SUPPLIERS.get(selected_supplier_id, SUPPLIERS["NORMAL"])

func set_selected_supplier(supplier_id: String) -> void:
	if SUPPLIERS.has(supplier_id):
		selected_supplier_id = supplier_id
		cart_updated.emit()

## Retorna a quantidade máxima que o jogador ainda pode comprar deste item
func get_available_to_buy(item_id: String) -> int:
	var inv = InventoryManager.get_instance()
	if not inv:
		return 0

	var max_cap = inv.get_max_capacity(item_id)
	var current_stock = inv.get_stock(item_id)
	var in_cart_qty = cart.get(item_id, {}).get("quantity", 0)

	# Espaço livre físico no restaurante
	var physical_space = max_cap - current_stock - in_cart_qty
	if physical_space <= 0:
		return 0

	# Disponibilidade do mercado no dia
	var item_cat = get_catalog_item(item_id)
	var market_avail = item_cat.get("market_available_qty", 99) - in_cart_qty

	return maxi(0, mini(physical_space, market_avail))

func add_to_cart(item_id: String, quantity_to_add: int = 1) -> Dictionary:
	if quantity_to_add <= 0:
		return {"success": false, "message": "Quantidade deve ser maior que zero!"}

	var item = get_catalog_item(item_id)
	if item.is_empty():
		return {"success": false, "message": "Produto não encontrado no catálogo!"}

	var available = get_available_to_buy(item_id)
	if available <= 0:
		var inv = InventoryManager.get_instance()
		var max_cap = inv.get_max_capacity(item_id) if inv else 0
		return {
			"success": false,
			"message": "Estoque de %s atingiu a capacidade máxima (%d un)!" % [item["display_name"], max_cap]
		}

	var add_amount = mini(quantity_to_add, available)
	if not cart.has(item_id):
		cart[item_id] = {
			"item_id": item_id,
			"display_name": item["display_name"],
			"category": item["category"],
			"quantity": 0,
			"unit_price": item["market_price"]
		}

	cart[item_id]["quantity"] += add_amount
	cart_updated.emit()

	return {
		"success": true,
		"message": "%dx %s adicionado(s) ao carrinho." % [add_amount, item["display_name"]],
		"amount_added": add_amount
	}

func set_cart_quantity(item_id: String, new_qty: int) -> Dictionary:
	if new_qty <= 0:
		remove_from_cart(item_id)
		return {"success": true, "message": "Item removido do carrinho."}

	if not cart.has(item_id):
		return add_to_cart(item_id, new_qty)

	var current_in_cart = cart[item_id]["quantity"]
	var delta = new_qty - current_in_cart
	if delta > 0:
		return add_to_cart(item_id, delta)
	else:
		cart[item_id]["quantity"] = new_qty
		cart_updated.emit()
		return {"success": true, "message": "Quantidade atualizada."}

func remove_from_cart(item_id: String) -> void:
	if cart.has(item_id):
		cart.erase(item_id)
		cart_updated.emit()

func clear_cart() -> void:
	cart.clear()
	cart_updated.emit()

func get_cart_subtotal() -> float:
	var total = 0.0
	for it in cart.values():
		total += it["quantity"] * it["unit_price"]
	return total

func get_cart_total() -> float:
	var subtotal = get_cart_subtotal()
	var sup = get_selected_supplier()
	var mult = sup.get("price_multiplier", 1.0) as float
	return subtotal * mult

func get_cart_delivery_time_sec() -> float:
	var sup = get_selected_supplier()
	var base_time = sup.get("base_time_sec", 300.0) as float

	# Multiplicador do evento diário (ex: +25% em problemas no transporte)
	var event_mgr = DailyEventManager.get_instance()
	var event_mult = event_mgr.get_delivery_time_multiplier() if event_mgr else 1.0

	return base_time * event_mult

# =============================================================================
# CONFIRMAÇÃO DO PEDIDO E PROCESSAMENTO DE ENTREGAS
# =============================================================================

func confirm_order(supplier_id: String = "") -> Dictionary:
	if supplier_id != "":
		set_selected_supplier(supplier_id)

	if cart.is_empty():
		return {"success": false, "message": "O carrinho está vazio!"}

	var total_cost = get_cart_total()
	var economy = EconomyManager.get_instance()
	if not economy:
		return {"success": false, "message": "Sistema econômico indisponível!"}

	if economy.get_money() < total_cost:
		return {
			"success": false,
			"message": "Dinheiro insuficiente! Necessário: $%.2f (Saldo: $%.2f)" % [total_cost, economy.get_money()]
		}

	var sup = get_selected_supplier()
	var delivery_time = get_cart_delivery_time_sec()

	# 1. Debita o dinheiro imediatamente
	var order_desc = "Pedido #%d (%s): %d itens" % [next_order_id, sup["name"], cart.size()]
	if not economy.spend_money(total_cost, order_desc):
		return {"success": false, "message": "Falha ao processar pagamento!"}

	# 2. Registra a entrega pendente
	var items_copy: Array[Dictionary] = []
	for k in cart.keys():
		items_copy.append(cart[k].duplicate(true))

	var clock = _get_game_clock()
	var time_str = clock.get_formatted_time() if clock else "12:00"
	var day_num = clock.day_number if clock else 1

	var new_order = {
		"order_id": next_order_id,
		"supplier_id": sup["id"],
		"supplier_name": sup["name"],
		"items": items_copy,
		"total_cost": total_cost,
		"order_time": time_str,
		"order_day": day_num,
		"time_remaining_sec": delivery_time,
		"total_duration_sec": delivery_time,
		"status": "in_transit"
	}
	next_order_id += 1

	active_deliveries.append(new_order)
	order_history.append(new_order)

	# 3. Limpa o carrinho
	cart.clear()
	cart_updated.emit()
	order_confirmed.emit(new_order)

	var mins = int(delivery_time / 60.0)
	var secs = int(delivery_time) % 60
	return {
		"success": true,
		"message": "✅ Pedido confirmado com sucesso! Previsão de chegada: %dm %02ds no Pallet Externo." % [mins, secs],
		"order": new_order
	}

func _process(delta: float) -> void:
	if active_deliveries.is_empty():
		return

	var finished_orders: Array[Dictionary] = []

	for order in active_deliveries:
		order["time_remaining_sec"] -= delta
		if order["time_remaining_sec"] <= 0.0:
			finished_orders.append(order)

	if not active_deliveries.is_empty():
		delivery_progress_updated.emit(active_deliveries)

	for finished in finished_orders:
		active_deliveries.erase(finished)
		_handle_delivery_arrival(finished)

func _handle_delivery_arrival(order: Dictionary) -> void:
	order["status"] = "arrived"
	print("[PURCHASE] 🚚 Entrega do Pedido #%d (%s) chegou ao Pallet Externo!" % [order["order_id"], order["supplier_name"]])

	# 1. Gera as caixas físicas na ReceivingArea (Pallet de Madeira)
	var recv = ReceivingArea.get_instance()
	if recv:
		for item in order["items"]:
			recv.add_pending_delivery(item["item_id"], item["display_name"], item["quantity"])

	# 2. Emite sinal e aviso
	delivery_arrived.emit(order)

func get_active_deliveries() -> Array[Dictionary]:
	return active_deliveries

func get_order_history() -> Array[Dictionary]:
	return order_history
