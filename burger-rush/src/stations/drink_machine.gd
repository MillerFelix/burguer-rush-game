class_name DrinkMachine
extends StaticBody3D

# ================================================================
# MÁQUINA PROFISSIONAL DE BEBIDAS / REFRIGERANTES
#
# Recursos Refatorados:
#  - 4 Sabores Comerciais com Logos Próprios: Cola, Cola Zero, Limão, Laranja
#  - 2 Portas Inferiores Independentes com Dobradiças Reais (Esq/Dir)
#  - 4 Estações Independentes com Bicos Salientes, Alavancas Físicas e Barras LED
#  - 4 Espaços/Slots Individuais para Copos na Bandeja de Pingos
#  - Jatos Líquidos 3D Visíveis Sincronizados com as Alavancas
#  - Botão Power de Ligar/Desligar com LED Indicador de Funcionamento
#  - Interior Técnico com Manifold e Acesso Visual aos Barris
#  - 4 Recipientes/Galões de Insumo Extraíveis e Substituíveis
# ================================================================

enum TargetType {
	NONE,
	POWER_SWITCH,
	LEFT_DOOR,
	RIGHT_DOOR,
	LEVER,
	CUP_SLOT,
	CANISTER_SLOT
}

const FLAVORS = [
	{
		"id": "soda_cola",
		"name": "COLA",
		"canister_id": "syrup_cola",
		"color": Color(0.12, 0.05, 0.03, 1.0)
	},
	{
		"id": "soda_cola_zero",
		"name": "ZERO",
		"canister_id": "syrup_cola_zero",
		"color": Color(0.06, 0.06, 0.08, 1.0)
	},
	{
		"id": "soda_lime",
		"name": "SODA",
		"canister_id": "syrup_lemon",
		"color": Color(0.75, 0.95, 0.65, 0.9)
	},
	{
		"id": "soda_citrus",
		"name": "CITRUS",
		"canister_id": "syrup_orange",
		"color": Color(0.95, 0.55, 0.08, 1.0)
	}
]

const PowerManager = preload("res://src/core/power_manager.gd")

# Compatibilidade para código legado
var available_flavors: Array[String] = [
	"soda_cola",
	"soda_cola_zero",
	"soda_lime",
	"soda_citrus"
]
var current_flavor_index: int = 0
var syrup_capacity: int = 25
const MAX_DOSES_PER_CANISTER: float = 25.0
const CONSUMPTION_PER_CUP: float = 1.0 # 1 dose consumida por copo servido -> 25 doses por galão
var syrup_current: int = 25:
	get:
		return int(syrup_levels[current_flavor_index])
	set(val):
		syrup_levels[current_flavor_index] = float(val)
		_update_all_visuals()

# Estado Geral da Máquina
@export var is_powered: bool = true

# Duas Portas Inferiores Independentes com Dobradiças Reais
@export var is_left_door_open: bool = false
@export var is_right_door_open: bool = false
var is_door_open: bool:
	get:
		return is_left_door_open or is_right_door_open
	set(val):
		is_left_door_open = val
		is_right_door_open = val

# 4 Estações Independentes
var is_lever_down: Array[bool] = [false, false, false, false]
var current_cups: Array[DrinkCup] = [null, null, null, null]
var fill_progresses: Array[float] = [0.0, 0.0, 0.0, 0.0]
var syrup_levels: Array[float] = [25.0, 25.0, 25.0, 25.0]
var canisters: Array[SyrupCanister] = [null, null, null, null]

const FILL_DURATION: float = 0.85 # segundos para encher 100%

