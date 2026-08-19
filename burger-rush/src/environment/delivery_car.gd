class_name DeliveryCar
extends Node3D

signal order_placed(order: Order)
signal order_completed(order: Order)
signal car_left(car: Node3D)

const CustomerMood = preload("res://src/customers/customer_mood.gd")
const CustomerExperience = preload("res://src/customers/customer_experience.gd")
const CustomerReview = preload("res://src/customers/customer_review.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")

enum CarState {
	SPAWNING,
	MOVING_TO_QUEUE,
	WAITING_IN_LINE,
	AT_WINDOW_WAITING_ORDER,
	AT_WINDOW_WAITING_FOOD,
	LEAVING
}

@export var car_id: int = 1
@export var move_speed: float = 8.5

@onready var model: Node3D = $Model
@onready var driver: Node3D = $Model/Driver
@onready var headlight_l: MeshInstance3D = $Model/HeadlightL
@onready var headlight_r: MeshInstance3D = $Model/HeadlightR
@onready var taillight_l: MeshInstance3D = $Model/TaillightL
@onready var taillight_r: MeshInstance3D = $Model/TaillightR
@onready var status_label: Label3D = $StatusLabel

# Áudio 3D Posicional do Veículo
var engine_audio: AudioStreamPlayer3D = null
var horn_audio: AudioStreamPlayer3D = null
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
var _horn_cooldown: float = 18.0

var current_state: CarState = CarState.SPAWNING
var target_position: Vector3 = Vector3.ZERO
var target_queue_index: int = -1
var spot_light: SpotLight3D = null

# Sistema de Humor e Experiência do Drive-Thru
var mood = null
var experience = null
var has_submitted_review: bool = false

var tolerance_order_wait: float = 85.0
var tolerance_food_wait: float = 135.0
var tolerance_in_line_wait: float = 140.0

var current_order: Order = null:
	set(val):
		current_order = val
		if current_order != null:
			tolerance_food_wait = _calculate_dynamic_food_tolerance(current_order)

func _calculate_dynamic_food_tolerance(order: Order) -> float:
	var base_time = 130.0 # Base generosa e confortável para 1 item no Drive-Thru
	if not order:
		return base_time

	var total_items_count = 0
	var burger_count = 0
	var side_count = 0
	var drink_count = 0

	for it in order.items:
		var qty = it.get("quantity", 1)
		var p_id = str(it.get("product_id", "")).to_lower()
		total_items_count += qty

		if p_id.contains("burger") or p_id.contains("sandwich") or p_id.contains("patty") or p_id == "cheeseburger" or p_id == "x_bacon" or p_id == "x_salada":
			burger_count += qty
		elif p_id.contains("fries") or p_id.contains("batata") or p_id.contains("onion"):
			side_count += qty
		elif p_id.contains("soda") or p_id.contains("juice") or p_id.contains("drink") or p_id.contains("cola") or p_id.contains("orange") or p_id.contains("grape"):
			drink_count += qty

	# Tolerância proporcional ao tamanho e complexidade do pedido:
	# - 1 item: 130s
	# - 2 a 3 itens: 165s a 200s
	# - 4+ itens: 220s a 290s
	var extra_time = 0.0
	if total_items_count <= 1:
		extra_time = 0.0
	elif total_items_count <= 3:
		extra_time = (burger_count * 35.0) + (side_count * 20.0) + (drink_count * 15.0)
	else:
		extra_time = (burger_count * 40.0) + (side_count * 25.0) + (drink_count * 18.0) + 25.0

	return clampf(base_time + extra_time, 125.0, 320.0)

static var last_used_color_idx: int = -1

