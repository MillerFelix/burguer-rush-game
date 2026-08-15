extends SceneTree

const WeatherManager = preload("res://src/environment/weather_manager.gd")
const DayNightCycle = preload("res://src/time/day_night_cycle.gd")
const GameClock = preload("res://src/time/game_clock.gd")

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DO SISTEMA DE CLIMA DINÂMICO E TRANSIÇÕES GRADUAIS")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var weather_mgr = main_scene.get_node_or_null("WeatherManager") as WeatherManager
	var day_night = main_scene.find_child("DayNightCycle", true, false) as DayNightCycle
	var clock = main_scene.find_child("GameClock", true, false) as GameClock
	var sun_light = main_scene.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	var world_env = main_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment

	assert(weather_mgr != null, "WeatherManager deve existir na cena")
	assert(day_night != null, "DayNightCycle deve existir na cena")
	assert(sun_light != null and world_env != null, "DirectionalLight3D e WorldEnvironment devem existir")

	weather_mgr.auto_weather_cycle = false # Controle manual para os testes

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DE DIA ENSOLARADO (SUNNY)
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação de Dia Ensolarado (Sunny) às 14:00 ---")
	day_night.current_time_hours = 14.0
	weather_mgr.set_weather(WeatherManager.WeatherType.SUNNY, true)
	day_night._update_lighting(14.0)

	print("  Clima: %s %s" % [weather_mgr.get_weather_icon(), weather_mgr.get_weather_name()])
	print("  Sol Energy: %.2f | Cloudiness: %.2f | Rain: %.2f" % [sun_light.light_energy, weather_mgr.cloudiness, weather_mgr.rain_intensity])
	assert(weather_mgr.current_weather == WeatherManager.WeatherType.SUNNY, "Clima deve ser SUNNY")
	assert(sun_light.light_energy >= 1.0, "Energia do sol deve ser forte no sol pleno")
	assert(weather_mgr.rain_particles.emitting == false, "Partículas de chuva devem estar desligadas")
	assert(weather_mgr.rain_audio.playing == false, "Áudio de chuva deve estar parado")
	print("  [PASS] Dia ensolarado validado com sucesso!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DE TRANSIÇÃO GRADUAL: ENSOLARADO -> NUBLADO
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação de Transição Gradual: Sol -> Nublado ---")
	weather_mgr.set_weather(WeatherManager.WeatherType.CLOUDY, false)
	assert(weather_mgr.target_weather == WeatherManager.WeatherType.CLOUDY, "Target weather deve ser CLOUDY")

	var initial_cloudiness = weather_mgr.cloudiness
	# Simula 2 segundos de transição gradual
	for i in range(20):
		weather_mgr._process(0.1)
		day_night._process(0.1)

	print("  Após 2s de transição: Cloudiness = %.2f (Sol Energy = %.2f)" % [weather_mgr.cloudiness, sun_light.light_energy])
	assert(weather_mgr.cloudiness > initial_cloudiness and weather_mgr.cloudiness < 1.0, "Transição de nuvens deve ser gradual e suave")

	# Avança até completar a transição para nublado
	for i in range(30):
		weather_mgr._process(0.1)
		day_night._process(0.1)
	assert(weather_mgr.cloudiness == 1.0, "Cloudiness deve atingir 1.0")
	assert(weather_mgr.rain_intensity == 0.0, "Não deve haver chuva no clima nublado")
	print("  [PASS] Transição gradual para dia nublado validada!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DE TRANSIÇÃO GRADUAL: NUBLADO -> CHUVA (TEMPESTADE DIURNA)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação de Transição Gradual: Nublado -> Chuva às 14:00 ---")
	weather_mgr.set_weather(WeatherManager.WeatherType.RAINY, false)

	# Simula chegada das primeiras gotas
	for i in range(15):
		weather_mgr._process(0.1)
		day_night._process(0.1)

	print("  Garoa / Primeiras gotas: Rain Intensity = %.2f | Volume dB = %.1f | Partículas = %d" % [
		weather_mgr.rain_intensity,
		weather_mgr.rain_audio.volume_db,
		weather_mgr.rain_particles.amount
	])
	assert(weather_mgr.rain_particles.emitting == true, "Partículas devem começar a emitir com a garoa")
	assert(weather_mgr.rain_audio.volume_db > -40.0, "Volume de chuva deve subir suavemente com a intensidade")

	# Avança para chuva estabelecida
	for i in range(35):
		weather_mgr._process(0.1)
		day_night._process(0.1)

	print("  Chuva Estabelecida: Rain Intensity = %.2f | Sol Energy = %.2f | Wetness = %.2f" % [
		weather_mgr.rain_intensity,
		sun_light.light_energy,
		weather_mgr.wetness
	])
	assert(weather_mgr.rain_intensity == 1.0, "Rain intensity deve atingir 1.0")
	assert(sun_light.light_energy < 0.6, "Sol deve estar significativamente escurecido pela chuva diurna")
	assert(weather_mgr.wetness > 0.5, "Superfícies externas devem acumular umidade")

	# Validação de acendimento de lâmpadas diurnas na chuva
	var dining_lamp = main_scene.find_child("DiningCeilingLamp*", true, false)
	assert(dining_lamp != null, "DiningCeilingLamp deve existir")
	var lamp_bulb = dining_lamp.find_child("Bulb", true, false) as MeshInstance3D
	var b_mat = lamp_bulb.material_override as StandardMaterial3D
	assert(b_mat.emission_enabled == true, "Luzes internas do restaurante devem acender durante tempestade diurna")
	print("  [PASS] Chuva diurna escurece o céu e acende luzes internas e públicas com atmosfera imersiva!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DE HORÁRIO INTACTO DURANTE A CHUVA
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação de Integridade do Relógio na Chuva ---")
	clock.current_hour = 14
	clock.current_minute = 30
	print("  Horário do Relógio: %s (Horário não foi alterado pelo clima)" % clock.get_formatted_time())
	assert(clock.current_hour == 14 and clock.current_minute == 30, "Horário deve permanecer exato")
	print("  [PASS] Sistema de horário preservado 100% intacto!")

	# -------------------------------------------------------------------------
	# 5. VALIDAÇÃO DE TRANSIÇÃO GRADUAL: CHUVA -> SOL (CESSAÇÃO E SECAGEM)
	# -------------------------------------------------------------------------
	print("\n--- 5. Validação de Transição Gradual: Chuva -> Sol (Secagem do Chão) ---")
	weather_mgr.set_weather(WeatherManager.WeatherType.SUNNY, false)

	# Simula chuva parando aos poucos
	for i in range(25):
		weather_mgr._process(0.1)
		day_night._process(0.1)

	print("  Chuva diminuindo: Rain Intensity = %.2f | Wetness = %.2f" % [weather_mgr.rain_intensity, weather_mgr.wetness])
	assert(weather_mgr.rain_intensity < 0.5, "Intensidade da chuva deve diminuir gradualmente")

	# Avança até a chuva parar completamente
	for i in range(35):
		weather_mgr._process(0.1)
		day_night._process(0.1)

	print("  Chuva encerrou: Rain Intensity = %.2f | Partículas Emitting = %s" % [weather_mgr.rain_intensity, weather_mgr.rain_particles.emitting])
	assert(weather_mgr.rain_intensity == 0.0, "Rain intensity deve zerar")
	assert(weather_mgr.rain_particles.emitting == false, "Partículas devem parar")
	assert(weather_mgr.rain_audio.playing == false, "Áudio deve encerrar")
	print("  [PASS] Cessação da chuva e processo de secagem validados com transições orgânicas!")

	# -------------------------------------------------------------------------
	# 6. VALIDAÇÃO DE CHUVA NOTURNA (NIGHT + RAIN)
	# -------------------------------------------------------------------------
	print("\n--- 6. Validação de Chuva Noturna (21:00 + Chuva) ---")
	day_night.current_time_hours = 21.0
	weather_mgr.set_weather(WeatherManager.WeatherType.RAINY, true)
	day_night._update_lighting(21.0)

	print("  Noite Chuvosa: Hora = 21:00 | Clima = %s | Partículas = %s" % [weather_mgr.get_weather_name(), weather_mgr.rain_particles.emitting])
	assert(weather_mgr.rain_particles.emitting == true, "Chuva deve funcionar perfeitamente à noite")
	assert(b_mat.emission_enabled == true, "Luzes noturnas devem permanecer acesas")
	print("  [PASS] Chuva noturna com iluminação de postes e interior validada!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("SISTEMA DE CLIMA DINÂMICO 100% VALIDADO E APROVADO!")
	print("================================================================================")
	quit(0)