const SyrupCanister = preload("res://src/items/syrup_canister.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const WaterManager = preload("res://src/core/water_manager.gd")
var SYRUP_CANISTER_SCENE = load("res://src/items/syrup_canister.tscn")

# Nós de Interface 3D
@onready var power_led: MeshInstance3D = get_node_or_null("Model/PowerSwitch/StatusLED")
@onready var left_door_hinge: Node3D = get_node_or_null("Model/LeftDoorHinge")
@onready var right_door_hinge: Node3D = get_node_or_null("Model/RightDoorHinge")
@onready var cup_slot: Node3D = get_node_or_null("CupSlot_0") # Compatibilidade legada

# Nós de Áudio 3D Posicional
@onready var hum_audio: AudioStreamPlayer3D = get_node_or_null("Audio/HumAudioPlayer")
@onready var dispense_audio: AudioStreamPlayer3D = get_node_or_null("Audio/DispenseAudioPlayer")
@onready var oneshot_audio: AudioStreamPlayer3D = get_node_or_null("Audio/OneShotAudioPlayer")

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

var _target_hum_vol: float = -80.0
var _target_dispense_vol: float = -80.0

var door_hinge: Node3D:
	get:
		return left_door_hinge if left_door_hinge else get_node_or_null("Model/LeftDoorHinge")

var current_cup: DrinkCup:
	get:
		return current_cups[current_flavor_index]
	set(val):
		current_cups[current_flavor_index] = val
		if val and is_instance_valid(val):
			val.set_flavor(FLAVORS[current_flavor_index].id)
var is_filling: bool:
	get:
		return is_lever_down[current_flavor_index]
	set(val):
		is_lever_down[current_flavor_index] = val
var fill_progress: float:
	get:
		return fill_progresses[current_flavor_index]
	set(val):
		fill_progresses[current_flavor_index] = val

func _ready() -> void:
	_setup_audio()
	_init_canisters()
	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "drink_machine", "Máquina de Refrigerantes", 0.85, is_powered)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)
	_update_all_visuals()

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func on_power_state_changed(main_power_on: bool) -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.set_appliance_state(self, is_powered and main_power_on)
	_update_all_visuals()

func _setup_audio() -> void:
	if not hum_audio:
		hum_audio = get_node_or_null("Audio/HumAudioPlayer")
	if not dispense_audio:
		dispense_audio = get_node_or_null("Audio/DispenseAudioPlayer")
	if not oneshot_audio:
		oneshot_audio = get_node_or_null("Audio/OneShotAudioPlayer")

	if not hum_audio:
		var audio_root = get_node_or_null("Audio")
		if not audio_root:
			audio_root = Node3D.new()
			audio_root.name = "Audio"
			audio_root.position = Vector3(0, 0.95, 0.1)
			add_child(audio_root)

		hum_audio = AudioStreamPlayer3D.new()
		hum_audio.name = "HumAudioPlayer"
		hum_audio.unit_size = 2.8
		hum_audio.max_distance = 18.0
		audio_root.add_child(hum_audio)

		dispense_audio = AudioStreamPlayer3D.new()
		dispense_audio.name = "DispenseAudioPlayer"
		dispense_audio.unit_size = 2.8
		dispense_audio.max_distance = 18.0
		audio_root.add_child(dispense_audio)

		oneshot_audio = AudioStreamPlayer3D.new()
		oneshot_audio.name = "OneShotAudioPlayer"
		oneshot_audio.unit_size = 2.8
		oneshot_audio.max_distance = 18.0
		audio_root.add_child(oneshot_audio)

	hum_audio.volume_db = -80.0
	dispense_audio.volume_db = -80.0

func _safe_play(player: AudioStreamPlayer3D) -> void:
	if player and player.is_inside_tree():
		player.play()

func _play_oneshot(sound_id: String, vol_db: float = -6.0) -> void:
	if not oneshot_audio:
		_setup_audio()
	if oneshot_audio:
		oneshot_audio.stream = SoundSynthesizer.get_stream(sound_id)
		oneshot_audio.volume_db = vol_db
		_safe_play(oneshot_audio)

func _init_canisters() -> void:
	for i in range(4):
		var slot_node = get_node_or_null("CanisterSlot_%d" % i)
		if slot_node and slot_node.get_child_count() > 0:
			var child = slot_node.get_child(0)
			if child is SyrupCanister:
				canisters[i] = child
				syrup_levels[i] = child.current_amount
		else:
			syrup_levels[i] = 100.0

func _process(delta: float) -> void:
	# Animação suave e independente das duas portas inferiores nas dobradiças
	if left_door_hinge:
		var target_left_y = deg_to_rad(-95.0) if is_left_door_open else 0.0
		left_door_hinge.rotation.y = move_toward(left_door_hinge.rotation.y, target_left_y, 4.0 * delta)

	if right_door_hinge:
		var target_right_y = deg_to_rad(95.0) if is_right_door_open else 0.0
		right_door_hinge.rotation.y = move_toward(right_door_hinge.rotation.y, target_right_y, 4.0 * delta)

	# Atualização das 4 estações independentes de enchimento
	for i in range(4):
		_process_station_dispense(i, delta)

	_process_audio(delta)
	_update_all_visuals()

