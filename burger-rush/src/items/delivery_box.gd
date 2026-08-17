class_name DeliveryBox
extends Item

# =============================================================================
# BURGER RUSH - CAIXA DE PAPELÃO DE TRANSPORTE E ENTREGA
#
# Características:
# 1. Aparência física de caixa de papelão marrom (Kraft) com fita adesiva.
# 2. Identificação simplificada impressa diretamente na superfície:
#    [DESENHO DO PRODUTO]
#    NOME DO PRODUTO
# 3. Sem quantidade, sem preço, sem textos flutuantes.
# =============================================================================

@export var contained_item_id: String = "patty_beef"
@export var contained_item_name: String = "Hambúrguer de Carne"
@export var quantity: int = 10

@onready var front_stamp: Label3D = $BoxBody/FrontStamp
@onready var back_stamp: Label3D = $BoxBody/BackStamp

func _ready() -> void:
	item_id = "delivery_box"
	display_name = "Caixa de %s (%d un)" % [contained_item_name, quantity]
	item_type = "delivery_box"
	_update_label()

func setup_box(p_item_id: String, p_item_name: String, p_qty: int) -> void:
	contained_item_id = p_item_id
	contained_item_name = p_item_name
	quantity = p_qty
	display_name = "Caixa de %s (%d un)" % [contained_item_name, quantity]
	_update_label()

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		return ""
	return "E — Pegar Caixa de %s" % contained_item_name

func _update_label() -> void:
	if not front_stamp:
		front_stamp = get_node_or_null("BoxBody/FrontStamp")
	if not back_stamp:
		back_stamp = get_node_or_null("BoxBody/BackStamp")

	var icon = _get_item_stamp_icon(contained_item_id)
	var label_name = _get_clean_label_name(contained_item_id, contained_item_name)
	var stamp_text = "%s\n%s" % [icon, label_name.to_upper()]

	if front_stamp:
		front_stamp.text = stamp_text
	if back_stamp:
		back_stamp.text = stamp_text

func _get_clean_label_name(id: String, default_name: String) -> String:
	match id:
		"bread_bottom", "bread_top": return "PÃO"
		"patty_beef": return "HAMBÚRGUER DE CARNE"
		"patty_chicken": return "HAMBÚRGUER DE FRANGO"
		"cheese_mozzarella", "cheese_cheddar", "cheese_prato": return "QUEIJO"
		"lettuce": return "ALFACE"
		"tomato": return "TOMATE"
		"onion": return "CEBOLA"
		"red_onion": return "CEBOLA ROXA"
		"pickle": return "PICLES"
		"bacon": return "BACON"
		"egg": return "OVOS"
		"potato_raw": return "BATATA FRITA"
		"cup_empty": return "COPOS"
		"cylinder_cola", "cylinder_cola_zero", "cylinder_soda", "cylinder_citrus": return "REFIL DE REFRIGERANTE"
		"burger_box": return "CAIXAS DE LANCHE"
		"potato_box": return "EMBALAGENS DE BATATA"
		"delivery_bag": return "SACOS DE DELIVERY"
		"pulp_orange", "pulp_grape", "pulp_strawberry": return "POLPA DE FRUTA"
		_: return default_name

func _get_item_stamp_icon(id: String) -> String:
	match id:
		"bread_bottom", "bread_top": return "🍞"
		"patty_beef": return "🥩"
		"patty_chicken": return "🍗"
		"cheese_mozzarella", "cheese_cheddar", "cheese_prato": return "🧀"
		"lettuce": return "🥬"
		"tomato": return "🍅"
		"onion", "red_onion": return "🧅"
		"pickle": return "🥒"
		"bacon": return "🥓"
		"egg": return "🍳"
		"potato_raw": return "🍟"
		"cup_empty": return "🥤"
		"cylinder_cola", "cylinder_cola_zero", "cylinder_soda", "cylinder_citrus": return "🍾"
		"burger_box": return "📦"
		"potato_box": return "🍟"
		"delivery_bag": return "🛍️"
		"pulp_orange": return "🍊"
		"pulp_grape": return "🍇"
		"pulp_strawberry": return "🍓"
		_: return "📦"
