class_name DeliveryBox
extends Item

# =============================================================================
# BURGER RUSH - CAIXA DE PAPELÃO DE TRANSPORTE E ENTREGA DE INGREDIENTES
#
# Características:
# 1. Aparência física de caixa de papelão marrom natural (Kraft) não metálica.
# 2. Identificação simplificada impressa na superfície frontal:
#    NOME DO INGREDIENTE
#    
#    QUANTIDADE UN.
# 3. Texto branco, pequeno, limpo e centralizado dentro da superfície da caixa.
# 4. Sincronização dinâmica de quantidade e persistência enquanto houver conteúdo.
# =============================================================================

@export var contained_item_id: String = "patty_beef"
@export var contained_item_name: String = "Hambúrguer de Carne"
@export var quantity: int = 20

@onready var front_stamp: Label3D = $BoxBody/FrontStamp
@onready var back_stamp: Label3D = $BoxBody/BackStamp

func _ready() -> void:
	item_id = "delivery_box"
	item_type = "delivery_box"
	_update_label()

func setup_box(p_item_id: String, p_item_name: String, p_qty: int) -> void:
	contained_item_id = p_item_id
	contained_item_name = p_item_name
	quantity = p_qty
	_update_label()

func set_quantity(new_qty: int) -> void:
	quantity = maxi(0, new_qty)
	_update_label()
	if quantity <= 0:
		queue_free()

func consume_units(amount: int) -> int:
	var to_take = mini(amount, quantity)
	quantity -= to_take
	_update_label()
	if quantity <= 0:
		queue_free()
	return to_take

func get_clean_name() -> String:
	return _get_clean_label_name(contained_item_id, contained_item_name)

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		return ""
	var clean_name = get_clean_name()
	return "E — Pegar Caixa de %s (%d un.)" % [clean_name, quantity]

func _update_label() -> void:
	if not front_stamp:
		front_stamp = get_node_or_null("BoxBody/FrontStamp")
	if not back_stamp:
		back_stamp = get_node_or_null("BoxBody/BackStamp")

	var label_name = _get_clean_label_name(contained_item_id, contained_item_name)
	display_name = "Caixa de %s (%d un)" % [label_name, quantity]

	var stamp_text = "%s\n\n%d UN." % [label_name, quantity]

	if front_stamp:
		front_stamp.text = stamp_text
		front_stamp.modulate = Color.WHITE
	if back_stamp:
		back_stamp.text = stamp_text
		back_stamp.modulate = Color.WHITE

func _get_clean_label_name(id: String, default_name: String) -> String:
	match id:
		"bread", "bread_bottom", "bread_top": return "PÃO"
		"patty_beef", "beef", "meat": return "CARNE"
		"patty_chicken", "chicken": return "FRANGO"
		"cheese_mozzarella", "cheese_cheddar", "cheese_prato", "cheese": return "QUEIJO"
		"lettuce": return "ALFACE"
		"tomato": return "TOMATE"
		"onion": return "CEBOLA"
		"red_onion": return "CEBOLA ROXA"
		"pickle": return "PICLES"
		"bacon": return "BACON"
		"egg": return "OVO"
		"potato_raw", "potato": return "BATATA"
		"oil", "cooking_oil": return "ÓLEO"
		"cup_empty", "cup": return "COPOS"
		"cylinder_cola": return "REFIL COLA"
		"cylinder_cola_zero": return "REFIL ZERO"
		"cylinder_soda": return "REFIL SODA"
		"cylinder_citrus": return "REFIL CITRUS"
		"burger_box": return "CAIXAS DE LANCHE"
		"potato_box": return "EMBALAGENS DE BATATA"
		"delivery_bag": return "SACOS DE DELIVERY"
		"pulp_orange": return "POLPA DE LARANJA"
		"pulp_grape": return "POLPA DE UVA"
		"pulp_strawberry": return "POLPA DE MORANGO"
		_:
			if default_name != "":
				var d = default_name.to_upper()
				d = d.replace("HAMBÚRGUER DE CARNE", "CARNE").replace("HAMBÚRGUER DE FRANGO", "FRANGO")
				return d
			return id.to_upper()
