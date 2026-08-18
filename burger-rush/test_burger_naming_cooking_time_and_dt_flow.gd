extends SceneTree

# ===========================================================================
# TESTE COMPLETO: TEMPOS DE COCÇÃO, NOMENCLATURA E FLUXO DO DRIVE-THRU
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: TEMPOS DE COCÇÃO (+50%), NOMENCLATURA E DRIVE-THRU")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# 1. NOMENCLATURA DOS LANCHES NA SACOLA E NO PACKAGED BURGER
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Nomenclatura dos Lanches (Nomes Oficiais do Cardápio) ---")

	var packaged_scene = load("res://src/items/packaged_burger.tscn")
	var bag_scene = load("res://src/items/delivery_bag.tscn")

	total_tests += 1
	if packaged_scene and bag_scene:
		print("  [PASS] Cenas de PackagedBurger e DeliveryBag carregadas com sucesso")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao carregar cenas básicas")

	# Cria PackagedBurger com receita de "Burger Clássico"
	var pkg1 = packaged_scene.instantiate() as PackagedBurger
	root.add_child(pkg1)
	var recipes = RecipeDatabase.get_all_recipes()
	var classic_rec = null
	for r in recipes:
		if r.id == "burger_classic":
			classic_rec = r
			break
	pkg1.setup_from_recipe(classic_rec, ["bread", "patty_beef:cooked", "cheese_cheddar", "lettuce", "tomato", "onion", "ketchup", "mustard"], true)

	total_tests += 1
	if pkg1.burger_name == "Burger Clássico" and pkg1.get_display_name() == "Burger Clássico":
		print("  [PASS] Nome do lanche clássico configurado como '%s'" % pkg1.burger_name)
		passed_tests += 1
	else:
		print("  [FAIL] Nome incorreto para lanche clássico: '%s'" % pkg1.burger_name)

	# Cria PackagedBurger com ingredientes de bacon (sem objeto Recipe explícito)
	var pkg2 = packaged_scene.instantiate() as PackagedBurger
	root.add_child(pkg2)
	pkg2.setup_from_recipe(null, ["bread", "patty_beef:cooked", "cheese_prato", "bacon", "mayo"], false)

	total_tests += 1
	if pkg2.burger_name == "Burger Bacon" and "artesanal" not in pkg2.burger_name.to_lower():
		print("  [PASS] Inferência de lanche específico sem receita gerou '%s' (Zero 'Artesanal')" % pkg2.burger_name)
		passed_tests += 1
	else:
		print("  [FAIL] Inferência falhou ou gerou nome genérico: '%s'" % pkg2.burger_name)

	# Adiciona à sacola de delivery e verifica a nomenclatura exibida
	var bag = bag_scene.instantiate() as DeliveryBag
	root.add_child(bag)
	bag.add_contained_item(pkg1)

	var fries = FriesPack.new()
	root.add_child(fries)
	bag.add_contained_item(fries)

	var cup_scene = load("res://src/items/drink_cup.tscn")
	var cup = cup_scene.instantiate() as DrinkCup
	root.add_child(cup)
	cup.set_flavor("soda_cola")
	cup.set_state(DrinkCup.State.FILLED)
	bag.add_contained_item(cup)

	total_tests += 1
	var bag_display = bag.get_display_name()
	if "Burger Clássico" in bag_display and "Batata Frita" in bag_display and "Copo de Cola" in bag_display:
		print("  [PASS] Nomenclatura na sacola perfeitamente formatada: '%s'" % bag_display)
		passed_tests += 1
	else:
		print("  [FAIL] Nomenclatura na sacola incorreta: '%s'" % bag_display)

	total_tests += 1
	if "artesanal" not in bag_display.to_lower():
		print("  [PASS] Confirmado: Nenhum termo genérico 'artesanal' presente na sacola")
		passed_tests += 1
	else:
		print("  [FAIL] Termo genérico 'artesanal' ainda presente na sacola!")

	# -----------------------------------------------------------------------
	# 2. TEMPOS DE COCÇÃO DOS HAMBÚRGUERES (+50%)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Tempo de Cocção dos Hambúrgueres (+50%) ---")

	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill.is_on = true
	grill.current_temperature = 180.0 # Temperatura ideal

	total_tests += 1
	if is_equal_approx(grill.patty_side_cook_time, 15.0) and is_equal_approx(grill.patty_burn_time, 15.0):
		print("  [PASS] Tempos da chapa para hambúrguer configurados para 15.0s por lado (Total 30s + 15s queima = +50%%)")
		passed_tests += 1
	else:
		print("  [FAIL] Tempos de cocção do hambúrguer não estão em 15.0s (atual: %f)" % grill.patty_side_cook_time)

	# Simula evolução do hambúrguer
	var patty_scene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate() as Patty
	root.add_child(patty)

	total_tests += 1
	if patty.state == Patty.State.RAW:
		print("  [PASS] Hambúrguer inicia no estado RAW (Cru)")
		passed_tests += 1
	else:
		print("  [FAIL] Hambúrguer não iniciou RAW")

	# Avança 7.5 segundos (50% do Lado 1 no novo tempo de 15s)
	patty.advance_cooking((100.0 / grill.patty_side_cook_time) * 7.5)
	total_tests += 1
	if patty.state == Patty.State.COOKING_SIDE_1 and is_equal_approx(patty.side_a_cooked, 50.0):
		print("  [PASS] Após 7.5s (metade de 15s), Lado 1 está exatamente em 50%%")
		passed_tests += 1
	else:
		print("  [FAIL] Progresso de 7.5s incorreto: %f%%" % patty.side_a_cooked)

	# Avança mais 7.5 segundos (Total 15.0s -> Lado 1 Pronto!)
	patty.advance_cooking((100.0 / grill.patty_side_cook_time) * 7.5)
	total_tests += 1
	if patty.state == Patty.State.READY_SIDE_1 and patty.side_a_cooked >= 100.0:
		print("  [PASS] Após 15.0s, Lado 1 atingiu 100%% e estado é READY_SIDE_1")
		passed_tests += 1
	else:
		print("  [FAIL] Lado 1 não ficou pronto em 15.0s (estado: %d, progresso: %f)" % [patty.state, patty.side_a_cooked])

	# Vira o hambúrguer e frita o Lado 2 por mais 15.0s
	patty.flip()
	patty.advance_cooking((100.0 / grill.patty_side_cook_time) * 15.0)
	total_tests += 1
	if patty.is_fully_cooked() and patty.state == Patty.State.COOKED:
		print("  [PASS] Hambúrguer totalmente grelhado e no ponto após 30.0s totais (15s cada lado)")
		passed_tests += 1
	else:
		print("  [FAIL] Hambúrguer não atingiu estado COOKED após 30.0s")

	# -----------------------------------------------------------------------
	# 3. TEMPO DE COCÇÃO DOS 3 TIPOS DE QUEIJO (+50%)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Tempo de Cocção dos 3 Tipos de Queijo (+50%) ---")

	total_tests += 1
	if is_equal_approx(grill.cheese_cook_time, 9.0) and is_equal_approx(grill.cheese_burn_time, 10.5):
		print("  [PASS] Tempo de derretimento do queijo na chapa configurado para 9.0s (+50%% de 6.0s)")
		passed_tests += 1
	else:
		print("  [FAIL] Tempo de cocção do queijo incorreto: %f" % grill.cheese_cook_time)

	var cheese_types = [Cheese.CheeseType.CHEDDAR, Cheese.CheeseType.MOZZARELLA, Cheese.CheeseType.PRATO]
	var cheese_names = ["Cheddar", "Muçarela", "Prato"]

	var cheese_scene = load("res://src/items/cheese.tscn")

	for i in range(cheese_types.size()):
		var c_type = cheese_types[i]
		var c_name = cheese_names[i]

		var ch = cheese_scene.instantiate() as Cheese
		ch.cheese_type = c_type
		root.add_child(ch)

		total_tests += 1
		if ch.state == Cheese.State.RAW and ch.is_grillable:
			print("  [PASS] Queijo %s inicia no estado RAW (Cru)" % c_name)
			passed_tests += 1
		else:
			print("  [FAIL] Queijo %s com estado inicial incorreto" % c_name)

		# Frita por 4.5s (50% do novo tempo de 9.0s)
		ch.advance_cooking((100.0 / 9.0) * 4.5)
		total_tests += 1
		if ch.state == Cheese.State.FRYING and is_equal_approx(ch.cook_progress, 50.0):
			print("  [PASS] Queijo %s em 4.5s está em estado FRYING (50%% derretido)" % c_name)
			passed_tests += 1
		else:
			print("  [FAIL] Queijo %s progresso incorreto: %f%%" % [c_name, ch.cook_progress])

		# Frita por mais 4.5s (Total 9.0s -> Derretido!)
		ch.advance_cooking((100.0 / 9.0) * 4.5)
		total_tests += 1
		if ch.is_ready() and ch.state == Cheese.State.READY:
			print("  [PASS] Queijo %s completamente derretido e pronto após 9.0s" % c_name)
			passed_tests += 1
		else:
			print("  [FAIL] Queijo %s não ficou pronto em 9.0s" % c_name)

		ch.queue_free()

	# -----------------------------------------------------------------------
	# 4. FLUXO DO DRIVE-THRU E EVENTOS DIÁRIOS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Fluxo de Carros no Drive-Thru e Multiplicador de Eventos ---")

	var dqm = DeliveryQueueManager.new()
	root.add_child(dqm)

	# Testa intervalo em dia normal (hora 12.0 = almoço)
	var normal_interval = dqm._calculate_interval_for_time(12.0)
	total_tests += 1
	if normal_interval >= 20.0 and normal_interval <= 28.0:
		print("  [PASS] Intervalo de almoço em dia normal ajustado para 20.0s a 28.0s (fluxo levemente reduzido)")
		passed_tests += 1
	else:
		print("  [FAIL] Intervalo de almoço fora da faixa esperada: %f" % normal_interval)

	# Testa evento de tempestade (STORM_DAY: drive_thru_multiplier = 1.50)
	var event_mgr = DailyEventManager.new()
	event_mgr.name = "DailyEventManager"
	root.add_child(event_mgr)
	DailyEventManager.instance = event_mgr
	event_mgr.drive_thru_multiplier = 1.50

	var storm_interval = dqm._calculate_interval_for_time(12.0)
	total_tests += 1
	if storm_interval < normal_interval and storm_interval >= (20.0 / 1.50) * 0.95:
		print("  [PASS] Evento com multiplicador 1.50 acelera fluxo do Drive-Thru com sucesso (%f s < %f s)" % [storm_interval, normal_interval])
		passed_tests += 1
	else:
		print("  [FAIL] Evento não acelerou o drive-thru adequadamente: storm=%f, normal=%f" % [storm_interval, normal_interval])

	# -----------------------------------------------------------------------
	# 5. PRESERVAÇÃO DAS REGRAS DA CHAPA (Ingredientes não-fritáveis)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Preservação das Regras da Chapa ---")

	var bread = Item.new()
	bread.item_id = "bread_bottom"
	bread.is_grillable = false
	root.add_child(bread)

	total_tests += 1
	if not grill.can_cook_item(bread):
		print("  [PASS] Chapa REJEITA ingredientes não-fritáveis (Pão é bloqueado)")
		passed_tests += 1
	else:
		print("  [FAIL] Chapa aceitou ingrediente não-fritável!")

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
