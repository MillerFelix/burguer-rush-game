class_name EmployeeTask
extends RefCounted

# =============================================================================
# BURGER RUSH - MODELO DE TAREFA DE FUNCIONÁRIO
#
# Estrutura modular de tarefa com prioridade configurável e reserva de exclusividade.
# =============================================================================

enum TaskType {
	SERVE_CUSTOMER,     # Prioridade 1: Atender cliente esperando na mesa
	SERVE_DRIVETHRU,    # Prioridade 2: Atender veículo na janela do drive-thru
	CLEAN_TABLE,        # Prioridade 3: Limpar mesa suja desocupada
	CLEAN_PUDDLE,       # Prioridade 4: Secar poça d'água no chão
	CLEAN_FLOOR_SPOT,   # Prioridade 4: Limpar mancha de sujeira no chão
	CLEAN_STATION,      # Prioridade 5: Limpar bancada/grelha/fritadeira suja
	OPERATE_CASHIER,    # Prioridade 6: Cobrar cliente na fila do caixa
	WASH_SPONGE,        # Tarefa de suporte: Lavar bucha suja na pia
	RESTOCK,            # Tarefa futura: Reposição de insumos
	IDLE_WAIT           # Descanso na área reservada
}

var task_id: int = 0
var task_type: TaskType = TaskType.IDLE_WAIT
var target_node: Node3D = null
var target_position: Vector3 = Vector3.ZERO
var priority: int = 7
var claimed_by: Node = null
var is_completed: bool = false
var created_time: float = 0.0

func _init(p_type: TaskType = TaskType.IDLE_WAIT, p_target: Node3D = null, p_pos: Vector3 = Vector3.ZERO, p_priority: int = 7) -> void:
	task_type = p_type
	target_node = p_target
	target_position = p_pos
	priority = p_priority
	created_time = Time.get_ticks_msec() / 1000.0

func is_available() -> bool:
	return not is_completed and (claimed_by == null or not is_instance_valid(claimed_by))
