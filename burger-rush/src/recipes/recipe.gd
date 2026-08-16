class_name Recipe
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var required_ingredients: Array[String] = []
@export var result_scene: PackedScene
@export var base_price: float = 15.0
@export var preparation_time: float = 0.0
@export var category: String = "burger" # burger, fries, drink, combo
@export var combo_items: Array[String] = []
@export var is_unlocked: bool = true

# Retorna dicionário com contagem exata de ingredientes necessários (ex: {"patty_beef:cooked": 2, "cheese_cheddar": 2})
func get_ingredient_counts() -> Dictionary:
	var counts: Dictionary = {}
	for ing in required_ingredients:
		var k = _normalize_key(ing)
		counts[k] = counts.get(k, 0) + 1
	return counts

# Retorna dicionário com consumo de matéria-prima bruta para estoque (ex: {"patty_beef": 2, "cheese_cheddar": 2, "bread": 1})
func get_raw_ingredient_consumption() -> Dictionary:
	var raw_counts: Dictionary = {}
	for ing in required_ingredients:
		var raw_id = ing.split(":")[0]
		# Normaliza equivalências
		if raw_id == "bread_bottom" or raw_id == "bread_top":
			raw_id = "bread"
		elif raw_id == "sauce" or raw_id.begins_with("sauce_"):
			raw_id = raw_id.replace("sauce_", "")
		raw_counts[raw_id] = raw_counts.get(raw_id, 0) + 1
	return raw_counts

func matches(ingredient_keys: Array) -> bool:
	var req_counts = get_ingredient_counts()
	var given_counts: Dictionary = {}

	for k in ingredient_keys:
		var norm_k = _normalize_key(str(k))
		given_counts[norm_k] = given_counts.get(norm_k, 0) + 1

	if req_counts.size() != given_counts.size():
		return false

	for k in req_counts.keys():
		if not given_counts.has(k) or given_counts[k] != req_counts[k]:
			return false

	return true

func _normalize_key(k: String) -> String:
	var s = k.strip_edges()
	# Pão pode ser representado por "bread" ou "bread_bottom"+"bread_top"
	if s == "bread":
		return "bread"
	elif s == "patty" or s == "patty:cooked":
		return "patty_beef:cooked"
	elif s == "patty:raw":
		return "patty_beef:raw"
	elif s == "cheese":
		return "cheese_cheddar"
	elif s == "bacon:cooked":
		return "bacon"
	elif s == "egg:cooked":
		return "egg"
	return s

func calculate_cost() -> float:
	var inv = InventoryManager.get_instance()
	var total_cost: float = 0.0
	var raw_counts = get_raw_ingredient_consumption()

	for raw_id in raw_counts.keys():
		var qty = raw_counts[raw_id] as int
		if inv:
			var item = inv.get_item(raw_id)
			if item:
				total_cost += item.unit_cost * qty
			else:
				total_cost += _fallback_ingredient_cost(raw_id) * qty
		else:
			total_cost += _fallback_ingredient_cost(raw_id) * qty
	return total_cost

func get_estimated_profit() -> float:
	return base_price - calculate_cost()

func _fallback_ingredient_cost(ing_id: String) -> float:
	match ing_id:
		"patty_beef", "patty":
			return 5.0
		"patty_chicken":
			return 4.5
		"bread", "bread_bottom", "bread_top":
			return 1.2
		"cheese_mozzarella", "cheese_cheddar", "cheese_prato", "cheese":
			return 2.0
		"bacon":
			return 3.0
		"egg":
			return 1.5
		"lettuce", "tomato", "onion", "red_onion", "pickle":
			return 1.0
		"ketchup", "mustard", "mayo", "special_sauce", "sauce":
			return 0.8
		"burger":
			return 7.0
		_:
			return 2.0
