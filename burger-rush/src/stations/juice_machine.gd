class_name JuiceMachine
extends StaticBody3D

# ================================================================
# MÁQUINA PROFISSIONAL DE SUCOS (SUQUEIRA INDUSTRIAL 3 SABORES)
# - Sincronização Perfeita de Estoque, Processamento e Renderização do Líquido
# - Nível de Suco Sobe Gradualmente de Baixo para Cima (+5 doses por polpa)
# - Reservatórios Acrílicos Transparentes com Líquido 3D Visível e Vibrante
# ================================================================

enum TargetType {
	DRAWER,
	LEVER,
	CUP_SLOT,
	POWER_SWITCH,
	NONE
}

const FLAVORS = [
	{
		"id": "juice_orange",
		"name": "LARANJA",
		"pulp_id": "pulp_orange",
		"icon": "🍊",
		"color": Color(0.98, 0.52, 0.05, 0.92),
		"x_pos": -0.42
	},
	{
		"id": "juice_grape",
		"name": "UVA",
		"pulp_id": "pulp_grape",
		"icon": "🍇",
		"color": Color(0.48, 0.12, 0.65, 0.92),
		"x_pos": 0.0
	},
	{
		"id": "juice_strawberry",
		"name": "MORANGO",
		"pulp_id": "pulp_strawberry",
		"icon": "🍓",
		"color": Color(0.92, 0.12, 0.28, 0.92),
		"x_pos": 0.42
	}
]

const MAX_JUICE_DOSES: float = 15.0 # Capacidade máxima: 15 doses (3 pedras de polpa)
const DOSES_PER_PULP: float = 5.0
const FILL_DURATION: float = 0.85 # tempo para encher um copo

