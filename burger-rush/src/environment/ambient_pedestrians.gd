class_name AmbientPedestrians
extends Node3D

const PED_SCENE = preload("res://src/environment/ambient_pedestrian.tscn")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

class PedestrianInstance:
	var node: Node3D
	var speed: float
	var direction: float
	var walk_phase: float = 0.0
	var arm_l: Node3D
	var arm_r: Node3D
	var leg_l: Node3D
	var leg_r: Node3D

var active_peds: Array[PedestrianInstance] = []
var spawn_timer: float = 1.5
var next_spawn_interval: float = 4.0

func _enter_tree() -> void:
	if active_peds.is_empty():
		_spawn_pedestrian(true, randf_range(-10.0, 10.0), 10.5)
		_spawn_pedestrian(false, randf_range(-15.0, 15.0), 25.0)

func _ready() -> void:
	if active_peds.is_empty():
		_spawn_pedestrian(true, randf_range(-10.0, 10.0), 10.5)
		_spawn_pedestrian(false, randf_range(-15.0, 15.0), 25.0)

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= next_spawn_interval and active_peds.size() < 4:
		spawn_timer = 0.0
		next_spawn_interval = randf_range(4.5, 9.0)
		var dir_right = (randi() % 2 == 0)
		var sidewalk_z = 10.5 if (randi() % 2 == 0) else 25.0
		_spawn_pedestrian(dir_right, -999.0, sidewalk_z)

	var i = active_peds.size() - 1
	while i >= 0:
		var p = active_peds[i]
		if not is_instance_valid(p.node):
			active_peds.remove_at(i)
			i -= 1
			continue

		p.node.position.x += p.speed * p.direction * delta
		p.walk_phase += delta * 7.5

		var swing = sin(p.walk_phase) * 0.45
		if p.arm_l:
			p.arm_l.rotation.x = -swing
		if p.arm_r:
			p.arm_r.rotation.x = swing
		if p.leg_l:
			p.leg_l.rotation.x = swing
		if p.leg_r:
			p.leg_r.rotation.x = -swing

		# Despawn fora da calçada
		if (p.direction > 0 and p.node.position.x > 40.0) or (p.direction < 0 and p.node.position.x < -40.0):
			p.node.queue_free()
			active_peds.remove_at(i)

		i -= 1

func _spawn_pedestrian(dir_right: bool, custom_x: float, z_pos: float) -> void:
	var ped = PED_SCENE.instantiate() as Node3D
	add_child(ped)

	var is_child = (randf() < 0.2)
	CharacterAppearance.apply_random_customer_appearance(ped, is_child)

	var arm_l = ped.get_node_or_null("Model/ArmLeft") as MeshInstance3D
	var arm_r = ped.get_node_or_null("Model/ArmRight") as MeshInstance3D
	var leg_l = ped.get_node_or_null("Model/LegLeft") as MeshInstance3D
	var leg_r = ped.get_node_or_null("Model/LegRight") as MeshInstance3D

	var p = PedestrianInstance.new()
	p.node = ped
	p.speed = randf_range(1.6, 2.3) if not is_child else randf_range(1.8, 2.5)
	p.arm_l = arm_l
	p.arm_r = arm_r
	p.leg_l = leg_l
	p.leg_r = leg_r

	if dir_right:
		p.direction = 1.0
		var spawn_x = custom_x if custom_x != -999.0 else -38.0
		ped.position = Vector3(spawn_x, 0, z_pos)
		ped.rotation.y = PI * 0.5
	else:
		p.direction = -1.0
		var spawn_x = custom_x if custom_x != -999.0 else 38.0
		ped.position = Vector3(spawn_x, 0, z_pos)
		ped.rotation.y = -PI * 0.5

	active_peds.append(p)
