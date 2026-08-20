class_name CommercialChestFreezer
extends Node3D

# ================================================================
# FREEZER HORIZONTAL DE CHÃO — ARMAZENAMENTO DOS QUEIJOS
# Estoque Visual Dinâmico de 3 Estágios: CHEIO | MÉDIO | BAIXO | ZERO
# Sem textos ou labels flutuantes
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
const PowerManager = preload("res://src/core/power_manager.gd")
const LID_CLOSE_ANGLE_DEG: float = 0.0
const LID_ANIM_SECS: float = 0.40

@export var initial_state: State = State.CLOSED

var current_state: State = State.CLOSED
var is_animating: bool = false
var _open_duration: float = 0.0
var _puddle_instance: Node3D = null

var SCENE_PUDDLE = load("res://src/stations/floor_puddle.tscn")

@onready var lid_pivot: Node3D = get_node_or_null("LidPivot")
@onready var cold_mist: CPUParticles3D = get_node_or_null("ColdMistParticles")
@onready var interior_light: OmniLight3D = get_node_or_null("InteriorLight")

@onready var moz_slot_col: CollisionShape3D = get_node_or_null("MozzarellaSlot/CollisionShape3D")
@onready var che_slot_col: CollisionShape3D = get_node_or_null("CheddarSlot/CollisionShape3D")
@onready var pra_slot_col: CollisionShape3D = get_node_or_null("PratoSlot/CollisionShape3D")

# Nós de estoque visual por compartimento (3 Estágios)
@onready var moz_full: Node3D = get_node_or_null("FreezerBody/Products/Mozzarella/Full")
@onready var moz_med: Node3D = get_node_or_null("FreezerBody/Products/Mozzarella/Medium")
@onready var moz_low: Node3D = get_node_or_null("FreezerBody/Products/Mozzarella/Low")

@onready var che_full: Node3D = get_node_or_null("FreezerBody/Products/Cheddar/Full")
@onready var che_med: Node3D = get_node_or_null("FreezerBody/Products/Cheddar/Medium")
@onready var che_low: Node3D = get_node_or_null("FreezerBody/Products/Cheddar/Low")

@onready var pra_full: Node3D = get_node_or_null("FreezerBody/Products/Prato/Full")
@onready var pra_med: Node3D = get_node_or_null("FreezerBody/Products/Prato/Medium")
@onready var pra_low: Node3D = get_node_or_null("FreezerBody/Products/Prato/Low")

var door_audio: AudioStreamPlayer3D = null
var hum_audio: AudioStreamPlayer3D = null
var _target_hum_vol: float = -28.0

func _enter_tree() -> void:
	_setup_audio()

func _ready() -> void:
	_setup_audio()
	current_state = initial_state
	_apply_state_instant(current_state)

	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "chest_freezer", "Freezer de Queijos", 1.5, true)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)

	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_all_visual_stocks()

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func on_power_state_changed(main_power_on: bool) -> void:
	if not main_power_on:
		if hum_audio and hum_audio.playing:
			hum_audio.stop()
		if interior_light:
			interior_light.light_energy = 0.0
		if cold_mist:
			cold_mist.emitting = false
	else:
		if hum_audio and not hum_audio.playing:
			hum_audio.play()
		if interior_light:
			interior_light.light_energy = 1.2 if current_state == State.OPEN else 0.4
		if cold_mist and current_state == State.OPEN:
			cold_mist.emitting = true

func _setup_audio() -> void:
	if not door_audio:
		door_audio = AudioStreamPlayer3D.new()
		door_audio.name = "DoorAudioPlayer"
		door_audio.unit_size = 2.5
		door_audio.max_distance = 15.0
		door_audio.volume_db = -4.0
		add_child(door_audio)

	if not hum_audio:
		hum_audio = AudioStreamPlayer3D.new()
		hum_audio.name = "HumAudioPlayer"
		hum_audio.unit_size = 2.5
		hum_audio.max_distance = 15.0
		hum_audio.volume_db = -28.0
		hum_audio.stream = SoundSynthesizer.get_stream("freezer_hum_loop")
		add_child(hum_audio)
	if hum_audio.is_inside_tree() and not hum_audio.playing:
		hum_audio.play()

