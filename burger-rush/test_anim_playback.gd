extends SceneTree

func _init() -> void:
	var char_scene = load("res://assets/models/kaykit_character.glb") as PackedScene
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)

	var anim_player = char_inst.get_node("AnimationPlayer") as AnimationPlayer
	assert(anim_player.has_animation("Walk"), "Deve ter animação Walk")
	assert(anim_player.has_animation("Idle"), "Deve ter animação Idle")

	anim_player.play("Walk")
	print("Walk animation playing: ", anim_player.current_animation)
	print("Walk animation length: ", anim_player.get_animation("Walk").length)

	anim_player.play("Idle")
	print("Idle animation playing: ", anim_player.current_animation)
	print("Idle animation length: ", anim_player.get_animation("Idle").length)

	char_inst.queue_free()
	print("All animations verified successfully!")
	quit(0)
