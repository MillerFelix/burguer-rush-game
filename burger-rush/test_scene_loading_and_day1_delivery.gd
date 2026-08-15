extends SceneTree

# Teste e validação de carregamento limpo da cena e delivery ativo desde o Dia 1

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE CARREGAMENTO DE CENA E DELIVERY DESDE O DIA 1")
	print("================================================================================")

	# 1. TESTE DE CARREGAMENTO DA CENA PRINCIPAL (SEM NÓS DUPLICADOS)
	print("\n--- 1. Carregamento da Cena Principal (main.tscn) ---")
	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# Verifica se existe EXATAMENTE 1 DeliveryStation na cena
	var delivery_stations = main_scene.find_children("DeliveryStation*", "", true, false)
	assert(delivery_stations.size() == 1, "Deve existir exatamente 1 DeliveryStation na cena (encontradas: %d)" % delivery_stations.size())
	print("  [PASS] main.tscn carregada perfeitamente com exatamente 1 DeliveryStation!")

	var clock = main_scene.get_node("GameClock") as GameClock
	GameClock.instance = clock
	var order_mgr = main_scene.get_node("OrderManager") as OrderManager
	OrderManager.instance = order_mgr
	var economy = main_scene.get_node("EconomyManager") as EconomyManager
	EconomyManager.instance = economy
	var prog_mgr = main_scene.get_node("ProgressionManager") as ProgressionManager
	ProgressionManager.instance = prog_mgr
	var deliv_station = main_scene.get_node("DeliveryStation")
	var deliv_mgr = main_scene.get_node("DeliveryQueueManager")
	var player = main_scene.get_node("Player") as Node3D

	# -------------------------------------------------------------------------
	# 2. TESTE DE DESBLOQUEIO DE DELIVERY DESDE O DIA 1 (SEM BLOQUEIO POR DIA 7)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação de Delivery Desbloqueado desde o Dia 1 ---")
	assert(clock.day_number == 1, "O jogo deve iniciar no Dia 1")
	assert(prog_mgr.is_unlocked("delivery") == true, "Delivery deve estar desbloqueado desde o Dia 1 (sem exigência de Dia 7)")
	print("  [PASS] Delivery confirmado como desbloqueado e ativo no Dia 1!")

	# -------------------------------------------------------------------------
	# 3. TESTE DE CURVA DE FREQUÊNCIA DE DELIVERY AO LONGO DO DIA
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Frequência de Delivery em Diferentes Horários ---")
	var int_1030 = deliv_mgr.call("_calculate_interval_for_time", 10.5)
	var int_1200 = deliv_mgr.call("_calculate_interval_for_time", 12.0)
	var int_1500 = deliv_mgr.call("_calculate_interval_for_time", 15.0)
	var int_1800 = deliv_mgr.call("_calculate_interval_for_time", 18.0)
	var int_2000 = deliv_mgr.call("_calculate_interval_for_time", 20.0)
	var int_2130 = deliv_mgr.call("_calculate_interval_for_time", 21.5)

	print("  10:30 (Manhã):     %.1fs de intervalo" % int_1030)
	print("  12:00 (Almoço):    %.1fs de intervalo" % int_1200)
	print("  15:00 (Tarde):     %.1fs de intervalo" % int_1500)
	print("  18:00 (Fim Tarde): %.1fs de intervalo" % int_1800)
	print("  20:00 (Noite):     %.1fs de intervalo" % int_2000)
	print("  21:30 (Noite):     %.1fs de intervalo" % int_2130)

	assert(int_1030 > 0.0 and int_1200 > 0.0 and int_1500 > 0.0 and int_2000 > 0.0, "Delivery deve estar habilitado em todos os horários")
	# A noite (20:00) deve ter intervalo menor / maior frequência que a manhã (10:30)
	assert(int_2000 < int_1030, "Intervalo noturno deve ser menor que o matutino (maior fluxo de delivery à noite)")
	print("  [PASS] Curva de delivery válida para todos os horários com maior intensidade à noite!")

	# -------------------------------------------------------------------------
	# 4. TESTE DE ATENDIMENTO E INTERAÇÃO COM [E] NA JANELA DE DELIVERY
	# -------------------------------------------------------------------------
	print("\n--- 4. Teste de Atendimento de Carro pela Janela com [E] ---")
	deliv_mgr.set("auto_spawn", false)
	var car = deliv_mgr.call("spawn_car")
	assert(car != null, "Carro de delivery deve ser instanciado no Dia 1")

	for i in range(120):
		car._physics_process(0.1)

	assert(car.get("current_state") == 3, "Carro deve aguardar pedido na janela")

	# Jogador atende o pedido
	var order = car.call("take_order", player) as Order
	assert(order != null and order.source_type == "DELIVERY", "Pedido de delivery criado com sucesso")

	# Simula entrega dos itens
	for it in order.items:
		var p_id = it["product_id"]
		for q in range(it["quantity"]):
			order.register_product_delivered(p_id)

	order_mgr.complete_order(order)
	car.call("finish_and_leave")
	assert(car.get("current_state") == 5, "Carro deve finalizar e sair")
	print("  [PASS] Atendimento completo de delivery via [E] testado sem qualquer erro!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS TESTES DE CARREGAMENTO E DELIVERY DESDE O DIA 1 FORAM APROVADOS!")
	print("================================================================================")
	quit(0)
