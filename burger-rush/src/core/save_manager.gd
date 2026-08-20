extends Node

# =============================================================================
# BURGER RUSH — GERENCIADOR DE PERSISTÊNCIA E SAVE LOCAL (FASE 4)
#
# Responsável por:
# - Gerenciar 2 slots de save independentes em user://saves/
# - Serializar e restaurar progresso permanente (Dinheiro, Dias, Desbloqueios)
# - Gravação atômica segura contra corrupção
# - Auto-save a cada 5 minutos de gameplay ativo (respeitando pausas)
# - Save automático ao encerramento de cada dia
# - Validação de integridade e metadados rápidos
# =============================================================================

signal save_completed(slot: int, success: bool)
signal save_loaded(slot: int, success: bool)
signal save_deleted(slot: int)
signal auto_save_triggered(slot: int)

const SAVE_VERSION: int = 1
const MAX_SLOTS: int = 2
const SAVE_DIR: String = "user://saves"
const AUTO_SAVE_INTERVAL: float = 300.0 # 5 minutos (300 segundos)

static var instance = null

var active_slot: int = 1
var has_active_game: bool = false
var pending_save_data: Dictionary = {}

var _auto_save_timer: float = 0.0
var _custom_save_dir: String = "" # Permite isolamento em suítes de teste

func _init() -> void:
	instance = self

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_save_directory()

func _ensure_save_directory() -> void:
	var dir_path = get_save_directory()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			printerr("[SaveManager] Erro ao criar diretório de saves: ", dir_path, " (Erro: ", err, ")")

func get_save_directory() -> String:
	return _custom_save_dir if _custom_save_dir != "" else SAVE_DIR

func set_custom_save_dir(path: String) -> void:
	_custom_save_dir = path
	_ensure_save_directory()

func get_slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [get_save_directory(), slot]

func get_slot_temp_path(slot: int) -> String:
	return "%s/slot_%d.tmp" % [get_save_directory(), slot]

# =============================================================================
# CONTROLE DE SLOTS E METADADOS
# =============================================================================

func set_active_slot(slot: int) -> void:
	if slot >= 1 and slot <= MAX_SLOTS:
		active_slot = slot

func get_active_slot() -> int:
	return active_slot

## Verifica se o arquivo do slot existe
func has_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false
	return FileAccess.file_exists(get_slot_path(slot))

## Verifica se existe pelo menos um save válido em qualquer slot
func has_any_save() -> bool:
	for slot in range(1, MAX_SLOTS + 1):
		if has_valid_save(slot):
			return true
	return false

## Retorna o slot do save mais recente, ou 1 por padrão
func get_latest_save_slot() -> int:
	var latest_slot = 1
	var latest_timestamp: int = -1

	for slot in range(1, MAX_SLOTS + 1):
		if has_valid_save(slot):
			var meta = get_save_metadata(slot)
			var unix_time = meta.get("last_save_unix", 0)
			if unix_time > latest_timestamp:
				latest_timestamp = unix_time
				latest_slot = slot

	return latest_slot

## Valida se o save do slot é um JSON íntegro e compatível
func has_valid_save(slot: int) -> bool:
	if not has_save(slot):
		return false

	var path = get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var content = file.get_as_text()
	file.close()

	if content.strip_edges().is_empty():
		return false

	var json = JSON.new()
	var parse_err = json.parse(content)
	if parse_err != OK:
		printerr("[SaveManager] Save corrompido no slot %d: falha no JSON." % slot)
		return false

	var data = json.data
	if not (data is Dictionary):
		return false

	# Validação dos campos mínimos obrigatórios
	if not data.has("save_version") or not data.has("slot") or not data.has("has_game"):
		return false

	if data.get("slot") != slot:
		return false

	if data.get("save_version") > SAVE_VERSION:
		printerr("[SaveManager] Versão do save (%d) superior à suportada (%d)." % [data.get("save_version"), SAVE_VERSION])
		return false

	return data.get("has_game", false)

