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
		recipe_id = "custom_burger"
		burger_name = "Burger Artesanal"
		base_price = 20.0

	ingredients = p_ingredients.duplicate()
	is_valid = p_is_valid
	display_name = "📦 %s (Embalado)" % burger_name
	_update_label()

func get_display_name() -> String:
	return "📦 %s (Embalado)" % burger_name

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		return ""
	return "🖱️ Pegar %s" % get_display_name()

func _update_label() -> void:
	if not label_3d:
		label_3d = get_node_or_null("Label3D")
	if label_3d:
		label_3d.text = "🍔 %s\n✓ PRONTO PARA ENTREGA" % burger_name
		label_3d.modulate = Color(0.3, 1.0, 0.4, 1.0) if is_valid else Color(1.0, 0.7, 0.2, 1.0)
