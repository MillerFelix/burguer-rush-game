class_name RecipeDatabase
extends RefCounted

static var _recipes: Array[Recipe] = []

static func get_all_recipes() -> Array[Recipe]:
	if _recipes.is_empty():
		_initialize_recipes()
	return _recipes

static func _initialize_recipes() -> void:
	_recipes.clear()

	var burger_scene = load("res://src/items/burger.tscn")
	var cheeseburger_scene = load("res://src/items/cheeseburger.tscn")
	var x_salada_scene = load("res://src/items/x_salada.tscn")
	var x_bacon_scene = load("res://src/items/x_bacon.tscn")
	var fries_scene = load("res://src/items/fries_pack.tscn")
	var soda_scene = load("res://src/items/drink_cup.tscn")

	# =========================================================================
	# NOVO CARDÁPIO DE BURGERS (11 RECEITAS REFORMULADAS)
	# =========================================================================

	# 1. Burger Clássico: Pão + Carne bovina + Queijo + Tomate + Ketchup + Mostarda
	var burger_classic = Recipe.new()
	burger_classic.id = "burger_classic"
	burger_classic.display_name = "Burger Clássico"
	burger_classic.category = "burger"
	burger_classic.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_cheddar", "tomato", "ketchup", "mustard"
	])
	burger_classic.result_scene = burger_scene
	burger_classic.base_price = 22.90
	burger_classic.is_unlocked = true
	_recipes.append(burger_classic)

	# 2. Burger Duplo: Pão + 2x Carne bovina + 1x Queijo + Tomate
	var burger_double = Recipe.new()
	burger_double.id = "burger_double"
	burger_double.display_name = "Burger Duplo"
	burger_double.category = "burger"
	burger_double.required_ingredients.assign([
		"bread", "patty_beef:cooked", "patty_beef:cooked", "cheese_cheddar", "tomato"
	])
	burger_double.result_scene = burger_scene
	burger_double.base_price = 32.90
	burger_double.is_unlocked = true
	_recipes.append(burger_double)

	# 3. Burger Cheddar: Pão + Carne bovina + Cheddar + Bacon + Cebola roxa
	var burger_cheddar = Recipe.new()
	burger_cheddar.id = "burger_cheddar"
	burger_cheddar.display_name = "Burger Cheddar"
	burger_cheddar.category = "burger"
	burger_cheddar.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_cheddar", "bacon", "red_onion"
	])
	burger_cheddar.result_scene = cheeseburger_scene
	burger_cheddar.base_price = 28.90
	burger_cheddar.is_unlocked = true
	_recipes.append(burger_cheddar)

	# 4. Burger Bacon: Pão + Carne bovina + Queijo + Bacon + Maionese
	var burger_bacon = Recipe.new()
	burger_bacon.id = "burger_bacon"
	burger_bacon.display_name = "Burger Bacon"
	burger_bacon.category = "burger"
	burger_bacon.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_prato", "bacon", "mayo"
	])
	burger_bacon.result_scene = x_bacon_scene
	burger_bacon.base_price = 27.90
	burger_bacon.is_unlocked = true
	_recipes.append(burger_bacon)

	# 5. Burger Salada: Pão + Carne bovina + Queijo + Alface + Tomate + Cebola normal + 3x Picles
	var burger_salad = Recipe.new()
	burger_salad.id = "burger_salad"
	burger_salad.display_name = "Burger Salada"
	burger_salad.category = "burger"
	burger_salad.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_prato", "lettuce", "tomato", "onion", "pickle", "pickle", "pickle"
	])
	burger_salad.result_scene = x_salada_scene
	burger_salad.base_price = 24.90
	burger_salad.is_unlocked = true
	_recipes.append(burger_salad)

	# 6. Burger Onion: Pão + Carne bovina + Queijo + Cebola comum + Cebola roxa + Maionese
	var burger_onion = Recipe.new()
	burger_onion.id = "burger_onion"
	burger_onion.display_name = "Burger Onion"
	burger_onion.category = "burger"
	burger_onion.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_cheddar", "onion", "red_onion", "mayo"
	])
	burger_onion.result_scene = burger_scene
	burger_onion.base_price = 26.90
	burger_onion.is_unlocked = true
	_recipes.append(burger_onion)

	# 7. Burger Chicken: Pão + Hambúrguer de frango + Queijo + Alface + Tomate + Maionese
	var burger_chicken = Recipe.new()
	burger_chicken.id = "burger_chicken"
	burger_chicken.display_name = "Burger Chicken"
	burger_chicken.category = "burger"
	burger_chicken.required_ingredients.assign([
		"bread", "patty_chicken:cooked", "cheese_mozzarella", "lettuce", "tomato", "mayo"
	])
	burger_chicken.result_scene = burger_scene
	burger_chicken.base_price = 23.90
	burger_chicken.is_unlocked = true
	_recipes.append(burger_chicken)

	# 8. Burger Supreme: Pão + 2x Carne bovina + 2x Queijo + Bacon + Cebola normal + Alface + Molho especial + 3x Picles
	var burger_supreme = Recipe.new()
	burger_supreme.id = "burger_supreme"
	burger_supreme.display_name = "Burger Supreme"
	burger_supreme.category = "burger"
	burger_supreme.required_ingredients.assign([
		"bread", "patty_beef:cooked", "patty_beef:cooked", "cheese_cheddar", "cheese_cheddar", "bacon", "onion", "lettuce", "special_sauce", "pickle", "pickle", "pickle"
	])
	burger_supreme.result_scene = burger_scene
	burger_supreme.base_price = 36.90
	burger_supreme.is_unlocked = true
	_recipes.append(burger_supreme)

	# 9. Burger Cheese (Três Queijos): Pão + Carne bovina + Muçarela + Cheddar + Queijo Prato + Maionese
	var burger_cheese = Recipe.new()
	burger_cheese.id = "burger_cheese"
	burger_cheese.display_name = "Burger Três Queijos"
	burger_cheese.category = "burger"
	burger_cheese.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_mozzarella", "cheese_cheddar", "cheese_prato", "mayo"
	])
	burger_cheese.result_scene = cheeseburger_scene
	burger_cheese.base_price = 29.90
	burger_cheese.is_unlocked = true
	_recipes.append(burger_cheese)

	# 10. Burger Vegano: Pão + Queijo + Alface + Tomate + Cebola normal + Picles + Maionese
	var burger_vegan = Recipe.new()
	burger_vegan.id = "burger_vegan"
	burger_vegan.display_name = "Burger Vegano"
	burger_vegan.category = "burger"
	burger_vegan.required_ingredients.assign([
		"bread", "cheese_mozzarella", "lettuce", "tomato", "onion", "pickle", "mayo"
	])
	burger_vegan.result_scene = x_salada_scene
	burger_vegan.base_price = 22.90
	burger_vegan.is_unlocked = true
	_recipes.append(burger_vegan)

	# 11. Burger Egg: Pão + Queijo + Alface + Tomate + Carne bovina + Ovo
	var burger_egg = Recipe.new()
	burger_egg.id = "burger_egg"
	burger_egg.display_name = "Burger Egg"
	burger_egg.category = "burger"
	burger_egg.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_prato", "lettuce", "tomato", "egg"
	])
	burger_egg.result_scene = burger_scene
	burger_egg.base_price = 25.90
	burger_egg.is_unlocked = true
	_recipes.append(burger_egg)

	# (Receitas legadas removidas — apenas novos burgers do cardápio reformulado)

	# =========================================================================
	# ACOMPANHAMENTOS E BEBIDAS
	# =========================================================================
	var fries_recipe = Recipe.new()
	fries_recipe.id = "fries"
	fries_recipe.display_name = "Batata Frita"
	fries_recipe.category = "fries"
	fries_recipe.required_ingredients.assign(["potato_raw", "potato_box"])
	fries_recipe.result_scene = fries_scene
	fries_recipe.base_price = 8.0
	fries_recipe.is_unlocked = true
	_recipes.append(fries_recipe)

	var onion_rings_recipe = Recipe.new()
	onion_rings_recipe.id = "onion_rings"
	onion_rings_recipe.display_name = "Cebola Frita"
	onion_rings_recipe.category = "fries"
	onion_rings_recipe.required_ingredients.assign(["onion_rings_raw", "potato_box"])
	onion_rings_recipe.result_scene = fries_scene
	onion_rings_recipe.base_price = 9.0
	onion_rings_recipe.is_unlocked = true
	_recipes.append(onion_rings_recipe)

	# --- BEBIDAS (REFRIGERANTES DE CILINDRO) ---
	var cola_recipe = Recipe.new()
	cola_recipe.id = "soda_cola"
	cola_recipe.display_name = "Refrigerante Cola"
	cola_recipe.category = "drink"
	cola_recipe.required_ingredients.assign(["cup_empty", "syrup_cola"])
	cola_recipe.result_scene = soda_scene
	cola_recipe.base_price = 6.0
	cola_recipe.is_unlocked = true
	_recipes.append(cola_recipe)

	var zero_soda_recipe = Recipe.new()
	zero_soda_recipe.id = "soda_cola_zero"
	zero_soda_recipe.display_name = "Refrigerante Zero"
	zero_soda_recipe.category = "drink"
	zero_soda_recipe.required_ingredients.assign(["cup_empty", "syrup_cola_zero"])
	zero_soda_recipe.result_scene = soda_scene
	zero_soda_recipe.base_price = 6.0
	zero_soda_recipe.is_unlocked = true
	_recipes.append(zero_soda_recipe)

	var soda_lime_recipe = Recipe.new()
	soda_lime_recipe.id = "soda_lime"
	soda_lime_recipe.display_name = "Refrigerante Soda"
	soda_lime_recipe.category = "drink"
	soda_lime_recipe.required_ingredients.assign(["cup_empty", "syrup_lemon"])
	soda_lime_recipe.result_scene = soda_scene
	soda_lime_recipe.base_price = 6.0
	soda_lime_recipe.is_unlocked = true
	_recipes.append(soda_lime_recipe)

	var citrus_recipe = Recipe.new()
	citrus_recipe.id = "soda_citrus"
	citrus_recipe.display_name = "Refrigerante Citrus"
	citrus_recipe.category = "drink"
	citrus_recipe.required_ingredients.assign(["cup_empty", "syrup_orange"])
	citrus_recipe.result_scene = soda_scene
	citrus_recipe.base_price = 6.0
	citrus_recipe.is_unlocked = true
	_recipes.append(citrus_recipe)

	# --- BEBIDAS (SUCOS DE POLPA NATURAL) ---
	var orange_juice_recipe = Recipe.new()
	orange_juice_recipe.id = "juice_orange"
	orange_juice_recipe.display_name = "Suco de Laranja"
	orange_juice_recipe.category = "drink"
	orange_juice_recipe.required_ingredients.assign(["cup_empty", "pulp_orange"])
	orange_juice_recipe.result_scene = soda_scene
	orange_juice_recipe.base_price = 7.0
	orange_juice_recipe.is_unlocked = true
	_recipes.append(orange_juice_recipe)

	var grape_juice_recipe = Recipe.new()
	grape_juice_recipe.id = "juice_grape"
	grape_juice_recipe.display_name = "Suco de Uva"
	grape_juice_recipe.category = "drink"
	grape_juice_recipe.required_ingredients.assign(["cup_empty", "pulp_grape"])
	grape_juice_recipe.result_scene = soda_scene
	grape_juice_recipe.base_price = 7.0
	grape_juice_recipe.is_unlocked = true
	_recipes.append(grape_juice_recipe)

	var strawberry_juice_recipe = Recipe.new()
	strawberry_juice_recipe.id = "juice_strawberry"
	strawberry_juice_recipe.display_name = "Suco de Morango"
	strawberry_juice_recipe.category = "drink"
	strawberry_juice_recipe.required_ingredients.assign(["cup_empty", "pulp_strawberry"])
	strawberry_juice_recipe.result_scene = soda_scene
	strawberry_juice_recipe.base_price = 7.0
	strawberry_juice_recipe.is_unlocked = true
	_recipes.append(strawberry_juice_recipe)

