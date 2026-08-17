class_name MainPowerPanel
extends StaticBody3D

const PowerManager = preload("res://src/core/power_manager.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

# ================================================================
# QUADRO GERAL DE ENERGIA (PAINEL ELÉTRICO INDUSTRIAL EXTERNO)
#
# Localizado na parede externa próximo à saída do armazém e caminhão.
# Controla a chave geral do disjuntor principal do restaurante.
#
# Interação:
#  - Tecla [E] -> Alterna Ligar / Desligar Chave Geral
# ================================================================

const LEVER_ON_ROT_Z: float = 32.0
const LEVER_OFF_ROT_Z: float = -32.0
const LEVER_ANIM_SECS: float = 0.22

@onready var lever_pivot: Node3D = get_node_or_null("Model/Enclosure/LeverPivot")
@onready var led_green: MeshInstance3D = get_node_or_null("Model/Enclosure/LEDGreen")
@onready var led_red: MeshInstance3D = get_node_or_null("Model/Enclosure/LEDRed")
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

var is_animating: bool = false

func _ready() -> void:
	_setup_audio()
	var pm = PowerManager.get_instance()
	if pm:
		if not pm.power_state_changed.is_connected(_on_power_state_changed):
			pm.power_state_changed.connect(_on_power_state_changed)
		_apply_visual_state(pm.is_main_power_on, false)
	else:
		_apply_visual_state(false, false)

func _setup_audio() -> void:
	if not audio_player:
		audio_player = get_node_or_null("AudioStreamPlayer3D")
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioStreamPlayer3D"
		audio_player.unit_size = 3.0
		audio_player.max_distance = 18.0
		audio_player.volume_db = -3.0
		add_child(audio_player)

func get_interaction_prompt(player: Node = null) -> String:
	var pm = PowerManager.get_instance()
	var is_on = pm.is_main_power_on if pm else false
	if is_on:
		return "⚡ [E] Desligar Quadro Geral de Energia"
	else:
		return "⚡ [E] Ligar Quadro Geral de Energia"

func interact_equipment(player: Node3D) -> void:
	toggle_power(player)

func interact(player: Node3D) -> void:
	toggle_power(player)

func toggle_power(player: Node3D = null) -> void:
	if is_animating:
		return

	var pm = PowerManager.get_instance()
	if not pm:
		return

	var target_state = not pm.is_main_power_on
	pm.set_main_power(target_state)

	_play_breaker_sound(target_state)
	_apply_visual_state(target_state, true)

	if player:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			if target_state:
				hud.show_temporary_feedback("⚡ Quadro Geral Ligado — Rede Elétrica Ativa!")
			else:
				hud.show_temporary_feedback("⚪ Quadro Geral Desligado — Energia Cortada!")

func _on_power_state_changed(is_on: bool) -> void:
	_apply_visual_state(is_on, false)

func _apply_visual_state(is_on: bool, animate: bool) -> void:
	var target_rot = LEVER_ON_ROT_Z if is_on else LEVER_OFF_ROT_Z

	if animate and lever_pivot:
		is_animating = true
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(lever_pivot, "rotation_degrees:z", target_rot, LEVER_ANIM_SECS)
		tween.finished.connect(func(): is_animating = false)
	elif lever_pivot:
		lever_pivot.rotation_degrees.z = target_rot

	# Atualiza LEDs luminosos
	if led_green:
		var mat = led_green.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = is_on
	if led_red:
		var mat = led_red.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = not is_on

func _play_breaker_sound(is_on: bool) -> void:
	_setup_audio()
	if audio_player:
		var sound_id = "breaker_switch_on" if is_on else "breaker_switch_off"
		audio_player.stream = SoundSynthesizer.get_stream(sound_id)
		audio_player.pitch_scale = randf_range(0.98, 1.02)
		if audio_player.is_inside_tree():
			audio_player.play()
