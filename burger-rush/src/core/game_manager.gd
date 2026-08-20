extends Node

# =============================================================================
# BURGER RUSH — GERENCIADOR CENTRAL DE ESTADO DO JOGO (FASE 1)
#
# Singleton / Autoload central responsável por coordenar os estados de alto nível
# da aplicação, transições seguras de cena e ciclo de vida do jogo.
#
# NÃO substitui nem centraliza a lógica interna dos subsistemas especializados
# (GameClock, EconomyManager, InventoryManager, OrderManager, ProgressionManager, etc.).
# =============================================================================

enum GameState {
	BOOT,           # Inicialização da engine e verificação de recursos
	LOADING,        # Carregamento de cenas e assets
	MAIN_MENU,      # Menu principal (Título, Novo Jogo, Continuar, Opções)
	NEW_GAME,       # Fluxo de preparação de nova partida
	STORY,          # Introdução narrativa / Cutscene
	TUTORIAL,       # Tutorial guiado do primeiro dia
	PLAYING,        # Gameplay ativo no restaurante
	PAUSED,         # Jogo pausado
	DAY_END,        # Encerramento do expediente e resumo diário
	LOADING_SAVE    # Carregamento de progresso salvo
}

signal state_changed(old_state: GameState, new_state: GameState)
signal game_paused(is_paused: bool)
signal scene_transition_started(target_scene_path: String)
signal scene_transition_finished(target_scene_path: String)

static var instance: GameManager = null

var current_state: GameState = GameState.BOOT
var previous_state: GameState = GameState.BOOT

var pending_target_scene: String = "res://src/main.tscn"
var pending_target_state: GameState = GameState.PLAYING

## Dicionário de caminhos de cena padrão do projeto para transições centralizadas
const SCENE_PATHS: Dictionary = {
	"main": "res://src/main.tscn",
	"menu": "res://src/ui/main_menu.tscn",
	"loading": "res://src/ui/loading_screen.tscn",
	"story": "res://src/ui/intro_story.tscn",
	"tutorial": "res://src/tutorial/tutorial_intro.tscn"
}

func _init() -> void:
	instance = self

func _enter_tree() -> void:
	instance = self
	_enforce_clean_window_title()

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance() -> GameManager:
	if instance and is_instance_valid(instance):
		return instance
	var ml = Engine.get_main_loop()
	if ml and ml is SceneTree:
		var tree = ml as SceneTree
		if tree.root:
			var found = tree.root.find_child("GameManager", true, false)
			if found:
				instance = found
				return instance
	return instance

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enforce_clean_window_title()
	var sm = _get_save_manager()
	if not sm:
		var sm_class = load("res://src/core/save_manager.gd")
		if sm_class:
			var sm_node = sm_class.new()
			sm_node.name = "SaveManager"
			add_child(sm_node)
	_initialize_game_state()

func _process(_delta: float) -> void:
	_enforce_clean_window_title()

func _enforce_clean_window_title() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Burger Rush")
		var tree = get_tree() if (is_inside_tree() and get_tree() != null) else (Engine.get_main_loop() as SceneTree)
		if tree and tree.root and tree.root.title != "Burger Rush":
			tree.root.title = "Burger Rush"

## Inicializa o estado de acordo com a cena em execução
func _initialize_game_state() -> void:
	var current_scene = get_tree().current_scene if (is_inside_tree() and get_tree() != null) else null
	if current_scene:
		if current_scene.name == "MainMenu" or current_scene is MainMenuUI:
			change_state(GameState.MAIN_MENU)
		elif current_scene.name == "Main" or current_scene.has_node("GameClock"):
			change_state(GameState.PLAYING)
		else:
			change_state(GameState.BOOT)
	else:
		change_state(GameState.BOOT)

## Altera o estado do jogo e notifica os ouvintes
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)

## Retorna o estado atual
func get_state() -> GameState:
	return current_state

## Retorna o nome textual legível do estado atual
func get_state_name(state_enum: int = -1) -> String:
	var s = current_state if state_enum == -1 else state_enum
	match s:
		GameState.BOOT: return "BOOT"
		GameState.LOADING: return "LOADING"
		GameState.MAIN_MENU: return "MAIN_MENU"
		GameState.NEW_GAME: return "NEW_GAME"
		GameState.STORY: return "STORY"
		GameState.TUTORIAL: return "TUTORIAL"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.DAY_END: return "DAY_END"
		GameState.LOADING_SAVE: return "LOADING_SAVE"
		_: return "UNKNOWN"

## Verifica se o jogador está ativamente jogando
func is_playing() -> bool:
	return current_state == GameState.PLAYING

