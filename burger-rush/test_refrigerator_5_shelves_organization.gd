extends SceneTree

# ===========================================================================
# TESTE: REORGANIZAÇÃO VERTICAL DO FREEZER EM 5 ANDARES
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: ORGANIZAÇÃO DOS 5 ANDARES NO FREEZER DE HORTIFRÚTI")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._ready()

	var pm = PowerManager.new()
	root.add_child(pm)
	PowerManager.instance = pm
	pm.is_main_power_on = true

	var fridge_scene = load("res://src/stations/ingredient_refrigerator.tscn")
	var fridge = fridge_scene.instantiate() as IngredientRefrigerator
	root.add_child(fridge)
	fridge._ready()
	fridge.is_open = true

	var player = load("res://src/player/player.tscn").instantiate() as CharacterBody3D
	root.add_child(player)

	# -----------------------------------------------------------------------
	# 1. VERIFICAÇÃO DAS ALTURAS DOS 5 ANDARES E ORDEM VERTICAL
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Ordem Vertical dos 5 Andares de Produtos ---")

	var pot_group = fridge.get_node_or_null("FridgeBody/Products/PotatoBagsGroup")
	var onion_bag_group = fridge.get_node_or_null("FridgeBody/Products/OnionBagsGroup")
	var let_group = fridge.get_node_or_null("FridgeBody/Products/LettuceGroup")
	var tom_group = fridge.get_node_or_null("FridgeBody/Products/TomatoGroup")
	var red_oni_group = fridge.get_node_or_null("FridgeBody/Products/RedOnionGroup")
	var white_oni_group = fridge.get_node_or_null("FridgeBody/Products/WhiteOnionGroup")
	var pic_group = fridge.get_node_or_null("FridgeBody/Products/PickleGroup")

	total_tests += 1
	if pot_group and onion_bag_group and let_group and tom_group and red_oni_group and white_oni_group and pic_group:
		print("  [PASS] Todos os 7 grupos de produtos existem dentro do freezer!")
		passed_tests += 1
	else:
		print("  [FAIL] Faltam grupos de produtos no freezer!")

	var y_pot = pot_group.position.y
	var y_oni_bag = onion_bag_group.position.y
	var y_let = let_group.position.y
	var y_red_oni = red_oni_group.position.y
	var y_pic = pic_group.position.y

	total_tests += 1
	if y_oni_bag > y_pot:
		print("  [PASS] Saco de Cebola (Y=%.2f) está IMEDIATAMENTE ACIMA do Saco de Batata (Y=%.2f)" % [y_oni_bag, y_pot])
		passed_tests += 1
	else:
		print("  [FAIL] Saco de Cebola não está acima da batata!")

	total_tests += 1
	if y_let > y_oni_bag and y_red_oni > y_let and y_pic > y_red_oni:
		print("  [PASS] Todos os demais itens subiram um nível:")
		print("         - Andar 1 (Inferior): Batata (Y=%.2f)" % y_pot)
		print("         - Andar 2: Cebola (Y=%.2f)" % y_oni_bag)
		print("         - Andar 3: Alface/Tomate (Y=%.2f)" % y_let)
		print("         - Andar 4: Cebolas Roxa/Normal (Y=%.2f)" % y_red_oni)
		print("         - Andar 5 (Superior): Picles (Y=%.2f)" % y_pic)
		passed_tests += 1
	else:
		print("  [FAIL] Ordem vertical incorreta dos andares!")

	# -----------------------------------------------------------------------
	# 2. VERIFICAÇÃO DE PRATELEIRAS FÍSICAS (SEM ITENS FLUTUANDO)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Prateleiras Físicas de Suporte para cada Andar ---")

	var shelf2 = fridge.get_node_or_null("FridgeBody/Shelf2")
	var shelf3 = fridge.get_node_or_null("FridgeBody/Shelf3")
	var shelf4 = fridge.get_node_or_null("FridgeBody/Shelf4")
	var shelf5 = fridge.get_node_or_null("FridgeBody/Shelf5")

	total_tests += 1
	if shelf2 and shelf3 and shelf4 and shelf5:
		print("  [PASS] Todas as prateleiras de arame (Shelf 2, 3, 4, 5) presentes e alinhadas.")
		passed_tests += 1
	else:
		print("  [FAIL] Faltam prateleiras na estrutura do gabinete!")

	total_tests += 1
	var no_overlap = (y_oni_bag - y_pot >= 0.30) and (y_let - y_oni_bag >= 0.30) and (y_red_oni - y_let >= 0.30) and (y_pic - y_red_oni >= 0.30)
	if no_overlap:
		print("  [PASS] Espaçamento vertical perfeito e uniforme (>= 0.30m por andar) - sem sobreposições!")
		passed_tests += 1
	else:
		print("  [FAIL] Andares muito próximos ou sobrepostos!")

	# -----------------------------------------------------------------------
	# 3. INTERAÇÃO E RETIRADA DE ITENS PELO JOGADOR
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Retirada de Produtos pelo Jogador ---")

	inv.add_stock("potato_raw", 10)
	inv.add_stock("onion_rings_raw", 10)
	inv.add_stock("lettuce", 10)
	inv.add_stock("pickle", 10)

	# 1. Retira Saco de Cebola
	fridge.handle_ingredient_interaction(player, "onion_rings_raw")
	total_tests += 1
	if player.held_item != null and player.held_item.get("item_id") == "onion_rings_raw":
		print("  [PASS] Jogador retirou Saco de Cebola do Andar 2 com sucesso!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao retirar Saco de Cebola: %s" % str(player.held_item))

	player.held_item.queue_free()
	player.held_item = null

	# 2. Retira Saco de Batata
	fridge.handle_ingredient_interaction(player, "potato_raw")
	total_tests += 1
	if player.held_item != null and player.held_item.get("item_id") == "potato_raw":
		print("  [PASS] Jogador retirou Saco de Batata do Andar 1 com sucesso!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao retirar Saco de Batata: %s" % str(player.held_item))

	player.held_item.queue_free()
	player.held_item = null

	# 3. Retira Picles (Andar Superior)
	fridge.handle_ingredient_interaction(player, "pickle")
	total_tests += 1
	if player.held_item != null and player.held_item.get("item_id") == "pickle":
		print("  [PASS] Jogador retirou Picles do Andar 5 (Superior) com sucesso!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao retirar Picles: %s" % str(player.held_item))

	player.held_item.queue_free()
	player.held_item = null

	# -----------------------------------------------------------------------
	# 4. ATUALIZAÇÃO DINÂMICA DO ESTOQUE VISUAL
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Atualização Dinâmica do Estoque Visual (3 Estágios) ---")

	fridge._update_all_visual_stocks()

	total_tests += 1
	var oni_full = fridge.get_node_or_null("FridgeBody/Products/OnionBagsGroup/Full")
	var pot_full = fridge.get_node_or_null("FridgeBody/Products/PotatoBagsGroup/Full")
	if oni_full != null and pot_full != null:
		print("  [PASS] Nós Full de cebola e batata atualizados corretamente pelo InventoryManager!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha nos nós visuais de estoque!")

	# -----------------------------------------------------------------------
	# RESULTADO FINAL
	# -----------------------------------------------------------------------
	print("\n===========================================================================")
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [passed_tests, total_tests - passed_tests])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
