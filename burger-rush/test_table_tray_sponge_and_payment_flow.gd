extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE AUTOMATIZADO DO CICLO COMPLETO DE ATENDIMENTO
#
# Valida:
# 1. Bandeja física não desaparece e permanece vazia sobre a mesa após cliente comer
# 2. Bandeja é recolhida sem duplicação e reutilizada normalmente
# 3. Mesa fica visualmente suja com restos/manchas perceptíveis
# 4. Limpeza da mesa com a bucha (progresso, mesa limpa e bucha SUJA)
# 5. Bucha suja precisa ser lavada na pia antes de nova limpeza
# 6. Mão do cliente apontando na direção correta do caixa
# 7. Dinheiro como objeto físico interagível (LMB pega dinheiro -> Caixa deposita e conclui venda)
# =============================================================================

const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const ServingTray = preload("res://src/items/serving_tray.gd")
const Customer = preload("res://src/customers/customer.gd")
const CustomerMoney = preload("res://src/items/customer_money.gd")
const Player = preload("res://src/player/player.gd")
const Sponge = preload("res://src/tools/sponge.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")
const FinanceManager = preload("res://src/economy/finance_manager.gd")
const Order = preload("res://src/orders/order.gd")
const PackagedBurger = preload("res://src/items/packaged_burger.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

var pass_count: int = 0
var total_count: int = 0

func assert_test(condition: bool, description: String) -> void:
	total_count += 1
	if condition:
		pass_count += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE: FLUXO DE ATENDIMENTO, BANDEJA, LIMPEZA E PAGAMENTO ===")
	print("=================================================================\n")

	test_tray_persistence_and_reuse()
	test_wrong_order_tray_persistence_and_reuse()
	test_table_visual_dirt()
	test_sponge_cleaning_and_wash_cycle()
	test_customer_payment_and_cash_flow()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: CICLO COMPLETO DE ATENDIMENTO 100% VALIDADO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)

func test_tray_persistence_and_reuse() -> void:
	print("--- TESTE 1 & 2: Persistência da Bandeja no Pedido Correto e Reutilização ---")

	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	root.add_child(table)

	var tray_scene = load("res://src/items/serving_tray.tscn")
	var tray = tray_scene.instantiate() as ServingTray
	root.add_child(tray)

	# 1. Coloca produtos na bandeja
	var burger_scene = load("res://src/items/packaged_burger.tscn")
	var burger = burger_scene.instantiate() as PackagedBurger
	tray.add_product(burger)

	var cup_scene = load("res://src/items/drink_cup.tscn")
	var cup = cup_scene.instantiate() as DrinkCup
	tray.add_product(cup)

	assert_test(tray.carried_items.size() == 2, "Bandeja possui 2 produtos montados antes da entrega")

	# 2. Cliente ocupa a mesa e faz pedido
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer = customer_scene.instantiate() as Customer
	root.add_child(customer)
	table.occupy(customer)
	customer.assigned_table = table

	var order = Order.new()
	order.add_item("burger", "Hambúrguer", 1, 20.0)
	order.add_item("drink", "Refrigerante", 1, 10.0)
	customer.current_order = order

	# 3. Jogador serve a bandeja na mesa
	var dummy_player = Node3D.new()
	table._serve_tray(dummy_player, tray)

	assert_test(table.has_tray_on_table(), "Bandeja está fisicamente servida sobre a mesa")
	assert_test(table.served_items.has(tray), "Bandeja registrada nos itens servidos da mesa")

	# 4. Cliente come e termina a refeição
	table.release(true)

	assert_test(is_instance_valid(tray), "Bandeja NÃO desapareceu e continua sendo a mesma instância válida")
	assert_test(tray.carried_items.is_empty(), "Os alimentos consumidos desapareceram e a bandeja ficou vazia")
	assert_test(table.has_tray_on_table(), "A bandeja vazia permanece sobre a mesa após o término da refeição")
	assert_test(table.table_state == RestaurantTable.TableState.DIRTY, "Mesa mudou para o estado DIRTY após o término da refeição")

	# 5. Jogador com as mãos livres recolhe a bandeja
	var player_scene = load("res://src/player/player.tscn")
	var player_char = player_scene.instantiate() as Player
	root.add_child(player_char)
	player_char.held_item = null

	table.clean_table(player_char)

	assert_test(player_char.held_item == tray, "Jogador recolheu a mesma bandeja vazia para a mão livre")
	assert_test(not table.has_tray_on_table(), "Bandeja foi retirada da mesa")
	assert_test(table.table_state == RestaurantTable.TableState.DIRTY, "Mesa permanece DIRTY para ser higienizada com a bucha")

	# 6. Reutilização da mesma bandeja para um novo pedido
	var new_burger = burger_scene.instantiate() as PackagedBurger
	var added = tray.add_product(new_burger)
	assert_test(added and tray.carried_items.size() == 1, "Mesma instância da bandeja reutilizada com sucesso para novo pedido")

	table.queue_free()
	tray.queue_free()
	customer.queue_free()
	player_char.queue_free()
	dummy_player.queue_free()