var paint_colors = [
	Color(0.92, 0.93, 0.96), # Branco Alpino
	Color(0.12, 0.13, 0.15), # Preto Ônix
	Color(0.48, 0.50, 0.54), # Cinza Chumbo
	Color(0.82, 0.84, 0.88), # Prata Metálico
	Color(0.82, 0.16, 0.16), # Vermelho Rubi
	Color(0.18, 0.42, 0.82), # Azul Royal
	Color(0.16, 0.52, 0.32), # Verde Esmeralda
	Color(0.92, 0.78, 0.18), # Amarelo Canário
	Color(0.86, 0.48, 0.16), # Laranja Cobre
	Color(0.24, 0.32, 0.45)  # Azul Ardósia
]

func _init() -> void:
	if mood == null:
		mood = CustomerMood.new(100.0, 1.0)
	if experience == null:
		experience = CustomerExperience.new(car_id, "Drive-Thru", 100.0, "DRIVE_THRU")

func _enter_tree() -> void:
	_ensure_spotlight()
	_randomize_appearance()

func _ready() -> void:
	if mood == null:
		mood = CustomerMood.new(100.0, 1.0)
	if experience == null:
		experience = CustomerExperience.new(car_id, "Drive-Thru", mood.current_mood, "DRIVE_THRU")
	else:
		experience.channel_type = "DRIVE_THRU"
		experience.customer_id = car_id
		experience.customer_type = "Drive-Thru"

	_setup_audio()
	_ensure_spotlight()
	_randomize_appearance()
	_update_status_label()

func _setup_audio() -> void:
	if not engine_audio:
		engine_audio = AudioStreamPlayer3D.new()
		engine_audio.name = "EngineAudioPlayer"
		engine_audio.unit_size = 6.0
		engine_audio.max_distance = 45.0
		engine_audio.volume_db = -6.0
		add_child(engine_audio)

	if not horn_audio:
		horn_audio = AudioStreamPlayer3D.new()
		horn_audio.name = "HornAudioPlayer"
		horn_audio.unit_size = 12.0
		horn_audio.max_distance = 80.0
		horn_audio.volume_db = 1.0
		add_child(horn_audio)

func _play_engine(sound_id: String, vol_db: float = -6.0) -> void:
	if not engine_audio:
		return
	var stream = SoundSynthesizer.get_stream(sound_id)
	if engine_audio.stream == stream and engine_audio.playing:
		return
	engine_audio.stream = stream
	engine_audio.volume_db = vol_db
	if engine_audio.is_inside_tree():
		engine_audio.play()

func _play_horn() -> void:
	if not horn_audio:
		return
	horn_audio.stream = SoundSynthesizer.get_stream("car_horn_beep")
	horn_audio.volume_db = 1.0
	horn_audio.pitch_scale = randf_range(0.99, 1.01)
	if horn_audio.is_inside_tree():
		horn_audio.play()

func _ensure_spotlight() -> SpotLight3D:
	if not spot_light:
		spot_light = get_node_or_null("SpotLight3D") as SpotLight3D
		if not spot_light:
			spot_light = SpotLight3D.new()
			spot_light.name = "SpotLight3D"
			spot_light.light_color = Color(1.0, 0.95, 0.82)
			spot_light.light_energy = 2.0
			spot_light.spot_range = 18.0
			spot_light.spot_angle = 35.0
			spot_light.position = Vector3(-2.2, 0.6, 0.0) # Aponta para frente (-X)
			spot_light.rotation_degrees = Vector3(-5.0, 180.0, 0.0)
			spot_light.visible = false
			add_child(spot_light)
	return spot_light

func _randomize_appearance() -> void:
	var idx = randi() % paint_colors.size()
	if idx == last_used_color_idx:
		idx = (idx + 1 + (randi() % (paint_colors.size() - 1))) % paint_colors.size()
	last_used_color_idx = idx

	var chosen_color = paint_colors[idx]
	var paint_mat = StandardMaterial3D.new()
	paint_mat.albedo_color = chosen_color
	paint_mat.roughness = 0.30
	paint_mat.metallic = 0.35

	var chassis = get_node_or_null("Model/Chassis") as MeshInstance3D
	var roof = get_node_or_null("Model/Roof") as MeshInstance3D
	if chassis: chassis.material_override = paint_mat
	if roof: roof.material_override = paint_mat

