extends SceneTree

func _init() -> void:
	var script = load("res://src/ui/computer_ui.gd")
	if script:
		print("computer_ui.gd loaded successfully!")
	quit(0)
