class_name IngredientRefrigerator
extends Node3D

# ================================================================
# GELADEIRA VERTICAL DE HORTIFRÚTI & BATATAS COM ESTOQUE VISUAL
# Regra dos 3 Estágios: CHEIO | MÉDIO | BAIXO | ZERO
# Sem textos ou labels 3D flutuantes
#
# Quatro Andares de Armazenamento:
#  Andar 4 (Superior): Picles
#  Andar 3:            Cebola Roxa (Esq) │ Cebola Normal (Dir)
#  Andar 2:            Alface (Esq)      │ Tomate (Dir)
#  Andar 1 (Inferior): Sacos de Batata Frita Congelada
#
# Regras de Interação:
#  - Tecla [E]                -> Abrir / Fechar a porta de vidro
#  - Clique Esquerdo do Mouse -> Pegar / Devolver ingredientes nas prateleiras
# ================================================================

const DOOR_OPEN_ANGLE_DEG: float = -85.0
const PowerManager = preload("res://src/core/power_manager.gd")
const DOOR_CLOSE_ANGLE_DEG: float = 0.0
const DOOR_ANIM_SECS: float = 0.42

var is_open: bool = false
var is_animating: bool = false
var _open_duration: float = 0.0
var _puddle_instance: Node3D = null

const SCENE_PUDDLE = preload("res://src/stations/floor_puddle.tscn")

@onready var door_pivot: Node3D = get_node_or_null("DoorPivot")
@onready var interior_light: OmniLight3D = get_node_or_null("InteriorLight")
@onready var cold_mist: CPUParticles3D = get_node_or_null("ColdMistParticles")

@onready var col_potato: CollisionShape3D = get_node_or_null("PotatoSlot/CollisionShape3D")
@onready var col_lettuce: CollisionShape3D = get_node_or_null("LettuceSlot/CollisionShape3D")
@onready var col_tomato: CollisionShape3D = get_node_or_null("TomatoSlot/CollisionShape3D")
@onready var col_red_onion: CollisionShape3D = get_node_or_null("RedOnionSlot/CollisionShape3D")
@onready var col_white_onion: CollisionShape3D = get_node_or_null("WhiteOnionSlot/CollisionShape3D")
@onready var col_pickle: CollisionShape3D = get_node_or_null("PickleSlot/CollisionShape3D")

# Nós de Estoque Visual Dinâmico (3 Estágios)
@onready var potato_full: Node3D = get_node_or_null("FridgeBody/Products/PotatoBagsGroup/Full")
@onready var potato_med: Node3D = get_node_or_null("FridgeBody/Products/PotatoBagsGroup/Medium")
@onready var potato_low: Node3D = get_node_or_null("FridgeBody/Products/PotatoBagsGroup/Low")

@onready var lettuce_full: Node3D = get_node_or_null("FridgeBody/Products/LettuceGroup/Full")
@onready var lettuce_med: Node3D = get_node_or_null("FridgeBody/Products/LettuceGroup/Medium")
@onready var lettuce_low: Node3D = get_node_or_null("FridgeBody/Products/LettuceGroup/Low")

@onready var tomato_full: Node3D = get_node_or_null("FridgeBody/Products/TomatoGroup/Full")
@onready var tomato_med: Node3D = get_node_or_null("FridgeBody/Products/TomatoGroup/Medium")
@onready var tomato_low: Node3D = get_node_or_null("FridgeBody/Products/TomatoGroup/Low")

@onready var red_onion_full: Node3D = get_node_or_null("FridgeBody/Products/RedOnionGroup/Full")
@onready var red_onion_med: Node3D = get_node_or_null("FridgeBody/Products/RedOnionGroup/Medium")
@onready var red_onion_low: Node3D = get_node_or_null("FridgeBody/Products/RedOnionGroup/Low")

@onready var white_onion_full: Node3D = get_node_or_null("FridgeBody/Products/WhiteOnionGroup/Full")
@onready var white_onion_med: Node3D = get_node_or_null("FridgeBody/Products/WhiteOnionGroup/Medium")
@onready var white_onion_low: Node3D = get_node_or_null("FridgeBody/Products/WhiteOnionGroup/Low")

@onready var pickle_full: Node3D = get_node_or_null("FridgeBody/Products/PickleGroup/Full")
@onready var pickle_med: Node3D = get_node_or_null("FridgeBody/Products/PickleGroup/Medium")
@onready var pickle_low: Node3D = get_node_or_null("FridgeBody/Products/PickleGroup/Low")

var door_audio: AudioStreamPlayer3D = null
var hum_audio: AudioStreamPlayer3D = null
var _target_hum_vol: float = -28.0

func _enter_tree() -> void:
	_setup_audio()

