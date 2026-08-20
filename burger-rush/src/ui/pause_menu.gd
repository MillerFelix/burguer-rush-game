class_name PauseMenu
extends CanvasLayer

# =============================================================================
# BURGER RUSH — MENU DE PAUSA (ESC)
#
# Process Mode: ALWAYS (opera mesmo com get_tree().paused = true)
# Suporta: Continuar, Configurações (Áudio/Vídeo), Voltar ao Menu (com save), Sair
# =============================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

@onready var dark_backdrop: ColorRect = get_node_or_null("DarkBackdrop")
@onready var main_card: PanelContainer = get_node_or_null("DarkBackdrop/MainCard")
@onready var continue_btn: Button = get_node_or_null("DarkBackdrop/MainCard/VBox/BtnMargin/BtnVBox/ContinueButton")
@onready var settings_btn: Button = get_node_or_null("DarkBackdrop/MainCard/VBox/BtnMargin/BtnVBox/SettingsButton")
@onready var skip_tutorial_btn: Button = get_node_or_null("DarkBackdrop/MainCard/VBox/BtnMargin/BtnVBox/SkipTutorialButton")
@onready var menu_btn: Button = get_node_or_null("DarkBackdrop/MainCard/VBox/BtnMargin/BtnVBox/MenuButton")
@onready var quit_btn: Button = get_node_or_null("DarkBackdrop/MainCard/VBox/BtnMargin/BtnVBox/QuitButton")

# Overlays Secundários
@onready var settings_overlay: PanelContainer = $DarkBackdrop/SettingsCard
@onready var master_slider: HSlider = $DarkBackdrop/SettingsCard/VBox/MasterRow/MasterSlider
@onready var master_val_lbl: Label = $DarkBackdrop/SettingsCard/VBox/MasterRow/MasterValue
@onready var music_slider: HSlider = $DarkBackdrop/SettingsCard/VBox/MusicRow/MusicSlider
@onready var music_val_lbl: Label = $DarkBackdrop/SettingsCard/VBox/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $DarkBackdrop/SettingsCard/VBox/SFXRow/SFXSlider
@onready var sfx_val_lbl: Label = $DarkBackdrop/SettingsCard/VBox/SFXRow/SFXValue
@onready var fullscreen_chk: CheckBox = $DarkBackdrop/SettingsCard/VBox/FullscreenRow/FullscreenCheck
@onready var back_settings_btn: Button = $DarkBackdrop/SettingsCard/VBox/BackSettingsButton

@onready var confirm_overlay: PanelContainer = $DarkBackdrop/ConfirmCard
@onready var confirm_title_lbl: Label = $DarkBackdrop/ConfirmCard/VBox/ConfirmTitle
@onready var confirm_msg_lbl: Label = $DarkBackdrop/ConfirmCard/VBox/ConfirmMessage
@onready var confirm_ok_btn: Button = $DarkBackdrop/ConfirmCard/VBox/HBox/ConfirmOkButton
@onready var confirm_cancel_btn: Button = $DarkBackdrop/ConfirmCard/VBox/HBox/ConfirmCancelButton

var _ui_audio_player: AudioStreamPlayer = null
var _pending_confirm_action: String = "" # "MENU", "QUIT" ou "SKIP_TUTORIAL"
var is_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_setup_audio()
	_setup_signals()
	_setup_settings_sliders()

func _setup_audio() -> void:
	if not _ui_audio_player:
		_ui_audio_player = AudioStreamPlayer.new()
		_ui_audio_player.name = "PauseUIAudio"
		_ui_audio_player.bus = "SFX"
		_ui_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_ui_audio_player)

