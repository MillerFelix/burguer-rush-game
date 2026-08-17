class_name PulpStorageTable
extends StaticBody3D

# ================================================================
# MESA DE ARMAZENAMENTO DE POLPAS CONGELADAS NO ARMAZÉM
# Sistema de Estoque Visual Dinâmico em 3 Estágios (Laranja, Uva, Morango)
# Sem textos ou labels 3D flutuantes
#
# REGRA DE CONTROLE:
#  - E: Reabastecer com caixa de mercadoria / Equipamentos
#  - CLIQUE ESQUERDO: Pegar / manipular pedras de polpa
# ================================================================

const JUICE_PULP_SCENE = preload("res://src/items/juice_pulp.tscn")

@export var stock_orange: int = 10:
	set(val):
		stock_orange = clamp(val, 0, 50)
		_update_pulp_visuals(0)

@export var stock_grape: int = 10:
	set(val):
		stock_grape = clamp(val, 0, 50)
		_update_pulp_visuals(1)

@export var stock_strawberry: int = 10:
	set(val):
		stock_strawberry = clamp(val, 0, 50)
		_update_pulp_visuals(2)

const FLAVORS = [
	{ "id": "orange", "item_id": "pulp_orange", "name": "Laranja", "icon": "🍊", "color": Color(0.98, 0.52, 0.05, 1.0) },
	{ "id": "grape", "item_id": "pulp_grape", "name": "Uva", "icon": "🍇", "color": Color(0.48, 0.12, 0.65, 1.0) },
	{ "id": "strawberry", "item_id": "pulp_strawberry", "name": "Morango", "icon": "🍓", "color": Color(0.92, 0.12, 0.28, 1.0) }
]

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_sync_from_inventory()
	_update_all_visuals()

func _on_stock_changed(_item_id: String, _new_qty: int) -> void:
	_sync_from_inventory()
	_update_all_visuals()

func _sync_from_inventory() -> void:
	var inv = InventoryManager.get_instance()
	if inv:
		stock_orange = inv.get_stock("pulp_orange")
		stock_grape = inv.get_stock("pulp_grape")
		stock_strawberry = inv.get_stock("pulp_strawberry")

func _get_aimed_flavor_index(player: Node3D) -> int:
	if not player:
		return 0
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.x < -0.16:
			return 0 # Laranja (Esquerda)
		elif col_pt.x > 0.16:
			return 2 # Morango (Direita)
		else:
			return 1 # Uva (Centro)
	return 0

func get_stock(idx: int) -> int:
	var inv = InventoryManager.get_instance()
	if inv:
		match idx:
			0: return inv.get_stock("pulp_orange")
			1: return inv.get_stock("pulp_grape")
			2: return inv.get_stock("pulp_strawberry")
	match idx:
		0: return stock_orange
		1: return stock_grape
		2: return stock_strawberry
	return 0

func set_stock(idx: int, val: int) -> void:
	var inv = InventoryManager.get_instance()
	if inv:
		var item_id = FLAVORS[idx].item_id
		var cur = inv.get_stock(item_id)
		if val > cur:
			inv.add_stock(item_id, val - cur)
		elif val < cur:
			inv.consume_stock(item_id, cur - val)
	match idx:
		0: stock_orange = val
		1: stock_grape = val
		2: stock_strawberry = val
	_update_pulp_visuals(idx)

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""
	var idx = _get_aimed_flavor_index(player as Node3D)
	var f_info = FLAVORS[idx]
	var f_name = f_info.name
	var icon = f_info.icon

	# Devolução / Reabastecimento com mãos ocupadas
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is JuicePulp and held.fruit_type == f_info.id:
			return "%s 🖱️ Devolver Polpa de %s" % [icon, f_name]
		elif held.get("ingredient_id") == f_info.item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "📦 🖱️ Armazenar Polpa de %s (+%d un.)" % [f_name, qty]
		return ""

	var count = get_stock(idx)
	if count <= 0:
		return "🔴 Polpa de %s Esgotada" % f_name
	return "%s 🖱️ Pegar Polpa de %s" % [icon, f_name]

