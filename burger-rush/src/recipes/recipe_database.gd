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

	# 1. Hambúrguer Básico: Pão + Carne Cozida
	var burger_recipe = Recipe.new()
	burger_recipe.id = "burger"
	burger_recipe.display_name = "Hambúrguer"
	burger_recipe.category = "burger"
	burger_recipe.required_ingredients.assign(["bread", "patty:cooked"])
	burger_recipe.result_scene = burger_scene
	burger_recipe.base_price = 15.0
	burger_recipe.is_unlocked = true
	_recipes.append(burger_recipe)

	# 2. Cheeseburger: Pão + Carne Cozida + Queijo
	var cheeseburger_recipe = Recipe.new()
	cheeseburger_recipe.id = "cheeseburger"
	cheeseburger_recipe.display_name = "Cheeseburger"
	cheeseburger_recipe.category = "burger"
	cheeseburger_recipe.required_ingredients.assign(["bread", "patty:cooked", "cheese"])
	cheeseburger_recipe.result_scene = cheeseburger_scene
	cheeseburger_recipe.base_price = 18.0
	cheeseburger_recipe.is_unlocked = true
	_recipes.append(cheeseburger_recipe)

	# 3. Upgrade: Hambúrguer + Queijo -> Cheeseburger
	var cheeseburger_upgrade = Recipe.new()
	cheeseburger_upgrade.id = "cheeseburger_upgrade"
	cheeseburger_upgrade.display_name = "Cheeseburger"
	cheeseburger_upgrade.category = "burger"
	cheeseburger_upgrade.required_ingredients.assign(["burger", "cheese"])
	cheeseburger_upgrade.result_scene = cheeseburger_scene
	cheeseburger_upgrade.base_price = 18.0
	cheeseburger_upgrade.is_unlocked = true
	_recipes.append(cheeseburger_upgrade)

	# 4. X-Salada: Pão + Carne Cozida + Queijo + Alface + Tomate
	var x_salada = Recipe.new()
	x_salada.id = "x_salada"
	x_salada.display_name = "X-Salada"
	x_salada.category = "burger"
	x_salada.required_ingredients.assign(["bread", "patty:cooked", "cheese", "lettuce", "tomato"])
	x_salada.result_scene = x_salada_scene
	x_salada.base_price = 22.0
	x_salada.is_unlocked = false
	_recipes.append(x_salada)

	# 4b. Upgrade: Cheeseburger + Alface + Tomate -> X-Salada
	var x_salada_up1 = Recipe.new()
	x_salada_up1.id = "x_salada_upgrade"
	x_salada_up1.display_name = "X-Salada"
	x_salada_up1.category = "burger"
	x_salada_up1.required_ingredients.assign(["cheeseburger", "lettuce", "tomato"])
	x_salada_up1.result_scene = x_salada_scene
	x_salada_up1.base_price = 22.0
	x_salada_up1.is_unlocked = false
	_recipes.append(x_salada_up1)

	# 5. X-Bacon: Pão + Carne Cozida + Queijo + Bacon
	var x_bacon = Recipe.new()
	x_bacon.id = "x_bacon"
	x_bacon.display_name = "X-Bacon"
	x_bacon.category = "burger"
	x_bacon.required_ingredients.assign(["bread", "patty:cooked", "cheese", "bacon"])
	x_bacon.result_scene = x_bacon_scene
	x_bacon.base_price = 25.0
	x_bacon.is_unlocked = false
	_recipes.append(x_bacon)

	# 5b. Upgrade: Cheeseburger + Bacon -> X-Bacon
	var x_bacon_up1 = Recipe.new()
	x_bacon_up1.id = "x_bacon_upgrade"
	x_bacon_up1.display_name = "X-Bacon"
	x_bacon_up1.category = "burger"
	x_bacon_up1.required_ingredients.assign(["cheeseburger", "bacon"])
	x_bacon_up1.result_scene = x_bacon_scene
	x_bacon_up1.base_price = 25.0
	x_bacon_up1.is_unlocked = false
	_recipes.append(x_bacon_up1)

	# 6. Batata Frita: Batata + Recipiente
	var fries_recipe = Recipe.new()
	fries_recipe.id = "fries"
	fries_recipe.display_name = "Batata Frita"
	fries_recipe.category = "fries"
	fries_recipe.required_ingredients.assign(["potato_raw", "potato_box"])
	fries_recipe.result_scene = fries_scene
	fries_recipe.base_price = 8.0
	fries_recipe.is_unlocked = true
	_recipes.append(fries_recipe)

	# 7a. Refrigerante Cola
	var cola_recipe = Recipe.new()
	cola_recipe.id = "soda_cola"
	cola_recipe.display_name = "Refrigerante Cola"
	cola_recipe.category = "drink"
	cola_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	cola_recipe.result_scene = soda_scene
	cola_recipe.base_price = 6.0
	cola_recipe.is_unlocked = true
	_recipes.append(cola_recipe)

	# 7b. Refrigerante Guaraná
	var guarana_recipe = Recipe.new()
	guarana_recipe.id = "soda_guarana"
	guarana_recipe.display_name = "Refrigerante Guaraná"
	guarana_recipe.category = "drink"
	guarana_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	guarana_recipe.result_scene = soda_scene
	guarana_recipe.base_price = 6.0
	guarana_recipe.is_unlocked = true
	_recipes.append(guarana_recipe)

	# 7c. Refrigerante Limão
	var sprite_recipe = Recipe.new()
	sprite_recipe.id = "soda_sprite"
	sprite_recipe.display_name = "Refrigerante Limão"
	sprite_recipe.category = "drink"
	sprite_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	sprite_recipe.result_scene = soda_scene
	sprite_recipe.base_price = 6.0
	sprite_recipe.is_unlocked = true
	_recipes.append(sprite_recipe)

	# 7d. Refrigerante Uva
	var grape_soda_recipe = Recipe.new()
	grape_soda_recipe.id = "soda_grape"
	grape_soda_recipe.display_name = "Refrigerante Uva"
	grape_soda_recipe.category = "drink"
	grape_soda_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	grape_soda_recipe.result_scene = soda_scene
	grape_soda_recipe.base_price = 6.0
	grape_soda_recipe.is_unlocked = true
	_recipes.append(grape_soda_recipe)

	# 7e. Refrigerante Cola Zero
	var zero_soda_recipe = Recipe.new()
	zero_soda_recipe.id = "soda_cola_zero"
	zero_soda_recipe.display_name = "Refrigerante Cola Zero"
	zero_soda_recipe.category = "drink"
	zero_soda_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	zero_soda_recipe.result_scene = soda_scene
	zero_soda_recipe.base_price = 6.0
	zero_soda_recipe.is_unlocked = true
	_recipes.append(zero_soda_recipe)

	# 7f. Refrigerante Genérico (compatibilidade)
	var soda_recipe = Recipe.new()
	soda_recipe.id = "soda"
	soda_recipe.display_name = "Refrigerante"
	soda_recipe.category = "drink"
	soda_recipe.required_ingredients.assign(["cup_empty", "syrup_soda", "cup_lid"])
	soda_recipe.result_scene = soda_scene
	soda_recipe.base_price = 6.0
	soda_recipe.is_unlocked = true
	_recipes.append(soda_recipe)

	# 7g. Suco de Laranja
	var juice_orange_recipe = Recipe.new()
	juice_orange_recipe.id = "juice_orange"
	juice_orange_recipe.display_name = "Suco de Laranja"
	juice_orange_recipe.category = "drink"
	juice_orange_recipe.required_ingredients.assign(["cup_empty", "cup_lid"])
	juice_orange_recipe.result_scene = soda_scene
	juice_orange_recipe.base_price = 7.0
	juice_orange_recipe.is_unlocked = true
	_recipes.append(juice_orange_recipe)

	# 7h. Suco de Uva
	var juice_grape_recipe = Recipe.new()
	juice_grape_recipe.id = "juice_grape"
	juice_grape_recipe.display_name = "Suco de Uva"
	juice_grape_recipe.category = "drink"
	juice_grape_recipe.required_ingredients.assign(["cup_empty", "cup_lid"])
	juice_grape_recipe.result_scene = soda_scene
	juice_grape_recipe.base_price = 7.0
	juice_grape_recipe.is_unlocked = true
	_recipes.append(juice_grape_recipe)

	# 7i. Suco de Maracujá
	var juice_passion_recipe = Recipe.new()
	juice_passion_recipe.id = "juice_passion"
	juice_passion_recipe.display_name = "Suco de Maracujá"
	juice_passion_recipe.category = "drink"
	juice_passion_recipe.required_ingredients.assign(["cup_empty", "cup_lid"])
	juice_passion_recipe.result_scene = soda_scene
	juice_passion_recipe.base_price = 7.0
	juice_passion_recipe.is_unlocked = true
	_recipes.append(juice_passion_recipe)

	# 8. Combo Clássico: Cheeseburger + Batata + Refrigerante Cola
	var combo_classic = Recipe.new()
	combo_classic.id = "combo_classic"
	combo_classic.display_name = "Combo Clássico (Cheeseburger + Batata + Cola)"
	combo_classic.category = "combo"
	combo_classic.combo_items.assign(["cheeseburger", "fries", "soda_cola"])
	combo_classic.required_ingredients.assign(["bread", "patty:cooked", "cheese", "potato_raw", "potato_box", "cup_empty", "syrup_soda", "cup_lid"])
	combo_classic.base_price = 28.0
	combo_classic.is_unlocked = true
	_recipes.append(combo_classic)

	# 9. Combo Bacon: X-Bacon + Batata + Refrigerante Guaraná
	var combo_bacon = Recipe.new()
	combo_bacon.id = "combo_bacon"
	combo_bacon.display_name = "Combo Bacon (X-Bacon + Batata + Guaraná)"
	combo_bacon.category = "combo"
	combo_bacon.combo_items.assign(["x_bacon", "fries", "soda_guarana"])
	combo_bacon.required_ingredients.assign(["bread", "patty:cooked", "cheese", "bacon", "potato_raw", "potato_box", "cup_empty", "syrup_soda", "cup_lid"])
	combo_bacon.base_price = 34.0
	combo_bacon.is_unlocked = false
	_recipes.append(combo_bacon)

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
		if recipe_id == "cheeseburger":
			var up = get_recipe_by_id("cheeseburger_upgrade")
			if up:
				up.base_price = new_price
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