func _process(delta: float) -> void:
	if hum_audio:
		if is_inside_tree() and not hum_audio.playing:
			hum_audio.play()
		if absf(hum_audio.volume_db - _target_hum_vol) > 0.05:
			var w = 1.0 - exp(-6.0 * delta)
			hum_audio.volume_db = lerpf(hum_audio.volume_db, _target_hum_vol, w)
		else:
			hum_audio.volume_db = _target_hum_vol

	# Efeito de perda de frio e formação de poça quando aberto por tempo suficiente
	if current_state == State.OPEN:
		_open_duration += delta
		if _open_duration >= 6.0:
			_process_condensation_puddle(delta)
	else:
		_open_duration = 0.0

func _process_condensation_puddle(delta: float) -> void:
	if _puddle_instance == null or not is_instance_valid(_puddle_instance):
		var parent_node = get_parent() if get_parent() else self
		_puddle_instance = SCENE_PUDDLE.instantiate()
		parent_node.add_child(_puddle_instance)
		var puddle_offset = transform.basis * Vector3(0.0, 0.005, 0.65)
		_puddle_instance.global_position = global_position + puddle_offset
		if _puddle_instance.has_method("set"):
			_puddle_instance.set("puddle_size", 0.25)
	else:
		var curr_size = _puddle_instance.get("puddle_size") if _puddle_instance.get("puddle_size") != null else 0.5
		_puddle_instance.set("puddle_size", minf(1.0, curr_size + delta * 0.08))

func is_door_open() -> bool:
	return current_state == State.OPEN

func interact(player: Node3D) -> void:
	var held = player.get("held_item") if player else null
	if current_state == State.OPEN and held != null and str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
		var box_item_id = str(held.get("contained_item_id"))
		var c_type = Cheese.CheeseType.CHEDDAR
		if box_item_id == "cheese_mozzarella": c_type = Cheese.CheeseType.MOZZARELLA
		elif box_item_id == "cheese_prato": c_type = Cheese.CheeseType.PRATO
		handle_slot_item_interaction(player, c_type)
		return
	toggle_lid(player)

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
	_target_hum_vol = -16.0

	if cold_mist:
		cold_mist.emitting = true

	if door_audio:
		door_audio.stream = SoundSynthesizer.get_stream("freezer_lid_open")
		door_audio.pitch_scale = randf_range(0.98, 1.02)
		if door_audio.is_inside_tree():
			door_audio.play()

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
		var pm = PowerManager.get_instance()
		if pm:
			pm.set_appliance_multiplier(self, 3.0)
		_set_slots_enabled(true)
		_update_all_visual_stocks()
		if player:
			_show_feedback(player, "🟢 Freezer aberto")
	)

