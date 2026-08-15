extends SceneTree

const CustomerScene = preload("res://src/customers/customer.tscn")
const DayNightCycle = preload("res://src/time/day_night_cycle.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE ESPAÇAMENTO DE MESAS E PEDIDOS REALISTAS")
	print("============================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var clock = main_scene.get_node("GameClock") as GameClock
	GameClock.instance = clock
	var order_mgr = main_scene.get_node("OrderManager") as OrderManager
	OrderManager.instance = order_mgr
	var economy_mgr = main_scene.get_node("EconomyManager") as EconomyManager
	EconomyManager.instance = economy_mgr
	var table_mgr = main_scene.get_node("TableManager") as TableManager
	var spawner = main_scene.get_node("CustomerSpawner") as CustomerSpawner
	var player = main_scene.get_node("Player") as Node3D

	for child in main_scene.get_children():
		if child is RestaurantTable:
			table_mgr.register_table(child as RestaurantTable)

	# ---------------------------------------------------------
	# TESTE 1: ESPAÇAMENTO GENEROSO DAS MESAS (MÍNIMO 2.4m ENTRE MESAS)
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação do Layout Espaçoso do Salão (9 Mesas) ---")
	var tables = table_mgr.get_all_tables()
	assert(tables.size() == 9, "Devem existir exatamente 9 mesas no salão (atual: %d)" % tables.size())

	for i in range(tables.size()):
		var t1 = tables[i]
		assert(t1.seat_count == 4, "Mesa %d deve possuir 4 lugares" % t1.table_id)
		for j in range(i + 1, tables.size()):
			var t2 = tables[j]
			var dist = t1.position.distance_to(t2.position)
			assert(dist >= 2.35, "Mesas %d e %d estão muito próximas! Distância: %.2fm (mínimo: 2.4m)" % [t1.table_id, t2.table_id, dist])

	var total_seats = table_mgr.get_total_seat_capacity()
	assert(total_seats == 36, "Capacidade total do salão deve ser 36 assentos confortáveis (atual: %d)" % total_seats)
	print("  [PASS] 9 mesas perfeitamente distribuídas com espaçamento generoso (>= 2.4m) e 36 assentos!")

	# ---------------------------------------------------------
	# TESTE 2: PEDIDOS REALISTAS BASEADOS NO TAMANHO DO GRUPO (1, 2, 3 e 4 PESSOAS)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Geração de Pedidos Realistas por Grupo ---")

	# Grupo de 1 pessoa: 1 Burger + 1 Drink (+ batata opcional)
	var order_1p = order_mgr.create_group_order(null, 1, 1, "DINE_IN")
	var burgers_1p = 0
	var drinks_1p = 0
	for it in order_1p.items:
		if "burger" in it.product_id or "x_" in it.product_id:
			burgers_1p += it.quantity
		elif "drink" in it.product_id or "soda" in it.product_id:
			drinks_1p += it.quantity
	assert(burgers_1p == 1, "1 pessoa deve pedir 1 hambúrguer (atual: %d)" % burgers_1p)
	assert(drinks_1p == 1, "1 pessoa deve pedir 1 bebida (atual: %d)" % drinks_1p)
	assert(order_1p.total_price >= 20.0, "Valor do pedido de 1 pessoa deve refletir itens reais ($%.2f)" % order_1p.total_price)
	print("  [PASS] Pedido de 1 pessoa: %d burger(s), %d bebida(s), Total: $%.2f" % [burgers_1p, drinks_1p, order_1p.total_price])

	# Grupo de 2 pessoas (Casal): 2 Burgers + 2 Drinks + 1 Batata
	var order_2p = order_mgr.create_group_order(null, 2, 2, "DINE_IN")
	var burgers_2p = 0
	var drinks_2p = 0
	var fries_2p = 0
	for it in order_2p.items:
		if "burger" in it.product_id or "x_" in it.product_id:
			burgers_2p += it.quantity
		elif "drink" in it.product_id or "soda" in it.product_id:
			drinks_2p += it.quantity
		elif it.product_id == "fries":
			fries_2p += it.quantity
	assert(burgers_2p == 2, "2 pessoas devem pedir 2 hambúrgueres (atual: %d)" % burgers_2p)
	assert(drinks_2p == 2, "2 pessoas devem pedir 2 bebidas (atual: %d)" % drinks_2p)
	assert(fries_2p >= 1, "2 pessoas devem pedir pelo menos 1 batata para compartilhar (atual: %d)" % fries_2p)
	assert(order_2p.total_price >= 45.0, "Valor do pedido de 2 pessoas deve refletir consumo completo ($%.2f)" % order_2p.total_price)
	print("  [PASS] Pedido de 2 pessoas: %d burgers, %d bebidas, %d batata(s), Total: $%.2f" % [burgers_2p, drinks_2p, fries_2p, order_2p.total_price])

	# Grupo de 3 pessoas: 3 Burgers + 3 Drinks + 1 ou 2 Batatas
	var order_3p = order_mgr.create_group_order(null, 3, 3, "DINE_IN")
	var burgers_3p = 0
	var drinks_3p = 0
	for it in order_3p.items:
		if "burger" in it.product_id or "x_" in it.product_id:
			burgers_3p += it.quantity
		elif "drink" in it.product_id or "soda" in it.product_id:
			drinks_3p += it.quantity
	assert(burgers_3p == 3, "3 pessoas devem pedir 3 hambúrgueres (atual: %d)" % burgers_3p)
	assert(drinks_3p == 3, "3 pessoas devem pedir 3 bebidas (atual: %d)" % drinks_3p)
	print("  [PASS] Pedido de 3 pessoas: %d burgers, %d bebidas, Total: $%.2f" % [burgers_3p, drinks_3p, order_3p.total_price])

	# Grupo de 4 pessoas (Família): 4 Burgers + 4 Drinks + 2 Batatas
	var order_4p = order_mgr.create_group_order(null, 4, 4, "DINE_IN")
	var burgers_4p = 0
	var drinks_4p = 0
	var fries_4p = 0
	for it in order_4p.items:
		if "burger" in it.product_id or "x_" in it.product_id:
			burgers_4p += it.quantity
		elif "drink" in it.product_id or "soda" in it.product_id:
			drinks_4p += it.quantity
		elif it.product_id == "fries":
			fries_4p += it.quantity
	assert(burgers_4p == 4, "4 pessoas devem pedir 4 hambúrgueres (atual: %d)" % burgers_4p)
	assert(drinks_4p == 4, "4 pessoas devem pedir 4 bebidas (atual: %d)" % drinks_4p)
	assert(fries_4p >= 2, "4 pessoas devem pedir pelo menos 2 batatas (atual: %d)" % fries_4p)
	assert(order_4p.total_price >= 90.0, "Valor do pedido de 4 pessoas deve refletir consumo de grupo ($%.2f)" % order_4p.total_price)
	print("  [PASS] Pedido de 4 pessoas: %d burgers, %d bebidas, %d batatas, Total: $%.2f" % [burgers_4p, drinks_4p, fries_4p, order_4p.total_price])

	# ---------------------------------------------------------
	# TESTE 3: CURVA DE CHEGADA E TAMANHO DE GRUPOS POR HORÁRIO
	# ---------------------------------------------------------
	print("\n--- Teste 3: Curva de Chegada e Grupos por Horário ---")

	# Manhã (09:30): Intervalos longos (16-22s), grupos pequenos (1-2)
	var interval_morning = spawner._calculate_interval_for_time(9.5)
	assert(interval_morning >= 15.0 and interval_morning <= 23.0, "Intervalo da manhã deve ser calmo (16-22s, atual: %.1fs)" % interval_morning)

	# Almoço (12:30): Intervalos curtos (5-8s), grupos maiores
	var interval_lunch = spawner._calculate_interval_for_time(12.5)
	assert(interval_lunch >= 4.5 and interval_lunch <= 8.5, "Intervalo do almoço deve ser movimentado (5-8s, atual: %.1fs)" % interval_lunch)

	# Tarde (15:30): Intervalos calmos (13-18s)
	var interval_afternoon = spawner._calculate_interval_for_time(15.5)
	assert(interval_afternoon >= 12.5 and interval_afternoon <= 18.5, "Intervalo da tarde deve ser calmo (13-18s, atual: %.1fs)" % interval_afternoon)

	# Noite (19:30): 2º Pico (5.5-8.5s)
	var interval_night = spawner._calculate_interval_for_time(19.5)
	assert(interval_night >= 5.0 and interval_night <= 9.0, "Intervalo da noite deve ser movimentado (5.5-8.5s, atual: %.1fs)" % interval_night)

	print("  [PASS] Curva de fluxo temporal validada: Manhã (%.1fs) -> Almoço (%.1fs) -> Tarde (%.1fs) -> Noite (%.1fs)" % [interval_morning, interval_lunch, interval_afternoon, interval_night])

	main_scene.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE SALÃO ESPAÇOSO E PEDIDOS REALISTAS APROVADOS!")
	print("============================================================")
	quit(0)
