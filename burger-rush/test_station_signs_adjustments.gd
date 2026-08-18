extends SceneTree

# ================================================================
# TESTE: VALIDAÇÃO DAS PLACAS FÍSICAS (BANDEJAS, CAIXA, DRIVE-THRU, REFIL)
# ================================================================

var total_tests = 0
var passed_tests = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=== INICIANDO TESTES DAS PLACAS FÍSICAS AJUSTADAS ===")
	call_deferred("_run_tests")

func _run_tests() -> void:
	# ── TESTE 1: PLACA BANDEJAS — DOIS LADOS DO BALCÃO ──
	print("\n--- 1. Testando Placa BANDEJAS (Dois Lados) ---")
	var tray_stack_scene = load("res://src/stations/serving_tray_stack.tscn")
	var tray_stack = tray_stack_scene.instantiate()
	root.add_child(tray_stack)

	var tray_sign_front = tray_stack.get_node_or_null("Model/PhysicalSign")
	var tray_sign_kitchen = tray_stack.get_node_or_null("Model/PhysicalSignKitchen")
	assert_test(tray_sign_front != null, "Placa frontal 'BANDEJAS' (voltada para as mesas) existe")
	assert_test(tray_sign_kitchen != null, "Placa traseira 'BANDEJAS' (voltada para a cozinha) existe")

	if tray_sign_front and tray_sign_kitchen:
		var lbl_front = tray_sign_front.get_node_or_null("SignLabel") as Label3D
		var lbl_kitchen = tray_sign_kitchen.get_node_or_null("SignLabel") as Label3D
		assert_test(lbl_front != null and lbl_front.text == "BANDEJAS", "Texto da placa frontal é 'BANDEJAS'")
		assert_test(lbl_kitchen != null and lbl_kitchen.text == "BANDEJAS", "Texto da placa da cozinha é 'BANDEJAS'")

	# ── TESTE 2: PLACA CAIXA — DOIS LADOS (SEM ÍCONES) ──
	print("\n--- 2. Testando Placa CAIXA (Dois Lados - Somente Palavra CAIXA) ---")
	var cash_scene = load("res://src/stations/cash_register.tscn")
	var cash = cash_scene.instantiate()
	root.add_child(cash)

	var cash_sign_front = cash.get_node_or_null("PhysicalCashSign")
	var cash_sign_kitchen = cash.get_node_or_null("PhysicalCashSignKitchen")
	assert_test(cash_sign_front != null, "Placa frontal 'CAIXA' (voltada para o salão) existe")
	assert_test(cash_sign_kitchen != null, "Placa traseira 'CAIXA' (voltada para a cozinha) existe")

	if cash_sign_front and cash_sign_kitchen:
		var lbl_c_front = cash_sign_front.get_node_or_null("SignLabel") as Label3D
		var lbl_c_kitchen = cash_sign_kitchen.get_node_or_null("SignLabel") as Label3D
		assert_test(lbl_c_front != null and lbl_c_front.text == "CAIXA", "Texto da placa frontal é exatamente 'CAIXA' (sem ícone de cartão/dinheiro)")
		assert_test(lbl_c_kitchen != null and lbl_c_kitchen.text == "CAIXA", "Texto da placa da cozinha é exatamente 'CAIXA' (sem ícone de cartão/dinheiro)")

	# ── TESTE 3: PLACA DRIVE-THRU (COM DESENHO/ÍCONE DE CARRO) ──
	print("\n--- 3. Testando Placa DRIVE-THRU com Ícone de Carro ---")
	var main_scene = load("res://src/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	var dt_sign_group = main_node.get_node_or_null("Room/DriveThruSignGroup")
	assert_test(dt_sign_group != null, "Grupo da placa de Drive-Thru existe no Room")
	if dt_sign_group:
		var dt_kitchen = dt_sign_group.get_node_or_null("SignKitchen") as Label3D
		var dt_exterior = dt_sign_group.get_node_or_null("SignExterior") as Label3D
		assert_test(dt_kitchen != null and "🚗" in dt_kitchen.text and "DRIVE-THRU" in dt_kitchen.text, "Placa interna de Drive-Thru contém o carrinho e texto: '%s'" % (dt_kitchen.text if dt_kitchen else ""))
		assert_test(dt_exterior != null and "🚗" in dt_exterior.text and "DRIVE-THRU" in dt_exterior.text, "Placa externa de Drive-Thru contém o carrinho e texto: '%s'" % (dt_exterior.text if dt_exterior else ""))

	# ── TESTE 4: PLACA REFIL REFRIGERANTES (ENCOSTADA NA PAREDE ATRÁS DOS CILINDROS) ──
	print("\n--- 4. Testando Posição da Placa REFIL REFRIGERANTES ---")
	var soda_rack_scene = load("res://src/stations/soda_refill_rack.tscn")
	var soda_rack = soda_rack_scene.instantiate()
	root.add_child(soda_rack)

	var soda_sign = soda_rack.get_node_or_null("Model/PhysicalSign")
	assert_test(soda_sign != null, "Placa física 'REFIL REFRIGERANTES' existe")
	if soda_sign:
		var lbl_soda = soda_sign.get_node_or_null("SignLabel") as Label3D
		assert_test(lbl_soda != null and lbl_soda.text == "REFIL REFRIGERANTES", "Texto da placa é 'REFIL REFRIGERANTES'")
		assert_test(soda_sign.transform.origin.z == -0.25, "Placa está encostada na parede atrás dos cilindros (Z = -0.25)")
		assert_test(soda_sign.transform.origin.y >= 1.70 and soda_sign.transform.origin.y <= 2.0, "Placa está em altura de leitura confortável (Y = %.2fm)" % soda_sign.transform.origin.y)

	# ── RELATÓRIO FINAL ──
	print("\n=======================================================")
	print("RESULTADO DOS TESTES: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DE PLACAS PASSARAM COM SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