# Regra Burger Rush: E é estritamente para máquinas, portas e equipamentos
func interact(player: Node3D) -> void:
	var held = player.get("held_item")
	var idx = _get_aimed_flavor_index(player)
	var f_info = FLAVORS[idx]

	if held != null and (held.get("ingredient_id") == f_info.item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			var inv = InventoryManager.get_instance()
			if inv:
				inv.add_stock(f_info.item_id, qty)
			else:
				set_stock(idx, get_stock(idx) + qty)
			_show_feedback(player, "📦 Polpa de %s armazenada (+%d un.)!" % [f_info.name, qty])
			crate.queue_free()
			_update_all_visuals()
			return

	_show_feedback(player, "ℹ️ Use [Clique Esquerdo] para pegar a pedra de polpa de %s." % f_info.name)

# Clique Esquerdo: manipula pedras de polpa (Pegar / Devolver)
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var idx = _get_aimed_flavor_index(player)
	var f_info = FLAVORS[idx]
	var held = player.get("held_item")

	# Devolução de pedra de polpa
	if held != null:
		if held is JuicePulp and held.fruit_type == f_info.id:
			if player.has_method("take_held_item"):
				var returned_pulp = player.take_held_item()
				var inv = InventoryManager.get_instance()
				if inv:
					inv.add_stock(f_info.item_id, 1)
				else:
					set_stock(idx, get_stock(idx) + 1)
				_show_feedback(player, "%s Polpa de %s devolvida à mesa" % [f_info.icon, f_info.name])
				returned_pulp.queue_free()
				_update_all_visuals()
				return
		elif str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var box_id = str(held.get("contained_item_id"))
			var target_flavor_id = f_info.item_id
			var valid_pulps = ["pulp_orange", "pulp_grape", "pulp_strawberry"]
			if box_id in valid_pulps:
				target_flavor_id = box_id
			if box_id in valid_pulps or box_id == "":
				if player.has_method("take_held_item"):
					var crate = player.take_held_item()
					var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
					var inv = InventoryManager.get_instance()
					if inv:
						inv.add_stock(target_flavor_id, qty)
					_show_feedback(player, "📦 Polpa de %s armazenada (+%d un.)!" % [str(held.get("contained_item_name")), qty])
					crate.queue_free()
					_update_all_visuals()
					return
			else:
				_show_feedback(player, "⚠️ Local incorreto! Esta caixa contém %s. Leve até a estação correta." % str(held.get("contained_item_name")))
				return

		_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	take_pulp(player, idx)

func take_pulp(player: Node3D, target_flavor_idx: int = -1) -> JuicePulp:
	if not player:
		return null
	if player.get("held_item") != null:
		_show_feedback(player, "⚠️ Suas mãos estão ocupadas!")
		return null

	var idx = target_flavor_idx if (target_flavor_idx >= 0 and target_flavor_idx < 3) else _get_aimed_flavor_index(player)
	var count = get_stock(idx)
	var f_info = FLAVORS[idx]
	if count <= 0:
		_show_feedback(player, "🔴 Polpa de %s esgotada no cesto!" % f_info.name)
		return null

	# Reduz o estoque
	var inv = InventoryManager.get_instance()
	if inv:
		inv.consume_stock(f_info.item_id, 1)
	else:
		set_stock(idx, count - 1)

	# Instancia a pedra de polpa na mão do jogador
	var pulp = JUICE_PULP_SCENE.instantiate() as JuicePulp
	if get_parent():
		get_parent().add_child(pulp)
	elif is_inside_tree() and get_tree() and get_tree().root:
		get_tree().root.add_child(pulp)

	pulp.fruit_type = f_info.id
	pulp._setup_pulp_properties()

	if player.has_method("pick_up"):
		player.pick_up(pulp)

	_show_feedback(player, "%s Polpa de %s retirada" % [f_info.icon, f_info.name])
	_update_all_visuals()
	return pulp

func _update_all_visuals() -> void:
	for i in range(3):
		_update_pulp_visuals(i)

func _update_pulp_visuals(idx: int) -> void:
	var stock = get_stock(idx)
	# Padrão dos 3 Estágios:
	# CHEIO (>= 8) -> 10 blocos visíveis
	# MÉDIO (>= 4) -> 5 blocos visíveis
	# BAIXO (> 0)  -> 2 blocos visíveis
	# ZERO (== 0)  -> 0 blocos visíveis
	var visible_count: int = 0
	if stock >= 8:
		visible_count = 10
	elif stock >= 4:
		visible_count = 5
	elif stock > 0:
		visible_count = 2
	else:
		visible_count = 0

	for slot in range(10):
		var node = get_node_or_null("Model/Crate/Pulp_%d_%d" % [idx, slot])
		if node and node is MeshInstance3D:
			node.visible = (slot < visible_count)

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