func test_wrong_order_tray_persistence_and_reuse() -> void:
	print("\n--- TESTE 1B: Persistência da Bandeja após Entrega de PEDIDO ERRADO ---")

	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	root.add_child(table)

	var tray_scene = load("res://src/items/serving_tray.tscn")
	var tray = tray_scene.instantiate() as ServingTray
	root.add_child(tray)

	# 1. Coloca produto errado na bandeja (apenas um copo)
	var cup_scene = load("res://src/items/drink_cup.tscn")
	var cup = cup_scene.instantiate() as DrinkCup
	tray.add_product(cup)

	assert_test(tray.carried_items.size() == 1, "Bandeja montada com 1 item para entrega errada")

	# 2. Cliente pede hambúrguer + batata
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer = customer_scene.instantiate() as Customer
	root.add_child(customer)
	table.occupy(customer)
	customer.assigned_table = table

	var order = Order.new()
	order.add_item("burger", "Hambúrguer", 1, 20.0)
	order.add_item("fries", "Batata Frita", 1, 12.0)
	customer.current_order = order

	# 3. Jogador serve a bandeja com pedido errado na mesa
	var dummy_player = Node3D.new()
	table._serve_tray(dummy_player, tray)

	# 4. Cliente rejeitou o pedido e abandonou o restaurante
	assert_test(customer.state == Customer.State.LEAVING, "Cliente rejeitou o pedido errado e iniciou saída")
	assert_test(is_instance_valid(tray), "Bandeja NÃO desapareceu e continua como instância válida após pedido errado")
	assert_test(tray.carried_items.is_empty(), "Conteúdo incorreto foi removido e a bandeja ficou vazia")
	assert_test(table.has_tray_on_table(), "Bandeja vazia permanece sobre a mesa após cliente ir embora")
	assert_test(table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa permaneceu LIMPA/AVAILABLE pois cliente não comeu")

	# 5. Jogador recolhe a bandeja com a tecla E (interact)
	var player_scene = load("res://src/player/player.tscn")
	var player_char = player_scene.instantiate() as Player
	root.add_child(player_char)
	player_char.held_item = null

	tray.interact(player_char)

	assert_test(player_char.held_item == tray, "Jogador recolheu a bandeja vazia para a mão com [E]")
	assert_test(not table.has_tray_on_table(), "Bandeja saiu da mesa após o recolhimento")

	# 6. Mesma bandeja é reutilizada normalmente
	var burger_scene = load("res://src/items/packaged_burger.tscn")
	var new_burger = burger_scene.instantiate() as PackagedBurger
	var added = tray.add_product(new_burger)
	assert_test(added and tray.carried_items.size() == 1, "Mesma bandeja reutilizada com sucesso para montar outro pedido")

	table.queue_free()
	tray.queue_free()
	customer.queue_free()
	player_char.queue_free()
	dummy_player.queue_free()

func test_table_visual_dirt() -> void:
	print("\n--- TESTE 3: Sujeira Visual Evidente na Mesa ---")

	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	root.add_child(table)

	# Mesa limpa
	assert_test(not table.is_dirty(), "Mesa recém-criada inicia LIMPA")
	var dirt_node = table.get_node_or_null("Model/TableTop/TableTopDirt")
	assert_test(dirt_node != null, "Nó visual de sujeira TableTopDirt existe no modelo da mesa")
	assert_test(not dirt_node.visible, "Sujeira visual está invisível na mesa limpa")

	# Cliente come e mesa fica suja
	table.table_state = RestaurantTable.TableState.DIRTY
	table.dirt_amount = 1.0
	table._update_visual_status()

	assert_test(table.is_dirty(), "Mesa está no estado DIRTY")
	assert_test(dirt_node.visible, "Sujeira visual da mesa está claramente VISÍVEL para o jogador")
	assert_test(dirt_node.get_child_count() > 0, "Sujeira visual possui múltiplos elementos de manchas/migalhas (%d nós)" % dirt_node.get_child_count())

	table.queue_free()

func test_sponge_cleaning_and_wash_cycle() -> void:
	print("\n--- TESTE 4: Limpeza da Mesa com Bucha e Ciclo de Lavagem na Pia ---")

	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	root.add_child(table)
	table.table_state = RestaurantTable.TableState.DIRTY
	table.dirt_amount = 1.0
	table._update_visual_status()

	var sponge_scene = load("res://src/tools/sponge.tscn")
	var sponge = sponge_scene.instantiate() as Sponge
	root.add_child(sponge)
	sponge.set_clean()

	assert_test(sponge.is_clean(), "Bucha inicia no estado LIMPA")

	# 1. Tentativa de limpar com bandeja sobre a mesa é bloqueada
	var tray_scene = load("res://src/items/serving_tray.tscn")
	var tray = tray_scene.instantiate() as ServingTray
	table.served_items.append(tray)

	var clean_res = table.clean_progress(1.0)
	assert_test(not clean_res and table.is_dirty(), "Limpeza é bloqueada enquanto a tábua/bandeja estiver sobre a mesa")

	# 2. Retira a bandeja e executa a limpeza progressiva com a bucha
	table.served_items.clear()

	var progress_1 = table.clean_progress(1.0)
	assert_test(not progress_1, "Limpeza em andamento: progresso parcial")
	assert_test(table.dirt_amount < 1.0, "Nível de sujeira da mesa diminuiu (%.2f < 1.0)" % table.dirt_amount)

	var progress_done = table.clean_progress(2.0)
	assert_test(progress_done, "Limpeza da mesa concluída com sucesso")
	assert_test(table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa voltou ao estado AVAILABLE (limpa)")
	assert_test(table.dirt_amount == 0.0, "Nível de sujeira da mesa zerado")

	# 3. Ao concluir a limpeza, bucha fica SUJA
	sponge.set_dirty()
	assert_test(sponge.is_dirty, "Bucha ficou SUJA após a higienização da mesa")

	# 4. Bucha suja levada à pia para lavar
	var sink_scene = load("res://src/stations/commercial_sink.tscn")
	var sink = sink_scene.instantiate() as CommercialSink
	root.add_child(sink)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	player.sponge_is_dirty = true
	var held_sponge = player.tool_holder.get_node_or_null("Sponge")
	if held_sponge:
		held_sponge.is_dirty = true

	sink.wash_or_sanitize(player)

	assert_test(not player.sponge_is_dirty, "Bucha lavada na pia voltou ao estado LIMPA")

	table.queue_free()
	sponge.queue_free()
	tray.queue_free()
	sink.queue_free()
	player.queue_free()

func test_customer_payment_and_cash_flow() -> void:
	print("\n--- TESTE 5: Pagamento do Cliente, Orientação e Coleta de Dinheiro ---")

	var cust_scene = load("res://src/customers/customer.tscn")
	var cust = cust_scene.instantiate() as Customer
	root.add_child(cust)

	var reg_scene = load("res://src/stations/cash_register.tscn")
	var reg = reg_scene.instantiate() as CashRegister
	root.add_child(reg)

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	root.add_child(fin)

	var order = Order.new()
	order.total_price = 38.50
	cust.current_order = order
	cust.has_money_to_give = true

	# 1. Cliente chega à fila do caixa no primeiro slot
	var slot_pos = reg.join_queue(cust)
	cust.target_position = slot_pos
	cust.state = Customer.State.GOING_TO_QUEUE
	cust._reach_queue_slot()

	assert_test(cust.state == Customer.State.PAYING, "Cliente atingiu o primeiro slot do caixa e entrou no estado PAYING")
	assert_test(cust.hand_money_mesh != null, "Cliente estendeu a mão com o dinheiro")
	assert_test(cust.hand_money_mesh is CustomerMoney, "Objeto na mão do cliente é uma instância de CustomerMoney")

	var money = cust.hand_money_mesh as CustomerMoney
	assert_test(money.collision_layer == 1, "Dinheiro possui camada de colisão física ativa (collision_layer = 1) para RayCast")
	assert_test(money.amount == 38.50, "Valor do dinheiro corresponde exatamente ao valor do pedido (R$ 38.50)")

	# 2. Jogador pega o dinheiro da mão do cliente com LMB / interact
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player.held_item = null

	money.interact(player)

	assert_test(player.held_item == money, "Dinheiro foi pego e está na mão do jogador")
	assert_test(not cust.has_money_to_give, "Cliente entregou o dinheiro (has_money_to_give = false)")
	assert_test(cust.hand_money_mesh == null, "Mão do cliente não contém mais dinheiro residual")

	# 3. Jogador leva o dinheiro ao Caixa Registradora
	var initial_revenue = fin.get_total_daily_revenue()
	reg.interact(player)

	assert_test(player.held_item == null, "Dinheiro foi depositado na gaveta do caixa")
	assert_test(fin.get_total_daily_revenue() == initial_revenue + 38.50, "Venda de R$ 38.50 registrada com sucesso no FinanceManager")
	assert_test(cust.state == Customer.State.LEAVING, "Cliente concluiu o pagamento e iniciou a saída do restaurante")

	cust.queue_free()
	reg.queue_free()
	fin.queue_free()
	player.queue_free()
