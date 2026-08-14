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

func matches(ingredient_keys: Array) -> bool:
	var sorted_req = []
	for r in required_ingredients:
		sorted_req.append(str(r))
	sorted_req.sort()

	var sorted_given = []
	for g in ingredient_keys:
		sorted_given.append(str(g))
	sorted_given.sort()

	return sorted_req == sorted_given

func calculate_cost() -> float:
	var inv = InventoryManager.get_instance()
	var total_cost: float = 0.0
	for ing in required_ingredients:
		var raw_id = ing.split(":")[0]
		if inv:
			var item = inv.get_item(raw_id)
			if item:
				total_cost += item.unit_cost
			else:
				total_cost += _fallback_ingredient_cost(raw_id)
		else:
			total_cost += _fallback_ingredient_cost(raw_id)
	return total_cost

func get_estimated_profit() -> float:
	return base_price - calculate_cost()

func _fallback_ingredient_cost(ing_id: String) -> float:
	match ing_id:
		"patty":
			return 5.0
		"bread":
			return 2.0
		"cheese":
			return 2.0
		"burger":
			return 7.0
		_:
			return 2.0
