class_name MeatRefrigerator
extends Node3D

# ================================================================
# GELADEIRA COMERCIAL DE CARNES COM ESTOQUE VISUAL DINÂMICO
# Regra dos 3 Estágios: CHEIO | MÉDIO | BAIXO | ZERO
# Sem textos ou labels 3D flutuantes
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
var _open_duration: float = 0.0
var _puddle_instance: Node3D = null

const SCENE_PUDDLE = preload("res://src/stations/floor_puddle.tscn")
const PowerManager = preload("res://src/core/power_manager.gd")

@onready var door_pivot: Node3D = get_node_or_null("DoorPivot")
@onready var cold_mist: CPUParticles3D = get_node_or_null("ColdMistParticles")
@onready var beef_slot_col: CollisionShape3D = get_node_or_null("BeefSlot/CollisionShape3D")
@onready var chicken_slot_col: CollisionShape3D = get_node_or_null("ChickenSlot/CollisionShape3D")
@onready var interior_light: OmniLight3D = get_node_or_null("InteriorLight")

# Grupos de alimentos visuais (3 Estágios)
@onready var beef_full: Node3D = get_node_or_null("FridgeBody/BeefFoodGroup/Full")
@onready var beef_med: Node3D = get_node_or_null("FridgeBody/BeefFoodGroup/Medium")
@onready var beef_low: Node3D = get_node_or_null("FridgeBody/BeefFoodGroup/Low")

@onready var chicken_full: Node3D = get_node_or_null("FridgeBody/ChickenFoodGroup/Full")
@onready var chicken_med: Node3D = get_node_or_null("FridgeBody/ChickenFoodGroup/Medium")
@onready var chicken_low: Node3D = get_node_or_null("FridgeBody/ChickenFoodGroup/Low")

var door_audio: AudioStreamPlayer3D = null
var hum_audio: AudioStreamPlayer3D = null
var _target_hum_vol: float = -28.0

func _enter_tree() -> void:
	_setup_audio()

func _ready() -> void:
	_setup_audio()
	# Inicialmente porta fechada → slots desabilitados
	_set_slots_enabled(false)
	if interior_light:
		interior_light.light_energy = 0.4

	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "meat_refrigerator", "Geladeira de Carnes", 1.0, true)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)

	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)

	_update_patty_visuals()

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
			interior_light.light_energy = 1.0 if is_open else 0.4
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
		tween.tween_property(interior_light, "light_energy", 1.0, DOOR_ANIM_SECS)

	tween.finished.connect(func():
		is_open = true
		is_animating = false
		var pm = PowerManager.get_instance()
		if pm:
			pm.set_appliance_multiplier(self, 3.0)
		_set_slots_enabled(true)
		if player:
			_show_feedback(player, "🟢 Geladeira aberta")
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
			_show_feedback(player, "🔒 Geladeira fechada")
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

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var d_name = "Hambúrguer de Carne" if meat_id == "patty_beef" else "Hambúrguer de Frango"
	var icon = "🥩" if meat_id == "patty_beef" else "🍗"

	# Caso 1: Devolução de carne segurada na mão
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty:
			var matches = (meat_id == "patty_chicken" and held.meat_type == Patty.MeatType.CHICKEN) or (meat_id == "patty_beef" and held.meat_type == Patty.MeatType.BEEF)
			if matches:
				var ret_p = player.take_held_item()
				if ret_p:
					ret_p.queue_free()
				inv.add_stock(meat_id, 1)
				_show_feedback(player, "%s Devolveu %s à geladeira" % [icon, d_name])
				_update_patty_visuals()
				return
		elif player.has_method("is_holding_large_item") and player.is_holding_large_item():
			if str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
				var box_item_id = str(held.get("contained_item_id"))
				var valid_meats = ["patty_beef", "patty_chicken"]
				if box_item_id == meat_id or (box_item_id == "" and meat_id in valid_meats):
					var qty: int = held.get("quantity") if held.get("quantity") != null else 10
					player.take_held_item().queue_free()
					inv.add_stock(meat_id, qty)
					if door_audio:
						door_audio.stream = SoundSynthesizer.get_stream("box_place")
						door_audio.play()
					_show_feedback(player, "📦 %s armazenado na geladeira (+%d un.)!" % [d_name, qty])
					_update_patty_visuals()
					return
				elif box_item_id in valid_meats:
					_show_feedback(player, "⚠️ Coloque esta caixa no compartimento de %s!" % str(held.get("contained_item_name")))
					return
				else:
					_show_feedback(player, "⚠️ Local incorreto! Esta caixa contém %s. Leve até a estação correta." % str(held.get("contained_item_name")))
					return
			else:
				_show_feedback(player, "Mãos ocupadas com objeto grande! Solte antes de pegar ingredientes.")
				return

	# Caso 2: Retirada de carne para a mão / slots rápidos
	if player.has_method("can_take_ingredient") and not player.can_take_ingredient(meat_id):
		_show_feedback(player, "⚠️ Slots rápidos cheios (3/3)! Use os ingredientes atuais antes de pegar outros.")
		return

	# Caso 2: Jogador com as mãos livres -> Pegar carne
	if not inv.has_stock(meat_id, 1):
		_show_feedback(player, "❌ Sem %s! Compre no Computador." % d_name)
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

	_show_feedback(player, "%s Pegou %s" % [icon, d_name])
	_update_patty_visuals()

# ─── Helpers e Atualizações ────────────────────────────────────
func _set_slots_enabled(enabled: bool) -> void:
	if beef_slot_col:
		beef_slot_col.disabled = not enabled
	if chicken_slot_col:
		chicken_slot_col.disabled = not enabled

func _on_stock_changed(_id: String, _qty: int) -> void:
	_update_patty_visuals()

func _update_patty_visuals() -> void:
	var inv = InventoryManager.get_instance()
	var beef_stock  = inv.get_stock("patty_beef")    if inv else 20
	var chick_stock = inv.get_stock("patty_chicken") if inv else 15

	_update_section_visual(beef_stock, beef_full, beef_med, beef_low, 15, 6)
	_update_section_visual(chick_stock, chicken_full, chicken_med, chicken_low, 15, 6)

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

func _show_feedback(player: Node3D, msg: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(msg)
