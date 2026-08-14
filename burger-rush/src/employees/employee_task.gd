class_name EmployeeTask
extends RefCounted

enum TaskType {
	GRILL_PATTY,
	SERVE_CUSTOMER,
	CLEAN_TABLE,
	TAKE_ORDER
}

var task_type: TaskType
var target_node: Node3D = null
var priority: int = 1
var is_claimed: bool = false
var created_time: float = 0.0

func _init(p_type: TaskType = TaskType.GRILL_PATTY, p_target: Node3D = null, p_priority: int = 1) -> void:
	task_type = p_type
	target_node = p_target
	priority = p_priority
