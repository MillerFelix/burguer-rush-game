@tool
extends SceneTree

func _init() -> void:
	print("--- GERANDO TEXTURAS ORGÂNICAS DE SUJEIRA ---")
	_generate_grill_dirt()
	_generate_table_dirt()
	_generate_counter_dirt()
	_generate_floor_dirt()
	_generate_fryer_dirt()
	print("--- TODAS AS TEXTURAS DE SUJEIRA GERADAS COM SUCESSO ---")
	quit(0)

func _generate_grill_dirt() -> void:
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_octaves = 4

	var noise2 = FastNoiseLite.new()
	noise2.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise2.frequency = 0.08

	var center = Vector2(size * 0.5, size * 0.5)

	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / (size * 0.42)
			var angle = pos.angle_to_point(center)
			
			# Deformação orgânica e assimétrica
			var deform = noise.get_noise_2d(x * 1.5, y * 1.5) * 0.35 + sin(angle * 3.0) * 0.12 + cos(angle * 5.0) * 0.08
			var effective_dist = dist + deform

			if effective_dist < 1.0:
				var edge_fade = clampf(1.0 - effective_dist, 0.0, 1.0)
				edge_fade = pow(edge_fade, 0.7) # Bordas suaves mas definidas
				
				var n_val = (noise.get_noise_2d(x * 3.0, y * 3.0) + 1.0) * 0.5
				var char_val = (noise2.get_noise_2d(x * 4.0, y * 4.0) + 1.0) * 0.5

				# Tom de gordura queimada / crosta de chapa quente (carvão escuro com nuances marrons)
				var r = lerpf(0.08, 0.18, n_val)
				var g = lerpf(0.06, 0.12, n_val)
				var b = lerpf(0.04, 0.08, char_val)
				var alpha = edge_fade * lerpf(0.65, 0.95, char_val)

				# Pequenos pontos de carvão mais escuro
				if char_val > 0.65 and effective_dist < 0.75:
					r *= 0.5
					g *= 0.5
					b *= 0.5
					alpha = minf(1.0, alpha * 1.2)

				img.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png("res://assets/textures/dirt_stain_grill.png")
	print("Salvo: res://assets/textures/dirt_stain_grill.png")

func _generate_table_dirt() -> void:
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	noise.fractal_octaves = 3

	var center = Vector2(size * 0.5, size * 0.5)

	# Mancha com anel de copo derramado + respingos orgânicos de molho / comida
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / (size * 0.38)
			var angle = pos.angle_to_point(center)
			
			var deform = noise.get_noise_2d(x * 2.0, y * 2.0) * 0.28 + cos(angle * 4.0) * 0.10
			var effective_dist = dist + deform

			# Anel de mancha de bebida/líquido + centro com restos
			var ring_factor = 1.0 - absf(effective_dist - 0.7) * 3.5
			ring_factor = clampf(ring_factor, 0.0, 1.0)

			var blob_factor = clampf(1.0 - (effective_dist / 0.85), 0.0, 1.0)
			var intensity = maxf(ring_factor * 0.8, pow(blob_factor, 1.4) * 0.75)

			# Gotículas satélites ao redor
			var n_splat = noise.get_noise_2d(x * 6.0, y * 6.0)
			if dist > 0.7 and dist < 1.2 and n_splat > 0.48:
				intensity = maxf(intensity, (n_splat - 0.48) * 2.0)

			if intensity > 0.02:
				var n_tex = (noise.get_noise_2d(x * 4.0, y * 4.0) + 1.0) * 0.5
				# Tom de resíduo de comida / molho seco / bebida derramada
				var r = lerpf(0.22, 0.36, n_tex)
				var g = lerpf(0.12, 0.20, n_tex)
				var b = lerpf(0.08, 0.14, n_tex)
				var alpha = clampf(intensity * lerpf(0.70, 0.90, n_tex), 0.0, 0.92)
				img.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png("res://assets/textures/dirt_stain_table.png")
	print("Salvo: res://assets/textures/dirt_stain_table.png")

