class_name MenuPricingManager
extends RefCounted

const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const InventoryManager = preload("res://src/inventory/inventory_manager.gd")
const RecipeDatabase = preload("res://src/recipes/recipe_database.gd")

# =============================================================================
# BURGER RUSH - SISTEMA DE GESTÃO DE CARDÁPIO E PRECIFICAÇÃO DINÂMICA
#
# Integração completa entre:
# - Custo dinâmico dos ingredientes (atualizado em tempo real pelo mercado)
# - Rendimento dos insumos (1 saco = 5 batatas, 1 saco = 3 cebolas, 1 cilindro = 20 copos)
# - Preço recomendado, mínimo (margem >= 20%) e máximo (~150% do recomendado)
# - Preço de mercado da região
# - Centralização dos preços para pedidos e clientes
# =============================================================================

static var _custom_prices: Dictionary = {}

static func get_purchase_manager() -> PurchaseManager:
	var pm = PurchaseManager.get_instance()
	if not pm and Engine.has_singleton("PurchaseManager"):
		pm = Engine.get_singleton("PurchaseManager")
	if not pm:
		var ml = Engine.get_main_loop()
		if ml and ml is SceneTree:
			var tree = ml as SceneTree
			if tree.root:
				pm = tree.root.find_child("PurchaseManager", true, false)
	return pm

static func get_inventory_manager() -> InventoryManager:
	var inv = InventoryManager.get_instance()
	if not inv and Engine.has_singleton("InventoryManager"):
		inv = Engine.get_singleton("InventoryManager")
	if not inv:
		var ml = Engine.get_main_loop()
		if ml and ml is SceneTree:
			var tree = ml as SceneTree
			if tree.root:
				inv = tree.root.find_child("InventoryManager", true, false)
	return inv

static func get_ingredient_unit_cost(ingredient_id: String) -> float:
	var pm = get_purchase_manager()
	if pm and pm.catalog.has(ingredient_id):
		return pm.catalog[ingredient_id].get("market_price", pm.catalog[ingredient_id].get("base_price", 1.0))

	var inv = get_inventory_manager()
	if inv and inv.items.has(ingredient_id):
		return inv.items[ingredient_id].get("unit_cost", 1.0)

	# Fallbacks com valores de mercado coerentes
	match ingredient_id:
		"bread_bottom", "bread_top": return 1.00
		"bread": return 2.00
		"patty_beef", "patty_beef:cooked": return 5.00
		"patty_chicken", "patty_chicken:cooked": return 4.50
		"cheese_cheddar": return 2.20
		"cheese_mozzarella", "cheese_prato": return 2.00
		"lettuce", "tomato", "pickle", "egg": return 1.50
		"bacon": return 3.00
		"red_onion": return 1.20
		"onion": return 1.00
		"ketchup", "mustard", "mayo", "special_sauce": return 0.50
		"burger_box": return 0.50
		"potato_box": return 0.30
		"cup_empty": return 0.20
		"delivery_bag": return 0.40
		"potato_raw": return 20.00
		"onion_rings_raw": return 15.00
		"cylinder_cola", "cylinder_cola_zero", "cylinder_soda", "cylinder_citrus": return 80.00
		"pulp_orange", "pulp_grape", "pulp_strawberry": return 15.00
		_: return 1.00

## Calcula o custo dinâmico de produção de um produto/receita a partir dos insumos atuais
static func calculate_production_cost(recipe_id: String) -> float:
	var recipe = RecipeDatabase.get_recipe_by_id(recipe_id)
	if not recipe:
		return 5.0

	# 1. ACOMPANHAMENTOS (Rendimento dos sacos + Embalagem)
	if recipe_id == "fries" or recipe.category == "fries" and recipe_id.contains("fries"):
		var bag_cost = get_ingredient_unit_cost("potato_raw")
		var box_cost = get_ingredient_unit_cost("potato_box")
		return (bag_cost / 5.0) + box_cost # 1 saco rende 5 porções

	if recipe_id == "onion_rings" or recipe_id.contains("onion_rings"):
		var onion_bag_cost = get_ingredient_unit_cost("onion_rings_raw")
		var box_cost = get_ingredient_unit_cost("potato_box")
		return (onion_bag_cost / 3.0) + box_cost # 1 saco rende 3 porções

	# 2. BEBIDAS (Rendimento dos cilindros / polpas + Copo)
	if recipe_id.begins_with("juice_"):
		var pulp_id = "pulp_orange"
		if recipe_id == "juice_grape": pulp_id = "pulp_grape"
		elif recipe_id == "juice_strawberry": pulp_id = "pulp_strawberry"

		var pulp_cost = get_ingredient_unit_cost(pulp_id)
		var cup_cost = get_ingredient_unit_cost("cup_empty")
		return (pulp_cost / 5.0) + cup_cost # 1 polpa rende 5 copos

	if recipe.category == "drink" or recipe_id.begins_with("soda_"):
		var cyl_id = "cylinder_cola"
		if recipe_id == "soda_cola_zero": cyl_id = "cylinder_cola_zero"
		elif recipe_id == "soda_lime": cyl_id = "cylinder_soda"
		elif recipe_id == "soda_citrus": cyl_id = "cylinder_citrus"

		var cyl_cost = get_ingredient_unit_cost(cyl_id)
		var cup_cost = get_ingredient_unit_cost("cup_empty")
		return (cyl_cost / 20.0) + cup_cost # 1 cilindro rende 20 copos

	# 3. BURGERS (Soma de todos os ingredientes da receita + caixa)
	var total_burger_cost = 0.0
	for ing_key in recipe.required_ingredients:
		var clean_id = ing_key.split(":")[0]
		if clean_id == "bread":
			total_burger_cost += get_ingredient_unit_cost("bread_bottom") + get_ingredient_unit_cost("bread_top")
		else:
			total_burger_cost += get_ingredient_unit_cost(clean_id)

	# Embalagem de lanche
	total_burger_cost += get_ingredient_unit_cost("burger_box")
	return maxf(total_burger_cost, 1.0)