func _process_audio(delta: float) -> void:
	if not hum_audio or not dispense_audio:
		_setup_audio()

	# 1. Zumbido sutil do compressor/refrigeração
	if is_powered:
		if not hum_audio.playing:
			hum_audio.stream = SoundSynthesizer.get_stream("soda_fridge_loop")
			_safe_play(hum_audio)
		_target_hum_vol = -28.0
	else:
		_target_hum_vol = -80.0

	var w_hum = 1.0 - exp(-6.0 * delta)
	hum_audio.volume_db = lerpf(hum_audio.volume_db, _target_hum_vol, w_hum)
	if not is_powered and hum_audio.volume_db <= -60.0 and hum_audio.playing:
		hum_audio.stop()

	# 2. Fluxo contínuo de refrigerante com gás
	var any_dispensing = false
	if is_powered:
		for i in range(4):
			if is_lever_down[i] and syrup_levels[i] > 0.0:
				any_dispensing = true
				break

	if any_dispensing:
		if not dispense_audio.playing:
			dispense_audio.stream = SoundSynthesizer.get_stream("soda_dispense_loop")
			_safe_play(dispense_audio)
		_target_dispense_vol = -17.0
	else:
		_target_dispense_vol = -80.0

	var w_disp = 1.0 - exp(-10.0 * delta)
	dispense_audio.volume_db = lerpf(dispense_audio.volume_db, _target_dispense_vol, w_disp)
	if not any_dispensing and dispense_audio.volume_db <= -60.0 and dispense_audio.playing:
		dispense_audio.stop()

func _process_station_dispense(idx: int, delta: float) -> void:
	var lever_pivot = get_node_or_null("Model/LeverPivot_%d" % idx)
	var stream_mesh = get_node_or_null("Model/Stream_%d" % idx)

	# Movimento angular nítido da alavanca ao acionar
	if lever_pivot:
		var target_rot_x = deg_to_rad(-30.0) if is_lever_down[idx] else 0.0
		lever_pivot.rotation.x = move_toward(lever_pivot.rotation.x, target_rot_x, 8.0 * delta)

	if is_lever_down[idx]:
		var cup = current_cups[idx]
		if not is_powered or syrup_levels[idx] <= 0.0 or not is_instance_valid(cup) or cup.state == DrinkCup.State.FILLED:
			stop_pouring(idx)
			return

		if stream_mesh:
			stream_mesh.visible = true

		# Progresso de enchimento e consumo de insumo do galão correspondente
		var prev_fill = fill_progresses[idx]
		var rate = 1.0 / FILL_DURATION
		var next_fill = minf(1.0, prev_fill + rate * delta)
		fill_progresses[idx] = next_fill
		var fill_step = next_fill - prev_fill
		var consumed = fill_step * CONSUMPTION_PER_CUP
		syrup_levels[idx] = maxf(0.0, syrup_levels[idx] - consumed)

		var wm = WaterManager.get_instance()
		if wm and fill_step > 0.0:
			wm.consume_water(fill_step * 0.35, "drink_machine")

		if canisters[idx] and is_instance_valid(canisters[idx]):
			canisters[idx].current_amount = syrup_levels[idx]

		cup.fill_amount = fill_progresses[idx]
		cup.set_flavor(FLAVORS[idx].id)
		cup._update_visuals()

		# Copo cheio (100%) -> cessa fluxo automaticamente e sobe alavanca
		if fill_progresses[idx] >= 1.0:
			cup.set_state(DrinkCup.State.FILLED)
			stop_pouring(idx)
	else:
		if stream_mesh:
			stream_mesh.visible = false

# Liga / Desliga a máquina no botão Power
func toggle_power(worker: Node3D = null) -> void:
	is_powered = !is_powered
	if not is_powered:
		_play_oneshot("soda_switch_off", -6.0)
		for i in range(4):
			stop_pouring(i)
	else:
		_play_oneshot("soda_switch_on", -6.0)

	if worker:
		var msg = "⚡ Máquina de Bebidas LIGADA (Refrigeração Ativa)" if is_powered else "⚡ Máquina de Bebidas DESLIGADA"
		_show_feedback(worker, msg)
	_update_all_visuals()

# Abre / Fecha a porta esquerda (acesso a Cola e Cola Zero)
func toggle_left_door(worker: Node3D = null) -> void:
	is_left_door_open = !is_left_door_open
	_play_oneshot("soda_door_open" if is_left_door_open else "soda_door_close", -5.0)
	if worker:
		var msg = "🚪 Porta Esquerda ABERTA (Cola / Cola Zero)" if is_left_door_open else "🚪 Porta Esquerda FECHADA"
		_show_feedback(worker, msg)