func _ready() -> void:
	_setup_audio()
	_set_slots_enabled(false)
	if interior_light:
		interior_light.light_energy = 0.4

	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "veg_refrigerator", "Geladeira de Hortifrúti", 1.0, true)
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
			interior_light.light_energy = 1.2 if is_open else 0.4
		if cold_mist and is_open:
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
		hum_audio.stream = SoundSynthesizer.get_stream("fridge_hum_loop")
		add_child(hum_audio)
	if hum_audio.is_inside_tree() and not hum_audio.playing:
		hum_audio.play()

func _process(delta: float) -> void:
	if hum_audio:
		if is_inside_tree() and not hum_audio.playing:
			hum_audio.play()
		var w = 1.0 - exp(-6.0 * delta)
		hum_audio.volume_db = lerpf(hum_audio.volume_db, _target_hum_vol, w)

	# Efeito de perda de frio e formação de poça quando aberta por tempo suficiente
	if is_open:
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
		var puddle_offset = transform.basis * Vector3(0.0, 0.005, 0.70)
		_puddle_instance.global_position = global_position + puddle_offset
		if _puddle_instance.has_method("set"):
			_puddle_instance.set("puddle_size", 0.25)
	else:
		var curr_size = _puddle_instance.get("puddle_size") if _puddle_instance.get("puddle_size") != null else 0.5
		_puddle_instance.set("puddle_size", minf(1.0, curr_size + delta * 0.08))

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
	_target_hum_vol = -16.0

	if cold_mist:
		cold_mist.emitting = true

	if door_audio:
		door_audio.stream = SoundSynthesizer.get_stream("fridge_door_open")
		door_audio.pitch_scale = randf_range(0.98, 1.02)
		if door_audio.is_inside_tree():
			door_audio.play()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if door_pivot:
		tween.tween_property(door_pivot, "rotation_degrees:y", DOOR_OPEN_ANGLE_DEG, DOOR_ANIM_SECS)
	if interior_light:
		tween.tween_property(interior_light, "light_energy", 1.2, DOOR_ANIM_SECS)

	tween.finished.connect(func():
		is_open = true
		is_animating = false
		var pm = PowerManager.get_instance()
		if pm:
			pm.set_appliance_multiplier(self, 3.0)
		_set_slots_enabled(true)
		_update_all_visual_stocks()
		if player:
			_show_feedback(player, "🟢 Geladeira de hortifrúti aberta")
	)

func close_door(player: Node3D = null) -> void:
	if not is_open or is_animating:
		return
	is_animating = true
	_set_slots_enabled(false)
	_target_hum_vol = -28.0

	var pm = PowerManager.get_instance()
	if pm:
		pm.set_appliance_multiplier(self, 1.0)

	if cold_mist:
		cold_mist.emitting = false

	if door_audio:
		door_audio.stream = SoundSynthesizer.get_stream("fridge_door_close")
		door_audio.pitch_scale = randf_range(0.98, 1.02)
		if door_audio.is_inside_tree():
			door_audio.play()

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
		if player:
			_show_feedback(player, "🔒 Geladeira de hortifrúti fechada")
	)

func _apply_state_instant(open_state: bool) -> void:
	is_open = open_state
	is_animating = false
	if door_pivot:
		door_pivot.rotation_degrees.y = DOOR_OPEN_ANGLE_DEG if is_open else DOOR_CLOSE_ANGLE_DEG
	if interior_light:
		interior_light.light_energy = 1.2 if is_open else 0.4
	_set_slots_enabled(is_open)

func _set_slots_enabled(enabled: bool) -> void:
	if col_potato: col_potato.disabled = not enabled
	if col_lettuce: col_lettuce.disabled = not enabled
	if col_tomato: col_tomato.disabled = not enabled
	if col_red_onion: col_red_onion.disabled = not enabled
	if col_white_onion: col_white_onion.disabled = not enabled
	if col_pickle: col_pickle.disabled = not enabled

# ─── Manipulação de Ingredientes (Clique do Mouse) ─────────────
func get_ingredient_prompt(player: Node, ing_id: String) -> String:
	if not is_open:
		return ""

	var inv = InventoryManager.get_instance()
	var ing_info = _get_ingredient_info(ing_id)
	var ing_name = ing_info.name
	var icon = ing_info.icon

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if _is_matching_ingredient(held, ing_id):
			return "%s 🖱️ Devolver %s" % [icon, ing_name]
		return ""

	var stock = inv.get_stock(ing_id) if inv else 0
	if stock <= 0:
		return "🔴 %s Esgotado" % ing_name

	return "%s 🖱️ Pegar %s" % [icon, ing_name]

