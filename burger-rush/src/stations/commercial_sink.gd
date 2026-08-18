class_name CommercialSink
extends StaticBody3D

# ================================================================
# PIA INDUSTRIAL DE HIGIENIZAÇÃO E LAVAGEM DE UTENSÍLIOS
#
# Funcionalidades:
#  - Lavar a bucha suja com água corrente e som realista
#  - Higienizar as mãos do cozinheiro
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const WaterManager = preload("res://src/core/water_manager.gd")

@onready var water_stream_mesh: MeshInstance3D = get_node_or_null("Model/Faucet/WaterStream")
@onready var water_pool_left: MeshInstance3D = get_node_or_null("Model/BasinLeftWaterPool")
@onready var water_audio: AudioStreamPlayer3D = get_node_or_null("WaterAudioPlayer")

var is_water_running: bool = false
var _wash_timer: float = 0.0

func _ready() -> void:
	if not water_audio:
		water_audio = get_node_or_null("WaterAudioPlayer")
	set_water_flow(false)

func _process(delta: float) -> void:
	if _wash_timer > 0.0:
		_wash_timer -= delta
		if _wash_timer <= 0.0:
			set_water_flow(false)

func set_water_flow(active: bool) -> void:
	is_water_running = active
	if water_stream_mesh:
		water_stream_mesh.visible = active
	if water_pool_left:
		water_pool_left.visible = active

	if water_audio:
		if active:
			if not water_audio.playing:
				water_audio.stream = SoundSynthesizer.get_stream("sink_running_water")
				water_audio.play()
		else:
			if water_audio.playing:
				water_audio.stop()

const DailyEventManager = preload("res://src/core/daily_event_manager.gd")

func get_interaction_prompt(player: Node = null) -> String:
	var dem = DailyEventManager.get_instance()
	if dem and not dem.is_water_available():
		return "⚠️ Torneira sem água (Abastecimento interrompido na região)"

	if not player:
		return "E — Usar Pia"

	var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder")
	var sponge = null
	if tool_holder:
		sponge = tool_holder.get_node_or_null("Sponge")

	if sponge and sponge.is_dirty:
		return "🖱️ [Segurar] ou [E] — Lavar Bucha na Pia"
	elif sponge and not sponge.is_dirty:
		return "Bucha já está limpa e higienizada"
	else:
		return "E — Higienizar as Mãos na Pia"

func interact(player: Node3D) -> void:
	wash_or_sanitize(player)

func interact_item(player: Node3D) -> void:
	wash_or_sanitize(player)

func wash_or_sanitize(player: Node3D) -> void:
	var dem = DailyEventManager.get_instance()
	if dem and not dem.is_water_available():
		set_water_flow(false)
		_show_feedback(player, "⚠️ Sem fornecimento de água! Abastecimento temporariamente interrompido.")
		return

	var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder")
	var sponge = null
	if tool_holder:
		sponge = tool_holder.get_node_or_null("Sponge")

	set_water_flow(true)
	_wash_timer = 1.2

	var wm = WaterManager.get_instance()
	if wm:
		wm.consume_water(0.50, "sink")

	if sponge:
		if sponge.has_method("play_wash_animation"):
			sponge.play_wash_animation()
		sponge.set_clean()
		_show_feedback(player, "💧 Bucha lavada e higienizada com sucesso! (Pronta para uso)")
	else:
		_show_feedback(player, "✨ Mãos higienizadas com água corrente! (Higiene 100%)")

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
