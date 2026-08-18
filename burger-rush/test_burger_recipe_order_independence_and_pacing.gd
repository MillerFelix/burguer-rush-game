extends SceneTree

# =============================================================================
# TEST SUITE: BURGER RECIPE IDENTIFICATION (ORDER INDEPENDENCE) & PACING
# =============================================================================

const RecipeDatabaseScript = preload("res://src/recipes/recipe_database.gd")
const BurgerAssemblyScript = preload("res://src/recipes/burger_assembly.gd")
const PackagedBurgerScript = preload("res://src/items/packaged_burger.gd")
const DeliveryBagScript = preload("res://src/items/delivery_bag.gd")
const DeliveryWindowStationScript = preload("res://src/stations/delivery_window_station.gd")
const DeliveryMotorcycleCourierScript = preload("res://src/customers/delivery_motorcycle_courier.gd")
const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const OrderScript = preload("res://src/orders/order.gd")
const EconomyManagerScript = preload("res://src/economy/economy_manager.gd")
const FinanceManagerScript = preload("res://src/economy/finance_manager.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: IDENTIFICAÇÃO DE RECEITAS (ORDEM INDEPENDENTE) & BALANCEAMENTO")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP MANAGERS
	var om = OrderManagerScript.new()
	om.name = "OrderManager"
	root.add_child(om)
	OrderManagerScript.instance = om

	var econ = EconomyManagerScript.new()
	econ.name = "EconomyManager"
	root.add_child(econ)
	EconomyManagerScript.instance = econ
	econ.current_money = 500.0

	var fin = FinanceManagerScript.new()
	fin.name = "FinanceManager"
	root.add_child(fin)
	FinanceManagerScript.instance = fin

	# --- TESTE 1: Montagem de Burger Onion na Ordem Padrão ---
	total_tests += 1
	var assembly_onion_std = BurgerAssemblyScript.new()
	var keys_std: Array[String] = ["patty_beef:cooked", "cheese_cheddar", "onion", "red_onion"]
	assembly_onion_std.ingredient_keys = keys_std
	assembly_onion_std.applied_sauces = {"mayo": 30.0}
	assembly_onion_std.state = BurgerAssemblyScript.State.CLOSED
	assembly_onion_std._check_recipe_match()

	var box_onion_std = PackagedBurgerScript.new()
	box_onion_std.setup_from_recipe(assembly_onion_std.matched_recipe, assembly_onion_std.ingredient_keys, assembly_onion_std.is_valid_recipe)

	var bag_onion_std = DeliveryBagScript.new()
	bag_onion_std.add_contained_item(box_onion_std)

	var bag_items_std = bag_onion_std.get_products()
	if not bag_items_std.is_empty() and bag_items_std[0]["recipe_id"] == "burger_onion" and bag_items_std[0]["name"] == "Burger Onion":
		print("  ✅ TESTE 1: Burger Onion na ordem padrão -> Caixinha e Sacola identificam 'Burger Onion'.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Burger Onion padrão identificado como: %s" % (bag_items_std[0]["name"] if not bag_items_std.is_empty() else "Nulo"))

	# --- TESTE 2: Montagem de Burger Onion em Ordem Invertida / Embaralhada ---
	total_tests += 1
	var assembly_onion_inv = BurgerAssemblyScript.new()
	# Ordem embaralhada: Cebola roxa -> Maionese -> Queijo -> Cebola comum -> Carne
	var keys_inv: Array[String] = ["red_onion", "cheese_cheddar", "onion", "patty_beef:cooked"]
	assembly_onion_inv.ingredient_keys = keys_inv
	assembly_onion_inv.applied_sauces = {"mayo": 45.0}
	assembly_onion_inv.state = BurgerAssemblyScript.State.CLOSED
	assembly_onion_inv._check_recipe_match()

	var box_onion_inv = PackagedBurgerScript.new()
	box_onion_inv.setup_from_recipe(assembly_onion_inv.matched_recipe, assembly_onion_inv.ingredient_keys, assembly_onion_inv.is_valid_recipe)

	var bag_onion_inv = DeliveryBagScript.new()
	bag_onion_inv.add_contained_item(box_onion_inv)

	var bag_items_inv = bag_onion_inv.get_products()
	if not bag_items_inv.is_empty() and bag_items_inv[0]["recipe_id"] == "burger_onion" and bag_items_inv[0]["name"] == "Burger Onion":
		print("  ✅ TESTE 2: Burger Onion em ordem invertida -> Caixinha e Sacola identificam corretamente 'Burger Onion'.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Burger Onion invertido identificado como: %s" % (bag_items_inv[0]["name"] if not bag_items_inv.is_empty() else "Nulo"))

	# --- TESTE 3: Montagem de Burger Cheddar ---
	total_tests += 1
	var assembly_cheddar = BurgerAssemblyScript.new()
	var keys_ched: Array[String] = ["patty_beef:cooked", "cheese_cheddar", "bacon", "red_onion"]
	assembly_cheddar.ingredient_keys = keys_ched
	assembly_cheddar.state = BurgerAssemblyScript.State.CLOSED
	assembly_cheddar._check_recipe_match()

	var box_cheddar = PackagedBurgerScript.new()
	box_cheddar.setup_from_recipe(assembly_cheddar.matched_recipe, assembly_cheddar.ingredient_keys, assembly_cheddar.is_valid_recipe)

	var bag_cheddar = DeliveryBagScript.new()
	bag_cheddar.add_contained_item(box_cheddar)

	var bag_items_ched = bag_cheddar.get_products()
	if not bag_items_ched.is_empty() and bag_items_ched[0]["recipe_id"] == "burger_cheddar" and bag_items_ched[0]["name"] == "Burger Cheddar":
		print("  ✅ TESTE 3: Burger Cheddar -> Caixinha e Sacola identificam 'Burger Cheddar'.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Burger Cheddar identificado incorretamente como: %s" % (bag_items_ched[0]["name"] if not bag_items_ched.is_empty() else "Nulo"))

	# --- TESTE 4: Comparação Delivery — Pedido Pedia Burger Onion, Jogador Entregou Burger Cheddar (Pedido Errado) ---
	total_tests += 1
	var order_onion = om.create_delivery_order()
	var ord_items_onion: Array[Dictionary] = [
		{"product_id": "burger_onion", "product_name": "Burger Onion", "quantity": 1, "unit_price": 26.90}
	]
	order_onion.items = ord_items_onion
	order_onion.total_price = 26.90
	om.accept_delivery_order(order_onion.id)

	var validation_wrong = order_onion.matches_delivery_bag(bag_cheddar)
	if validation_wrong.get("matches", false) == false:
		print("  ✅ TESTE 4: Sacola com Burger Cheddar rejeitada para pedido de Burger Onion -> Incorreto!")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Pedido aceitou lanche diferente indevidamente!")

	# --- TESTE 5: Fluxo Físico Completo de Pedido Incorreto na Janela com Motoboy ---
	total_tests += 1
	var window_scene: PackedScene = load("res://src/stations/delivery_window_station.tscn")
	var window_station = window_scene.instantiate()
	root.add_child(window_station)

	# Coloca o saco com Burger Cheddar na janela para o pedido que pedia Burger Onion
	window_station._place_bag_on_station(bag_cheddar)

	var courier_wrong_scene: PackedScene = load("res://src/customers/delivery_motorcycle_courier.tscn")
	var courier_wrong = courier_wrong_scene.instantiate()
	root.add_child(courier_wrong)
	courier_wrong.target_window_station = window_station

	# Motoboy coleta pela janela
	courier_wrong._perform_pickup()
	var courier_got_bag = (courier_wrong.held_bag == bag_cheddar)

	var initial_money = econ.get_money()
	courier_wrong._finalize_delivery()
	var final_money = econ.get_money()

	if courier_got_bag and is_equal_approx(initial_money, final_money) and order_onion.is_wrong_delivery == true and order_onion.is_paid == false and order_onion.payment_amount == 0.0:
		print("  ✅ TESTE 5: Pedido Incorreto -> Motoboy pegou saco na janela, finalizou -> R$ 0,00 registrado com sucesso!")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Fluxo de pedido incorreto com motoboy falhou.")

	# --- TESTE 6: Fluxo Físico Completo de Pedido Correto na Janela com Motoboy ---
	total_tests += 1
	var order_correct = om.create_delivery_order()
	var ord_items_correct: Array[Dictionary] = [
		{"product_id": "burger_onion", "product_name": "Burger Onion", "quantity": 1, "unit_price": 26.90}
	]
	order_correct.items = ord_items_correct
	order_correct.total_price = 26.90
	om.accept_delivery_order(order_correct.id)

	# Coloca o saco com Burger Onion (montado em ordem embaralhada) na janela
	window_station._place_bag_on_station(bag_onion_inv)

	var courier_correct = courier_wrong_scene.instantiate()
	root.add_child(courier_correct)
	courier_correct.target_window_station = window_station

	courier_correct._perform_pickup()
	var courier_got_correct_bag = (courier_correct.held_bag == bag_onion_inv)

	var initial_money_c = econ.get_money()
	courier_correct._finalize_delivery()
	var final_money_c = econ.get_money()
	var delivery_revenue = fin.daily_revenue.get("delivery", 0.0)

	if courier_got_correct_bag and is_equal_approx(final_money_c, initial_money_c + 26.90) and is_equal_approx(delivery_revenue, 26.90) and order_correct.is_paid == true:
		print("  ✅ TESTE 6: Pedido Correto -> Motoboy pegou saco na janela, finalizou -> +R$ 26.90 confirmado!")
		passed_tests += 1
	else:
		print("  ❌ TESTE 6 FALHOU: Fluxo de pedido correto com motoboy falhou.")

	# --- TESTE 7: Verificação do Rebalanceamento de Cadência (~50% Redução de Frequência) ---
	total_tests += 1
	var dt_queue_script = load("res://src/customers/delivery_queue_manager.gd")
	var dt_mgr = dt_queue_script.new()
	root.add_child(dt_mgr)

	var dt_lunch_interval = dt_mgr._calculate_interval_for_time(12.5) # Horário de almoço
	var dt_morning_interval = dt_mgr._calculate_interval_for_time(10.5) # Horário da manhã

	if dt_lunch_interval >= 70.0 and dt_morning_interval >= 105.0:
		print("  ✅ TESTE 7: Intervalos de Drive-thru rebalanceados com cadência de ~50%% menos frequente.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 7 FALHOU: Intervalos de Drive-thru ainda excessivamente rápidos.")

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