## Retorna metadados resumidos para exibição rápida de slots na UI
func get_save_metadata(slot: int) -> Dictionary:
	var meta = {
		"exists": false,
		"valid": false,
		"slot": slot,
		"player_name": "Chefe",
		"current_day": 1,
		"money": 100.0,
		"last_save_timestamp": "Nunca",
		"last_save_unix": 0
	}

	if not has_save(slot):
		return meta

	meta["exists"] = true
	if not has_valid_save(slot):
		return meta

	meta["valid"] = true
	var path = get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(content) == OK and json.data is Dictionary:
			var d = json.data
			meta["player_name"] = d.get("player_name", "Chefe")
			meta["current_day"] = d.get("current_day", 1)
			meta["money"] = d.get("money", 100.0)
			meta["last_save_timestamp"] = d.get("last_save_timestamp", "Desconhecido")
			meta["last_save_unix"] = d.get("last_save_unix", 0)

	return meta

# =============================================================================
# GRAVAÇÃO E PERSISTÊNCIA ATÔMICA
# =============================================================================

## Salva o estado atual do jogo no slot especificado (ou active_slot)
func save_game(slot: int = -1) -> bool:
	var target_slot = active_slot if slot == -1 else slot
	if target_slot < 1 or target_slot > MAX_SLOTS:
		printerr("[SaveManager] Slot inválido para gravação: ", target_slot)
		return false

	_ensure_save_directory()

	# Coleta os dados dos subsistemas existentes (sem duplicação de dados)
	var save_data = _collect_game_data(target_slot)

	# Gravação atômica: escreve no .tmp primeiro e depois renomeia
	var temp_path = get_slot_temp_path(target_slot)
	var final_path = get_slot_path(target_slot)

	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		printerr("[SaveManager] Falha ao abrir arquivo temporário: ", temp_path)
		save_completed.emit(target_slot, false)
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	# Validação da escrita temporária antes da substituição final
	if not FileAccess.file_exists(temp_path):
		printerr("[SaveManager] Arquivo temporário não persistido.")
		save_completed.emit(target_slot, false)
		return false

	# Substituição atômica: remove save antigo e renomeia temporário
	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(final_path)

	var rename_err = DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		printerr("[SaveManager] Falha ao finalizar arquivo de save: ", rename_err)
		save_completed.emit(target_slot, false)
		return false

	has_active_game = true
	active_slot = target_slot
	save_completed.emit(target_slot, true)
	return true

## Cria uma nova carreira com valores iniciais limpos e salva no slot especificado
func create_new_career(slot: int, player_name: String = "Chefe") -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false

	var clean_name = player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Chefe"

	_ensure_save_directory()

	var now_dict = Time.get_datetime_dict_from_system()
	var timestamp_str = "%02d/%02d/%04d %02d:%02d" % [
		now_dict["day"], now_dict["month"], now_dict["year"],
		now_dict["hour"], now_dict["minute"]
	]
	var unix_timestamp = int(Time.get_unix_time_from_system())

	var initial_data = {
		"save_version": SAVE_VERSION,
		"slot": slot,
		"has_game": true,
		"player_name": clean_name,
		"current_day": 1,
		"money": 100.0,
		"last_save_timestamp": timestamp_str,
		"last_save_unix": unix_timestamp,
		"tutorial_completed": false,
		"tutorial_step": 0,
		"progression": {
			"unlocked_features": {
				"dine_in": true,
				"delivery": true,
				"burger_classic": true
			}
		},
		"reputation": 5.0,
		"game_clock": {
			"day_number": 1,
			"day_of_week": 4,
			"week_number": 1
		}
	}

	var temp_path = get_slot_temp_path(slot)
	var final_path = get_slot_path(slot)

	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(initial_data, "\t"))
	file.close()

	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(final_path)

	var rename_err = DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		return false

	has_active_game = true
	active_slot = slot
	pending_save_data = initial_data

	apply_save_data_to_game(initial_data)

	save_completed.emit(slot, true)
	return true

