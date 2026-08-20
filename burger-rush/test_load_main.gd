extends SceneTree

func _init():
	print("--- TESTANDO CARREGAMENTO DA CENA MAIN ---")
	var s = load("res://src/main.tscn")
	print("Loaded main.tscn: ", s)
	assert(s != null, "Cena main.tscn carregada")
	var inst = s.instantiate()
	print("Instantiated main: ", inst.name)
	assert(inst != null, "Instanciação com sucesso")
	print(">>> MAIN.TSCN CARREGADA COM 100% DE SUCESSO! <<<")
	quit(0)