static func find_matching_recipe(ingredient_keys: Array) -> Recipe:
	# 1. Procura correspondência exata
	for recipe in get_all_recipes():
		if recipe.category == "burger" and recipe.matches(ingredient_keys):
			return recipe

	# 2. Se não encontrar exata, calcula a receita de hambúrguer com maior afinidade de ingredientes
	var best_recipe: Recipe = null
	var best_score: float = -1.0

	var given_counts: Dictionary = {}
	for k in ingredient_keys:
		var norm = _normalize_recipe_key(str(k))
		given_counts[norm] = given_counts.get(norm, 0) + 1

	for recipe in get_all_recipes():
		if recipe.category != "burger":
			continue
		var req_counts = recipe.get_ingredient_counts()
		var matched_count = 0
		var total_req = 0
		for rk in req_counts.keys():
			var req_qty = req_counts[rk]
			total_req += req_qty
			var given_qty = given_counts.get(rk, 0)
			matched_count += min(req_qty, given_qty)

		var extra_count = 0
		for gk in given_counts.keys():
			if not req_counts.has(gk):
				extra_count += given_counts[gk]

		var score = float(matched_count) - float(extra_count) * 0.5
		if score > best_score and score >= 2.0:
			best_score = score
			best_recipe = recipe

	return best_recipe

