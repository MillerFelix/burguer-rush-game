class_name AmbientAudioManager
extends Node3D

# ================================================================
# GERENCIADOR DE ÁUDIO AMBIENTE (BURGER RUSH AMBIENCE SYSTEM)
# - Música Ambiente Global 2D: Contínua, discreta em todo o mapa
# - Cozinha / Coifa: Zumbido suave localizado (sem ruído de vento)
# - Exterior / Trânsito 3D:
#     * Rua Frontal (Z >= 9.2) e Porta Principal (Z 7.0 -> 9.2)
#     * Área Externa do Caminhão/Alley (X <= -10.8)
#     * Armazém: Abafado (-34.0 dB)
#     * Centro da Cozinha / Salão: Inaudível (-80.0 dB)
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

var music_audio: AudioStreamPlayer = null
var kitchen_audio: AudioStreamPlayer3D = null
var outside_traffic_audio: AudioStreamPlayer3D = null

var player_ref: Node3D = null

func _enter_tree() -> void:
	_setup_ambient_players()

func _ready() -> void:
	_setup_ambient_players()

func _setup_ambient_players() -> void:
	# 1. Música ambiente global 2D (não posicional)
	# Toca de forma contínua e discreta em qualquer lugar do mapa (-16.0 dB)
	if not music_audio:
		music_audio = AudioStreamPlayer.new()
		music_audio.name = "DinerMusicAudio2D"
		music_audio.volume_db = -16.0
		music_audio.bus = "Master"
		music_audio.stream = SoundSynthesizer.get_stream("diner_bg_music")
		add_child(music_audio)
		if music_audio.is_inside_tree():
			music_audio.play()

	# 2. Zumbido térmico/elétrico sutil e localizado da cozinha (sem chiado de vento)
	if not kitchen_audio:
		kitchen_audio = AudioStreamPlayer3D.new()
		kitchen_audio.name = "KitchenHoodAudio"
		kitchen_audio.position = Vector3(0.0, 2.5, -1.5)
		kitchen_audio.unit_size = 1.5
		kitchen_audio.max_distance = 8.0
		kitchen_audio.volume_db = -30.0
		kitchen_audio.stream = SoundSynthesizer.get_stream("kitchen_hood_ambience")
		add_child(kitchen_audio)
		if kitchen_audio.is_inside_tree():
			kitchen_audio.play()

	# 3. Trânsito e atmosfera de rua externa / área do caminhão
	if not outside_traffic_audio:
		outside_traffic_audio = AudioStreamPlayer3D.new()
		outside_traffic_audio.name = "OutsideTrafficAudio"
		outside_traffic_audio.position = Vector3(0.0, 1.5, 15.0)
		outside_traffic_audio.unit_size = 4.0
		outside_traffic_audio.max_distance = 25.0
		outside_traffic_audio.volume_db = -80.0 # Inicializa silenciado para quem está na cozinha
		outside_traffic_audio.stream = SoundSynthesizer.get_stream("outside_traffic_ambience")
		add_child(outside_traffic_audio)
		if outside_traffic_audio.is_inside_tree():
			outside_traffic_audio.play()

func _process(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player") if (is_inside_tree() and get_tree()) else []
		if not players.is_empty():
			player_ref = players[0]
		elif get_parent():
			player_ref = get_parent().get_node_or_null("Player")

	if player_ref:
		var p_pos = player_ref.global_position if player_ref.is_inside_tree() else player_ref.position

		# --- CONTROLE RIGOROSO E ESPACIAL DO SOM EXTERNO ---
		var target_outside_vol = -80.0

		if p_pos.x <= -10.8:
			# 1. Área externa do caminhão / doca de recebimento (Alley exterior)
			target_outside_vol = -8.0
			outside_traffic_audio.position = Vector3(-14.0, 1.5, -4.5)
		elif p_pos.x <= -4.8 and p_pos.z <= -2.0:
			# 2. Dentro do armazém: som externo abafado
			target_outside_vol = -34.0
			outside_traffic_audio.position = Vector3(-14.0, 1.5, -4.5)
		elif p_pos.z >= 9.2:
			# 3. Fora do restaurante na calçada/rua frontal: plenamente audível
			target_outside_vol = -4.0
			outside_traffic_audio.position = Vector3(0.0, 1.5, 15.0)
		elif p_pos.z >= 7.0 and p_pos.x >= -3.5 and p_pos.x <= 3.5:
			# 4. Próximo da porta principal frontal (transição natural Z: 7.0 até 9.2)
			var door_factor = clampf((p_pos.z - 7.0) / 2.2, 0.0, 1.0)
			target_outside_vol = lerpf(-35.0, -6.0, door_factor)
			outside_traffic_audio.position = Vector3(0.0, 1.5, 15.0)
		elif p_pos.z <= -9.0 and p_pos.x >= 4.5:
			# 5. Próximo da janela de atendimento do Drive-Thru
			target_outside_vol = -10.0
			outside_traffic_audio.position = Vector3(7.0, 1.5, -12.0)
		elif p_pos.x >= 6.5 and p_pos.z > -6.0 and p_pos.z < 7.0:
			# 6. Próximo às janelas laterais de vidro
			target_outside_vol = -18.0
			outside_traffic_audio.position = Vector3(9.0, 1.5, 0.0)
		else:
			# 7. Centro da cozinha, ilha de preparo e salão interno: INAUDÍVEL (0% vazamento)
			target_outside_vol = -80.0

		if outside_traffic_audio:
			var w = 1.0 - exp(-4.5 * delta)
			outside_traffic_audio.volume_db = lerpf(outside_traffic_audio.volume_db, target_outside_vol, w)