## Verifica se o jogo está pausado
func is_paused() -> bool:
	if current_state == GameState.PAUSED:
		return true
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	return tree.paused if tree else false

## Pausa ou despausa a árvore de cena do jogo
func set_pause(paused: bool) -> void:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = paused
	if paused:
		if current_state == GameState.PLAYING:
			change_state(GameState.PAUSED)
	else:
		if current_state == GameState.PAUSED:
			change_state(GameState.PLAYING)
	game_paused.emit(paused)

## Alterna o estado de pausa
func toggle_pause() -> void:
	set_pause(not is_paused())

# =============================================================================
# TRANSIÇÃO CENTRALIZADA DE CENAS
# =============================================================================

## Transita com segurança para outra cena por chave ou caminho de arquivo
func change_scene(scene_key_or_path: String, target_state: GameState = GameState.PLAYING) -> bool:
	var target_path = SCENE_PATHS.get(scene_key_or_path, scene_key_or_path)

	if not ResourceLoader.exists(target_path):
		printerr("[GameManager] Erro: Cena não encontrada: %s" % target_path)
		return false

	scene_transition_started.emit(target_path)
	change_state(GameState.LOADING)

	# Executa a troca de cena no próximo ciclo seguro da engine
	call_deferred("_deferred_change_scene", target_path, target_state)
	return true

func _deferred_change_scene(target_path: String, target_state: GameState) -> void:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if not tree:
		printerr("[GameManager] Erro: SceneTree inacessível para troca de cena.")
		change_state(previous_state)
		return

	var err = tree.change_scene_to_file(target_path)
	if err == OK:
		change_state(target_state)
		scene_transition_finished.emit(target_path)
	else:
		printerr("[GameManager] Falha ao transitar para cena %s (Erro: %d)" % [target_path, err])
		change_state(previous_state)

# =============================================================================
# ACESSORES CONVENIENTES PARA OS SUBSISTEMAS DO MUNDO ATUAL
# =============================================================================

## Obtém o nó raiz da cena principal (Main)
func get_main_scene() -> Node:
	var tree: SceneTree = null
	if is_inside_tree() and get_tree() != null:
		tree = get_tree()
	else:
		var main_loop = Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop as SceneTree

	if tree:
		if tree.current_scene:
			return tree.current_scene
		if tree.root:
			for child in tree.root.get_children():
				if child == self:
					continue
				if child.has_node("GameClock") or child.name == "Main" or child.name.to_lower().contains("main"):
					return child

	# Fallback seguro para resolução por parent/irmãos
	var p = get_parent()
	if p:
		if p.has_node("GameClock"):
			return p
		for sibling in p.get_children():
			if sibling != self and (sibling.has_node("GameClock") or sibling.name == "Main" or sibling.name.to_lower().contains("main")):
				return sibling

	return null

## Busca nós dos subsistemas dinamicamente no grafo da cena atual
func get_subsystem(node_path_or_group: String) -> Node:
	var current = get_main_scene()
	if current:
		if current.has_node(node_path_or_group):
			return current.get_node(node_path_or_group)
		var found = current.find_child(node_path_or_group, true, false)
		if found:
			return found
	var tree: SceneTree = null
	if is_inside_tree() and get_tree() != null:
		tree = get_tree()
	else:
		var main_loop = Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop as SceneTree

	if tree:
		if tree.root:
			var root_found = tree.root.find_child(node_path_or_group, true, false)
			if root_found:
				return root_found
		var in_group = tree.get_nodes_in_group(node_path_or_group)
		if not in_group.is_empty():
			return in_group[0]
	return null

func get_game_clock() -> Node:
	return get_subsystem("GameClock")

func get_economy_manager() -> Node:
	return get_subsystem("EconomyManager")

func get_inventory_manager() -> Node:
	return get_subsystem("InventoryManager")

func get_order_manager() -> Node:
	return get_subsystem("OrderManager")

func get_progression_manager() -> Node:
	return get_subsystem("ProgressionManager")

func get_player() -> Node:
	return get_subsystem("Player")

# =============================================================================
# INTERFACES PREPARADAS PARA AS PRÓXIMAS FASES (Hooks Não-Intrusivos)
# =============================================================================

## Transita para a cena desejada passando pela Loading Screen assíncrona
func load_scene_with_loading(scene_key_or_path: String, target_state: GameState = GameState.PLAYING) -> bool:
	var target_path = SCENE_PATHS.get(scene_key_or_path, scene_key_or_path)
	pending_target_scene = target_path
	pending_target_state = target_state
	return change_scene("loading", GameState.LOADING)

