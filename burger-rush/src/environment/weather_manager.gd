class_name WeatherManager
extends Node3D

# Gerenciador de Clima Dinâmico e Atmosférico para Burger Rush
# Controla tipos de clima (Ensolarado, Nublado, Chuvoso), transições contínuas e graduais,
# partículas de chuva externa, superfícies molhadas (asfalto/calçada), áudio ambiente e
# integração com a iluminação do DayNightCycle.

signal weather_changed(new_weather: WeatherType)
signal rain_intensity_changed(intensity: float)

enum WeatherType {
	SUNNY,   # Ensolarado / Céu aberto normal
	CLOUDY,  # Nublado / Céu encoberto, sol mais fraco, iluminação difusa
	RAINY    # Chuvoso / Céu escuro, partículas de chuva, som, chão molhado, luzes acesas
}

static var instance: WeatherManager = null

@export var auto_weather_cycle: bool = true
@export var transition_speed: float = 0.25 # Taxa de transição por segundo

var current_weather: WeatherType = WeatherType.SUNNY
var target_weather: WeatherType = WeatherType.SUNNY

# Valores contínuos interpolados (0.0 a 1.0)
var cloudiness: float = 0.0       # 0.0 = céu limpo, 1.0 = 100% encoberto
var rain_intensity: float = 0.0   # 0.0 = sem chuva, 1.0 = chuva máxima
var wetness: float = 0.0          # 0.0 = seco, 1.0 = totalmente molhado

var target_cloudiness: float = 0.0
var target_rain_intensity: float = 0.0

var weather_timer: float = 0.0
var current_duration: float = 60.0

# Componentes Visuais e Sonoros
var rain_particles: CPUParticles3D = null
var rain_audio: AudioStreamPlayer = null
var wet_materials: Array[StandardMaterial3D] = []

# Paletas de cores para o céu durante climas modificados
const SKY_TOP_CLOUDY = Color(0.42, 0.48, 0.55, 1.0)
const SKY_HORIZON_CLOUDY = Color(0.65, 0.68, 0.72, 1.0)
const GROUND_BOTTOM_CLOUDY = Color(0.18, 0.20, 0.22, 1.0)
const GROUND_HORIZON_CLOUDY = Color(0.55, 0.58, 0.62, 1.0)

const SKY_TOP_RAINY = Color(0.16, 0.20, 0.26, 1.0)
const SKY_HORIZON_RAINY = Color(0.32, 0.36, 0.42, 1.0)
const GROUND_BOTTOM_RAINY = Color(0.08, 0.10, 0.12, 1.0)
const GROUND_HORIZON_RAINY = Color(0.24, 0.28, 0.32, 1.0)

func _enter_tree() -> void:
	instance = self
	_ensure_components()

func _ready() -> void:
	instance = self
	_ensure_components()
	_setup_wet_materials()

	# Sorteia clima inicial com duração balanceada
	current_duration = randf_range(45.0, 90.0)
	weather_timer = 0.0

func _ensure_components() -> void:
	_setup_rain_particles()
	_setup_rain_audio()

func static_get() -> WeatherManager:
	return instance

static func get_instance() -> WeatherManager:
	return instance

func _setup_rain_particles() -> void:
	if not rain_particles:
		rain_particles = get_node_or_null("RainParticles") as CPUParticles3D
		if not rain_particles:
			rain_particles = CPUParticles3D.new()
			rain_particles.name = "RainParticles"
			add_child(rain_particles)

		# Configura partículas de chuva estilizadas e eficientes
		rain_particles.amount = 350
		rain_particles.lifetime = 1.2
		rain_particles.preprocess = 0.5
		rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		# Cobre toda a extensão externa ao redor do restaurante
		rain_particles.emission_box_extents = Vector3(26.0, 0.5, 24.0)
		rain_particles.position = Vector3(0.0, 14.0, 0.0)
		rain_particles.direction = Vector3(-0.15, -1.0, 0.05).normalized()
		rain_particles.spread = 4.0
		rain_particles.initial_velocity_min = 22.0
		rain_particles.initial_velocity_max = 28.0
		rain_particles.gravity = Vector3(0, -9.8, 0)
		rain_particles.scale_amount_min = 0.04
		rain_particles.scale_amount_max = 0.08

		# Mesh de gota de chuva (cilindro fino e alongado estilizado)
		var drop_mesh = CylinderMesh.new()
		drop_mesh.top_radius = 0.015
		drop_mesh.bottom_radius = 0.015
		drop_mesh.height = 0.45

		var drop_mat = StandardMaterial3D.new()
		drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		drop_mat.albedo_color = Color(0.75, 0.85, 0.95, 0.45)
		drop_mat.roughness = 0.1
		drop_mat.metallic = 0.2
		drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop_mesh.material = drop_mat

		rain_particles.mesh = drop_mesh
		rain_particles.emitting = false

func _setup_rain_audio() -> void:
	if not rain_audio:
		rain_audio = get_node_or_null("RainAudio") as AudioStreamPlayer
		if not rain_audio:
			rain_audio = AudioStreamPlayer.new()
			rain_audio.name = "RainAudio"
			add_child(rain_audio)

		# Gerador de ruído sonoro suave de chuva sintética caso não haja wav estático
		var sample_rate = 22050
		var duration = 2.0
		var num_samples = int(sample_rate * duration)
		var pcm = PackedByteArray()
		pcm.resize(num_samples * 2)

		var last_val = 0.0
		for i in range(num_samples):
			var white = randf_range(-1.0, 1.0)
			# Filtro passa-baixa leve para simular som suave de chuva
			last_val = (last_val * 0.92) + (white * 0.08)
			var s16 = int(clampf(last_val * 0.35, -1.0, 1.0) * 32767.0)
			pcm.encode_s16(i * 2, s16)

		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = sample_rate
		stream.stereo = false
		stream.data = pcm
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = num_samples

		rain_audio.stream = stream
		rain_audio.volume_db = -80.0
		rain_audio.autoplay = false

