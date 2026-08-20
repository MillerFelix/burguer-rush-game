class_name DayNightCycle
extends Node

const WeatherManager = preload("res://src/environment/weather_manager.gd")

# Controlador do Ciclo Dia e Noite Integrado ao Sistema de Clima Dinâmico para Burger Rush
# Gerencia a iluminação natural, transições graduais (Manhã -> Almoço -> Tarde -> Fim de Tarde -> Noite),
# modulação atmosférica por clima (Ensolarado, Nublado, Chuvoso), acendimento de luzes internas
# e postes tanto ao anoitecer quanto durante tempestades diurnas, postes de rua e tráfego ambiente.

@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var lights_root: Node3D
@export var ambient_traffic: AmbientTraffic
@export var customer_spawner: CustomerSpawner

var current_time_hours: float = 8.5 # 08:30

# Cores base do céu para interpolação dinâmica no dia ensolarado
const SKY_TOP_DAY = Color(0.35, 0.62, 0.90, 1.0)
const SKY_HORIZON_DAY = Color(0.82, 0.86, 0.92, 1.0)
const GROUND_BOTTOM_DAY = Color(0.24, 0.25, 0.28, 1.0)
const GROUND_HORIZON_DAY = Color(0.82, 0.86, 0.92, 1.0)

const SKY_TOP_SUNSET = Color(0.18, 0.28, 0.58, 1.0)
const SKY_HORIZON_SUNSET = Color(0.88, 0.42, 0.18, 1.0)
const GROUND_BOTTOM_SUNSET = Color(0.12, 0.12, 0.15, 1.0)
const GROUND_HORIZON_SUNSET = Color(0.48, 0.22, 0.12, 1.0)

const SKY_TOP_DUSK = Color(0.04, 0.06, 0.14, 1.0)
const SKY_HORIZON_DUSK = Color(0.12, 0.14, 0.26, 1.0)
const GROUND_BOTTOM_DUSK = Color(0.03, 0.03, 0.05, 1.0)
const GROUND_HORIZON_DUSK = Color(0.06, 0.07, 0.12, 1.0)

const SKY_TOP_NIGHT = Color(0.012, 0.018, 0.042, 1.0) # Azul petróleo profundo / quase preto
const SKY_HORIZON_NIGHT = Color(0.024, 0.032, 0.065, 1.0)
const GROUND_BOTTOM_NIGHT = Color(0.008, 0.010, 0.016, 1.0)
const GROUND_HORIZON_NIGHT = Color(0.016, 0.020, 0.038, 1.0)

# Cores atmosféricas para Clima Nublado e Chuvoso
const SKY_TOP_CLOUDY = Color(0.38, 0.45, 0.54, 1.0)
const SKY_HORIZON_CLOUDY = Color(0.60, 0.64, 0.70, 1.0)
const SKY_TOP_RAINY = Color(0.14, 0.18, 0.24, 1.0)
const SKY_HORIZON_RAINY = Color(0.28, 0.32, 0.38, 1.0)

func _ready() -> void:
	var clock = GameClock.get_instance()
	if clock:
		clock.time_tick.connect(_on_time_tick)
		current_time_hours = clock.current_hour + (clock.current_minute / 60.0)

	_find_references_if_null()
	_update_lighting(current_time_hours)

var _references_checked: bool = false
var _cached_weather_manager: WeatherManager = null
var _cached_street_lamps: Array = []
var _cached_dining_lamps: Array = []
var _cached_kitchen_panels: Array = []
var _cached_deliv_mgr: Node = null
var _last_calc_time_h: float = -1.0
var _last_calc_cloud: float = -1.0
var _last_calc_rain: float = -1.0

func _find_references_if_null() -> void:
	if _references_checked:
		return
	_references_checked = true

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
	if not _cached_deliv_mgr:
		_cached_deliv_mgr = search_root.find_child("DeliveryQueueManager", true, false)

	_cached_street_lamps = search_root.find_children("StreetLamp*", "Node3D", true, false)
	_cached_dining_lamps = search_root.find_children("DiningCeilingLamp*", "Node3D", true, false)
	var kp = search_root.find_children("KitchenPanel*", "Node3D", true, false)
	kp.append_array(search_root.find_children("StoragePanel*", "Node3D", true, false))
	_cached_kitchen_panels = kp

func _on_time_tick(hours: int, minutes: int) -> void:
	current_time_hours = hours + (minutes / 60.0)
	_update_lighting(current_time_hours)

func _process(_delta: float) -> void:
	# Atualiza a iluminação a cada frame para acompanhar transições climáticas graduais em tempo real
	_update_lighting(current_time_hours)

