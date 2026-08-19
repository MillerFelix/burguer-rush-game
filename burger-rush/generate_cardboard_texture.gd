extends SceneTree

func _init() -> void:
	var width = 512
	var height = 512
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)

	var base_r = 0.72
	var base_g = 0.53
	var base_b = 0.34

	for y in range(height):
		# Efeito sutil de canelado horizontal do papelão
		var corrugate = sin(float(y) * 0.25) * 0.018
		for x in range(width):
			# Variação sutil de fibra orgânica do papel kraft
			var noise_val = (randf() - 0.5) * 0.025
			var vignette = 1.0 - (pow(abs(float(x) - 256.0) / 256.0, 4.0) + pow(abs(float(y) - 256.0) / 256.0, 4.0)) * 0.05

			var r = clampf((base_r + corrugate + noise_val) * vignette, 0.0, 1.0)
			var g = clampf((base_g + corrugate * 0.8 + noise_val * 0.8) * vignette, 0.0, 1.0)
			var b = clampf((base_b + corrugate * 0.6 + noise_val * 0.6) * vignette, 0.0, 1.0)

			img.set_pixel(x, y, Color(r, g, b, 1.0))

	img.save_png("res://assets/textures/cardboard_box_kraft.png")
	print("Textura cardboard_box_kraft.png gerada com sucesso!")
	quit(0)
