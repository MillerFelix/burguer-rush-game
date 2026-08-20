class_name MainMenuUI
extends Control

# =============================================================================
# BURGER RUSH — MENU PRINCIPAL FUNCIONAL (FASE 2 / FASE 5)
#
# Controla a interface do menu inicial, feedback visual e sonoro dos botões,
# painel de configurações de áudio, modal de seleção de slots e confirmação de
# substituição para Novo Jogo e Continuar.
# =============================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

enum SlotMode {
	NEW_GAME,
	CONTINUE
}

@onready var background_rect: TextureRect = $BackgroundRect
@onready var menu_container: VBoxContainer = $MenuCenter/MenuContainer
@onready var play_button: Button = $MenuCenter/MenuContainer/PlayButton
@onready var continue_button: Button = $MenuCenter/MenuContainer/ContinueButton
@onready var settings_button: Button = $MenuCenter/MenuContainer/SettingsButton
@onready var quit_button: Button = $MenuCenter/MenuContainer/QuitButton

# Painel de Configurações
@onready var settings_overlay: Control = $SettingsOverlay
@onready var master_slider: HSlider = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/MasterVolumeContainer/MasterSlider
@onready var master_value_label: Label = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/MasterVolumeContainer/HeaderBox/MasterValueLabel
@onready var music_slider: HSlider = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/MusicVolumeContainer/MusicSlider
@onready var music_value_label: Label = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/MusicVolumeContainer/HeaderBox/MusicValueLabel
@onready var sfx_slider: HSlider = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/SFXVolumeContainer/SFXSlider
@onready var sfx_value_label: Label = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/SFXVolumeContainer/HeaderBox/SFXValueLabel
@onready var back_settings_button: Button = $SettingsOverlay/CenterContainer/SettingsCard/MarginContainer/VBoxContainer/BackSettingsButton

# Modal de Seleção de Slots (Fase 5)
@onready var slot_select_overlay: ColorRect = $SlotSelectOverlay
@onready var slot_header_label: Label = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/SlotHeaderLabel
@onready var slot_sub_label: Label = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/SlotSubLabel
@onready var slot1_details: Label = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/SlotsHBox/Slot1Card/Margin/VBox/Slot1Details
@onready var slot1_button: Button = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/SlotsHBox/Slot1Card/Margin/VBox/Slot1Button
@onready var slot2_details: Label = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/SlotsHBox/Slot2Card/Margin/VBox/Slot2Details
@onready var slot2_button: Button = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/SlotsHBox/Slot2Card/Margin/VBox/Slot2Button
@onready var back_slot_select_button: Button = $SlotSelectOverlay/CenterContainer/SlotSelectCard/MarginContainer/VBoxContainer/BackSlotSelectButton

# Modal de Confirmação de Substituição de Save (Fase 5)
@onready var overwrite_confirm_overlay: ColorRect = $OverwriteConfirmOverlay
@onready var warn_message: Label = $OverwriteConfirmOverlay/CenterContainer/OverwriteCard/Margin/VBox/WarnMessage
@onready var cancel_overwrite_button: Button = $OverwriteConfirmOverlay/CenterContainer/OverwriteCard/Margin/VBox/HBox/CancelOverwriteButton
@onready var confirm_overwrite_button: Button = $OverwriteConfirmOverlay/CenterContainer/OverwriteCard/Margin/VBox/HBox/ConfirmOverwriteButton

var _ui_audio_player: AudioStreamPlayer = null
var _is_initialized: bool = false
var _current_slot_mode: SlotMode = SlotMode.NEW_GAME
var _pending_overwrite_slot: int = 1

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true

	# 1. Configuração do Player de Áudio UI
	_setup_audio_player()

	# 2. Notifica o GameManager do estado atual
	var gm = _get_game_manager()
	if gm and gm.has_method("change_state"):
		gm.change_state(gm.get("GameState").MAIN_MENU if "GameState" in gm else 2)

	# 3. Estado inicial do botão Continuar
	_update_continue_button_state()

	# 4. Conexão dos botões principais
	play_button.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_settings_button.pressed.connect(_on_back_settings_pressed)

	# Conexões da Seleção de Slots
	slot1_button.pressed.connect(func(): _on_slot_button_pressed(1))
	slot2_button.pressed.connect(func(): _on_slot_button_pressed(2))
	back_slot_select_button.pressed.connect(_on_back_slot_select_pressed)

	# Conexões da Confirmação de Sobrescrita
	cancel_overwrite_button.pressed.connect(_on_cancel_overwrite_pressed)
	confirm_overwrite_button.pressed.connect(_on_confirm_overwrite_pressed)

	# 5. Efeitos visuais e sonoros nos botões
	_setup_button_effects(play_button)
	_setup_button_effects(continue_button)
	_setup_button_effects(settings_button)
	_setup_button_effects(quit_button)
	_setup_button_effects(back_settings_button)
	_setup_button_effects(slot1_button)
	_setup_button_effects(slot2_button)
	_setup_button_effects(back_slot_select_button)
	_setup_button_effects(cancel_overwrite_button)
	_setup_button_effects(confirm_overwrite_button)

	# 6. Sliders de Configuração
	_setup_settings_sliders()

	# 7. Garante painéis de overlay ocultos no início
	if settings_overlay:
		settings_overlay.visible = false
	if slot_select_overlay:
		slot_select_overlay.visible = false
	if overwrite_confirm_overlay:
		overwrite_confirm_overlay.visible = false

