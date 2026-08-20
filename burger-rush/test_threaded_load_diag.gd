extends SceneTree

func _init() -> void:
	print("--- TESTING FULL THREADED LOAD OF res://src/main.tscn ---")
	var target = "res://src/main.tscn"
	print("Exists: ", ResourceLoader.exists(target))
	var err = ResourceLoader.load_threaded_request(target, "PackedScene")
	print("Request error: ", err)
	
	var frame = 0
	var status = ResourceLoader.load_threaded_get_status(target)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		frame += 1
		var progress: Array = []
		status = ResourceLoader.load_threaded_get_status(target, progress)
		if frame % 20 == 0 or status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print("Frame %d: status=%d progress=%s" % [frame, status, str(progress)])
		if frame > 2000:
			print("TIMEOUT AFTER 2000 FRAMES!")
			break
		await process_frame
		
	print("FINAL STATUS: ", status)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res = ResourceLoader.load_threaded_get(target)
		print("SUCCESSFULLY LOADED RESOURCE: ", res)
		var inst = res.instantiate()
		print("SUCCESSFULLY INSTANTIATED MAIN SCENE: ", inst)
	else:
		print("FAILED STATUS: ", status)
		
	quit(0 if status == ResourceLoader.THREAD_LOAD_LOADED else 1)
