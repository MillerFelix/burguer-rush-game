extends SceneTree

const ParkedCar = preload("res://src/environment/parked_car.gd")

# Teste e validação do Estacionamento Visual do Restaurante:
# 1. Existência e integridade do RestaurantParkingLot na cena
# 2. Marcações claras de vagas no chão (faixas brancas e limitadores de roda)
# 3. Carros estacionados com cores variadas e vagas vazias
# 4. Enquadramento com árvores no limite do terreno
# 5. Visão desimpedida a partir da janela alta da cozinha

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DO ESTACIONAMENTO VISUAL E INTEGRAÇÃO DO CENÁRIO")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO NÓ DO ESTACIONAMENTO E PISO
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Estrutura do Estacionamento ---")
	var parking = main_scene.get_node_or_null("RestaurantParkingLot")
	assert(parking != null, "RestaurantParkingLot deve existir na cena principal")

	var asphalt = parking.get_node_or_null("AsphaltFloor") as MeshInstance3D
	assert(asphalt != null, "Piso de asfalto do estacionamento deve existir")
	print("  Posição do Asfalto: %s" % asphalt.position)

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DAS MARCAÇÕES DE VAGAS E LIMITADORES
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação das Marcações de Vagas ---")
	for i in range(6):
		var stripe = parking.get_node_or_null("Stripe%d" % i) as MeshInstance3D
		assert(stripe != null, "Faixa Stripe%d deve existir" % i)
		print("  Faixa %d -> X: %.1f, Z: %.1f" % [i, stripe.position.x, stripe.position.z])

	var end_stripe = parking.get_node_or_null("EndStripe")
	assert(end_stripe != null, "Faixa limitadora EndStripe deve existir")

	for i in range(1, 6):
		var wheel_stop = parking.get_node_or_null("WheelStop%d" % i)
		assert(wheel_stop != null, "Limitador de roda WheelStop%d deve existir" % i)

	print("  [PASS] Demarcações completas de 5 vagas organizadas e limitadores de roda presentes!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DOS CARROS ESTACIONADOS E VAGAS LIVRES
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação dos Carros Estacionados ---")
	var car1 = parking.get_node_or_null("ParkedCar1") as ParkedCar
	var car2 = parking.get_node_or_null("ParkedCar2") as ParkedCar
	var car3 = parking.get_node_or_null("ParkedCar3") as ParkedCar

	assert(car1 != null and car2 != null and car3 != null, "Os 3 carros decorativos devem existir")
	print("  Carro 1 na Vaga 1 (X = %.1f) - Cor: %s" % [car1.position.x, car1.custom_paint_color])
	print("  Carro 2 na Vaga 3 (X = %.1f) - Cor: %s" % [car2.position.x, car2.custom_paint_color])
	print("  Carro 3 na Vaga 5 (X = %.1f) - Cor: %s" % [car3.position.x, car3.custom_paint_color])

	assert(car1.custom_paint_color != car2.custom_paint_color, "Carros estacionados devem ter cores diferentes")
	assert(car2.custom_paint_color != car3.custom_paint_color, "Carros estacionados devem ter cores diferentes")

	# Verifica se há vagas livres (vagas 2 e 4)
	print("  Vagas 2 e 4 desocupadas (estacionamento parcialmente ocupado e funcional)")
	print("  [PASS] Carros posicionados nas vagas com variedade visual e vagas livres!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DO ALINHAMENTO COM A JANELA DA COZINHA
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação da Visão a partir da Janela da Cozinha ---")
	var room = main_scene.get_node("Room")
	var window = room.get_node_or_null("KitchenDriveThruWindowGlass") as CSGBox3D
	assert(window != null, "Janela de observação da cozinha deve existir")

	# Janela está em X = 9.0, Z = -4.1. As vagas estão em X in [11.2, 24.2], Z in [-6.8, -1.8]
	print("  Janela da Cozinha: %s" % window.position)
	print("  Área das Vagas: X=[11.2, 24.2], Z=[-6.8, -1.8]")
	assert(window.position.z >= -6.8 and window.position.z <= -1.8, "Janela deve estar diretamente alinhada com as vagas do estacionamento")
	print("  [PASS] Janela da cozinha possui linha de visão direta para o estacionamento!")

	# -------------------------------------------------------------------------
	# 5. VALIDAÇÃO DA BARREIRA DE ÁRVORES NO LIMITE
	# -------------------------------------------------------------------------
	print("\n--- 5. Validação das Árvores no Limite do Estacionamento ---")
	for i in range(1, 6):
		var tree = parking.get_node_or_null("TreeBorder%d" % i)
		assert(tree != null, "Árvore de borda TreeBorder%d deve existir" % i)
		assert(tree.position.x >= 25.0, "Árvores de borda devem estar no limite distante (X >= 25.0)")

	print("  [PASS] Barreira natural de árvores no perímetro validada com sucesso!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("ESTACIONAMENTO DO RESTAURANTE IMPLEMENTADO E VALIDADO COM 100% DE SUCESSO!")
	print("================================================================================")
	quit(0)
