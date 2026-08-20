class_name WeatherManager
extends Node3D

# =============================================================================
# GERENCIADOR DE CLIMA ATMOSFÉRICO E IMERSÃO DE CHUVA (BURGER RUSH)
#
# Recursos:
# 1. Partículas de chuva densas e dinâmicas que acompanham a posição do jogador.
# 2. Respingos e micro-gotículas atingindo o chão e superfícies externas.
# 3. Asfalto, calçadas e pallets molhados com reflexos suaves.
# 4. Janelas do salão com vidro úmido/gotejante e vista clara da chuva lá fora.
# 5. Áudio da chuva com abafamento espacial (abafado no interior, vívido perto de
#    portas/janelas e imersivo no exterior).
# =============================================================================

signal weather_changed(new_weather: WeatherType)
signal rain_intensity_changed(intensity: float)

enum WeatherType {
	SUNNY,   # Ensolarado / Céu aberto normal
	CLOUDY,  # Nublado / Céu encoberto
	RAINY    # Chuvoso / Chuva externa visível, som espacial, chão molhado
}

static var instance: WeatherManager = null

@export var auto_weather_cycle: bool = true
@export var transition_speed: float = 0.35 # Taxa de transição por segundo

var current_weather: WeatherType = WeatherType.SUNNY
var target_weather: WeatherType = WeatherType.SUNNY

var cloudiness: float = 0.0       # 0.0 a 1.0
var rain_intensity: float = 0.0   # 0.0 a 1.0
var wetness: float = 0.0          # 0.0 a 1.0

var target_cloudiness: float = 0.0
var target_rain_intensity: float = 0.0

var weather_timer: float = 0.0
var current_duration: float = 60.0

# Componentes Visuais e Sonoros
var rain_particles: CPUParticles3D = null
var rain_splashes: CPUParticles3D = null
var rain_audio_ext: AudioStreamPlayer = null
var rain_audio_int: AudioStreamPlayer = null

var wet_materials: Array[StandardMaterial3D] = []
var window_materials: Array[StandardMaterial3D] = []

func _enter_tree() -> void:
	instance = self
	_ensure_components()

func _ready() -> void:
	instance = self
	_ensure_components()
	_setup_materials()
	current_duration = randf_range(50.0, 90.0)
	weather_timer = 0.0

func static_get() -> WeatherManager:
	return instance

static func get_instance() -> WeatherManager:
	return instance

func _ensure_components() -> void:
	_setup_rain_visuals()
	_setup_rain_audio()

func _setup_rain_visuals() -> void:
	# 1. Partículas de chuva caindo (Densas, nítidas e cobrindo todo o exterior)
	if not rain_particles:
		rain_particles = get_node_or_null("RainParticles") as CPUParticles3D
		if not rain_particles:
			rain_particles = CPUParticles3D.new()
			rain_particles.name = "RainParticles"
			add_child(rain_particles)

		rain_particles.amount = 2000
		rain_particles.lifetime = 0.55
		rain_particles.preprocess = 0.5
		rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rain_particles.emission_box_extents = Vector3(36.0, 0.5, 36.0)
		rain_particles.position = Vector3(0.0, 12.0, 0.0)
		rain_particles.direction = Vector3(-0.15, -1.0, 0.05).normalized()
		rain_particles.spread = 2.5
		rain_particles.initial_velocity_min = 34.0
		rain_particles.initial_velocity_max = 44.0
		rain_particles.gravity = Vector3(-2.0, -32.0, 0.5)

		# Gotas alongadas, nítidas e brilhantes (altamente visíveis através de vidros e no ar)
		var drop_mesh = CylinderMesh.new()
		drop_mesh.top_radius = 0.016
		drop_mesh.bottom_radius = 0.016
		drop_mesh.height = 1.15

		var drop_mat = StandardMaterial3D.new()
		drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		drop_mat.albedo_color = Color(0.90, 0.95, 1.0, 0.85)
		drop_mat.roughness = 0.1
		drop_mat.metallic = 0.1
		drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop_mesh.material = drop_mat

		rain_particles.mesh = drop_mesh
		rain_particles.emitting = false

	# 2. Respingos e impacto das gotas no chão externo (Water Splashes)
	if not rain_splashes:
		rain_splashes = get_node_or_null("RainSplashes") as CPUParticles3D
		if not rain_splashes:
			rain_splashes = CPUParticles3D.new()
			rain_splashes.name = "RainSplashes"
			add_child(rain_splashes)

		rain_splashes.amount = 800
		rain_splashes.lifetime = 0.30
		rain_splashes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rain_splashes.emission_box_extents = Vector3(34.0, 0.05, 34.0)
		rain_splashes.position = Vector3(0.0, 0.03, 0.0)
		rain_splashes.direction = Vector3(0, 1, 0)
		rain_splashes.spread = 80.0
		rain_splashes.initial_velocity_min = 2.2
		rain_splashes.initial_velocity_max = 5.0
		rain_splashes.gravity = Vector3(0, -18.0, 0)
		rain_splashes.scale_amount_min = 0.03
		rain_splashes.scale_amount_max = 0.08

		var splash_mesh = SphereMesh.new()
		splash_mesh.radius = 0.04
		splash_mesh.height = 0.08
		var splash_mat = StandardMaterial3D.new()
		splash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		splash_mat.albedo_color = Color(0.90, 0.95, 1.0, 0.75)
		splash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		splash_mesh.material = splash_mat
		rain_splashes.mesh = splash_mesh
		rain_splashes.emitting = false

