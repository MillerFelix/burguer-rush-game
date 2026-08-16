extends SceneTree

func _init() -> void:
	var size = 512
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 16.0

	# 1. Background disc
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				# Bezel edge
				if dist >= radius - 8.0:
					img.set_pixel(x, y, Color(0.35, 0.38, 0.42, 1.0))
				elif dist >= radius - 12.0:
					img.set_pixel(x, y, Color(0.75, 0.78, 0.82, 1.0))
				else:
					# Parchment face
					var grad = 1.0 - (dist / radius) * 0.1
					img.set_pixel(x, y, Color(0.96 * grad, 0.95 * grad, 0.92 * grad, 1.0))

	# 2. Temperature colored arcs and ticks
	# Angle range from 135 deg to 405 deg (span 270 deg)
	for i in range(270):
		var angle_deg = 135.0 + i
		var rad = deg_to_rad(angle_deg)
		var arc_col = Color(0.3, 0.55, 0.85, 1.0) # Cold
		if angle_deg >= 340.0:
			arc_col = Color(0.9, 0.2, 0.15, 1.0) # High Hot
		elif angle_deg >= 250.0:
			arc_col = Color(0.15, 0.78, 0.32, 1.0) # Ideal Cooking Zone (Green)
		elif angle_deg >= 195.0:
			arc_col = Color(0.95, 0.65, 0.15, 1.0) # Warming (Amber)

		# Draw arc band
		for r in range(int(radius - 34.0), int(radius - 18.0)):
			var px = int(center.x + cos(rad) * r)
			var py = int(center.y + sin(rad) * r)
			if px >= 0 and px < size and py >= 0 and py < size:
				img.set_pixel(px, py, arc_col)

	# 3. Ticks
	for i in range(28):
		var angle_deg = 135.0 + (270.0 / 27.0) * i
		var rad = deg_to_rad(angle_deg)
		var is_major = (i % 3 == 0)
		var r_outer = radius - 36.0
		var r_inner = radius - (54.0 if is_major else 44.0)
		var steps = 18
		for s in range(steps):
			var r = lerp(r_inner, r_outer, float(s) / steps)
			for offset_ang in [-0.008, 0.0, 0.008] if is_major else [0.0]:
				var px = int(center.x + cos(rad + offset_ang) * r)
				var py = int(center.y + sin(rad + offset_ang) * r)
				if px >= 0 and px < size and py >= 0 and py < size:
					img.set_pixel(px, py, Color(0.18, 0.20, 0.24, 1.0))

	# 4. Center hub
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= 38.0:
				if dist >= 34.0:
					img.set_pixel(x, y, Color(0.4, 0.42, 0.48, 1.0))
				elif dist <= 16.0:
					img.set_pixel(x, y, Color(0.2, 0.22, 0.26, 1.0))
				else:
					img.set_pixel(x, y, Color(0.85, 0.86, 0.88, 1.0))

	img.save_png("res://assets/textures/thermometer_dial.png")
	print("Thermometer dial texture created!")
	quit(0)