const JuicePulp = preload("res://src/items/juice_pulp.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

# Estado Geral da Máquina
@export var is_powered: bool = true

# Estado de cada uma das 3 estações (0: Laranja, 1: Uva, 2: Morango)
var is_drawer_open: Array[bool] = [false, false, false]
var drawer_positions: Array[float] = [0.0, 0.0, 0.0]
var placed_pulps: Array = [null, null, null]
var is_processing: Array[bool] = [false, false, false]
var process_timers: Array[float] = [0.0, 0.0, 0.0]
var juice_doses: Array[float] = [0.0, 0.0, 0.0] # Inicia vazio para o ciclo de abastecimento por polpa
var target_juice_doses: Array[float] = [0.0, 0.0, 0.0]

# Estado de torneiras e copos
var is_lever_down: Array[bool] = [false, false, false]
var current_cups: Array = [null, null, null]
var fill_progresses: Array[float] = [0.0, 0.0, 0.0]

# Nós de Referência
@onready var power_led: MeshInstance3D = get_node_or_null("Model/PowerSwitch/StatusLED")

func _ready() -> void:
	_update_all_visuals()

func _process(delta: float) -> void:
	# 1. Animação de deslizamento suave das gavetas
	for i in range(3):
		var target_z = 0.32 if is_drawer_open[i] else 0.0
		drawer_positions[i] = lerpf(drawer_positions[i], target_z, delta * 12.0)
		var d_node = get_node_or_null("Model/Drawer_%d" % i)
		if d_node:
			d_node.position.z = drawer_positions[i]

	# 2. Processamento e Moagem da Polpa
	for i in range(3):
		if is_processing[i] and is_powered:
			process_timers[i] -= delta
			if process_timers[i] <= 0.0:
				is_processing[i] = false
				target_juice_doses[i] = minf(MAX_JUICE_DOSES, target_juice_doses[i] + DOSES_PER_PULP)

		# Subida gradual e suave do nível de suco no reservatório correspondente (de baixo para cima)
		if juice_doses[i] < target_juice_doses[i]:
			juice_doses[i] = move_toward(juice_doses[i], target_juice_doses[i], delta * 3.0)
			_update_reservoir_visual(i)
		elif juice_doses[i] > target_juice_doses[i]:
			juice_doses[i] = target_juice_doses[i]
			_update_reservoir_visual(i)

	# 3. Fluxo das Torneiras para os Copos
	for i in range(3):
		_process_dispensing(i, delta)

func _process_dispensing(idx: int, delta: float) -> void:
	var lever_mesh = get_node_or_null("Model/LeverPivot_%d/LeverArm_%d" % [idx, idx])
	var target_lever_rot = deg_to_rad(28.0) if is_lever_down[idx] else 0.0
	if lever_mesh:
		lever_mesh.rotation.x = lerp_angle(lever_mesh.rotation.x, target_lever_rot, delta * 14.0)

	var stream_mesh = get_node_or_null("Model/Stream_%d" % idx)

	if is_lever_down[idx]:
		var cup = current_cups[idx]
		if not is_powered or not cup or not is_instance_valid(cup) or juice_doses[idx] <= 0.0:
			stop_pouring(idx)
			return

		if stream_mesh:
			stream_mesh.visible = true

		var prev_fill = fill_progresses[idx]
		var flow_step = delta / FILL_DURATION
		var next_fill = minf(1.0, prev_fill + flow_step)
		fill_progresses[idx] = next_fill
		var fill_step = next_fill - prev_fill

		cup.fill_amount = fill_progresses[idx]
		cup.set_flavor(FLAVORS[idx].id)
		cup._update_visuals()

		# Consome 1 dose gradualmente durante o enchimento
		var dose_cost = fill_step * 1.0
		juice_doses[idx] = maxf(0.0, juice_doses[idx] - dose_cost)
		target_juice_doses[idx] = juice_doses[idx]
		_update_reservoir_visual(idx)

		if fill_progresses[idx] >= 1.0:
			cup.set_state(DrinkCup.State.FILLED)
			stop_pouring(idx)
	else:
		if stream_mesh:
			stream_mesh.visible = false

# ================================================================
# BOTÃO POWER LIGA/DESLIGA
# ================================================================
func toggle_power(worker: Node3D = null) -> void:
	is_powered = !is_powered
	if not is_powered:
		for i in range(3):
			stop_pouring(i)
	if worker:
		var msg = "⚡ Máquina de Sucos LIGADA" if is_powered else "⚡ Máquina de Sucos DESLIGADA"
		_show_feedback(worker, msg)
	_update_power_visual()

# ================================================================
# CONTROLE E VALIDAÇÃO DE POLPAS E GAVETAS
# ================================================================
func is_pulp_compatible(idx: int, pulp: JuicePulp) -> bool:
	if idx < 0 or idx >= 3 or not pulp:
		return false
	var expected_pulp_id = FLAVORS[idx].pulp_id
	var expected_fruit_id = FLAVORS[idx].id
	if pulp.item_id == expected_pulp_id or pulp.fruit_type == FLAVORS[idx].name.to_lower():
		return true
	if pulp.has_method("get_fruit_id") and pulp.get_fruit_id() == expected_fruit_id:
		return true
	return false

func toggle_drawer(idx: int, worker: Node3D = null) -> void:
	if idx < 0 or idx >= 3:
		return

	is_drawer_open[idx] = !is_drawer_open[idx]
	if not is_drawer_open[idx]:
		# Ao fechar a gaveta: se tiver uma polpa colocada, consome e inicia o processamento
		if placed_pulps[idx] != null and is_instance_valid(placed_pulps[idx]):
			placed_pulps[idx].queue_free()
			placed_pulps[idx] = null
			is_processing[idx] = true
			process_timers[idx] = 1.8 # Tempo de processamento (~1.8s) antes de iniciar a subida do líquido
			if worker:
				if not is_powered:
					_show_feedback(worker, "⚙️ Polpa inserida! Ligue a máquina no botão Power para processar.")
				else:
					_show_feedback(worker, "⚙️ Processando polpa de %s... (+5 doses de suco)" % FLAVORS[idx].name)
		else:
			if worker:
				_show_feedback(worker, "Gaveta de %s Fechada" % FLAVORS[idx].name)
	else:
		if worker:
			_show_feedback(worker, "Gaveta de %s Aberta — Insira uma Pedra de Polpa de %s" % [FLAVORS[idx].name, FLAVORS[idx].name])

func insert_pulp_in_drawer(idx: int, pulp: JuicePulp, worker: Node3D = null) -> bool:
	if idx < 0 or idx >= 3 or not pulp:
		return false

	if not is_drawer_open[idx]:
		if worker:
			_show_feedback(worker, "⚠️ Abra a gaveta com [E] antes de colocar a polpa.")
		return false

	# Validação estrita do tipo do item
	if not is_pulp_compatible(idx, pulp):
		if worker:
			_show_feedback(worker, "❌ Esta gaveta é de %s! Não aceita polpa de outro sabor." % FLAVORS[idx].name)
		return false

	if placed_pulps[idx] != null and is_instance_valid(placed_pulps[idx]):
		if worker:
			_show_feedback(worker, "⚠️ Já existe uma pedra de polpa na gaveta. Feche-a com [E] para processar.")
		return false

	if target_juice_doses[idx] + DOSES_PER_PULP > MAX_JUICE_DOSES:
		if worker:
			_show_feedback(worker, "⚠️ Reservatório de %s quase cheio! Consuma antes de adicionar mais." % FLAVORS[idx].name)
		return false

	var prev = pulp.get_parent()
	if prev:
		prev.remove_child(pulp)

	var holder = get_node_or_null("Model/Drawer_%d/PulpHolder" % idx)
	if holder:
		holder.add_child(pulp)
	else:
		var d_node = get_node_or_null("Model/Drawer_%d" % idx)
		if d_node:
			d_node.add_child(pulp)
		else:
			add_child(pulp)

	# Apoia perfeitamente a pedra no fundo da gaveta
	pulp.position = Vector3.ZERO
	pulp.rotation = Vector3.ZERO
	pulp.visible = true
	placed_pulps[idx] = pulp

	if worker:
		_show_feedback(worker, "🧊 Polpa de %s colocada na gaveta! Feche com [E] para moer." % FLAVORS[idx].name)
	return true

# ================================================================
# CONTROLE DE TORNEIRAS E COPOS
# ================================================================
func toggle_lever(idx: int, worker: Node3D = null) -> void:
	if idx < 0 or idx >= 3:
		return

	if is_lever_down[idx]:
		stop_pouring(idx)
		if worker:
			_show_feedback(worker, "⏹️ Fluxo de Suco de %s interrompido" % FLAVORS[idx].name)
		return

	if not is_powered:
		if worker:
			_show_feedback(worker, "⚠️ Ligue a máquina no botão Power antes de servir.")
		return

	if juice_doses[idx] <= 0.0:
		if worker:
			_show_feedback(worker, "🔴 Reservatório de %s vazio! Abasteça com uma pedra de polpa na gaveta." % FLAVORS[idx].name)
		return

	var cup = current_cups[idx]
	if not cup or not is_instance_valid(cup):
		if worker:
			_show_feedback(worker, "⚠️ Posicione um copo na base sob a torneira de %s." % FLAVORS[idx].name)
		return

	if cup.fill_amount >= 1.0 or cup.state == DrinkCup.State.FILLED or cup.state == DrinkCup.State.CLOSED:
		if worker:
			_show_feedback(worker, "✨ Copo já está cheio!")
		return

	start_pouring(idx)
	if worker:
		_show_feedback(worker, "🍹 Servindo Suco de %s..." % FLAVORS[idx].name)

func start_pouring(idx: int) -> void:
	if idx < 0 or idx >= 3:
		return
	is_lever_down[idx] = true
	var cup = current_cups[idx]
	if cup and is_instance_valid(cup):
		cup.set_flavor(FLAVORS[idx].id)
	var stream_mesh = get_node_or_null("Model/Stream_%d" % idx)
	if stream_mesh:
		stream_mesh.visible = true

func stop_pouring(idx: int) -> void:
	if idx < 0 or idx >= 3:
		return
	is_lever_down[idx] = false
	var stream_mesh = get_node_or_null("Model/Stream_%d" % idx)
	if stream_mesh:
		stream_mesh.visible = false

func place_cup_in_slot(idx: int, cup: DrinkCup, worker: Node3D = null) -> bool:
	if idx < 0 or idx >= 3 or not cup:
		return false
	if current_cups[idx] != null and is_instance_valid(current_cups[idx]):
		if worker:
			_show_feedback(worker, "⚠️ Já existe um copo na base de %s." % FLAVORS[idx].name)
		return false

	var prev = cup.get_parent()
	if prev:
		prev.remove_child(cup)

	var slot = get_node_or_null("CupSlot_%d" % idx)
	if slot:
		slot.add_child(cup)
	else:
		add_child(cup)

	cup.position = Vector3.ZERO
	cup.rotation = Vector3.ZERO
	current_cups[idx] = cup
	fill_progresses[idx] = cup.fill_amount

	if cup.has_method("on_placed_in_station"):
		cup.on_placed_in_station()

	if worker:
		_show_feedback(worker, "🥤 Copo apoiado na base de Suco de %s" % FLAVORS[idx].name)
	return true

func take_cup_from_slot(idx: int, player: Node3D) -> DrinkCup:
	if idx < 0 or idx >= 3:
		return null
	var cup = current_cups[idx]
	if not cup or not is_instance_valid(cup):
		return null

	stop_pouring(idx)
	current_cups[idx] = null
	fill_progresses[idx] = 0.0

	var slot = get_node_or_null("CupSlot_%d" % idx)
	if slot and cup.get_parent() == slot:
		slot.remove_child(cup)
	elif cup.get_parent():
		cup.get_parent().remove_child(cup)

	if player and player.has_method("pick_up"):
		player.pick_up(cup)

	_show_feedback(player, "🥤 %s retirado!" % cup.get_flavor_display_name())
	return cup

func try_snap_cup(cup: DrinkCup, drop_global_pos: Vector3) -> bool:
	if not cup or not is_instance_valid(cup):
		return false

	var local_drop = to_local(drop_global_pos)
	if local_drop.y >= 0.70 and local_drop.y <= 1.30 and local_drop.z >= 0.0 and local_drop.z <= 0.45:
		var best_idx = 0
		var best_dist = 999.0
		for i in range(3):
			var slot_pos = Vector3(FLAVORS[i].x_pos, 0.894, 0.22)
			var d = local_drop.distance_to(slot_pos)
			if d < best_dist and current_cups[i] == null:
				best_dist = d
				best_idx = i

		if best_dist < 0.32:
			return place_cup_in_slot(best_idx, cup, null)
	return false

# ================================================================
# DETECÇÃO DE MIRA E INTERAÇÃO
# ================================================================
func _get_target_interaction(player: Node3D) -> Dictionary:
	var result = { "type": TargetType.NONE, "index": 0 }
	if not player:
		return result

	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if not ray or not (ray is RayCast3D) or not ray.is_colliding():
		return result

	var col_pt = to_local(ray.get_collision_point())

	# 1. Botão Power (Painel lateral direito)
	if col_pt.y > 0.85 and col_pt.x > 0.48:
		return { "type": TargetType.POWER_SWITCH, "index": -1 }

	var station_idx = 0
	if col_pt.x < -0.21:
		station_idx = 0 # Laranja
	elif col_pt.x > 0.21:
		station_idx = 2 # Morango
	else:
		station_idx = 1 # Uva

	# 2. Gavetas Inferiores (Y < 0.78)
	if col_pt.y < 0.78:
		return { "type": TargetType.DRAWER, "index": station_idx }

	# 3. Alavancas das Torneiras (Y >= 1.10)
	if col_pt.y >= 1.10:
		return { "type": TargetType.LEVER, "index": station_idx }

	# 4. Área de Copos na Base (Y ~ 0.78 - 1.10)
	return { "type": TargetType.CUP_SLOT, "index": station_idx }

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var target = _get_target_interaction(player as Node3D)
	var held = player.get("held_item")
	var idx = target.index

	match target.type:
		TargetType.POWER_SWITCH:
			return "E — %s Máquina de Sucos" % ("Desligar" if is_powered else "Ligar")

		TargetType.DRAWER:
			if is_drawer_open[idx]:
				if held is JuicePulp:
					if is_pulp_compatible(idx, held):
						return "🖱️ / [E] Colocar Polpa de %s na Gaveta" % FLAVORS[idx].name
					else:
						return "❌ Polpa Incompatível (Esta gaveta é para %s)" % FLAVORS[idx].name
				return "E — Fechar Gaveta de %s" % FLAVORS[idx].name
			else:
				return "E — Abrir Gaveta de Polpa de %s" % FLAVORS[idx].name

		TargetType.LEVER:
			if not is_powered:
				return "⚡ Máquina de Sucos Desligada (Ligue no botão Power)"
			if is_lever_down[idx]:
				return "E — Parar Fluxo de Suco de %s" % FLAVORS[idx].name
			if juice_doses[idx] <= 0.0:
				return "🔴 Sem Suco de %s! Abasteça com Polpa na Gaveta" % FLAVORS[idx].name
			var cup = current_cups[idx]
			if not cup:
				return "⚠️ Posicione um copo na base sob a torneira de %s" % FLAVORS[idx].name
			return "E — Servir Suco de %s" % FLAVORS[idx].name

		TargetType.CUP_SLOT:
			if held is DrinkCup and held.state == DrinkCup.State.EMPTY:
				return "🖱️ / [E] Posicionar Copo na Base de %s" % FLAVORS[idx].name
			var cup = current_cups[idx]
			if cup and is_instance_valid(cup):
				return "🖱️ Pegar %s" % cup.get_flavor_display_name()
			return "🥤 Base de Copo (%s)" % FLAVORS[idx].name

	return "E — Máquina de Sucos"

func interact(player: Node3D) -> void:
	if not player:
		return

	var target = _get_target_interaction(player)
	var held = player.get("held_item")
	var idx = target.index

	match target.type:
		TargetType.POWER_SWITCH:
			toggle_power(player)
			return

		TargetType.DRAWER:
			if is_drawer_open[idx] and held is JuicePulp:
				if not is_pulp_compatible(idx, held):
					_show_feedback(player, "❌ Esta gaveta é de %s! Não aceita polpa de outro sabor." % FLAVORS[idx].name)
					return
				if placed_pulps[idx] != null and is_instance_valid(placed_pulps[idx]):
					_show_feedback(player, "⚠️ Já existe uma pedra de polpa na gaveta. Feche-a com [E] para processar.")
					return
				if target_juice_doses[idx] + DOSES_PER_PULP > MAX_JUICE_DOSES:
					_show_feedback(player, "⚠️ Reservatório de %s quase cheio! Consuma antes de adicionar mais." % FLAVORS[idx].name)
					return
				var pulp = player.take_held_item() as JuicePulp
				insert_pulp_in_drawer(idx, pulp, player)
			else:
				toggle_drawer(idx, player)
			return

		TargetType.LEVER:
			toggle_lever(idx, player)
			return

		TargetType.CUP_SLOT:
			if held is DrinkCup and held.state == DrinkCup.State.EMPTY:
				var c = player.take_held_item() as DrinkCup
				place_cup_in_slot(idx, c, player)
			elif current_cups[idx] != null and is_instance_valid(current_cups[idx]):
				take_cup_from_slot(idx, player)
			return

	# Fallback
	toggle_lever(idx, player)

func interact_item(player: Node3D) -> void:
	if not player:
		return

	var target = _get_target_interaction(player)
	var held = player.get("held_item")
	var idx = target.index

	# Se estiver segurando polpa e mirar na gaveta aberta -> validação estrita antes de transferir
	if held is JuicePulp and is_drawer_open[idx]:
		if not is_pulp_compatible(idx, held):
			_show_feedback(player, "❌ Esta gaveta é de %s! Não aceita polpa de outro sabor." % FLAVORS[idx].name)
			return
		if placed_pulps[idx] != null and is_instance_valid(placed_pulps[idx]):
			_show_feedback(player, "⚠️ Já existe uma pedra de polpa na gaveta. Feche-a com [E] para processar.")
			return
		if target_juice_doses[idx] + DOSES_PER_PULP > MAX_JUICE_DOSES:
			_show_feedback(player, "⚠️ Reservatório de %s quase cheio! Consuma antes de adicionar mais." % FLAVORS[idx].name)
			return
		var pulp = player.take_held_item() as JuicePulp
		insert_pulp_in_drawer(idx, pulp, player)
		return

	# Se segurando copo vazio -> coloca na base
	if held is DrinkCup and held.state == DrinkCup.State.EMPTY:
		var c = player.take_held_item() as DrinkCup
		place_cup_in_slot(idx, c, player)
		return

	# Se mão livre e mirar em copo -> retira
	if held == null and current_cups[idx] != null and is_instance_valid(current_cups[idx]):
		take_cup_from_slot(idx, player)
		return

# ================================================================
# ATUALIZAÇÃO VISUAL DOS RESERVATÓRIOS E POWER LED
# ================================================================
func _update_all_visuals() -> void:
	_update_power_visual()
	for i in range(3):
		_update_reservoir_visual(i)

func _update_power_visual() -> void:
	if not power_led:
		power_led = get_node_or_null("Model/PowerSwitch/StatusLED")
	if power_led:
		var mat_led = StandardMaterial3D.new()
		mat_led.albedo_color = Color(0.2, 0.95, 0.3, 1.0) if is_powered else Color(0.9, 0.2, 0.2, 1.0)
		mat_led.emission_enabled = true
		mat_led.emission = mat_led.albedo_color
		mat_led.emission_energy_multiplier = 1.3 if is_powered else 0.4
		power_led.material_override = mat_led

func _update_reservoir_visual(idx: int) -> void:
	var liquid_mesh = get_node_or_null("Model/Reservoir_%d/Liquid" % idx)
	if liquid_mesh and liquid_mesh is MeshInstance3D:
		var pct = clampf(juice_doses[idx] / MAX_JUICE_DOSES, 0.0, 1.0)
		if pct <= 0.001:
			liquid_mesh.visible = false
		else:
			liquid_mesh.visible = true
			var mat = StandardMaterial3D.new()
			mat.render_priority = 0
			mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = FLAVORS[idx].color
			mat.roughness = 0.12
			mat.clearcoat = 0.6
			mat.emission_enabled = true
			mat.emission = Color(FLAVORS[idx].color.r, FLAVORS[idx].color.g, FLAVORS[idx].color.b) * 0.22
			liquid_mesh.material_override = mat

			# Altura e posicionamento preciso dentro do jarro de acrílico (Y 1.20 a 1.74)
			var max_h = 0.52
			var h = maxf(0.03, max_h * pct)
			var box = BoxMesh.new()
			box.size = Vector3(0.33, h, 0.39)
			liquid_mesh.mesh = box
			liquid_mesh.position = Vector3(0, 1.20 + h * 0.5, 0)

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
