class_name ScreenManager
extends Node

# =============================================================================
# BURGER RUSH - GERENCIADOR DE TELA E RESOLUÇÃO (DESKTOP)
#
# Controla o modo de exibição (Tela Cheia, Janela Sem Bordas, Janela),
# detecta automaticamente a resolução do monitor desktop e adapta a interface.
# Permite alternância com F11 ou Alt+Enter.
# =============================================================================

static var instance: ScreenManager = null

signal display_mode_changed(mode: DisplayServer.WindowMode)

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance() -> ScreenManager:
	return instance

func _ready() -> void:
	apply_initial_fullscreen()

func apply_initial_fullscreen() -> void:
	var screen_id = DisplayServer.window_get_current_screen()
	if screen_id < 0:
		screen_id = DisplayServer.SCREEN_PRIMARY
	var screen_size = DisplayServer.screen_get_size(screen_id)
	if screen_size == Vector2i.ZERO:
		screen_size = Vector2i(1920, 1080)
	
	print("[DISPLAY] Resolução do monitor detectada: %dx%d (Screen #%d)" % [screen_size.x, screen_size.y, screen_id])
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("[DISPLAY] Jogo configurado para iniciar em Tela Cheia (Fullscreen) adaptativa.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		set_windowed()
	else:
		set_fullscreen()

func set_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	display_mode_changed.emit(DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("[DISPLAY] Modo alterado para: Tela Cheia (Fullscreen)")

func set_exclusive_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	display_mode_changed.emit(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	print("[DISPLAY] Modo alterado para: Tela Cheia Exclusiva")

func set_borderless_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	var screen_id = DisplayServer.window_get_current_screen()
	if screen_id < 0:
		screen_id = DisplayServer.SCREEN_PRIMARY
	var screen_size = DisplayServer.screen_get_size(screen_id)
	if screen_size == Vector2i.ZERO:
		screen_size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(screen_size)
	DisplayServer.window_set_position(Vector2i.ZERO)
	display_mode_changed.emit(DisplayServer.WINDOW_MODE_WINDOWED)
	print("[DISPLAY] Modo alterado para: Janela Sem Bordas (Borderless)")

func set_windowed(custom_size: Vector2i = Vector2i(1600, 900)) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(custom_size)
	
	var screen_id = DisplayServer.window_get_current_screen()
	if screen_id < 0:
		screen_id = DisplayServer.SCREEN_PRIMARY
	var screen_size = DisplayServer.screen_get_size(screen_id)
	if screen_size != Vector2i.ZERO:
		var pos = (screen_size - custom_size) / 2
		DisplayServer.window_set_position(pos)
	
	display_mode_changed.emit(DisplayServer.WINDOW_MODE_WINDOWED)
	print("[DISPLAY] Modo alterado para: Janela (%dx%d)" % [custom_size.x, custom_size.y])

func get_current_resolution() -> Vector2i:
	return DisplayServer.window_get_size()

func get_monitor_resolution() -> Vector2i:
	var screen_id = DisplayServer.window_get_current_screen()
	if screen_id < 0:
		screen_id = DisplayServer.SCREEN_PRIMARY
	var size = DisplayServer.screen_get_size(screen_id)
	if size == Vector2i.ZERO:
		size = Vector2i(1920, 1080)
	return size
