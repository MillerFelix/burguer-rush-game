class_name ReceivingArea
extends StaticBody3D

static var instance: ReceivingArea = null

@onready var status_label: Label3D = $StatusLabel
@onready var crate_spawn_slot: Node3D = $CrateSpawnSlot

var spawned_boxes: Array[DeliveryBox] = []
var delivery_box_scene: PackedScene = preload("res://src/items/delivery_box.tscn")

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_update_visual_status()

static func get_instance() -> ReceivingArea:
	return instance

func has_pending_boxes() -> bool:
	_clean_destroyed_boxes()
	return not spawned_boxes.is_empty()

func add_pending_delivery(item_id: String, item_name: String, quantity: int) -> void:
	var box = delivery_box_scene.instantiate() as DeliveryBox
	if crate_spawn_slot:
		crate_spawn_slot.add_child(box)
	else:
		add_child(box)

	var offset_x = (spawned_boxes.size() % 2) * 0.45 - 0.225
	var offset_z = ((spawned_boxes.size() / 2) % 2) * 0.45 - 0.225
	var offset_y = (spawned_boxes.size() / 4) * 0.35
	box.position = Vector3(offset_x, offset_y, offset_z)
	box.setup_box(item_id, item_name, quantity)
	box.location = Item.ItemLocation.WORLD

	spawned_boxes.append(box)
	_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	_clean_destroyed_boxes()
	if spawned_boxes.is_empty():
		return "📦 Recebimento: Nenhuma carga aguardando"
	return "E — Pegar Próxima Caixa de Mercadoria (%d cargas)" % spawned_boxes.size()

func interact(player: Node3D) -> void:
	_clean_destroyed_boxes()
	if spawned_boxes.is_empty():
		_show_feedback(player, "Nenhuma mercadoria aguardando transporte.")
		return

	if player.get("held_item") == null and player.has_method("pick_up"):
		var box = spawned_boxes.pop_back()
		if is_instance_valid(box):
			if box.get_parent():
				box.get_parent().remove_child(box)
			var tr = player.get_tree() if player.is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tr and tr.root:
				tr.root.add_child(box)
			elif is_inside_tree() and get_tree() and get_tree().root:
				get_tree().root.add_child(box)
			else:
				add_child(box)
			player.pick_up(box)
			_show_feedback(player, "📦 Você pegou a %s. Leve até o estoque correspondente!" % box.display_name)
		_update_visual_status()

func _clean_destroyed_boxes() -> void:
	spawned_boxes = spawned_boxes.filter(func(b): return is_instance_valid(b) and b.location == Item.ItemLocation.WORLD and (b.get_parent() == crate_spawn_slot or b.get_parent() == self))

func _update_visual_status() -> void:
	_clean_destroyed_boxes()
	if not status_label:
		return

	if spawned_boxes.is_empty():
		status_label.text = "📦 RECEBIMENTO\n🟢 Livre"
		status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
	else:
		status_label.text = "📦 RECEBIMENTO\n📦 %d Caixas de Mercadoria\n[E] Pegar para Guardar" % spawned_boxes.size()
		status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