static func _normalize_recipe_key(k: String) -> String:
	var s = k.strip_edges()
	if s == "bread" or s == "bread_bottom" or s == "bread_top":
		return "bread"
	elif s == "patty" or s == "patty:cooked" or s == "patty_beef" or s == "patty_beef:cooked":
		return "patty_beef:cooked"
	elif s == "patty:raw" or s == "patty_beef:raw":
		return "patty_beef:raw"
	elif s == "patty_chicken" or s == "patty_chicken:cooked":
		return "patty_chicken:cooked"
	elif s == "patty_chicken:raw":
		return "patty_chicken:raw"
	elif s == "cheese" or s == "cheddar" or s == "cheese_cheddar":
		return "cheese_cheddar"
	elif s == "prato" or s == "cheese_prato":
		return "cheese_prato"
	elif s == "mozzarella" or s == "cheese_mozzarella":
		return "cheese_mozzarella"
	elif s == "bacon:cooked" or s == "bacon":
		return "bacon"
	elif s == "egg:cooked" or s == "egg":
		return "egg"
	elif s == "sauce_mayo" or s == "mayo":
		return "mayo"
	elif s == "sauce_ketchup" or s == "ketchup":
		return "ketchup"
	elif s == "sauce_mustard" or s == "mustard":
		return "mustard"
	elif s == "sauce_special" or s == "special_sauce":
		return "special_sauce"
	elif s == "white_onion" or s == "onion":
		return "onion"
	elif s == "red_onion" or s == "onion_red":
		return "red_onion"
	return s

static func get_recipe_by_id(recipe_id: String) -> Recipe:
	for recipe in get_all_recipes():
		if recipe.id == recipe_id:
			return recipe
	return null

static func update_recipe_price(recipe_id: String, new_price: float) -> bool:
	var recipe = get_recipe_by_id(recipe_id)
	if recipe:
		recipe.base_price = new_price
		return true
	return false

static func get_unlocked_menu_recipes() -> Array[Recipe]:
	var menu: Array[Recipe] = []
	var prog = ProgressionManager.get_instance()
	for r in get_all_recipes():
		if r.id.ends_with("_upgrade"):
			continue
		if prog:
			if prog.is_unlocked(r.id):
				menu.append(r)
		elif r.is_unlocked:
			menu.append(r)
	return menu

static func register_recipe(recipe: Recipe) -> void:
	if not _recipes.has(recipe):
		_recipes.append(recipe)