## Preço de mercado de referência praticado na região
static func get_market_reference_price(recipe_id: String) -> float:
	match recipe_id:
		"burger_classic": return 22.00
		"burger_double": return 32.00
		"burger_cheddar": return 28.00
		"burger_bacon": return 26.00
		"burger_salad": return 24.00
		"burger_onion": return 26.00
		"burger_chicken": return 24.00
		"burger_supreme": return 35.00
		"burger_cheese": return 29.00
		"burger_vegan": return 22.00
		"burger_egg": return 25.00
		"fries": return 12.00
		"onion_rings": return 11.00
		"soda_cola", "soda_cola_zero", "soda_lime", "soda_citrus": return 8.00
		"juice_orange", "juice_grape", "juice_strawberry": return 9.00
		_:
			var r = RecipeDatabase.get_recipe_by_id(recipe_id)
			return r.base_price if r else 15.00

## Preço recomendado pelo restaurante baseado no custo real + margem saudável
static func get_recommended_price(recipe_id: String) -> float:
	var cost = calculate_production_cost(recipe_id)
	match recipe_id:
		"fries": return 12.00
		"onion_rings": return 11.00
		"soda_cola", "soda_cola_zero", "soda_lime", "soda_citrus": return 8.00
		"juice_orange", "juice_grape", "juice_strawberry": return 9.00
		_:
			var market = get_market_reference_price(recipe_id)
			# Garante que o recomendado cubra pelo menos 45% de margem ou aproxime do mercado
			var cost_based = cost * 1.85
			return snappedf(clampf(cost_based, cost * 1.40, market * 1.15), 0.50)

## Preço mínimo aceitável (garante margem bruta mínima de aproximadamente 20%)
static func get_min_price(recipe_id: String) -> float:
	var cost = calculate_production_cost(recipe_id)
	# Margem bruta de 20% significa Preço >= Custo / 0.80 = Custo * 1.25
	return snappedf(cost * 1.20, 0.10)

## Preço máximo permitido (~150% do recomendado / mercado)
static func get_max_price(recipe_id: String) -> float:
	var rec = get_recommended_price(recipe_id)
	var market = get_market_reference_price(recipe_id)
	var base_ref = maxf(rec, market)
	return snappedf(base_ref * 1.50, 0.50)

## Retorna o preço de venda atual praticado pelo jogador
static func get_selling_price(recipe_id: String) -> float:
	if _custom_prices.has(recipe_id):
		return _custom_prices[recipe_id]
	var recipe = RecipeDatabase.get_recipe_by_id(recipe_id)
	if recipe:
		return recipe.base_price
	return get_recommended_price(recipe_id)

## Altera o preço de venda praticado com validação rígida de limites econômicos
static func set_selling_price(recipe_id: String, new_price: float) -> bool:
	var min_p = get_min_price(recipe_id)
	var max_p = get_max_price(recipe_id)

	if new_price < (min_p - 0.01) or new_price > (max_p + 0.01):
		return false

	var final_price = snappedf(clampf(new_price, min_p, max_p), 0.10)
	_custom_prices[recipe_id] = final_price

	# Sincroniza com RecipeDatabase para que os pedidos usem imediatamente o novo valor
	var recipe = RecipeDatabase.get_recipe_by_id(recipe_id)
	if recipe:
		recipe.base_price = final_price

	return true

## Calcula a margem bruta (%) com base no preço atual e custo dinâmico
static func get_gross_margin_pct(recipe_id: String) -> float:
	var price = get_selling_price(recipe_id)
	if price <= 0.0:
		return 0.0
	var cost = calculate_production_cost(recipe_id)
	var profit = price - cost
	return (profit / price) * 100.0

## Retorna o lucro bruto unitário ($)
static func get_gross_profit(recipe_id: String) -> float:
	var price = get_selling_price(recipe_id)
	var cost = calculate_production_cost(recipe_id)
	return price - cost
