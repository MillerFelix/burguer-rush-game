class_name OpenSign
extends StaticBody3D

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	var clock = GameClock.get_instance()
	if clock:
		clock.state_changed.connect(_on_clock_state_changed)
	_update_sign()

func get_interaction_prompt(player: Node = null) -> String:
	var clock = GameClock.get_instance()
	if not clock:
		return ""

	match clock.state:
		GameClock.State.PREPARATION:
			return "E — Abrir Restaurante Agora"
		GameClock.State.CLOSING:
			return "E — Encerrar o Dia"
		GameClock.State.OPEN:
			return "Restaurante Aberto (Fecha às %02d:%02d)" % [clock.closing_hour, clock.closing_minute]
		GameClock.State.CLOSED:
			return "Restaurante Fechado"
		_:
			return ""

func interact(player: Node3D) -> void:
	var clock = GameClock.get_instance()
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
		return

	var clock = GameClock.get_instance()
	if not clock:
		label_3d.text = "RESTAURANTE"
		return

	match clock.state:
		GameClock.State.PREPARATION:
			label_3d.text = "🟡 PREPARAÇÃO\n[E] Abrir Agora"
			label_3d.modulate = Color(1.0, 0.85, 0.2, 1)
		GameClock.State.OPEN:
			label_3d.text = "🟢 ABERTO\n09:00 - 18:00"
			label_3d.modulate = Color(0.2, 1.0, 0.4, 1)
		GameClock.State.CLOSING:
			label_3d.text = "🟠 ENCERRANDO\n[E] Finalizar Dia"
			label_3d.modulate = Color(1.0, 0.5, 0.2, 1)
		GameClock.State.CLOSED:
			label_3d.text = "🔴 FECHADO"
			label_3d.modulate = Color(1.0, 0.2, 0.2, 1)
