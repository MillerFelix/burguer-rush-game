extends SceneTree

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const InventoryManager = preload("res://src/inventory/inventory_manager.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const RecipeDatabase = preload("res://src/recipes/recipe_database.gd")

# ===========================================================================
# TESTE: ABA RECEITAS DO PC, MONTAGEM LIVRE, REMOÇÃO DE COMBOS E RESPONSIVIDADE
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: ABA RECEITAS DO PC, MONTAGEM LIVRE, REMOÇÃO DE COMBOS E RESPONSIVIDADE")
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
	# 2. TESTE 1: REMOÇÃO COMPLETA DE COMBOS
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Remoção de Combos do Sistema ---")
	var all_recipes = RecipeDatabase.get_all_recipes()
	var found_combo = false
	for r in all_recipes:
		if r.category == "combo" or r.id.begins_with("combo_"):
			found_combo = true
			break

	total_tests += 1
	if not found_combo:
		print("  [PASS] Nenhum combo encontrado no RecipeDatabase (Removidos com sucesso)!")
		passed_tests += 1
	else:
		print("  [FAIL] Combos ainda presentes no RecipeDatabase!")

	# Verifica se bebidas e acompanhamentos continuam individuais
	var fries_recipe = RecipeDatabase.get_recipe_by_id("fries")
	var onion_recipe = RecipeDatabase.get_recipe_by_id("onion_rings")
	var cola_recipe = RecipeDatabase.get_recipe_by_id("soda_cola")

	total_tests += 1
	if fries_recipe and onion_recipe and cola_recipe:
		print("  [PASS] Acompanhamentos (Batata, Cebola) e Bebidas (Cola) continuam ativos como produtos individuais!")
		passed_tests += 1
	else:
		print("  [FAIL] Produtos individuais de bebidas ou acompanhamentos foram perdidos!")

	# -----------------------------------------------------------------------
	# 3. TESTE 2: ABERTURA E NAVEGAÇÃO DA ABA RECEITAS NO PC
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Navegação e Consistência Visual entre Abas ---")
	comp_ui.open()

	# Alterna por todas as abas principais
	comp_ui._switch_tab(ComputerUI.TabID.INVENTORY, "Estoque Geral")
	var inv_tab = comp_ui._get_tab_node("InventoryTab")
	var inv_ok = inv_tab and inv_tab.visible

	comp_ui._switch_tab(ComputerUI.TabID.PURCHASES, "Central de Compras")
	var pur_tab = comp_ui._get_tab_node("PurchasesTab")
	var pur_ok = pur_tab and pur_tab.visible

	comp_ui._switch_tab(ComputerUI.TabID.MENU, "Cardápio & Preços")
	var menu_tab = comp_ui._get_tab_node("MenuTab")
	var menu_ok = menu_tab and menu_tab.visible

	comp_ui._switch_tab(ComputerUI.TabID.RECIPES, "Livro de Receitas")
	var recipes_tab = comp_ui._get_tab_node("RecipesTab")
	var rec_ok = recipes_tab and recipes_tab.visible

	total_tests += 1
	if inv_ok and pur_ok and menu_ok and rec_ok:
		print("  [PASS] Navegação fluida e transição de abas funcionando 100% (Estoque -> Compras -> Cardápio -> Receitas)!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na alternância entre as abas do PC!")

	# -----------------------------------------------------------------------
	# 4. TESTE 3: TODAS AS 11 RECEITAS DE HAMBÚRGUERES EXISTENTES
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Verificação das 11 Receitas Oficiais de Burgers ---")
	var expected_burgers = [
		"burger_classic",
		"burger_double",
		"burger_cheddar",
		"burger_bacon",
		"burger_salad",
		"burger_onion",
		"burger_chicken",
		"burger_supreme",
		"burger_cheese",
		"burger_vegan",
		"burger_egg"
	]

	var all_burgers_found = true
	for b_id in expected_burgers:
		var r = RecipeDatabase.get_recipe_by_id(b_id)
		if not r or r.display_name == "":
			all_burgers_found = false
			print("    -> Receita faltando: %s" % b_id)

	total_tests += 1
	if all_burgers_found:
		print("  [PASS] Todos os 11 hambúrgueres oficiais cadastrados e preservados!")
		passed_tests += 1
	else:
		print("  [FAIL] Inconsistência nos 11 hambúrgueres oficiais!")

	# -----------------------------------------------------------------------
	# 5. TESTE 4: QUANTIDADES E CUSTO DINÂMICO DA RECEITA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Quantidades de Ingredientes e Custo Dinâmico ---")
	var double_recipe = RecipeDatabase.get_recipe_by_id("burger_double")
	var double_counts = double_recipe.get_ingredient_counts()
	var double_cost = MenuPricingManager.calculate_production_cost("burger_double")

	total_tests += 1
	# Burger Duplo deve ter 2 carnes, 1 queijo e 1 tomate
	if double_counts.get("patty_beef:cooked", 0) == 2 and double_counts.get("cheese_cheddar", 0) == 1 and double_counts.get("tomato", 0) == 1:
		print("  [PASS] Burger Duplo contém exatamente 2x Carne, 1x Queijo Cheddar e 1x Tomate!")
		passed_tests += 1
	else:
		print("  [FAIL] Quantidades de ingredientes incorretas no Burger Duplo: %s" % str(double_counts))

	total_tests += 1
	if double_cost > 15.0:
		print("  [PASS] Custo dinâmico do Burger Duplo recalculado corretamente: R$ %.2f!" % double_cost)
		passed_tests += 1
	else:
		print("  [FAIL] Custo do Burger Duplo abaixo do esperado: R$ %.2f" % double_cost)

	# -----------------------------------------------------------------------
	# 6. TESTE 5: MONTAGEM LIVRE (ORDEM DOS INGREDIENTES É FLEXÍVEL)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Validação da Montagem Livre (Ordem Flexível) ---")
	var classic_recipe = RecipeDatabase.get_recipe_by_id("burger_classic")

	# Ordem 1: Pão, Carne, Queijo, Tomate, Ketchup, Mostarda
	var stack_order_1 = ["bread", "patty_beef:cooked", "cheese_cheddar", "tomato", "ketchup", "mustard"]
	# Ordem 2: Pão, Mostarda, Ketchup, Tomate, Queijo, Carne
	var stack_order_2 = ["bread", "mustard", "ketchup", "tomato", "cheese_cheddar", "patty_beef:cooked"]

	var match_1 = classic_recipe.matches(stack_order_1)
	var match_2 = classic_recipe.matches(stack_order_2)

	total_tests += 1
	if match_1 and match_2:
		print("  [PASS] Montagem Livre validada: O lanche é reconhecido com sucesso em ambas as ordens de montagem!")
		passed_tests += 1
	else:
		print("  [FAIL] Montagem livre falhou: match_1=%s, match_2=%s" % [match_1, match_2])

	# -----------------------------------------------------------------------
	# 7. TESTE 6: FILTRO E BUSCA EM TEMPO REAL NA ABA RECEITAS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 6: Filtros e Busca em Tempo Real na Aba Receitas ---")
	comp_ui._set_recipe_category_filter("BURGER")
	var grid = comp_ui.recipes_grid_container if comp_ui.recipes_grid_container else comp_ui._get_tab_node("RecipesTab").get_node("RecipesScroll/Margin/RecipesGrid")
	var burger_cards_count = grid.get_child_count()

	total_tests += 1
	if burger_cards_count == 11:
		print("  [PASS] Filtro 'Hambúrgueres' exibiu exatamente os 11 cards de lanches!")
		passed_tests += 1
	else:
		print("  [FAIL] Filtro 'Hambúrgueres' exibiu %d cards (esperado 11)!" % burger_cards_count)

	# Busca por "Cheddar"
	comp_ui._set_recipe_category_filter("ALL")
	comp_ui._on_recipe_search_text_changed("Cheddar")
	var search_cards_count = grid.get_child_count()

	total_tests += 1
	if search_cards_count == 1:
		print("  [PASS] Busca em tempo real por 'Cheddar' filtrou exatamente o card do Burger Cheddar!")
		passed_tests += 1
	else:
		print("  [FAIL] Busca por 'Cheddar' exibiu %d cards (esperado 1)!" % search_cards_count)

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
