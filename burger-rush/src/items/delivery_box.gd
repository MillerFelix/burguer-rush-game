class_name DeliveryBox
extends Item

@export var contained_item_id: String = "bread"
@export var contained_item_name: String = "Pão"
@export var quantity: int = 10

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	item_id = "delivery_box"
	display_name = "Caixa de %s (%d un)" % [contained_item_name, quantity]
	item_type = "storage_box"
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
	return "E — Pegar Caixa de %s (%d un)" % [contained_item_name, quantity]

func _update_label() -> void:
	if label_3d:
		label_3d.text = "📦 %s\nQtd: %d" % [contained_item_name, quantity]