func _setup_audio_player() -> void:
	if _ui_audio_player == null:
		_ui_audio_player = AudioStreamPlayer.new()
		_ui_audio_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(_ui_audio_player)

func _play_ui_sound(pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if _ui_audio_player and is_inside_tree() and _ui_audio_player.is_inside_tree():
		var stream = SoundSynthesizer.get_stream("ui_click")
		if stream:
			_ui_audio_player.stream = stream
			_ui_audio_player.pitch_scale = pitch
			_ui_audio_player.volume_db = vol_db
			_ui_audio_player.play()

func _setup_button_effects(button: Button) -> void:
	if button == null:
		return
	button.mouse_entered.connect(func():
		if not button.disabled:
			_play_ui_sound(1.4, -4.0)
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(button, "scale", Vector3(1.04, 1.04, 1.0), 0.12)
	)
	button.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(button, "scale", Vector3.ONE, 0.12)
	)

func _update_continue_button_state() -> void:
	var has_save = _check_save_exists()
	continue_button.disabled = not has_save
	if not has_save:
		continue_button.tooltip_text = "Nenhum jogo salvo encontrado. Inicie um Novo Jogo!"
	else:
		var sm = _get_save_manager()
		var slot = sm.get_latest_save_slot() if sm and sm.has_method("get_latest_save_slot") else 1
		var meta = sm.get_save_metadata(slot) if sm and sm.has_method("get_save_metadata") else {}
		var day = meta.get("current_day", 1)
		var money = meta.get("money", 100.0)
		continue_button.tooltip_text = "Continuar partida (Slot %d - Dia %d | $%.2f)" % [slot, day, money]

func _check_save_exists() -> bool:
	var sm = _get_save_manager()
	if sm and sm.has_method("has_any_save"):
		return sm.has_any_save()
	return false

# =============================================================================
# FLUXO DE NOVO JOGO E CONTINUAR COM SELEÇÃO DE SLOTS (FASE 5)
# =============================================================================

func _on_play_pressed() -> void:
	_play_ui_sound(1.0, 0.0)
	_current_slot_mode = SlotMode.NEW_GAME
	_open_slot_selection()

func _on_continue_pressed() -> void:
	if continue_button.disabled:
		return
	_play_ui_sound(1.0, 0.0)
	_current_slot_mode = SlotMode.CONTINUE
	_open_slot_selection()

func _open_slot_selection() -> void:
	_refresh_slots_ui()
	slot_select_overlay.visible = true
	if is_inside_tree():
		slot1_button.grab_focus()

func _refresh_slots_ui() -> void:
	var sm = _get_save_manager()

	if _current_slot_mode == SlotMode.NEW_GAME:
		slot_header_label.text = "NOVO JOGO — ESCOLHA UM SLOT"
		slot_sub_label.text = "Selecione o slot onde sua nova carreira será gravada:"
	else:
		slot_header_label.text = "CONTINUAR — ESCOLHA UMA CARREIRA"
		slot_sub_label.text = "Selecione a carreira que deseja continuar:"

	# Configura Slot 1
	_populate_slot_card(1, slot1_details, slot1_button, sm)
	# Configura Slot 2
	_populate_slot_card(2, slot2_details, slot2_button, sm)

func _populate_slot_card(slot: int, details_label: Label, button: Button, sm: Node) -> void:
	var meta = sm.get_save_metadata(slot) if sm and sm.has_method("get_save_metadata") else {"exists": false, "valid": false}

	if meta.get("valid", false):
		var chef = meta.get("player_name", "Chefe")
		var day = meta.get("current_day", 1)
		var money = meta.get("money", 100.0)
		var ts = meta.get("last_save_timestamp", "Desconhecido")
		details_label.text = "👨‍🍳 Chefe: %s\n📅 Dia: %d | 💵 R$ %.2f\n⏱️ %s" % [chef, day, money, ts]
		button.disabled = false
		button.text = "CARREGAR" if _current_slot_mode == SlotMode.CONTINUE else "SOBRESCREVER"
	else:
		details_label.text = "— Slot Vazio —\n\nNenhuma carreira salva"
		if _current_slot_mode == SlotMode.CONTINUE:
			button.disabled = true
			button.text = "VAZIO"
		else:
			button.disabled = false
			button.text = "CRIAR CARREIRA"

