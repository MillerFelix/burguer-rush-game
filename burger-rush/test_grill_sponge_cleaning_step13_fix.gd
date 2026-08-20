extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE VALIDAÇÃO DO FIX DE LIMPEZA DA GRELHA NO TUTORIAL (ETAPA 13)
# ==============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")

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
	call_deferred("run_test")

func run_test() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE DE FIX DA LIMPEZA DA GRELHA (ETAPA 13) ===")
	print("=================================================================")

	var main_scene_res = load("res://src/main.tscn")
	if not main_scene_res:
		print("❌ Falha ao carregar main.tscn")
		quit(1)
		return

	var main_scene = main_scene_res.instantiate()
	root.add_child(main_scene)

	var tut_scene_res = load("res://src/ui/tutorial.tscn")
	var tut = tut_scene_res.instantiate() as TutorialController
	root.add_child(tut)

	var player = main_scene.find_child("Player", true, false)
	var grill = main_scene.find_child("Grill", true, false)
	var sink = main_scene.find_child("CommercialSink", true, false)

	assert_test(player != null, "Player instanciado na cena")
	assert_test(grill != null, "Grill instanciado na cena")
	assert_test(sink != null, "CommercialSink instanciado na cena")

	# 1. Configura Etapa 12 (Limpeza da Grelha)
	tut._apply_step(12)
	tut.transition_timer = 0.0
	assert_test(tut.current_step_index == 12, "Posicionado na etapa de limpeza da grelha (Etapa 13 da UI)")
	assert_test(grill.is_dirty() == true, "Grelha inicializada com sujeira")

	# 2. Testa _get_target_interactable para Grill
	var target_interactable = player._get_target_interactable(grill)
	assert_test(target_interactable == grill, "_get_target_interactable reconhece a Grelha corretamente")

	# 3. Equipar Bucha (Slot 2)
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	assert_test(player.active_tool_slot == Player.ToolSlot.SPONGE, "Bucha de limpeza equipada no Slot 2")

	# 4. Simula o Raycast mirando na Grelha e executando clean_progress
	var is_cleaned = grill.clean_progress(1.5, player)
	assert_test(is_cleaned == true, "Grelha limpa com sucesso através de clean_progress")
	assert_test(grill.is_dirty() == false, "Grelha agora está 100% limpa (dirt_level = 0)")
	assert_test(player.sponge_is_dirty == true, "Bucha ficou suja após a limpeza da grelha")

	# 5. Valida prompt da pia quando bucha está suja
	var sink_prompt = sink.get_interaction_prompt(player)
	assert_test(sink_prompt.contains("Lavar Bucha"), "Pia exibe prompt para lavar a bucha")

	# 6. Simula lavagem da bucha na pia
	sink.wash_or_sanitize(player)
	assert_test(player.sponge_is_dirty == false, "Bucha limpa e higienizada na pia")

	# 7. Checa avanço da etapa no tutorial
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 13, "Tutorial avançou com sucesso da etapa de limpeza para a etapa de pagamento!")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FIX DA ETAPA 13 VALIDADO COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
