extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE REFINAMENTO FINAL DAS ETAPAS DO TUTORIAL (V7)
# ==============================================================================

const TutorialController = preload("res://src/ui/tutorial.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")

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
	print("=== BURGER RUSH - TESTE DE REFINAMENTO DAS ETAPAS DO TUTORIAL V7 ===")
	print("=================================================================")

	var sm = SaveManager.new()
	sm.name = "SaveManager"
	root.add_child(sm)
	sm.create_new_career(1, "Miller")
	sm.load_game(1)

	var gm = GameManager.new()
	gm.name = "GameManager"
	root.add_child(gm)

	var tut_res = load("res://src/ui/tutorial.tscn")
	var tut = tut_res.instantiate() as TutorialController
	root.add_child(tut)

	# --- TESTE 1: Textos e Instruções Refinadas das Etapas ---
	print("\n--- TESTE 1: Verificação de Textos e Coerência das Etapas ---")
	
	# Etapa 3 — PC Administrativo na Cozinha
	var s3 = tut.steps[2]
	assert_test(s3.instruction.contains("cozinha") and s3.instruction.contains("[E]"), "Etapa 3: PC localizado na cozinha com acesso por [E]")
	
	# Etapa 4 — Caixa no Pallet Externo
	var s4 = tut.steps[3]
	assert_test(s4.instruction.contains("PALLET EXTERNO") and s4.instruction.contains("armazém"), "Etapa 4: Pallet externo do restaurante e transporte ao armazém")
	
	# Etapa 6 — Máquina de Refrigerante
	var s5 = tut.steps[5]
	assert_test(s5.instruction.contains("MESA DE EMBALAGENS") and s5.instruction.contains("[E]"), "Etapa 6: Copo na mesa de embalagens e posicionamento com tecla [E]")
	
	# Etapa 7 — Máquina de Suco Natural
	var s6 = tut.steps[6]
	assert_test(s6.instruction.contains("ESTOQUE") and s6.instruction.contains("[E]"), "Etapa 7: Polpa no estoque/armazém e posicionamento com [E]")
	
	# Etapa 8 — Fritadeira Comercial
	var s7 = tut.steps[7]
	assert_test(s7.instruction.contains("BATATAS") and s7.instruction.contains("CEBOLA") and s7.instruction.contains("embalagens"), "Etapa 8: Fritadeira prepara batatas e cebolas, embalagens na mesa")
	
	# Etapa 11 — Estação de Embalagem
	var s10 = tut.steps[10]
	assert_test(s10.instruction.contains("Caixa de Hambúrguer") and s10.instruction.contains("Saco de Delivery") and s10.instruction.contains("Salão"), "Etapa 11: Diferenciação clara entre Salão (Caixa/Bandeja) e Delivery/Drive-thru (Saco)")
	
	# Etapa 12 — Atendimento no Salão e Bandeja
	var s11 = tut.steps[11]
	assert_test(s11.instruction.contains("balcão") and s11.instruction.contains("Bandeja de Serviço") and s11.instruction.contains("cliente"), "Etapa 12: Bandeja disponível no balcão e entrega ao cliente")

	# --- TESTE 2: Estabilidade do Indicador 3D (Sem Recriação Contínua / Sem Piscar) ---
	print("\n--- TESTE 2: Estabilidade e Não-Duplicação de Highlights 3D ---")
	var dummy_target = Node3D.new()
	dummy_target.name = "DummyStation"
	root.add_child(dummy_target)

	# Primeira criação
	tut._create_highlight(dummy_target, "Indicador Teste [E]")
	assert_test(tut.current_highlight_marker != null, "Highlight criado com sucesso")
	var initial_marker = tut.current_highlight_marker
	var child_count_1 = dummy_target.get_child_count()
	assert_test(child_count_1 == 1, "Exatamente 1 nó de highlight adicionado no alvo")

	# Segunda chamada idêntica (como ocorre a cada 0.15s no loop)
	tut._create_highlight(dummy_target, "Indicador Teste [E]")
	assert_test(tut.current_highlight_marker == initial_marker, "Marcador preservado sem recriação (estável)")
	assert_test(dummy_target.get_child_count() == 1, "Nenhum nó duplicado criado")

	# Limpeza do destaque
	tut._clear_highlight()
	assert_test(tut.current_highlight_marker == null, "Marcador zerado no clear_highlight")

	dummy_target.queue_free()

	# --- TESTE 3: Finalização do Treinamento e Transição ---
	print("\n--- TESTE 3: Mensagens de Finalização do Treinamento ---")
	tut._show_congrats_panel()
	assert_test(tut.congrats_title.text.contains("TREINAMENTO CONCLUÍDO"), "Painel de parabéns com título de treinamento concluído")
	assert_test(tut.start_day_button.text == "COMEÇAR DIA 1", "Botão de início com texto 'COMEÇAR DIA 1'")

	tut.queue_free()
	gm.queue_free()
	sm.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 TODOS OS AJUSTES FINAIS DO TUTORIAL V7 FORAM VALIDADOS COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
