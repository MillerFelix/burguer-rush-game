extends SceneTree

# Teste e validação da Área Externa de Delivery, Fila de Carros (Drive-Thru) e Cenário dos Fundos

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DA ÁREA EXTERNA DE DELIVERY E FILA DE CARROS (DRIVE-THRU)")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var clock = main_scene.get_node("GameClock") as GameClock
	GameClock.instance = clock
	var order_mgr = main_scene.get_node("OrderManager") as OrderManager
	OrderManager.instance = order_mgr
	var economy = main_scene.get_node("EconomyManager") as EconomyManager
	EconomyManager.instance = economy
	var deliv_station = main_scene.get_node("DeliveryStation")
	var deliv_mgr = main_scene.get_node("DeliveryQueueManager")
	var player = main_scene.get_node("Player") as Node3D
	var day_night = main_scene.get_node("DayNightCycle") as DayNightCycle

	assert(deliv_station != null, "DeliveryStation deve existir na cena")
	assert(deliv_mgr != null, "DeliveryQueueManager deve existir na cena")
	assert(order_mgr != null, "OrderManager deve existir na cena")
	assert(player != null, "Player deve existir na cena")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO CENÁRIO EXTERNO DOS FUNDOS (RUA, CALÇADAS, PRÉDIOS, GRADE)
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação do Cenário Urbano dos Fundos ---")
	var room = main_scene.get_node("Room")
	var floor_dt = room.get_node("FloorDriveThru") as CSGBox3D
	assert(floor_dt != null, "Rua dos fundos FloorDriveThru deve existir")
	assert(floor_dt.size.x >= 80.0, "Rua dos fundos deve ter extensão ampla para circulação e fila")
	assert(floor_dt.size.z >= 4.5, "Rua dos fundos deve ter largura adequada para tráfego")

	var facade_back = main_scene.get_node("UrbanFacadeBack")
	assert(facade_back != null, "UrbanFacadeBack deve existir ao fundo da rua de delivery")
	var bld_nodes = facade_back.get_node("Buildings")
	assert(bld_nodes != null and bld_nodes.get_child_count() >= 4, "Devem existir prédios/construções ao fundo para profundidade urbana")

	var fence = facade_back.get_node("SecurityFence")
	assert(fence != null, "Grade metálica de segurança dos fundos deve existir")
	var gate = fence.get_node("GateFrame")
	assert(gate != null, "Portão de acesso deve existir na grade")

	var trees = facade_back.get_node("Trees")
	assert(trees != null and trees.get_child_count() >= 4, "Árvores urbanas dos fundos devem existir")
	print("  [PASS] Rua dos fundos, calçadas, prédios, grade com portão e árvores validados!")

	# -------------------------------------------------------------------------
	# 2. TESTE COM 1 CARRO (FLUXO COMPLETO: CHEGADA -> PEDIDO -> ENTREGA -> SAÍDA)
	# -------------------------------------------------------------------------
	print("\n--- 2. Teste de Fluxo Completo com 1 Carro no Drive-Thru ---")
	deliv_mgr.set("auto_spawn", false) # Controle manual para teste
	var car1 = deliv_mgr.call("spawn_car")
	assert(car1 != null, "Carro de delivery deve ser instanciado")
	assert(deliv_mgr.call("get_queue_count") == 1, "Fila deve conter 1 carro")

	# Verifica presença do motorista dentro do carro
	var driver_node = car1.get_node("Model/Driver")
	assert(driver_node != null, "Motorista deve existir dentro do carro")
	var driver_head = driver_node.get_node("Head")
	assert(driver_head != null, "Motorista deve possuir cabeça visível")

	# Simula avanço até a posição da janela
	for i in range(120):
		car1._physics_process(0.1)

	assert(car1.get("current_state") == 3, "Carro 1 deve parar na janela aguardando atendimento (estado 3 = AT_WINDOW_WAITING_ORDER)")
	assert(deliv_mgr.call("get_car_at_window") == car1, "Carro 1 deve ser reconhecido como carro na janela")

	# Jogador atende o pedido na janela
	var initial_balance = economy.get_money()
	var order1 = car1.call("take_order", player) as Order
	assert(order1 != null, "Pedido deve ser gerado pelo carro de delivery")
	assert(order1.source_type == "DELIVERY", "Pedido deve ter source_type == 'DELIVERY'")
	assert(order1.customer_ref == car1, "Pedido deve referenciar o carro como cliente")
	assert(car1.get("current_state") == 4, "Carro deve aguardar a entrega dos produtos (estado 4 = AT_WINDOW_WAITING_FOOD)")

	# Simula entrega dos itens do pedido
	for item in order1.items:
		var p_id = item["product_id"]
		var qty = item["quantity"]
		for q in range(qty):
			order1.register_product_delivered(p_id)

	assert(order1.is_all_delivered(), "Todos os itens do pedido devem estar marcados como entregues")
	order_mgr.complete_order(order1)
	economy.add_money(order1.total_price, "Drive-Thru Venda")
	car1.call("finish_and_leave")

	assert(economy.get_money() > initial_balance, "Saldo deve aumentar com a venda do delivery")
	assert(car1.get("current_state") == 5, "Carro 1 deve entrar em estado LEAVING (estado 5) após receber todos os itens")

	# Simula deslocamento de saída
	for i in range(60):
		car1._physics_process(0.1)

	print("  [PASS] Fluxo de 1 carro (chegada, atendimento, entrega e saída) aprovado!")

	# -------------------------------------------------------------------------
	# 3. TESTE COM FILA DE 3 CARROS (FORMAÇÃO DE FILA E AVANÇO PROGRESSIVO)
	# -------------------------------------------------------------------------
	print("\n--- 3. Teste de Fila de Carros (3 Veículos Alinhados e Avanço) ---")
	var qcar1 = deliv_mgr.call("spawn_car")
	var qcar2 = deliv_mgr.call("spawn_car")
	var qcar3 = deliv_mgr.call("spawn_car")

	assert(deliv_mgr.call("get_queue_count") == 3, "Fila deve conter exatamente 3 carros")

	# Simula chegada e posicionamento de cada carro em sua vaga da fila
	for i in range(120):
		qcar1._physics_process(0.1)
		qcar2._physics_process(0.1)
		qcar3._physics_process(0.1)

	assert(qcar1.get("target_queue_index") == 0, "Carro 1 deve ser o primeiro da fila (índice 0)")
	assert(qcar2.get("target_queue_index") == 1, "Carro 2 deve ser o segundo da fila (índice 1)")
	assert(qcar3.get("target_queue_index") == 2, "Carro 3 deve ser o terceiro da fila (índice 2)")

	# Verifica espaçamento longitudinal seguro entre os veículos (sem sobreposição)
	var dist_1_2 = abs(qcar2.position.x - qcar1.position.x)
	var dist_2_3 = abs(qcar3.position.x - qcar2.position.x)
	assert(dist_1_2 >= 5.5, "Espaçamento entre Carro 1 e Carro 2 deve ser >= 5.5m (real: %.2fm)" % dist_1_2)
	assert(dist_2_3 >= 5.5, "Espaçamento entre Carro 2 e Carro 3 deve ser >= 5.5m (real: %.2fm)" % dist_2_3)
	print("  [PASS] Fila formada corretamente com 3 carros alinhados longitudinalmente e espaçamento seguro!")

	# Carro 1 é atendido e sai
	qcar1.call("take_order", player)
	qcar1.call("finish_and_leave")
	deliv_mgr.call("_on_car_left", qcar1)

	# Fila avança: Carro 2 vai para o índice 0 (janela), Carro 3 vai para o índice 1
	assert(deliv_mgr.call("get_queue_count") == 2, "Fila deve conter 2 carros após a saída do primeiro")
	assert(qcar2.get("target_queue_index") == 0, "Carro 2 deve agora ser o primeiro da fila (índice 0 na janela)")
	assert(qcar3.get("target_queue_index") == 1, "Carro 3 deve agora ser o segundo da fila (índice 1)")

	# Simula avanço físico
	for i in range(120):
		qcar2._physics_process(0.1)
		qcar3._physics_process(0.1)

	assert(qcar2.get("current_state") == 3, "Carro 2 deve assumir a janela e aguardar pedido (estado 3)")
	print("  [PASS] Avanço progressivo da fila validado perfeitamente!")

	# -------------------------------------------------------------------------
	# 4. TESTE DE ILUMINAÇÃO NOTURNA DOS CARROS E POSTES
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação de Iluminação Noturna dos Carros de Delivery ---")
	deliv_mgr.call("set_night_mode", true)
	var qcar2_spot = qcar2.get_node_or_null("SpotLight3D")
	assert(qcar2_spot != null and qcar2_spot.visible == true, "Farol spot light deve estar ligado no modo noturno")
	deliv_mgr.call("set_night_mode", false)
	assert(qcar2_spot != null and qcar2_spot.visible == false, "Farol spot light deve estar desligado no modo diurno")
	print("  [PASS] Controle dinâmico de faróis e iluminação dos veículos de delivery aprovado!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS TESTES DA ÁREA DE DELIVERY E FILA DE CARROS FORAM APROVADOS COM SUCESSO!")
	print("================================================================================")
	quit(0)
