extends SceneTree

# ===========================================================================
# TESTE COMPLETO: TEMPO DE FRITURA DAS BATATAS (3.5x) E ENTREGA NO DRIVE-THRU
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: TEMPO DE FRITURA DAS BATATAS (3.5x) E ENTREGA NO DRIVE-THRU")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# 1. TEMPO DE FRITURA DAS BATATAS (28.0s = 8.0s * 3.5)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Tempo de Fritura da Fritadeira (3.5x = 28.0s) ---")

	var pm = PowerManager.get_instance()
	if pm:
		pm.is_main_power_on = true

	var fryer_scene = load("res://src/stations/fryer.tscn")
	var fryer = fryer_scene.instantiate() as Fryer
	root.add_child(fryer)
	fryer.is_on = true
	fryer.current_temperature = 180.0

	total_tests += 1
	if is_equal_approx(fryer.cook_time, 28.0) and is_equal_approx(fryer.burn_time, 42.0):
		print("  [PASS] cook_time da fritadeira configurado para 28.0s (3.5x de 8.0s)")
		passed_tests += 1
	else:
		print("  [FAIL] cook_time da fritadeira incorreto: %f" % fryer.cook_time)

	# Adiciona batata congelada na cesta 0 e desce a cesta
	fryer.compartments[0]["food_state"] = "frozen"
	fryer.compartments[0]["basket_down"] = true # desce para o óleo

	total_tests += 1
	if fryer.compartments[0]["food_state"] == "frozen" and fryer.compartments[0]["basket_down"]:
		print("  [PASS] Batata congelada submersa na cuba 0 com sucesso")
		passed_tests += 1
	else:
		print("  [FAIL] Estado inicial da batata incorreto")

	# Avança 14.0 segundos (50% do tempo)
	fryer._process(14.0)
	total_tests += 1
	if fryer.compartments[0]["food_state"] == "cooking" and is_equal_approx(fryer.compartments[0]["timer"], 14.0):
		print("  [PASS] Em 14.0s (metade de 28.0s), estado é 'cooking' com progresso de 50%%")
		passed_tests += 1
	else:
		print("  [FAIL] Estado em 14.0s incorreto: %s, timer: %f" % [fryer.compartments[0]["food_state"], fryer.compartments[0]["timer"]])

	# Avança mais 14.0 segundos (Total 28.0s -> Pronto!)
	fryer._process(14.0)
	total_tests += 1
	if fryer.compartments[0]["food_state"] == "cooked":
		print("  [PASS] Em 28.0s, batata atinge estado 'cooked' (Frita e crocante)")
		passed_tests += 1
	else:
		print("  [FAIL] Batata não atingiu 'cooked' em 28.0s: %s" % fryer.compartments[0]["food_state"])

	# -----------------------------------------------------------------------
	# 2. ENTREGA DE PEDIDO CORRETO AO OLHAR PARA O CARRO DO DRIVE-THRU
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Entrega de Pedido Correto ao Olhar para o Carro ---")

	var car_scene = load("res://src/environment/delivery_car.tscn")
	var car = car_scene.instantiate() as DeliveryCar
	root.add_child(car)
	car.current_state = 4 # AT_WINDOW_WAITING_FOOD
	car.car_id = 101

	var order = Order.new()
	order.id = 101
	order.source_type = "DELIVERY"
	order.add_item("burger_classic", "Burger Clássico", 1, 22.90)
	order.add_item("fries", "Batata Frita", 1, 10.0)
	car.current_order = order

	# Cria sacola com itens corretos
	var bag_scene = load("res://src/items/delivery_bag.tscn")
	var bag_correct = bag_scene.instantiate() as DeliveryBag
	root.add_child(bag_correct)

	var pkg = load("res://src/items/packaged_burger.tscn").instantiate() as PackagedBurger
	root.add_child(pkg)
	pkg.recipe_id = "burger_classic"
	pkg.burger_name = "Burger Clássico"
	bag_correct.add_contained_item(pkg)

	var fries_pack = FriesPack.new()
	root.add_child(fries_pack)
	bag_correct.add_contained_item(fries_pack)

	# Simula player segurando a sacola
	var player_script = load("res://src/player/player.gd")
	var player = CharacterBody3D.new()
	player.set_script(player_script)
	root.add_child(player)
	player.held_item = bag_correct

	# Confirma que o carro exibe prompt de entrega
	total_tests += 1
	var prompt = car.get_interaction_prompt(player)
	if "Entregar" in prompt and "Carro #101" in prompt:
		print("  [PASS] Prompt de entrega ao olhar para o carro: '%s'" % prompt)
		passed_tests += 1
	else:
		print("  [FAIL] Prompt de entrega incorreto: '%s'" % prompt)

	# Jogador interage com o carro (clique ou E)
	car.interact(player)

	total_tests += 1
	if player.held_item == null:
		print("  [PASS] Sacola retirada das mãos do jogador (saiu da mão/bancada)")
		passed_tests += 1
	else:
		print("  [FAIL] Sacola permaneceu nas mãos do jogador!")

	total_tests += 1
	if car.current_state == DeliveryCar.CarState.LEAVING:
		print("  [PASS] Carro recebeu o pedido e transicionou para LEAVING (deixa o drive-thru)")
		passed_tests += 1
	else:
		print("  [FAIL] Carro não entrou no estado LEAVING: %d" % car.current_state)

	total_tests += 1
	if car.experience and car.experience.order_correct and not car.experience.abandoned:
		print("  [PASS] Pedido validado como CORRETO com avaliação positiva")
		passed_tests += 1
	else:
		print("  [FAIL] Pedido correto não foi validado com sucesso")

	# -----------------------------------------------------------------------
	# 3. ENTREGA DE PEDIDO ERRADO AO OLHAR PARA O CARRO DO DRIVE-THRU
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Entrega de Pedido Errado (Transição Garantida & Sem Bloqueio) ---")

	var car_wrong = car_scene.instantiate() as DeliveryCar
	root.add_child(car_wrong)
	car_wrong.current_state = 4 # AT_WINDOW_WAITING_FOOD
	car_wrong.car_id = 102

	var order_expected = Order.new()
	order_expected.id = 102
	order_expected.source_type = "DELIVERY"
	order_expected.add_item("burger_bacon", "Burger Bacon", 1, 28.0)
	car_wrong.current_order = order_expected

	# Cria sacola com item errado (Burger Chicken ao invés de Bacon)
	var bag_wrong = bag_scene.instantiate() as DeliveryBag
	root.add_child(bag_wrong)

	var pkg_wrong = load("res://src/items/packaged_burger.tscn").instantiate() as PackagedBurger
	root.add_child(pkg_wrong)
	pkg_wrong.recipe_id = "burger_chicken"
	pkg_wrong.burger_name = "Burger Chicken"
	bag_wrong.add_contained_item(pkg_wrong)

	player.held_item = bag_wrong

	# Entrega o pedido errado
	car_wrong.interact(player)

	total_tests += 1
	if player.held_item == null:
		print("  [PASS] Sacola de pedido errado TAMBÉM é recolhida das mãos do jogador")
		passed_tests += 1
	else:
		print("  [FAIL] Sacola de pedido errado permaneceu na mão do jogador!")

	total_tests += 1
	if car_wrong.current_state == DeliveryCar.CarState.LEAVING:
		print("  [PASS] Carro transiciona para LEAVING e vai embora sem travar")
		passed_tests += 1
	else:
		print("  [FAIL] Carro não transicionou para LEAVING")

	total_tests += 1
	if car_wrong.experience and car_wrong.experience.abandon_type == CustomerExperience.AbandonType.WRONG_ORDER:
		print("  [PASS] Cliente identifica que o pedido está errado (WRONG_ORDER) e não paga")
		passed_tests += 1
	else:
		print("  [FAIL] Telemetria não registrou WRONG_ORDER")

	total_tests += 1
	var car_label = car_wrong.status_label.text if car_wrong.status_label else ""
	if "não é o meu" in car_label.to_lower() or "errad" in car_label.to_lower():
		print("  [PASS] Fala do motorista expressa recusa por pedido errado: \"%s\"" % car_label)
		passed_tests += 1
	else:
		print("  [FAIL] Fala do motorista incorreta: \"%s\"" % car_label)

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