# Abre / Fecha a porta direita (acesso a Limão e Laranja)
func toggle_right_door(worker: Node3D = null) -> void:
	is_right_door_open = !is_right_door_open
	_play_oneshot("soda_door_open" if is_right_door_open else "soda_door_close", -5.0)
	if worker:
		var msg = "🚪 Porta Direita ABERTA (Limão / Laranja)" if is_right_door_open else "🚪 Porta Direita FECHADA"
		_show_feedback(worker, msg)

func toggle_door(worker: Node3D = null) -> void:
	# Toggles ambas para compatibilidade de testes gerais
	if is_door_open:
		is_left_door_open = false
		is_right_door_open = false
		_play_oneshot("soda_door_close", -5.0)
	else:
		is_left_door_open = true
		is_right_door_open = true
		_play_oneshot("soda_door_open", -5.0)
	if worker:
		_show_feedback(worker, "🚪 Portas %s" % ("ABERTAS" if is_door_open else "FECHADAS"))

# Aciona ou interrompe a alavanca da estação
func toggle_lever(idx: int, worker: Node3D = null) -> void:
	if idx < 0 or idx >= 4:
		return

	if is_lever_down[idx]:
		stop_pouring(idx)
		if worker:
			_show_feedback(worker, "⏹️ Fluxo de %s interrompido" % FLAVORS[idx].name)
		return

	if not is_powered:
		if worker:
			_show_feedback(worker, "⚠️ Ligue a máquina no botão Power antes de servir.")
		return

	if syrup_levels[idx] <= 0.0:
		if worker:
			_show_feedback(worker, "🔴 Sem xarope de %s! Troque o galão no compartimento inferior." % FLAVORS[idx].name)
		return

	var cup = current_cups[idx]
	if not cup or not is_instance_valid(cup):
		if worker:
			_show_feedback(worker, "⚠️ Posicione um copo no espaço de %s antes de abaixar a alavanca." % FLAVORS[idx].name)
		return

	if cup.fill_amount >= 1.0 or cup.state == DrinkCup.State.FILLED or cup.state == DrinkCup.State.CLOSED:
		if worker:
			_show_feedback(worker, "✨ Copo já está cheio!")
		return

	start_pouring(idx)
	if worker:
		_show_feedback(worker, "🥤 Servindo %s..." % FLAVORS[idx].name)

func start_pouring(idx: int) -> void:
	if idx < 0 or idx >= 4:
		return
	is_lever_down[idx] = true
	_play_oneshot("soda_lever_pull", -6.0)
	var cup = current_cups[idx]
	if cup and is_instance_valid(cup):
		cup.set_flavor(FLAVORS[idx].id)
	var stream_mesh = get_node_or_null("Model/Stream_%d" % idx)
	if stream_mesh:
		stream_mesh.visible = true

func stop_pouring(idx: int) -> void:
	if idx < 0 or idx >= 4:
		return
	if is_lever_down[idx]:
		_play_oneshot("soda_lever_release", -6.0)
	is_lever_down[idx] = false
	var stream_mesh = get_node_or_null("Model/Stream_%d" % idx)
	if stream_mesh:
		stream_mesh.visible = false

# Coloca um copo na posição correspondente
func place_cup_in_slot(idx: int, cup: DrinkCup, worker: Node3D = null) -> bool:
	if idx < 0 or idx >= 4 or not cup:
		return false
	if current_cups[idx] != null and is_instance_valid(current_cups[idx]):
		if worker:
			_show_feedback(worker, "⚠️ Já existe um copo na posição de %s." % FLAVORS[idx].name)
		return false

	var prev_parent = cup.get_parent()
	if prev_parent:
		prev_parent.remove_child(cup)

	var slot_node = get_node_or_null("CupSlot_%d" % idx)
	if slot_node:
		slot_node.add_child(cup)
	else:
		add_child(cup)

	cup.position = Vector3.ZERO
	cup.rotation = Vector3.ZERO
	current_cups[idx] = cup
	fill_progresses[idx] = cup.fill_amount

	if cup.has_method("on_placed_in_station"):
		cup.on_placed_in_station()

	_play_oneshot("soda_cup_place", -6.0)

	if worker:
		_show_feedback(worker, "🥤 Copo posicionado no bico de %s" % FLAVORS[idx].name)
	_update_all_visuals()
	return true

