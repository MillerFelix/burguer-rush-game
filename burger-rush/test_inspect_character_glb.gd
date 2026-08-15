extends SceneTree

func _init() -> void:
	print("--- Inspecting kaykit_character.glb with GLTFDocument ---")
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var err = gltf_doc.append_from_file("res://assets/models/kaykit_character.glb", gltf_state)
	if err != OK:
		print("Failed to append from file: ", err)
		quit(1)
		return

	var char_instance = gltf_doc.generate_scene(gltf_state)
	root.add_child(char_instance)

	_print_tree_recursive(char_instance, 0)
	char_instance.queue_free()
	print("--- Done ---")
	quit(0)

func _print_tree_recursive(node: Node, depth: int) -> void:
	var prefix = "  ".repeat(depth)
	print("%s- %s (%s)" % [prefix, node.name, node.get_class()])
	if node is AnimationPlayer:
		var anim_player = node as AnimationPlayer
		var list = anim_player.get_animation_list()
		print("%s  [Animations: %s]" % [prefix, str(list)])
	for child in node.get_children():
		_print_tree_recursive(child, depth + 1)
