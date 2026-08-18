class_name ComputerStation
extends StaticBody3D

const PowerManager = preload("res://src/core/power_manager.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const Order = preload("res://src/orders/order.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

@export var computer_ui_scene: PackedScene

var computer_ui_instance: ComputerUI = null
var unviewed_orders_count: int = 0
var notified_order_ids: Dictionary = {}

var notification_badge: Label3D = null
var audio_player: AudioStreamPlayer3D = null

func _enter_tree() -> void:
	_setup_3d_notification_badge()
	_setup_audio_player()
	_connect_order_manager()

func _ready() -> void:
	if not computer_ui_scene:
		computer_ui_scene = load("res://src/ui/computer_ui.tscn")

	if computer_ui_scene and not computer_ui_instance:
		computer_ui_instance = computer_ui_scene.instantiate() as ComputerUI
		add_child(computer_ui_instance)
		computer_ui_instance.orders_viewed.connect(_on_orders_viewed_in_ui)

	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "computer", "Terminal / PC do Escritório", 0.35, true)

	_setup_3d_notification_badge()
	_setup_audio_player()
	_connect_order_manager()

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func _setup_3d_notification_badge() -> void:
	notification_badge = get_node_or_null("NotificationBadge") as Label3D
	if not notification_badge:
		notification_badge = Label3D.new()
		notification_badge.name = "NotificationBadge"
		add_child(notification_badge)
		# Posicionado confortavelmente acima do monitor do PC
		notification_badge.position = Vector3(0.0, 1.65, 0.0)
		notification_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		notification_badge.font_size = 26
		notification_badge.outline_size = 4
		notification_badge.modulate = Color(1.0, 0.88, 0.20, 1.0)
		notification_badge.outline_modulate = Color(0.08, 0.10, 0.14, 0.95)
		notification_badge.text = "🔔"
		notification_badge.visible = false

func _setup_audio_player() -> void:
	audio_player = get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioStreamPlayer3D"
		audio_player.unit_size = 6.0
		audio_player.max_distance = 35.0
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		audio_player.bus = "Master"
		add_child(audio_player)

func _connect_order_manager() -> void:
	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)
	if om:
		if not om.order_created.is_connected(_on_order_created):
			om.order_created.connect(_on_order_created)

func _process(_delta: float) -> void:
	# Garante conexão caso o OrderManager tenha sido instanciado depois
	var om = OrderManager.get_instance()
	if om and not om.order_created.is_connected(_on_order_created):
		om.order_created.connect(_on_order_created)

func _on_order_created(order: Order) -> void:
	if not order or notified_order_ids.has(order.id):
		return

	notified_order_ids[order.id] = true
	unviewed_orders_count += 1
	_update_notification_badge()
	_play_notification_sound()

func _play_notification_sound() -> void:
	if not audio_player:
		_setup_audio_player()
	if audio_player:
		var stream = SoundSynthesizer.get_stream("pc_notification")
		if stream:
			audio_player.stream = stream
			audio_player.volume_db = -6.0
			audio_player.pitch_scale = 1.0
			if is_inside_tree() and audio_player.is_inside_tree():
				audio_player.play()

func _update_notification_badge() -> void:
	if not notification_badge:
		_setup_3d_notification_badge()
	if notification_badge:
		if unviewed_orders_count > 0:
			notification_badge.text = "🔔"
			notification_badge.visible = true
			_animate_notification_badge()
		else:
			notification_badge.visible = false

func _animate_notification_badge() -> void:
	if not notification_badge or not is_inside_tree():
		return
	var tw = create_tween()
	if tw:
		notification_badge.scale = Vector3(1.35, 1.35, 1.35)
		tw.tween_property(notification_badge, "scale", Vector3(1.0, 1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_orders_viewed_in_ui() -> void:
	unviewed_orders_count = 0
	_update_notification_badge()

func get_interaction_prompt(player: Node = null) -> String:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	if has_power:
		if unviewed_orders_count > 0:
			return "💻 [E] Acessar Computador (🔔 %d Novo(s) Pedido(s)!)" % unviewed_orders_count
		return "💻 [E] Acessar Computador / Pedidos de Insumos"
	else:
		return "Computador sem energia (Ligue o Quadro Geral)"

func interact(player: Node3D) -> void:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	if not has_power:
		if player and player.has_node("HUD"):
			var hud = player.get_node("HUD")
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("⚠️ Computador desligado! Ligue a chave geral no quadro de energia.")
		return

	if computer_ui_instance:
		computer_ui_instance.open()
		# Ao abrir o PC, se houver novos pedidos, avisa a interface
		if unviewed_orders_count > 0:
			computer_ui_instance.notify_new_orders_arrived()
