extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DA PLACA INTEGRADA (SEM ERROS DE TEXTURA) E TETO DO SALÃO
# ==============================================================================

const OpenSignClass = preload("res://src/stations/open_sign.gd")
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
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE: PLACA INTEGRADA E TETO DO SALÃO =======")
	print("=================================================================")

	# --------------------------------------------------------------------------
	# PARTE 1: PLACA DE ABRIR/FECHAR O RESTAURANTE (OPEN SIGN)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Estrutura da Placa (open_sign.tscn) ---")
	var sign_scene = load("res://src/stations/open_sign.tscn")
	assert_test(sign_scene != null, "Cena open_sign.tscn carregada com sucesso")

	var open_sign = sign_scene.instantiate() as OpenSignClass
	root.add_child(open_sign)

	# Verifica o material da lousa (não pode ter ViewportTexture quebrada que causa magenta)
	var chalk_mesh = open_sign.get_node_or_null("Model/EaselFront/ChalkAreaFront") as MeshInstance3D
	assert_test(chalk_mesh != null, "Malha da lousa 'ChalkAreaFront' presente no cavalete")
	var mat = chalk_mesh.mesh.material as StandardMaterial3D
	assert_test(mat != null, "Material StandardMaterial3D configurado na lousa")
	assert_test(mat.albedo_texture == null, "Sem textura dinâmica externa ViewportTexture (elimina padrão roxo/quadriculado)")
	assert_test(mat.albedo_color.r < 0.2 and mat.albedo_color.g < 0.2 and mat.albedo_color.b < 0.2, "Cor da lousa é ardósia escura sólida e realista")

	# Verifica o texto integrado na face da lousa
	var sign_content = open_sign.get_node_or_null("Model/EaselFront/ChalkAreaFront/SignContent") as Label3D
	assert_test(sign_content != null, "SignContent (Label3D) presente como filho direto da lousa ChalkAreaFront")
	assert_test(sign_content.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "billboard = DISABLED (texto plano e fixado na superfície da madeira)")
	assert_test(sign_content.transform.origin.z <= 0.015, "Texto fixado rente à face da lousa (Z <= 0.015m, sem flutuação)")
	assert_test(sign_content.text.contains("BURGER RUSH"), "Título 'BURGER RUSH' presente no quadro")
	assert_test(sign_content.text.contains("10:00 — 22:00"), "Horário oficial '10:00 — 22:00' presente no quadro")

	# --- TESTE 2: LÓGICA DE INTERAÇÃO E ATUALIZAÇÃO DA PLACA ---
	print("\n--- TESTE 2: Lógica de Interação da Placa ---")
	var clock = GameClock.new()
	root.add_child(clock)
	clock.day_number = 1
	clock.current_hour = 9
	clock.current_minute = 0
	clock.state = GameClock.State.PREPARATION

	open_sign._update_sign()
	assert_test(open_sign.get_interaction_prompt().contains("Abrir"), "Prompt correto no estado PREPARATION")
	assert_test(sign_content.text.contains("FECHADO"), "Texto da lousa exibe FECHADO em PREPARATION")
	assert_test(sign_content.text.contains("10:00 — 22:00"), "Horário preservado em PREPARATION")

	# Interage para abrir
	open_sign.interact(null)
	assert_test(clock.state == GameClock.State.OPEN, "Interação abriu o restaurante")
	assert_test(open_sign.get_interaction_prompt().contains("Aberto"), "Prompt correto no estado OPEN")
	assert_test(sign_content.text.contains("ABERTO"), "Texto da lousa exibe ABERTO no estado OPEN")

	# Simula horário de fechamento
	clock.state = GameClock.State.CLOSING
	open_sign._update_sign()
	assert_test(open_sign.get_interaction_prompt().contains("Finalizar Dia"), "Prompt correto no estado CLOSING")
	assert_test(sign_content.text.contains("ENCERRANDO"), "Texto da lousa exibe ENCERRANDO em CLOSING")

	# --------------------------------------------------------------------------
	# PARTE 2: TETO DO SALÃO DO RESTAURANTE (MAIN.TSCN)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Teto da Área de Mesas (Salão) em main.tscn ---")
	var main_scene = load("res://src/main.tscn")
	assert_test(main_scene != null, "Cena main.tscn carregada com sucesso")

	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)

	var ceiling_dining = main_inst.get_node_or_null("Room/CeilingDining") as CSGBox3D
	var ceiling_kitchen = main_inst.get_node_or_null("Room/CeilingKitchen") as CSGBox3D
	var ceiling_storage = main_inst.get_node_or_null("Room/CeilingStorage") as CSGBox3D

	assert_test(ceiling_dining != null, "Nó 'CeilingDining' presente no salão de mesas")
	assert_test(ceiling_kitchen != null, "Nó 'CeilingKitchen' presente na cozinha")
	assert_test(ceiling_storage != null, "Nó 'CeilingStorage' presente no armazém")

	var dining_mat = ceiling_dining.material as StandardMaterial3D
	assert_test(dining_mat != null, "Material do teto do salão configurado")
	print("  [INFO] Cor do Teto do Salão: ", dining_mat.albedo_color)

	# Verifica se é um amarelo-claro suave (R alto, G alto, B intermediário-alto)
	var col = dining_mat.albedo_color
	var is_light_yellow = (col.r >= 0.90 and col.g >= 0.88 and col.b >= 0.65 and col.b <= 0.85 and col.r > col.b)
	assert_test(is_light_yellow, "Teto do salão possui tonalidade amarelo-claro suave e aconchegante")

	# Verifica que cozinha e armazém permanecem com material neutro
	var kitchen_mat = ceiling_kitchen.material as StandardMaterial3D
	assert_test(kitchen_mat != null and kitchen_mat.albedo_color != dining_mat.albedo_color, "Teto da cozinha NÃO foi alterado para amarelo (mantém material padrão)")

	# Cleanup
	open_sign.queue_free()
	clock.queue_free()
	main_inst.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 PLACA INTEGRADA E TETO AMALERO DO SALÃO 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
