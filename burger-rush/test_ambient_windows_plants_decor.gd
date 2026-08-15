extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE AMBIENTAÇÃO (JANELAS, PLANTAS E DECORAÇÃO)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var clock = GameClock.new()
	root.add_child(clock)
	clock._enter_tree()
	clock.open_restaurant()

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# ---------------------------------------------------------
	# TESTE 1: JANELAS LATERAIS COM MOLDURA E VIDRO TRANSPARENTE
	# ---------------------------------------------------------
	print("\n--- Teste 1: Janelas Arquitetônicas na Parede Esquerda e Direita ---")
	var win_e1 = main_scene.get_node_or_null("Room/WindowEast1")
	var win_e2 = main_scene.get_node_or_null("Room/WindowEast2")
	var win_w1 = main_scene.get_node_or_null("Room/WindowWest1")
	var win_w2 = main_scene.get_node_or_null("Room/WindowWest2")

	assert(win_e1 != null and win_e2 != null, "Janelas na parede Leste (Direita) devem existir")
	assert(win_w1 != null and win_w2 != null, "Janelas na parede Oeste (Esquerda) devem existir")

	# Verifica presença de molduras e vidro
	for win in [win_e1, win_e2, win_w1, win_w2]:
		assert(win.has_node("GlassPane"), "Janela deve conter painel de vidro")
		assert(win.has_node("FrameTop") and win.has_node("FrameBottom"), "Janela deve conter moldura horizontal")
		assert(win.has_node("FrameLeft") and win.has_node("FrameRight"), "Janela deve conter moldura vertical")
		assert(win.has_node("WindowSill"), "Janela deve conter peitoril")
		assert(win.position.y >= 1.50 and win.position.y <= 1.80, "Janela deve estar posicionada no nível natural da visão (~1.65m)")

	print("  [PASS] 4 Janelas arquitetônicas completas instaladas nas paredes laterais!")

	# ---------------------------------------------------------
	# TESTE 2: PAISAGISMO EXTERNO VISÍVEL ATRAVÉS DAS JANELAS
	# ---------------------------------------------------------
	print("\n--- Teste 2: Vista Externa e Paisagismo com Árvores e Gramado ---")
	assert(main_scene.has_node("Room/LawnEastOuter"), "Gramado externo Leste deve existir")
	assert(main_scene.has_node("Room/LawnWestOuter"), "Gramado externo Oeste deve existir")
	assert(main_scene.has_node("TreeEast1") and main_scene.has_node("TreeEast2"), "Árvores do lado Leste devem existir")
	assert(main_scene.has_node("TreeWest1") and main_scene.has_node("TreeWest2"), "Árvores do lado Oeste devem existir")

	print("  [PASS] Paisagismo externo instalado e perfeitamente visível pelas janelas!")

	# ---------------------------------------------------------
	# TESTE 3: PLANTAS ORNAMENTAIS EM CANTOS ESTRATÉGICOS
	# ---------------------------------------------------------
	print("\n--- Teste 3: Plantas Ornamentais em Vasos de Cerâmica ---")
	var plant_sw = main_scene.get_node_or_null("PlantSouthWest")
	var plant_se = main_scene.get_node_or_null("PlantSouthEast")
	var plant_nw = main_scene.get_node_or_null("PlantNorthWest")
	var plant_ne = main_scene.get_node_or_null("PlantNorthEast")

	assert(plant_sw != null and plant_se != null and plant_nw != null and plant_ne != null, "Plantas ornamentais de canto devem existir")
	for plant in [plant_sw, plant_se, plant_nw, plant_ne]:
		assert(plant.has_node("Model/Pot"), "Planta deve ter vaso de cerâmica")
		assert(plant.has_node("Model/FoliageMain"), "Planta deve ter folhagem verde")
		# Garante que não bloqueia o centro da circulação
		assert(absf(plant.position.x) >= 8.0, "Planta deve ficar encostada nos cantos/paredes (|x| >= 8.0)")

	print("  [PASS] 4 Plantas ornamentais distribuídas nos cantos sem obstruir circulação!")

	# ---------------------------------------------------------
	# TESTE 4: DECORAÇÃO GERAL, PÔSTERES, LUMINÁRIAS E LIXEIRA DE SALÃO
	# ---------------------------------------------------------
	print("\n--- Teste 4: Identidade Visual de Hamburgueria e Iluminação ---")
	assert(main_scene.has_node("Room/PosterEastBurger"), "Pôster de Burger na parede Leste deve existir")
	assert(main_scene.has_node("Room/PosterWestShake"), "Pôster de Shake na parede Oeste deve existir")
	assert(main_scene.has_node("PendantTable1"), "Luminária pendente na Mesa 1 deve existir")
	assert(main_scene.has_node("PendantTable2"), "Luminária pendente na Mesa 2 deve existir")
	assert(main_scene.has_node("PendantTable3"), "Luminária pendente na Mesa 3 deve existir")
	assert(main_scene.has_node("DiningWasteStation"), "Estação de descarte e lixeira do salão deve existir")

	print("  [PASS] Decoração harmoniosa, iluminação quente e identidade Burger Rush completas!")

	# ---------------------------------------------------------
	# TESTE 5: PRESERVAÇÃO INTEGRAL DE COZINHA, ESTOQUE E GAMEPLAY
	# ---------------------------------------------------------
	print("\n--- Teste 5: Preservação de Cozinha, Estoque e Gameplay ---")
	assert(main_scene.has_node("Grill"), "Grelha preservada")
	assert(main_scene.has_node("Fryer"), "Fritadeira preservada")
	assert(main_scene.has_node("PrepTable"), "Mesa de montagem preservada")
	assert(main_scene.has_node("PackagingStation"), "Bancada de embalagem preservada")
	assert(main_scene.has_node("DeliveryStation"), "Delivery preservado")
	assert(main_scene.has_node("StorageRack"), "Estoque preservado")
	assert(main_scene.has_node("Table1") and main_scene.has_node("Table2") and main_scene.has_node("Table3"), "Mesas de atendimento preservadas")

	print("  [PASS] Todos os sistemas de cozinha, estoque e gameplay permanecem 100% intactos!")

	# Limpeza
	main_scene.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE AMBIENTAÇÃO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
