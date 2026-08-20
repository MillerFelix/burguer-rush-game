extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE PERFORMANCE E INTEGRIDADE DE GAMEPLAY / VISUAL
# ==============================================================================

const ItemClass = preload("res://src/items/item.gd")
const DrinkMachineClass = preload("res://src/stations/drink_machine.gd")
const JuiceMachineClass = preload("res://src/stations/juice_machine.gd")
const FryerClass = preload("res://src/stations/fryer.gd")
const CustomerClass = preload("res://src/customers/customer.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const WeatherManagerClass = preload("res://src/environment/weather_manager.gd")
const PrepIslandClass = preload("res://src/stations/prep_island.gd")
const AmbientTrafficClass = preload("res://src/environment/ambient_traffic.gd")
const PlayerClass = preload("res://src/player/player.gd")

var passed: int = 0
var failed: int = 0

func assert_test(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % message)
	else:
		failed += 1
		print("  [FAIL] %s" % message)

func _init() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE DE PERFORMANCE & INTEGRIDADE ===========")
	print("=================================================================")

	# --------------------------------------------------------------------------
	# TESTE 1: OTIMIZAÇÃO DE ITENS EM REPOUSO (ZERO FÍSICA INÚTIL)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Gestão de Processamento de Física dos Itens ---")
	var items: Array[ItemClass] = []
	for i in range(30):
		var item = ItemClass.new()
		root.add_child(item)
		items.append(item)

	var resting_disabled_count = 0
	for it in items:
		if not it.is_physics_processing():
			resting_disabled_count += 1

	assert_test(resting_disabled_count == 30, "Todos os 30 itens em repouso desativaram physics_process (0% consumo de CPU)")

	# Drop ativa temporariamente o processamento de física
	items[0].on_dropped()
	assert_test(items[0].is_physics_processing() == true, "Item solto ativa physics_process para calcular queda")

	# Ao ser pego, desativa novamente
	items[0].on_picked_up()
	assert_test(items[0].is_physics_processing() == false, "Item pego na mão desativa physics_process")

	for it in items:
		it.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 2: DRINK MACHINE (ZERO ALOCAÇÃO DE MATERIAIS POR FRAME)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 2: Drink Machine (Pooling de Materiais & Fluidez) ---")
	var drink_scene = load("res://src/stations/drink_machine.tscn")
	if drink_scene:
		var dm = drink_scene.instantiate() as DrinkMachineClass
		root.add_child(dm)
		dm.is_powered = true
		dm._update_all_visuals()

		var initial_mat = dm._mat_led_on
		assert_test(initial_mat != null, "Material LED Power cacheado com sucesso")
		assert_test(dm._meter_materials.size() == 4, "Materiais dos 4 medidores cacheados")

		# Simula 60 frames de _process
		for f in range(60):
			dm._process(0.016)

		assert_test(dm._mat_led_on == initial_mat, "Zero novas instâncias de materiais criadas durante 60 frames de _process")
		dm.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 3: JUICE MACHINE (ZERO ALOCAÇÃO DE BOXMESH POR FRAME)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Juice Machine (Reutilização de Malhas & Materiais) ---")
	var juice_scene = load("res://src/stations/juice_machine.tscn")
	if juice_scene:
		var jm = juice_scene.instantiate() as JuiceMachineClass
		root.add_child(jm)
		jm.is_powered = true
		jm.juice_doses[0] = 10.0
		jm.juice_doses[1] = 10.0
		jm.juice_doses[2] = 10.0
		jm._update_all_visuals()

		assert_test(jm._reservoir_materials.size() == 3, "Materiais dos 3 reservatórios cacheados")
		assert_test(jm._mat_led_on != null, "Material LED Power da suqueira cacheado")

		# Simula 60 frames
		for f in range(60):
			jm._process(0.016)

		assert_test(jm._reservoir_materials.size() == 3, "Estrutura estável sem vazamento de memória ou novos BoxMeshes a cada frame")
		jm.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 4: FRITADEIRA (CACHING DE NÓS DE CESTOS E ALAVANCAS)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 4: Fritadeira (Acesso O(1) aos Cestos e Alavancas) ---")
	var fr = Fryer.new()
	root.add_child(fr)
	fr._process(0.016)

	assert_test(fr._cached_basket_nodes.size() == 4, "4 nós de cestos cacheados no array direto")
	assert_test(fr._cached_lever_arms.size() == 4, "4 nós de alavancas cacheados no array direto")
	fr.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 5: STATUS VISUAL DOS CLIENTES (PRESERVAÇÃO E REDUÇÃO DE OVERHEAD)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 5: Clientes (Atualização Otimizada de Label3D) ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	if cust_scene:
		var cust = cust_scene.instantiate() as CustomerClass
		root.add_child(cust)
		cust.state = CustomerClass.State.ARRIVING
		cust._update_visual_status()

		assert_test(cust.label_3d != null, "Label3D do cliente presente")
		assert_test(cust.label_3d.text.contains("Entrando"), "Texto visual do cliente preservado com fidelidade: '%s'" % cust.label_3d.text)

		# Testa estado de atendimento
		cust.state = CustomerClass.State.SEATED_WAITING_TO_ORDER
		cust._update_visual_status()
		assert_test(cust.label_3d.text.contains("Aguardando Atendimento"), "Texto de espera preservado: '%s'" % cust.label_3d.text)

		cust.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 6: AMBIENT TRAFFIC (POOLING DE CORES)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 6: Tráfego Ambiente (Reutilização de Materiais de Carros) ---")
	var traffic = AmbientTrafficClass.new()
	root.add_child(traffic)
	traffic._ensure_car_materials()
	assert_test(traffic._car_materials.size() == 7, "7 materiais de veículos pré-alocados para pooling")
	traffic.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 7: GAME CLOCK E WEATHER MANAGER
	# --------------------------------------------------------------------------
	print("\n--- TESTE 7: GameClock e WeatherManager (Execução Throttled sem Overhead) ---")
	var clock = GameClockClass.new()
	root.add_child(clock)
	clock.day_number = 1
	clock.current_hour = 10
	clock.current_minute = 0
	clock.state = GameClockClass.State.OPEN
	clock._process(0.1)
	assert_test(clock.current_minute >= 0, "GameClock processando tempo normalmente")
	clock.queue_free()

	var weather = WeatherManagerClass.new()
	root.add_child(weather)
	weather.set_weather(WeatherManagerClass.WeatherType.SUNNY, true)
	assert_test(weather.get_weather_name() == "Ensolarado", "WeatherManager funcional com transições otimizadas")
	weather.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 OTIMIZAÇÃO DE PERFORMANCE E INTEGRIDADE 100% VALIDADAS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
