extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REORGANIZAÇÃO DO ARMAZÉM (ÁREA DE PÃES)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["bread_top"]["quantity"] = 25
	inv.items["bread_bottom"]["quantity"] = 25
	inv.items["bread"]["quantity"] = 50

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	print("\n--- Teste 1: Instanciação da Mesinha de Armazenamento de Pães ---")
	var bread_station_scene = load("res://src/stations/storage_rack.tscn")
	assert(bread_station_scene != null, "Cena storage_rack.tscn deve carregar")
	var station = bread_station_scene.instantiate() as StorageRack
	root.add_child(station)
	station._ready()

	# 1. Estrutura da Mesa
	assert(station.has_node("Model/TableTop"), "Tampo da mesa deve existir")
	assert(station.has_node("Model/Leg1"), "Pernas da mesa devem existir")
	assert(station.has_node("Model/LowerShelf"), "Prateleira inferior da mesa deve existir")
	print("  [PASS] Estrutura da mesa de madeira funcional e compatível.")

	# 2. Identificação da Área (Etiqueta 'PÃO' com Desenho)
	print("\n--- Teste 2: Placa e Etiqueta Frontal Fixada na Mesa ---")
	assert(station.has_node("Model/TableFrontBadge"), "Placa frontal deve existir")
	assert(station.has_node("Model/TableFrontLabel"), "Label da placa frontal deve existir")
	var front_label = station.get_node("Model/TableFrontLabel") as Label3D
	assert(front_label.text.contains("PÃO") and front_label.text.contains("🍞"), "Etiqueta deve conter '🍞 PÃO'")
	print("  [PASS] Etiqueta '🍞 PÃO' fixada fisicamente na mesa.")

	# 3. Duas Caixas de Pão Apoiadas sobre a Mesa
	print("\n--- Teste 3: Duas Caixas de Pão Apoiadas na Mesa ---")
	assert(station.has_node("Model/BoxBreadTop"), "Caixa de tampas de pão (BoxBreadTop) deve existir")
	assert(station.has_node("Model/BoxBreadBottom"), "Caixa de bases de pão (BoxBreadBottom) deve existir")
	var box_top = station.get_node("Model/BoxBreadTop") as Node3D
	var box_bot = station.get_node("Model/BoxBreadBottom") as Node3D
	assert(box_top.position.y >= 0.82, "Caixa de tampas apoiada sobre a mesa")
	assert(box_bot.position.y >= 0.82, "Caixa de bases apoiada sobre a mesa")
	assert(box_top.position.x < 0.0 and box_bot.position.x > 0.0, "Caixas organizadas lado a lado")
	print("  [PASS] Duas caixas de pão apoiadas lado a lado sobre a mesa.")

	# 4. Conteúdo das Caixas (Pães Visíveis com Modelo Aprovado)
	print("\n--- Teste 4: Pães Visíveis com Gergelim e Bases ---")
	assert(box_top.has_node("TopBun1/TopBun"), "Pão superior visível dentro da caixa 1")
	assert(box_top.has_node("TopBun1/Sesame1"), "Gergelim visível na tampa do pão")
	assert(box_bot.has_node("BotBun1/BottomBun"), "Base do pão visível dentro da caixa 2")
	print("  [PASS] Pães com gergelim e bases visíveis dentro das caixas.")

	# 5. Remoção de Outros Produtos da Apresentação Visual
	print("\n--- Teste 5: Remoção Visual de Outros Produtos ---")
	assert(not station.has_node("Model/BoxCheese"), "Queijo removido da apresentação visual da mesa de pão")
	assert(not station.has_node("Model/BoxTomato"), "Tomate removido da apresentação visual")
	assert(not station.has_node("Model/BoxPotato"), "Batata removida da apresentação visual")
	assert(not station.has_node("Model/BoxLettuce"), "Alface removida da apresentação visual")
	print("  [PASS] Outros produtos antigos removidos da apresentação visual do armazém.")

	# 6. Interação e Retirada de Pães
	print("\n--- Teste 6: Interação e Retirada de Tampas e Bases ---")
	# Retira Tampa do Pão (index 0)
	station.active_item_index = 0
	var prompt_top = station.get_interaction_prompt(player)
	assert(prompt_top.contains("Tampa") or prompt_top.contains("🥯"), "Prompt para pegar tampa")
	station.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "bread_top", "Jogador pegou Tampa do Pão")
	assert(inv.get_stock("bread_top") == 24, "Estoque de bread_top atualizado para 24")
	player.take_held_item().queue_free()

	# Retira Base do Pão (index 1)
	station.active_item_index = 1
	var prompt_bot = station.get_interaction_prompt(player)
	assert(prompt_bot.contains("Base") or prompt_bot.contains("🍞"), "Prompt para pegar base")
	station.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "bread_bottom", "Jogador pegou Base do Pão")
	assert(inv.get_stock("bread_bottom") == 24, "Estoque de bread_bottom atualizado para 24")
	player.take_held_item().queue_free()
	print("  [PASS] Retirada de tampas e bases de pão funcionando perfeitamente.")

	# Limpeza
	station.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA ÁREA DE PÃES DO ARMAZÉM FORAM APROVADOS!")
	print("============================================================")
	quit(0)
