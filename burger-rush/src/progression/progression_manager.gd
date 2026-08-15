class_name ProgressionManager
extends Node

signal feature_unlocked(feature_id: String)

static var instance: ProgressionManager = null

var unlocked_features: Dictionary = {
	# Sistema base
	"dine_in": true,
	"delivery": true,
	# Ingredientes
	"bread": true,
	"bread_bottom": true,
	"bread_top": true,
	"patty_beef": true,
	"patty_chicken": true,
	"cheese_mozzarella": true,
	"cheese_cheddar": true,
	"cheese_prato": true,
	"lettuce": true,
	"tomato": true,
	"onion": true,
	"red_onion": true,
	"pickle": true,
	"bacon": true,
	"egg": true,
	"sauce_ketchup": true,
	"sauce_mustard": true,
	"sauce_mayo": true,
	"sauce_special": true,
	# Acompanhamentos e embalagens
	"fries": true,
	"potato_raw": true,
	"potato_box": true,
	"burger_box": true,
	"cup_empty": true,
	"cup_lid": true,
	"syrup_soda": true,
	"cooking_oil": true,
	# Bebidas
	"soda_cola": true,
	"soda_guarana": true,
	"soda_sprite": true,
	"soda_grape": true,
	"soda_cola_zero": true,
	"soda": true,
	"juice_orange": true,
	"juice_grape": true,
	"juice_passion": true,
	# Novos burgers — TODOS DESBLOQUEADOS desde o início
	"burger_classic": true,
	"burger_double": true,
	"burger_cheddar": true,
	"burger_bacon": true,
	"burger_salad": true,
	"burger_onion": true,
	"burger_chicken": true,
	"burger_supreme": true,
	"burger_cheese": true,
	"burger_vegan": true,
	"burger_egg": true,
	# Combos
	"combo_classic": true,
	"combo_cheddar": true,
}

var unlock_costs: Dictionary = {
	# Reservado para futuras expansões de progressão
}

func _enter_tree() -> void:
	instance = self

static func get_instance() -> ProgressionManager:
	return instance

func is_unlocked(feature_id: String) -> bool:
	# Verifica no dicionário de features primeiro
	if unlocked_features.has(feature_id):
		return unlocked_features[feature_id]
	# Fallback: verifica se a própria receita está marcada como unlocked
	var recipe = RecipeDatabase.get_recipe_by_id(feature_id)
	if recipe:
		return recipe.is_unlocked
	# Ingredientes do inventário: se não estiver explicitamente bloqueado, considera liberado
	return true

func get_unlock_cost(feature_id: String) -> float:
	return unlock_costs.get(feature_id, 0.0)

func can_unlock(feature_id: String) -> Dictionary:
	if is_unlocked(feature_id):
		return {"success": false, "message": "Já desbloqueado."}

	var cost = get_unlock_cost(feature_id)
	var economy = EconomyManager.get_instance()
	if not economy or economy.get_money() < cost:
		return {"success": false, "message": "Saldo insuficiente (Necessário $%.2f)." % cost}

	return {"success": true, "message": "Disponível para desbloqueio."}

func unlock_with_money(feature_id: String) -> Dictionary:
	var check = can_unlock(feature_id)
	if not check.get("success", false):
		return check

	var cost = get_unlock_cost(feature_id)
	var economy = EconomyManager.get_instance()

	if economy and economy.spend_money(cost, "Desbloqueio: %s" % feature_id.capitalize()):
		unlocked_features[feature_id] = true
		feature_unlocked.emit(feature_id)
		return {"success": true, "message": "🎉 %s desbloqueado com sucesso por $%.2f!" % [feature_id.capitalize(), cost]}

	return {"success": false, "message": "Falha na transação financeira."}

func unlock_feature(feature_id: String) -> void:
	unlocked_features[feature_id] = true
	feature_unlocked.emit(feature_id)

func get_unlocked_recipes() -> Array[String]:
	var list: Array[String] = []
	for r in RecipeDatabase.get_all_recipes():
		if r.id.ends_with("_upgrade"):
			continue
		if is_unlocked(r.id):
			list.append(r.id)
	return list
