class_name MeatRefrigerator
extends Node3D

# ================================================================
# GELADEIRA COMERCIAL DE CARNES — RECONSTRUÇÃO COMPLETA
#
# Arquitetura Física e Visual:
#  Node3D "CommercialRefrigerator" (raiz)
#  ├── FridgeBody       (StaticBody3D) — paredes externas (colisão periférica),
#  │                                    cavidade interna profunda, prateleiras,
#  │                                    cestos vazados e modelos de alimentos
#  ├── BeefSlot         (StaticBody3D) — slot interativo cesto esquerdo (Carne Bovina)
#  ├── ChickenSlot      (StaticBody3D) — slot interativo cesto direito (Frango)
#  ├── DoorPivot        (Node3D)       — pivô na dobradiça esquerda
#  │   └── FridgeDoor   (StaticBody3D) — moldura + vidro translúcido + puxador
#  ├── InteriorLight    (OmniLight3D)  — iluminação interna suave e convidativa
#  └── StatusLabel      (Label3D)      — monitor de status e estoque
#
# Sistema de Controle:
#  - [E] — Interage com o equipamento (abre e fecha a porta de vidro)
#  - [Clique do Mouse] — Manipula itens (pegar e devolver hambúrgueres nos cestos)
# ================================================================

const DOOR_OPEN_ANGLE_DEG: float = -85.0
const DOOR_CLOSE_ANGLE_DEG: float = 0.0
const DOOR_ANIM_SECS: float = 0.45

var is_open: bool = false
var is_animating: bool = false

@onready var door_pivot: Node3D = $DoorPivot
@onready var status_label: Label3D = $StatusLabel
@onready var beef_slot_col: CollisionShape3D = $BeefSlot/CollisionShape3D
@onready var chicken_slot_col: CollisionShape3D = $ChickenSlot/CollisionShape3D
@onready var interior_light: OmniLight3D = get_node_or_null("InteriorLight")

# Grupos de alimentos visuais
@onready var beef_food_group: Node3D = get_node_or_null("FridgeBody/BeefFoodGroup")
@onready var chicken_food_group: Node3D = get_node_or_null("FridgeBody/ChickenFoodGroup")

func _ready() -> void:
	# Inicialmente porta fechada → slots desabilitados
	_set_slots_enabled(false)
	if interior_light:
		interior_light.light_energy = 0.4

	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)

	_update_label()
	_update_patty_visuals()

## Retorna se a geladeira está com a porta aberta
func is_door_open() -> bool:
	return is_open

func interact_equipment(player: Node3D) -> void:
	toggle_door(player)

func interact(player: Node3D) -> void:
	toggle_door(player)

# ─── Controle da Porta (Tecla E) ───────────────────────────────
func toggle_door(player: Node3D = null) -> void:
	if is_animating:
		return
	if is_open:
		close_door(player)
	else:
		open_door(player)