func _generate_counter_dirt() -> void:
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.045
	noise.fractal_octaves = 4

	var center = Vector2(size * 0.5, size * 0.5)

	# Mancha de bancada: esfregaço de gordura, molho, resíduo de preparo
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			# Formato alongado / estirado de mancha de bancada
			var scaled_pos = Vector2((x - center.x) * 0.8, (y - center.y) * 1.3)
			var dist = scaled_pos.length() / (size * 0.36)
			var deform = noise.get_noise_2d(x * 1.8, y * 1.8) * 0.32
			var effective_dist = dist + deform

			if effective_dist < 1.0:
				var fade = clampf(1.0 - effective_dist, 0.0, 1.0)
				var n_val = (noise.get_noise_2d(x * 3.5, y * 3.5) + 1.0) * 0.5
				
				# Mancha escura oleosa com partes mais translúcidas
				var r = lerpf(0.16, 0.26, n_val)
				var g = lerpf(0.12, 0.20, n_val)
				var b = lerpf(0.09, 0.14, n_val)
				var alpha = pow(fade, 0.85) * lerpf(0.55, 0.88, n_val)
				img.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png("res://assets/textures/dirt_stain_counter.png")
	print("Salvo: res://assets/textures/dirt_stain_counter.png")

func _generate_floor_dirt() -> void:
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.038
	noise.fractal_octaves = 4

	var center = Vector2(size * 0.5, size * 0.5)

	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / (size * 0.40)
			var angle = pos.angle_to_point(center)
			
			var deform = noise.get_noise_2d(x * 2.2, y * 2.2) * 0.38 + sin(angle * 6.0) * 0.12
			var effective_dist = dist + deform

			# Gotas e espirros periféricos
			var n_drop = noise.get_noise_2d(x * 5.0 + 100.0, y * 5.0 + 100.0)
			var is_droplet = (dist > 0.65 and dist < 1.15 and n_drop > 0.42)

			if effective_dist < 1.0 or is_droplet:
				var fade = 0.0
				if effective_dist < 1.0:
					fade = clampf(1.0 - effective_dist, 0.0, 1.0)
				if is_droplet:
					fade = maxf(fade, (n_drop - 0.42) * 2.2)

				var n_val = (noise.get_noise_2d(x * 3.0, y * 3.0) + 1.0) * 0.5
				# Líquido derramado / refrigerante escuro / sujeira de sapato e cozinha
				var r = lerpf(0.12, 0.22, n_val)
				var g = lerpf(0.09, 0.16, n_val)
				var b = lerpf(0.07, 0.12, n_val)
				var alpha = clampf(pow(fade, 0.75) * lerpf(0.65, 0.90, n_val), 0.0, 0.92)
				img.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png("res://assets/textures/dirt_stain_floor.png")
	print("Salvo: res://assets/textures/dirt_stain_floor.png")

func _generate_fryer_dirt() -> void:
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	noise.fractal_octaves = 3

	var center = Vector2(size * 0.5, size * 0.5)

	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / (size * 0.36)
			var deform = noise.get_noise_2d(x * 2.5, y * 2.5) * 0.30
			var effective_dist = dist + deform

			# Gotículas de óleo quente espirradas
			var n_splatter = noise.get_noise_2d(x * 7.0, y * 7.0)
			var has_splatter = (dist > 0.5 and dist < 1.2 and n_splatter > 0.40)

			if effective_dist < 1.0 or has_splatter:
				var fade = 0.0
				if effective_dist < 1.0:
					fade = clampf(1.0 - effective_dist, 0.0, 1.0)
				if has_splatter:
					fade = maxf(fade, (n_splatter - 0.40) * 2.5)

				var n_val = (noise.get_noise_2d(x * 4.0, y * 4.0) + 1.0) * 0.5
				# Óleo de fritadeira âmbar escuro / gordura caramelizada
				var r = lerpf(0.35, 0.55, n_val)
				var g = lerpf(0.22, 0.35, n_val)
				var b = lerpf(0.06, 0.12, n_val)
				var alpha = clampf(pow(fade, 0.8) * lerpf(0.60, 0.85, n_val), 0.0, 0.88)
				img.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png("res://assets/textures/dirt_stain_fryer.png")
	print("Salvo: res://assets/textures/dirt_stain_fryer.png")
