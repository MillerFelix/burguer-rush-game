extends SceneTree

# =============================================================================
# TESTE AUTOMATIZADO: JORNAL DO PC, INTEGRAÇÃO COM CALENDÁRIO E PLACAS FÍSICAS
# =============================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: JORNAL DO PC, INTEGRAÇÃO COM CALENDÁRIO E NOVAS PLACAS FÍSICAS")
	print("===========================================================================")

	var total = 4
	var passed = 0

	# -------------------------------------------------------------
	# TESTE 1: Placa Física de BANDEJAS
	# -------------------------------------------------------------
	var tray_res = load("res://src/stations/serving_tray_stack.tscn")
	var tray_stack = tray_res.instantiate() as StaticBody3D
	get_root().add_child(tray_stack)

	var tray_sign = tray_stack.get_node_or_null("Model/PhysicalSign") as Node3D
	var tray_border = tray_stack.get_node_or_null("Model/PhysicalSign/PlateBorder") as MeshInstance3D
	var tray_body = tray_stack.get_node_or_null("Model/PhysicalSign/PlateBody") as MeshInstance3D
	var tray_label = tray_stack.get_node_or_null("Model/PhysicalSign/SignLabel") as Label3D

	var tray_sign_ok = (
		tray_sign != null and
		tray_border != null and
		tray_body != null and
		tray_label != null and
		tray_label.text == "BANDEJAS" and
		tray_sign.transform.origin.y < 0.0 # Posicionada na face frontal do balcão
	)

	if tray_sign_ok:
		print("  ✅ TESTE 1: Placa física 'BANDEJAS' integrada ao balcão com borda, fundo próprio e texto centralizado.")
		passed += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Placa física de Bandejas ausente ou mal configurada.")
	tray_stack.queue_free()

	# -------------------------------------------------------------
	# TESTE 2: Placa Física de REFIL REFRIGERANTES (Na parede acima dos cilindros)
	# -------------------------------------------------------------
	var soda_res = load("res://src/stations/soda_refill_rack.tscn")
	var soda_rack = soda_res.instantiate() as StaticBody3D
	get_root().add_child(soda_rack)

	var soda_sign = soda_rack.get_node_or_null("Model/PhysicalSign") as Node3D
	var soda_border = soda_rack.get_node_or_null("Model/PhysicalSign/PlateBorder") as MeshInstance3D
	var soda_body = soda_rack.get_node_or_null("Model/PhysicalSign/PlateBody") as MeshInstance3D
	var soda_label = soda_rack.get_node_or_null("Model/PhysicalSign/SignLabel") as Label3D

	var soda_pos_ok = soda_sign != null and soda_sign.transform.origin.y >= 1.80 and soda_sign.transform.origin.z <= -0.25
	var soda_sign_ok = (
		soda_sign != null and
		soda_border != null and
		soda_body != null and
		soda_label != null and
		soda_label.text == "REFIL REFRIGERANTES" and
		soda_pos_ok
	)

	if soda_sign_ok:
		print("  ✅ TESTE 2: Placa 'REFIL REFRIGERANTES' fixada na parede (Y=%.2fm, Z=%.2fm) acima dos cilindros." % [
			soda_sign.transform.origin.y, soda_sign.transform.origin.z
		])
		passed += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Placa de Refil de Refrigerantes ausente ou não posicionada na parede.")
	soda_rack.queue_free()

	# -------------------------------------------------------------
	# TESTE 3: Jornal do PC — Conteúdo Rico (Com e Sem Eventos)
	# -------------------------------------------------------------
	var nm = NewsManager.new()
	var dem = DailyEventManager.new()
	var cal = CalendarManager.new()
	get_root().add_child(cal)
	get_root().add_child(dem)
	get_root().add_child(nm)
	cal._ready()
	dem._ready()
	nm._ready()

	# Caso A: Dia sem eventos -> Gera boletim diário regular + notícias secundárias da cidade
	dem.current_event = DailyEventManager.EventType.NONE
	var normal_news = nm.generate_daily_news(1)
	var normal_has_content = normal_news.size() >= 2
	var normal_main = normal_news[0] if normal_news.size() > 0 else {}
	var normal_title_ok = "Boletim da Cidade" in normal_main.get("title", "")
	var normal_impact_ok = normal_main.get("impacts", []).size() > 0

	# Caso B: Dia com evento -> Gera matéria jornalística com impacto no restaurante
	dem.current_event = DailyEventManager.EventType.TRANSPORT_DISRUPTION
	var event_news = nm.generate_daily_news(2)
	var event_main = event_news[0] if event_news.size() > 0 else {}
	var event_story_ok = "transportadoras" in event_main.get("title", "").to_lower() or "tráfego" in event_main.get("title", "").to_lower() or "paralisação" in event_main.get("title", "").to_lower()
	var event_impact_ok = event_main.get("impacts", []).size() > 0

	if normal_has_content and normal_title_ok and normal_impact_ok and event_story_ok and event_impact_ok:
		print("  ✅ TESTE 3: Jornal sempre apresenta conteúdo completo (Boletim sem eventos: '%s', Matéria com evento: '%s')." % [
			normal_main.get("title", ""), event_main.get("title", "")
		])
		passed += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Geração de notícias com ou sem eventos falhou.")

	# -------------------------------------------------------------
	# TESTE 4: Integração com o Calendário e Renderização da UI
	# -------------------------------------------------------------
	var comp_ui_res = load("res://src/ui/computer_ui.tscn")
	var comp_ui = comp_ui_res.instantiate() as ComputerUI
	get_root().add_child(comp_ui)
	comp_ui._ready()
	comp_ui.open()

	# Alterna para a aba Notícias
	comp_ui._switch_tab(ComputerUI.TabID.NEWS, "Notícias / Jornal")
	var news_count = comp_ui.news_content_vbox.get_child_count() if comp_ui.news_content_vbox else 0

	# Alterna para a aba Calendário e seleciona sub-aba de Notícias
	comp_ui._switch_tab(ComputerUI.TabID.CALENDAR, "Calendário")
	comp_ui._set_calendar_subtab("NEWS")
	var cal_news_count = comp_ui.day_detail_content_vbox.get_child_count() if comp_ui.day_detail_content_vbox else 0

	if news_count > 0 and cal_news_count > 0:
		print("  ✅ TESTE 4: Telas de Notícias e Calendário perfeitamente integradas via NewsManager (Cards carregados: %d e %d)." % [
			news_count, cal_news_count
		])
		passed += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Erro ao renderizar notícias na aba Notícias (%d cards) ou Calendário (%d cards)." % [
			news_count, cal_news_count
		])

	comp_ui.queue_free()
	nm.queue_free()
	dem.queue_free()
	cal.queue_free()

	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed, total, (float(passed)/float(total)) * 100.0])
	print("===========================================================================")
	if passed == total:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
	quit()
