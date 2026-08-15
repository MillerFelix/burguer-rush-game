extends SceneTree

func _init() -> void:
	print("--- Testing PackedScene load for kaykit_character.glb ---")
	var char_scene = load("res://assets/models/kaykit_character.glb") as PackedScene
	assert(char_scene != null, "PackedScene deve carregar com sucesso")
	var char_instance = char_scene.instantiate()
	root.add_child(char_instance)
	print("Instantiated successfully: ", char_instance.name)
	
	var anim_player = char_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert(anim_player != null, "AnimationPlayer deve existir")
	print("Animations available: ", str(anim_player.get_animation_list()))
	
	char_instance.queue_free()
	print("--- Test Passed ---")
	quit(0)
