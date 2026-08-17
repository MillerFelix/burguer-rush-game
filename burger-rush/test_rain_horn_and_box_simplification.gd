extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE: CHUVA IMERSIVA, BUZINA POTENTE E CAIXAS SIMPLIFICADAS
# =============================================================================

const WeatherManager = preload("res://src/environment/weather_manager.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const ReceivingArea = preload("res://src/stations/receiving_area.gd")
const DeliveryBox = preload("res://src/items/delivery_box.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: IMERSÃO DE CHUVA, BUZINA DE CAMINHÃO E IDENTIFICAÇÃO DE CAIXAS")
	print("=".repeat(85) + "\n")
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
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.3).timeout

	print("\n--- TESTE 1: Sistema Visual e Físico de Chuva ---")
	var wm = root_node.find_child("WeatherManager", true, false) as WeatherManager
	assert_test(wm != null, "1.1 WeatherManager presente na cena")

	wm.set_weather(WeatherManager.WeatherType.RAINY, true)
	wm._process(0.1)

	assert_test(wm.rain_intensity >= 0.95, "1.2 Intensidade de chuva ativada (%.2f)" % wm.rain_intensity)
	assert_test(wm.rain_particles != null and wm.rain_particles.emitting, "1.3 Partículas de chuva externa visíveis e emitindo")
	assert_test(wm.rain_splashes != null and wm.rain_splashes.emitting, "1.4 Respingos de chuva atingindo o chão exterior emitindo")
	assert_test(wm.wetness >= 0.95, "1.5 Umidade do chão atingiu estado molhado (%.2f)" % wm.wetness)
	assert_test(wm.wet_materials.size() > 0, "1.6 Materiais externos (asfalto/calçadas/pallet) coletados para efeito molhado (%d materiais)" % wm.wet_materials.size())

	print("\n--- TESTE 2: Áudio Espacial da Chuva com Abafamento Interno ---")
	var player = root_node.find_child("Player", true, false)
	assert_test(player != null, "2.1 Jogador presente na cena")

	# Posição no interior do restaurante (Cozinha/Salão)
	player.global_position = Vector3(0.0, 1.0, 3.0)
	wm._process_spatial_audio(player.global_position)
	var int_vol_inside = wm.rain_audio_int.volume_db if wm.rain_audio_int else -80.0
	var ext_vol_inside = wm.rain_audio_ext.volume_db if wm.rain_audio_ext else -80.0
	assert_test(ext_vol_inside < -12.0, "2.2 Chuva externa mais abafada dentro do restaurante (Ext: %.1f dB)" % ext_vol_inside)

	# Posição no exterior (Rua / Pallet de entrega)
	player.global_position = Vector3(0.0, 1.0, -12.0)
	wm._process_spatial_audio(player.global_position)
	var ext_vol_outside = wm.rain_audio_ext.volume_db if wm.rain_audio_ext else -80.0
	assert_test(ext_vol_outside > ext_vol_inside, "2.3 Chuva externa significativamente mais alta no exterior (Ext: %.1f dB vs %.1f dB)" % [ext_vol_outside, ext_vol_inside])

	print("\n--- TESTE 3: Buzina de Caminhão Potente e Chamativa ---")
	var horn_stream = SoundSynthesizer.get_stream("truck_horn")
	assert_test(horn_stream != null, "3.1 Stream de áudio da buzina de caminhão gerado com sucesso")

	var receiving_area = root_node.find_child("ReceivingArea", true, false) as ReceivingArea
	assert_test(receiving_area != null, "3.2 ReceivingArea presente na doca de carga")
	assert_test(receiving_area.horn_audio != null, "3.3 AudioStreamPlayer3D da buzina configurado no pallet")
	assert_test(receiving_area.horn_audio.max_distance >= 60.0, "3.4 Alcance espacial da buzina amplo para cobrir todo o restaurante (%.0fm)" % receiving_area.horn_audio.max_distance)

	print("\n--- TESTE 4: Identificação Simples das Caixas de Papelão ---")
	var box_scene = load("res://src/items/delivery_box.tscn")
	var box_instance = box_scene.instantiate() as DeliveryBox
	root_node.add_child(box_instance)
	box_instance.setup_box("patty_beef", "Hambúrguer de Carne", 10)

	assert_test(box_instance.front_stamp != null, "4.1 Carimbo impresso frontal presente na caixa")
	var stamp_text = box_instance.front_stamp.text
	print("    -> Texto impresso na caixa:\n" + stamp_text.indent("       "))

	assert_test(stamp_text.contains("🥩"), "4.2 Carimbo possui desenho/ícone do produto")
	assert_test(stamp_text.contains("HAMBÚRGUER DE CARNE"), "4.3 Carimbo possui nome do ingrediente impresso")
	assert_test(not stamp_text.contains("BURGER RUSH LOGISTICS"), "4.4 Carimbo NÃO contém 'BURGER RUSH LOGISTICS'")
	assert_test(not stamp_text.contains("10 UN"), "4.5 Carimbo NÃO contém números de quantidade poluídos ('10 UN')")
	assert_test(not stamp_text.contains("CONTEÚDO:"), "4.6 Carimbo NÃO contém textos de interface ('CONTEÚDO:')")
	assert_test(box_instance.get_node_or_null("Label3D") == null, "4.7 Caixa NÃO possui textos ou labels 3D flutuantes no ar")

	# Outros exemplos solicitados pelo usuário
	box_instance.setup_box("cheese_cheddar", "Queijo Cheddar", 10)
	assert_test(box_instance.front_stamp.text == "🧀\nQUEIJO", "4.8 Caixa de queijo exibe apenas '🧀\\nQUEIJO'")

	box_instance.setup_box("cup_empty", "Copo", 50)
	assert_test(box_instance.front_stamp.text == "🥤\nCOPOS", "4.9 Caixa de copos exibe apenas '🥤\\nCOPOS'")

	box_instance.setup_box("pulp_orange", "Polpa de Laranja", 10)
	assert_test(box_instance.front_stamp.text == "🍊\nPOLPA DE FRUTA", "4.10 Caixa de polpa exibe apenas '🍊\\nPOLPA DE FRUTA'")

	print("\n" + "=".repeat(85))
	print("RESULTADO DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE CHUVA, BUZINA E CAIXAS PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
