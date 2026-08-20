extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE DO FLUXO REAL: SALVAR -> FECHAR -> ABRIR -> CONTINUAR
# =============================================================================

const SaveManagerClass = preload("res://src/core/save_manager.gd")
const GameManagerClass = preload("res://src/core/game_manager.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")

var pass_count: int = 0
var total_count: int = 0
var sim_dir: String = "user://sim_real_saves"

func assert_sim(cond: bool, msg: String) -> void:
	total_count += 1
	if cond:
		pass_count += 1
		print("  [PASS] %s" % msg)
	else:
		printerr("  [FAIL] %s" % msg)

func _init() -> void:
	print("\n=================================================================")
	print("=== SIMULAÇÃO REAL: SALVAR -> FECHAR -> ABRIR -> CONTINUAR ===")
	print("=================================================================\n")

	_cleanup()
	DirAccess.make_dir_recursive_absolute(sim_dir)

	# --- ETAPA 1: Sessão 1 - Jogador joga e salva no Slot 1 ---
	print("--- ETAPA 1: Sessão 1 (Novo Jogo -> Slot 1 -> Progresso -> Save) ---")
	var sm1 = SaveManagerClass.new()
	sm1.set_custom_save_dir(sim_dir)
	root.add_child(sm1)

	var eco1 = EconomyManagerClass.new()
	eco1.name = "EconomyManager"
	root.add_child(eco1)

	var clock1 = GameClockClass.new()
	clock1.name = "GameClock"
	root.add_child(clock1)

	# Inicia no Slot 1
	sm1.set_active_slot(1)
	sm1.has_active_game = true

	# Simula gameplay: ganha dinheiro e avança dias
	eco1.current_money = 645.50
	clock1.day_number = 3

	# Salva e fecha a sessão
	var saved1 = sm1.save_game(1)
	assert_sim(saved1 == true, "Sessão 1 gravou progresso no Slot 1 com sucesso")

	eco1.free()
	clock1.free()
	sm1.free()

	# --- ETAPA 2: Sessão 2 - Jogador joga e salva no Slot 2 ---
	print("\n--- ETAPA 2: Sessão 2 (Novo Jogo -> Slot 2 -> Progresso Diferente -> Save) ---")
	var sm2 = SaveManagerClass.new()
	sm2.set_custom_save_dir(sim_dir)
	root.add_child(sm2)

	var eco2 = EconomyManagerClass.new()
	eco2.name = "EconomyManager"
	root.add_child(eco2)

	var clock2 = GameClockClass.new()
	clock2.name = "GameClock"
	root.add_child(clock2)

	# Inicia no Slot 2 com outros dados
	sm2.set_active_slot(2)
	sm2.has_active_game = true
	eco2.current_money = 1250.00
	clock2.day_number = 7

	var saved2 = sm2.save_game(2)
	assert_sim(saved2 == true, "Sessão 2 gravou progresso no Slot 2 com sucesso")

	eco2.free()
	clock2.free()
	sm2.free()

	# --- ETAPA 3: Sessão 3 - Reabertura do jogo do zero (Menu -> Continuar) ---
	print("\n--- ETAPA 3: Sessão 3 (Reinicialização Completa -> Menu -> Continuar) ---")
	var sm3 = SaveManagerClass.new()
	sm3.set_custom_save_dir(sim_dir)
	root.add_child(sm3)

	assert_sim(sm3.has_any_save() == true, "SaveManager detecta saves existentes ao abrir o jogo")
	assert_sim(sm3.has_valid_save(1) == true, "Slot 1 permanece válido após reinício")
	assert_sim(sm3.has_valid_save(2) == true, "Slot 2 permanece válido após reinício")

	# Carrega e restaura Slot 1
	var eco3 = EconomyManagerClass.new()
	eco3.name = "EconomyManager"
	root.add_child(eco3)

	var clock3 = GameClockClass.new()
	clock3.name = "GameClock"
	root.add_child(clock3)

	sm3.load_game(1)
	assert_sim(eco3.current_money == 645.50, "Slot 1 restaurou R$ 645.50 no EconomyManager")
	assert_sim(clock3.day_number == 3, "Slot 1 restaurou Dia 3 no GameClock")

	# Carrega e restaura Slot 2
	sm3.load_game(2)
	assert_sim(eco3.current_money == 1250.00, "Slot 2 restaurou R$ 1250.00 no EconomyManager")
	assert_sim(clock3.day_number == 7, "Slot 2 restaurou Dia 7 no GameClock")

	eco3.free()
	clock3.free()
	sm3.free()
	_cleanup()

	print("\n=================================================================")
	print("RESULTADO DA SIMULAÇÃO: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL NA SIMULAÇÃO REAL DE CARREIRAS! <<<\n")
		quit(0)
	else:
		quit(1)

func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(sim_dir):
		var dir = DirAccess.open(sim_dir)
		if dir:
			dir.list_dir_begin()
			var fn = dir.get_next()
			while fn != "":
				if not dir.current_is_dir():
					dir.remove(fn)
				fn = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(sim_dir)
