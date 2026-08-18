extends SceneTree

# ===========================================================================
# TESTE: TEMPO DE FRITURA DE OVO (+25%), BACON (+100%), PROMPTS DISCRETOS
#        E EMBALAGEM VERMELHA UNIFICADA (BATATA E CEBOLA)
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: OVO (+25%), BACON (+100%), PROMPTS E EMBALAGEM UNIFICADA")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# 1. SETUP DE COMPONENTES BÁSICOS
	# -----------------------------------------------------------------------
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._ready()

	var pm = PowerManager.new()
	root.add_child(pm)
	PowerManager.instance = pm
	pm.is_main_power_on = true

	var player = load("res://src/player/player.tscn").instantiate() as CharacterBody3D
	root.add_child(player)

	# -----------------------------------------------------------------------
	# 2. TESTES DE OVO NA CHAPA (+25% / 8.125s) E FEEDBACK DISCRETO
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Fritura do Ovo (+25% / 8.125s) e Porcentagem Discreta ---")

	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill._ready()
	grill.is_on = true
	grill.current_temperature = 180.0

	var egg_scene = load("res://src/items/egg.tscn")
	var egg = egg_scene.instantiate() as Egg
	root.add_child(egg)

	total_tests += 1
	if is_equal_approx(grill.egg_cook_time, 8.125):
		print("  [PASS] Tempo de fritura do ovo configurado para 8.125s (+25%% de 6.5s)!")
		passed_tests += 1
	else:
		print("  [FAIL] Tempo do ovo incorreto: %.3f" % grill.egg_cook_time)

	# Coloca o ovo na chapa
	grill.place_item(egg)

	# Avança 4.0625s (50% do tempo de 8.125s)
	grill._process(4.0625)

	total_tests += 1
	var prompt_egg = egg.get_interaction_prompt(player)
	if prompt_egg == "🍳 Ovo Fritando (50%)":
		print("  [PASS] Prompt discreto do ovo em 50%%: '%s'" % prompt_egg)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt do ovo incorreto aos 50%%: '%s'" % prompt_egg)

	# Avança até 8.2s (100% -> Pronto!)
	grill._process(4.2)

	total_tests += 1
	if egg.state == Egg.State.COOKED:
		print("  [PASS] Ovo completamente frito (Estado COOKED) aos 8.125s!")
		passed_tests += 1
	else:
		print("  [FAIL] Ovo não atingiu estado COOKED: %s" % str(egg.state))

	total_tests += 1
	var prompt_cooked_egg = egg.get_interaction_prompt(player)
	if prompt_cooked_egg == "🍳 [Clique] Pegar Ovo Frito Pronto":
		print("  [PASS] Prompt do ovo pronto: '%s'" % prompt_cooked_egg)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt do ovo pronto incorreto: '%s'" % prompt_cooked_egg)

	grill._remove_item_from_grill(egg, null)
	egg.queue_free()

	# -----------------------------------------------------------------------
	# 3. TESTES DE BACON NA CHAPA (+100% / 12.0s) E FEEDBACK DISCRETO
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Fritura do Bacon (+100% / 12.0s) e Porcentagem Discreta ---")

	var bacon_scene = load("res://src/items/bacon.tscn")
	var bacon = bacon_scene.instantiate() as Bacon
	root.add_child(bacon)

	total_tests += 1
	if is_equal_approx(grill.bacon_cook_time, 12.0):
		print("  [PASS] Tempo de fritura do bacon configurado para 12.0s (+100%% de 6.0s)!")
		passed_tests += 1
	else:
		print("  [FAIL] Tempo do bacon incorreto: %.3f" % grill.bacon_cook_time)

	# Coloca o bacon na chapa
	grill.place_item(bacon)

	# Avança 6.0s (50% do tempo de 12.0s)
	grill._process(6.0)

	total_tests += 1
	var prompt_bacon = bacon.get_interaction_prompt(player)
	if prompt_bacon == "🥓 Bacon Fritando (50%)":
		print("  [PASS] Prompt discreto do bacon em 50%%: '%s'" % prompt_bacon)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt do bacon incorreto aos 50%%: '%s'" % prompt_bacon)

	# Avança até 12.2s (100% -> Pronto!)
	grill._process(6.2)

	total_tests += 1
	if bacon.state == Bacon.State.COOKED:
		print("  [PASS] Bacon completamente crocante (Estado COOKED) aos 12.0s!")
		passed_tests += 1
	else:
		print("  [FAIL] Bacon não atingiu estado COOKED: %s" % str(bacon.state))

	total_tests += 1
	var prompt_cooked_bacon = bacon.get_interaction_prompt(player)
	if prompt_cooked_bacon == "🥓 [Clique] Pegar Bacon Crocante Pronto":
		print("  [PASS] Prompt do bacon pronto: '%s'" % prompt_cooked_bacon)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt do bacon pronto incorreto: '%s'" % prompt_cooked_bacon)

	grill._remove_item_from_grill(bacon, null)
	bacon.queue_free()

	# -----------------------------------------------------------------------
	# 4. TESTES DA EMBALAGEM FÍSICA UNIFICADA (VAZIA -> BATATA -> CEBOLA)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Embalagem Vermelha Física Única e Unificada ---")

	var potato_box_scene = load("res://src/items/potato_box.tscn")
	var box = potato_box_scene.instantiate() as FriesPack
	root.add_child(box)
	box._ready()

	var red_container = box.get_node_or_null("MeshInstance3D/RedContainer")
	var fries_content = box.get_node_or_null("MeshInstance3D/FriesContent")
	var onion_content = box.get_node_or_null("MeshInstance3D/OnionRingsContent")

	total_tests += 1
	if red_container != null and red_container.visible:
		print("  [PASS] Embalagem vazia possui o recipiente vermelho (RedContainer) visível.")
		passed_tests += 1
	else:
		print("  [FAIL] RedContainer ausente na embalagem vazia!")

	total_tests += 1
	if not fries_content.visible and not onion_content.visible:
		print("  [PASS] Embalagem vazia: sem alimentos visíveis dentro.")
		passed_tests += 1
	else:
		print("  [FAIL] Embalagem vazia contém alimentos visíveis indevidamente!")

	# Coloca batatas na MESMA embalagem
	box.set_side_type("fries")

	total_tests += 1
	if red_container.visible and fries_content.visible and not onion_content.visible:
		print("  [PASS] Batata Frita na mesma embalagem: Recipiente vermelho + Batatas dentro visíveis!")
		passed_tests += 1
	else:
		print("  [FAIL] Visual da batata frita incorreto na embalagem!")

	# Pega na mão do jogador
	box.is_held = true
	total_tests += 1
	if box.is_held and fries_content.get_parent().get_parent() == box:
		print("  [PASS] Sincronização física: Alimento é filho direto da embalagem e acompanha mão/movimento.")
		passed_tests += 1
	else:
		print("  [FAIL] Sincronização física quebrada!")

	# Coloca cebolas na MESMA embalagem
	box.set_side_type("onion_rings")

	total_tests += 1
	if red_container.visible and onion_content.visible and not fries_content.visible:
		print("  [PASS] Cebola Frita na mesma embalagem: Recipiente vermelho + Anéis de cebola dentro visíveis!")
		passed_tests += 1
	else:
		print("  [FAIL] Visual da cebola frita incorreto na embalagem!")

	total_tests += 1
	if box.item_id == "onion_rings" and box.display_name == "Cebola Frita":
		print("  [PASS] Nomenclatura e identificação perfeitamente sincronizadas ('Cebola Frita').")
		passed_tests += 1
	else:
		print("  [FAIL] Identificação do item incorreta: %s" % box.item_id)

	box.queue_free()

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
