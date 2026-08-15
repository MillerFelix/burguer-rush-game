class_name MeatRefrigerator
extends Node3D

# ================================================================
# GELADEIRA DE CARNES — SIMPLES E FUNCIONAL
#
# Arquitetura:
#  Node3D "CommercialRefrigerator" (raiz, sem física — MeatRefrigerator)
#  ├── FridgeBody    (StaticBody3D) — corpo + interior + visuais
#  ├── BeefSlot      (StaticBody3D) — interação da carne bovina
#  ├── ChickenSlot   (StaticBody3D) — interação da carne frango
#  ├── DoorPivot     (Node3D)       — pivot na dobradiça esquerda
#  │   └── FridgeDoor (StaticBody3D) — porta, raycast → abrir/fechar
#  └── StatusLabel   (Label3D)
#
# Os slots (BeefSlot, ChickenSlot) ficam DESABILITADOS enquanto a porta
# está fechada, e HABILITADOS quando a porta abre — assim o jogador só
# consegue pegar carne com a geladeira aberta, e a porta não interfere.
# ================================================================

const DOOR_OPEN_ANGLE_DEG: float = -85.0
const DOOR_CLOSE_ANGLE_DEG: float = 0.0
const DOOR_ANIM_SECS: float = 0.50

var is_open: bool = false
var is_animating: bool = false

@onready var door_pivot: Node3D    = $DoorPivot
@onready var status_label: Label3D = $StatusLabel
@onready var beef_slot_col: CollisionShape3D   = $BeefSlot/CollisionShape3D
@onready var chicken_slot_col: CollisionShape3D = $ChickenSlot/CollisionShape3D

func _ready() -> void:
	# Inicialmente porta fechada → slots desabilitados
	_set_slots_enabled(false)
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_label()

# ─── Chamado pela FridgeDoor ─────────────────────────────────
func toggle_door(player: Node3D) -> void:
	if is_animating:
		return
	is_animating = true

	# Desabilita slots durante a animação para não gerar interação estranha
	_set_slots_enabled(false)

	var target_deg = DOOR_OPEN_ANGLE_DEG if not is_open else DOOR_CLOSE_ANGLE_DEG
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(door_pivot, "rotation_degrees:y", target_deg, DOOR_ANIM_SECS)
	await tween.finished

	is_open = not is_open
	is_animating = false

	# Habilita slots somente quando aberta
	_set_slots_enabled(is_open)
	_update_label()

	var msg = "🟢 Geladeira aberta — escolha sua carne!" if is_open else "🔒 Geladeira fechada."
	_show_feedback(player, msg)

# ─── Chamado pelos BeefSlot / ChickenSlot ────────────────────
func pick_meat(player: Node3D, meat_id: String) -> void:
	if player.get("held_item") != null:
		_show_feedback(player, "Você já está segurando algo!")
		return

	var inv = InventoryManager.get_instance()
	if not inv or not inv.has_stock(meat_id, 1):
		var nm = "Carne Bovina" if meat_id == "patty_beef" else "Hambúrguer de Frango"
		_show_feedback(player, "❌ Sem %s! Reabasteça no Computador." % nm)
		return

	inv.consume_stock(meat_id, 1)

	# Instanciar patty com tipo correto ANTES de add_child (antes de _ready() disparar)
	var patty_scene: PackedScene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate() as Patty
	if meat_id == "patty_chicken":
		patty.meat_type = Patty.MeatType.CHICKEN
	else:
		patty.meat_type = Patty.MeatType.BEEF

	# Adicionar na raiz da cena — exatamente como o IngredientDispenser faz
	player.get_tree().root.add_child(patty)
	player.pick_up(patty)

	var icon = "🥩" if meat_id == "patty_beef" else "🍗"
	var nm2 = "Carne Bovina" if meat_id == "patty_beef" else "Hambúrguer de Frango"
	_show_feedback(player, "%s Pegou %s (Restam: %d)" % [icon, nm2, inv.get_stock(meat_id)])
	_update_label()

# ─── Helpers ─────────────────────────────────────────────────
func _set_slots_enabled(enabled: bool) -> void:
	if beef_slot_col:
		beef_slot_col.disabled = not enabled
	if chicken_slot_col:
		chicken_slot_col.disabled = not enabled

func _on_stock_changed(_id: String, _qty: int) -> void:
	_update_label()

func _update_label() -> void:
	if not status_label:
		return
	var inv = InventoryManager.get_instance()
	var beef  = inv.get_stock("patty_beef")    if inv else 0
	var chick = inv.get_stock("patty_chicken") if inv else 0
	var door_str = "🟢 ABERTA" if is_open else "🔒 FECHADA"
	status_label.text = "❄️ GELADEIRA — %s\n🥩 Bovina: %d  │  🍗 Frango: %d" % [door_str, beef, chick]
	status_label.modulate = Color(0.5, 1.0, 0.7, 1.0) if is_open else Color(0.4, 0.85, 1.0, 1.0)

func _show_feedback(player: Node3D, msg: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(msg)
