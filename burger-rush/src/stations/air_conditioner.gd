class_name AirConditioner
extends StaticBody3D

const PowerManager = preload("res://src/core/power_manager.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

# ================================================================
# AR-CONDICIONADO COMERCIAL DE PAREDE ALTA
#
# Instalado no alto da parede interna do salão de refeições.
# Climatiza o ambiente e consome energia da rede elétrica.
#
# Interação:
#  - Tecla [E] -> Alterna Ligar / Desligar Aparelho
# ================================================================

@export var is_turned_on: bool = false
@export var base_consumption_kw: float = 2.2

@onready var led_status: MeshInstance3D = get_node_or_null("Model/Body/LEDStatus")
@onready var flap_pivot: Node3D = get_node_or_null("Model/Body/FlapPivot")
@onready var vent_particles: CPUParticles3D = get_node_or_null("Model/Body/AirVentParticles")
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

var is_running: bool = false

func _ready() -> void:
	_setup_audio()
	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "air_conditioner", "Ar-Condicionado do Salão", base_consumption_kw, is_turned_on)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)
	_update_running_state()

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func _setup_audio() -> void:
	if not audio_player:
		audio_player = get_node_or_null("AudioStreamPlayer3D")
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioStreamPlayer3D"
		audio_player.unit_size = 2.5
		audio_player.max_distance = 15.0
		audio_player.volume_db = -24.0
		audio_player.stream = SoundSynthesizer.get_stream("air_conditioner_loop")
		add_child(audio_player)
	elif audio_player.stream == null:
		audio_player.volume_db = -24.0
		audio_player.stream = SoundSynthesizer.get_stream("air_conditioner_loop")

func get_interaction_prompt(player: Node = null) -> String:
	if is_running:
		return "❄️ [E] Desligar Ar-Condicionado"
	else:
		return "❄️ [E] Ligar Ar-Condicionado"

func interact_equipment(player: Node3D) -> void:
	toggle_ac(player)

func interact(player: Node3D) -> void:
	toggle_ac(player)

func toggle_ac(player: Node3D = null) -> void:
	is_turned_on = not is_turned_on

	var pm = PowerManager.get_instance()
	if pm:
		pm.set_appliance_state(self, is_turned_on)

	_update_running_state()

	if player:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			if is_running:
				hud.show_temporary_feedback("❄️ Ar-Condicionado Ligado — Climatização Ativa")
			elif is_turned_on:
				hud.show_temporary_feedback("⚠️ Ar-Condicionado Ligado (Aguardando energia no quadro geral)")
			else:
				hud.show_temporary_feedback("⚪ Ar-Condicionado Desligado")

func on_power_state_changed(main_power_on: bool) -> void:
	_update_running_state()

func _update_running_state() -> void:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	is_running = is_turned_on and has_power

	# Atualiza o registro no PowerManager
	if pm:
		pm.set_appliance_state(self, is_running)

	# Atualiza LED frontal físico (Verde = Ligado, Vermelho = Desligado)
	if led_status:
		var mat = led_status.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			if is_running:
				mat.albedo_color = Color(0.15, 0.95, 0.25, 1.0)
				mat.emission = Color(0.15, 0.95, 0.25, 1.0)
				mat.emission_enabled = true
			else:
				mat.albedo_color = Color(0.95, 0.15, 0.15, 1.0)
				mat.emission = Color(0.95, 0.15, 0.15, 1.0)
				mat.emission_enabled = true

	# Atualiza aletas de ventilação
	if flap_pivot:
		var target_rot_x = 35.0 if is_running else 0.0
		var tween = create_tween()
		tween.tween_property(flap_pivot, "rotation_degrees:x", target_rot_x, 0.4)

	# Atualiza partículas de fluxo de ar
	if vent_particles:
		vent_particles.emitting = is_running

	# Atualiza áudio de ventilação
	_setup_audio()
	if audio_player and audio_player.is_inside_tree():
		if is_running:
			if not audio_player.playing:
				audio_player.play()
		else:
			if audio_player.playing:
				audio_player.stop()
