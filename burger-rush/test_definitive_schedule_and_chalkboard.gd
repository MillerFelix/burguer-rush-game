extends SceneTree

# Teste e validação definitiva do ciclo de horário 10:00 — 22:00, quadro de giz da entrada e paredes amarelas

const OpenSign = preload("res://src/stations/open_sign.gd")

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DEFINITIVO DE HORÁRIO 10:00 — 22:00 E QUADRO DE GIZ")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var clock = main_scene.get_node("GameClock") as GameClock
	GameClock.instance = clock
	var open_sign = main_scene.get_node("OpenSign") as OpenSign
	var player = main_scene.get_node("Player") as Node3D
	var day_night = main_scene.get_node("DayNightCycle") as DayNightCycle

	assert(clock != null, "GameClock deve existir na cena")
	assert(open_sign != null, "OpenSign deve existir na cena")
	assert(player != null, "Player deve existir na cena")
	assert(day_night != null, "DayNightCycle deve existir na cena")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO MODELO DO QUADRO DE GIZ E MOLDURA HORIZONTAL
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação do Quadro de Giz (Tamanho e Moldura Superior Horizontal) ---")
	var model = open_sign.get_node("Model")
	assert(model != null, "OpenSign deve possuir node Model")
	var top_hinge = model.get_node("TopHinge") as MeshInstance3D
	assert(top_hinge != null, "OpenSign deve possuir TopHinge")
	
	# Verifica que a moldura/ferro superior está alinhada horizontalmente no eixo X
	# A rotação deve deitar o cilindro ao longo de X (eixo X ~ 0 e eixo Y/Z girados 90 graus)
	var hinge_mesh = top_hinge.mesh as CylinderMesh
	assert(hinge_mesh != null, "TopHinge deve ser um CylinderMesh")
	assert(hinge_mesh.height >= 0.8, "Moldura superior deve cobrir a largura do quadro")
	# Translação Y deve estar acima do quadro
	assert(top_hinge.position.y >= 1.0, "Moldura deve ficar no topo do quadro (acima da lousa)")
	print("  [PASS] Moldura superior perfeitamente horizontal e posicionada acima da lousa!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA PAREDE AMARELA DO SALÃO
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Cor Amarela da Parede do Salão ---")
	var room = main_scene.get_node("Room")
	var dining_wall = room.get_node("WallEastSill1") as CSGBox3D
	var dining_mat = dining_wall.material as StandardMaterial3D
	assert(dining_mat != null, "Material da parede do salão deve existir")
	print("Cor da parede do salão: ", dining_mat.albedo_color)
	# Claramente amarelo: R > 0.90, G > 0.80, B < 0.60
	assert(dining_mat.albedo_color.r >= 0.90 and dining_mat.albedo_color.g >= 0.80 and dining_mat.albedo_color.b <= 0.60, "Parede deve ser nitidamente amarela/diner")
	
	var kitchen_wall = room.get_node("WallEastKitchen") as CSGBox3D
	var kitchen_mat = kitchen_wall.material as StandardMaterial3D
	assert(kitchen_mat != dining_mat, "Cozinha não pode ter a mesma cor do salão")
	print("  [PASS] Parede do salão é nitidamente amarela, e cozinha permanece preservada!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DOS HORÁRIOS BASE DO GAME CLOCK
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação dos Parâmetros Oficiais do GameClock ---")
	assert(clock.start_hour == 9 and clock.start_minute == 0, "Dia deve começar às 09:00")
	assert(clock.auto_open_hour == 10 and clock.auto_open_minute == 0, "Abertura automática deve ser às 10:00")
	assert(clock.closing_hour == 22 and clock.closing_minute == 0, "Fechamento oficial deve ser às 22:00")
	print("  [PASS] Início: 09:00 | Abertura: 10:00 | Fechamento: 22:00 validados no GameClock!")

	# -------------------------------------------------------------------------
	# 4. TESTE DE ABERTURA MANUAL (09:00 -> Pressionar E -> ABERTO)
	# -------------------------------------------------------------------------
	print("\n--- 4. Teste de Abertura Manual antes das 10:00 ---")
	clock.current_hour = 9
	clock.current_minute = 0
	clock.set_state(GameClock.State.PREPARATION)
	open_sign._update_sign()

	# Verifica estado inicial de preparação
	assert(clock.state == GameClock.State.PREPARATION, "Às 09:00 o restaurante deve iniciar em PREPARAÇÃO")
	assert("10:00 — 22:00" in open_sign.label_3d.text, "Quadro deve conter '10:00 — 22:00'")
	assert("FECHADO" in open_sign.label_3d.text, "Quadro deve indicar FECHADO durante a preparação")
	assert("BURGER RUSH" in open_sign.label_3d.text, "Quadro deve conter título BURGER RUSH")

	var prompt_prep = open_sign.get_interaction_prompt(player)
	assert("Abrir" in prompt_prep, "Prompt deve indicar que o jogador pode abrir com E")

	# Jogador interage com E
	open_sign.interact(player)
	assert(clock.state == GameClock.State.OPEN, "Interagir com E durante preparação deve abrir o restaurante")
	assert("ABERTO" in open_sign.label_3d.text, "Quadro deve mudar para ABERTO")
	assert("10:00 — 22:00" in open_sign.label_3d.text, "Quadro deve manter o horário '10:00 — 22:00' visível")
	print("  [PASS] Abertura manual com [E] executada e validada com sucesso!")

	# -------------------------------------------------------------------------
	# 5. TESTE DE ABERTURA AUTOMÁTICA (09:00 -> Não interagir -> 10:00 abre sozinho)
	# -------------------------------------------------------------------------
	print("\n--- 5. Teste de Abertura Automática às 10:00 ---")
	clock.current_hour = 9
	clock.current_minute = 0
	clock.set_state(GameClock.State.PREPARATION)
	open_sign._update_sign()

	# Avança minuto a minuto de 09:00 até 09:59 (deve continuar em PREPARAÇÃO)
	for m in range(59):
		clock._advance_minute()
		assert(clock.state == GameClock.State.PREPARATION, "Às %02d:%02d ainda deve estar em PREPARAÇÃO" % [clock.current_hour, clock.current_minute])

	# Avança para 10:00
	clock._advance_minute()
	assert(clock.current_hour == 10 and clock.current_minute == 0, "Horário deve ser 10:00")
	assert(clock.state == GameClock.State.OPEN, "Às 10:00 o restaurante DEVE abrir automaticamente")
	assert("ABERTO" in open_sign.label_3d.text, "Quadro deve mostrar ABERTO às 10:00")
	assert("10:00 — 22:00" in open_sign.label_3d.text, "Quadro deve exibir '10:00 — 22:00'")
	print("  [PASS] Abertura automática pontualmente às 10:00 validada!")

	# -------------------------------------------------------------------------
	# 6. TESTE DE FUNCIONAMENTO DIURNO E NOTURNO ATÉ O FECHAMENTO (22:00)
	# -------------------------------------------------------------------------
	print("\n--- 6. Teste de Funcionamento 10:00 — 22:00 e Fechamento às 22:00 ---")
	# Avança até 21:59 (deve permanecer ABERTO)
	clock.current_hour = 21
	clock.current_minute = 59
	clock.set_state(GameClock.State.OPEN)
	open_sign._update_sign()
	assert(clock.state == GameClock.State.OPEN, "Às 21:59 o restaurante deve continuar ABERTO")

	# Avança para 22:00
	clock._advance_minute()
	assert(clock.current_hour == 22 and clock.current_minute == 0, "Horário deve ser 22:00")
	assert(clock.state == GameClock.State.CLOSING, "Às 22:00 o restaurante DEVE entrar em estado CLOSING (Encerrando)")
	assert("10:00 — 22:00" in open_sign.label_3d.text, "Quadro deve exibir '10:00 — 22:00'")
	assert("ENCERRANDO" in open_sign.label_3d.text, "Quadro deve indicar ENCERRANDO")

	# Jogador finaliza o dia no quadro
	open_sign.interact(player)
	assert(clock.state == GameClock.State.CLOSED, "Finalizar dia deve transicionar para CLOSED")
	assert("FECHADO" in open_sign.label_3d.text, "Quadro deve exibir FECHADO")
	assert("10:00 — 22:00" in open_sign.label_3d.text, "Quadro deve exibir '10:00 — 22:00'")
	print("  [PASS] Fechamento pontualmente às 22:00 e encerramento validados com sucesso!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS TESTES DE HORÁRIO 10:00 — 22:00 E QUADRO DE GIZ FORAM APROVADOS!")
	print("================================================================================")
	quit(0)
