extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: ETIQUETA DAS BANDEJAS & SOM DA LIXEIRA
# =============================================================================

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: ETIQUETA DAS BANDEJAS & SOM DA LIXEIRA (BURGER RUSH)")
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

	print("--- TESTE 1: Etiqueta das Bandejas (Voltada para a Cozinha e Abaixo das Bandejas) ---")
	var tray_stack: ServingTrayStack = root_node.get_node_or_null("ServingTrayStack")
	assert_test(tray_stack != null, "Pilha de Bandejas (ServingTrayStack) presente no balcão")

	if tray_stack:
		var badge_node = tray_stack.get_node_or_null("Model/CounterFrontBadge")
		assert_test(badge_node != null, "Etiqueta física (CounterFrontBadge) colada no balcão")

		if badge_node:
			var label: Label3D = badge_node.get_node_or_null("Label") as Label3D
			assert_test(label != null, "Label3D da etiqueta presente")
			if label:
				assert_test(label.text == "BANDEJAS PARA ENTREGA",
					"Texto da etiqueta é 'BANDEJAS PARA ENTREGA'")
				assert_test(label.billboard == BaseMaterial3D.BILLBOARD_DISABLED,
					"Etiqueta física plana integrada ao balcão (sem billboard)")
				assert_test(label.font_size <= 16,
					"Fonte pequena e discreta (tamanho: %d)" % label.font_size)

			# Verifica que a etiqueta está voltada para o lado do jogador / cozinha (Z negativo e rotacionada para -Z)
			assert_test(badge_node.position.z < 0.0,
				"Etiqueta posicionada na face voltada para a cozinha (Z = %.3fm)" % badge_node.position.z)
			assert_test(badge_node.position.y < 0.0,
				"Etiqueta posicionada mais abaixo da base das bandejas (Y = %.3fm)" % badge_node.position.y)
			assert_test(is_equal_approx(abs(badge_node.rotation.y), PI),
				"Etiqueta rotacionada para dentro da cozinha na direção do cozinheiro (rot_y = %.2f rad)" % badge_node.rotation.y)

	print("\n--- TESTE 2: Som Procedural e Componente de Áudio na Lixeira ---")
	var trash_bin: TrashBin = root_node.get_node_or_null("TrashBin")
	assert_test(trash_bin != null, "Lixeira (TrashBin) presente na cena")

	if trash_bin:
		assert_test(trash_bin.get_node_or_null("StatusLabel") == null,
			"Nenhum texto/label flutuante na lixeira")
		assert_test(trash_bin.audio_player != null,
			"AudioPlayer3D configurado na lixeira")

	var sound_stream = SoundSynthesizer.get_stream("trash_dispose")
	assert_test(sound_stream != null and sound_stream.data.size() > 0,
		"Efeito sonoro 'trash_dispose' sintetizado com sucesso no SoundSynthesizer")

	print("\n--- TESTE 3: Descarte de Alimentos com Reprodução de Som e Atualização de Estoque ---")
	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo")

	if player and trash_bin:
		# 3.1 Descarte de Pão (BreadTop)
		var bread_scene = load("res://src/items/bread_top.tscn")
		var bread = bread_scene.instantiate()
		root_node.add_child(bread)
		player.pick_up(bread)
		assert_test(player.held_item == bread, "Jogador segurando pão")

		trash_bin.interact(player)
		assert_test(player.held_item == null, "Pão descartado da mão")
		assert_test(bread.is_queued_for_deletion(), "Pão removido do jogo")
		assert_test(trash_bin.audio_player.playing or trash_bin.audio_player.stream != null,
			"Som de descarte acionado no AudioPlayer da lixeira")

		# 3.2 Descarte de Carne (Patty)
		var patty_scene = load("res://src/items/patty.tscn")
		var patty = patty_scene.instantiate()
		root_node.add_child(patty)
		player.pick_up(patty)
		assert_test(player.held_item == patty, "Jogador segurando carne")

		trash_bin.interact(player)
		assert_test(player.held_item == null, "Carne descartada da mão")
		assert_test(patty.is_queued_for_deletion(), "Carne removida do jogo")

		# 3.3 Descarte de Bebida
		var drink_scene = load("res://src/items/drink_cup.tscn")
		var drink = drink_scene.instantiate()
		root_node.add_child(drink)
		player.pick_up(drink)
		assert_test(player.held_item == drink, "Jogador segurando bebida")

		trash_bin.interact(player)
		assert_test(player.held_item == null, "Bebida descartada da mão")
		assert_test(drink.is_queued_for_deletion(), "Bebida removida do jogo")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