func _setup_rain_audio() -> void:
	# Camada Exterior (Som aberto e vívido de chuva)
	if not rain_audio_ext:
		rain_audio_ext = get_node_or_null("RainAudioExt") as AudioStreamPlayer
		if not rain_audio_ext:
			rain_audio_ext = AudioStreamPlayer.new()
			rain_audio_ext.name = "RainAudioExt"
			add_child(rain_audio_ext)
		rain_audio_ext.stream = _synthesize_rain_stream(false)
		rain_audio_ext.volume_db = -80.0

	# Camada Interior (Som abafado e aconchegante no telhado)
	if not rain_audio_int:
		rain_audio_int = get_node_or_null("RainAudioInt") as AudioStreamPlayer
		if not rain_audio_int:
			rain_audio_int = AudioStreamPlayer.new()
			rain_audio_int.name = "RainAudioInt"
			add_child(rain_audio_int)
		rain_audio_int.stream = _synthesize_rain_stream(true)
		rain_audio_int.volume_db = -80.0

func _synthesize_rain_stream(is_interior_muffled: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	var last_val = 0.0
	var filter_coeff = 0.97 if is_interior_muffled else 0.88

	for i in range(num_samples):
		var white = randf_range(-1.0, 1.0)
		last_val = (last_val * filter_coeff) + (white * (1.0 - filter_coeff))
		var sample = clampf(last_val * (0.22 if not is_interior_muffled else 0.30), -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

func _setup_materials() -> void:
	wet_materials.clear()
	window_materials.clear()
	var root_node = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if not root_node:
		return

	var meshes = root_node.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var parent_name = m.get_parent().name if m.get_parent() else ""
		var is_outdoor = false
		for pattern in ["Street", "Road", "Parking", "Sidewalk", "Terrain", "Yard", "Alley", "TruckRoad", "Pallet", "Receiving"]:
			if pattern in m.name or pattern in parent_name:
				is_outdoor = true
				break

		# Coleta superfícies externas para molhar
		if is_outdoor and m.material_override is StandardMaterial3D:
			var mat = m.material_override as StandardMaterial3D
			if not wet_materials.has(mat):
				if not mat.has_meta("orig_roughness"):
					mat.set_meta("orig_roughness", mat.roughness)
					mat.set_meta("orig_albedo", mat.albedo_color)
				wet_materials.append(mat)

		# Coleta janelas de vidro
		if ("Glass" in m.name or "Window" in parent_name) and (m.material_override is StandardMaterial3D or (m.mesh and m.mesh.surface_get_material(0) is StandardMaterial3D)):
			var wmat = m.material_override as StandardMaterial3D if m.material_override else m.mesh.surface_get_material(0) as StandardMaterial3D
			if wmat and not window_materials.has(wmat):
				if not wmat.has_meta("orig_roughness"):
					wmat.set_meta("orig_roughness", wmat.roughness)
					wmat.set_meta("orig_albedo", wmat.albedo_color)
				window_materials.append(wmat)

func set_weather(weather: WeatherType, immediate: bool = false) -> void:
	_ensure_components()
	target_weather = weather
	match target_weather:
		WeatherType.SUNNY:
			target_cloudiness = 0.0
			target_rain_intensity = 0.0
		WeatherType.CLOUDY:
			target_cloudiness = 1.0
			target_rain_intensity = 0.0
		WeatherType.RAINY:
			target_cloudiness = 1.0
			target_rain_intensity = 1.0

	if immediate:
		current_weather = target_weather
		cloudiness = target_cloudiness
		rain_intensity = target_rain_intensity
		wetness = 1.0 if target_weather == WeatherType.RAINY else 0.0
		_apply_weather_state(0.0)

	weather_changed.emit(target_weather)

func _process(delta: float) -> void:
	if auto_weather_cycle:
		weather_timer += delta
		if weather_timer >= current_duration:
			weather_timer = 0.0
			current_duration = randf_range(50.0, 110.0)
			_pick_next_weather_randomly()

	var step = transition_speed * delta
	cloudiness = move_toward(cloudiness, target_cloudiness, step)
	rain_intensity = move_toward(rain_intensity, target_rain_intensity, step)

	if rain_intensity > 0.05:
		wetness = minf(1.0, wetness + (delta * 0.35 * rain_intensity))
	else:
		wetness = maxf(0.0, wetness - (delta * 0.03))

	if cloudiness == target_cloudiness and rain_intensity == target_rain_intensity:
		current_weather = target_weather

	_apply_weather_state(delta)

func _pick_next_weather_randomly() -> void:
	var roll = randf()
	match current_weather:
		WeatherType.SUNNY:
			set_weather(WeatherType.SUNNY if roll < 0.50 else WeatherType.CLOUDY)
		WeatherType.CLOUDY:
			if roll < 0.45:
				set_weather(WeatherType.SUNNY)
			elif roll < 0.70:
				set_weather(WeatherType.CLOUDY)
			else:
				set_weather(WeatherType.RAINY)
		WeatherType.RAINY:
			set_weather(WeatherType.CLOUDY if roll < 0.75 else WeatherType.RAINY)

func _apply_weather_state(_delta: float) -> void:
	_ensure_components()

	# 1. Posicionamento das partículas de chuva acompanhando o jogador em área ampla
	var player = _get_player_node()
	var p_pos = player.global_position if player else Vector3.ZERO

	if rain_particles:
		if rain_intensity > 0.05:
			if is_inside_tree() and rain_particles.is_inside_tree():
				rain_particles.global_position = Vector3(p_pos.x, 12.0, p_pos.z)
			else:
				rain_particles.position = Vector3(p_pos.x, 12.0, p_pos.z)
			rain_particles.emitting = true
			rain_particles.amount = int(lerpf(600.0, 2000.0, rain_intensity))
		else:
			rain_particles.emitting = false

	if rain_splashes:
		if rain_intensity > 0.10:
			if is_inside_tree() and rain_splashes.is_inside_tree():
				rain_splashes.global_position = Vector3(p_pos.x, 0.03, p_pos.z)
			else:
				rain_splashes.position = Vector3(p_pos.x, 0.03, p_pos.z)
			rain_splashes.emitting = true
			rain_splashes.amount = int(lerpf(250.0, 800.0, rain_intensity))
		else:
			rain_splashes.emitting = false

	# 2. Áudio Espacial da Chuva com Abafamento Interno e Presença nas Portas/Janelas
	_process_spatial_audio(p_pos)

	# 3. Superfícies Molhadas (Asfalto, Calçada, Deck, Pallet)
	if absf(wetness - _last_applied_wetness) > 0.004:
		_last_applied_wetness = wetness
		for mat in wet_materials:
			if is_instance_valid(mat) and mat.has_meta("orig_roughness"):
				var orig_r = mat.get_meta("orig_roughness", 0.8)
				var orig_alb = mat.get_meta("orig_albedo", Color.WHITE) as Color
				mat.roughness = lerpf(orig_r, 0.16, wetness)
				mat.albedo_color = orig_alb.lerp(orig_alb.darkened(0.25 * wetness), wetness)

		# 4. Janelas Úmidas com Gotículas
		for wmat in window_materials:
			if is_instance_valid(wmat) and wmat.has_meta("orig_roughness"):
				var orig_r = wmat.get_meta("orig_roughness", 0.05)
				var orig_alb = wmat.get_meta("orig_albedo", Color(0.85, 0.93, 0.98, 0.25)) as Color
				wmat.roughness = lerpf(orig_r, 0.02, wetness)
				var wet_window_col = Color(0.78, 0.88, 0.96, 0.35)
				wmat.albedo_color = orig_alb.lerp(wet_window_col, wetness)

	rain_intensity_changed.emit(rain_intensity)

func _process_spatial_audio(p_pos: Vector3) -> void:
	if rain_intensity <= 0.02:
		if rain_audio_ext and rain_audio_ext.playing: rain_audio_ext.stop()
		if rain_audio_int and rain_audio_int.playing: rain_audio_int.stop()
		return

	if rain_audio_ext and not rain_audio_ext.playing and rain_audio_ext.is_inside_tree():
		rain_audio_ext.play()
	if rain_audio_int and not rain_audio_int.playing and rain_audio_int.is_inside_tree():
		rain_audio_int.play()

	# Coordenadas do interior do restaurante: X em [-6.0, 6.0], Z em [-5.0, 11.0]
	var is_indoor = (abs(p_pos.x) < 6.0 and p_pos.z > -5.0 and p_pos.z < 11.0)
	var dist_to_openings = 10.0

	if is_indoor:
		# Distância da porta da frente (Z = -5.0), janelas laterais (|X| = 6.0) ou porta de serviço (Z = 11.0)
		var dist_front = abs(p_pos.z - (-5.0))
		var dist_sides = 6.0 - abs(p_pos.x)
		var dist_back = abs(11.0 - p_pos.z)
		dist_to_openings = minf(dist_front, minf(dist_sides, dist_back))

	if not is_indoor:
		# Totalmente no exterior (rua, doca, pallet de entrega) — Reduzido para som ambiente confortável
		if rain_audio_ext: rain_audio_ext.volume_db = lerpf(-38.0, -18.0, rain_intensity)
		if rain_audio_int: rain_audio_int.volume_db = -80.0
	else:
		# No interior do restaurante (abafado e relaxante no telhado, sem sobrepor a jogabilidade)
		var openness_factor = clampf(1.0 - (dist_to_openings / 4.0), 0.0, 1.0)
		var ext_vol = lerpf(-34.0, -22.0, openness_factor) - (1.0 - rain_intensity) * 12.0
		var int_vol = lerpf(-24.0, -28.0, openness_factor) - (1.0 - rain_intensity) * 12.0

		if rain_audio_ext: rain_audio_ext.volume_db = ext_vol
		if rain_audio_int: rain_audio_int.volume_db = int_vol

var _cached_player_node: Node3D = null
var _last_applied_wetness: float = -1.0

func _get_player_node() -> Node3D:
	if _cached_player_node and is_instance_valid(_cached_player_node):
		return _cached_player_node
	if is_inside_tree() and get_tree():
		_cached_player_node = get_tree().get_first_node_in_group("player") as Node3D
	return _cached_player_node

func get_weather_name() -> String:
	match current_weather:
		WeatherType.SUNNY: return "Ensolarado"
		WeatherType.CLOUDY: return "Nublado"
		WeatherType.RAINY: return "Chuvoso"
	return "Normal"

func get_weather_icon() -> String:
	match current_weather:
		WeatherType.SUNNY: return "☀️"
		WeatherType.CLOUDY: return "☁️"
		WeatherType.RAINY: return "🌧️"
	return "☀️"
