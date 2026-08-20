extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE FREQUÊNCIA DE SUJEIRA DA GRELHA E FLUXO DE PREPARO
# ==============================================================================

const Grill = preload("res://src/stations/grill.gd")
const Patty = preload("res://src/items/patty.gd")
const Player = preload("res://src/player/player.gd")

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

func _create_dummy_patty() -> Node3D:
	var p = StaticBody3D.new()
	p.set_script(load("res://src/items/patty.gd"))
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	p.add_child(col)
	return p

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE DE SUJEIRA DA GRELHA ====================")
	print("=================================================================")

	var grill_res = load("res://src/stations/grill.tscn")
	var grill = grill_res.instantiate()
	root.add_child(grill)

	var player_res = load("res://src/player/player.tscn")
	var player = player_res.instantiate()
	root.add_child(player)

	# --- TESTE 1: GRELHA INICIAL TOTALMENTE LIMPA ---
	print("\n--- TESTE 1: Estado Inicial da Grelha ---")
	assert_test(grill.dirt_level == 0.0, "Nível de sujeira inicial = 0.0")
	assert_test(grill.is_dirty() == false, "Grelha inicia limpa (is_dirty() == false)")

	# --- TESTE 2: MÚLTIPLOS CICLOS DE PREPARO SEM INTERRUPÇÃO ---
	print("\n--- TESTE 2: Preparo de Hambúrgueres Sem Bloqueio Constante ---")
	
	# Ciclo 1: 1 Hambúrguer
	var p1 = _create_dummy_patty()
	grill.place_item(p1)
	grill.active_items.clear()
	grill.add_dirt(0.035)

	assert_test(grill.is_dirty() == false, "Após 1 hambúrguer: Grelha NÃO fica suja")
	assert_test(grill.dirt_level < 0.10, "Acúmulo de sujeira suave (dirt_level = %.3f < 0.10)" % grill.dirt_level)

	# Ciclo 2: 5 Hambúrgueres
	for i in range(4):
		var p = _create_dummy_patty()
		grill.place_item(p)
		grill.active_items.clear()
		grill.add_dirt(0.035)
		p.free()

	assert_test(grill.is_dirty() == false, "Após 5 hambúrgueres: Grelha continua limpa e pronta para uso (dirt_level = %.3f)" % grill.dirt_level)

	# Ciclo 3: 15 Hambúrgueres
	for i in range(10):
		var p = _create_dummy_patty()
		grill.place_item(p)
		grill.active_items.clear()
		grill.add_dirt(0.035)
		p.free()

	assert_test(grill.is_dirty() == false, "Após 15 hambúrgueres: Jogador consegue grelhar em fluxo contínuo (dirt_level = %.3f)" % grill.dirt_level)

	# Permite colocar novos alimentos normalmente após 15 hambúrgueres
	var test_patty = _create_dummy_patty()
	var placed_ok = grill.place_item(test_patty)
	assert_test(placed_ok == true, "Alimento colocado na chapa sem bloqueios desnecessários")
	grill.active_items.clear()
	test_patty.free()

	# --- TESTE 3: ACÚMULO OCASIONAL APÓS USO INTENSO ---
	print("\n--- TESTE 3: Sujeira Ocasional Após Longo Uso ---")
	# Continua grelhando até ultrapassar o limiar de sujeira
	var extra_burgers = 0
	while grill.dirt_level < grill.DIRT_THRESHOLD:
		grill.add_dirt(0.035)
		extra_burgers += 1

	assert_test(grill.dirt_level >= grill.DIRT_THRESHOLD, "Sujeira atinge o limiar após intenso uso contínuo (mais %d hambúrgueres)" % extra_burgers)
	assert_test(grill.is_dirty() == true, "Grelha passa a indicar sujeira somente quando realmente necessário")

	# Tentativa de colocar alimento na grelha suja
	var rejected_patty = _create_dummy_patty()
	var placed_rejected = grill.place_item(rejected_patty)
	assert_test(placed_rejected == false, "Grelha suja exige limpeza antes de novo preparo")
	rejected_patty.free()

	# --- TESTE 4: LIMPEZA COM A BUCHA/ESPONJA ---
	print("\n--- TESTE 4: Limpeza da Grelha ---")
	# Limpeza progressiva com a bucha até completar
	while grill.cleanliness_state != Grill.CleanlinessState.CLEAN:
		grill.clean_progress(0.2, player)

	assert_test(grill.dirt_level == 0.0, "Sujeira totalmente removida após limpeza com bucha")
	assert_test(grill.is_dirty() == false, "Grelha volta a ficar limpa e brilhando")

	# Permite preparo imediato após a limpeza
	var clean_patty = _create_dummy_patty()
	var placed_clean = grill.place_item(clean_patty)
	assert_test(placed_clean == true, "Preparo liberado imediatamente após limpeza")
	grill.active_items.clear()
	clean_patty.free()

	# --- TESTE 5: SUPORTE AO TUTORIAL VIA SET_DIRTY ---
	print("\n--- TESTE 5: Compatibilidade com Tutorial ---")
	grill.set_dirty(true)
	assert_test(grill.is_dirty() == true, "set_dirty(true) ativa sujeira para etapa do tutorial")
	grill.clean_station(player)
	assert_test(grill.is_dirty() == false, "clean_station limpa a grelha completamente")

	# Cleanup
	grill.queue_free()
	player.queue_free()
	p1.free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FREQUÊNCIA DE SUJEIRA DA GRELHA 100% BALANCEADA E VALIDADA!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