## Finaliza o carregamento da cena instanciando o PackedScene gerado pelo ResourceLoader
func complete_loading(loaded_scene: PackedScene) -> void:
	var tree: SceneTree = null
	if is_inside_tree() and get_tree() != null:
		tree = get_tree()
	else:
		var loop = Engine.get_main_loop()
		if loop is SceneTree:
			tree = loop as SceneTree

	if tree and loaded_scene:
		tree.change_scene_to_packed(loaded_scene)

	change_state(pending_target_state)

	if pending_target_state == GameState.TUTORIAL:
		call_deferred("_instantiate_tutorial")

	# Restaura dados pendentes do save se houver
	var save_mgr = _get_save_manager()
	if save_mgr and "pending_save_data" in save_mgr and not save_mgr.pending_save_data.is_empty():
		call_deferred("_deferred_apply_save")

	scene_transition_finished.emit(pending_target_scene)

func _instantiate_tutorial() -> void:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if not tree:
		return

	# Aguarda de forma assíncrona até que o nó Main esteja instanciado e presente na árvore
	var attempts = 0
	while attempts < 120:
		var main_node = tree.current_scene
		if not main_node or main_node.scene_file_path == "res://src/ui/loading_screen.tscn" or main_node.name == "LoadingScreen":
			if tree.root and tree.root.has_node("Main"):
				main_node = tree.root.get_node("Main")
			elif tree.root:
				for child in tree.root.get_children():
					if child.name == "Main" or child.scene_file_path == "res://src/main.tscn":
						main_node = child
						break

		if main_node and (main_node.name == "Main" or main_node.scene_file_path == "res://src/main.tscn"):
			if main_node.has_node("Tutorial"):
				print("[GameManager] Tutorial já presente na cena Main.")
				return
			var tut_scene = load("res://src/ui/tutorial.tscn")
			if tut_scene:
				var tut_inst = tut_scene.instantiate()
				tut_inst.name = "Tutorial"
				main_node.add_child(tut_inst)
				print("[GameManager] Tutorial instanciado com sucesso como filho de: ", main_node.name)
				return
		await tree.process_frame
		attempts += 1
	printerr("[GameManager] Erro: Cena Main não foi encontrada para instanciar o Tutorial.")

func _deferred_apply_save() -> void:
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.has_method("apply_save_data_to_game") and not save_mgr.pending_save_data.is_empty():
		save_mgr.apply_save_data_to_game(save_mgr.pending_save_data)

## Hook para o encerramento do dia (chamado pelo GameClock e salvo pelo SaveManager)
func notify_day_ended(day_number: int) -> void:
	change_state(GameState.DAY_END)
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.has_method("on_day_ended"):
		save_mgr.on_day_ended(day_number)

## Hook para início de novo jogo a ser chamado pelo Menu Principal (Fase 5)
func start_new_game(slot: int = 1) -> void:
	start_story_flow(slot)

## Inicia o fluxo narrativo de Novo Jogo no slot escolhido (Fase 5)
func start_story_flow(slot: int = 1) -> void:
	change_state(GameState.NEW_GAME)
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.has_method("set_active_slot"):
		save_mgr.set_active_slot(slot)
	load_scene_with_loading("story", GameState.STORY)

## Finaliza a criação da carreira e transita para a preparação do tutorial (Fase 5/6)
func finish_new_game_creation(slot: int = 1) -> void:
	change_state(GameState.TUTORIAL)
	load_scene_with_loading("main", GameState.TUTORIAL)

## Hook para continuar jogo a ser chamado pelo Menu Principal (Fase 4/5)
func continue_game(slot: int = -1) -> void:
	change_state(GameState.LOADING_SAVE)
	var save_mgr = _get_save_manager()
	var target_state = GameState.PLAYING
	if save_mgr:
		var target_slot = slot
		if target_slot == -1 and save_mgr.has_method("get_latest_save_slot"):
			target_slot = save_mgr.get_latest_save_slot()
		if save_mgr.has_method("load_game"):
			var save_data = save_mgr.load_game(target_slot)
			if not save_data.is_empty():
				if not save_data.get("tutorial_completed", false):
					target_state = GameState.TUTORIAL
	load_scene_with_loading("main", target_state)

func _get_save_manager() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root:
		if get_tree().root.has_node("SaveManager"):
			return get_tree().root.get_node("SaveManager")
		for child in get_tree().root.get_children():
			if child.name == "SaveManager" or child.get_script() == load("res://src/core/save_manager.gd"):
				return child
	var sm_script = load("res://src/core/save_manager.gd")
	if sm_script and "instance" in sm_script and sm_script.instance and is_instance_valid(sm_script.instance):
		return sm_script.instance
	return null
