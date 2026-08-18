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
	var best_recipe = p_recipe
	if not best_recipe:
		best_recipe = RecipeDatabase.find_matching_recipe(p_ingredients)

	if best_recipe:
		recipe_id = best_recipe.id
		burger_name = best_recipe.display_name
		base_price = best_recipe.base_price
		is_valid = p_is_valid if p_recipe else best_recipe.matches(p_ingredients)
	else:
		recipe_id = "burger_custom"
		burger_name = "Burger Personalizado"
		base_price = 20.00
		is_valid = false

	ingredients = p_ingredients.duplicate()
	display_name = burger_name
	_update_label()

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