# Retira o copo da posição correspondente
func take_cup_from_slot(idx: int, player: Node3D) -> DrinkCup:
	if idx < 0 or idx >= 4:
		return null
	var cup = current_cups[idx]
	if not cup or not is_instance_valid(cup):
		return null

	stop_pouring(idx)
	current_cups[idx] = null
	fill_progresses[idx] = 0.0

	var slot_node = get_node_or_null("CupSlot_%d" % idx)
	if slot_node and cup.get_parent() == slot_node:
		slot_node.remove_child(cup)
	elif cup.get_parent():
		cup.get_parent().remove_child(cup)

	if player and player.has_method("pick_up"):
		player.pick_up(cup)

	_play_oneshot("soda_cup_remove", -6.0)

	_show_feedback(player, "🥤 %s retirado da máquina!" % cup.get_flavor_display_name())
	_update_all_visuals()
	return cup

# Retira um galão de insumo do compartimento
func remove_canister(idx: int, player: Node3D) -> SyrupCanister:
	if idx < 0 or idx >= 4:
		return null
	var can = canisters[idx]
	if not can or not is_instance_valid(can):
		return null

	canisters[idx] = null
	syrup_levels[idx] = 0.0

	var slot_node = get_node_or_null("CanisterSlot_%d" % idx)
	if slot_node and can.get_parent() == slot_node:
		slot_node.remove_child(can)
	elif can.get_parent():
		can.get_parent().remove_child(can)

	can.owner = null

	if player and player.has_method("pick_up"):
		player.pick_up(can)

	_play_oneshot("soda_canister_remove", -5.0)

	_show_feedback(player, "📦 %s desconectado e retirado" % can.display_name)
	_update_all_visuals()
	return can

# Conecta um novo galão de insumo no encaixe
func insert_canister(idx: int, can: SyrupCanister, player: Node3D) -> bool:
	if idx < 0 or idx >= 4 or not can:
		return false

	var expected_canister_id = FLAVORS[idx].canister_id
	var expected_flavor_id = FLAVORS[idx].id
	if can.item_id != expected_canister_id and can.flavor_type != expected_flavor_id:
		if player:
			_show_feedback(player, "❌ Galão incompatível! Este bocal requer %s." % FLAVORS[idx].name)
		return false

	if canisters[idx] != null and is_instance_valid(canisters[idx]):
		if player:
			_show_feedback(player, "⚠️ Já existe um galão conectado nesta posição. Remova-o primeiro.")
		return false

	var prev_parent = can.get_parent()
	if prev_parent:
		prev_parent.remove_child(can)

	var slot_node = get_node_or_null("CanisterSlot_%d" % idx)
	if slot_node:
		slot_node.add_child(can)
	else:
		add_child(can)

	can.position = Vector3.ZERO
	can.rotation = Vector3.ZERO
	canisters[idx] = can
	syrup_levels[idx] = can.current_amount

	_play_oneshot("soda_canister_insert", -5.0)

	if can.has_method("on_placed_in_station"):
		can.on_placed_in_station()

	if player:
		_show_feedback(player, "✅ %s instalado e conectado!" % can.display_name)
	_update_all_visuals()
	return true

func try_snap_cup(cup: DrinkCup, drop_global_pos: Vector3) -> bool:
	if not cup or not is_instance_valid(cup):
		return false

	var local_drop = to_local(drop_global_pos)
	# Verifica se está próximo da bandeja de pingos (Y ~ 0.70-1.30, Z ~ 0.0-0.40)
	if local_drop.y >= 0.70 and local_drop.y <= 1.30 and local_drop.z >= 0.0 and local_drop.z <= 0.40:
		var best_idx = _get_station_index_from_x(local_drop.x)
		if best_idx >= 0 and best_idx < 4:
			if current_cups[best_idx] == null:
				return place_cup_in_slot(best_idx, cup, null)
	return false

