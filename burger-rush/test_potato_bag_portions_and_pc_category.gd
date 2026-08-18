extends SceneTree

# ===========================================================================
# TESTE: SACO DE BATATA (INGREDIENTES), CESTO CHEIO E 5 PORÇÕES SUCESSIVAS
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: SACO DE BATATA NO PC, CESTO CHEIO E 5 PORÇÕES")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# 1. CATEGORIZAÇÃO NO ESTOQUE E NO PC (INGREDIENTES vs EMBALAGENS)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Categorização no PC e Estoque ---")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._ready()

	var pot_data = inv.get_item_data("potato_raw")
	total_tests += 1
	if pot_data and pot_data.get("category") == "vegetables":
		print("  [PASS] potato_raw cadastrado na categoria de ingredientes ('vegetables')")
		passed_tests += 1
	else:
		print("  [FAIL] potato_raw com categoria incorreta: %s" % str(pot_data.get("category")))

	# Testa filtro do PC
	var comp_ui = load("res://src/ui/computer_ui.tscn").instantiate() as ComputerUI
	root.add_child(comp_ui)

	total_tests += 1
	var is_in_supplies = comp_ui._is_item_in_filter(pot_data.get("category"), "SUPPLIES")
	if not is_in_supplies:
		print("  [PASS] Saco de batata NÃO aparece no filtro de EMBALAGENS (SUPPLIES)")
		passed_tests += 1
	else:
		print("  [FAIL] Saco de batata apareceu incorretamente no filtro de EMBALAGENS!")

	total_tests += 1
	var is_in_ing = comp_ui._is_item_in_filter(pot_data.get("category"), "INGREDIENTS")
	if is_in_ing:
		print("  [PASS] Saco de batata aparece no filtro de INGREDIENTES")
		passed_tests += 1
	else:
		print("  [FAIL] Saco de batata não apareceu no filtro de INGREDIENTES!")

	total_tests += 1
	var icon = comp_ui._get_item_icon("potato_raw")
	if icon == "🥔":
		print("  [PASS] Ícone do saco de batata configurado como 🥔")
		passed_tests += 1
	else:
		print("  [FAIL] Ícone incorreto para saco de batata: %s" % icon)

	# -----------------------------------------------------------------------
	# 2. FRITADEIRA — 1 SACO ABASTECE 1 CESTO (5 PORÇÕES) E FEEDBACK DISCRETO
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Fritadeira — 1 Saco = 1 Cesto Cheio -> 5 Porções ---")

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
	var bag_pot = pot_scene.instantiate() as Potato
	root.add_child(bag_pot)

	var player = CharacterBody3D.new()
	var player_script = load("res://src/player/player.gd")
	player.set_script(player_script)
	root.add_child(player)
	player.held_item = bag_pot

	# Abastece Cesto 0
	fryer.interact_item(player)

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "frozen" and fryer.compartments[0]["portions_remaining"] == 5 and player.held_item == null:
		print("  [PASS] Cesto 0 abastecido com 5 porções e saco consumido!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha no abastecimento: state=%s, portions=%d" % [fryer.compartments[0]["food_state"], fryer.compartments[0]["portions_remaining"]])

	# Abaixa o Cesto 0 para iniciar fritura
	fryer.toggle_basket(0)

	# Avança 54.6s (65% do tempo de 84.0s)
	fryer._process(54.6)

	total_tests += 1
	var prompt = fryer.get_interaction_prompt(player)
	if prompt == "🍟 Batata Fritando (65%)":
		print("  [PASS] Prompt discreto no mesmo estilo do hambúrguer: '%s'" % prompt)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de fritura incorreto: '%s'" % prompt)

	# Avança até 85.0s (100% -> Pronta!)
	fryer._process(30.4)

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "cooked" and fryer.compartments[0]["portions_remaining"] == 5:
		print("  [PASS] Batatas atingiram estado 'cooked' com 5 porções prontas.")
		passed_tests += 1
	else:
		print("  [FAIL] Batata não atingiu estado de pronta aos 84.0s")

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
