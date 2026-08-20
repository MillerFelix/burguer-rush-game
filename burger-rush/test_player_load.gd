extends SceneTree

func _init() -> void:
	print("--- DIRECT LOADING res://src/player/player.tscn ---")
	var p = load("res://src/player/player.tscn")
	print("Loaded player: ", p)
	if p:
		var inst = p.instantiate()
		print("Instantiated player: ", inst)
	quit(0)