# Determina qual elemento da máquina o jogador está mirando
func _get_target_interaction(player: Node3D) -> Dictionary:
	if not player:
		return { "type": TargetType.NONE, "index": -1 }

	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if not ray or not ray is RayCast3D or not ray.is_colliding():
		return { "type": TargetType.NONE, "index": -1 }

	var col = ray.get_collider()
	if col and is_instance_valid(col):
		var col_name = col.name
		if col_name == "LeftDoorCollider" or (col.get_parent() and col.get_parent().name == "LeftDoorHinge"):
			return { "type": TargetType.LEFT_DOOR, "index": -1 }
		elif col_name == "RightDoorCollider" or (col.get_parent() and col.get_parent().name == "RightDoorHinge"):
			return { "type": TargetType.RIGHT_DOOR, "index": -1 }

	var hit_global_pt = ray.get_collision_point()
	var col_pt = to_local(hit_global_pt)

	# 1. Compartimento Inferior e Portas Articuladas (Y < 0.85)
	if col_pt.y < 0.85:
		# Verificação precisa das portas através de suas coordenadas locais de dobradiça
		if left_door_hinge:
			var pt_left = left_door_hinge.to_local(hit_global_pt)
			if pt_left.x >= -0.05 and pt_left.x <= 0.88 and absf(pt_left.y) <= 0.38 and absf(pt_left.z) <= 0.08:
				return { "type": TargetType.LEFT_DOOR, "index": -1 }

		if right_door_hinge:
			var pt_right = right_door_hinge.to_local(hit_global_pt)
			if pt_right.x >= -0.88 and pt_right.x <= 0.05 and absf(pt_right.y) <= 0.38 and absf(pt_right.z) <= 0.08:
				return { "type": TargetType.RIGHT_DOOR, "index": -1 }

		# Se não atingiu a porta (ex: porta aberta e jogador olhando para dentro do compartimento)
		if col_pt.x < 0.0:
			if is_left_door_open:
				var slot_idx = 0 if col_pt.x < -0.32 else 1
				return { "type": TargetType.CANISTER_SLOT, "index": slot_idx }
			else:
				return { "type": TargetType.LEFT_DOOR, "index": -1 }
		else:
			if is_right_door_open:
				var slot_idx = 2 if col_pt.x < 0.32 else 3
				return { "type": TargetType.CANISTER_SLOT, "index": slot_idx }
			else:
				return { "type": TargetType.RIGHT_DOOR, "index": -1 }

	# 2. Botão Power de Ligar/Desligar (Canto Superior Direito)
	if col_pt.y > 1.46 and col_pt.x > 0.58:
		return { "type": TargetType.POWER_SWITCH, "index": -1 }

	# 3. Estações Superiores (4 Sabores)
	var station_idx = _get_station_index_from_x(col_pt.x)
	current_flavor_index = station_idx

	if col_pt.y >= 1.05:
		return { "type": TargetType.LEVER, "index": station_idx }
	else:
		return { "type": TargetType.CUP_SLOT, "index": station_idx }

func _get_station_index_from_x(local_x: float) -> int:
	if local_x < -0.32:
		return 0 # Cola
	elif local_x < 0.0:
		return 1 # Cola Zero
	elif local_x < 0.32:
		return 2 # Limão
	else:
		return 3 # Laranja

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var target = _get_target_interaction(player as Node3D)
	var held = player.get("held_item")

	match target.type:
		TargetType.POWER_SWITCH:
			return "E — %s Máquina de Bebidas" % ("Desligar" if is_powered else "Ligar")

		TargetType.LEFT_DOOR:
			return "E — %s Porta Esquerda (Cola / Cola Zero)" % ("Fechar" if is_left_door_open else "Abrir")

		TargetType.RIGHT_DOOR:
			return "E — %s Porta Direita (Limão / Laranja)" % ("Fechar" if is_right_door_open else "Abrir")

		TargetType.CANISTER_SLOT:
			var idx = target.index
			if idx >= 0 and idx < 4:
				var can = canisters[idx]
				if held is SyrupCanister:
					if can == null:
						return "E — Conectar %s" % held.display_name
					else:
						return "⚠️ Encaixe ocupado por %s" % can.display_name
				elif held == null:
					if can != null and is_instance_valid(can):
						return "🖱️ / [E] Retirar %s (%d%%)" % [can.display_name, int(can.current_amount)]
					else:
						return "📦 Encaixe Vazio (%s) — Conecte um Galão" % FLAVORS[idx].name
			return "E — Fechar Porta"

		TargetType.LEVER:
			var idx = target.index
			if idx >= 0 and idx < 4:
				if not is_powered:
					return "⚠️ Máquina Desligada (Ligue no botão Power)"
				if is_lever_down[idx]:
					return "E — Levantar Alavanca e Parar Fluxo de %s" % FLAVORS[idx].name
				if syrup_levels[idx] <= 0.0:
					return "🔴 Sem Insumo de %s! Troque o Galão" % FLAVORS[idx].name
				var cup = current_cups[idx]
				if not cup:
					return "⚠️ Posicione um copo no bico de %s" % FLAVORS[idx].name
				if cup.fill_amount >= 1.0 or cup.state == DrinkCup.State.FILLED or cup.state == DrinkCup.State.CLOSED:
					return "✨ Copo já está cheio! Pegue com o clique"
				return "E — Abaixar Alavanca e Servir %s" % FLAVORS[idx].name

		TargetType.CUP_SLOT:
			var idx = target.index
			if idx >= 0 and idx < 4:
				var cup = current_cups[idx]
				if held is DrinkCup and held.state == DrinkCup.State.EMPTY:
					return "E — Posicionar Copo no Bico de %s" % FLAVORS[idx].name
				if cup and is_instance_valid(cup):
					if cup.fill_amount >= 1.0 or cup.state == DrinkCup.State.FILLED:
						return "🖱️ / [E] Pegar %s Cheio" % cup.get_flavor_display_name()
					else:
						return "🖱️ Pegar Copo Vazio  │  [E na Alavanca] Servir %s" % FLAVORS[idx].name
				elif held == null:
					if not is_powered:
						return "⚡ Máquina Desligada"
					if syrup_levels[idx] <= 0.0:
						return "🔴 Sem Insumo de %s" % FLAVORS[idx].name
					return "🥤 Posicione um copo vazio no bico de %s" % FLAVORS[idx].name

	return "E — Máquina de Bebidas"

