extends SceneTree

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const InventoryManager = preload("res://src/inventory/inventory_manager.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const RecipeDatabase = preload("res://src/recipes/recipe_database.gd")

# ===========================================================================
# TESTE: ABA CARDÁPIO DO PC, PRECIFICAÇÃO DINÂMICA E INTEGRAÇÃO DE PEDIDOS
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: ABA CARDÁPIO DO PC, PRECIFICAÇÃO DINÂMICA E INTEGRAÇÃO DE PEDIDOS")
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
	# 2. TESTE DE ABERTURA E VISUALIZAÇÃO DOS PRODUTOS EXISTENTES
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Abertura da Aba Cardápio no PC ---")
	comp_ui.open()
	comp_ui._switch_tab(ComputerUI.TabID.MENU, "Cardápio & Preços")

	var menu_tab_node = comp_ui.menu_tab if comp_ui.menu_tab else comp_ui._get_tab_node("MenuTab")
	total_tests += 1
	if menu_tab_node and menu_tab_node.visible:
		print("  [PASS] Aba Cardápio aberta com sucesso no PC!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao abrir aba Cardápio no PC!")

	var all_recipes = RecipeDatabase.get_all_recipes()
	total_tests += 1
	if all_recipes.size() >= 15:
		print("  [PASS] %d produtos carregados do cardápio existente (Burgers, Acompanhamentos, Bebidas, Combos)!" % all_recipes.size())
		passed_tests += 1
	else:
		print("  [FAIL] Quantidade insuficiente de produtos no cardápio: %d" % all_recipes.size())

	# -----------------------------------------------------------------------
	# 3. TESTE DE CUSTO DINÂMICO, MARGEM E LIMITES ECONÔMICOS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Custo Dinâmico, Margem e Limites (Min / Max) ---")
	var classic_cost = MenuPricingManager.calculate_production_cost("burger_classic")
	var classic_market = MenuPricingManager.get_market_reference_price("burger_classic")
	var classic_rec = MenuPricingManager.get_recommended_price("burger_classic")
	var classic_min = MenuPricingManager.get_min_price("burger_classic")
	var classic_max = MenuPricingManager.get_max_price("burger_classic")

	total_tests += 1
	if classic_cost > 0.0 and classic_min > classic_cost and classic_max > classic_rec:
		print("  [PASS] Burger Clássico -> Custo: $%.2f | Mín: $%.2f | Sugerido: $%.2f | Máx: $%.2f" % [classic_cost, classic_min, classic_rec, classic_max])
		passed_tests += 1
	else:
		print("  [FAIL] Falha no cálculo de limites do Burger Clássico!")

	# Margem com preço sugerido
	var classic_margin = MenuPricingManager.get_gross_margin_pct("burger_classic")
	total_tests += 1
	if classic_margin >= 20.0:
		print("  [PASS] Margem bruta do Burger Clássico: %.1f%% (Saudável)" % classic_margin)
		passed_tests += 1
	else:
		print("  [FAIL] Margem do Burger Clássico abaixo do esperado: %.1f%%" % classic_margin)

	# -----------------------------------------------------------------------
	# 4. TESTE DE ALTERAÇÃO E VALIDAÇÃO DE LIMITES (BLOQUEIO MÍN/MÁX)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Alteração de Preço e Bloqueio de Valores Inválidos ---")

	# Tenta valor abaixo do mínimo (ex: R$ 3.00)
	var blocked_low = MenuPricingManager.set_selling_price("burger_classic", 3.00)
	total_tests += 1
	if not blocked_low:
		print("  [PASS] Bloqueio correto de preço abaixo do mínimo ($3.00 < $%.2f)!" % classic_min)
		passed_tests += 1
	else:
		print("  [FAIL] Preço abaixo do mínimo foi aceito indevidamente!")

	# Tenta valor acima do máximo (ex: R$ 150.00)
	var blocked_high = MenuPricingManager.set_selling_price("burger_classic", 150.00)
	total_tests += 1
	if not blocked_high:
		print("  [PASS] Bloqueio correto de preço acima do teto ($150.00 > $%.2f)!" % classic_max)
		passed_tests += 1
	else:
		print("  [FAIL] Preço acima do teto foi aceito indevidamente!")

	# Altera para um valor válido (R$ 25.00)
	var allowed_price = MenuPricingManager.set_selling_price("burger_classic", 25.00)
	total_tests += 1
	if allowed_price and is_equal_approx(MenuPricingManager.get_selling_price("burger_classic"), 25.00):
		print("  [PASS] Novo preço de venda do Burger Clássico definido para R$ 25.00 com sucesso!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao definir novo preço válido de R$ 25.00!")

	# -----------------------------------------------------------------------
	# 5. TESTE DE INTEGRAÇÃO COM PEDIDOS DOS CLIENTES
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Integração com Novos Pedidos dos Clientes ---")

	# Cria pedido de Burger Clássico e verifica preço cobrado
	var order_c = om.create_order(null, "burger_classic", 1)
	total_tests += 1
	if order_c and is_equal_approx(order_c.total_price, 25.00):
		print("  [PASS] Novo pedido de Burger Clássico cobrou exatamente o novo preço definido: R$ 25.00!")
		passed_tests += 1
	else:
		print("  [FAIL] Pedido não utilizou o novo preço (Cobrou: $%.2f)" % (order_c.total_price if order_c else 0.0))

	# Altera preço de bebida (soda_cola para R$ 7.50) e cria pedido
	MenuPricingManager.set_selling_price("soda_cola", 7.50)
	var order_drink = om.create_order(null, "soda_cola", 1)
	total_tests += 1
	if order_drink and is_equal_approx(order_drink.total_price, 7.50):
		print("  [PASS] Novo pedido de Refrigerante Cola cobrou exatamente o novo preço: R$ 7.50!")
		passed_tests += 1
	else:
		print("  [FAIL] Pedido de bebida não utilizou o novo preço (Cobrou: $%.2f)" % (order_drink.total_price if order_drink else 0.0))

	# -----------------------------------------------------------------------
	# 6. TESTE DE CUSTO DINÂMICO E VARIAÇÃO DE MERCADO
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Custo Dinâmico Atualizado por Variação de Mercado ---")

	var initial_burger_cost = MenuPricingManager.calculate_production_cost("burger_classic")
	var prev_patty_price = MenuPricingManager.get_ingredient_unit_cost("patty_beef")
	var target_patty_price = prev_patty_price + 2.00

	# Aumenta preço da carne bovina no catálogo de compras
	if pm.catalog.has("patty_beef"):
		pm.catalog["patty_beef"]["market_price"] = target_patty_price

	var updated_burger_cost = MenuPricingManager.calculate_production_cost("burger_classic")
	total_tests += 1
	if is_equal_approx(updated_burger_cost, initial_burger_cost + 2.00):
		print("  [PASS] Custo do Burger Clássico subiu automaticamente de $%.2f para $%.2f (+ $2.00 da carne)!" % [initial_burger_cost, updated_burger_cost])
		passed_tests += 1
	else:
		print("  [FAIL] Custo dinâmico não refletiu o aumento da carne ($%.2f -> $%.2f)" % [initial_burger_cost, updated_burger_cost])

	# Recalcula e confirma que a margem foi atualizada com o novo custo
	var updated_margin = MenuPricingManager.get_gross_margin_pct("burger_classic")
	var expected_margin = ((25.00 - updated_burger_cost) / 25.00) * 100.0
	total_tests += 1
	if is_equal_approx(updated_margin, expected_margin):
		print("  [PASS] Margem bruta recalculada em tempo real: %.1f%%!" % updated_margin)
		passed_tests += 1
	else:
		print("  [FAIL] Margem recalculada incorreta: %.1f%% (esperado %.1f%%)" % [updated_margin, expected_margin])

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