func open_door(player: Node3D = null) -> void:
	if is_open or is_animating:
		return
	is_animating = true
	_set_slots_enabled(false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if door_pivot:
		tween.tween_property(door_pivot, "rotation_degrees:y", DOOR_OPEN_ANGLE_DEG, DOOR_ANIM_SECS)
	if interior_light:
		tween.tween_property(interior_light, "light_energy", 1.0, DOOR_ANIM_SECS)

	tween.finished.connect(func():
		is_open = true
		is_animating = false
		_set_slots_enabled(true)
		_update_label()
		if player:
			_show_feedback(player, "🟢 Geladeira aberta — use o [Clique do Mouse] para pegar hambúrgueres!")
	)

func close_door(player: Node3D = null) -> void:
	if not is_open or is_animating:
		return
	is_animating = true
	_set_slots_enabled(false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if door_pivot:
		tween.tween_property(door_pivot, "rotation_degrees:y", DOOR_CLOSE_ANGLE_DEG, DOOR_ANIM_SECS)
	if interior_light:
		tween.tween_property(interior_light, "light_energy", 0.4, DOOR_ANIM_SECS)

	tween.finished.connect(func():
		is_open = false
		is_animating = false
		_set_slots_enabled(false)
		_update_label()
		if player:
			_show_feedback(player, "🔒 Geladeira fechada.")
	)

func _apply_state_instant(open_state: bool) -> void:
	is_open = open_state
	is_animating = false
	if door_pivot:
		door_pivot.rotation_degrees.y = DOOR_OPEN_ANGLE_DEG if is_open else DOOR_CLOSE_ANGLE_DEG
	if interior_light:
		interior_light.light_energy = 1.0 if is_open else 0.4
	_set_slots_enabled(is_open)

# ─── Retirada de Alimentos (Clique do Mouse) ───────────────────
func pick_meat(player: Node3D, meat_id: String) -> void:
	if not is_open:
		_show_feedback(player, "Abra a porta da geladeira primeiro com [E]!")
		return

	if player.get("held_item") != null:
		_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	var inv = InventoryManager.get_instance()
	if not inv or not inv.has_stock(meat_id, 1):
		var nm = "Carne Bovina" if meat_id == "patty_beef" else "Hambúrguer de Frango"
		_show_feedback(player, "❌ Sem %s! Reabasteça no Computador." % nm)
		return

	inv.consume_stock(meat_id, 1)

	# Instancia o patty com o tipo correto antes do add_child
	var patty_scene: PackedScene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate() as Patty
	if meat_id == "patty_chicken":
		patty.meat_type = Patty.MeatType.CHICKEN
	else:
		patty.meat_type = Patty.MeatType.BEEF

	# Adiciona no topo da cena e entrega para o jogador
	if is_inside_tree() and get_tree().root:
		get_tree().root.add_child(patty)
	elif player.get_parent():
		player.get_parent().add_child(patty)
	else:
		add_child(patty)
	patty._ready()
	player.pick_up(patty)

	var icon = "🥩" if meat_id == "patty_beef" else "🍗"
	var nm2 = "Carne Bovina" if meat_id == "patty_beef" else "Hambúrguer de Frango"
	_show_feedback(player, "%s Pegou %s (Restam: %d)" % [icon, nm2, inv.get_stock(meat_id)])
	_update_label()
	_update_patty_visuals()

# ─── Helpers e Atualizações ────────────────────────────────────
func _set_slots_enabled(enabled: bool) -> void:
	if beef_slot_col:
		beef_slot_col.disabled = not enabled
	if chicken_slot_col:
		chicken_slot_col.disabled = not enabled

func _on_stock_changed(_id: String, _qty: int) -> void:
	_update_label()
	_update_patty_visuals()

func _update_patty_visuals() -> void:
	var inv = InventoryManager.get_instance()
	var beef_stock  = inv.get_stock("patty_beef")    if inv else 10
	var chick_stock = inv.get_stock("patty_chicken") if inv else 10

	if beef_food_group:
		beef_food_group.visible = (beef_stock > 0)
	if chicken_food_group:
		chicken_food_group.visible = (chick_stock > 0)

func _update_label() -> void:
	if not status_label:
		return
	var inv = InventoryManager.get_instance()
	var beef  = inv.get_stock("patty_beef")    if inv else 0
	var chick = inv.get_stock("patty_chicken") if inv else 0
	var door_str = "🟢 ABERTA" if is_open else "🔒 FECHADA"
	status_label.text = "❄️ GELADEIRA — %s\n🥩 Bovina: %d  │  🍗 Frango: %d\n[E] Porta  │  [🖱️ Clique] Pegar/Devolver" % [door_str, beef, chick]
	status_label.modulate = Color(0.5, 1.0, 0.7, 1.0) if is_open else Color(0.4, 0.85, 1.0, 1.0)

func _show_feedback(player: Node3D, msg: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(msg)