func interact(player: Node3D) -> void:
	if not player:
		return

	var target = _get_target_interaction(player)
	var held = player.get("held_item")

	match target.type:
		TargetType.POWER_SWITCH:
			toggle_power(player)
			return

		TargetType.LEFT_DOOR:
			toggle_left_door(player)
			return

		TargetType.RIGHT_DOOR:
			toggle_right_door(player)
			return

		TargetType.CANISTER_SLOT:
			var idx = target.index
			if idx >= 0 and idx < 4:
				if held is SyrupCanister:
					var can = player.take_held_item() if player.has_method("take_held_item") else held
					if can is SyrupCanister:
						insert_canister(idx, can, player)
					return
				elif held == null:
					remove_canister(idx, player)
					return
			return

		TargetType.LEVER:
			var idx = target.index
			if idx >= 0 and idx < 4:
				toggle_lever(idx, player)
				return

		TargetType.CUP_SLOT:
			var idx = target.index
			if idx >= 0 and idx < 4:
				var cup = current_cups[idx]
				# 1. Colocar copo da mão no slot
				if held is DrinkCup and held.state == DrinkCup.State.EMPTY:
					if player.has_method("take_held_item"):
						var c = player.take_held_item() as DrinkCup
						place_cup_in_slot(idx, c, player)
					return

				# 2. Retirar copo presente
				if cup and is_instance_valid(cup):
					take_cup_from_slot(idx, player)
					return

	# Fallback geral (para testes headless sem RayCast de câmera)
	var fallback_idx = target.index if (target.index >= 0 and target.index < 4) else current_flavor_index
	if fallback_idx >= 0 and fallback_idx < 4:
		var cup = current_cups[fallback_idx]
		if cup != null and is_instance_valid(cup):
			if cup.state == DrinkCup.State.EMPTY and not is_lever_down[fallback_idx]:
				toggle_lever(fallback_idx, player)
				return
			elif cup.state == DrinkCup.State.FILLED or cup.state == DrinkCup.State.CLOSED:
				take_cup_from_slot(fallback_idx, player)
				return
		toggle_lever(fallback_idx, player)