func _on_slot_button_pressed(slot: int) -> void:
	_play_ui_sound(1.0, 0.0)
	var sm = _get_save_manager()

	if _current_slot_mode == SlotMode.CONTINUE:
		# Continuar direto no slot escolhido
		slot_select_overlay.visible = false
		var gm = _get_game_manager()
		if gm and gm.has_method("continue_game"):
			gm.continue_game(slot)
		else:
			get_tree().change_scene_to_file("res://src/main.tscn")
	else:
		# Novo Jogo
		var has_valid = sm.has_valid_save(slot) if sm and sm.has_method("has_valid_save") else false
		if has_valid:
			# Slot ocupado: requer confirmação de substituição
			_pending_overwrite_slot = slot
			var meta = sm.get_save_metadata(slot)
			warn_message.text = "O Slot %d já possui uma carreira salva:\n(Chefe: %s | Dia %d | R$ %.2f)\n\nIniciar um novo jogo irá SUBSTITUIR os dados anteriores permanentemente.\n\nTem certeza que deseja substituir?" % [
				slot, meta.get("player_name", "Chefe"), meta.get("current_day", 1), meta.get("money", 100.0)
			]
			overwrite_confirm_overlay.visible = true
			if is_inside_tree():
				cancel_overwrite_button.grab_focus()
		else:
			# Slot vazio: segue direto para a história e criação do chefe
			slot_select_overlay.visible = false
			_start_story_for_slot(slot)

func _on_cancel_overwrite_pressed() -> void:
	_play_ui_sound(0.9, -2.0)
	overwrite_confirm_overlay.visible = false
	if is_inside_tree():
		slot1_button.grab_focus()

func _on_confirm_overwrite_pressed() -> void:
	_play_ui_sound(1.1, 0.0)
	overwrite_confirm_overlay.visible = false
	slot_select_overlay.visible = false
	_start_story_for_slot(_pending_overwrite_slot)

func _start_story_for_slot(slot: int) -> void:
	var gm = _get_game_manager()
	if gm and gm.has_method("start_story_flow"):
		gm.start_story_flow(slot)
	elif gm and gm.has_method("start_new_game"):
		gm.start_new_game(slot)
	else:
		get_tree().change_scene_to_file("res://src/ui/intro_story.tscn")

func _on_back_slot_select_pressed() -> void:
	_play_ui_sound(0.9, -2.0)
	slot_select_overlay.visible = false
	_update_continue_button_state()
	if is_inside_tree():
		play_button.grab_focus()

# =============================================================================
# PAINEL DE CONFIGURAÇÕES E SAÍDA
# =============================================================================

func _on_settings_pressed() -> void:
	_play_ui_sound(1.1, -1.0)
	settings_overlay.visible = true
	if is_inside_tree():
		back_settings_button.grab_focus()

func _on_back_settings_pressed() -> void:
	_play_ui_sound(0.9, -2.0)
	settings_overlay.visible = false
	if is_inside_tree():
		settings_button.grab_focus()

func _on_quit_pressed() -> void:
	_play_ui_sound(0.8, 0.0)
	get_tree().quit()

# =============================================================================
# SLIDERS DE CONFIGURAÇÕES DE ÁUDIO
# =============================================================================

func _setup_settings_sliders() -> void:
	if master_slider:
		master_slider.value = _get_bus_volume_linear("Master") * 100.0
		_update_slider_label(master_value_label, master_slider.value)
		master_slider.value_changed.connect(func(val):
			_set_bus_volume_linear("Master", val / 100.0)
			_update_slider_label(master_value_label, val)
		)

	if music_slider:
		music_slider.value = _get_bus_volume_linear("Music") * 100.0
		_update_slider_label(music_value_label, music_slider.value)
		music_slider.value_changed.connect(func(val):
			_set_bus_volume_linear("Music", val / 100.0)
			_update_slider_label(music_value_label, val)
		)

	if sfx_slider:
		sfx_slider.value = _get_bus_volume_linear("SFX") * 100.0
		_update_slider_label(sfx_value_label, sfx_slider.value)
		sfx_slider.value_changed.connect(func(val):
			_set_bus_volume_linear("SFX", val / 100.0)
			_update_slider_label(sfx_value_label, val)
			_play_ui_sound(1.2, -6.0)
		)

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

# =============================================================================
# RESOLUÇÃO DE SINGLETONS
# =============================================================================

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