func set_night_mode(is_night: bool) -> void:
	_ensure_spotlight()
	if spot_light:
		spot_light.visible = is_night

	var hl_mat = StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1.0, 0.96, 0.85)
	hl_mat.emission_enabled = is_night
	hl_mat.emission = Color(1.0, 0.95, 0.75) if is_night else Color.BLACK
	hl_mat.emission_energy_multiplier = 3.0 if is_night else 0.0

	var tl_mat = StandardMaterial3D.new()
	tl_mat.albedo_color = Color(0.85, 0.1, 0.1)
	tl_mat.emission_enabled = is_night
	tl_mat.emission = Color(0.9, 0.1, 0.1) if is_night else Color.BLACK
	tl_mat.emission_energy_multiplier = 2.0 if is_night else 0.0

	if not headlight_l: headlight_l = get_node_or_null("Model/HeadlightL") as MeshInstance3D
	if not headlight_r: headlight_r = get_node_or_null("Model/HeadlightR") as MeshInstance3D
	if not taillight_l: taillight_l = get_node_or_null("Model/TaillightL") as MeshInstance3D
	if not taillight_r: taillight_r = get_node_or_null("Model/TaillightR") as MeshInstance3D

	if headlight_l: headlight_l.material_override = hl_mat
	if headlight_r: headlight_r.material_override = hl_mat
	if taillight_l: taillight_l.material_override = tl_mat
	if taillight_r: taillight_r.material_override = tl_mat

func set_target_position(pos: Vector3, queue_idx: int) -> void:
	target_position = pos
	target_queue_index = queue_idx
	current_state = CarState.MOVING_TO_QUEUE
	_update_status_label()

func _physics_process(delta: float) -> void:
	if experience:
		experience.total_time_in_restaurant += delta

	match current_state:
		CarState.MOVING_TO_QUEUE:
			_play_engine("car_engine_approach", -6.0)
			var target_h = Vector3(target_position.x, position.y, target_position.z)
			position = position.move_toward(target_h, move_speed * delta)
			if position.distance_to(target_h) <= 0.1:
				position = target_h
				if target_queue_index == 0:
					if current_order == null:
						current_state = CarState.AT_WINDOW_WAITING_ORDER
						_play_horn() # Buzina curta e clara avisando chegada ao ponto de atendimento
					else:
						current_state = CarState.AT_WINDOW_WAITING_FOOD
				else:
					current_state = CarState.WAITING_IN_LINE
				_update_status_label()

		CarState.WAITING_IN_LINE:
			_play_engine("car_engine_idle", -8.0)
			_horn_cooldown -= delta
			if _horn_cooldown <= 0.0:
				_horn_cooldown = randf_range(30.0, 55.0)
				if randf() < 0.35:
					_play_horn()
			if experience:
				experience.wait_time_in_line += delta
			if mood:
				mood.decay_progressively(experience.wait_time_in_line, tolerance_in_line_wait, delta * 0.4)
			_update_status_label()

		CarState.AT_WINDOW_WAITING_ORDER:
			_play_engine("car_engine_idle", -8.0)
			if experience:
				experience.wait_time_to_order += delta
			if mood:
				mood.decay_progressively(experience.wait_time_to_order, tolerance_order_wait, delta)
				if mood.is_exhausted() or (experience and experience.wait_time_to_order >= tolerance_order_wait):
					abandon_drive_thru("Demora no atendimento do Drive-Thru")
					return
			_update_status_label()

		CarState.AT_WINDOW_WAITING_FOOD:
			if current_order == null or not is_instance_valid(current_order):
				abandon_drive_thru("Pedido do Drive-thru cancelado")
				return
			if current_order.state == Order.State.COMPLETED or current_order.state == Order.State.DELIVERED:
				finish_and_leave()
				return
			if current_order.state == Order.State.CANCELLED:
				abandon_drive_thru("Pedido do Drive-thru cancelado")
				return

			_play_engine("car_engine_idle", -8.0)
			if experience:
				experience.wait_time_for_food += delta
			if mood:
				mood.decay_progressively(experience.wait_time_for_food, tolerance_food_wait, delta)
				if mood.is_exhausted() or (experience and experience.wait_time_for_food >= tolerance_food_wait):
					abandon_drive_thru("Demora na entrega do Drive-Thru")
					return
			_update_status_label()

		CarState.LEAVING:
			_play_engine("car_engine_leave", -6.0)
			var target_h = Vector3(target_position.x, position.y, target_position.z)
			position = position.move_toward(target_h, (move_speed * 1.3) * delta)
			if position.distance_to(target_h) <= 0.5:
				car_left.emit(self)
				queue_free()


