extends SceneTree

# ===========================================================================
# TESTE COMPLETO: 1 SACO -> 1 CESTO CHEIO -> FRITURA (ESTILO HAMBÚRGUER) -> 5 PORÇÕES
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: 1 SACO -> 1 CESTO CHEIO -> FRITURA (ESTILO HAMBÚRGUER) -> 5 PORÇÕES")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP DE SISTEMA
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._ready()

	var pm = PowerManager.new()
	root.add_child(pm)
	PowerManager.instance = pm
	pm.is_main_power_on = true

	var fryer_scene = load("res://src/stations/fryer.tscn")
	var fryer = fryer_scene.instantiate() as Fryer
	root.add_child(fryer)
	fryer._ready()
	fryer.is_on = true
	fryer.current_temperature = 180.0

	var pot_scene = load("res://src/items/potato.tscn")
	var box_scene = load("res://src/items/potato_box.tscn")

	var player = CharacterBody3D.new()
	var player_script = load("res://src/player/player.gd")
	player.set_script(player_script)
	root.add_child(player)

	# -----------------------------------------------------------------------
	# PASSO 1 & 2: PEGAR 1 SACO DE BATATA E COLOCAR NO CESTO
	# -----------------------------------------------------------------------
	print("--- PASSO 1 & 2: Pegar 1 saco de batata e abastecer o cesto 0 ---")
	var potato_bag = pot_scene.instantiate() as Potato
	root.add_child(potato_bag)
	player.held_item = potato_bag

	total_tests += 1
	var prompt_fill = fryer.get_interaction_prompt(player)
	if "Abastecer Cesto 1" in prompt_fill:
		print("  [PASS] Prompt discreto para abastecer cesto com o saco: '%s'" % prompt_fill)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de abastecimento inesperado: '%s'" % prompt_fill)

	# Interage para abastecer
	fryer.interact_item(player)

	# -----------------------------------------------------------------------
	# PASSO 3 & 4: CONFIRMAR CESTO CHEIO E SACO CONSUMIDO
	# -----------------------------------------------------------------------
	print("\n--- PASSO 3 & 4: Confirmar cesto cheio e saco consumido ---")
	total_tests += 1
	if fryer.compartments[0]["food_state"] == "frozen" and fryer.compartments[0]["portions_remaining"] == 5:
		print("  [PASS] Cesto 0 está abastecido e cheio (food_state='frozen', portions_remaining=5)")
		passed_tests += 1
	else:
		print("  [FAIL] Cesto não foi abastecido corretamente: state=%s, portions=%d" % [fryer.compartments[0]["food_state"], fryer.compartments[0]["portions_remaining"]])

	total_tests += 1
	if player.held_item == null:
		print("  [PASS] Saco de batata foi consumido integralmente no abastecimento!")
		passed_tests += 1
	else:
		print("  [FAIL] Saco não foi consumido e continua nas mãos do jogador!")

	# -----------------------------------------------------------------------
	# PASSO 5, 6, 7, 8: INICIAR FRITURA E OBSERVAR PROGRESSO DISCRETO
	# -----------------------------------------------------------------------
	print("\n--- PASSO 5 a 8: Fritura e feedback discreto no estilo do hambúrguer ---")
	fryer.toggle_basket(0) # Abaixa o cesto no óleo

	# Avança 42.0s (50% da fritura de 84.0s)
	fryer._process(42.0)

	total_tests += 1
	var prompt_cooking = fryer.get_interaction_prompt(player)
	if prompt_cooking == "🍟 Batata Fritando (50%)":
		print("  [PASS] Prompt discreto no mesmo modelo do hambúrguer: '%s'" % prompt_cooking)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de fritura incorreto: '%s'" % prompt_cooking)

	# Avança mais 21.0s (75% da fritura de 84.0s)
	fryer._process(21.0)

	total_tests += 1
	var prompt_cooking_75 = fryer.get_interaction_prompt(player)
	if prompt_cooking_75 == "🍟 Batata Fritando (75%)":
		print("  [PASS] Progresso aumentou suavemente: '%s'" % prompt_cooking_75)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de 75%% incorreto: '%s'" % prompt_cooking_75)

	# -----------------------------------------------------------------------
	# PASSO 9 & 10: CHEGAR A 100% E CONFIRMAR ESTADO PRONTO
	# -----------------------------------------------------------------------
	print("\n--- PASSO 9 & 10: Conclusão da fritura e estado de pronto ---")
	fryer._process(22.0) # Total 85.0s (> 84.0s)

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "cooked" and fryer.compartments[0]["portions_remaining"] == 5:
		print("  [PASS] Batatas fritas prontas no Cesto 0 (5 porções prontas disponíveis)")
		passed_tests += 1
	else:
		print("  [FAIL] Estado da batata não é 'cooked': %s" % fryer.compartments[0]["food_state"])

	# Levanta o cesto para drenar e embalar
	fryer.toggle_basket(0)

	total_tests += 1
	var prompt_ready = fryer.get_interaction_prompt(player)
	if "Embalar Porção de Batata Frita (5/5 restantes)" in prompt_ready:
		print("  [PASS] Prompt de retirada inicial indica 5/5 porções disponíveis: '%s'" % prompt_ready)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de retirada incorreto: '%s'" % prompt_ready)

	# -----------------------------------------------------------------------
	# PASSO 11 a 15: RETIRAR AS 5 PORÇÕES SUCESSIVAMENTE ATÉ ESVAZIAR
	# -----------------------------------------------------------------------
	print("\n--- PASSO 11 a 15: Retirada sucessiva das 5 porções ---")

	# Porção 1: 5 -> 4
	var box1 = box_scene.instantiate()
	root.add_child(box1)
	player.held_item = box1
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 4 and player.held_item is FriesPack:
		print("  [PASS] 1ª porção retirada! Restam 4 porções no cesto. Jogador recebeu Batata Frita.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na 1ª porção: restam %d" % fryer.compartments[0]["portions_remaining"])

	# Descarta a porção embalada das mãos para pegar próxima caixinha
	player.held_item.queue_free()
	player.held_item = null

	# Porção 2: 4 -> 3
	var box2 = box_scene.instantiate()
	root.add_child(box2)
	player.held_item = box2
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 3:
		print("  [PASS] 2ª porção retirada! Restam 3 porções no cesto.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na 2ª porção: restam %d" % fryer.compartments[0]["portions_remaining"])

	player.held_item.queue_free()
	player.held_item = null

	# Porção 3: 3 -> 2
	var box3 = box_scene.instantiate()
	root.add_child(box3)
	player.held_item = box3
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 2:
		print("  [PASS] 3ª porção retirada! Restam 2 porções no cesto.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na 3ª porção: restam %d" % fryer.compartments[0]["portions_remaining"])

	player.held_item.queue_free()
	player.held_item = null

	# Porção 4: 2 -> 1
	var box4 = box_scene.instantiate()
	root.add_child(box4)
	player.held_item = box4
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 1:
		print("  [PASS] 4ª porção retirada! Resta 1 porção no cesto.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na 4ª porção: restam %d" % fryer.compartments[0]["portions_remaining"])

	player.held_item.queue_free()
	player.held_item = null

	# Porção 5: 1 -> 0 (Cesto fica vazio novamente!)
	var box5 = box_scene.instantiate()
	root.add_child(box5)
	player.held_item = box5
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["portions_remaining"] == 0 and fryer.compartments[0]["food_state"] == "empty":
		print("  [PASS] 5ª e última porção retirada! Cesto 0 agora está completamente VAZIO.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na 5ª porção: state=%s, portions=%d" % [fryer.compartments[0]["food_state"], fryer.compartments[0]["portions_remaining"]])

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
