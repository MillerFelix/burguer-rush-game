extends SceneTree

func _init() -> void:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Fundo 100% transparente

	var wire_col = Color(0.85, 0.88, 0.92, 1.0)
	var shadow_col = Color(0.4, 0.42, 0.46, 1.0)
	var highlight_col = Color(0.98, 0.99, 1.0, 1.0)

	var step = 24
	var wire_w = 4

	for x in range(256):
		for y in range(256):
			var x_mod = x % step
			var y_mod = y % step

			var is_wire_x = (x_mod < wire_w)
			var is_wire_y = (y_mod < wire_w)

			if is_wire_x or is_wire_y:
				if x_mod == 0 or y_mod == 0:
					img.set_pixel(x, y, highlight_col)
				elif x_mod == wire_w - 1 or y_mod == wire_w - 1:
					img.set_pixel(x, y, shadow_col)
				else:
					img.set_pixel(x, y, wire_col)

	img.save_png("res://assets/textures/wire_mesh_grid.png")
	print("Grade de malha aramada wire_mesh_grid.png gerada com sucesso!")
	quit()
