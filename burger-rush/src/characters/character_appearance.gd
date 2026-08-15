class_name CharacterAppearance
extends RefCounted

# Paletas Naturais e Agradáveis de Pele
static var SKIN_PALETTES: Array[Color] = [
	Color(0.96, 0.80, 0.68, 1.0), # 1. Fair Peach
	Color(0.90, 0.72, 0.56, 1.0), # 2. Warm Tan
	Color(0.78, 0.58, 0.42, 1.0), # 3. Golden Olive
	Color(0.56, 0.38, 0.25, 1.0), # 4. Rich Caramel
	Color(0.34, 0.22, 0.15, 1.0)  # 5. Deep Espresso
]

# Paletas de Roupas (Tops / Camisas)
static var SHIRT_PALETTES: Array[Color] = [
	Color(0.18, 0.48, 0.82, 1.0), # Azul Real
	Color(0.82, 0.22, 0.22, 1.0), # Vermelho Carmim
	Color(0.24, 0.62, 0.42, 1.0), # Verde Floresta
	Color(0.88, 0.68, 0.22, 1.0), # Amarelo Mostarda
	Color(0.82, 0.45, 0.40, 1.0), # Coral
	Color(0.48, 0.28, 0.62, 1.0), # Roxo Lavanda
	Color(0.28, 0.30, 0.35, 1.0), # Cinza Chumbo
	Color(0.92, 0.92, 0.94, 1.0)  # Branco
]

# Paletas de Calças
static var PANTS_PALETTES: Array[Color] = [
	Color(0.16, 0.24, 0.40, 1.0), # Jeans Azul
	Color(0.68, 0.58, 0.46, 1.0), # Cáqui / Areia
	Color(0.18, 0.20, 0.24, 1.0), # Sarja Preta
	Color(0.28, 0.36, 0.26, 1.0), # Verde Militar
	Color(0.38, 0.50, 0.62, 1.0)  # Jeans Claro
]

# Paletas de Cabelo
static var HAIR_PALETTES: Array[Color] = [
	Color(0.12, 0.12, 0.14, 1.0), # Preto
	Color(0.26, 0.16, 0.12, 1.0), # Castanho Escuro
	Color(0.46, 0.28, 0.18, 1.0), # Castanho Médio
	Color(0.85, 0.72, 0.40, 1.0), # Loiro
	Color(0.65, 0.28, 0.16, 1.0), # Ruivo
	Color(0.78, 0.80, 0.84, 1.0)  # Grisalho
]

# Paletas de Sapatos
static var SHOE_PALETTES: Array[Color] = [
	Color(0.15, 0.15, 0.16, 1.0), # Tênis Preto
	Color(0.92, 0.92, 0.94, 1.0), # Tênis Branco
	Color(0.48, 0.28, 0.16, 1.0), # Sapato Marrom
	Color(0.22, 0.32, 0.45, 1.0)  # Tênis Azul
]

