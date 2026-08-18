extends SceneTree

func _init() -> void:
	var width = 512
	var height = 512
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)

	var tile_count = 4 # 4x4 tiles per texture repeat = 128x128 per tile
	var tile_size = width / tile_count
	var grout_width = 4 # 4 pixels grout line

	var base_red = Color(0.82, 0.32, 0.30, 1.0)
	var grout_color = Color(0.38, 0.16, 0.16, 1.0) # Rejunte contrastante visível

	# Cores com pequenas variações realistas para cada piso individual
	var tile_variations = [
		Color(0.84, 0.34, 0.32, 1.0),
		Color(0.80, 0.30, 0.28, 1.0),
		Color(0.85, 0.35, 0.33, 1.0),
		Color(0.81, 0.31, 0.29, 1.0),
		Color(0.83, 0.33, 0.31, 1.0),
		Color(0.86, 0.36, 0.34, 1.0),
		Color(0.79, 0.29, 0.27, 1.0),
		Color(0.84, 0.33, 0.30, 1.0),
		Color(0.82, 0.32, 0.30, 1.0),
		Color(0.85, 0.34, 0.31, 1.0),
		Color(0.80, 0.31, 0.29, 1.0),
		Color(0.83, 0.35, 0.33, 1.0),
		Color(0.84, 0.32, 0.29, 1.0),
		Color(0.81, 0.30, 0.28, 1.0),
		Color(0.86, 0.35, 0.32, 1.0),
		Color(0.83, 0.33, 0.31, 1.0)
	]

	for y in range(height):
		var tile_y = y / tile_size
		var local_y = y % tile_size
		var is_grout_y = (local_y < grout_width) or (local_y >= tile_size - 1)

		for x in range(width):
			var tile_x = x / tile_size
			var local_x = x % tile_size
			var is_grout_x = (local_x < grout_width) or (local_x >= tile_size - 1)

			if is_grout_x or is_grout_y:
				# Rejunte
				img.set_pixel(x, y, grout_color)
			else:
				var tile_idx = (tile_y * tile_count + tile_x) % tile_variations.size()
				var col = tile_variations[tile_idx]

				# Chanfro/sombra suave na borda do piso
				var dist_border = min(min(local_x - grout_width, tile_size - local_x - 1), min(local_y - grout_width, tile_size - local_y - 1))
				var bevel = clampf(float(dist_border) / 8.0, 0.82, 1.0)

				# Leve ruído de grão cerâmico
				var grain = (sin(x * 12.3 + y * 7.7) + cos(x * 3.1 - y * 11.2)) * 0.015

				var final_col = Color(
					clampf(col.r * bevel + grain, 0.0, 1.0),
					clampf(col.g * bevel + grain, 0.0, 1.0),
					clampf(col.b * bevel + grain, 0.0, 1.0),
					1.0
				)
				img.set_pixel(x, y, final_col)

	img.save_png("res://assets/textures/light_red_tiles.png")
	print("✅ Textura light_red_tiles.png gerada com sucesso!")
	quit(0)