func take_order(player: Node3D = null) -> Order:
	if current_order != null:
		return current_order

	var order_mgr = OrderManager.instance
	if not order_mgr and is_inside_tree() and get_tree() and get_tree().root:
		order_mgr = get_tree().root.find_child("OrderManager", true, false) as OrderManager
	if not order_mgr:
		var curr = self.get_parent()
		while curr:
			if curr.has_node("OrderManager"):
				order_mgr = curr.get_node("OrderManager") as OrderManager
				break
			curr = curr.get_parent()
	if not order_mgr:
		return null

	var group_size = 1
	var r = randf()
	if r < 0.65:
		group_size = 1 # 65% Pequeno (1 lanche / combo)
	elif r < 0.92:
		group_size = 2 # 27% Médio (2 lanches)
	else:
		group_size = 3 # 8% Grande (3 lanches - raro)

	current_order = order_mgr.create_group_order(self, group_size, 0, "DRIVE_THRU")
	current_state = CarState.AT_WINDOW_WAITING_FOOD

	if mood:
		mood.boost(15.0) # Anotou o pedido -> motorista fica animado

	_update_status_label()

	if player:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("🚗 Drive-Thru: Pedido #%03d registrado (R$ %.2f)" % [current_order.id, current_order.total_price])

	order_placed.emit(current_order)
	return current_order

func get_interaction_prompt(player: Node = null) -> String:
	if current_state == CarState.AT_WINDOW_WAITING_ORDER:
		return "[E] Atender Pedido (Drive-Thru Carro #%d)" % car_id
	elif current_state == CarState.AT_WINDOW_WAITING_FOOD:
		if player and player.get("held_item") != null:
			var held = player.get("held_item")
			var d_name = held.get_display_name() if held.has_method("get_display_name") else str(held.get("item_id", "Pedido")).capitalize()
			return "🖱️ / [E] Entregar %s (Carro #%d)" % [d_name, car_id]
		return "Carro #%d aguardando entrega..." % car_id
	return ""

func interact(player: Node3D) -> void:
	if current_state == CarState.AT_WINDOW_WAITING_ORDER:
		if player.get("held_item") == null:
			take_order(player)
		return

	if current_state == CarState.AT_WINDOW_WAITING_FOOD:
		_process_delivery(player)

func interact_item(player: Node3D) -> void:
	if current_state == CarState.AT_WINDOW_WAITING_ORDER:
		if player.get("held_item") == null:
			take_order(player)
		return

	if current_state == CarState.AT_WINDOW_WAITING_FOOD:
		_process_delivery(player)