## Coleta dados reais dos subsistemas oficiais do jogo
func _collect_game_data(slot: int) -> Dictionary:
	var now_dict = Time.get_datetime_dict_from_system()
	var timestamp_str = "%02d/%02d/%04d %02d:%02d" % [
		now_dict["day"], now_dict["month"], now_dict["year"],
		now_dict["hour"], now_dict["minute"]
	]
	var unix_timestamp = int(Time.get_unix_time_from_system())

	# 1. Dinheiro via EconomyManager
	var current_money: float = pending_save_data.get("money", 100.0)
	var economy = _get_subsystem("EconomyManager")
	if economy and "current_money" in economy:
		current_money = economy.current_money

	# 2. Dia atual via GameClock
	var current_day: int = pending_save_data.get("current_day", pending_save_data.get("day", 1))
	var day_of_week: int = 4
	var week_number: int = 1
	var clock = _get_subsystem("GameClock")
	if clock:
		if "day_number" in clock:
			current_day = clock.day_number
		if "day_of_week" in clock:
			day_of_week = clock.day_of_week
		if "week_number" in clock:
			week_number = clock.week_number

	# 3. Desbloqueios via ProgressionManager
	var unlocked_features: Dictionary = {}
	var progression = _get_subsystem("ProgressionManager")
	if progression and "unlocked_features" in progression:
		unlocked_features = progression.unlocked_features.duplicate(true)

	# 4. Reputação via ReputationManager
	var reputation_stars: float = 5.0
	var reputation = _get_subsystem("ReputationManager")
	if reputation and "current_reputation" in reputation:
		reputation_stars = reputation.current_reputation

	# 5. Estado do Tutorial
	var tut_completed: bool = false
	var tut_step: int = 0
	
	var gm = _get_game_manager()
	var main_scene = gm.get_main_scene() if gm else null
	var tutorial_node = main_scene.get_node_or_null("Tutorial") if main_scene else null
	if tutorial_node:
		tut_completed = tutorial_node.get("tutorial_completed") if "tutorial_completed" in tutorial_node else false
		tut_step = tutorial_node.get("current_step_index") if "current_step_index" in tutorial_node else 0
	else:
		tut_completed = pending_save_data.get("tutorial_completed", false)
		tut_step = pending_save_data.get("tutorial_step", 0)

	# Preserva o player_name real!
	var player_name = pending_save_data.get("player_name", "Chefe")

	return {
		"save_version": SAVE_VERSION,
		"slot": slot,
		"has_game": true,
		"player_name": player_name,
		"current_day": current_day,
		"day": current_day,
		"money": current_money,
		"last_save_timestamp": timestamp_str,
		"last_save_unix": unix_timestamp,
		"tutorial_completed": tut_completed,
		"tutorial_step": tut_step,
		"progression": {
			"unlocked_features": unlocked_features
		},
		"reputation": reputation_stars,
		"game_clock": {
			"day_number": current_day,
			"day_of_week": day_of_week,
			"week_number": week_number
		}
	}

# =============================================================================
# CARREGAMENTO E RESTAURAÇÃO DE DADOS
# =============================================================================

## Carrega e valida os dados de um slot, preparando-os para aplicação
func load_game(slot: int = -1) -> Dictionary:
	var target_slot = active_slot if slot == -1 else slot
	if not has_valid_save(target_slot):
		printerr("[SaveManager] Tentativa de carregar save inválido no slot: ", target_slot)
		save_loaded.emit(target_slot, false)
		return {}

	var path = get_slot_path(target_slot)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		save_loaded.emit(target_slot, false)
		return {}

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK or not (json.data is Dictionary):
		save_loaded.emit(target_slot, false)
		return {}

	var save_data: Dictionary = json.data
	active_slot = target_slot
	has_active_game = true
	pending_save_data = save_data

	# Aplica diretamente aos subsistemas se a cena ativa já estiver presente
	apply_save_data_to_game(save_data)

	save_loaded.emit(target_slot, true)
	return save_data