func _play_ui_sound(pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if _ui_audio_player:
		_ui_audio_player.stream = SoundSynthesizer.get_stream("ui_click")
		_ui_audio_player.pitch_scale = pitch
		_ui_audio_player.volume_db = volume_db
		_ui_audio_player.play()

func _setup_signals() -> void:
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if skip_tutorial_btn:
		skip_tutorial_btn.pressed.connect(_on_skip_tutorial_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if back_settings_btn:
		back_settings_btn.pressed.connect(_on_back_settings_pressed)
	if confirm_ok_btn:
		confirm_ok_btn.pressed.connect(_on_confirm_ok_pressed)
	if confirm_cancel_btn:
		confirm_cancel_btn.pressed.connect(_on_confirm_cancel_pressed)
	if fullscreen_chk:
		fullscreen_chk.toggled.connect(_on_fullscreen_toggled)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Se uma janela interna do jogo estiver consumindo o ESC (ex: PC administrativo, Modal do Dia Encerrado, etc.), não intercepta
		var comp_ui = get_tree().root.find_child("ComputerUI", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
		if comp_ui and comp_ui.visible:
			return

		var hud = get_tree().root.find_child("HUD", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
		if hud:
			if hud.get("report_modal") and hud.report_modal.visible:
				return
			if hud.get("day1_welcome_modal") and hud.day1_welcome_modal.visible:
				return
			if hud.get("daily_notice_modal") and hud.daily_notice_modal.visible:
				return

		if visible:
			if confirm_overlay.visible:
				_on_confirm_cancel_pressed()
			elif settings_overlay.visible:
				_on_back_settings_pressed()
			else:
				resume_game()
			get_viewport().set_input_as_handled()
		else:
			# Abre menu de pausa
			pause_game()
			get_viewport().set_input_as_handled()

func pause_game() -> void:
	is_active = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_play_ui_sound(1.1, -1.0)
	
	main_card.visible = true
	settings_overlay.visible = false
	confirm_overlay.visible = false
	
	# Exibe o botão "Pular Tutorial" somente se estivermos ativamente no tutorial
	var tut = get_tree().root.find_child("Tutorial", true, false) if (is_inside_tree() and get_tree()) else null
	var in_tutorial = (tut != null and is_instance_valid(tut) and not tut.get("tutorial_completed"))
	if skip_tutorial_btn:
		skip_tutorial_btn.visible = in_tutorial
	
	if continue_btn and is_inside_tree():
		continue_btn.grab_focus()

func resume_game() -> void:
	is_active = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_play_ui_sound(0.9, -2.0)

	var gm = get_tree().root.find_child("GameManager", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
	if gm and gm.has_method("change_state") and "GameState" in gm:
		var tut = get_tree().root.find_child("Tutorial", true, false) if (is_inside_tree() and get_tree()) else null
		var in_tut = (tut != null and is_instance_valid(tut) and not tut.get("tutorial_completed"))
		gm.change_state(gm.GameState.TUTORIAL if in_tut else gm.GameState.PLAYING)

func _on_continue_pressed() -> void:
	resume_game()

func _on_settings_pressed() -> void:
	_play_ui_sound(1.0, 0.0)
	main_card.visible = false
	settings_overlay.visible = true
	_refresh_settings_values()
	if back_settings_btn and is_inside_tree():
		back_settings_btn.grab_focus()

func _on_skip_tutorial_pressed() -> void:
	_play_ui_sound(1.0, 0.0)
	_pending_confirm_action = "SKIP_TUTORIAL"
	confirm_title_lbl.text = "PULAR O TUTORIAL?"
	confirm_msg_lbl.text = "Você poderá começar o Dia 1 imediatamente, mas algumas mecânicas ainda não terão sido apresentadas."
	main_card.visible = false
	confirm_overlay.visible = true
	if confirm_cancel_btn and is_inside_tree():
		confirm_cancel_btn.grab_focus()

func _on_back_settings_pressed() -> void:
	_play_ui_sound(0.9, -2.0)
	settings_overlay.visible = false
	main_card.visible = true
	if settings_btn and is_inside_tree():
		settings_btn.grab_focus()

func _on_menu_pressed() -> void:
	_play_ui_sound(1.0, 0.0)
	_pending_confirm_action = "MENU"
	confirm_title_lbl.text = "VOLTAR AO MENU PRINCIPAL"
	confirm_msg_lbl.text = "Deseja realmente voltar ao menu?\nSeu progresso mais recente será salvo automaticamente."
	main_card.visible = false
	confirm_overlay.visible = true
	if confirm_cancel_btn and is_inside_tree():
		confirm_cancel_btn.grab_focus()

func _on_quit_pressed() -> void:
	_play_ui_sound(1.0, 0.0)
	_pending_confirm_action = "QUIT"
	confirm_title_lbl.text = "SAIR DO JOGO"
	confirm_msg_lbl.text = "Deseja realmente fechar o Burger Rush?\nO progresso salvo nesta sessão será preservado."
	main_card.visible = false
	confirm_overlay.visible = true
	if confirm_cancel_btn and is_inside_tree():
		confirm_cancel_btn.grab_focus()

func _on_confirm_ok_pressed() -> void:
	_play_ui_sound(1.0, 0.0)
	_save_current_game_state()
	
	if _pending_confirm_action == "MENU":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
	elif _pending_confirm_action == "QUIT":
		get_tree().quit()
	elif _pending_confirm_action == "SKIP_TUTORIAL":
		confirm_overlay.visible = false
		visible = false
		get_tree().paused = false
		var tut = get_tree().root.find_child("Tutorial", true, false) if (is_inside_tree() and get_tree()) else null
		if tut and is_instance_valid(tut):
			tut._on_confirm_skip_pressed()
		else:
			var sm = _get_save_manager()
			if sm and sm.has_active_game:
				sm.pending_save_data["tutorial_step"] = 15
				sm.pending_save_data["tutorial_completed"] = true
				sm.pending_save_data["day1_intro_shown"] = false
				sm.pending_save_data["clock_hour"] = 9
				sm.pending_save_data["clock_minute"] = 0
				sm.pending_save_data["clock_state"] = "PREPARATION"
				sm.save_game(sm.active_slot)
			
			var gm = get_tree().root.find_child("GameManager", true, false) if (is_inside_tree() and get_tree()) else null
			if not gm:
				var gm_class = load("res://src/core/game_manager.gd")
				if gm_class and gm_class.has_method("get_instance"):
					gm = gm_class.get_instance()
			
			if gm and gm.has_method("load_scene_with_loading"):
				gm.load_scene_with_loading("main", gm.GameState.PLAYING)
			else:
				get_tree().change_scene_to_file("res://src/ui/loading_screen.tscn")

func _on_confirm_cancel_pressed() -> void:
	_play_ui_sound(0.9, -2.0)
	confirm_overlay.visible = false
	main_card.visible = true
	if continue_btn and is_inside_tree():
		continue_btn.grab_focus()

func _get_save_manager():
	var sm = get_tree().root.find_child("SaveManager", true, false) if (is_inside_tree() and get_tree()) else null
	if not sm:
		var sm_class = preload("res://src/core/save_manager.gd")
		if sm_class and "instance" in sm_class:
			sm = sm_class.instance
	return sm

func _save_current_game_state() -> void:
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		sm.save_game(sm.active_slot)

# =============================================================================
# CONFIGURAÇÕES DE ÁUDIO E VÍDEO
# =============================================================================

func _setup_settings_sliders() -> void:
	if master_slider:
		master_slider.value_changed.connect(func(val):
			_set_bus_volume_linear("Master", val / 100.0)
			_update_slider_label(master_val_lbl, val)
		)
	if music_slider:
		music_slider.value_changed.connect(func(val):
			_set_bus_volume_linear("Music", val / 100.0)
			_update_slider_label(music_val_lbl, val)
		)
	if sfx_slider:
		sfx_slider.value_changed.connect(func(val):
			_set_bus_volume_linear("SFX", val / 100.0)
			_update_slider_label(sfx_val_lbl, val)
			_play_ui_sound(1.2, -6.0)
		)

func _refresh_settings_values() -> void:
	if master_slider:
		master_slider.value = _get_bus_volume_linear("Master") * 100.0
		_update_slider_label(master_val_lbl, master_slider.value)
	if music_slider:
		music_slider.value = _get_bus_volume_linear("Music") * 100.0
		_update_slider_label(music_val_lbl, music_slider.value)
	if sfx_slider:
		sfx_slider.value = _get_bus_volume_linear("SFX") * 100.0
		_update_slider_label(sfx_val_lbl, sfx_slider.value)
	if fullscreen_chk:
		fullscreen_chk.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_fullscreen_toggled(is_fs: bool) -> void:
	_play_ui_sound(1.0, 0.0)
	if is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _update_slider_label(label: Label, value: float) -> void:
	if label:
		label.text = "%d%%" % int(value)

func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var db = AudioServer.get_bus_volume_db(bus_idx)
		return db_to_linear(db)
	return 1.0

func _set_bus_volume_linear(bus_name: String, linear_val: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var db = linear_to_db(clampf(linear_val, 0.0001, 1.0)) if linear_val > 0.001 else -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, linear_val <= 0.001)
