extends SceneTree

# Track test results
var total_files = 0
var total_tests = 0
var passed_assertions = 0
var failed_assertions = 0
var current_test_failed = false

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("====================================================")
	print("   INICIANDO SUÍTE DE TESTES E2E HEADLESS GODOT     ")
	print("====================================================")
	
	# 1. Back up save game
	backup_save()
	
	# 2. Find test files
	var test_files = get_test_files("res://tests/e2e")
	print("Encontrados %d arquivos de teste." % test_files.size())
	
	# 3. Run each test file
	for file_path in test_files:
		print("\n--- Executando arquivo de teste: %s ---" % file_path)
		total_files += 1
		
		# Load test script and discover methods first using a dummy instance
		var test_script = load(file_path)
		var discovery_instance = test_script.new()
		var method_list = discovery_instance.get_method_list()
		var test_methods: Array[String] = []
		for method_info in method_list:
			var method_name = method_info["name"]
			if method_name.begins_with("test_"):
				test_methods.append(method_name)
		discovery_instance.queue_free()
		
		# Run each test case in complete isolation
		for method_name in test_methods:
			current_test_failed = false
			total_tests += 1
			print("  Executando: %s" % method_name)
			
			# A. Clear the save file before EACH test case
			if FileAccess.file_exists(SAVE_PATH):
				DirAccess.remove_absolute(SAVE_PATH)
				
			# B. Instantiate a fresh Game.tscn
			var game = load("res://scenes/main/Game.tscn").instantiate()
			root.add_child(game)
			
			# C. Instantiate fresh test script instance
			var test_instance = test_script.new()
			test_instance.name = "ActiveTestInstance"
			test_instance.game = game
			test_instance.runner = self
			root.add_child(test_instance)
			
			# D. Call method and handle async/await
			var callable = Callable(test_instance, method_name)
			await callable.call()
			
			if current_test_failed:
				print("  [FAIL] %s" % method_name)
			else:
				print("  [PASS] %s" % method_name)
				
			# E. Clean up both instances
			test_instance.queue_free()
			game.queue_free()
			# Wait a frame to ensure cleanup happens
			await process_frame
	
	# 4. Restore save game
	restore_save()
	
	# 5. Output results and quit
	print("\n====================================================")
	print("   RESULTADOS DOS TESTES E2E:")
	print("   Arquivos executados: %d" % total_files)
	print("   Casos de teste executados: %d" % total_tests)
	print("   Asserções válidas: %d" % passed_assertions)
	print("   Asserções falhas: %d" % failed_assertions)
	print("====================================================")
	
	if failed_assertions > 0:
		print("SUÍTE DE TESTES E2E: REJEITADA (Exit Code 1)")
		quit(1)
	else:
		print("SUÍTE DE TESTES E2E: SUCESSO (Exit Code 0)")
		quit(0)

func register_assertion(passed: bool, msg: String) -> void:
	if passed:
		passed_assertions += 1
	else:
		failed_assertions += 1
		current_test_failed = true
		print("    [ASSERT FAIL] %s" % msg)

func get_test_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					files.append_array(get_test_files(dir_path.path_join(file_name)))
			else:
				if file_name.begins_with("test_") and file_name.ends_with(".gd"):
					files.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return files

const SAVE_PATH = "user://savegame.save"
const BACKUP_PATH = "user://savegame.save.backup"

func backup_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists(SAVE_PATH):
			print("Efetuando backup do save existente...")
			if dir.copy(SAVE_PATH, BACKUP_PATH) == OK:
				print("Backup criado com sucesso.")
			else:
				print("Falha ao criar backup do save.")
			dir.remove(SAVE_PATH)
		else:
			print("Nenhum save existente para backup.")

func restore_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists(SAVE_PATH):
			dir.remove(SAVE_PATH)
			
		if dir.file_exists(BACKUP_PATH):
			print("Restaurando backup do save...")
			if dir.copy(BACKUP_PATH, SAVE_PATH) == OK:
				print("Save restaurado.")
				dir.remove(BACKUP_PATH)
			else:
				print("Falha ao restaurar save.")
