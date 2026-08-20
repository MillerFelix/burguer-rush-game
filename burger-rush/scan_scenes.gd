extends SceneTree

func _init() -> void:
	print("--- SCANNING ALL TSCN FILES IN RES:// ---")
	var files: Array[String] = []
	var dirs = [
		"res://src",
		"res://src/ui",
		"res://src/stations",
		"res://src/items",
		"res://src/player",
		"res://src/environment",
		"res://src/recipes",
		"res://src/core",
		"res://src/time",
		"res://src/economy",
		"res://src/orders",
		"res://src/inventory",
		"res://src/progression"
	]
	
	for d in dirs:
		var dir = DirAccess.open(d)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".tscn"):
					files.append(d + "/" + file_name)
				file_name = dir.get_next()
	
	var failed: Array[String] = []
	for f in files:
		var res = load(f)
		if res == null:
			print("[FAILED LOAD] ", f)
			failed.append(f)
		else:
			print("[OK] ", f)
			
	print("\n=================================================")
	print("TOTAL SCANNED: %d | FAILED: %d" % [files.size(), failed.size()])
	for fail in failed:
		print(" - FAIL: %s" % fail)
	print("=================================================")
	quit(0 if failed.is_empty() else 1)
