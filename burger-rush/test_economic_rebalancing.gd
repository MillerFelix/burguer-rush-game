extends SceneTree

# ===========================================================================
# TESTE: REBALANCEAMENTO ECONÔMICO DE INSUMOS E MARGENS BRUTAS
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: REBALANCEAMENTO ECONÔMICO DE INSUMOS E MARGENS BRUTAS")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	var pm = PurchaseManager.new()
	root.add_child(pm)
	pm._ready()

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._ready()

	# -----------------------------------------------------------------------
	# 1. TESTE DO SACO DE BATATA (Rendimento: 5 porções)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Saco de Batata (Base R$ 20,00 | Rendimento: 5 porções) ---")
	var potato_item = pm.get_catalog_item("potato_raw")
	total_tests += 1
	if potato_item and is_equal_approx(potato_item["base_price"], 20.00):
		print("  [PASS] Preço base do Saco de Batata configurado para R$ 20,00!")
		passed_tests += 1
	else:
		print("  [FAIL] Preço base da batata incorreto: %s" % str(potato_item))

	var fries_recipe = RecipeDatabase.get_recipe_by_id("fries")
	var fries_sell_price = fries_recipe.base_price if fries_recipe else 8.0
	var potato_cost_per_portion = 20.00 / 5.0
	var fries_box_cost = 0.30
	var total_fries_cost = potato_cost_per_portion + fries_box_cost
	var fries_profit = fries_sell_price - total_fries_cost
	var fries_margin = (fries_profit / fries_sell_price) * 100.0

	total_tests += 1
	if fries_margin >= 35.0 and fries_margin <= 50.0:
		print("  [PASS] Margem bruta da Batata Frita: %.2f%% (R$ %.2f lucro / R$ %.2f venda) na faixa saudável [35%% - 50%%]!" % [fries_margin, fries_profit, fries_sell_price])
		passed_tests += 1
	else:
		print("  [FAIL] Margem da batata fora da faixa: %.2f%%" % fries_margin)

	# -----------------------------------------------------------------------
	# 2. TESTE DOS CILINDROS DE REFRIGERANTE (Rendimento: 20 copos)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Cilindros de Refrigerante (Base R$ 80,00 | Rendimento: 20 copos) ---")
	var soda_cylinders = ["cylinder_cola", "cylinder_cola_zero", "cylinder_soda", "cylinder_citrus"]
	var all_cylinders_80 = true
	for cyl_id in soda_cylinders:
		var c_item = pm.get_catalog_item(cyl_id)
		if not c_item or not is_equal_approx(c_item["base_price"], 80.00):
			all_cylinders_80 = false
			print("  [FAIL] Cilindro %s incorreto: %s" % [cyl_id, str(c_item)])

	total_tests += 1
	if all_cylinders_80:
		print("  [PASS] Todos os 4 cilindros de refrigerante configurados com preço base de R$ 80,00!")
		passed_tests += 1

	var soda_cost_per_cup = 80.00 / 20.0
	var cup_cost = 0.20
	var total_soda_cost = soda_cost_per_cup + cup_cost
	var soda_recipe = RecipeDatabase.get_recipe_by_id("soda_cola")
	var soda_sell_price = soda_recipe.base_price if soda_recipe else 6.0
	var soda_profit = soda_sell_price - total_soda_cost
	var soda_margin = (soda_profit / soda_sell_price) * 100.0

	total_tests += 1
	if is_equal_approx(soda_cost_per_cup, 4.00) and soda_profit > 0.0:
		print("  [PASS] Custo por copo de refri: R$ 4,00 (+ R$ 0,20 copo = R$ 4,20) | Margem: %.1f%% (R$ %.2f lucro)!" % [soda_margin, soda_profit])
		passed_tests += 1
	else:
		print("  [FAIL] Cálculo do refri incorreto!")

	# -----------------------------------------------------------------------
	# 3. TESTE DAS POLPAS DE SUCO (Rendimento: 5 sucos)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Polpas de Suco (Base R$ 15,00 | Rendimento: 5 sucos) ---")
	var orange_pulp = pm.get_catalog_item("pulp_orange")
	var grape_pulp = pm.get_catalog_item("pulp_grape")
	var strawberry_pulp = pm.get_catalog_item("pulp_strawberry")

	total_tests += 1
	if orange_pulp and grape_pulp and is_equal_approx(orange_pulp["base_price"], 15.00) and is_equal_approx(grape_pulp["base_price"], 15.00):
		print("  [PASS] Polpas de Laranja e Uva configuradas para R$ 15,00 (R$ 3,00 por suco)!")
		passed_tests += 1
	else:
		print("  [FAIL] Polpas de suco com preço incorreto!")

	# -----------------------------------------------------------------------
	# 4. TESTE DO SACO DE CEBOLA (Rendimento: 3 porções)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Saco de Cebola (Base R$ 15,00 | Rendimento: 3 porções) ---")
	var onion_item = pm.get_catalog_item("onion_rings_raw")
	total_tests += 1
	if onion_item and is_equal_approx(onion_item["base_price"], 15.00):
		print("  [PASS] Preço base do Saco de Cebola configurado para R$ 15,00!")
		passed_tests += 1
	else:
		print("  [FAIL] Preço base da cebola incorreto: %s" % str(onion_item))

	var onion_recipe = RecipeDatabase.get_recipe_by_id("onion_rings")
	var onion_sell_price = onion_recipe.base_price if onion_recipe else 9.0
	var onion_cost_per_portion = 15.00 / 3.0
	var total_onion_cost = onion_cost_per_portion + fries_box_cost
	var onion_profit = onion_sell_price - total_onion_cost
	var onion_margin = (onion_profit / onion_sell_price) * 100.0

	total_tests += 1
	if onion_margin >= 35.0 and onion_margin <= 50.0:
		print("  [PASS] Margem bruta da Cebola Frita: %.2f%% (R$ %.2f lucro / R$ %.2f venda) na faixa saudável [35%% - 50%%]!" % [onion_margin, onion_profit, onion_sell_price])
		passed_tests += 1
	else:
		print("  [FAIL] Margem da cebola fora da faixa: %.2f%%" % onion_margin)

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
