extends SceneTree

func _init() -> void:
	var char_scene = load("res://assets/models/kaykit_character.glb") as PackedScene
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)

	var skel = char_inst.find_child("Skeleton3D", true, false) as Skeleton3D
	assert(skel != null, "Skeleton3D deve existir")

	var head_attach = BoneAttachment3D.new()
	head_attach.name = "Head"
	head_attach.bone_name = "DEF-head"
	skel.add_child(head_attach)

	var torso_attach = BoneAttachment3D.new()
	torso_attach.name = "Torso"
	torso_attach.bone_name = "DEF-spine002"
	skel.add_child(torso_attach)

	print("BoneAttachment3D added successfully!")
	print("Head attachment bone index: ", head_attach.bone_idx)
	print("Torso attachment bone index: ", torso_attach.bone_idx)

	char_inst.queue_free()
	quit(0)
