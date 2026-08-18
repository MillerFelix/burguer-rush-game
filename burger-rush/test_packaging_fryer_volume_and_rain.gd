extends SceneTree

# ===========================================================================
# TESTE: EMBALAGEM VISÍVEL (BATATA/CEBOLA), SOM DA FRITADEIRA E CHUVA APRIMORADA
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: EMBALAGEM VERMELHA DE FRITAS, VOLUME DA FRITADEIRA E CHUVA")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# TESTE 1: EMBALAGEM VERMELHA FÍSICA PARA BATATA E CEBOLA FRITAS
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Embalagem Vermelha de Batata e Cebola Frita ---")

	var fries_pack_scene = load("res://src/items/fries_pack.tscn")
	var pack = fries_pack_scene.instantiate() as FriesPack
	root.add_child(pack)
	pack._ready()

	var mesh_root = pack.get_node_or_null("MeshInstance3D")
	var red_container = pack.get_node_or_null("MeshInstance3D/RedContainer")
	var fries_content = pack.get_node_or_null("MeshInstance3D/FriesContent")
	var rings_content = pack.get_node_or_null("MeshInstance3D/OnionRingsContent")

	total_tests += 1
	if red_container != null and red_container.visible:
		print("  [PASS] Embalagem vermelha (RedContainer) fisicamente presente e visível!")
		passed_tests += 1
	else:
		print("  [FAIL] RedContainer ausente ou invisível!")

	total_tests += 1
	if fries_content != null and fries_content.visible and not rings_content.visible:
		print("  [PASS] Batata Frita: Palitos dourados dentro da embalagem vermelha visíveis.")
		passed_tests += 1
	else:
		print("  [FAIL] Visual da batata frita incorreto!")

	# Muda para Cebola Frita
	pack.set_side_type("onion_rings")
	total_tests += 1
	if red_container.visible and rings_content.visible and not fries_content.visible:
		print("  [PASS] Cebola Frita: Anéis de cebola dentro da MESMA embalagem vermelha visíveis!")
		passed_tests += 1
	else:
		print("  [FAIL] Visual da cebola frita incorreto na embalagem!")

	total_tests += 1
	if pack.item_id == "onion_rings" and pack.display_name == "Cebola Frita":
		print("  [PASS] Propriedades e nome de 'Cebola Frita' aplicados corretamente.")
		passed_tests += 1
	else:
		print("  [FAIL] Propriedades do item incorretas!")

	# -----------------------------------------------------------------------
	# TESTE 2: VOLUME EQUILIBRADO E MODERADO DA FRITADEIRA
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Volume Equilibrado da Fritadeira ---")

	var fryer_scene = load("res://src/stations/fryer.tscn")
	var fryer = fryer_scene.instantiate() as Fryer
	root.add_child(fryer)
	fryer._ready()

	fryer.is_on = true
	fryer._process_audio(0.1)

	total_tests += 1
	if fryer._target_hum_vol <= -35.0:
		print("  [PASS] Zumbido da fritadeira reduzido para nível ambiente discreto (%.1f dB <= -35.0 dB)" % fryer._target_hum_vol)
		passed_tests += 1
	else:
		print("  [FAIL] Volume do zumbido da fritadeira muito alto: %.1f dB" % fryer._target_hum_vol)

	fryer.compartments[0]["basket_down"] = true
	fryer.compartments[0]["food_state"] = "cooking"
	fryer.current_temperature = 180.0
	fryer._process_audio(0.1)

	total_tests += 1
	if fryer._target_sizzle_vol <= -14.0:
		print("  [PASS] Chiado do óleo reduzido e equilibrado com a cozinha (%.1f dB <= -14.0 dB)" % fryer._target_sizzle_vol)
		passed_tests += 1
	else:
		print("  [FAIL] Volume do chiado muito alto: %.1f dB" % fryer._target_sizzle_vol)

	# -----------------------------------------------------------------------
	# TESTE 3: CHUVA INTENSA, Densa, COBERTURA AMPLA E RESPINGOS
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Presença Visual da Chuva e Respingos no Chão ---")

	var wm = WeatherManager.new()
	root.add_child(wm)
	WeatherManager.instance = wm
	wm._ready()
	wm.set_weather(WeatherManager.WeatherType.RAINY, true)

	total_tests += 1
	var rp = wm.rain_particles
	if rp != null and rp.amount >= 1800 and rp.emission_box_extents.x >= 30.0:
		print("  [PASS] Chuva densa configurada: %d partículas, cobertura ampla de %.1fm x %.1fm" % [rp.amount, rp.emission_box_extents.x * 2, rp.emission_box_extents.z * 2])
		passed_tests += 1
	else:
		print("  [FAIL] Partículas de chuva insuficientes ou área pequena!")

	total_tests += 1
	var drop_m = rp.mesh as CylinderMesh
	if drop_m != null and drop_m.height >= 1.0:
		print("  [PASS] Gotas de chuva longas e bem visíveis (altura: %.2fm)" % drop_m.height)
		passed_tests += 1
	else:
		print("  [FAIL] Malha dos pingos de chuva inadequada!")

	total_tests += 1
	var sp = wm.rain_splashes
	if sp != null and sp.amount >= 700 and sp.emission_box_extents.x >= 30.0:
		print("  [PASS] Respingos no chão configurados: %d partículas de splash em %.1fm x %.1fm" % [sp.amount, sp.emission_box_extents.x * 2, sp.emission_box_extents.z * 2])
		passed_tests += 1
	else:
		print("  [FAIL] Respingos no chão insuficientes!")

	# -----------------------------------------------------------------------
	# TESTE 4: ÁUDIO ESPACIAL DA CHUVA (EXTERIOR VS JANELAS/PORTAS VS INTERIOR)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Áudio Espacial da Chuva ---")

	# Posição Externa (Rua / Estacionamento: X=0, Z=-15)
	wm._process_spatial_audio(Vector3(0, 1.0, -15.0))
	var ext_outdoor = wm.rain_audio_ext.volume_db
	var int_outdoor = wm.rain_audio_int.volume_db

	total_tests += 1
	if ext_outdoor >= -10.0 and int_outdoor <= -70.0:
		print("  [PASS] No exterior: Áudio de chuva externo vívido (%.1f dB) e interior mutado (%.1f dB)" % [ext_outdoor, int_outdoor])
		passed_tests += 1
	else:
		print("  [FAIL] Áudio externo da chuva incorreto: ext=%.1f, int=%.1f" % [ext_outdoor, int_outdoor])

	# Posição Interior Próxima à Porta/Janela (X=0, Z=-4.5)
	wm._process_spatial_audio(Vector3(0, 1.0, -4.5))
	var ext_near_door = wm.rain_audio_ext.volume_db

	# Posição Interior Fundo da Cozinha (X=0, Z=3.0)
	wm._process_spatial_audio(Vector3(0, 1.0, 3.0))
	var ext_deep_inside = wm.rain_audio_ext.volume_db
	var int_deep_inside = wm.rain_audio_int.volume_db

	total_tests += 1
	if ext_near_door > ext_deep_inside and int_deep_inside >= -20.0:
		print("  [PASS] Perto de portas/janelas o som externo é mais audível (%.1f dB > %.1f dB) e o telhado abafado é aconchegante (%.1f dB)" % [ext_near_door, ext_deep_inside, int_deep_inside])
		passed_tests += 1
	else:
		print("  [FAIL] Transição acústica das portas/janelas incorreta!")

	# -----------------------------------------------------------------------
	# RESULTADO FINAL
	# -----------------------------------------------------------------------
	print("\n===========================================================================")
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [passed_tests, total_tests - passed_tests])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
