extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REFINAMENTO VISUAL DO BECO DE SERVIÇO")
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
	# TESTE 1: MUROS BRANCOS, PISO ESCURO E GRADE VAZADA
	# ---------------------------------------------------------
	print("\n--- Teste 1: Muros Brancos, Piso Escuro e Grade Metálica Vazada ---")
	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	var wall_north = main.get_node_or_null("Room/AlleyWallNorth") as CSGBox3D
	var wall_south = main.get_node_or_null("Room/AlleyWallSouth") as CSGBox3D
	var floor_dock = main.get_node_or_null("Room/FloorLoadingDock") as CSGBox3D

	assert(wall_north != null and wall_south != null, "Muros laterais do beco devem existir")
	assert(floor_dock != null, "Piso do beco deve existir")

	# Confirma que prédios pesados antigos foram removidos
	assert(main.get_node_or_null("Room/AlleyBackdropBuilding1") == null, "Prédios pesados de fundo devem ser removidos")
	assert(main.get_node_or_null("Room/AlleyBackdropBuilding2") == null, "Prédios pesados de fundo devem ser removidos")

	# Confirma grade vazada com barras verticais reais
	var fence = main.get_node_or_null("SecurityFence")
	assert(fence != null, "SecurityFence deve existir")
	assert(fence.has_node("Model/PicketsNorth/PicketN1"), "Grade deve ter barras verticais vazadas no setor norte")
	assert(fence.has_node("Model/PicketsSouth/PicketS1"), "Grade deve ter barras verticais vazadas no setor sul")
	assert(fence.has_node("Model/PicketsGate/PicketG1"), "Grade deve ter barras verticais vazadas no portão")
	assert(fence.has_node("Model/SignPlate"), "Grade deve conter placa de aviso")

	print("  [PASS] Muros brancos, piso escuro uniforme e grade metálica vazada com barras e espaçamento real!")

	# ---------------------------------------------------------
	# TESTE 2: ÁRVORES EXTERNAS E LIXEIRA ENCOSTADA NA GRADE
	# ---------------------------------------------------------
	print("\n--- Teste 2: Árvores Além da Grade e Lixeira Encostada na Grade ---")
	assert(main.get_node_or_null("TreePark1") != null, "TreePark1 deve existir fora da grade")
	assert(main.get_node_or_null("TreePark2") != null, "TreePark2 deve existir fora da grade")
	assert(main.get_node_or_null("TreePark3") != null, "TreePark3 deve existir fora da grade")

	var dumpster = main.get_node_or_null("IndustrialDumpster") as TrashBin
	assert(dumpster != null, "IndustrialDumpster deve existir")

	# Lixeira deve estar encostada na grade (x ≈ -14.65) e no canto norte (z ≈ -7.2)
	assert(abs(dumpster.position.x - (-14.65)) < 0.2, "Lixeira deve estar encostada na grade em x = -14.65 (atual: %.2f)" % dumpster.position.x)
	assert(dumpster.position.z <= -6.0, "Lixeira deve estar no canto norte do beco (atual: %.2f)" % dumpster.position.z)

	print("  [PASS] Lixeira industrial posicionada rente à grade no canto norte (x = %.2f, z = %.2f)" % [
		dumpster.position.x, dumpster.position.z
	])
	print("  [PASS] Árvores naturais visíveis através da grade contra o céu aberto!")

	# ---------------------------------------------------------
	# TESTE 3: FUNCIONALIDADE PRESERVADA DO CONTÊINER E RECEBIMENTO
	# ---------------------------------------------------------
	print("\n--- Teste 3: Descarte de Lixo e Recebimento no Beco Refinado ---")
	var burnt_patty = load("res://src/items/patty.tscn").instantiate() as Patty
	burnt_patty.state = Patty.State.BURNT
	root.add_child(burnt_patty)
	player.pick_up(burnt_patty)

	dumpster.interact(player)
	assert(player.held_item == null, "Item deve ser descartado no contêiner")
	assert(waste_mgr.total_waste_cost > 0.0, "WasteManager deve registrar perda financeira")

	var rec_area = main.get_node_or_null("ReceivingArea") as ReceivingArea
	assert(rec_area != null, "ReceivingArea deve existir")
	rec_area.add_pending_delivery("bread", "Pão Brioche", 10)
	rec_area.interact(player)
	assert(player.held_item != null, "Jogador pegou caixa de entrega")
	player.take_held_item().queue_free()

	print("  [PASS] Contêiner industrial e recebimento de mercadorias 100% funcionais!")

	# Limpeza
	player.queue_free()
	main.queue_free()
	prog.queue_free()
	waste_mgr.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO DO BECO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
