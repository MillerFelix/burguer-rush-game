class_name PackagedBurger
extends Item

# ================================================================
# HAMBÚRGUER EMBALADO — PRODUTO FINAL PARA ATENDIMENTO E ENTREGA
# ================================================================

@export var recipe_id: String = "burger_classic"
@export var burger_name: String = "Burger Clássico"
@export var ingredients: Array[String] = []
@export var is_valid: bool = true
@export var quality_score: float = 1.0
@export var base_price: float = 22.90

@onready var label_3d: Label3D = get_node_or_null("Label3D")

func _ready() -> void:
	item_id = "packaged_burger"
	item_type = "final_product"
	_update_label()

func setup_from_recipe(p_recipe: Recipe, p_ingredients: Array[String], p_is_valid: bool) -> void:
	if p_recipe:
		recipe_id = p_recipe.id
		burger_name = p_recipe.display_name
		base_price = p_recipe.base_price
	else:
		var inferred = _infer_burger_name(p_ingredients)
		recipe_id = inferred["id"]
		burger_name = inferred["name"]
		base_price = 22.90

	ingredients = p_ingredients.duplicate()
	is_valid = p_is_valid
	display_name = burger_name
	_update_label()

func _infer_burger_name(p_ing: Array[String]) -> Dictionary:
	var has_bacon = false
	var has_cheddar = false
	var has_cheese = false
	var has_salad = false
	var has_chicken = false
	var has_onion = false

	for ing in p_ing:
		var lower = ing.to_lower()
		if "bacon" in lower: has_bacon = true
		if "cheddar" in lower: has_cheddar = true
		if "cheese" in lower or "queijo" in lower or "prato" in lower or "mozzarella" in lower: has_cheese = true
		if "lettuce" in lower or "tomato" in lower or "salada" in lower or "alface" in lower or "tomate" in lower: has_salad = true
		if "chicken" in lower or "frango" in lower: has_chicken = true
		if "onion" in lower or "cebola" in lower: has_onion = true

	if has_chicken:
		return {"id": "burger_chicken", "name": "Burger Chicken"}
	if has_bacon:
		return {"id": "burger_bacon", "name": "Burger Bacon"}
	if has_cheddar:
		return {"id": "burger_cheddar", "name": "Burger Cheddar"}
	if has_salad and has_cheese:
		return {"id": "burger_salad", "name": "Burger Salada"}
	if has_onion:
		return {"id": "burger_onion", "name": "Burger Onion"}
	if has_cheese:
		return {"id": "burger_cheese", "name": "Burger com Queijo"}
	return {"id": "burger_classic", "name": "Burger Clássico"}

func get_display_name() -> String:
	return burger_name

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		return ""
	return "🖱️ Pegar Caixa de Hambúrguer (%s)" % burger_name

func _update_label() -> void:
	if not label_3d:
		label_3d = get_node_or_null("Label3D")
	if label_3d:
		label_3d.visible = false
