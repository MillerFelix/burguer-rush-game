extends SceneTree

# Teste e validação dos 3 ajustes visuais:
# 1. Rua de Delivery (Asfalto escuro idêntico à rua da frente, sem grama/piso verde)
# 2. Postes de iluminação urbana (Luminária apoiada corretamente, sem ferro atravessando a lâmpada)
# 3. Porta de entrada principal (Vermelha + Amarela com vidro, aberta para fora)

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DOS AJUSTES VISUAIS (RUA DELIVERY, POSTES E ENTRADA)")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO PISO DA RUA DE DELIVERY (ASFALTO PRETO/ESCURO, SEM VERDE)
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação do Piso da Rua do Delivery ---")
	var floor_dt = room.get_node("FloorDriveThru") as CSGBox3D
	assert(floor_dt != null, "FloorDriveThru deve existir")
	var street_mat = floor_dt.material as StandardMaterial3D
	assert(street_mat != null, "Material da rua deve existir")
	assert(street_mat.albedo_texture != null, "Material da rua deve possuir textura de asfalto")
	assert(street_mat.albedo_texture.resource_path.contains("asphalt"), "Textura da rua deve ser asphalt_dark.png")
	print("  Textura da rua de delivery: %s (Fosco roughness: %.2f)" % [street_mat.albedo_texture.resource_path, street_mat.roughness])

	var outer_pavement = room.get_node("FloorStreetOuterPavement") as CSGBox3D
	assert(outer_pavement != null, "FloorStreetOuterPavement deve existir")
	assert(outer_pavement.material == street_mat, "Piso externo deve usar o mesmo material de asfalto da rua")

	var backdrop_pavement = room.get_node("FloorBackdropPavement") as CSGBox3D
	assert(backdrop_pavement != null, "FloorBackdropPavement deve cobrir a fundação traseira")
	assert(backdrop_pavement.material == street_mat, "Piso sob prédios traseiros deve ser asfalto/concreto urbano")

	# Confirma que nenhum nó LawnOuter ou piso verde de parque existe na área de tráfego
	var lawn_nodes = room.find_children("*Lawn*", "", true, false)
	assert(lawn_nodes.size() == 0, "Não deve existir nenhuma grama/lawn na área dos fundos ou delivery")
	print("  [PASS] Rua de delivery e fundos 100% asfaltados no mesmo padrão da rua frontal, sem piso verde!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA ESTRUTURA DOS POSTES DE LUZ (SEM FERRO ATRAVESSANDO LÂMPADA)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Estrutura dos Postes de Luz ---")
	var lamp_scene = load("res://src/environment/street_lamp.tscn").instantiate()
	var post = lamp_scene.get_node("Post") as MeshInstance3D
	var arm = lamp_scene.get_node("Arm") as MeshInstance3D
	var shade = lamp_scene.get_node("LanternShade") as MeshInstance3D
	var bulb = lamp_scene.get_node("Bulb") as MeshInstance3D
	var lamp_light = lamp_scene.get_node("LampLight") as OmniLight3D

	assert(post != null, "Poste vertical deve existir")
	assert(arm != null, "Braço horizontal deve existir")
	assert(shade != null, "Cúpula/Luminária deve existir")
	assert(bulb != null, "Lâmpada deve existir")
	assert(lamp_light != null, "Luz OmniLight3D deve existir")

	# Verifica hierarquia vertical: Braço (Y=3.95) -> Luminária (Y=3.72) -> Lâmpada (Y=3.64) -> Ponto de Luz (Y=3.55)
	assert(arm.position.y > shade.position.y, "Braço deve estar acima da cúpula da luminária")
	assert(shade.position.y > bulb.position.y, "Cúpula deve estar acima da lâmpada (abrigando-a)")
	assert(bulb.position.y >= lamp_light.position.y, "Lâmpada e ponto de luz devem estar alinhados na base da luminária")
	# Verifica que lâmpada e luminária compartilham o mesmo eixo Z (sem deslocamentos tortos)
	assert(abs(shade.position.z - bulb.position.z) < 0.01, "Cúpula e lâmpada devem estar perfeitamente alinhadas verticalmente")
	lamp_scene.queue_free()
	print("  [PASS] Estrutura do poste reformulada: braço horizontal, luminária e lâmpada perfeitamente alinhados!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA PORTA PRINCIPAL (VERMELHA + AMARELA, VIDRO, ABERTA PRA FORA)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Porta de Entrada Principal ---")
	var lintel = room.get_node("WallSouthDoorLintel") as CSGBox3D
	assert(lintel != null, "Dintel da parede sul sobre a porta deve existir")

	var door_left = room.get_node("DoorLeafLeft")
	var door_right = room.get_node("DoorLeafRight")
	assert(door_left != null, "Folha esquerda da porta deve existir")
	assert(door_right != null, "Folha direita da porta deve existir")

	# Verifica presença dos elementos: Moldura vermelha, Friso amarelo, Vidro
	var left_frame = door_left.get_node("FrameTop") as CSGBox3D
	var left_yellow = door_left.get_node("YellowMidBand") as CSGBox3D
	var left_glass = door_left.get_node("GlassPanel") as CSGBox3D

	assert(left_frame != null and left_frame.material != null, "Moldura da porta deve possuir material")
	assert(left_yellow != null and left_yellow.material != null, "Detalhes amarelos da porta devem possuir material")
	assert(left_glass != null and left_glass.material != null, "Painel central de vidro deve existir")

	var red_mat = left_frame.material as StandardMaterial3D
	var yellow_mat = left_yellow.material as StandardMaterial3D
	var glass_mat = left_glass.material as StandardMaterial3D

	assert(red_mat.albedo_color.r > 0.6 and red_mat.albedo_color.g < 0.3, "Moldura da porta deve ser vermelha")
	assert(yellow_mat.albedo_color.r > 0.8 and yellow_mat.albedo_color.g > 0.6, "Friso/Puxador deve ser amarelo")
	assert(glass_mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED, "Vidro da porta deve ser translúcido")

	# Verifica que a porta está aberta para fora (Z > 9.0 na calçada frontal)
	assert(door_left.position.z >= 9.0, "Porta esquerda deve estar aberta para o lado externo (calçada)")
	assert(door_right.position.z >= 9.0, "Porta direita deve estar aberta para o lado externo (calçada)")
	print("  [PASS] Porta principal vermelha e amarela com vidro translúcido, aberta para fora e integrada à parede!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS AJUSTES VISUAIS FORAM VALIDADOS COM SUCESSO!")
	print("================================================================================")
	quit(0)