## Restaura os dados carregados nos subsistemas reais do jogo
func apply_save_data_to_game(data: Dictionary) -> void:
	if data.is_empty():
		return

	# 1. Restaura Dinheiro no EconomyManager
	var economy = _get_subsystem("EconomyManager")
	if economy:
		var saved_money = data.get("money", 100.0)
		if "current_money" in economy:
			economy.current_money = saved_money
		if economy.has_signal("money_changed"):
			economy.money_changed.emit(saved_money, 0.0)

	# 2. Restaura Dia e Calendário no GameClock
	var clock = _get_subsystem("GameClock")
	if clock:
		var clock_data = data.get("game_clock", {})
		if "day_number" in clock:
			clock.day_number = clock_data.get("day_number", data.get("current_day", 1))
		if "day_of_week" in clock:
			clock.day_of_week = clock_data.get("day_of_week", 4)
		if "week_number" in clock:
			clock.week_number = clock_data.get("week_number", 1)

	# 3. Restaura Desbloqueios no ProgressionManager
	var progression = _get_subsystem("ProgressionManager")
	if progression:
		var prog_data = data.get("progression", {})
		var features = prog_data.get("unlocked_features", {})
		if "unlocked_features" in progression and not features.is_empty():
			for k in features:
				progression.unlocked_features[k] = features[k]

	# 4. Restaura Reputação no ReputationManager
	var reputation = _get_subsystem("ReputationManager")
	if reputation and "current_reputation" in reputation:
		reputation.current_reputation = data.get("reputation", 5.0)

## Exclui o save de um slot específico
func delete_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false

	var path = get_slot_path(slot)
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err == OK:
			if active_slot == slot:
				has_active_game = false
				pending_save_data = {}
			save_deleted.emit(slot)
			return true
	return false

# =============================================================================
# AUTO-SAVE E SAVE NO FINAL DO DIA
# =============================================================================

func _process(delta: float) -> void:
	if not has_active_game:
		return

	# Só processa auto-save se estiver em gameplay ativo e despausado
	var is_playing = false
	var gm = _get_game_manager()
	if gm and gm.has_method("is_playing"):
		is_playing = gm.is_playing() and not gm.is_paused()
	else:
		var tree = get_tree() if (is_inside_tree() and get_tree() != null) else null
		is_playing = (tree != null and not tree.paused)

	if not is_playing:
		return

	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		trigger_auto_save()

## Dispara o auto-save usando o slot ativo
func trigger_auto_save() -> bool:
	if not has_active_game or active_slot < 1 or active_slot > MAX_SLOTS:
		return false

	var success = save_game(active_slot)
	if success:
		auto_save_triggered.emit(active_slot)
	return success

## Notificação de encerramento do dia recebida do GameClock/GameManager
func on_day_ended(_summary = null) -> void:
	if has_active_game:
		save_game(active_slot)

# =============================================================================
# HELPERS DE RESOLUÇÃO
# =============================================================================

func _get_subsystem(node_name: String) -> Node:
	# 1. Tenta instâncias estáticas dos singletons dos subsistemas
	match node_name:
		"EconomyManager":
			var eco_script = load("res://src/economy/economy_manager.gd")
			if eco_script and "instance" in eco_script and eco_script.instance and is_instance_valid(eco_script.instance):
				return eco_script.instance
		"GameClock":
			var clock_script = load("res://src/time/game_clock.gd")
			if clock_script and "instance" in clock_script and clock_script.instance and is_instance_valid(clock_script.instance):
				return clock_script.instance
		"ProgressionManager":
			var prog_script = load("res://src/progression/progression_manager.gd")
			if prog_script and "instance" in prog_script and prog_script.instance and is_instance_valid(prog_script.instance):
				return prog_script.instance

	# 2. Tenta resolução via GameManager
	var gm = _get_game_manager()
	if gm and gm.has_method("get_subsystem"):
		var node = gm.get_subsystem(node_name)
		if node:
			return node

	# 3. Tenta árvore de nós ativa
	var tree = get_tree() if (is_inside_tree() and get_tree() != null) else (Engine.get_main_loop() as SceneTree)
	if tree and tree.root:
		var found = tree.root.find_child(node_name, true, false)
		if found:
			return found

	# 4. Tenta busca por nós irmãos
	var p = get_parent()
	if p:
		if p.name == node_name:
			return p
		for sibling in p.get_children():
			if sibling.name == node_name:
				return sibling

	return null

func _get_game_manager() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root:
		if get_tree().root.has_node("GameManager"):
			return get_tree().root.get_node("GameManager")
		for child in get_tree().root.get_children():
			if child.name == "GameManager" or child.get_script() == load("res://src/core/game_manager.gd"):
				return child
	var gm_script = load("res://src/core/game_manager.gd")
	if gm_script and "instance" in gm_script and gm_script.instance and is_instance_valid(gm_script.instance):
		return gm_script.instance
	return null
