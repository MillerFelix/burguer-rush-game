class_name ProgressionManager
extends Node

signal feature_unlocked(feature_id: String)

static var instance: ProgressionManager = null

var unlocked_features: Dictionary = {
	"dine_in": true,
	"burger": true,
	"cheeseburger": true,
	"bread": true,
	"patty": true,
	"cheese": true,
	"sauce": true,
	"burger_box": true,
	"fries": true,
	"potato_raw": true,
	"potato_box": true,
	"soda": true,
	"cup_empty": true,
	"cup_lid": true,
	"syrup_soda": true,
	"combo_classic": true,
	"x_salada": true,
	"lettuce": true,
	"tomato": true,
	"onion": false,
	"x_bacon": false,
	"bacon": false,
	"combo_bacon": false,
	"delivery": false
}

var unlock_costs: Dictionary = {
	"x_salada": 250.0,
	"x_bacon": 400.0,
	"combo_bacon": 500.0,
	"delivery": 600.0,
	"lettuce": 100.0,
	"tomato": 100.0,
	"onion": 80.0,
	"bacon": 150.0
}

func _enter_tree() -> void:
	instance = self

static func get_instance() -> ProgressionManager:
	return instance

func is_unlocked(feature_id: String) -> bool:
	return unlocked_features.get(feature_id, false)

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

		if feature_id == "x_salada":
			unlocked_features["lettuce"] = true
			unlocked_features["tomato"] = true
			unlocked_features["onion"] = true
		elif feature_id == "x_bacon":
			unlocked_features["bacon"] = true
		elif feature_id == "combo_bacon":
			unlocked_features["x_bacon"] = true
			unlocked_features["bacon"] = true

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
