extends SceneTree

func _init() -> void:
	var char_scene = load("res://assets/models/kaykit_character.glb") as PackedScene
	var char_inst = char_scene.instantiate()
	root.add_child(char_inst)

	var mesh_inst = char_inst.find_child("Skinned Mesh 0", true, false) as MeshInstance3D
	assert(mesh_inst != null, "MeshInstance3D deve existir")
	
	var tex = load("res://assets/models/character.png") as Texture2D
	assert(tex != null, "character.png texture deve carregar")

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.85
	mat.metallic = 0.0
	mesh_inst.material_override = mat

	print("Texture assigned successfully!")
	print("Material override active: ", mesh_inst.material_override != null)

	char_inst.queue_free()
	quit(0)
