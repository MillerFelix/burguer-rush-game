extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE AMBIENTAÇÃO DO BECO DE SERVIÇO E LIXEIRAS")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var waste_mgr = WasteManager.new()
	root.add_child(waste_mgr)
	waste_mgr._enter_tree()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ---------------------------------------------------------
	# TESTE 1: VALIDAÇÃO ARQUITETÔNICA DO BECO DE SERVIÇO E FECHAMENTO
	# ---------------------------------------------------------
	print("\n--- Teste 1: Estruturas do Beco de Serviço, Grade e Oclusão ---")
	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	# Paredes do beco (bloqueio do vazio norte/sul)
	assert(main.get_node_or_null("Room/AlleyWallNorth") != null, "AlleyWallNorth deve existir")
	assert(main.get_node_or_null("Room/AlleyWallSouth") != null, "AlleyWallSouth deve existir")
	assert(main.get_node_or_null("Room/AlleyBackdropBuilding1") != null, "Prédios de fundo 1 devem existir")
	assert(main.get_node_or_null("Room/AlleyBackdropBuilding2") != null, "Prédios de fundo 2 devem existir")

	# Grade de segurança e portão fechado
	assert(main.get_node_or_null("Room/AlleyFenceWestNorth") != null, "Grade norte deve existir")
	assert(main.get_node_or_null("Room/AlleyFenceWestSouth") != null, "Grade sul deve existir")
	assert(main.get_node_or_null("Room/AlleySecurityGateClosed") != null, "Portão fechado deve existir")
	assert(main.get_node_or_null("Room/AlleySecurityGateClosed/AlleyGateSign") != null, "Placa de aviso no portão deve existir")

	# Iluminação externa de serviço
	assert(main.get_node_or_null("Room/DockSecurityLamp") != null, "Luz da doca deve existir")
	assert(main.get_node_or_null("Room/DumpsterSecurityLamp") != null, "Luz do contêiner deve existir")

	# Caminhão de entrega no fundo
	assert(main.get_node_or_null("DeliveryTruck") != null, "Caminhão de entrega de ambientação deve existir")

	print("  [PASS] Beco de serviço completamente cercado, ocluído e iluminado sem buracos para o vazio!")

	# ---------------------------------------------------------
	# TESTE 2: LIXEIRA DA COZINHA E CONTÊINER INDUSTRIAL EXTERNO
	# ---------------------------------------------------------
	print("\n--- Teste 2: Sistema Unificado de Descarte (Cozinha e Contêiner) ---")
	var dumpster = main.get_node_or_null("IndustrialDumpster") as TrashBin
	var kitchen_bin = main.get_node_or_null("TrashBin") as TrashBin

	assert(dumpster != null, "IndustrialDumpster deve existir no beco de serviço")
	assert(kitchen_bin != null, "TrashBin deve existir dentro da cozinha")

	# 1. Descarte no Contêiner Industrial Externo
	var burnt_patty = load("res://src/items/patty.tscn").instantiate() as Patty
	burnt_patty.state = Patty.State.BURNT
	root.add_child(burnt_patty)
	player.pick_up(burnt_patty)

	dumpster.interact(player)
	assert(player.held_item == null, "Carne queimada deve ser descartada no contêiner")
	assert(waste_mgr.total_waste_cost > 0.0, "WasteManager deve registrar perda financeira no contêiner")

	var prev_waste = waste_mgr.total_waste_cost

	# 2. Descarte na Lixeira Interna da Cozinha
	var extra_bread = load("res://src/items/bread_bottom.tscn").instantiate()
	root.add_child(extra_bread)
	player.pick_up(extra_bread)

	kitchen_bin.interact(player)
	assert(player.held_item == null, "Item deve ser descartado na lixeira da cozinha")
	assert(waste_mgr.total_waste_cost > prev_waste, "WasteManager deve registrar descarte unificado")

	print("  [PASS] Ambas as lixeiras operam com sucesso no mesmo sistema WasteManager!")

	# ---------------------------------------------------------
	# TESTE 3: ÁREA DE RECEBIMENTO FUNCIONAL NO BECO
	# ---------------------------------------------------------
	print("\n--- Teste 3: Recebimento de Mercadorias no Beco de Serviço ---")
	var rec_area = main.get_node_or_null("ReceivingArea") as ReceivingArea
	assert(rec_area != null, "ReceivingArea deve existir no beco")
	assert(rec_area.position.x <= -10.0, "ReceivingArea deve estar posicionada no beco de serviço")

	rec_area.add_pending_delivery("cheese", "Queijo Cheddar", 10)
	assert(rec_area.has_pending_boxes(), "Recebimento deve conter caixas pendentes")

	rec_area.interact(player)
	assert(player.held_item != null and player.held_item is DeliveryBox, "Jogador pegou caixa de entrega no beco")
	player.take_held_item().queue_free()

	print("  [PASS] Recebimento de caixas de mercadoria no beco funcionando 100%!")

	# Limpeza
	player.queue_free()
	main.queue_free()
	prog.queue_free()
	waste_mgr.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE AMBIENTAÇÃO DO BECO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