func close_freezer(player: Node3D = null) -> void:
	if current_state == State.CLOSED or is_animating:
		return
	is_animating = true
	current_state = State.CLOSING
	_set_slots_enabled(false)
	_target_hum_vol = -28.0

	var pm = PowerManager.get_instance()
	if pm:
		pm.set_appliance_multiplier(self, 1.0)

	if cold_mist:
		cold_mist.emitting = false

	if door_audio:
		door_audio.stream = SoundSynthesizer.get_stream("freezer_lid_close")
		door_audio.pitch_scale = randf_range(0.98, 1.02)
		if door_audio.is_inside_tree():
			door_audio.play()

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
		if player:
			_show_feedback(player, "🔒 Freezer de queijos fechado")
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

	# Caso 1: Mão ocupada com objeto grande
	if player and player.has_method("is_holding_large_item") and player.is_holding_large_item():
		var held = player.get("held_item")
		if str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var box_item_id = str(held.get("contained_item_id"))
			var valid_cheeses = ["cheese_mozzarella", "cheese_cheddar", "cheese_prato"]
			if box_item_id == item_id or (box_item_id == "" and item_id in valid_cheeses):
				var qty: int = held.get("quantity") if held.get("quantity") != null else 10
				player.take_held_item().queue_free()
				inv.add_stock(item_id, qty)
				if door_audio:
					door_audio.stream = SoundSynthesizer.get_stream("box_place")
					door_audio.play()
				_show_feedback(player, "📦 %s armazenado no freezer (+%d un.)!" % [cheese_name, qty])
				_update_all_visual_stocks()
				return
			elif box_item_id in valid_cheeses:
				_show_feedback(player, "⚠️ Coloque esta caixa no compartimento de %s!" % str(held.get("contained_item_name")))
				return
			else:
				_show_feedback(player, "⚠️ Local incorreto! Esta caixa contém %s. Leve até a estação correta." % str(held.get("contained_item_name")))
				return
		else:
			_show_feedback(player, "⚠️ Mãos ocupadas com %s! Solte antes de pegar ingredientes." % (held.get_display_name() if held.has_method("get_display_name") else held.name))
			return

	# Caso 2: Retirada de queijo para os slots rápidos
	if player.has_method("has_empty_quick_slot") and not player.has_empty_quick_slot():
		_show_feedback(player, "⚠️ Slots rápidos cheios (3/3)! Use os ingredientes atuais antes de pegar outros.")
		return

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
	_show_feedback(player, "%s Pegou %s" % [icon, cheese_name])
	_update_all_visual_stocks()

# Clique Direito (RMB) — DEVOLVER 1 UNIDADE
func handle_slot_item_return(player: Node3D, cheese_type: Cheese.CheeseType) -> void:
	if current_state != State.OPEN:
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

	if player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient(item_id):
		var returned = player.return_one_matching_ingredient(item_id)
		if returned:
			inv.add_stock(item_id, 1)
			_show_feedback(player, "%s Devolveu 1x %s ao freezer" % [icon, cheese_name])
			_update_all_visual_stocks()
			return

	_show_feedback(player, "⚠️ Armazenamento incompatível! Este compartimento aceita apenas %s." % cheese_name)

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

	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock(item_id) if inv else 0
	var prompt = ""
	if stock <= 0:
		prompt = "🔴 %s Esgotado" % cheese_name
	else:
		prompt = "%s 🖱️ [Esq] Pegar %s (%d un.)" % [icon, cheese_name, stock]

	if player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient(item_id):
		prompt += " | 🖱️ [Dir] Devolver 1x"

	return prompt

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_all_visual_stocks()

func _update_all_visual_stocks() -> void:
	var inv = InventoryManager.get_instance()
	var moz_stock = inv.get_stock("cheese_mozzarella") if inv else 15
	var che_stock = inv.get_stock("cheese_cheddar")    if inv else 20
	var pra_stock = inv.get_stock("cheese_prato")      if inv else 15

	_update_section_visual(moz_stock, moz_full, moz_med, moz_low, 15, 6)
	_update_section_visual(che_stock, che_full, che_med, che_low, 15, 6)
	_update_section_visual(pra_stock, pra_full, pra_med, pra_low, 15, 6)

func _update_section_visual(
	stock_qty: int,
	node_full: Node3D,
	node_med: Node3D,
	node_low: Node3D,
	full_thresh: int = 15,
	med_thresh: int = 6
) -> void:
	if not node_full and not node_med and not node_low:
		return

	if stock_qty >= full_thresh:
		if node_full: node_full.visible = true
		if node_med: node_med.visible = false
		if node_low: node_low.visible = false
	elif stock_qty >= med_thresh:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = true
		if node_low: node_low.visible = false
	elif stock_qty > 0:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = false
		if node_low: node_low.visible = true
	else:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = false
		if node_low: node_low.visible = false

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
