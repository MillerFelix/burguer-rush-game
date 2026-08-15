class_name DayNightCycle
extends Node

# Controlador do Ciclo Dia e Noite para Burger Rush
# Gerencia a iluminação natural, transições graduais (Manhã -> Almoço -> Tarde -> Fim de Tarde -> Noite),
# luzes artificiais internas e externas, faróis de veículos e pico de almoço.

@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var lights_root: Node3D
@export var ambient_traffic: AmbientTraffic
@export var customer_spawner: CustomerSpawner

var current_time_hours: float = 8.5 # 08:30

func _ready() -> void:
	var clock = GameClock.get_instance()
	if clock:
		clock.time_tick.connect(_on_time_tick)
		current_time_hours = clock.current_hour + (clock.current_minute / 60.0)

	_find_references_if_null()
	_update_lighting(current_time_hours)

func _find_references_if_null() -> void:
	var search_root: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		search_root = get_tree().root
	elif get_parent():
		search_root = get_parent()

	if not search_root:
		return

	if not sun_light:
		sun_light = search_root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if not world_environment:
		world_environment = search_root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if not lights_root:
		lights_root = search_root.find_child("Lights", true, false) as Node3D
	if not ambient_traffic:
		ambient_traffic = search_root.find_child("AmbientTraffic", true, false) as AmbientTraffic
	if not customer_spawner:
		customer_spawner = search_root.find_child("CustomerSpawner", true, false) as CustomerSpawner

func _on_time_tick(hours: int, minutes: int) -> void:
	current_time_hours = hours + (minutes / 60.0)
	_update_lighting(current_time_hours)

func _update_lighting(time_h: float) -> void:
	_find_references_if_null()

	# ---------------------------------------------------------
	# 1. CÁLCULO DAS FASES DO DIA
	# ---------------------------------------------------------
	# MANHÃ:         09:00 - 11:30 (Luz natural equilibrada, sombras suaves)
	# ALMOÇO/PICO:   11:30 - 14:00 (Sol alto brilhante, maior fluxo de clientes)
	# TARDE:         14:00 - 17:00 (Aquecimento gradual)
	# FIM DE TARDE:  17:00 - 18:30 (Hora dourada, sombras longas, pôr do sol)
	# NOITE:         18:30 - 21:00+ (Céu escuro, luzes artificiais acesas)

	var sun_color: Color = Color(1.0, 0.98, 0.92)
	var sun_energy: float = 1.2
	var sun_pitch: float = -45.0 # Graus
	var sun_yaw: float = 35.0
	var is_night: bool = false
	var lamp_energy_mult: float = 0.4 # Luzes de preenchimento diurnas

	if time_h < 11.5:
		# MANHÃ (08:30 - 11:30)
		var t = clampf((time_h - 8.5) / 3.0, 0.0, 1.0)
		sun_color = Color(1.0, 0.96, 0.90).lerp(Color(1.0, 0.99, 0.96), t)
		sun_energy = lerpf(1.0, 1.3, t)
		sun_pitch = lerpf(-30.0, -55.0, t)
		sun_yaw = lerpf(25.0, 45.0, t)
		lamp_energy_mult = 0.4
		is_night = false

	elif time_h < 14.0:
		# ALMOÇO / PICO (11:30 - 14:00)
		var t = clampf((time_h - 11.5) / 2.5, 0.0, 1.0)
		sun_color = Color(1.0, 1.0, 0.98)
		sun_energy = 1.35
		sun_pitch = lerpf(-55.0, -65.0, t)
		sun_yaw = lerpf(45.0, 60.0, t)
		lamp_energy_mult = 0.4
		is_night = false

	elif time_h < 17.0:
		# TARDE (14:00 - 17:00)
		var t = clampf((time_h - 14.0) / 3.0, 0.0, 1.0)
		sun_color = Color(1.0, 0.98, 0.95).lerp(Color(1.0, 0.88, 0.72), t)
		sun_energy = lerpf(1.3, 1.05, t)
		sun_pitch = lerpf(-65.0, -35.0, t)
		sun_yaw = lerpf(60.0, 85.0, t)
		lamp_energy_mult = lerpf(0.4, 0.8, t)
		is_night = false

	elif time_h < 18.5:
		# FIM DE TARDE / PÔR DO SOL DOURADO (17:00 - 18:30)
		var t = clampf((time_h - 17.0) / 1.5, 0.0, 1.0)
		sun_color = Color(1.0, 0.88, 0.72).lerp(Color(1.0, 0.58, 0.28), t)
		sun_energy = lerpf(1.05, 0.35, t)
		sun_pitch = lerpf(-35.0, -12.0, t) # Sombras longas
		sun_yaw = lerpf(85.0, 110.0, t)
		lamp_energy_mult = lerpf(0.8, 1.4, t)
		is_night = (t > 0.6)

	else:
		# NOITE (18:30 - 24:00)
		var t = clampf((time_h - 18.5) / 2.5, 0.0, 1.0)
		sun_color = Color(0.45, 0.55, 0.85) # Luar suave
		sun_energy = lerpf(0.20, 0.06, t)
		sun_pitch = -15.0
		sun_yaw = 120.0
		lamp_energy_mult = 1.5
		is_night = true

	# ---------------------------------------------------------
	# 2. ATUALIZAÇÃO DO SOL (DirectionalLight3D)
	# ---------------------------------------------------------
	if sun_light:
		sun_light.light_color = sun_color
		sun_light.light_energy = sun_energy
		sun_light.rotation_degrees = Vector3(sun_pitch, sun_yaw, 0.0)

	# ---------------------------------------------------------
	# 3. ATUALIZAÇÃO DO AMBIENTE (WorldEnvironment)
	# ---------------------------------------------------------
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		if is_night:
			env.background_energy_multiplier = 0.25
			env.ambient_light_color = Color(0.12, 0.16, 0.28)
			env.ambient_light_energy = 0.5
		elif time_h >= 17.0:
			# Fim de tarde
			env.background_energy_multiplier = 0.85
			env.ambient_light_color = Color(0.55, 0.42, 0.32)
			env.ambient_light_energy = 0.8
		else:
			# Dia claro
			env.background_energy_multiplier = 1.0
			env.ambient_light_color = Color(0.5, 0.52, 0.55)
			env.ambient_light_energy = 1.0

	# ---------------------------------------------------------
	# 4. LUZES ARTIFICIAIS (Luminárias do Salão e Cozinha)
	# ---------------------------------------------------------
	if lights_root:
		for light in lights_root.get_children():
			if light is Light3D:
				var base_e = light.get_meta("base_energy", -1.0)
				if base_e < 0.0:
					base_e = light.light_energy
					light.set_meta("base_energy", base_e)
				light.light_energy = base_e * lamp_energy_mult

	# ---------------------------------------------------------
	# 5. AJUSTE DE FLUXO DE ALMOÇO (CustomerSpawner)
	# ---------------------------------------------------------
	if customer_spawner:
		if time_h >= 11.5 and time_h <= 14.0:
			# Pico de almoço: mais clientes e maior frequência
			customer_spawner.spawn_interval = 5.0
		else:
			customer_spawner.spawn_interval = 8.5

	# ---------------------------------------------------------
	# 6. FARÓIS DOS CARROS (AmbientTraffic)
	# ---------------------------------------------------------
	if ambient_traffic and ambient_traffic.has_method("set_night_mode"):
		ambient_traffic.set_night_mode(is_night)
