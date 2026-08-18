extends SceneTree

# =============================================================================
# TEST SUITE: QUADRO DE CARDÁPIO CENTRALIZADO & REMOÇÃO DO TEXTO POWER
# =============================================================================

const DiningMenuBoardScene: PackedScene = preload("res://src/environment/dining_menu_board.tscn")
const JuiceMachineScene: PackedScene = preload("res://src/stations/juice_machine.tscn")
const DrinkMachineScene: PackedScene = preload("res://src/stations/drink_machine.tscn")
const PowerManagerScript = preload("res://src/core/power_manager.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: CARDÁPIO CENTRALIZADO & BOTÃO DE ENERGIA SEM TEXTO FLUTUANTE")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	var pm = PowerManagerScript.new()
	pm.name = "PowerManager"
	root.add_child(pm)
	pm._ready()

	# --- TESTE 1: Cardápio Sem Subtítulos Desnecessários e Centralizado Dentro do Quadro ---
	total_tests += 1
	var menu_board = DiningMenuBoardScene.instantiate()
	root.add_child(menu_board)

	var has_subtitles = (menu_board.get_node_or_null("SubtitleLabel") != null or menu_board.get_node_or_null("ColLeftHeader") != null or menu_board.get_node_or_null("ColRightHeader") != null)
	var col_left = menu_board.get_node_or_null("ColLeftLabel") as Label3D
	var col_right = menu_board.get_node_or_null("ColRightLabel") as Label3D

	var col_left_x_ok = (col_left != null and col_left.position.x >= -1.50 and col_left.position.x <= -1.40)
	var col_right_x_ok = (col_right != null and col_right.position.x >= 0.10 and col_right.position.x <= 0.20)
	var all_burgers_present = (
		col_left != null and col_right != null and
		"Burger Clássico" in col_left.text and "Burger Duplo" in col_left.text and
		"Burger Cheddar" in col_left.text and "Burger Bacon" in col_left.text and
		"Burger Salada" in col_left.text and "Burger Onion" in col_left.text and
		"Burger Chicken" in col_right.text and "Burger Supreme" in col_right.text and
		"Burger Três Queijos" in col_right.text and "Burger Vegano" in col_right.text and
		"Burger Egg" in col_right.text
	)

	if not has_subtitles and col_left_x_ok and col_right_x_ok and all_burgers_present:
		print("  ✅ TESTE 1: Cardápio na parede sem descrições extras, centralizado perfeitamente dentro da chapa preta.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Cardápio incorreto (HasSubtitles: %s, LeftX: %s, RightX: %s, BurgersOk: %s)" % [has_subtitles, col_left.position.x if col_left else 0, col_right.position.x if col_right else 0, all_burgers_present])

	# --- TESTE 2: Máquina de Sucos Sem Texto 'POWER' e Botão Físico Preservado ---
	total_tests += 1
	var juice_mach = JuiceMachineScene.instantiate()
	root.add_child(juice_mach)
	juice_mach._ready()

	var j_has_power_label = (juice_mach.get_node_or_null("Model/PowerSwitch/PowerLabel") != null)
	var j_has_switch_bezel = (juice_mach.get_node_or_null("Model/PowerSwitch/SwitchBezel") != null)
	var j_has_status_led = (juice_mach.get_node_or_null("Model/PowerSwitch/StatusLED") != null)

	if not j_has_power_label and j_has_switch_bezel and j_has_status_led:
		print("  ✅ TESTE 2: Máquina de Sucos sem texto flutuante 'POWER', preservando o botão físico (moldura e LED).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Máquina de Sucos incorreta (HasLabel: %s, Bezel: %s, LED: %s)" % [j_has_power_label, j_has_switch_bezel, j_has_status_led])

	# --- TESTE 3: Máquina de Refrigerantes Sem Texto 'POWER' e Botão Físico Preservado ---
	total_tests += 1
	var drink_mach = DrinkMachineScene.instantiate()
	root.add_child(drink_mach)
	drink_mach._ready()

	var d_has_power_label = (drink_mach.get_node_or_null("Model/PowerSwitch/PowerLabel") != null)
	var d_has_switch_bezel = (drink_mach.get_node_or_null("Model/PowerSwitch/SwitchBezel") != null)
	var d_has_status_led = (drink_mach.get_node_or_null("Model/PowerSwitch/StatusLED") != null)

	if not d_has_power_label and d_has_switch_bezel and d_has_status_led:
		print("  ✅ TESTE 3: Máquina de Refrigerantes sem texto flutuante 'POWER', preservando o botão físico (moldura e LED).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Máquina de Refrigerantes incorreta (HasLabel: %s, Bezel: %s, LED: %s)" % [d_has_power_label, d_has_switch_bezel, d_has_status_led])

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