func interact_item(player: Node3D) -> void:
	if not player:
		return

	var target = _get_target_interaction(player)
	var held = player.get("held_item")

	# 1. Se estiver segurando um copo vazio e clicou na máquina -> posiciona o copo no bico correspondente
	if held is DrinkCup and held.state == DrinkCup.State.EMPTY:
		var idx = target.index if (target.index >= 0 and target.index < 4) else current_flavor_index
		if idx >= 0 and idx < 4:
			if current_cups[idx] == null:
				var c = player.take_held_item() as DrinkCup
				place_cup_in_slot(idx, c, player)
				return

	# 2. Se estiver segurando um barril e clicou no compartimento aberto -> insere o barril
	if held is SyrupCanister:
		var idx = target.index if (target.index >= 0 and target.index < 4) else current_flavor_index
		if idx >= 0 and idx < 4:
			var can = player.take_held_item() as SyrupCanister
			insert_canister(idx, can, player)
			return

	# 3. Se estiver com a mão livre:
	if held == null:
		# Se mirou no compartimento com porta aberta em um barril -> retira o barril
		if target.type == TargetType.CANISTER_SLOT:
			var idx = target.index
			if idx >= 0 and idx < 4 and canisters[idx] != null:
				remove_canister(idx, player)
				return

		# Se mirou em uma estação / copo na bandeja -> retira o copo imediatamente!
		var idx = target.index if (target.index >= 0 and target.index < 4) else current_flavor_index
		if idx >= 0 and idx < 4 and current_cups[idx] != null and is_instance_valid(current_cups[idx]):
			take_cup_from_slot(idx, player)
			return

# Atualização de barras LED e luz indicadora Power
func _update_all_visuals() -> void:
	# 1. LED Power
	if not power_led:
		power_led = get_node_or_null("Model/PowerSwitch/StatusLED")
	if power_led:
		var mat_led = StandardMaterial3D.new()
		mat_led.albedo_color = Color(0.2, 0.95, 0.3, 1.0) if is_powered else Color(0.9, 0.2, 0.2, 1.0)
		mat_led.emission_enabled = true
		mat_led.emission = mat_led.albedo_color
		mat_led.emission_energy_multiplier = 1.3 if is_powered else 0.4
		power_led.material_override = mat_led

	# 2. Barras LED de nível das 4 estações
	for i in range(4):
		var meter = get_node_or_null("Model/LevelMeter_%d" % i)
		if meter and meter is MeshInstance3D:
			var lvl = syrup_levels[i]
			var mat = StandardMaterial3D.new()
			if not is_powered:
				mat.albedo_color = Color(0.18, 0.18, 0.20, 1.0)
				mat.roughness = 0.8
			elif lvl <= 0.0:
				mat.albedo_color = Color(0.9, 0.18, 0.18, 1.0)
				mat.emission_enabled = true
				mat.emission = Color(0.9, 0.18, 0.18, 1.0)
				mat.emission_energy_multiplier = 0.8
			elif lvl <= 5.0:
				mat.albedo_color = Color(0.95, 0.75, 0.1, 1.0) # Amarelo/Laranja Alerta
				mat.emission_enabled = true
				mat.emission = Color(0.95, 0.75, 0.1, 1.0)
				mat.emission_energy_multiplier = 0.8
			else:
				mat.albedo_color = Color(0.2, 0.95, 0.3, 1.0) # Verde Cheio
				mat.emission_enabled = true
				mat.emission = Color(0.2, 0.95, 0.3, 1.0)
				mat.emission_energy_multiplier = 0.95

			meter.material_override = mat
			# Escala visual da barra proporcional ao nível de 25 doses
			var fraction = clampf(lvl / MAX_DOSES_PER_CANISTER, 0.05, 1.0) if is_powered else 0.05
			meter.scale.x = fraction

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)

# ================================================================
# MÉTODOS DE COMPATIBILIDADE PARA TESTES LEGADOS
# ================================================================
func get_current_flavor_id() -> String:
	return FLAVORS[current_flavor_index].id

func get_current_flavor_name() -> String:
	return FLAVORS[current_flavor_index].name

func select_flavor_by_index(idx: int, worker: Node3D = null) -> String:
	current_flavor_index = clampi(idx, 0, 3)
	var fname = get_current_flavor_name()
	if worker:
		_show_feedback(worker, "🥤 Sabor selecionado: %s" % fname)
	return fname

func cycle_flavor(worker: Node3D = null) -> String:
	current_flavor_index = (current_flavor_index + 1) % 4
	return select_flavor_by_index(current_flavor_index, worker)

func has_syrup() -> bool:
	return syrup_levels[current_flavor_index] > 0.0

func refill_syrup(amount: int = 50, worker: Node3D = null) -> int:
	for i in range(4):
		syrup_levels[i] = minf(100.0, syrup_levels[i] + float(amount))
		if canisters[i] and is_instance_valid(canisters[i]):
			canisters[i].current_amount = syrup_levels[i]
	if worker:
		_show_feedback(worker, "✨ Reservatórios de xarope abastecidos!")
	_update_all_visuals()
	return amount