func handle_ingredient_interaction(player: Node3D, ing_id: String) -> void:
	if not is_open:
		_show_feedback(player, "Abra a porta da geladeira primeiro com [E]!")
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var ing_info = _get_ingredient_info(ing_id)
	var ing_name = ing_info.name
	var icon = ing_info.icon

	# Caso 1: Jogador segurando um item -> Devolução
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if _is_matching_ingredient(held, ing_id):
			player.take_held_item().queue_free()
			inv.add_stock(ing_id, 1)
			_show_feedback(player, "%s Devolveu %s à geladeira" % [icon, ing_name])
			_update_all_visual_stocks()
		elif str(held.get("item_type")) == "crate" or str(held.get("item_type")) == "storage_box":
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			player.take_held_item().queue_free()
			inv.add_stock(ing_id, qty)
			_show_feedback(player, "📦 %s armazenado (+%d un.)!" % [ing_name, qty])
			_update_all_visual_stocks()
		else:
			_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# Caso 2: Jogador com as mãos livres -> Retirada
	if not inv.has_stock(ing_id, 1):
		_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % ing_name)
		return

	inv.consume_stock(ing_id, 1)
	var item_node = _instantiate_ingredient_item(ing_id)

	if is_inside_tree() and get_tree() and get_tree().root:
		get_tree().root.add_child(item_node)
	elif player.get_parent():
		player.get_parent().add_child(item_node)
	else:
		add_child(item_node)

	if item_node.has_method("_ready"):
		item_node._ready()

	if player.has_method("pick_up"):
		player.pick_up(item_node)

	_show_feedback(player, "%s Pegou %s" % [icon, ing_name])
	_update_all_visual_stocks()

func _instantiate_ingredient_item(ing_id: String) -> Node3D:
	match ing_id:
		"potato_raw":
			var sc = load("res://src/items/potato.tscn")
			var pot = sc.instantiate() as Potato
			pot.state = Potato.State.RAW
			return pot
		"lettuce":
			var sc = load("res://src/items/lettuce.tscn")
			return sc.instantiate()
		"tomato":
			var sc = load("res://src/items/tomato.tscn")
			return sc.instantiate()
		"red_onion":
			var sc = load("res://src/items/onion.tscn")
			var on = sc.instantiate() as Onion
			on.onion_type = Onion.OnionType.RED
			return on
		"onion":
			var sc = load("res://src/items/onion.tscn")
			var on = sc.instantiate() as Onion
			on.onion_type = Onion.OnionType.NORMAL
			return on
		"pickle":
			var sc = load("res://src/items/pickle.tscn")
			return sc.instantiate()
		_:
			var sc = load("res://src/items/lettuce.tscn")
			return sc.instantiate()

func _is_matching_ingredient(held: Node3D, ing_id: String) -> bool:
	if not held:
		return false
	var held_id = str(held.get("item_id"))

	match ing_id:
		"potato_raw":
			if held is Potato:
				return held.state == Potato.State.RAW
			return held_id == "potato_raw" or held_id == "potato"
		"lettuce":
			return held is Lettuce or held_id == "lettuce"
		"tomato":
			return held is Tomato or held_id == "tomato"
		"red_onion":
			if held is Onion:
				return held.onion_type == Onion.OnionType.RED
			return held_id == "red_onion"
		"onion":
			if held is Onion:
				return held.onion_type == Onion.OnionType.NORMAL
			return held_id == "onion"
		"pickle":
			return held is Pickle or held_id == "pickle"
		_:
			return held_id == ing_id

func _get_ingredient_info(ing_id: String) -> Dictionary:
	match ing_id:
		"potato_raw":
			return {"name": "Saco de Batata Frita", "icon": "🍟"}
		"lettuce":
			return {"name": "Alface", "icon": "🥬"}
		"tomato":
			return {"name": "Tomate", "icon": "🍅"}
		"red_onion":
			return {"name": "Cebola Roxa", "icon": "🧅"}
		"onion":
			return {"name": "Cebola Normal", "icon": "🧅"}
		"pickle":
			return {"name": "Picles", "icon": "🥒"}
		_:
			return {"name": "Ingrediente", "icon": "🥗"}

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_all_visual_stocks()

func _update_all_visual_stocks() -> void:
	var inv = InventoryManager.get_instance()
	var pot_stock = inv.get_stock("potato_raw") if inv else 25
	var let_stock = inv.get_stock("lettuce")    if inv else 15
	var tom_stock = inv.get_stock("tomato")     if inv else 15
	var red_stock = inv.get_stock("red_onion")  if inv else 15
	var oni_stock = inv.get_stock("onion")      if inv else 15
	var pic_stock = inv.get_stock("pickle")     if inv else 15

	_update_section_visual(pot_stock, potato_full, potato_med, potato_low, 20, 8)
	_update_section_visual(let_stock, lettuce_full, lettuce_med, lettuce_low, 15, 6)
	_update_section_visual(tom_stock, tomato_full, tomato_med, tomato_low, 15, 6)
	_update_section_visual(red_stock, red_onion_full, red_onion_med, red_onion_low, 15, 6)
	_update_section_visual(oni_stock, white_onion_full, white_onion_med, white_onion_low, 15, 6)
	_update_section_visual(pic_stock, pickle_full, pickle_med, pickle_low, 15, 6)

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
