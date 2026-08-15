class_name CommercialChestFreezer
extends Node3D

# ================================================================
# FREEZER HORIZONTAL DE CHÃO — ARMAZENAMENTO DOS QUEIJOS
#
# Arquitetura Física e Visual:
#  Node3D "CommercialChestFreezer" (raiz)
#  ├── FreezerBody       (StaticBody3D) — gabinete externo, revestimento interno,
#  │                                      divisórias e fatias de queijo visíveis
#  ├── MozzarellaSlot    (StaticBody3D) — slot interativo da Muçarela (Esq)
#  ├── CheddarSlot       (StaticBody3D) — slot interativo do Cheddar (Centro)
#  ├── PratoSlot         (StaticBody3D) — slot interativo do Queijo Prato (Dir)
#  ├── LidPivot          (Node3D)       — pivô superior traseiro (tampa articulada)
#  │   └── ChestLid      (StaticBody3D) — tampa superior articulada + puxador
#  ├── InteriorLight     (OmniLight3D)  — iluminação interna LED
#  └── StatusLabel       (Label3D)      — monitor de status e estoque
#
# Sistema de Controle:
#  - [E] — Interage com o equipamento (abre e fecha a tampa superior articulada)
#  - [Clique do Mouse] — Manipula itens (pegar e devolver fatias nos compartimentos)
# ================================================================

enum State {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING
}

const LID_OPEN_ANGLE_DEG: float = -80.0
const LID_CLOSE_ANGLE_DEG: float = 0.0
const LID_ANIM_SECS: float = 0.40

@export var initial_state: State = State.CLOSED

var current_state: State = State.CLOSED
var is_animating: bool = false

@onready var lid_pivot: Node3D = get_node_or_null("LidPivot")
@onready var status_label: Label3D = get_node_or_null("StatusLabel")
@onready var interior_light: OmniLight3D = get_node_or_null("InteriorLight")

@onready var moz_slot_col: CollisionShape3D = get_node_or_null("MozzarellaSlot/CollisionShape3D")
@onready var che_slot_col: CollisionShape3D = get_node_or_null("CheddarSlot/CollisionShape3D")
@onready var pra_slot_col: CollisionShape3D = get_node_or_null("PratoSlot/CollisionShape3D")

func _ready() -> void:
	current_state = initial_state
	_apply_state_instant(current_state)

	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_labels()

func is_door_open() -> bool:
	return current_state == State.OPEN

# ─── Controle da Tampa Articulada (Tecla E) ────────────────────
func toggle_lid(player: Node3D = null) -> void:
	if is_animating:
		return
	if current_state == State.CLOSED:
		open_freezer(player)
	elif current_state == State.OPEN:
		close_freezer(player)

