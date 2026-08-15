class_name OpenSign
extends StaticBody3D

@onready var label_3d: Label3D = $Label3D

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
	if not label_3d:
		label_3d = get_node_or_null("Label3D")
	if not label_3d:
		return

	var clock = _ensure_clock_connection()
	if not clock:
		label_3d.text = "BURGER RUSH\n\nFECHADO\n\n10:00 — 22:00"
		label_3d.modulate = Color(0.95, 0.95, 0.95, 1.0)
		return

	match clock.state:
		GameClock.State.PREPARATION:
			label_3d.text = "BURGER RUSH\n\nFECHADO\n\n10:00 — 22:00\n\n[E] Abrir Restaurante"
			label_3d.modulate = Color(1.0, 0.92, 0.75, 1.0)
		GameClock.State.OPEN:
			label_3d.text = "BURGER RUSH\n\n🟢 ABERTO\n\n10:00 — 22:00"
			label_3d.modulate = Color(0.85, 1.0, 0.85, 1.0)
		GameClock.State.CLOSING:
			label_3d.text = "BURGER RUSH\n\n🟠 ENCERRANDO\n\n10:00 — 22:00\n\n[E] Finalizar Dia"
			label_3d.modulate = Color(1.0, 0.85, 0.65, 1.0)
		GameClock.State.CLOSED:
			label_3d.text = "BURGER RUSH\n\n🔴 FECHADO\n\n10:00 — 22:00"
			label_3d.modulate = Color(0.95, 0.80, 0.80, 1.0)
