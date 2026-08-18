extends SceneTree

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const InventoryManager = preload("res://src/inventory/inventory_manager.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const RecipeDatabase = preload("res://src/recipes/recipe_database.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: REVISÃO DE RECEITAS DOS BURGERS E SUCOS DE POLPA")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP DO SISTEMA
	var pm = PurchaseManager.new()
	pm.name = "PurchaseManager"
	root.add_child(pm)
	pm._ready()
	PurchaseManager.instance = pm

	var inv = InventoryManager.new()
	inv.name = "InventoryManager"
	root.add_child(inv)
	inv._ready()
	InventoryManager.instance = inv

	var om = OrderManager.new()
	om.name = "OrderManager"
	root.add_child(om)
	om._ready()
	OrderManager.instance = om

	var computer_ui_scene = load("res://src/ui/computer_ui.tscn")
	var comp_ui = computer_ui_scene.instantiate() as ComputerUI
	root.add_child(comp_ui)
	comp_ui._ready()

	# -----------------------------------------------------------------------
	# TESTE 1: BURGER CLÁSSICO (Removidos Alface e Cebola)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Burger Clássico (Sem alface, sem cebola) ---")
	var classic = RecipeDatabase.get_recipe_by_id("burger_classic")
	var classic_counts = classic.get_ingredient_counts()

	total_tests += 1
	var classic_ok = (
		not classic_counts.has("lettuce") and
		not classic_counts.has("onion") and
		classic_counts.get("patty_beef:cooked", 0) == 1 and
		classic_counts.get("cheese_cheddar", 0) == 1 and
		classic_counts.get("tomato", 0) == 1 and
		classic_counts.get("ketchup", 0) == 1 and
		classic_counts.get("mustard", 0) == 1
	)
	if classic_ok:
		print("  [PASS] Burger Clássico atualizado: alface e cebola removidos, demais ingredientes preservados!")
		passed_tests += 1
	else:
		print("  [FAIL] Inconsistência no Burger Clássico: %s" % str(classic_counts))

	# -----------------------------------------------------------------------
	# TESTE 2: BURGER DUPLO (1x cheddar, sem picles, sem alface, +1 tomate)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Burger Duplo (2 carnes, 1 cheddar, 1 tomate, sem picles/alface) ---")
	var double_r = RecipeDatabase.get_recipe_by_id("burger_double")
	var double_counts = double_r.get_ingredient_counts()

	total_tests += 1
	var double_ok = (
		double_counts.get("patty_beef:cooked", 0) == 2 and
		double_counts.get("cheese_cheddar", 0) == 1 and
		double_counts.get("tomato", 0) == 1 and
		not double_counts.has("pickle") and
		not double_counts.has("lettuce")
	)
	if double_ok:
		print("  [PASS] Burger Duplo atualizado: 2 carnes, 1 queijo, 1 tomate (sem picles e sem alface)!")
		passed_tests += 1
	else:
		print("  [FAIL] Inconsistência no Burger Duplo: %s" % str(double_counts))

	# -----------------------------------------------------------------------
	# TESTE 3: BURGER SUPREME (+3 picles adicionados)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Burger Supreme (+3 picles) ---")
	var supreme_r = RecipeDatabase.get_recipe_by_id("burger_supreme")
	var supreme_counts = supreme_r.get_ingredient_counts()

	total_tests += 1
	var supreme_ok = (
		supreme_counts.get("patty_beef:cooked", 0) == 2 and
		supreme_counts.get("cheese_cheddar", 0) == 2 and
		supreme_counts.get("bacon", 0) == 1 and
		supreme_counts.get("onion", 0) == 1 and
		supreme_counts.get("lettuce", 0) == 1 and
		supreme_counts.get("special_sauce", 0) == 1 and
		supreme_counts.get("pickle", 0) == 3
	)
	if supreme_ok:
		print("  [PASS] Burger Supreme atualizado: contém exatamente 3x picles além de todos os demais ingredientes!")
		passed_tests += 1
	else:
		print("  [FAIL] Inconsistência no Burger Supreme: %s" % str(supreme_counts))

	# -----------------------------------------------------------------------
	# TESTE 4: BURGER SALADA (+2 picles adicionais -> 3 picles no total)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Burger Salada (3 picles no total) ---")
	var salad_r = RecipeDatabase.get_recipe_by_id("burger_salad")
	var salad_counts = salad_r.get_ingredient_counts()

	total_tests += 1
	var salad_ok = (
		salad_counts.get("patty_beef:cooked", 0) == 1 and
		salad_counts.get("cheese_prato", 0) == 1 and
		salad_counts.get("lettuce", 0) == 1 and
		salad_counts.get("tomato", 0) == 1 and
		salad_counts.get("onion", 0) == 1 and
		salad_counts.get("pickle", 0) == 3
	)
	if salad_ok:
		print("  [PASS] Burger Salada atualizado: contém 3x picles no total!")
		passed_tests += 1
	else:
		print("  [FAIL] Inconsistência no Burger Salada: %s" % str(salad_counts))

	# -----------------------------------------------------------------------
	# TESTE 5: BURGER ONION (+ Cebola roxa)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Burger Onion (+ Cebola roxa) ---")
	var onion_r = RecipeDatabase.get_recipe_by_id("burger_onion")
	var onion_counts = onion_r.get_ingredient_counts()

	total_tests += 1
	var onion_ok = (
		onion_counts.get("patty_beef:cooked", 0) == 1 and
		onion_counts.get("cheese_cheddar", 0) == 1 and
		onion_counts.get("onion", 0) == 1 and
		onion_counts.get("red_onion", 0) == 1 and
		onion_counts.get("mayo", 0) == 1
	)
	if onion_ok:
		print("  [PASS] Burger Onion atualizado: contém cebola comum + cebola roxa!")
		passed_tests += 1
	else:
		print("  [FAIL] Inconsistência no Burger Onion: %s" % str(onion_counts))

	# -----------------------------------------------------------------------
	# TESTE 6: SUCOS DE POLPA NATURAL (Laranja, Uva, Morango)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 6: Sucos de Polpa Natural ---")
	var orange_j = RecipeDatabase.get_recipe_by_id("juice_orange")
	var grape_j = RecipeDatabase.get_recipe_by_id("juice_grape")
	var straw_j = RecipeDatabase.get_recipe_by_id("juice_strawberry")

	total_tests += 1
	var juices_ok = (
		orange_j != null and orange_j.required_ingredients.has("pulp_orange") and
		grape_j != null and grape_j.required_ingredients.has("pulp_grape") and
		straw_j != null and straw_j.required_ingredients.has("pulp_strawberry")
	)
	if juices_ok:
		print("  [PASS] Sucos de polpa cadastrados com suas respectivas polpas (Laranja, Uva, Morango)!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha no cadastro de sucos de polpa!")

	# Custo do suco calculado por rendimento (1 polpa = 5 sucos -> pulp_cost / 5 + cup_cost)
	var pulp_cost = MenuPricingManager.get_ingredient_unit_cost("pulp_orange")
	var cup_cost = MenuPricingManager.get_ingredient_unit_cost("cup_empty")
	var expected_juice_cost = (pulp_cost / 5.0) + cup_cost
	var actual_juice_cost = MenuPricingManager.calculate_production_cost("juice_orange")

	total_tests += 1
	if absf(actual_juice_cost - expected_juice_cost) < 0.01:
		print("  [PASS] Custo de produção do suco por rendimento de polpa: R$ %.2f (Polpa R$ %.2f / 5 + Copo R$ %.2f)!" % [actual_juice_cost, pulp_cost, cup_cost])
		passed_tests += 1
	else:
		print("  [FAIL] Custo do suco incorreto: R$ %.2f (esperado %.2f)" % [actual_juice_cost, expected_juice_cost])

	# -----------------------------------------------------------------------
	# TESTE 7: RECÁLCULO DINÂMICO DE CUSTOS E MARGENS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 7: Recálculo Dinâmico de Custo de Produção ---")
	var cost_classic = MenuPricingManager.calculate_production_cost("burger_classic")
	var cost_double = MenuPricingManager.calculate_production_cost("burger_double")
	var cost_supreme = MenuPricingManager.calculate_production_cost("burger_supreme")
	var cost_salad = MenuPricingManager.calculate_production_cost("burger_salad")
	var cost_onion = MenuPricingManager.calculate_production_cost("burger_onion")

	total_tests += 1
	if cost_classic > 0 and cost_double > 0 and cost_supreme > cost_double and cost_salad > 0 and cost_onion > 0:
		print("  [PASS] Custos recalculados com precisão:")
		print("    - Clássico: R$ %.2f" % cost_classic)
		print("    - Duplo: R$ %.2f" % cost_double)
		print("    - Salada: R$ %.2f" % cost_salad)
		print("    - Onion: R$ %.2f" % cost_onion)
		print("    - Supreme: R$ %.2f" % cost_supreme)
		passed_tests += 1
	else:
		print("  [FAIL] Erro nos cálculos de custo dos novos lanches!")

	# -----------------------------------------------------------------------
	# TESTE 8: MONTAGEM LIVRE COM AS NOVAS RECEITAS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 8: Montagem Livre (Ordem Flexível) com as Novas Receitas ---")
	# Montagem do Burger Duplo na ordem 1: Pão, Carne, Carne, Queijo, Tomate
	var d_order_1 = ["bread", "patty_beef:cooked", "patty_beef:cooked", "cheese_cheddar", "tomato"]
	# Montagem do Burger Duplo na ordem 2: Pão, Tomate, Queijo, Carne, Carne
	var d_order_2 = ["bread", "tomato", "cheese_cheddar", "patty_beef:cooked", "patty_beef:cooked"]

	var match_d1 = double_r.matches(d_order_1)
	var match_d2 = double_r.matches(d_order_2)

	total_tests += 1
	if match_d1 and match_d2:
		print("  [PASS] Montagem livre validada para o novo Burger Duplo em múltiplas ordens!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha no matching de montagem livre do novo Burger Duplo!")

	# -----------------------------------------------------------------------
	# TESTE 9: EXIBIÇÃO NO LIVRO DE RECEITAS DO PC
	# -----------------------------------------------------------------------
	print("\n--- TESTE 9: Exibição no Livro de Receitas do PC ---")
	comp_ui.open()
	comp_ui._switch_tab(ComputerUI.TabID.RECIPES, "Livro de Receitas")
	comp_ui._set_recipe_category_filter("ALL")

	var grid = comp_ui.recipes_grid_container if comp_ui.recipes_grid_container else comp_ui._get_tab_node("RecipesTab").get_node("RecipesScroll/Margin/RecipesGrid")
	var total_cards = grid.get_child_count()

	# 11 burgers + 2 acompanhamentos + 4 refrigerantes + 3 sucos = 20 receitas
	total_tests += 1
	if total_cards == 20:
		print("  [PASS] Aba Receitas carregou todas as 20 receitas do restaurante (11 burgers, 2 porções, 4 refris, 3 sucos)!")
		passed_tests += 1
	else:
		print("  [FAIL] Aba Receitas carregou %d receitas (esperado 20)!" % total_cards)

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
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
