class_name DiningMenuBoard
extends Node3D

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")

@onready var col_left_label: Label3D = get_node_or_null("ColLeftLabel")
@onready var col_right_label: Label3D = get_node_or_null("ColRightLabel")
@onready var extras_label: Label3D = get_node_or_null("ExtrasLabel")

func _ready() -> void:
	MenuPricingManager.register_price_listener(update_menu_prices)
	update_menu_prices()

func _exit_tree() -> void:
	MenuPricingManager.unregister_price_listener(update_menu_prices)

## Atualiza dinamicamente os valores de todos os lanches, porções e bebidas com os preços oficiais
func update_menu_prices() -> void:
	if not col_left_label:
		col_left_label = get_node_or_null("ColLeftLabel") as Label3D
	if not col_right_label:
		col_right_label = get_node_or_null("ColRightLabel") as Label3D
	if not extras_label:
		extras_label = get_node_or_null("ExtrasLabel") as Label3D

	var p_classic = MenuPricingManager.get_selling_price("burger_classic")
	var p_double = MenuPricingManager.get_selling_price("burger_double")
	var p_cheddar = MenuPricingManager.get_selling_price("burger_cheddar")
	var p_bacon = MenuPricingManager.get_selling_price("burger_bacon")
	var p_salad = MenuPricingManager.get_selling_price("burger_salad")
	var p_onion = MenuPricingManager.get_selling_price("burger_onion")

	if col_left_label:
		var txt_l = "Burger Clássico ........... R$ %.2f\nBurger Duplo ............... R$ %.2f\nBurger Cheddar ............ R$ %.2f\nBurger Bacon ............... R$ %.2f\nBurger Salada .............. R$ %.2f\nBurger Onion ............... R$ %.2f" % [
			p_classic, p_double, p_cheddar, p_bacon, p_salad, p_onion
		]
		col_left_label.text = txt_l.replace(".", ",")

	var p_chicken = MenuPricingManager.get_selling_price("burger_chicken")
	var p_supreme = MenuPricingManager.get_selling_price("burger_supreme")
	var p_cheese = MenuPricingManager.get_selling_price("burger_cheese")
	var p_vegan = MenuPricingManager.get_selling_price("burger_vegan")
	var p_egg = MenuPricingManager.get_selling_price("burger_egg")

	if col_right_label:
		var txt_r = "Burger Chicken ........... R$ %.2f\nBurger Supreme ........... R$ %.2f\nBurger Três Queijos ..... R$ %.2f\nBurger Vegano ............. R$ %.2f\nBurger Egg ................... R$ %.2f" % [
			p_chicken, p_supreme, p_cheese, p_vegan, p_egg
		]
		col_right_label.text = txt_r.replace(".", ",")

	var p_fries = MenuPricingManager.get_selling_price("fries")
	var p_soda = MenuPricingManager.get_selling_price("soda_cola")
	var p_juice = MenuPricingManager.get_selling_price("juice_orange")

	if extras_label:
		var txt_e = "🍟  Batata Frita  R$ %.2f     •     🥤  Refrigerante  R$ %.2f     •     🧃  Suco Natural  R$ %.2f" % [
			p_fries, p_soda, p_juice
		]
		extras_label.text = txt_e.replace(".", ",")
