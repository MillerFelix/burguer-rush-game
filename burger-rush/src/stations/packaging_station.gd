class_name PackagingStation
extends StaticBody3D

@onready var packaging_slot: Node3D = $PackagingSlot
@onready var status_label: Label3D = $StatusLabel

var packaged_item: Node3D = null

var items_data: Array[Dictionary] = [
	{
		"id": "burger_box",
		"name": "Embalagem de Lanche",
		"icon": "📦",
		"scene": preload("res://src/items/burger_box.tscn")
	},
	{
		"id": "potato_box",
		"name": "Embalagem de Batata",
		"icon": "🍟",
		"scene": preload("res://src/items/potato_box.tscn")
	},
	{
		"id": "cup_empty",
		"name": "Copo de Bebida",
		"icon": "🥤",
		"scene": preload("res://src/items/drink_cup.tscn")
	}
]
var active_item_index: int = 0

func _ready() -> void:
	_update_label()

func get_aimed_item_index(player: Node = null) -> int:
	if not player:
		return active_item_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		# Bancada ao longo do eixo Z local:
		# Z < -0.35 -> Lanche, -0.35 <= Z <= 0.35 -> Batata, Z > 0.35 -> Copos
		if col_pt.z < -0.35:
			return 0 # Lanche
		elif col_pt.z > 0.35:
			return 2 # Copos
		else:
			return 1 # Batata
	return active_item_index

func cycle_item(worker: Node3D = null) -> String:
	active_item_index = (active_item_index + 1) % items_data.size()
	var itm = items_data[active_item_index]
	if worker:
		_show_feedback(worker, "📦 Embalagem selecionada: %s %s" % [itm["icon"], itm["name"]])
	_update_label()
	return itm["name"]

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")

	# 1. Se houver item embalado pronto para retirar da bancada
	if packaged_item != null:
		var d_name = packaged_item.get_display_name() if packaged_item.has_method("get_display_name") else packaged_item.name
		if held == null:
			return "🖱️ / [E] Pegar %s Embalado" % d_name
		return ""

	# 2. Se o jogador estiver segurando copo aberto para selar com tampa
	if held != null and held.has_method("has_lid") and not held.has_lid():
		var flv = held.get("flavor") if held.get("flavor") != null else "Bebida"
		return "🖱️ / [E] Selar %s com Tampa e Canudo" % flv

	# 3. Se o jogador estiver segurando comida/lanche para embalar
	if held != null and (held.has_method("can_be_packaged") or str(held.get("item_type")) in ["final_product", "food", "burger", "fries"]):
		var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
		return "🖱️ / [E] Embalar %s para Viagem" % d_name

	# 4. Mão vazia: pode pegar embalagem ou copo diretamente com o clique esquerdo
	if held == null:
		var aimed_idx = get_aimed_item_index(player)
		var itm = items_data[aimed_idx]
		return "🖱️ Pegar %s %s" % [itm["icon"], itm["name"]]

	return ""

# [Clique Esquerdo do Mouse] — Manipulação de Itens / Embalagens
func interact_item(player: Node3D) -> void:
	_handle_packaging_interaction(player)

# [E] — Interação com Equipamento
func interact(player: Node3D) -> void:
	_handle_packaging_interaction(player)

func _handle_packaging_interaction(player: Node3D) -> void:
	var held = player.get("held_item")

	# 1. Retirar item embalado da bancada
	if packaged_item != null and held == null:
		var item = packaged_item
		packaged_item = null
		if packaging_slot and item.get_parent() == packaging_slot:
			packaging_slot.remove_child(item)
		if player.has_method("pick_up"):
			player.pick_up(item)
		_update_label()
		_show_feedback(player, "📦 Pegou %s embalado!" % (item.get_display_name() if item.has_method("get_display_name") else item.name))
		return

	# 2. Selar Copo de Bebida com Tampa e Canudo
	if held != null and held.has_method("has_lid") and not held.has_lid():
		if held.has_method("seal_cup"):
			held.seal_cup()
		elif held.get("lid_mesh") != null:
			held.lid_mesh.visible = true
			if "is_sealed" in held:
				held.is_sealed = true
		_update_label()
		_show_feedback(player, "🥤 Bebida selada com sucesso!")
		return

	# 3. Embalar sanduíche / batata na bancada
	if held != null and (held.has_method("can_be_packaged") or str(held.get("item_type")) in ["final_product", "food", "burger", "fries"]):
		if player.has_method("take_held_item"):
			var food_item = player.take_held_item()
			if food_item:
				_package_item_on_station(food_item)
				_show_feedback(player, "📦 %s embalado para viagem!" % (food_item.get_display_name() if food_item.has_method("get_display_name") else food_item.name))
		return

	# 4. Pegar Embalagem ou Copo individual com as mãos livres (Clique Esquerdo)
	if held == null:
		var aimed_idx = get_aimed_item_index(player)
		active_item_index = aimed_idx
		var itm = items_data[aimed_idx]
		var item_scene: PackedScene = itm["scene"]
		if item_scene:
			var new_item = item_scene.instantiate()
			if is_inside_tree() and get_tree().root:
				get_tree().root.add_child(new_item)
			else:
				add_child(new_item)
			if player.has_method("pick_up"):
				player.pick_up(new_item)
			_show_feedback(player, "📦 Pegou %s" % itm["name"])
			_update_label()

func _package_item_on_station(food_item: Node3D) -> void:
	if packaging_slot:
		var prev_p = food_item.get_parent()
		if prev_p:
			prev_p.remove_child(food_item)
		packaging_slot.add_child(food_item)
		food_item.position = Vector3.ZERO
		food_item.rotation = Vector3.ZERO
		packaged_item = food_item
	_update_label()

func _update_label() -> void:
	if not status_label:
		return
	if packaged_item != null:
		var d_name = packaged_item.get_display_name() if packaged_item.has_method("get_display_name") else packaged_item.name
		status_label.text = "📦 %s (Pronto)" % d_name
		status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
	else:
		var itm = items_data[active_item_index]
		status_label.text = "📦 EMBALAGENS\n[Clique] Pegar %s" % itm["name"]
		status_label.modulate = Color(0.9, 0.9, 0.9, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
