extends SceneTree

var passed_tests: int = 0
var total_tests: int = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE: RANDOMIZAÇÃO CONTROLADA DE DEMANDA E PEDIDOS ===")
	print("=================================================================\n")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var clock = load("res://src/time/game_clock.gd").new()
	root.add_child(clock)
	clock._ready()

	var order_mgr = load("res://src/orders/order_manager.gd").new()
	root.add_child(order_mgr)
	order_mgr._ready()

	var spawner = load("res://src/customers/customer_spawner.gd").new()
	root.add_child(spawner)
	spawner._ready()

	var drive_mgr = load("res://src/customers/delivery_queue_manager.gd").new()
	root.add_child(drive_mgr)
	drive_mgr._ready()
	drive_mgr._ready()

	# =========================================================================
	# TESTE 1: CLIENTES FÍSICOS SÃO O FOCO PRINCIPAL E MAIORIA
	# =========================================================================
	print("\n--- TESTE 1: Clientes Físicos como Maioria e Foco Principal ---")
	var total_physical_demand = 0
	var total_drivethru_demand = 0
	var total_delivery_demand = 0

	for d in range(1, 8):
		clock.day_number = d
		spawner._update_day_intensity()
		drive_mgr._init_day_demand()
		order_mgr._init_day_delivery_demand()

		total_physical_demand += spawner.target_daily_customers
		total_drivethru_demand += drive_mgr.daily_scheduled_cars.size()
		total_delivery_demand += order_mgr.daily_scheduled_deliveries.size()

	var total_overall = total_physical_demand + total_drivethru_demand + total_delivery_demand
	var physical_pct = float(total_physical_demand) / float(max(1, total_overall)) * 100.0

	print("  -> Estatísticas Semanais (7 Dias):")
	print("     - Clientes Físicos (Salão): %d (%.1f%%)" % [total_physical_demand, physical_pct])
	print("     - Drive-Thru: %d" % total_drivethru_demand)
	print("     - Delivery: %d" % total_delivery_demand)

	assert_test(physical_pct >= 70.0, "Clientes físicos representam a esmagadora maioria da demanda (%.1f%% >= 70%%)" % physical_pct)
	assert_test(total_drivethru_demand <= 25, "Drive-thru permanece com fluxo contido ao longo da semana (%d <= 25)" % total_drivethru_demand)
	assert_test(total_delivery_demand <= 20, "Delivery permanece com fluxo contido ao longo da semana (%d <= 20)" % total_delivery_demand)

	# =========================================================================
	# TESTE 2 & 3: DRIVE-THRU E DELIVERY RAROS, OCASIONAIS E COM HORÁRIOS VARIADOS
	# =========================================================================
	print("\n--- TESTE 2 & 3: Drive-Thru e Delivery Ocasionais e com Horários Variados ---")
	var has_day_with_zero_or_one_drive = false
	var has_day_with_zero_or_one_deliv = false
	var distinct_drive_times: Array[float] = []
	var distinct_deliv_times: Array[float] = []

	for d in range(1, 15):
		clock.day_number = d
		drive_mgr._init_day_demand()
		order_mgr._init_day_delivery_demand()

		var dt_count = drive_mgr.daily_scheduled_cars.size()
		var dl_count = order_mgr.daily_scheduled_deliveries.size()

		assert_test(dt_count <= 4, "Dia %d: Drive-thru limitado a no máximo 4 carros (atual: %d)" % [d, dt_count])
		assert_test(dl_count <= 3, "Dia %d: Delivery limitado a no máximo 3 pedidos (atual: %d)" % [d, dl_count])

		if dt_count <= 1:
			has_day_with_zero_or_one_drive = true
		if dl_count <= 1:
			has_day_with_zero_or_one_deliv = true

		for t in drive_mgr.daily_scheduled_cars:
			distinct_drive_times.append(snapped(t, 0.01))
		for t in order_mgr.daily_scheduled_deliveries:
			distinct_deliv_times.append(snapped(t, 0.01))

	assert_test(has_day_with_zero_or_one_drive, "Existem dias com pouco ou nenhum Drive-Thru (0 a 1 carro)")
	assert_test(has_day_with_zero_or_one_deliv, "Existem dias com pouco ou nenhum Delivery (0 a 1 pedido)")
	assert_test(distinct_drive_times.size() > 0, "Drive-thru gerou horários dinâmicos")
	assert_test(distinct_deliv_times.size() > 0, "Delivery gerou horários dinâmicos")

	# =========================================================================
	# TESTE 4 & 5: VARIAÇÃO DE DEMANDA POR DIA E INTERVALOS NÃO-FIXOS
	# =========================================================================
	print("\n--- TESTE 4 & 5: Variação por Dia e Intervalos Orgânicos com Jitter ---")
	var target_history: Array[int] = []
	for d in range(1, 10):
		clock.day_number = d
		spawner._update_day_intensity()
		target_history.append(spawner.target_daily_customers)

	var all_targets_identical = true
	for i in range(1, target_history.size()):
		if target_history[i] != target_history[0]:
			all_targets_identical = false
			break

	assert_test(not all_targets_identical, "Demanda de clientes físicos varia entre os dias (%s)" % str(target_history))

	# Testa se intervalos de chegada variam com jitter
	var int1 = spawner._calculate_interval_for_time(12.5)
	var int2 = spawner._calculate_interval_for_time(12.5)
	var int3 = spawner._calculate_interval_for_time(12.5)
	var has_interval_jitter = (int1 != int2 or int2 != int3 or int1 != int3)
	assert_test(has_interval_jitter, "Intervalos entre clientes possuem variação orgânica (Jitter: %.1fs, %.1fs, %.1fs)" % [int1, int2, int3])

	# =========================================================================
	# TESTE 6 & 7: DISTRIBUIÇÃO DO TAMANHO DOS PEDIDOS (60% P, 30% M, 10% G)
	# =========================================================================
	print("\n--- TESTE 6 & 7: Distribuição de Tamanho dos Pedidos ---")
	var small_count = 0
	var medium_count = 0
	var large_count = 0
	var max_items_found = 0

	for _i in range(100):
		var test_order = order_mgr.create_delivery_order()
		var item_count = 0
		for it in test_order.items:
			item_count += it.get("quantity", 1)

		max_items_found = max(max_items_found, item_count)

		if item_count <= 2:
			small_count += 1
		elif item_count <= 3:
			medium_count += 1
		else:
			large_count += 1

		order_mgr.active_orders.erase(test_order)

	print("  -> Distribuição de 100 Pedidos de Delivery:")
	print("     - Pequenos (1 a 2 itens): %d%%" % small_count)
	print("     - Médios (3 itens): %d%%" % medium_count)
	print("     - Grandes (4+ itens): %d%%" % large_count)
	print("     - Maior pedido gerado: %d itens" % max_items_found)

	assert_test(small_count >= 45, "Pedidos pequenos são a maioria (%d%% >= 45%%)" % small_count)
	assert_test(medium_count >= 20, "Pedidos médios são frequentes (%d%% >= 20%%)" % medium_count)
	assert_test(large_count <= 20, "Pedidos grandes são raros (%d%% <= 20%%)" % large_count)
	assert_test(max_items_found <= 6, "Nenhum pedido absurdo foi gerado (máximo encontrado: %d itens <= 6)" % max_items_found)

	# =========================================================================
	# TESTE 8: LIMITES DE SEGURANÇA E CONCORRÊNCIA
	# =========================================================================
	print("\n--- TESTE 8: Limites de Segurança ---")
	assert_test(spawner._get_max_concurrent_customers(12.0) <= 4, "Capacidade máxima de clientes simultâneos no salão é segura (<= 4)")
	assert_test(drive_mgr.max_queue_size <= 2, "Fila máxima de carros no Drive-thru é contida (<= 2)")

	# =========================================================================
	# TESTE 9: DRIVE-THRU ORDER SIZING (delivery_car.gd)
	# =========================================================================
	print("\n--- TESTE 9: Tamanho dos Pedidos do Drive-Thru ---")
	var car_scene = load("res://src/environment/delivery_car.tscn")
	var car: DeliveryCar = car_scene.instantiate() as DeliveryCar
	root.add_child(car)

	var dt_small = 0
	var dt_medium = 0
	var dt_large = 0

	for _i in range(100):
		car.current_order = null
		var ord = car.take_order(null)
		if ord:
			var burger_count = 0
			for it in ord.items:
				if it.get("product_id", "").begins_with("burger"):
					burger_count += it.get("quantity", 1)
			if burger_count == 1:
				dt_small += 1
			elif burger_count == 2:
				dt_medium += 1
			else:
				dt_large += 1
			order_mgr.active_orders.erase(ord)

	print("  -> Distribuição de 100 Pedidos do Drive-Thru:")
	print("     - 1 Lanche (Pequeno): %d%%" % dt_small)
	print("     - 2 Lanches (Médio): %d%%" % dt_medium)
	print("     - 3 Lanches (Grande): %d%%" % dt_large)

	assert_test(dt_small >= 50, "Drive-thru: 1 lanche/combo é a grande maioria (%d%% >= 50%%)" % dt_small)
	assert_test(dt_medium >= 15, "Drive-thru: 2 lanches são moderados (%d%% >= 15%%)" % dt_medium)
	assert_test(dt_large <= 15, "Drive-thru: 3 lanches são raros (%d%% <= 15%%)" % dt_large)

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: RANDOMIZAÇÃO CONTROLADA DE DEMANDA 100% VALIDADA! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)
