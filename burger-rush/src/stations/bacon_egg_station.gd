class_name BaconEggStation
extends StaticBody3D

# ================================================================
# BANCADA DE ARMAZENAMENTO DE BACON & OVO — ARMAZÉM
#
# Estrutura:
#  StaticBody3D "BaconEggStation"
#  ├── Model (Node3D)
#  │   ├── Table (Tampo + 4 Pernas + Prateleira Inferior)
#  │   ├── BaconArea (Lado Esquerdo: Pacotes Empilhados de Bacon)
#  │   │   ├── Packs (Modelos 3D de pacotes de bacon)
#  │   │   └── Label (Label3D com estoque)
#  │   ├── EggArea (Lado Direito: Cesto com Ovos Individuais)
#  │   │   ├── Basket (Cesto aberto 3D)
#  │   │   ├── Eggs (Modelos 3D de ovos individuais no cesto)
#  │   │   └── Label (Label3D com estoque)
#  │   └── TableBadge (Placa frontal "🥓 BACON & OVOS 🥚")
#  └── StatusLabel (Label3D)
#
# REGRA DE CONTROLE:
#  - E: Reabastecer com caixa de mercadoria / Equipamentos
#  - CLIQUE ESQUERDO: Pegar / manipular bacon e ovos
# ================================================================

@onready var status_label: Label3D = get_node_or_null("StatusLabel")

var items_data: Array[Dictionary] = [
	{
		"id": "bacon",
		"name": "Tirinha de Bacon",
		"icon": "🥓",
		"scene": preload("res://src/items/bacon.tscn"),
		"label_node": "Model/BaconArea/Label"
	},
	{
		"id": "egg",
		"name": "Ovo",
		"icon": "🥚",
		"scene": preload("res://src/items/egg.tscn"),
		"label_node": "Model/EggArea/Label"
	}
]

var active_item_index: int = 0

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_label()

func get_aimed_item_index(player: Node = null) -> int:
	if not player:
		return active_item_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		# Lado esquerdo (X < 0) -> Bacon (index 0)
		# Lado direito (X >= 0) -> Ovo (index 1)
		if col_pt.x < 0.0:
			return 0
		else:
			return 1
	return active_item_index

func get_interaction_prompt(player: Node = null) -> String:
	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# 1. Se o jogador estiver segurando item para devolução ou caixa para reabastecimento
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var held_id = str(held.get("item_id"))

		# Devolução de item cru individual
		if held is Bacon and held.state == Bacon.State.RAW:
			return "🖱️ Clique para Devolver Tirinha de Bacon ao Estoque"
		elif held is Egg and held.state == Egg.State.RAW:
			return "🖱️ Clique para Devolver Ovo ao Cesto"
		elif held_id == item_id and held.get("state") == 0:
			return "🖱️ Clique para Devolver %s ao Estoque" % itm["name"]

		# Reabastecimento com caixa/entrega
		if held.get("ingredient_id") == item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "E / 🖱️ Armazenar %s (+%d unidades)" % [itm["name"], qty]

		return ""

	# 2. Jogador de mãos vazias -> pegar ingrediente (EXCLUSIVAMENTE clique esquerdo)
	var stock = inv.get_stock(item_id)
	var max_cap = inv.get_max_capacity(item_id)
	if max_cap == 0:
		max_cap = 50

	if stock <= 0:
		return "🔴 %s Esgotado! Compre no Computador" % itm["name"]

	return "🖱️ Pegar %s %s (%d/%d)" % [itm["icon"], itm["name"], stock, max_cap]

# [Clique Esquerdo do Mouse] — Manipulação de Itens (Pegar / Devolver)
func interact_item(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	active_item_index = aimed_idx
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	var held = player.get("held_item")

	# 1. Devolução de item cru individual
	if held != null:
		var held_id = str(held.get("item_id"))
		if (held is Bacon and held.state == Bacon.State.RAW) or (held is Egg and held.state == Egg.State.RAW) or (held_id == item_id and held.get("state") == 0):
			if player.has_method("take_held_item"):
				var returned_item = player.take_held_item()
				inv.add_stock(item_id, 1)
				_show_feedback(player, "%s %s devolvido ao armazém (Estoque: %d)" % [itm["icon"], itm["name"], inv.get_stock(item_id)])
				returned_item.queue_free()
				_update_label()
				return

		# Reabastecimento com Caixa de Entrega
		if held.get("ingredient_id") == item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			if player.has_method("take_held_item"):
				var crate = player.take_held_item()
				var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
				inv.add_stock(item_id, qty)
				_show_feedback(player, "📦 %s armazenado na bancada (+%d un.)!" % [itm["name"], qty])
				crate.queue_free()
				_update_label()
				return

		_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# 2. Pegar ingrediente com clique esquerdo (Mãos Livres)
	if held == null:
		if not inv.has_stock(item_id, 1):
			_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % itm["name"])
			return

		var item_scene: PackedScene = itm["scene"]
		if item_scene:
			inv.consume_stock(item_id, 1)
			var item = item_scene.instantiate()
			if "state" in item:
				item.state = 0 # RAW
			if is_inside_tree() and get_tree().root:
				get_tree().root.add_child(item)
			else:
				add_child(item)
			if player.has_method("pick_up"):
				player.pick_up(item)
			_show_feedback(player, "%s Pegou %s (Estoque: %d)" % [itm["icon"], itm["name"], inv.get_stock(item_id)])
			_update_label()

# [E] — Interação com Equipamento (NÃO pega ingrediente; apenas reabastecimento com caixa)
func interact(player: Node3D) -> void:
	var held = player.get("held_item")
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# Reabastecimento com Caixa de Entrega acionado com E
	if held != null and (held.get("ingredient_id") == item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			inv.add_stock(item_id, qty)
			_show_feedback(player, "📦 %s armazenado na bancada (+%d un.)!" % [itm["name"], qty])
			crate.queue_free()
			_update_label()
			return

	# Se tentar apertar E com as mãos vazias, orienta que a tecla correta para ingredientes é o Clique Esquerdo
	if held == null:
		_show_feedback(player, "ℹ️ Use o Clique Esquerdo do mouse para pegar ingredientes.")

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_label()

func _update_label() -> void:
	var inv = InventoryManager.get_instance()
	var b_stock = inv.get_stock("bacon") if inv else 0
	var e_stock = inv.get_stock("egg") if inv else 0

	_update_slot_label("Model/BaconArea/Label", "🥓 BACON\nx%d" % b_stock)
	_update_slot_label("Model/EggArea/Label", "🥚 OVOS\nx%d" % e_stock)

	# Atualiza visibilidade dos modelos conforme estoque
	var bacon_packs = get_node_or_null("Model/BaconArea/Packs")
	if bacon_packs:
		bacon_packs.visible = (b_stock > 0)

	var egg_items = get_node_or_null("Model/EggArea/Eggs")
	if egg_items:
		egg_items.visible = (e_stock > 0)

	if not status_label:
		return

	status_label.text = "🥓 BANCADA DE BACON & OVOS 🥚\n🥓 Bacon: %d un.  │  🥚 Ovos: %d un.\n[Clique Esquerdo] Pegar item apontado" % [b_stock, e_stock]
	status_label.modulate = Color(0.98, 0.92, 0.82, 1.0)

func _update_slot_label(node_path: String, text: String) -> void:
	var lbl = get_node_or_null(node_path)
	if lbl and lbl is Label3D:
		lbl.text = text

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