func _get_weather_manager() -> WeatherManager:
	if _cached_weather_manager and is_instance_valid(_cached_weather_manager):
		return _cached_weather_manager
	var wm = WeatherManager.instance
	if not wm:
		var curr = self.get_parent()
		while curr:
			if curr.has_node("WeatherManager"):
				wm = curr.get_node("WeatherManager") as WeatherManager
				break
			curr = curr.get_parent()
	if not wm and is_inside_tree() and get_tree() and get_tree().root:
		wm = get_tree().root.find_child("WeatherManager", true, false) as WeatherManager
	_cached_weather_manager = wm
	return _cached_weather_manager

func _update_lighting(time_h: float) -> void:
	_find_references_if_null()

	# ---------------------------------------------------------
	# 1. OBTENÇÃO DOS PARÂMETROS CLIMÁTICOS ATUAIS
	# ---------------------------------------------------------
	var cloudiness: float = 0.0
	var rain_intensity: float = 0.0
	var wm = _get_weather_manager()
	if wm:
		cloudiness = wm.cloudiness
		rain_intensity = wm.rain_intensity

	if absf(time_h - _last_calc_time_h) < 0.0001 and absf(cloudiness - _last_calc_cloud) < 0.001 and absf(rain_intensity - _last_calc_rain) < 0.001:
		return
	_last_calc_time_h = time_h
	_last_calc_cloud = cloudiness
	_last_calc_rain = rain_intensity

	# ---------------------------------------------------------
	# 2. CÁLCULO DAS FASES BASE DO CICLO HORÁRIO (08:30 - 24:00+)
	# ---------------------------------------------------------
	var sun_color: Color = Color(1.0, 0.98, 0.92)
	var sun_energy: float = 1.2
	var sun_pitch: float = -45.0
	var sun_yaw: float = 35.0
	var is_night: bool = false
	var indoor_energy_mult: float = 0.0
	var street_lamp_energy_mult: float = 0.0

	var cur_sky_top: Color = SKY_TOP_DAY
	var cur_sky_horiz: Color = SKY_HORIZON_DAY
	var cur_gnd_bot: Color = GROUND_BOTTOM_DAY
	var cur_gnd_horiz: Color = GROUND_HORIZON_DAY
	var cur_amb_color: Color = Color(0.50, 0.52, 0.55)
	var cur_amb_energy: float = 1.0
	var cur_bg_energy: float = 1.0

	if time_h >= 6.0 and time_h < 11.5:
		# MANHÃ (06:00 - 11:30)
		var t = clampf((time_h - 8.5) / 3.0, 0.0, 1.0)
		sun_color = Color(1.0, 0.96, 0.90).lerp(Color(1.0, 0.99, 0.96), t)
		sun_energy = lerpf(1.0, 1.3, t)
		sun_pitch = lerpf(-30.0, -55.0, t)
		sun_yaw = lerpf(25.0, 45.0, t)
		indoor_energy_mult = 0.0
		street_lamp_energy_mult = 0.0
		is_night = false
		cur_sky_top = SKY_TOP_DAY
		cur_sky_horiz = SKY_HORIZON_DAY
		cur_gnd_bot = GROUND_BOTTOM_DAY
		cur_gnd_horiz = GROUND_HORIZON_DAY
		cur_amb_color = Color(0.50, 0.52, 0.55)
		cur_amb_energy = 1.0
		cur_bg_energy = 1.0

	elif time_h < 14.0:
		# ALMOÇO / PICO (11:30 - 14:00)
		var t = clampf((time_h - 11.5) / 2.5, 0.0, 1.0)
		sun_color = Color(1.0, 1.0, 0.98)
		sun_energy = 1.35
		sun_pitch = lerpf(-55.0, -65.0, t)
		sun_yaw = lerpf(45.0, 60.0, t)
		indoor_energy_mult = 0.0
		street_lamp_energy_mult = 0.0
		is_night = false
		cur_sky_top = SKY_TOP_DAY
		cur_sky_horiz = SKY_HORIZON_DAY
		cur_gnd_bot = GROUND_BOTTOM_DAY
		cur_gnd_horiz = GROUND_HORIZON_DAY
		cur_amb_color = Color(0.52, 0.54, 0.56)
		cur_amb_energy = 1.05
		cur_bg_energy = 1.0

	elif time_h < 17.0:
		# TARDE (14:00 - 17:00)
		var t = clampf((time_h - 14.0) / 3.0, 0.0, 1.0)
		sun_color = Color(1.0, 0.98, 0.95).lerp(Color(1.0, 0.88, 0.72), t)
		sun_energy = lerpf(1.3, 1.05, t)
		sun_pitch = lerpf(-65.0, -35.0, t)
		sun_yaw = lerpf(60.0, 85.0, t)
		indoor_energy_mult = 0.0
		street_lamp_energy_mult = 0.0
		is_night = false
		cur_sky_top = SKY_TOP_DAY
		cur_sky_horiz = SKY_HORIZON_DAY.lerp(Color(0.86, 0.80, 0.72), t)
		cur_gnd_bot = GROUND_BOTTOM_DAY
		cur_gnd_horiz = GROUND_HORIZON_DAY
		cur_amb_color = Color(0.50, 0.50, 0.52).lerp(Color(0.52, 0.44, 0.35), t)
		cur_amb_energy = lerpf(1.0, 0.85, t)
		cur_bg_energy = lerpf(1.0, 0.90, t)

	elif time_h < 18.5:
		# FIM DE TARDE / PÔR DO SOL (17:00 - 18:30)
		var t = clampf((time_h - 17.0) / 1.5, 0.0, 1.0)
		sun_color = Color(1.0, 0.88, 0.72).lerp(Color(1.0, 0.55, 0.22), t)
		sun_energy = lerpf(1.05, 0.25, t)
		sun_pitch = lerpf(-35.0, -10.0, t)
		sun_yaw = lerpf(85.0, 110.0, t)

		if time_h <= 18.0:
			indoor_energy_mult = 0.0
			street_lamp_energy_mult = 0.0
		else:
			var t_lamp = (time_h - 18.0) / 0.5
			indoor_energy_mult = lerpf(0.0, 0.40, t_lamp)
			street_lamp_energy_mult = lerpf(0.0, 0.20, t_lamp)

		is_night = false
		cur_sky_top = SKY_TOP_DAY.lerp(SKY_TOP_SUNSET, t)
		cur_sky_horiz = SKY_HORIZON_DAY.lerp(SKY_HORIZON_SUNSET, t)
		cur_gnd_bot = GROUND_BOTTOM_DAY.lerp(GROUND_BOTTOM_SUNSET, t)
		cur_gnd_horiz = GROUND_HORIZON_DAY.lerp(GROUND_HORIZON_SUNSET, t)
		cur_amb_color = Color(0.52, 0.44, 0.35).lerp(Color(0.50, 0.32, 0.20), t)
		cur_amb_energy = lerpf(0.85, 0.45, t)
		cur_bg_energy = lerpf(0.90, 0.45, t)

	elif time_h < 19.5:
		# CREPÚSCULO (18:30 - 19:30)
		var t = clampf((time_h - 18.5) / 1.0, 0.0, 1.0)
		sun_color = Color(1.0, 0.55, 0.22).lerp(Color(0.35, 0.45, 0.75), t)
		sun_energy = lerpf(0.25, 0.03, t)
		sun_pitch = lerpf(-10.0, -15.0, t)
		sun_yaw = lerpf(110.0, 125.0, t)
		indoor_energy_mult = lerpf(0.40, 1.0, t)
		street_lamp_energy_mult = lerpf(0.20, 1.0, t)
		is_night = (time_h >= 19.0)

		cur_sky_top = SKY_TOP_SUNSET.lerp(SKY_TOP_DUSK, t)
		cur_sky_horiz = SKY_HORIZON_SUNSET.lerp(SKY_HORIZON_DUSK, t)
		cur_gnd_bot = GROUND_BOTTOM_SUNSET.lerp(GROUND_BOTTOM_DUSK, t)
		cur_gnd_horiz = GROUND_HORIZON_SUNSET.lerp(GROUND_HORIZON_DUSK, t)
		cur_amb_color = Color(0.50, 0.32, 0.20).lerp(Color(0.08, 0.10, 0.18), t)
		cur_amb_energy = lerpf(0.45, 0.10, t)
		cur_bg_energy = lerpf(0.45, 0.08, t)

	elif time_h < 21.0:
		# NOITE ABERTA (19:30 - 21:00)
		var t = clampf((time_h - 19.5) / 1.5, 0.0, 1.0)
		sun_color = Color(0.35, 0.45, 0.75).lerp(Color(0.25, 0.35, 0.65), t)
		sun_energy = lerpf(0.03, 0.01, t)
		sun_pitch = -15.0
		sun_yaw = 130.0
		indoor_energy_mult = lerpf(1.0, 1.15, t)
		street_lamp_energy_mult = 1.0
		is_night = true

		cur_sky_top = SKY_TOP_DUSK.lerp(SKY_TOP_NIGHT, t)
		cur_sky_horiz = SKY_HORIZON_DUSK.lerp(SKY_HORIZON_NIGHT, t)
		cur_gnd_bot = GROUND_BOTTOM_DUSK.lerp(GROUND_BOTTOM_NIGHT, t)
		cur_gnd_horiz = GROUND_HORIZON_DUSK.lerp(GROUND_HORIZON_NIGHT, t)
		cur_amb_color = Color(0.08, 0.10, 0.18).lerp(Color(0.04, 0.06, 0.11), t)
		cur_amb_energy = lerpf(0.10, 0.05, t)
		cur_bg_energy = lerpf(0.08, 0.03, t)

	else:
		# NOITE PROFUNDA (21:00+)
		sun_color = Color(0.25, 0.35, 0.65)
		sun_energy = 0.01
		sun_pitch = -15.0
		sun_yaw = 130.0
		indoor_energy_mult = 1.15
		street_lamp_energy_mult = 1.0
		is_night = true

		cur_sky_top = SKY_TOP_NIGHT
		cur_sky_horiz = SKY_HORIZON_NIGHT
		cur_gnd_bot = GROUND_BOTTOM_NIGHT
		cur_gnd_horiz = GROUND_HORIZON_NIGHT
		cur_amb_color = Color(0.04, 0.06, 0.11)
		cur_amb_energy = 0.05
		cur_bg_energy = 0.03

	# ---------------------------------------------------------
	# 3. MODULAÇÃO ATMOSFÉRICA INTEGRADA DO CLIMA DINÂMICO
	# ---------------------------------------------------------
	# A) Sol: Atenuação de intensidade e temperatura de cor
	if cloudiness > 0.0 or rain_intensity > 0.0:
		var sun_attenuation = 1.0 - (cloudiness * 0.35) - (rain_intensity * 0.40)
		sun_energy = maxf(0.01, sun_energy * sun_attenuation)
		# Dias nublados/chuvosos tornam a luz solar mais neutra/fria
		var overcast_tint = Color(0.75, 0.80, 0.85)
		sun_color = sun_color.lerp(overcast_tint, maxf(cloudiness * 0.4, rain_intensity * 0.7))

	# B) Céu: Interpolação suave de tons nublados e chuvosos (sem mudar o relógio)
	if not is_night:
		if rain_intensity > 0.05:
			cur_sky_top = cur_sky_top.lerp(SKY_TOP_RAINY, rain_intensity)
			cur_sky_horiz = cur_sky_horiz.lerp(SKY_HORIZON_RAINY, rain_intensity)
			cur_amb_color = cur_amb_color.lerp(Color(0.22, 0.25, 0.30), rain_intensity * 0.7)
			cur_amb_energy = lerpf(cur_amb_energy, 0.40, rain_intensity * 0.65)
			cur_bg_energy = lerpf(cur_bg_energy, 0.35, rain_intensity * 0.70)
		elif cloudiness > 0.05:
			cur_sky_top = cur_sky_top.lerp(SKY_TOP_CLOUDY, cloudiness)
			cur_sky_horiz = cur_sky_horiz.lerp(SKY_HORIZON_CLOUDY, cloudiness)
			cur_amb_color = cur_amb_color.lerp(Color(0.40, 0.42, 0.46), cloudiness * 0.5)
			cur_amb_energy = lerpf(cur_amb_energy, 0.75, cloudiness * 0.35)

	# C) Acendimento Automático de Luzes Internas e Externas em Chuva Diurna
	if rain_intensity > 0.15 and not is_night:
		var rain_indoor_boost = lerpf(0.0, 0.85, (rain_intensity - 0.15) / 0.85)
		indoor_energy_mult = maxf(indoor_energy_mult, rain_indoor_boost)
		var rain_street_boost = lerpf(0.0, 0.90, (rain_intensity - 0.15) / 0.85)
		street_lamp_energy_mult = maxf(street_lamp_energy_mult, rain_street_boost)

	# ---------------------------------------------------------
	# 4. ATUALIZAÇÃO DO SOL (DirectionalLight3D)
	# ---------------------------------------------------------
	if sun_light:
		sun_light.light_color = sun_color
		sun_light.light_energy = sun_energy
		sun_light.rotation_degrees = Vector3(sun_pitch, sun_yaw, 0.0)

	# ---------------------------------------------------------
	# 5. ATUALIZAÇÃO DO AMBIENTE E CÉU (WorldEnvironment)
	# ---------------------------------------------------------
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.background_energy_multiplier = cur_bg_energy
		env.ambient_light_color = cur_amb_color
		env.ambient_light_energy = cur_amb_energy

		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = cur_sky_top
			sky_mat.sky_horizon_color = cur_sky_horiz
			sky_mat.ground_bottom_color = cur_gnd_bot
			sky_mat.ground_horizon_color = cur_gnd_horiz

	# ---------------------------------------------------------
	# 6. LUZES ARTIFICIAIS DO NODE 'Lights'
	# ---------------------------------------------------------
	if lights_root:
		for light in lights_root.get_children():
			if light is Light3D:
				var base_e = light.get_meta("base_energy", -1.0)
				if base_e < 0.0:
					base_e = light.light_energy
					light.set_meta("base_energy", base_e)

				var mult = indoor_energy_mult
				if light.name.begins_with("Street") or "Street" in light.name:
					mult = street_lamp_energy_mult
				elif light.name.begins_with("Facade") or "Dock" in light.name or "Dumpster" in light.name:
					mult = street_lamp_energy_mult

				light.light_energy = base_e * mult

	# ---------------------------------------------------------
	# 7. EMISSÃO VISUAL DAS LUMINÁRIAS E POSTES
	# ---------------------------------------------------------
	# A) Postes de Rua
	for lamp in _cached_street_lamps:
		if not is_instance_valid(lamp):
			continue
		var omni = lamp.find_child("LampLight", true, false) as Light3D
		if omni:
			var base_e = omni.get_meta("base_energy", -1.0)
			if base_e < 0.0:
				base_e = omni.light_energy
				omni.set_meta("base_energy", base_e)
			omni.light_energy = base_e * street_lamp_energy_mult

		var bulb = lamp.find_child("Bulb", true, false) as MeshInstance3D
		if bulb:
			if bulb.material_override == null:
				var m = StandardMaterial3D.new()
				m.albedo_color = Color(1.0, 0.92, 0.72)
				bulb.material_override = m
			var b_mat = bulb.material_override as StandardMaterial3D
			if b_mat:
				b_mat.emission_enabled = (street_lamp_energy_mult > 0.05)
				b_mat.emission = Color(1.0, 0.85, 0.55)
				b_mat.emission_energy_multiplier = 2.8 * street_lamp_energy_mult

	# B) Luminárias Centrais do Salão
	for dlamp in _cached_dining_lamps:
		if not is_instance_valid(dlamp):
			continue
		var bulb = dlamp.find_child("Bulb", true, false) as MeshInstance3D
		if bulb:
			if bulb.material_override == null:
				var m = StandardMaterial3D.new()
				m.albedo_color = Color(1.0, 0.94, 0.82)
				bulb.material_override = m
			var b_mat = bulb.material_override as StandardMaterial3D
			if b_mat:
				b_mat.emission_enabled = (indoor_energy_mult > 0.05)
				b_mat.emission = Color(1.0, 0.86, 0.65)
				b_mat.emission_energy_multiplier = 2.4 * indoor_energy_mult

	# C) Painéis de LED da Cozinha e Estoque
	for kpanel in _cached_kitchen_panels:
		if not is_instance_valid(kpanel):
			continue
		var diff = kpanel.find_child("Diffuser", true, false) as MeshInstance3D
		if diff:
			if diff.material_override == null:
				var m = StandardMaterial3D.new()
				m.albedo_color = Color(0.96, 0.98, 1.0)
				diff.material_override = m
			var d_mat = diff.material_override as StandardMaterial3D
			if d_mat:
				d_mat.emission_enabled = (indoor_energy_mult > 0.05)
				d_mat.emission = Color(0.94, 0.97, 1.0)
				d_mat.emission_energy_multiplier = 2.5 * indoor_energy_mult

	# ---------------------------------------------------------
	# 8. AJUSTE DE FLUXO DE CLIENTES (CustomerSpawner)
	# ---------------------------------------------------------
	if customer_spawner:
		if time_h >= 11.5 and time_h <= 14.0:
			customer_spawner.spawn_interval = 5.0
		else:
			customer_spawner.spawn_interval = 8.5

	# ---------------------------------------------------------
	# 9. FARÓIS DOS CARROS (AmbientTraffic e DeliveryQueueManager)
	# ---------------------------------------------------------
	var enable_headlights = is_night or (rain_intensity > 0.3)
	if ambient_traffic and ambient_traffic.has_method("set_night_mode"):
		ambient_traffic.set_night_mode(enable_headlights)

	if _cached_deliv_mgr and _cached_deliv_mgr.has_method("set_night_mode"):
		_cached_deliv_mgr.set_night_mode(enable_headlights)
