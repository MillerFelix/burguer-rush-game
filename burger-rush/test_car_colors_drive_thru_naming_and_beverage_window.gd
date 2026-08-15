extends SceneTree

# Teste e validação:
# 1. Variedade e randomização de cores dos carros do Drive-Thru (sem predominância exclusiva de amarelo)
# 2. Correção da nomenclatura visual para "DRIVE-THRU"
# 3. Janela alta, fechada e com vidro na parede dos recipientes de bebidas

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE CORES DOS CARROS, NOMENCLATURA DRIVE-THRU E JANELA")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA VARIEDADE DE CORES DOS CARROS
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Variedade de Cores dos Carros do Drive-Thru ---")
	var car_scene = load("res://src/environment/delivery_car.tscn")
	var spawned_colors: Array[Color] = []

	for i in range(10):
		var car = car_scene.instantiate()
		main_scene.add_child(car)
		car._ready()
		var chassis = car.get_node_or_null("Model/Chassis") as MeshInstance3D
		assert(chassis != null, "Chassis do carro deve existir")
		assert(chassis.material_override != null, "Carro deve possuir material_override de pintura aplicada")
		var col = (chassis.material_override as StandardMaterial3D).albedo_color
		spawned_colors.append(col)
		print("  Carro #%02d -> Cor: R:%.2f G:%.2f B:%.2f" % [i + 1, col.r, col.g, col.b])
		car.queue_free()

	# Verifica se há mais de 3 cores distintas no lote de 10 carros
	var unique_colors: Array[Color] = []
	for c in spawned_colors:
		var exists = false
		for uc in unique_colors:
			if c.is_equal_approx(uc):
				exists = true
				break
		if not exists:
			unique_colors.append(c)

	print("  Cores únicas geradas em 10 carros: %d" % unique_colors.size())
	assert(unique_colors.size() >= 4, "Devem existir ao menos 4 cores distintas geradas entre 10 carros")
	print("  [PASS] Variedade rica de cores dos carros validada com sucesso!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA NOMENCLATURA DRIVE-THRU
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Nomenclatura Visual 'DRIVE-THRU' ---")
	var deliv_station = main_scene.get_node_or_null("DeliveryStation")
	assert(deliv_station != null, "DeliveryStation deve existir")
	var station_sign = deliv_station.get_node_or_null("SignLabel3D") as Label3D
	assert(station_sign != null, "SignLabel3D da estação deve existir")
	print("  Texto da Placa da Estação: '%s'" % station_sign.text)
	assert("DRIVE-THRU" in station_sign.text, "Placa da estação deve conter DRIVE-THRU")

	var room = main_scene.get_node("Room")
	var window_sign = room.get_node_or_null("DeliveryWindowSign") as Label3D
	assert(window_sign != null, "DeliveryWindowSign deve existir no Room")
	print("  Texto do Letreiro Externo: '%s'" % window_sign.text)
	assert("DRIVE-THRU" in window_sign.text, "Letreiro externo deve conter DRIVE-THRU")
	assert(not ("DELIVERY" in window_sign.text), "Letreiro externo não deve conter DELIVERY")
	print("  [PASS] Nomenclatura visual corrigida para DRIVE-THRU em todos os pontos!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA JANELA ALTA NA PAREDE DAS BEBIDAS
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Janela Alta na Parede de Bebidas ---")
	var window_glass = room.get_node_or_null("KitchenDriveThruWindowGlass") as CSGBox3D
	assert(window_glass != null, "KitchenDriveThruWindowGlass deve existir no Room")
	assert(window_glass.use_collision, "Janela de vidro deve possuir colisão fechada (não atravessável)")
	print("  Posição da Janela: %s | Dimensões: %s" % [window_glass.position, window_glass.size])
	assert(window_glass.position.x >= 8.9 and window_glass.position.x <= 9.1, "Janela deve estar na parede Leste (X = 9.0)")
	assert(window_glass.position.y >= 1.5, "Janela deve ser alta (Y >= 1.5m)")
	assert(window_glass.position.z <= -2.5 and window_glass.position.z >= -5.8, "Janela deve cobrir a área atrás das máquinas de bebidas")
	assert(window_glass.material != null and window_glass.material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED, "Vidro deve ser transparente para visão externa")
	print("  [PASS] Janela alta de observação do Drive-Thru perfeitamente integrada!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS AJUSTES VISUAIS E DE AMBIENTAÇÃO APROVADOS COM 100% DE SUCESSO!")
	print("================================================================================")
	quit(0)
