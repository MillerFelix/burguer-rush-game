extends SceneTree

func _init() -> void:
	var char_scene = load("res://assets/models/kaykit_character.glb") as PackedScene
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)
	_print_tree(char_inst, 0)
	char_inst.queue_free()
	quit(0)

func _print_tree(node: Node, depth: int) -> void:
	var p = "  ".repeat(depth)
	print("%s- '%s' (%s)" % [p, node.name, node.get_class()])
	for c in node.get_children():
		_print_tree(c, depth + 1)
