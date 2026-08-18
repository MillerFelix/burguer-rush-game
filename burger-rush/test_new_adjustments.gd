extends SceneTree

const SodaRackScene = preload("res://src/stations/soda_refill_rack.tscn")
const PackagingScene = preload("res://src/stations/packaging_station.tscn")
const PattyScene = preload("res://src/items/patty.tscn")
const BreadBottomScene = preload("res://src/items/bread_bottom.tscn")
const CheeseScene = preload("res://src/items/cheese.tscn")
const LettuceScene = preload("res://src/items/lettuce.tscn")
const TomatoScene = preload("res://src/items/tomato.tscn")
const BreadTopScene = preload("res://src/items/bread_top.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: PLACAS DO ARMAZÉM, HAMBÚRGUER (COCÇÃO E FLIP) & EMPILHAMENTO")
	print("===========================================================================")

	var passed = 0
	var total = 4

	# -------------------------------------------------------------
	# TESTE 1: Placa Física REFIL REFRIGERANTES
	# -------------------------------------------------------------
	var soda_rack = SodaRackScene.instantiate()
	var refill_sign = soda_rack.get_node_or_null("Model/PhysicalSign")
	var refill_label = soda_rack.get_node_or_null("Model/PhysicalSign/SignLabel") as Label3D
	var refill_text_ok = refill_label != null and "REFIL REFRIGERANTES" in refill_label.text.to_upper()
	var refill_pos_ok = refill_sign != null and refill_sign.position.y < 0.15 # Rente ao chão na base

	if refill_sign and refill_text_ok and refill_pos_ok:
		print("  ✅ TESTE 1: Placa física 'REFIL REFRIGERANTES' instalada rente ao chão na base metálica (Y: %.2f)." % refill_sign.position.y)
		passed += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Placa de refil de refrigerante não encontrada ou posição incorreta.")
	soda_rack.queue_free()

	# -------------------------------------------------------------
	# TESTE 2: Placa Física EMBALAGENS
	# -------------------------------------------------------------
	var pack_station = PackagingScene.instantiate()
	var pack_sign = pack_station.get_node_or_null("Model/PhysicalSign")
	var pack_label = pack_station.get_node_or_null("Model/PhysicalSign/SignLabel") as Label3D
	var pack_text_ok = pack_label != null and "EMBALAGENS" in pack_label.text.to_upper()

	if pack_sign and pack_text_ok:
		print("  ✅ TESTE 2: Placa física 'EMBALAGENS' instalada no suporte metálico do armazém.")
		passed += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Placa física de embalagens não encontrada.")
	pack_station.queue_free()

	# -------------------------------------------------------------
	# TESTE 3: Hambúrguer — Cozimento dos 2 lados, Flip e Estados Visuais
	# -------------------------------------------------------------
	var patty = PattyScene.instantiate() as Patty
	patty._ready()

	# Estado inicial: cru
	var t3_raw_ok = (patty.state == Patty.State.RAW and patty.side_a_cooked == 0.0 and patty.side_b_cooked == 0.0)

	# Cozinha lado A
	patty.advance_cooking(100.0)
	var t3_side1_ok = (patty.state == Patty.State.READY_SIDE_1 and patty.side_a_cooked == 100.0 and patty.side_b_cooked == 0.0)

	# Vira com a espátula
	patty.flip()
	var t3_flip_ok = (patty.is_flipped and patty.current_side_cooking == 2)

	# Cozinha lado B
	patty.advance_cooking(100.0)
	var t3_cooked_ok = (patty.state == Patty.State.COOKED and patty.is_fully_cooked())

	# Continua cozinhando sem queimar imediatamente -> deve permanecer COOKED e marrom
	patty.advance_cooking(50.0)
	var t3_stay_cooked_ok = (patty.state == Patty.State.COOKED)

	# Queima apenas quando set_burnt é chamado
	patty.set_burnt()
	var t3_burnt_ok = (patty.state == Patty.State.BURNT)

	if t3_raw_ok and t3_side1_ok and t3_flip_ok and t3_cooked_ok and t3_stay_cooked_ok and t3_burnt_ok:
		print("  ✅ TESTE 3: Hambúrguer com cocção realista dos 2 lados, flip coerente e persistência do estado pronto.")
		passed += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Falha na lógica ou estados do hambúrguer (Raw: %s, Side1: %s, Flip: %s, Cooked: %s, StayCooked: %s, Burnt: %s)" % [
			str(t3_raw_ok), str(t3_side1_ok), str(t3_flip_ok), str(t3_cooked_ok), str(t3_stay_cooked_ok), str(t3_burnt_ok)
		])
	patty.queue_free()

	# -------------------------------------------------------------
	# TESTE 4: Empilhamento dos Ingredientes (Contato Físico e Centralização)
	# -------------------------------------------------------------
	var base_bun = BreadBottomScene.instantiate()
	var assembly = base_bun.get_node_or_null("BurgerAssembly") as BurgerAssembly
	if not assembly:
		assembly = BurgerAssembly.new()
		base_bun.add_child(assembly)
		assembly.base_bun = base_bun

	var ing_patty = PattyScene.instantiate() as Patty
	ing_patty.state = Patty.State.COOKED
	assembly.add_ingredient(ing_patty, Vector3(0.04, 0, 0.04))

	var ing_cheese = CheeseScene.instantiate()
	assembly.add_ingredient(ing_cheese, Vector3(-0.05, 0, 0.02))

	var ing_lettuce = LettuceScene.instantiate()
	assembly.add_ingredient(ing_lettuce, Vector3(0.01, 0, -0.01))

	var ing_tomato = TomatoScene.instantiate()
	assembly.add_ingredient(ing_tomato, Vector3(0.0, 0, 0.0))

	var ing_bun_top = BreadTopScene.instantiate()
	assembly.close_burger(ing_bun_top, Vector3(0.02, 0, 0.01))

	# Verificações de contato e altura:
	# Base: ~0.040
	# Patty: pos Y = 0.040
	# Cheese: pos Y = 0.040 + 0.032 = 0.072 (perfeitamente centralizado X=0, Z=0)
	# Lettuce: pos Y = 0.072 + 0.007 = 0.079
	# Tomato: pos Y = 0.079 + 0.013 = 0.092
	# BunTop: pos Y = 0.092 + 0.013 = 0.105
	var patty_pos_ok = absf(ing_patty.position.y - 0.040) < 0.005
	var cheese_pos_ok = absf(ing_cheese.position.y - 0.072) < 0.005
	var cheese_center_ok = absf(ing_cheese.position.x) < 0.001 and absf(ing_cheese.position.z) < 0.001
	var top_pos_ok = ing_bun_top.position.y > ing_tomato.position.y and ing_bun_top.position.y > 0.100

	if patty_pos_ok and cheese_pos_ok and cheese_center_ok and top_pos_ok:
		print("  ✅ TESTE 4: Empilhamento físico contíguo e centralizado (Patty Y: %.3f, Cheese Y: %.3f [Centrado], Top Y: %.3f)." % [
			ing_patty.position.y, ing_cheese.position.y, ing_bun_top.position.y
		])
		passed += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Altura ou centralização incorreta (Patty: %s, Cheese: %s, CheeseCenter: %s, Top: %s)" % [
			str(patty_pos_ok), str(cheese_pos_ok), str(cheese_center_ok), str(top_pos_ok)
		])
	base_bun.queue_free()

	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed, total, (float(passed)/float(total)) * 100.0])
	print("===========================================================================")
	if passed == total:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
