extends SceneTree

# Teste e validação da identidade visual do salão (paredes amarelinhas) e controle de luzes (apagadas de dia)

const DayNightCycle = preload("res://src/time/day_night_cycle.gd")

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE IDENTIDADE DO SALÃO E CONTROLE DE ILUMINAÇÃO (DIA/NOITE)")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var day_night = main_scene.get_node("DayNightCycle") as DayNightCycle
	day_night._find_references_if_null()
	var sun = main_scene.get_node("DirectionalLight3D") as DirectionalLight3D
	var env_node = main_scene.get_node("WorldEnvironment") as WorldEnvironment
	var lights_root = main_scene.get_node("Lights") as Node3D

	day_night.sun_light = sun
	day_night.world_environment = env_node
	day_night.lights_root = lights_root

	assert(day_night != null, "DayNightCycle deve existir na cena")
	assert(sun != null, "DirectionalLight3D deve existir na cena")
	assert(env_node != null and env_node.environment != null, "WorldEnvironment deve possuir Environment")
	assert(lights_root != null, "Node Lights deve existir na cena")

	var env = env_node.environment
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial if (env.sky and env.sky.sky_material is ProceduralSkyMaterial) else null
	assert(sky_mat != null, "ProceduralSkyMaterial deve estar configurado no Sky")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DAS PAREDES DO SALÃO (AMARELINHAS E SUAVES)
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação das Paredes do Salão (Amarelinhas e Suaves) ---")
	var room = main_scene.get_node("Room") as Node3D
	assert(room != null, "Node Room deve existir")

	var dining_wall_sample = room.get_node("WallEastSill1") as CSGBox3D
	assert(dining_wall_sample != null, "WallEastSill1 deve existir no Room")
	var dining_mat = dining_wall_sample.material as StandardMaterial3D
	assert(dining_mat != null, "WallEastSill1 deve ter material StandardMaterial3D")

	print("Cor da parede do salão: ", dining_mat.albedo_color)
	# Claramente amarelo suave/quente: R >= 0.90, G >= 0.80, B <= 0.60
	assert(dining_mat.albedo_color.r >= 0.90 and dining_mat.albedo_color.g >= 0.80 and dining_mat.albedo_color.b <= 0.60, "Parede do salão deve ser um amarelo suave/quente")
	assert(dining_mat.albedo_color.r > dining_mat.albedo_color.b, "Parede deve ter tom quente amarelado")
	assert(dining_mat.roughness >= 0.6, "Parede deve ser um material difuso sem reflexo excessivo")

	# Validação da cozinha (NÃO deve ter recebido a mesma cor do salão)
	var kitchen_wall = room.get_node("WallEastKitchen") as CSGBox3D
	assert(kitchen_wall != null, "WallEastKitchen deve existir")
	var kitchen_mat = kitchen_wall.material as StandardMaterial3D
	assert(kitchen_mat != null and kitchen_mat != dining_mat, "Cozinha deve ter material próprio separado do salão")
	print("Cor da parede da cozinha: ", kitchen_mat.albedo_color)
	assert(kitchen_mat.albedo_color.b > 0.90, "Parede da cozinha deve ser branca/cinza funcional")

	# Validação do estoque (armazenagem inalterada)
	var storage_wall = room.get_node("WallWestNorth") as CSGBox3D
	assert(storage_wall != null, "WallWestNorth deve existir")
	var storage_mat = storage_wall.material as StandardMaterial3D
	assert(storage_mat != null and storage_mat != dining_mat, "Estoque deve manter seu material próprio de armazém")
	print("  [PASS] Paredes do salão amarelinhas e suaves, com cozinha e estoque protegidos e distintos!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DAS LUZES DO SALÃO (QUENTES) E COZINHA (BRANCAS)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Temperatura das Luzes do Salão e Cozinha ---")
	var dining_lights = []
	var kitchen_lights = []
	for l in lights_root.get_children():
		if l is Light3D:
			if "Dining" in l.name:
				dining_lights.append(l)
			elif l.name.begins_with("KitchenLight") or l.name.begins_with("StorageLight"):
				kitchen_lights.append(l)

	assert(dining_lights.size() >= 4, "Devem existir luzes centrais do salão no node Lights")
	assert(kitchen_lights.size() >= 6, "Devem existir luzes funcionais da cozinha no node Lights")

	for dl in dining_lights:
		assert(dl.light_color.r > dl.light_color.b, "Luzes do salão devem ser aconchegantes e quentes")

	for kl in kitchen_lights:
		assert(kl.light_color.b >= 0.95 and kl.light_color.r >= 0.90, "Luzes da cozinha devem ser brancas e funcionais")
	print("  [PASS] Diferença de temperatura entre salão (quente) e cozinha (branca) validada!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DAS LUZES APAGADAS DURANTE O DIA (09:00, 12:00, 15:00)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação de Luzes TOTALMENTE APAGADAS durante o Dia (09:00, 12:00, 15:00) ---")
	var day_hours = [9.0, 12.0, 15.0]
	var street_lamps = main_scene.find_children("StreetLamp*", "Node3D", true, false)
	var dining_fixtures = main_scene.find_children("DiningCeilingLamp*", "Node3D", true, false)
	var kitchen_fixtures = main_scene.find_children("KitchenPanel*", "Node3D", true, false)

	for dh in day_hours:
		day_night._update_lighting(dh)

		# Luzes no node Lights devem ter energia 0.0
		for l in lights_root.get_children():
			if l is Light3D:
				assert(l.light_energy == 0.0, "Luz '%s' deve estar APAGADA (energia 0) às %.1fh (atual: %f)" % [l.name, dh, l.light_energy])

		# Postes devem estar apagados
		for slamp in street_lamps:
			var light = slamp.find_child("LampLight", true, false) as Light3D
			assert(light.light_energy == 0.0, "Poste de rua '%s' deve estar apagado às %.1fh" % [slamp.name, dh])

		# Emissões visuais devem estar desligadas
		for dlam in dining_fixtures:
			var bulb = dlam.find_child("Bulb", true, false) as MeshInstance3D
			if bulb and bulb.material_override:
				var m = bulb.material_override as StandardMaterial3D
				assert(not m.emission_enabled or m.emission_energy_multiplier == 0.0, "Lâmpada do salão deve estar visualmente desligada às %.1fh" % dh)

		for kpan in kitchen_fixtures:
			var diff = kpan.find_child("Diffuser", true, false) as MeshInstance3D
			if diff and diff.material_override:
				var m = diff.material_override as StandardMaterial3D
				assert(not m.emission_enabled or m.emission_energy_multiplier == 0.0, "Painel da cozinha deve estar visualmente desligado às %.1fh" % dh)

		print("  [PASS] Horário %02d:00 verificado: TODAS as luzes e luminárias internas e externas estão 100%% APAGADAS." % int(dh))

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DE FIM DE TARDE E NOITE (17:30, 19:00, 21:00)
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação de Fim de Tarde e Noite (17:30, 19:00, 21:00) ---")

	# 17:30 - Fim de tarde dourado, lâmpadas ainda apagadas (ou no limite de ativação)
	day_night._update_lighting(17.5)
	assert(sun.light_energy >= 0.70, "17:30: Sol ainda presente com luz dourada")
	assert(sun.light_color.r > 0.95 and sun.light_color.b < 0.65, "17:30: Sol em tom dourado/alaranjado")
	for dl in dining_lights:
		assert(dl.light_energy <= 0.05, "17:30: Luzes internas ainda essencialmente apagadas enquanto há sol dourado")
	print("  [PASS] 17:30 - Fim de tarde natural com sombras longas douradas e lâmpadas apagadas.")

	# 19:00 - Anoitecer: Luzes claramente acesas
	day_night._update_lighting(19.0)
	assert(sun.light_energy <= 0.20, "19:00: Luz solar caiu drasticamente")
	for dl in dining_lights:
		assert(dl.light_energy > 0.5, "19:00: Luzes do salão devem estar ACESAS")
	for kl in kitchen_lights:
		assert(kl.light_energy > 0.5, "19:00: Luzes da cozinha devem estar ACESAS")
	for slamp in street_lamps:
		var light = slamp.find_child("LampLight", true, false) as Light3D
		assert(light.light_energy > 0.4, "19:00: Postes de rua devem estar ACESOS")
	print("  [PASS] 19:00 - Transição suave completada: salão quente, cozinha branca e postes acesos.")

	# 21:00 - Noite completa: Totalmente acesas e céu escuro
	day_night._update_lighting(21.0)
	assert(sun.light_energy <= 0.02, "21:00: Sol desligado/luar mínimo")
	assert(env.background_energy_multiplier <= 0.05, "21:00: Céu noturno escuro profundo")
	assert(env.ambient_light_energy <= 0.08, "21:00: Ambiente natural escuro")
	for dl in dining_lights:
		assert(dl.light_energy >= 1.0, "21:00: Salão com brilho noturno acolhedor pleno")
	for kl in kitchen_lights:
		assert(kl.light_energy >= 1.0, "21:00: Cozinha com brilho noturno funcional pleno")
	print("  [PASS] 21:00 - Noite completa com iluminação artificial dominante e ambiente acolhedor.")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS CRITÉRIOS DE IDENTIDADE VISUAL E CONTROLE DE LUZES FORAM APROVADOS!")
	print("================================================================================")
	quit(0)
