extends SceneTree

func _init() -> void:
	var char_scene = load("res://assets/models/kaykit_character.glb") as PackedScene
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)

	var mesh_inst = char_inst.find_child("Skinned Mesh 0", true, false) as MeshInstance3D
	if mesh_inst:
		var aabb = mesh_inst.get_aabb()
		print("AABB: ", aabb)
		print("Size: ", aabb.size)
		print("Position: ", mesh_inst.global_position)
	
	var skel = char_inst.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel:
		print("Bone count: ", skel.get_bone_count())
		for b in range(min(15, skel.get_bone_count())):
			print("  Bone %d: %s" % [b, skel.get_bone_name(b)])

	char_inst.queue_free()
	quit(0)
