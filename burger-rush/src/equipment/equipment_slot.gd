class_name EquipmentSlot
extends Node3D

@export var equipment_id: String = "second_grill"
@export var equipment_scene: PackedScene

var installed_instance: Node3D = null

func _ready() -> void:
	var equip_mgr = EquipmentManager.get_instance()
	if equip_mgr:
		equip_mgr.equipment_purchased.connect(_on_equipment_purchased)
		if equip_mgr.is_installed(equipment_id):
			_install()

func _on_equipment_purchased(purchased_id: String) -> void:
	if purchased_id == equipment_id:
		_install()

func _install() -> void:
	if installed_instance or not equipment_scene:
		return

	installed_instance = equipment_scene.instantiate() as Node3D
	add_child(installed_instance)
	installed_instance.position = Vector3.ZERO
	installed_instance.rotation = Vector3.ZERO