func _process_delivery(player: Node3D) -> void:
	if not player or player.get("held_item") == null:
		return

	var deliv_station: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		deliv_station = get_tree().root.find_child("DeliveryStation", true, false)

	if deliv_station:
		deliv_station.interact(player)
		return

	# Fallback caso não haja DeliveryStation na cena:
	var held_item = player.get("held_item")
	var product_id: String = str(held_item.get("item_id")) if held_item.get("item_id") != null else ""
	var item: Node3D = player.take_held_item()
	if not item:
		return

	var matching_order = current_order
	var is_valid_delivery = false

	if matching_order != null and current_state == CarState.AT_WINDOW_WAITING_FOOD:
		if item is DeliveryBag:
			var bag = item as DeliveryBag
			var prods = bag.get_products()
			if not prods.is_empty():
				var all_match = true
				var delivered_items: Array[String] = []
				for itm in prods:
					var p_id = str(itm.get("id", ""))
					var r_id = str(itm.get("recipe_id", ""))
					var matched_id = ""

					if matching_order.has_pending_product(p_id):
						matched_id = p_id
					elif r_id != "" and matching_order.has_pending_product(r_id):
						matched_id = r_id
					elif (p_id == "packaged_burger" or r_id != "") and matching_order.has_pending_product("burger"):
						matched_id = "burger"
					elif (p_id == "packaged_burger" or r_id != "") and matching_order.has_pending_product("cheeseburger"):
						matched_id = "cheeseburger"
					elif p_id in ["fries", "fries_pack", "potato_box"] and matching_order.has_pending_product("fries"):
						matched_id = "fries"
					elif p_id in ["onion_rings", "fried_onions"] and matching_order.has_pending_product("onion_rings"):
						matched_id = "onion_rings"
					elif p_id.begins_with("soda_") or p_id.begins_with("juice_") or p_id == "drink_cup":
						for ord_itm in matching_order.items:
							var oid = str(ord_itm.get("product_id", ""))
							if (oid.begins_with("soda_") or oid.begins_with("juice_") or oid == "drink_cup" or oid == "soda") and matching_order.has_pending_product(oid):
								matched_id = oid
								break

					if matched_id != "":
						matching_order.register_product_delivered(matched_id)
						delivered_items.append(matched_id)
					else:
						all_match = false
						break

				if all_match and not delivered_items.is_empty():
					is_valid_delivery = true
		else:
			var matched_id = ""
			if matching_order.has_pending_product(product_id):
				matched_id = product_id
			elif product_id == "packaged_burger" and (matching_order.has_pending_product("burger") or matching_order.has_pending_product("cheeseburger")):
				matched_id = "burger" if matching_order.has_pending_product("burger") else "cheeseburger"
			elif product_id in ["fries", "fries_pack"] and matching_order.has_pending_product("fries"):
				matched_id = "fries"
			elif product_id in ["onion_rings", "fried_onions"] and matching_order.has_pending_product("onion_rings"):
				matched_id = "onion_rings"
			elif (product_id.begins_with("soda_") or product_id.begins_with("juice_")) and matching_order.has_pending_product(product_id):
				matched_id = product_id

			if matched_id != "":
				matching_order.register_product_delivered(matched_id)
				is_valid_delivery = true

	if is_valid_delivery and matching_order != null:
		if matching_order.is_all_delivered():
			var fin = FinanceManager.get_instance()
			if fin:
				fin.record_sale(matching_order.total_price, "drive_thru", "Drive-Thru: %s" % matching_order.items[0].get("product_name", product_id))
			else:
				var economy = EconomyManager.get_instance()
				if economy:
					economy.add_money(matching_order.total_price, "Drive-Thru: %s" % matching_order.items[0].get("product_name", product_id))
			_play_payment_sound()
			receive_order(product_id)
			var order_mgr = OrderManager.get_instance()
			if order_mgr:
				order_mgr.complete_order(matching_order)
			if player and player.has_node("HUD"):
				var hud = player.get_node("HUD")
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("🚗 Pedido #%03d entregue com sucesso! +$%.2f" % [matching_order.id, matching_order.total_price])
	else:
		on_order_wrong("Pedido incorreto entregue no Drive-Thru!")
		if player and player.has_node("HUD"):
			var hud = player.get_node("HUD")
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("❌ Pedido incorreto no Drive-Thru! O cliente foi embora sem pagar.")

	item.queue_free()