static func apply_random_customer_appearance(character: Node3D, is_child: bool = false) -> void:
	if not character:
		return

	var model = character.get_node_or_null("Model")
	if not model:
		return

	var skin_color = SKIN_PALETTES[randi() % SKIN_PALETTES.size()]
	var shirt_color = SHIRT_PALETTES[randi() % SHIRT_PALETTES.size()]
	var pants_color = PANTS_PALETTES[randi() % PANTS_PALETTES.size()]
	var hair_color = HAIR_PALETTES[randi() % HAIR_PALETTES.size()]
	var shoe_color = SHOE_PALETTES[randi() % SHOE_PALETTES.size()]

	var is_female = (randi() % 2 == 0)

	if is_child:
		# Proporção infantil fofa cartoon
		character.scale = Vector3(0.72, 0.72, 0.72)
		model.scale = Vector3(1.0, 1.0, 1.0)
		# Cores alegres infantis
		var child_shirts: Array[Color] = [
			Color(0.95, 0.82, 0.22, 1.0), # Amarelo vibrante
			Color(0.22, 0.75, 0.85, 1.0), # Turquesa
			Color(0.92, 0.35, 0.65, 1.0), # Rosa
			Color(0.45, 0.82, 0.35, 1.0), # Verde limão
			Color(0.95, 0.45, 0.25, 1.0)  # Laranja alegre
		]
		shirt_color = child_shirts[randi() % child_shirts.size()]
	else:
		character.scale = Vector3(1.0, 1.0, 1.0)
		var height_scale = randf_range(0.96, 1.04)
		var width_scale = randf_range(0.95, 1.02) if is_female else randf_range(0.98, 1.05)
		model.scale = Vector3(width_scale, height_scale, (width_scale + height_scale) * 0.5)

	# Aplica Tom de Pele
	_set_mat(model, "Head", skin_color, 0.85)
	_set_mat(model, "Torso/Neck", skin_color, 0.85)
	_set_mat(model, "Head/Nose", skin_color, 0.85)
	_set_mat(model, "ArmLeft/HandLeft", skin_color, 0.85)
	_set_mat(model, "ArmRight/HandRight", skin_color, 0.85)

	# Aplica Cabelo e Sobrancelhas
	_set_mat(model, "Head/Hair", hair_color, 0.85)
	_set_mat(model, "Head/Hair/HairBang", hair_color, 0.85)
	_set_mat(model, "Head/EyebrowLeft", hair_color, 0.85)
	_set_mat(model, "Head/EyebrowRight", hair_color, 0.85)

	# Aplica Roupas
	_set_mat(model, "Torso", shirt_color, 0.85)
	_set_mat(model, "ArmLeft", shirt_color, 0.85)
	_set_mat(model, "ArmRight", shirt_color, 0.85)
	_set_mat(model, "Torso/Hips", pants_color, 0.85)
	_set_mat(model, "LegLeft", pants_color, 0.85)
	_set_mat(model, "LegRight", pants_color, 0.85)

	# Aplica Sapatos
	_set_mat(model, "LegLeft/ShoeLeft", shoe_color, 0.75)
	_set_mat(model, "LegRight/ShoeRight", shoe_color, 0.75)

static func apply_employee_appearance(character: Node3D, employee_name: String = "") -> void:
	if not character:
		return

	var model = character.get_node_or_null("Model")
	if not model:
		return

	var skin_color = SKIN_PALETTES[randi() % SKIN_PALETTES.size()]
	var hair_color = HAIR_PALETTES[randi() % HAIR_PALETTES.size()]
	var uniform_red = Color(0.85, 0.16, 0.16, 1.0)
	var apron_dark = Color(0.18, 0.18, 0.22, 1.0)
	var pants_dark = Color(0.18, 0.18, 0.22, 1.0)
	var shoes_dark = Color(0.12, 0.12, 0.14, 1.0)

	_set_mat(model, "Head", skin_color, 0.85)
	_set_mat(model, "Torso/Neck", skin_color, 0.85)
	_set_mat(model, "Head/Nose", skin_color, 0.85)
	_set_mat(model, "ArmLeft/HandLeft", skin_color, 0.85)
	_set_mat(model, "ArmRight/HandRight", skin_color, 0.85)

	_set_mat(model, "Head/EyebrowLeft", hair_color, 0.85)
	_set_mat(model, "Head/EyebrowRight", hair_color, 0.85)

	_set_mat(model, "Torso", uniform_red, 0.85)
	_set_mat(model, "ArmLeft", uniform_red, 0.85)
	_set_mat(model, "ArmRight", uniform_red, 0.85)
	_set_mat(model, "Head/Hat", uniform_red, 0.85)
	_set_mat(model, "Head/Hat/VisorBrim", uniform_red, 0.85)

	_set_mat(model, "Apron", apron_dark, 0.85)
	_set_mat(model, "Torso/Hips", pants_dark, 0.85)
	_set_mat(model, "LegLeft", pants_dark, 0.85)
	_set_mat(model, "LegRight", pants_dark, 0.85)
	_set_mat(model, "LegLeft/ShoeLeft", shoes_dark, 0.75)
	_set_mat(model, "LegRight/ShoeRight", shoes_dark, 0.75)

static func _set_mat(root: Node, path: String, color: Color, roughness: float = 0.85) -> void:
	var node = root.get_node_or_null(path) as MeshInstance3D
	if not node:
		return

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.0
	node.material_override = mat
