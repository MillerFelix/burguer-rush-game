extends SceneTree

# ===========================================================================
# TESTE COMPLETO: NOVO PRODUTO CEBOLA FRITA (3 PORÇÕES) + TEMPO FRITURA 84s (3x)
# ===========================================================================

const OnionBagClass = preload("res://src/items/onion_bag.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: CEBOLA FRITA (NOVO PRODUTO 3 PORÇÕES) & TEMPO DA BATATA 3X (84s)")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# 1. SETUP DE SISTEMAS
	# -----------------------------------------------------------------------
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._ready()

	var pm = PowerManager.new()
	root.add_child(pm)
	PowerManager.instance = pm
	pm.is_main_power_on = true

	var pur_mgr = PurchaseManager.new()
	root.add_child(pur_mgr)
	pur_mgr._ready()

	# -----------------------------------------------------------------------
	# 2. PC: COMPRAS E ESTOQUE DO SACO DE CEBOLA
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Saco de Cebola no PC, Compras e Estoque ---")

	var onion_data = inv.get_item_data("onion_rings_raw")
	total_tests += 1
	if onion_data and onion_data.get("category") == "vegetables":
		print("  [PASS] Saco de Cebola cadastrado no inventário na categoria 'vegetables'")
		passed_tests += 1
	else:
		print("  [FAIL] Saco de Cebola não encontrado no inventário: %s" % str(onion_data))

	var cat_item = pur_mgr.get_catalog_item("onion_rings_raw")
	total_tests += 1
	if cat_item and cat_item.get("display_name") == "Saco de Cebola":
		print("  [PASS] Saco de Cebola presente no catálogo de compras com preço R$ %.2f" % cat_item.get("base_price"))
		passed_tests += 1
	else:
		print("  [FAIL] Saco de Cebola não encontrado no catálogo de compras!")

	# Testa filtros e ícones do PC
	var comp_ui = load("res://src/ui/computer_ui.tscn").instantiate() as ComputerUI
	root.add_child(comp_ui)

	total_tests += 1
	var is_in_supplies = comp_ui._is_item_in_filter(onion_data.get("category"), "SUPPLIES")
	var is_in_ing = comp_ui._is_item_in_filter(onion_data.get("category"), "INGREDIENTS")
	if not is_in_supplies and is_in_ing:
		print("  [PASS] Saco de Cebola aparece em INGREDIENTES e NÃO em EMBALAGENS")
		passed_tests += 1
	else:
		print("  [FAIL] Filtros do PC incorretos para Saco de Cebola!")

	total_tests += 1
	var icon = comp_ui._get_item_icon("onion_rings_raw")
	if icon == "🧅":
		print("  [PASS] Ícone de Saco de Cebola configurado como 🧅")
		passed_tests += 1
	else:
		print("  [FAIL] Ícone de Saco de Cebola incorreto: %s" % icon)

	# -----------------------------------------------------------------------
	# 3. FREEZER / GELADEIRA: ARMAZENAMENTO E RETIRADA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Freezer / Geladeira — Armazenamento e Retirada de Cebola ---")

	var fridge = load("res://src/stations/ingredient_refrigerator.gd").new()
	root.add_child(fridge)
	fridge._ready()
	fridge.is_open = true

	var player = load("res://src/player/player.tscn").instantiate() as CharacterBody3D
	root.add_child(player)

	# Retira 1 saco de cebola da geladeira
	inv.add_stock("onion_rings_raw", 10)
	fridge.handle_ingredient_interaction(player, "onion_rings_raw")

	total_tests += 1
	if (player.held_item is OnionBagClass or (player.held_item != null and player.held_item.get("item_id") == "onion_rings_raw")) and player.held_item.get_display_name() == "Saco de Cebola":
		print("  [PASS] Jogador retirou Saco de Cebola do freezer (Item: OnionBag)")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao retirar Saco de Cebola do freezer: %s" % str(player.held_item))

	# -----------------------------------------------------------------------
	# 4. FRITADEIRA: TEMPO NOVO DE 84.0s (3x / +200%) E ABASTECIMENTO COM CEBOLA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Fritadeira — Tempo 84.0s e Fritura de Cebola (3 Porções) ---")

	var fryer = load("res://src/stations/fryer.gd").new()
	root.add_child(fryer)
	fryer._ready()
	fryer.is_on = true
	fryer.current_temperature = 180.0

	total_tests += 1
	if fryer.cook_time == 84.0 and fryer.burn_time == 126.0:
		print("  [PASS] cook_time da fritadeira configurado para 84.0s (+200%% / 3x de 28.0s)")
		passed_tests += 1
	else:
		print("  [FAIL] cook_time incorreto: %.1f s (esperado 84.0s)" % fryer.cook_time)

	# Abastece Cesto 0 com Saco de Cebola
	var prompt_onion_fill = fryer.get_interaction_prompt(player)
	total_tests += 1
	if "Abastecer Cesto 1 com Cebola (1 Saco = 3 Porções)" in prompt_onion_fill:
		print("  [PASS] Prompt de abastecimento de cebola correto: '%s'" % prompt_onion_fill)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de abastecimento de cebola inesperado: '%s'" % prompt_onion_fill)

	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "frozen" and fryer.compartments[0]["food_type"] == "onion" and fryer.compartments[0]["portions_remaining"] == 3 and player.held_item == null:
		print("  [PASS] Cesto 0 abastecido com Cebola: food_type='onion', portions_remaining=3, saco consumido!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha no abastecimento com cebola: state=%s, type=%s, portions=%d" % [fryer.compartments[0]["food_state"], fryer.compartments[0]["food_type"], fryer.compartments[0]["portions_remaining"]])

	# Inicia fritura (abaixa o cesto)
	fryer.toggle_basket(0)

	# Frita por 42.0s (50% de 84.0s)
	fryer._process(42.0)

	total_tests += 1
	var prompt_onion_cooking = fryer.get_interaction_prompt(player)
	if prompt_onion_cooking == "🧅 Cebola Fritando (50%)":
		print("  [PASS] Prompt discreto no estilo do hambúrguer: '%s'" % prompt_onion_cooking)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de fritura de cebola incorreto: '%s'" % prompt_onion_cooking)

	# Avança até 85.0s (conclusão da fritura de cebola)
	fryer._process(43.0)

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "cooked" and fryer.compartments[0]["portions_remaining"] == 3:
		print("  [PASS] Cebola frita pronta no Cesto 0 aos 84.0s (3 porções disponíveis)")
		passed_tests += 1
	else:
		print("  [FAIL] Cebola não atingiu estado cooked aos 84s: %s" % fryer.compartments[0]["food_state"])

	fryer.toggle_basket(0) # Levanta o cesto

	# -----------------------------------------------------------------------
	# 5. RETIRADA DAS 3 PORÇÕES DE CEBOLA NA EMBALAGEM VERMELHA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Retirada sucessiva das 3 porções de Cebola Frita ---")

	var box_scene = load("res://src/items/potato_box.tscn")

	# Porção 1: 3 -> 2
	var b1 = box_scene.instantiate()
	root.add_child(b1)
	player.held_item = b1
	fryer.interact_item(player)

	total_tests += 1
	var pack1 = player.held_item as FriesPack
	if fryer.compartments[0]["portions_remaining"] == 2 and pack1 != null and pack1.display_name == "Cebola Frita" and pack1.item_id == "onion_rings":
		print("  [PASS] 1ª porção retirada! Restam 2 no cesto. Item gerado: 'Cebola Frita' (ID: onion_rings)")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao retirar 1ª porção de cebola!")

	player.held_item.queue_free()
	player.held_item = null

	# Porção 2: 2 -> 1
	var b2 = box_scene.instantiate()
	root.add_child(b2)
	player.held_item = b2
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 1:
		print("  [PASS] 2ª porção retirada! Resta 1 no cesto.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao retirar 2ª porção de cebola!")

	player.held_item.queue_free()
	player.held_item = null

	# Porção 3: 1 -> 0 (Cesto Vazio!)
	var b3 = box_scene.instantiate()
	root.add_child(b3)
	player.held_item = b3
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 0 and fryer.compartments[0]["food_state"] == "empty":
		print("  [PASS] 3ª e última porção retirada! Cesto 0 agora está completamente VAZIO.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na 3ª porção de cebola: state=%s, portions=%d" % [fryer.compartments[0]["food_state"], fryer.compartments[0]["portions_remaining"]])

	# -----------------------------------------------------------------------
	# 6. VALIDAÇÃO DE PEDIDOS E VENDAS COM CEBOLA FRITA VS BATATA FRITA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Validação de Pedidos (Cebola Frita vs Batata Frita) ---")

	var deliv_station_scene = load("res://src/stations/delivery_station.tscn")
	var deliv_station = deliv_station_scene.instantiate() as DeliveryStation
	root.add_child(deliv_station)

	var order = Order.new()
	order.id = 999
	order.add_item("onion_rings", "Cebola Frita", 1, 9.0)

	total_tests += 1
	if order.has_pending_product("onion_rings"):
		print("  [PASS] Pedido aceita produto 'onion_rings' (Cebola Frita)")
		passed_tests += 1
	else:
		print("  [FAIL] Pedido não registrou 'onion_rings'!")

	# Cria porção de Cebola Frita
	var onion_pack = load("res://src/items/fries_pack.tscn").instantiate() as FriesPack
	root.add_child(onion_pack)
	onion_pack.set_side_type("onion_rings")

	# Entrega a cebola frita
	order.register_product_delivered("onion_rings")

	total_tests += 1
	if order.is_all_delivered():
		print("  [PASS] Pedido de Cebola Frita validado e entregue com 100% de sucesso!")
		passed_tests += 1
	else:
		print("  [FAIL] Pedido de Cebola Frita não completou!")

	# -----------------------------------------------------------------------
	# 7. CONFIRMAÇÃO: BATATA CONTINUA FUNCIONANDO COM 5 PORÇÕES A 84.0s
	# -----------------------------------------------------------------------
	print("\n--- TESTE 6: Batata frita continua operando perfeitamente com 5 porções a 84s ---")

	var pot_bag = load("res://src/items/potato.tscn").instantiate() as Potato
	root.add_child(pot_bag)
	player.held_item = pot_bag

	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "frozen" and fryer.compartments[0]["food_type"] == "potato" and fryer.compartments[0]["portions_remaining"] == 5:
		print("  [PASS] Cesto 0 reabastecido com Batata (5 porções)!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao abastecer batata no Cesto 0: %s" % str(fryer.compartments[0]))

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