func _play_payment_sound() -> void:
	var snd = AudioStreamPlayer3D.new()
	snd.name = "PaymentAudioPlayer"
	snd.unit_size = 8.0
	snd.max_distance = 35.0
	snd.volume_db = -2.0
	snd.stream = SoundSynthesizer.get_stream("payment_success_cash")
	add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)

func receive_order(product_id: String) -> void:
	if current_order == null:
		return

	if current_order.is_all_delivered() or current_order.state == Order.State.DELIVERED or current_order.state == Order.State.COMPLETED:
		finish_and_leave()

func finish_and_leave() -> void:
	if current_state == CarState.LEAVING:
		return

	if mood:
		mood.boost(25.0)

	if experience and current_order:
		experience.final_mood = mood.current_mood if mood else 100.0
		experience.food_quality = 1.0
		experience.order_correct = true
		var items_str: Array[String] = []
		for it in current_order.items:
			items_str.append("%dx %s" % [it.get("quantity", 1), it.get("product_name", "Lanche")])
		experience.order_summary = ", ".join(items_str)

	_submit_review()

	current_state = CarState.LEAVING
	_play_engine("car_engine_leave", -11.0)
	target_position = Vector3(-42.0, position.y, position.z) # Rumo à saída oeste
	_update_status_label()

	if current_order:
		order_completed.emit(current_order)

func on_order_wrong(reason: String = "Pedido incorreto no Drive-Thru!") -> void:
	if current_state == CarState.LEAVING:
		return

	if mood:
		mood.current_mood = 0.0

	if experience:
		experience.order_correct = false
		experience.abandoned = true
		experience.abandon_type = CustomerExperience.AbandonType.WRONG_ORDER
		experience.abandon_reason = reason
		experience.food_quality = 0.0

	if not horn_audio:
		_setup_audio()
	if horn_audio:
		horn_audio.stream = SoundSynthesizer.get_stream("customer_wrong_order")
		if horn_audio.stream and horn_audio.is_inside_tree():
			horn_audio.play()

	# Cancela o pedido no OrderManager se existir (sem pagamento)
	if current_order and current_order.state != Order.State.COMPLETED:
		current_order.state = Order.State.CANCELLED
		var order_mgr = OrderManager.instance
		if not order_mgr and is_inside_tree() and get_tree() and get_tree().root:
			order_mgr = get_tree().root.find_child("OrderManager", true, false)
		if order_mgr:
			order_mgr.active_orders.erase(current_order)
			if order_mgr.has_signal("order_cancelled"):
				order_mgr.order_cancelled.emit(current_order)

	_submit_review()

	current_state = CarState.LEAVING
	_play_engine("car_engine_leave", -11.0)
	target_position = Vector3(-42.0, position.y, position.z)
	_update_status_label()

func abandon_drive_thru(reason: String) -> void:
	if current_state == CarState.LEAVING:
		return

	if experience:
		experience.abandoned = true
		if experience.abandon_type == CustomerExperience.AbandonType.NONE:
			experience.abandon_type = CustomerExperience.AbandonType.TIMEOUT
		experience.abandon_reason = reason
		experience.final_mood = mood.current_mood if mood else 0.0

	# Cancela o pedido no OrderManager se existir
	if current_order and current_order.state != Order.State.COMPLETED:
		current_order.state = Order.State.CANCELLED
		var order_mgr = OrderManager.instance
		if not order_mgr and is_inside_tree() and get_tree() and get_tree().root:
			order_mgr = get_tree().root.find_child("OrderManager", true, false)
		if not order_mgr:
			var curr = self.get_parent()
			while curr:
				if curr.has_node("OrderManager"):
					order_mgr = curr.get_node("OrderManager")
					break
				curr = curr.get_parent()
		if order_mgr:
			order_mgr.active_orders.erase(current_order)
			if order_mgr.has_signal("order_cancelled"):
				order_mgr.order_cancelled.emit(current_order)

	_submit_review()

	current_state = CarState.LEAVING
	target_position = Vector3(-42.0, position.y, position.z)
	_update_status_label()

