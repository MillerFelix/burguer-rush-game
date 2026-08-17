extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: RESERVA DE REFIS DE REFRIGERANTE NO ARMAZÉM
# (Posicionamento no Canto Noroeste, Etiqueta na Base e Passagem Desobstruída)
# =============================================================================

const SodaRefillRack = preload("res://src/stations/soda_refill_rack.gd")
const SyrupCanister = preload("res://src/items/syrup_canister.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: REPOSICIONAMENTO E IDENTIFICAÇÃO DOS REFIS DE REFRIGERANTE")
	print("=".repeat(75) + "\n")
	call_deferred("_run_tests")

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("ERRO CRÍTICO: Não foi possível carregar main.tscn")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	print("--- TESTE 1: Posicionamento no Canto Noroeste e Desobstrução da Passagem Externa ---")
	var rack: SodaRefillRack = root_node.get_node_or_null("SodaRefillRack")
	assert_test(rack != null, "Suporte de Refis (SodaRefillRack) encontrado na cena")

	if rack:
		# Verifica que está recuado no canto Noroeste (Z <= -6.0)
		assert_test(rack.global_position.z <= -6.0,
			"Suporte posicionado no canto Noroeste do armazém (Z = %.2fm)" % rack.global_position.z)
		assert_test(rack.global_position.x <= -8.4,
			"Suporte encostado na parede Oeste (X = %.2fm)" % rack.global_position.x)

		# Verifica que a área da doca/porta externa (Z entre -5.0 e -2.0) está completamente desobstruída
		var distance_to_dock_door = abs(rack.global_position.z - (-3.5))
		assert_test(distance_to_dock_door >= 2.5,
			"Passagem para a doca externa 100%% livre e desobstruída (distância da porta = %.2fm)" % distance_to_dock_door)

	print("\n--- TESTE 2: Altura da Estrutura e Etiqueta na Base Frontal ---")
	if rack:
		var col_shape: BoxShape3D = rack.get_node("CollisionShape3D").shape as BoxShape3D
		assert_test(col_shape.size.y >= 0.70, "Estrutura do suporte com altura adequada (%.2fm)" % col_shape.size.y)

		var badge = rack.get_node_or_null("Model/FrontBadge")
		assert_test(badge != null, "Área de identificação física (FrontBadge) presente na base frontal")
		if badge:
			assert_test(badge.position.y <= 0.12,
				"Etiqueta posicionada na parte inferior/base frontal do suporte (Y = %.3fm)" % badge.position.y)

			var label: Label3D = badge.get_node_or_null("Label") as Label3D
			assert_test(label != null, "Label3D da etiqueta presente")
			if label:
				assert_test(label.text == "INSUMOS DE REFRIGERANTE" or label.text == "REFIS DE TROCA — REFRIGERANTES",
					"Texto da etiqueta atualizado: %s" % label.text)
				assert_test(label.billboard == BaseMaterial3D.BILLBOARD_DISABLED,
					"Etiqueta física plana integrada à base metálica (sem billboard)")
				assert_test(label.font_size <= 16,
					"Fonte pequena e discreta (tamanho: %d)" % label.font_size)

	print("\n--- TESTE 3: Quatro Espaços e Reserva Inicial (1 Refil de Cada Sabor) ---")
	if rack:
		assert_test(rack.canisters.size() == 4, "Suporte possui 4 espaços definidos")
		assert_test(rack.has_reserve(0) and rack.has_reserve(1) and rack.has_reserve(2) and rack.has_reserve(3),
			"Todos os 4 sabores possuem 1 reserva inicial (Cola, Cola Zero, Soda, Citrus)")

		var c0 = rack.canisters[0]
		var c1 = rack.canisters[1]
		var c2 = rack.canisters[2]
		var c3 = rack.canisters[3]

		assert_test(c0.item_id == "syrup_cola" and c0.current_amount == 25.0, "Refil de Cola configurado e cheio")
		assert_test(c1.item_id == "syrup_cola_zero" and c1.current_amount == 25.0, "Refil de Cola Zero configurado e cheio")
		assert_test(c2.item_id == "syrup_lemon" and c2.current_amount == 25.0, "Refil de Soda configurado e cheio")
		assert_test(c3.item_id == "syrup_orange" and c3.current_amount == 25.0, "Refil de Citrus configurado e cheio")

	print("\n--- TESTE 4: Retirada e Reabastecimento com Limite de 1 por Sabor ---")
	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo")

	if player and rack:
		# Pega refil de Cola
		var cola = rack.take_canister(0)
		assert_test(cola != null, "Refil de Cola retirado do suporte")
		assert_test(not rack.has_reserve(0), "Espaço de Cola ficou vazio no suporte")

		# Tenta colocar refil duplicado de Soda no espaço de Cola (rejeita sabor incorreto)
		var can_scene = load("res://src/items/syrup_canister.tscn")
		var extra_soda: SyrupCanister = can_scene.instantiate()
		extra_soda.flavor_type = "soda_lime"
		assert_test(not rack.place_canister(0, extra_soda), "Não permite colocar refil de Soda no espaço de Cola")

		# Tenta colocar extra_soda no espaço 2 (Soda) que já está ocupado
		assert_test(not rack.place_canister(2, extra_soda), "Rejeita segundo refil de Soda (Limite estrito de 1 reserva)")
		extra_soda.queue_free()

		# Devolve a Cola para o espaço 0 vazio
		assert_test(rack.place_canister(0, cola), "Refil de Cola devolvido com sucesso ao espaço 0")
		assert_test(rack.has_reserve(0), "Espaço 0 novamente ocupado com 1 refil")

	print("\n--- TESTE 5: Integração com a Máquina de Refrigerantes ---")
	var drink_machine: DrinkMachine = root_node.get_node_or_null("DrinkMachine")
	assert_test(drink_machine != null, "Máquina de refrigerantes presente")

	if drink_machine and player and rack:
		drink_machine.is_door_open = true
		var old_can = drink_machine.remove_canister(0, player)
		assert_test(old_can != null, "Barril antigo retirado da máquina de refrigerantes")

		var fresh_can = rack.take_canister(0)
		assert_test(fresh_can != null, "Pegou refil novo de Cola no suporte do armazém")
		assert_test(drink_machine.insert_canister(0, fresh_can, player), "Refil novo inserido com sucesso na máquina")
		assert_test(drink_machine.canisters[0] == fresh_can, "Máquina de refrigerantes abastecida")

		if old_can:
			old_can.queue_free()

	print("\n--- TESTE 6: Etiqueta das Bandejas no Balcão Principal ---")
	var tray_stack: ServingTrayStack = root_node.get_node_or_null("ServingTrayStack")
	assert_test(tray_stack != null, "Pilha de Bandejas presente")

	if tray_stack:
		var badge = tray_stack.get_node_or_null("Model/CounterFrontBadge")
		assert_test(badge != null, "Etiqueta física (CounterFrontBadge) presente")
		if badge:
			var label: Label3D = badge.get_node_or_null("Label") as Label3D
			assert_test(label != null and label.text == "BANDEJAS PARA ENTREGA",
				"Texto da etiqueta é 'BANDEJAS PARA ENTREGA'")
			assert_test(badge.position.z <= -0.34,
				"Etiqueta no bordo voltado para a cozinha (Z = %.3fm)" % badge.position.z)

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
