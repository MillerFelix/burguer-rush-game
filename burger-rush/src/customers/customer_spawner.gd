class_name CustomerSpawner
extends Node3D

@export var customer_scene: PackedScene
@export var spawn_interval: float = 12.0
@export var max_customers: int = 3
@export var auto_spawn: bool = true

@export var spawn_position: Vector3 = Vector3(8.5, 0.0, 3.0)
@export var exit_position: Vector3 = Vector3(8.5, 0.0, 3.0)

var active_customers: Array[Customer] = []
var spawn_timer: float = 0.0

func _ready() -> void:
	if not customer_scene:
		customer_scene = load("res://src/customers/customer.tscn")

	# Primeiro spawn após pequeno delay quando aberto
	spawn_timer = spawn_interval - 2.0

func _process(delta: float) -> void:
	# Limpa referências a clientes finalizados / deletados
	active_customers = active_customers.filter(func(c): return is_instance_valid(c) and c.state != Customer.State.FINISHED)

	if not auto_spawn:
		return

	# Só spawna durante o horário de funcionamento
	var clock = GameClock.get_instance()
	if clock and clock.state != GameClock.State.OPEN:
		return

	# Só spawna se houver mesas disponíveis
	var table_mgr = TableManager.get_instance()
	if table_mgr and table_mgr.get_available_table_count() <= 0:
		return

	if active_customers.size() < max_customers:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_customer()

func spawn_customer(product_id: String = "") -> Customer:
	if not customer_scene:
		return null

	var customer = customer_scene.instantiate() as Customer
	add_child(customer)
	customer.setup(spawn_position, exit_position, product_id)
	active_customers.append(customer)
	return customer
