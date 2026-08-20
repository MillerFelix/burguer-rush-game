extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE: SAVE INTRA-DIA, AUTOSAVE E LIMPEZA DA GRELHA/CHAPA
# ==============================================================================

const SaveManagerClass = preload("res://src/core/save_manager.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")
const InventoryManagerClass = preload("res://src/inventory/inventory_manager.gd")
const EmployeeManagerClass = preload("res://src/employees/employee_manager.gd")
const MenuPricingManagerClass = preload("res://src/recipes/menu_pricing_manager.gd")
const GrillClass = preload("res://src/stations/grill.gd")
const PattyClass = preload("res://src/items/patty.gd")
const SpongeClass = preload("res://src/tools/sponge.gd")

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
	print("\n=================================================================")
	print("=== TESTE: SAVE INTRA-DIA, AUTOSAVE E LIMPEZA DA GRELHA =========")
	print("=================================================================")
	run_tests()
	quit(0 if failed == 0 else 1)

func run_tests() -> void:
	var root = Node3D.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	# --------------------------------------------------------------------------
	# TESTE 1: SAVE DO PROGRESSO DURANTE O DIA (Ex: 18:30 no Dia 2)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Save e Restauração de Gameplay Intra-Dia (18:30, Dia 2) ---")
	var sm = SaveManagerClass.new()
	sm.name = "SaveManager"
	sm.set_custom_save_dir("user://test_saves_midday")
	root.add_child(sm)

	var econ = EconomyManagerClass.new()
	econ.name = "EconomyManager"
	econ.current_money = 850.25
	root.add_child(econ)

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	clock.day_number = 2
	clock.current_hour = 18
	clock.current_minute = 30
	clock.state = GameClockClass.State.OPEN
	root.add_child(clock)

	var inv = InventoryManagerClass.new()
	inv.name = "InventoryManager"
	root.add_child(inv)
	inv.restore_stock_dictionary({
		"bread_bottom": 12,
		"bread_top": 12,
		"patty_beef": 8,
		"cheese_cheddar": 15
	})

	var emp_mgr = EmployeeManagerClass.new()
	emp_mgr.name = "EmployeeManager"
	root.add_child(emp_mgr)
	var hire_res = emp_mgr.hire_employee("Carlos Teste", 0)

	MenuPricingManagerClass.set_custom_prices({
		"burger_classic": 28.50,
		"soda_cola": 8.00
	})

	# Salva o jogo no Slot 1 durante o gameplay ativo às 18:30
	sm.active_slot = 1
	sm.has_active_game = true
	var saved_ok = sm.save_game(1)
	assert_test(saved_ok, "Save do jogo às 18:30 realizado com sucesso")

	# Verifica o arquivo JSON salvo no disco
	var path = sm.get_slot_path(1)
	assert_test(FileAccess.file_exists(path), "Arquivo de save gerado fisicamente no disco")
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	json.parse(content)
	var disk_data: Dictionary = json.data
	assert_test(disk_data.get("clock_hour") == 18, "JSON no disco salvou clock_hour = 18 (e NÃO 9)")
	assert_test(disk_data.get("clock_minute") == 30, "JSON no disco salvou clock_minute = 30 (e NÃO 0)")
	assert_test(disk_data.get("current_day") == 2, "JSON no disco salvou current_day = 2")
	assert_test(is_equal_approx(disk_data.get("money", 0.0), 850.25 - 150.0), "JSON no disco salvou dinheiro atualizado")

	# Agora reseta o estado local simulando recarregamento de cena
	clock.current_hour = 9
	clock.current_minute = 0
	clock.state = GameClockClass.State.PREPARATION
	econ.current_money = 100.0

	# Carrega o save e aplica nos subsistemas
	var loaded_data = sm.load_game(1)
	assert_test(not loaded_data.is_empty(), "Dados do Slot 1 carregados com sucesso")

	assert_test(clock.current_hour == 18, "GameClock restaurado para 18:00 (NÃO voltou para o início do dia)")
	assert_test(clock.current_minute == 30, "GameClock minutos restaurados para 30")
	assert_test(clock.get_formatted_time() == "18:30", "Horário formatado exibe exatamente '18:30'")
	assert_test(clock.day_number == 2, "Dia restaurado para Dia 2")
	assert_test(clock.state == GameClockClass.State.OPEN, "Estado do relógio restaurado para OPEN (Aberto)")
	assert_test(is_equal_approx(econ.get_money(), 700.25), "Dinheiro restaurado com precisão")
	assert_test(inv.get_stock("bread_bottom") == 12, "Estoque de pães restaurado (12 unidades)")
	assert_test(inv.get_stock("patty_beef") == 8, "Estoque de carnes restaurado (8 unidades)")
	assert_test(emp_mgr.has_hired_employee(), "Funcionário contratado restaurado na equipe")
	assert_test(MenuPricingManagerClass.get_selling_price("burger_classic") == 28.50, "Preço personalizado restaurado")

	# --------------------------------------------------------------------------
	# TESTE 2: AUTO-SAVE A CADA 5 MINUTOS DE GAMEPLAY
	# --------------------------------------------------------------------------
	print("\n--- TESTE 2: Validação de Auto-save Periódico (300 segundos) ---")
	sm._auto_save_timer = 0.0
	clock.current_hour = 19
	clock.current_minute = 15

	# Simula 299s de gameplay -> ainda não deve salvar
	sm._process(299.0)
	assert_test(sm._auto_save_timer >= 299.0, "Timer de autosave acumulou 299 segundos")

	# Passa mais 2 segundos -> atinge 301s -> dispara autosave
	sm._process(2.0)
	assert_test(sm._auto_save_timer == 0.0, "Timer de autosave resetou após disparo")

	# Carrega e valida que o autosave salvou o horário mais recente (19:15)
	var autosave_data = sm.load_game(1)
	assert_test(autosave_data.get("clock_hour") == 19 and autosave_data.get("clock_minute") == 15, "Autosave gravou com sucesso o estado mais recente (19:15)")

	# --------------------------------------------------------------------------
	# TESTE 3: LIMPEZA COMPLETA E REPETIDA DA CHAPA / GRELHA
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Mecânica de Limpeza da Grelha com a Bucha (Ciclos Repetidos) ---")
	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as GrillClass
	root.add_child(grill)

	var sponge = SpongeClass.new()
	sponge.name = "Sponge"
	root.add_child(sponge)

	var patty_scene = load("res://src/items/patty.tscn")

	# CICLO 1: Deixar a grelha suja
	grill.set_dirty(true)
	assert_test(grill.is_dirty(), "1.1 Grelha está suja (dirt_level = 1.0)")
	assert_test(grill.get_dirt_level() == 1.0, "1.2 Nível de sujeira é 1.0")

	# Tentar colocar carne na grelha suja -> DEVE SER REJEITADA
	var p1 = patty_scene.instantiate()
	var placed_dirty = grill.place_item(p1)
	assert_test(not placed_dirty, "1.3 Grelha suja rejeita corretamente a colocação de hambúrguer")
	p1.queue_free()

	# Limpar a grelha com a bucha (chamando clean_progress em etapas)
	assert_test(not sponge.is_dirty, "1.4 Bucha inicia limpa")
	var finished = false
	# Simula esfregar por ~1.0 segundo (passos de delta)
	for s in range(15):
		finished = grill.clean_progress(0.1, root)
		if finished:
			break

	assert_test(finished, "1.5 clean_progress concluiu a limpeza da grelha")
	assert_test(not grill.is_dirty(), "1.6 Grelha agora NÃO está suja (is_dirty == false)")
	assert_test(grill.get_dirt_level() <= 0.001, "1.7 dirt_level zerado")
	assert_test(grill.cleanliness_state == GrillClass.CleanlinessState.CLEAN, "1.8 Estado de limpeza é CLEAN")

	# Agora colocar carne na grelha limpa -> DEVE SER ACEITA
	var p2 = patty_scene.instantiate()
	var placed_clean = grill.place_item(p2)
	assert_test(placed_clean, "1.9 Grelha limpa aceita hambúrguer normalmente")

	# CICLO 2 & 3: Repetir ciclos de sujeira e limpeza consecutiva
	for cycle in range(2, 4):
		grill.set_dirty(true)
		assert_test(grill.is_dirty(), "%d.1 Grelha suja novamente" % cycle)
		
		# Limpeza completa
		for s in range(15):
			if grill.clean_progress(0.1, root):
				break
		
		assert_test(not grill.is_dirty(), "%d.2 Grelha limpa com sucesso no ciclo %d" % [cycle, cycle])
		assert_test(grill.get_dirt_level() == 0.0, "%d.3 Nível de sujeira 0.0 no ciclo %d" % [cycle, cycle])

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")
	if failed == 0:
		print("🎉 SAVE INTRA-DIA, AUTOSAVE E LIMPEZA DA CHAPA 100% VALIDADOS!")