func _submit_review() -> void:
	if has_submitted_review or not experience:
		return
	has_submitted_review = true

	if mood:
		experience.final_mood = mood.current_mood

	if current_order:
		if current_order.items.size() > 0:
			var f_item = current_order.items[0]
			experience.primary_product_id = f_item.get("product_id", f_item.get("recipe_id", "burger_classic"))
			experience.charged_price = f_item.get("unit_price", current_order.total_price)
		else:
			experience.charged_price = current_order.total_price

	var clock_day = 1
	var clock_time = "12:00"
	var clock = null
	if is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	if clock:
		clock_day = clock.get("day_number") if clock.get("day_number") != null else 1
		clock_time = clock.get_formatted_time() if clock.has_method("get_formatted_time") else "12:00"

	var review = experience.generate_review(clock_day, clock_time)
	var rep_mgr = ReputationManager.instance
	if not rep_mgr:
		var curr = self.get_parent()
		while curr:
			if curr.has_node("ReputationManager"):
				rep_mgr = curr.get_node("ReputationManager")
				break
			curr = curr.get_parent()
	if not rep_mgr and is_inside_tree() and get_tree() and get_tree().root:
		rep_mgr = get_tree().root.find_child("ReputationManager", true, false)

	if rep_mgr:
		rep_mgr.add_review(review)

func _update_status_label() -> void:
	if not status_label:
		status_label = get_node_or_null("StatusLabel") as Label3D
	if not status_label:
		return

	var emoji = mood.get_emoji() if mood else "🙂"
	var mood_color = mood.get_color() if mood else Color(1, 1, 1)

	match current_state:
		CarState.SPAWNING, CarState.MOVING_TO_QUEUE:
			status_label.text = "%s 🚗 Carro #%d" % [emoji, car_id]
			status_label.modulate = Color(1.0, 1.0, 1.0, 0.8)

		CarState.WAITING_IN_LINE:
			status_label.text = "%s ⏳ Fila (#%d)" % [emoji, target_queue_index + 1]
			status_label.modulate = mood_color

		CarState.AT_WINDOW_WAITING_ORDER:
			var pct = int(mood.current_mood) if mood else 100
			if pct <= 25:
				status_label.text = "%s ⚠️ Quase Desistindo! (%d%%)" % [emoji, pct]
				status_label.modulate = Color(1.0, 0.25, 0.25)
			else:
				status_label.text = "%s 💬 [E] Fazer Pedido (%d%%)" % [emoji, pct]
				status_label.modulate = mood_color

		CarState.AT_WINDOW_WAITING_FOOD:
			var pend = current_order.get_total_quantity() - current_order.get_delivered_count() if current_order else 1
			var pct = int(mood.current_mood) if mood else 100
			if pct <= 25:
				status_label.text = "%s ⚠️ Demora na Entrega! (%d%%)" % [emoji, pct]
				status_label.modulate = Color(1.0, 0.25, 0.25)
			else:
				status_label.text = "%s 🍔 Aguardando (%d)" % [emoji, pend]
				status_label.modulate = mood_color

		CarState.LEAVING:
			if experience and experience.abandoned:
				if experience.abandon_type == CustomerExperience.AbandonType.WRONG_ORDER or "errad" in experience.abandon_reason.to_lower() or "incorret" in experience.abandon_reason.to_lower():
					status_label.text = "😡 🚗 'Esse pedido não é o meu! Fui.'"
					status_label.modulate = Color(1.0, 0.2, 0.2)
				else:
					status_label.text = "😡 ⏰ 'Demorou demais! Desisti do Drive-Thru.'"
					status_label.modulate = Color(1.0, 0.25, 0.25)
			else:
				status_label.text = "%s ✓ Obrigado!" % emoji
				status_label.modulate = Color(0.4, 1.0, 0.5, 1.0)
