extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE VALIDAÇÃO DO FLUXO DE PAGAMENTO NO TUTORIAL (ETAPA 14)
# ==============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const CustomerMoney = preload("res://src/items/customer_money.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")

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
	print("=== BURGER RUSH - TESTE DO FLUXO DE DINHEIRO NO CAIXA (ETAPA 14) ===")
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
	var cr = main_scene.find_child("CashRegister", true, false) as CashRegister

	assert_test(player != null, "Player instanciado na cena")
	assert_test(cr != null, "CashRegister instanciado na cena")

	# 1. Ativa a Etapa 13 (UI Etapa 14 - Recebimento e Caixa Registradora)
	tut._apply_step(13)
	tut.transition_timer = 0.0
	assert_test(tut.current_step_index == 13, "Posicionado na etapa de pagamento (Etapa 14)")

	# 2. Verifica se o CustomerMoney foi instanciado no balcão em frente ao caixa
	var moneys = root.find_children("", "CustomerMoney", true, false)
	assert_test(moneys.size() > 0, "Dinheiro do cliente instanciado com sucesso no balcão")
	var money = moneys[0] as CustomerMoney
	assert_test(money != null and is_instance_valid(money), "Objeto CustomerMoney válido na cena")

	# 3. Jogador pega o dinheiro na bancada
	money.interact(player)
	assert_test(player.held_item == money, "Jogador pegou o dinheiro na mão")
	assert_test(player.held_item.get("is_customer_deposit_money") == true, "Item segurado é dinheiro de depósito do cliente")

	# 4. Jogador interage com a Caixa Registradora [E]
	cr.interact(player)
	assert_test(player.held_item == null, "Dinheiro depositado no caixa e retirado da mão do jogador")
	assert_test(cr.is_drawer_open == true or cr.register_balance >= 35.0, "Gaveta do caixa aberta e saldo registrado")

	# 5. Tutorial reconhece o depósito e avança para a próxima etapa
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 14, "Tutorial avançou com sucesso para a Etapa 15 (Placa de Abertura)!")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FLUXO DE PAGAMENTO DA ETAPA 14 VALIDADO COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
