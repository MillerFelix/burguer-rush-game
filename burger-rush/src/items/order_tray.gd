class_name OrderTray
extends Item

@export var max_capacity: int = 6

@onready var slot: Node3D = $TraySlot

var carried_items: Array[Node3D] = []

func _ready() -> void:
	item_id = "order_tray"
	display_name = "Bandeja de Pedido"
	item_type = "tool"
	prompt_text = "E — Pegar Bandeja"

func add_product(item: Node3D) -> bool:
	if carried_items.size() >= max_capacity:
		return false

	var prev_parent = item.get_parent()
	if prev_parent:
		prev_parent.remove_child(item)

	slot.add_child(item)
	var col = carried_items.size() % 3
	var row = carried_items.size() / 3
	item.position = Vector3((col - 1) * 0.22, 0.04, (row - 0.5) * 0.22)
	item.rotation = Vector3.ZERO

	if item.has_method("on_picked_up"):
		item.on_picked_up()
	elif item.get("collision_shape") != null:
		item.collision_shape.disabled = true

	carried_items.append(item)
	return true

func remove_top_product() -> Node3D:
	if carried_items.is_empty():
		return null

	var item = carried_items.pop_back()
	if item.get_parent() == slot:
		slot.remove_child(item)
	return item

func remove_product(item: Node3D) -> bool:
	if carried_items.has(item):
		carried_items.erase(item)
		if item.get_parent() == slot:
			slot.remove_child(item)
		return true
	return false

func get_products() -> Array[Node3D]:
	return carried_items
