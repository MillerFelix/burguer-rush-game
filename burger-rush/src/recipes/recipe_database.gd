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

	# 1. Burger Clássico: Pão + Carne bovina + Queijo + Alface + Tomate + Cebola normal + Ketchup + Mostarda
	var burger_classic = Recipe.new()
	burger_classic.id = "burger_classic"
	burger_classic.display_name = "Burger Clássico"
	burger_classic.category = "burger"
	burger_classic.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_cheddar", "lettuce", "tomato", "onion", "ketchup", "mustard"
	])
	burger_classic.result_scene = burger_scene
	burger_classic.base_price = 22.90
	burger_classic.is_unlocked = true
	_recipes.append(burger_classic)

	# 2. Burger Duplo: Pão + 2x Carne bovina + 2x Queijo + Alface + Picles
	var burger_double = Recipe.new()
	burger_double.id = "burger_double"
	burger_double.display_name = "Burger Duplo"
	burger_double.category = "burger"
	burger_double.required_ingredients.assign([
		"bread", "patty_beef:cooked", "patty_beef:cooked", "cheese_cheddar", "cheese_cheddar", "lettuce", "pickle"
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

	# 5. Burger Salada: Pão + Carne bovina + Queijo + Alface + Tomate + Cebola normal + Picles
	var burger_salad = Recipe.new()
	burger_salad.id = "burger_salad"
	burger_salad.display_name = "Burger Salada"
	burger_salad.category = "burger"
	burger_salad.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_prato", "lettuce", "tomato", "onion", "pickle"
	])
	burger_salad.result_scene = x_salada_scene
	burger_salad.base_price = 24.90
	burger_salad.is_unlocked = true
	_recipes.append(burger_salad)

	# 6. Burger Onion: Pão + Carne bovina + Queijo + Cebola grelhada + Maionese
	var burger_onion = Recipe.new()
	burger_onion.id = "burger_onion"
	burger_onion.display_name = "Burger Onion"
	burger_onion.category = "burger"
	burger_onion.required_ingredients.assign([
		"bread", "patty_beef:cooked", "cheese_cheddar", "onion", "mayo"
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

	# 8. Burger Supreme: Pão + 2x Carne bovina + 2x Queijo + Bacon + Cebola normal + Alface + Molho especial
	var burger_supreme = Recipe.new()
	burger_supreme.id = "burger_supreme"
	burger_supreme.display_name = "Burger Supreme"
	burger_supreme.category = "burger"
	burger_supreme.required_ingredients.assign([
		"bread", "patty_beef:cooked", "patty_beef:cooked", "cheese_cheddar", "cheese_cheddar", "bacon", "onion", "lettuce", "special_sauce"
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

	var cola_recipe = Recipe.new()
	cola_recipe.id = "soda_cola"
	cola_recipe.display_name = "Refrigerante Cola"
	cola_recipe.category = "drink"
	cola_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	cola_recipe.result_scene = soda_scene
	cola_recipe.base_price = 6.0
	cola_recipe.is_unlocked = true
	_recipes.append(cola_recipe)

	var guarana_recipe = Recipe.new()
	guarana_recipe.id = "soda_guarana"
	guarana_recipe.display_name = "Refrigerante Guaraná"
	guarana_recipe.category = "drink"
	guarana_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	guarana_recipe.result_scene = soda_scene
	guarana_recipe.base_price = 6.0
	guarana_recipe.is_unlocked = true
	_recipes.append(guarana_recipe)

	var sprite_recipe = Recipe.new()
	sprite_recipe.id = "soda_sprite"
	sprite_recipe.display_name = "Refrigerante Limão"
	sprite_recipe.category = "drink"
	sprite_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	sprite_recipe.result_scene = soda_scene
	sprite_recipe.base_price = 6.0
	sprite_recipe.is_unlocked = true
	_recipes.append(sprite_recipe)

	var grape_soda_recipe = Recipe.new()
	grape_soda_recipe.id = "soda_grape"
	grape_soda_recipe.display_name = "Refrigerante Uva"
	grape_soda_recipe.category = "drink"
	grape_soda_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	grape_soda_recipe.result_scene = soda_scene
	grape_soda_recipe.base_price = 6.0
	grape_soda_recipe.is_unlocked = true
	_recipes.append(grape_soda_recipe)

	var zero_soda_recipe = Recipe.new()
	zero_soda_recipe.id = "soda_cola_zero"
	zero_soda_recipe.display_name = "Refrigerante Cola Zero"
	zero_soda_recipe.category = "drink"
	zero_soda_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	zero_soda_recipe.result_scene = soda_scene
	zero_soda_recipe.base_price = 6.0
	zero_soda_recipe.is_unlocked = true
	_recipes.append(zero_soda_recipe)

	var soda_recipe = Recipe.new()
	soda_recipe.id = "soda"
	soda_recipe.display_name = "Refrigerante"
	soda_recipe.category = "drink"
	soda_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	soda_recipe.result_scene = soda_scene
	soda_recipe.base_price = 6.0
	soda_recipe.is_unlocked = true
	_recipes.append(soda_recipe)

	var juice_orange_recipe = Recipe.new()
	juice_orange_recipe.id = "juice_orange"
	juice_orange_recipe.display_name = "Suco de Laranja"
	juice_orange_recipe.category = "drink"
	juice_orange_recipe.required_ingredients.assign(["cup_empty", "cup_lid"])
	juice_orange_recipe.result_scene = soda_scene
	juice_orange_recipe.base_price = 7.0
	juice_orange_recipe.is_unlocked = true
	_recipes.append(juice_orange_recipe)

	var juice_grape_recipe = Recipe.new()
	juice_grape_recipe.id = "juice_grape"
	juice_grape_recipe.display_name = "Suco de Uva"
	juice_grape_recipe.category = "drink"
	juice_grape_recipe.required_ingredients.assign(["cup_empty", "cup_lid"])
	juice_grape_recipe.result_scene = soda_scene
	juice_grape_recipe.base_price = 7.0
	juice_grape_recipe.is_unlocked = true
	_recipes.append(juice_grape_recipe)

	var juice_passion_recipe = Recipe.new()
	juice_passion_recipe.id = "juice_passion"
	juice_passion_recipe.display_name = "Suco de Maracujá"
	juice_passion_recipe.category = "drink"
	juice_passion_recipe.required_ingredients.assign(["cup_empty", "cup_lid"])
	juice_passion_recipe.result_scene = soda_scene
	juice_passion_recipe.base_price = 7.0
	juice_passion_recipe.is_unlocked = true
	_recipes.append(juice_passion_recipe)

	# Combos
	var combo_classic = Recipe.new()
	combo_classic.id = "combo_classic"
	combo_classic.display_name = "Combo Clássico (Burger + Batata + Cola)"
	combo_classic.category = "combo"
	combo_classic.combo_items.assign(["burger_classic", "fries", "soda_cola"])
	combo_classic.base_price = 32.0
	combo_classic.is_unlocked = true
	_recipes.append(combo_classic)

	var combo_cheddar = Recipe.new()
	combo_cheddar.id = "combo_cheddar"
	combo_cheddar.display_name = "Combo Cheddar (Burger Cheddar + Batata + Guaraná)"
	combo_cheddar.category = "combo"
	combo_cheddar.combo_items.assign(["burger_cheddar", "fries", "soda_guarana"])
	combo_cheddar.base_price = 38.0
	combo_cheddar.is_unlocked = true
	_recipes.append(combo_cheddar)

static func find_matching_recipe(ingredient_keys: Array) -> Recipe:
	for recipe in get_all_recipes():
		if recipe.matches(ingredient_keys):
			return recipe
	return null

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
