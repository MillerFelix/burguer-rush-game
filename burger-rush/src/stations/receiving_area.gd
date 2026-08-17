class_name ReceivingArea
extends StaticBody3D

# =============================================================================
# BURGER RUSH - ÁREA DE RECEBIMENTO EXTERNA (PALLET DE CARGAS)
#
# Regras:
# 1. 100% livre de textos flutuantes 3D (StatusLabel removido).
# 2. As caixas de papelão são empilhadas fisicamente sobre o pallet de madeira.
# 3. Interação limpa via HUD quando o jogador olha para o pallet ou caixas.
# 4. Som audível de caminhão/buzina de entrega ao descarregar as caixas.
# =============================================================================

static var instance: ReceivingArea = null

@onready var crate_spawn_slot: Node3D = $CrateSpawnSlot

var spawned_boxes: Array[DeliveryBox] = []
var delivery_box_scene: PackedScene = preload("res://src/items/delivery_box.tscn")
var horn_audio: AudioStreamPlayer3D = null

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_setup_audio()

static func get_instance() -> ReceivingArea:
	return instance

func _setup_audio() -> void:
	if not horn_audio:
		horn_audio = AudioStreamPlayer3D.new()
		horn_audio.name = "DeliveryHornAudio"
		horn_audio.unit_size = 14.0
		horn_audio.max_distance = 80.0
		horn_audio.volume_db = 9.0
		horn_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(horn_audio)

func play_delivery_arrival_sound() -> void:
	if horn_audio:
		var sound = SoundSynthesizer.get_stream("truck_horn")
		if not sound:
			sound = SoundSynthesizer.get_stream("order_bell")
		if sound:
			horn_audio.stream = sound
			horn_audio.play()

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
	var offset_y = (spawned_boxes.size() / 4) * 0.30
	box.position = Vector3(offset_x, offset_y, offset_z)
	box.setup_box(item_id, item_name, quantity)
	box.location = Item.ItemLocation.WORLD

	spawned_boxes.append(box)
	play_delivery_arrival_sound()

func get_interaction_prompt(player: Node = null) -> String:
	_clean_destroyed_boxes()
	if spawned_boxes.is_empty():
		return "📦 Pallet de Recebimento Livre"
	return "E — Pegar Caixa de Mercadoria (%d aguardando)" % spawned_boxes.size()

func interact(player: Node3D) -> void:
	_clean_destroyed_boxes()
	if spawned_boxes.is_empty():
		_show_feedback(player, "Nenhuma mercadoria aguardando transporte no pallet.")
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

func _clean_destroyed_boxes() -> void:
	spawned_boxes = spawned_boxes.filter(func(b): return is_instance_valid(b) and b.location == Item.ItemLocation.WORLD and (b.get_parent() == crate_spawn_slot or b.get_parent() == self))

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