func open_freezer(player: Node3D = null) -> void:
	if current_state == State.OPEN or is_animating:
		return
	is_animating = true
	current_state = State.OPENING
	_set_slots_enabled(false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if lid_pivot:
		tween.tween_property(lid_pivot, "rotation_degrees:x", LID_OPEN_ANGLE_DEG, LID_ANIM_SECS)
	if interior_light:
		tween.tween_property(interior_light, "light_energy", 1.2, LID_ANIM_SECS)

	tween.finished.connect(func():
		current_state = State.OPEN
		is_animating = false
		_set_slots_enabled(true)
		_update_labels()
		if player:
			_show_feedback(player, "🟢 Freezer aberto — use o [Clique do Mouse] para pegar queijos!")
	)

func close_freezer(player: Node3D = null) -> void:
	if current_state == State.CLOSED or is_animating:
		return
	is_animating = true
	current_state = State.CLOSING
	_set_slots_enabled(false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if lid_pivot:
		tween.tween_property(lid_pivot, "rotation_degrees:x", LID_CLOSE_ANGLE_DEG, LID_ANIM_SECS)
	if interior_light:
		tween.tween_property(interior_light, "light_energy", 0.4, LID_ANIM_SECS)

	tween.finished.connect(func():
		current_state = State.CLOSED
		is_animating = false
		_set_slots_enabled(false)
		_update_labels()
		if player:
			_show_feedback(player, "🔒 Freezer de queijos fechado.")
	)

func _apply_state_instant(state: State) -> void:
	if state == State.OPEN:
		if lid_pivot:
			lid_pivot.rotation_degrees.x = LID_OPEN_ANGLE_DEG
		if interior_light:
			interior_light.light_energy = 1.2
		_set_slots_enabled(true)
	else:
		if lid_pivot:
			lid_pivot.rotation_degrees.x = LID_CLOSE_ANGLE_DEG
		if interior_light:
			interior_light.light_energy = 0.4
		_set_slots_enabled(false)

func _set_slots_enabled(enabled: bool) -> void:
	if moz_slot_col:
		moz_slot_col.disabled = not enabled
	if che_slot_col:
		che_slot_col.disabled = not enabled
	if pra_slot_col:
		pra_slot_col.disabled = not enabled

# ─── Manipulação de Itens (Clique do Mouse) ────────────────────
func handle_slot_item_interaction(player: Node3D, cheese_type: Cheese.CheeseType) -> void:
	if current_state != State.OPEN:
		_show_feedback(player, "Abra o freezer com [E] primeiro!")
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var item_id = "cheese_cheddar"
	var cheese_name = "Queijo Cheddar"
	var icon = "🧀"

	match cheese_type:
		Cheese.CheeseType.MOZZARELLA:
			item_id = "cheese_mozzarella"
			cheese_name = "Queijo Muçarela"
		Cheese.CheeseType.CHEDDAR:
			item_id = "cheese_cheddar"
			cheese_name = "Queijo Cheddar"
		Cheese.CheeseType.PRATO:
			item_id = "cheese_prato"
			cheese_name = "Queijo Prato"

	# Caso 1: Jogador segurando um item -> tentar Devolver
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Cheese and held.cheese_type == cheese_type:
			player.take_held_item().queue_free()
			inv.add_stock(item_id, 1)
			_show_feedback(player, "%s Devolveu %s ao freezer (Estoque: %d)" % [icon, cheese_name, inv.get_stock(item_id)])
			_update_labels()
		elif str(held.get("item_type")) == "crate" or str(held.get("item_type")) == "storage_box":
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			player.take_held_item().queue_free()
			inv.add_stock(item_id, qty)
			_show_feedback(player, "📦 %s armazenado no freezer (+%d un.)!" % [cheese_name, qty])
			_update_labels()
		else:
			_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# Caso 2: Jogador com as mãos livres -> Pegar queijo
	if not inv.has_stock(item_id, 1):
		_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % cheese_name)
		return

	inv.consume_stock(item_id, 1)
	var cheese_scene = load("res://src/items/cheese.tscn")
	var cheese = cheese_scene.instantiate() as Cheese
	cheese.cheese_type = cheese_type
	if is_inside_tree() and get_tree().root:
		get_tree().root.add_child(cheese)
	else:
		add_child(cheese)
	cheese._ready()

	if player.has_method("pick_up"):
		player.pick_up(cheese)
	_show_feedback(player, "%s Pegou %s (Estoque: %d)" % [icon, cheese_name, inv.get_stock(item_id)])
	_update_labels()

# ─── Prompts e Atualizações ────────────────────────────────────
func get_slot_prompt(player: Node, cheese_type: Cheese.CheeseType) -> String:
	if current_state != State.OPEN:
		return ""

	var item_id = "cheese_cheddar"
	var cheese_name = "Queijo Cheddar"
	var icon = "🧀"

	match cheese_type:
		Cheese.CheeseType.MOZZARELLA:
			item_id = "cheese_mozzarella"
			cheese_name = "Queijo Muçarela"
		Cheese.CheeseType.CHEDDAR:
			item_id = "cheese_cheddar"
			cheese_name = "Queijo Cheddar"
		Cheese.CheeseType.PRATO:
			item_id = "cheese_prato"
			cheese_name = "Queijo Prato"

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Cheese and held.cheese_type == cheese_type:
			return "🖱️ Clique para Devolver %s" % cheese_name
		elif str(held.get("item_type")) == "crate" or str(held.get("item_type")) == "storage_box":
			return "🖱️ Clique para Armazenar %s (+10 un.)" % cheese_name
		return ""

	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock(item_id) if inv else 0
	if stock <= 0:
		return "🔴 %s Esgotado!" % cheese_name

	return "%s 🖱️ Clique para Pegar %s (%d em estoque)" % [icon, cheese_name, stock]

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_labels()

func _update_labels() -> void:
	var inv = InventoryManager.get_instance()
	var moz_stock = inv.get_stock("cheese_mozzarella") if inv else 0
	var che_stock = inv.get_stock("cheese_cheddar") if inv else 0
	var pra_stock = inv.get_stock("cheese_prato") if inv else 0

	_update_compartment_label("FreezerBody/Plates/PlateMozzarella/Label", "🧀 MUÇARELA\nx%d" % moz_stock)
	_update_compartment_label("FreezerBody/Plates/PlateCheddar/Label", "🧀 CHEDDAR\nx%d" % che_stock)
	_update_compartment_label("FreezerBody/Plates/PlatePrato/Label", "🧀 PRATO\nx%d" % pra_stock)

	if not status_label:
		return

	if current_state == State.CLOSED:
		status_label.text = "❄️ FREEZER DE QUEIJOS [FECHADO]\n[E] Abrir Tampa Superior"
		status_label.modulate = Color(0.85, 0.95, 1.0, 1.0)
	else:
		status_label.text = "❄️ FREEZER DE QUEIJOS [ABERTO]\nMuçarela: %d │ Cheddar: %d │ Prato: %d\n[E] Fechar Tampa  │  [🖱️ Clique] Pegar/Devolver" % [moz_stock, che_stock, pra_stock]
		status_label.modulate = Color(1.0, 0.95, 0.80, 1.0)

func _update_compartment_label(node_path: String, text: String) -> void:
	var lbl = get_node_or_null(node_path)
	if lbl and lbl is Label3D:
		lbl.text = text

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
