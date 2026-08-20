class_name OpenSign
extends StaticBody3D

# =============================================================================
# BURGER RUSH — PLACA DE ABERTURA / FECHAMENTO (CAVALETE DE MADEIRA)
#
# O texto é posicionado diretamente na face da lousa de ardósia escura,
# perfeitamente plano e rente à madeira (sem texturas corrompidas ou flutuação).
# =============================================================================

const GameClock = preload("res://src/time/game_clock.gd")

@onready var sign_content: Label3D = get_node_or_null("Model/EaselFront/ChalkAreaFront/SignContent")

func _ready() -> void:
	_ensure_clock_connection()
	_update_sign()

func _ensure_clock_connection() -> GameClock:
	var clock = GameClock.get_instance()
	if not clock and is_inside_tree():
		clock = get_tree().root.find_child("GameClock", true, false) as GameClock
	if clock and not clock.state_changed.is_connected(_on_clock_state_changed):
		clock.state_changed.connect(_on_clock_state_changed)
	return clock

func get_interaction_prompt(player: Node = null) -> String:
	var clock = _ensure_clock_connection()
	if not clock:
		return ""

	match clock.state:
		GameClock.State.PREPARATION:
			return "[E] Abrir restaurante"
		GameClock.State.OPEN:
			return "Restaurante Aberto (10:00 — 22:00)"
		GameClock.State.CLOSING:
			return "[E] Finalizar Dia"
		GameClock.State.CLOSED:
			return "Restaurante Fechado (10:00 — 22:00)"
		_:
			return ""

func interact(player: Node3D) -> void:
	var clock = _ensure_clock_connection()
	if not clock:
		return

	match clock.state:
		GameClock.State.PREPARATION:
			clock.open_restaurant()
			_update_sign()
		GameClock.State.CLOSING:
			clock.close_day()
			_update_sign()

func _on_clock_state_changed(_new_state: GameClock.State) -> void:
	_update_sign()

func _update_sign() -> void:
	if not sign_content:
		sign_content = get_node_or_null("Model/EaselFront/ChalkAreaFront/SignContent")
	if not sign_content:
		sign_content = find_child("SignContent", true, false) as Label3D
	if not sign_content:
		sign_content = find_child("Label3D", true, false) as Label3D

	if not sign_content:
		return

	var clock = _ensure_clock_connection()
	if not clock:
		sign_content.text = "★ BURGER RUSH ★\n\n🔴 FECHADO\n\nHORÁRIO DE FUNCIONAMENTO\n10:00 — 22:00\n\n[E] Abrir Restaurante"
		sign_content.modulate = Color(1.0, 0.94, 0.76, 1.0)
		return

	match clock.state:
		GameClock.State.PREPARATION:
			sign_content.text = "★ BURGER RUSH ★\n\n🔴 FECHADO\n\nHORÁRIO DE FUNCIONAMENTO\n10:00 — 22:00\n\n[E] Abrir Restaurante"
			sign_content.modulate = Color(1.0, 0.94, 0.76, 1.0)
		GameClock.State.OPEN:
			sign_content.text = "★ BURGER RUSH ★\n\n🟢 ABERTO\n\nHORÁRIO DE FUNCIONAMENTO\n10:00 — 22:00\n\nExpediente em Andamento"
			sign_content.modulate = Color(0.85, 1.0, 0.85, 1.0)
		GameClock.State.CLOSING:
			sign_content.text = "★ BURGER RUSH ★\n\n🟠 ENCERRANDO\n\nHORÁRIO DE FUNCIONAMENTO\n10:00 — 22:00\n\n[E] Finalizar Dia"
			sign_content.modulate = Color(1.0, 0.88, 0.65, 1.0)
		GameClock.State.CLOSED:
			sign_content.text = "★ BURGER RUSH ★\n\n🔴 FECHADO\n\nHORÁRIO DE FUNCIONAMENTO\n10:00 — 22:00\n\nExpediente Encerrado"
			sign_content.modulate = Color(0.95, 0.80, 0.80, 1.0)