func _setup_wet_materials() -> void:
	wet_materials.clear()
	var root_node = get_tree().current_scene if (is_inside_tree() and get_tree() and get_tree().current_scene) else get_parent()
	if not root_node:
		return

	# Coleta malhas do asfalto, calçada, estacionamento e rua
	var mesh_names = ["Street", "Sidewalk", "ParkingLot", "Asphalt", "Terrain", "YardGround", "FloorDining", "FloorKitchen"]
	var meshes = root_node.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var parent_name = m.get_parent().name if m.get_parent() else ""
		var is_outdoor = false
		for pattern in ["Street", "Road", "Parking", "Sidewalk", "Terrain", "Yard", "Alley", "TruckRoad"]:
			if pattern in m.name or pattern in parent_name:
				is_outdoor = true
				break

		if is_outdoor and m.material_override is StandardMaterial3D:
			if not wet_materials.has(m.material_override):
				var mat = m.material_override as StandardMaterial3D
				# Guarda valores originais
				if not mat.has_meta("orig_roughness"):
					mat.set_meta("orig_roughness", mat.roughness)
					mat.set_meta("orig_albedo", mat.albedo_color)
				wet_materials.append(mat)

func ensure_setup() -> void:
	_ensure_components()
	_setup_wet_materials()

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
		if target_weather == WeatherType.RAINY:
			wetness = 1.0
		elif target_weather == WeatherType.SUNNY:
			wetness = 0.0
		_apply_weather_state(0.0)

	weather_changed.emit(target_weather)

func _process(delta: float) -> void:
	# 1. Ciclo Aleatório Controlado de Clima
	if auto_weather_cycle:
		weather_timer += delta
		if weather_timer >= current_duration:
			weather_timer = 0.0
			current_duration = randf_range(50.0, 110.0)
			_pick_next_weather_randomly()

	# 2. Interpolação Contínua e Suave dos Parâmetros Climáticos
	var step = transition_speed * delta
	cloudiness = move_toward(cloudiness, target_cloudiness, step)
	rain_intensity = move_toward(rain_intensity, target_rain_intensity, step)

	# Dinâmica de Umidade (Chão molha rápido com chuva e seca gradualmente)
	if rain_intensity > 0.05:
		wetness = minf(1.0, wetness + (delta * 0.25 * rain_intensity))
	else:
		wetness = maxf(0.0, wetness - (delta * 0.04)) # Seca em ~25s

	# Atualiza o estado atual quando a transição conclui
	if cloudiness == target_cloudiness and rain_intensity == target_rain_intensity:
		current_weather = target_weather

	_apply_weather_state(delta)

func _pick_next_weather_randomly() -> void:
	var roll = randf()
	match current_weather:
		WeatherType.SUNNY:
			# Ensolarado pode permanecer ensolarado (50%) ou fechar para nublado (50%)
			if roll < 0.50:
				set_weather(WeatherType.SUNNY)
			else:
				set_weather(WeatherType.CLOUDY)

		WeatherType.CLOUDY:
			# Nublado pode abrir para ensolarado (45%), continuar nublado (25%) ou começar a chover (30%)
			if roll < 0.45:
				set_weather(WeatherType.SUNNY)
			elif roll < 0.70:
				set_weather(WeatherType.CLOUDY)
			else:
				set_weather(WeatherType.RAINY)

		WeatherType.RAINY:
			# Chuvoso geralmente diminui para nublado antes de abrir
			if roll < 0.75:
				set_weather(WeatherType.CLOUDY)
			else:
				set_weather(WeatherType.RAINY)

func _apply_weather_state(_delta: float) -> void:
	_ensure_components()
	# A) Partículas de Chuva
	if rain_particles:
		if rain_intensity > 0.05:
			rain_particles.emitting = true
			rain_particles.amount = int(lerpf(60.0, 400.0, rain_intensity))
		else:
			rain_particles.emitting = false

	# B) Áudio Ambiente da Chuva
	if rain_audio:
		if rain_intensity > 0.02:
			if not rain_audio.playing and is_inside_tree() and rain_audio.is_inside_tree():
				rain_audio.play()
			var target_vol = lerpf(-40.0, -12.0, rain_intensity)
			rain_audio.volume_db = target_vol
		else:
			if rain_audio.playing:
				rain_audio.stop()

	# C) Aspecto de Superfícies Molhadas
	if not wet_materials.is_empty():
		for mat in wet_materials:
			if is_instance_valid(mat) and mat.has_meta("orig_roughness"):
				var orig_r = mat.get_meta("orig_roughness", 0.8)
				var orig_alb = mat.get_meta("orig_albedo", Color.WHITE) as Color

				# Superfície molhada fica mais escura e reflexiva (roughness menor)
				mat.roughness = lerpf(orig_r, 0.20, wetness)
				var darkened_alb = orig_alb.darkened(0.20 * wetness)
				mat.albedo_color = orig_alb.lerp(darkened_alb, wetness)

	rain_intensity_changed.emit(rain_intensity)

func get_weather_name() -> String:
	match current_weather:
		WeatherType.SUNNY:
			return "Ensolarado"
		WeatherType.CLOUDY:
			return "Nublado"
		WeatherType.RAINY:
			return "Chuvoso"
	return "Normal"

func get_weather_icon() -> String:
	match current_weather:
		WeatherType.SUNNY:
			return "☀️"
		WeatherType.CLOUDY:
			return "☁️"
		WeatherType.RAINY:
			return "🌧️"
	return "☀️"
