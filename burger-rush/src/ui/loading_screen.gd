class_name LoadingScreenUI
extends Control

# =============================================================================
# BURGER RUSH — TELA DE CARREGAMENTO REAL E ASSÍNCRONA (FASE 3)
#
# Carrega recursos e cenas em background utilizando ResourceLoader threaded,
# com atualização visual de progresso, tempo mínimo de exibição seguro (sem
# atrasos artificiais longos) e transição fluida com o GameManager.
# =============================================================================

@onready var background_rect: TextureRect = $BackgroundRect
@onready var loading_container: VBoxContainer = find_child("LoadingContainer", true, false) as VBoxContainer
@onready var loading_label: Label = find_child("LoadingLabel", true, false) as Label
@onready var progress_bar: ProgressBar = find_child("ProgressBar", true, false) as ProgressBar
@onready var progress_label: Label = find_child("ProgressLabel", true, false) as Label
@onready var fade_overlay: ColorRect = $FadeOverlay

@export var target_scene_path: String = "res://src/main.tscn"
@export var min_display_time: float = 0.6  # Tempo mínimo para transição visualmente agradável

var _time_elapsed: float = 0.0
var _load_progress: Array = []
var _is_loading_completed: bool = false
var _loaded_resource: PackedScene = null
var _visual_progress: float = 0.0

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Burger Rush")
		if is_inside_tree() and get_tree() and get_tree().root:
			get_tree().root.title = "Burger Rush"

	# 1. Determina o destino a ser carregado
	_resolve_target_scene()

	# 2. Sincroniza estado com o GameManager
	var gm = _get_game_manager()
	if gm and gm.has_method("change_state"):
		gm.change_state(gm.get("GameState").LOADING if "GameState" in gm else 1)

	# 3. Inicializa elementos visuais
	if progress_bar:
		progress_bar.value = 0.0
	if progress_label:
		progress_label.text = "0%"

	# 4. Animação suave de entrada (Fade In)
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.25)

	# 5. Inicia o carregamento assíncrono real via ResourceLoader
	_start_threaded_loading()

func _resolve_target_scene() -> void:
	var gm = _get_game_manager()
	if gm and "pending_target_scene" in gm and gm.pending_target_scene != "":
		target_scene_path = gm.pending_target_scene
	elif target_scene_path == "":
		target_scene_path = "res://src/main.tscn"

func _start_threaded_loading() -> void:
	var gm = _get_game_manager()
	var state_name = "UNKNOWN"
	if gm and gm.has_method("get_state_name") and "current_state" in gm:
		state_name = gm.get_state_name(gm.current_state)
	print("[Loading] Solicitando carregamento da cena: ", target_scene_path, " | Estado GM: ", state_name)

	if not ResourceLoader.exists(target_scene_path):
		printerr("[Loading] Erro crítico: Cena de destino não encontrada: ", target_scene_path)
		return

	var err = ResourceLoader.load_threaded_request(target_scene_path, "PackedScene")
	print("[Loading] ResourceLoader.load_threaded_request resultado: ", err)
	if err != OK and err != ERR_ALREADY_IN_USE:
		printerr("[Loading] Erro ao iniciar carregamento de ", target_scene_path, " (Código: ", err, ")")

func _process(delta: float) -> void:
	_time_elapsed += delta

	# Pulso suave no texto "CARREGANDO..."
	if loading_label:
		var pulse = 0.75 + 0.25 * sin(_time_elapsed * 5.0)
		loading_label.modulate.a = pulse

	if _is_loading_completed:
		return

	# Se o recurso já foi carregado e armazenado, apenas anima a barra até 100% e conclui
	if _loaded_resource != null:
		_visual_progress = move_toward(_visual_progress, 100.0, delta * 180.0)
		if progress_bar:
			progress_bar.value = _visual_progress
		if progress_label:
			progress_label.text = "%d%%" % int(_visual_progress)

		if _time_elapsed >= min_display_time and _visual_progress >= 99.0:
			_is_loading_completed = true
			print("[Loading] Transição de carregamento concluída para: ", target_scene_path)
			_finish_loading()
		return

	var status = ResourceLoader.load_threaded_get_status(target_scene_path, _load_progress)

	var target_progress_val = 0.0
	if not _load_progress.is_empty():
		target_progress_val = _load_progress[0] * 100.0
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		target_progress_val = 100.0

	# Interpolação suave da barra de progresso visual
	_visual_progress = move_toward(_visual_progress, maxf(_visual_progress, target_progress_val), delta * 140.0)
	if progress_bar:
		progress_bar.value = _visual_progress
	if progress_label:
		progress_label.text = "%d%%" % int(_visual_progress)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_loaded_resource = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
			print("[Loading] Recurso carregado com sucesso pelo ResourceLoader: ", target_scene_path)
			if _time_elapsed >= min_display_time and _visual_progress >= 99.0:
				_is_loading_completed = true
				print("[Loading] Transição de carregamento concluída para: ", target_scene_path)
				_finish_loading()

		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass

		ResourceLoader.THREAD_LOAD_FAILED:
			printerr("[Loading] Falha fatal no carregamento da cena: ", target_scene_path, " Status: ", status)
			_is_loading_completed = true

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Aguarda até 5s caso a requisição inicial ainda esteja sendo enfileirada no pool
			if _time_elapsed > 5.0:
				printerr("[Loading] Timeout ao inicializar carregamento da cena: ", target_scene_path)
				_is_loading_completed = true

func _finish_loading() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.2)
		tw.tween_callback(_apply_scene_transition)
	else:
		_apply_scene_transition()

func _apply_scene_transition() -> void:
	var gm = _get_game_manager()
	var state_name = "UNKNOWN"
	if gm and gm.has_method("get_state_name") and "current_state" in gm:
		state_name = gm.get_state_name(gm.current_state)
	print("[Loading] Chamando transição final. complete_loading() | Estado GM: ", state_name)
	if gm and gm.has_method("complete_loading") and _loaded_resource:
		gm.complete_loading(_loaded_resource)
	elif _loaded_resource:
		get_tree().change_scene_to_packed(_loaded_resource)
	else:
		get_tree().change_scene_to_file(target_scene_path)

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
