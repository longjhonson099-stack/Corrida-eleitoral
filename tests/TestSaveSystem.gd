extends MicroTestRunner
class_name TestSaveSystem

func run_tests() -> void:
	print("--- Testando SaveSystem ---")
	test_save_and_load_integrity()

func test_save_and_load_integrity() -> void:
	var mock_data = {
		"discursos": 999.5,
		"prestige_multiplier": 3.0,
		"upgrades_counts": [10, 5, 1, 0]
	}
	
	# Salva
	AppSaveManager.save_game(mock_data)
	
	# Carrega
	var loaded_data = AppSaveManager.load_game()
	
	assert_eq(float(loaded_data.get("discursos", 0)), 999.5, "Discursos salvos devem ser carregados corretamente")
	assert_eq(float(loaded_data.get("prestige_multiplier", 0)), 3.0, "Prestige deve ser carregado corretamente")
	
	var counts = loaded_data.get("upgrades_counts", [])
	assert_eq(counts.size(), 4, "Deve haver 4 upgrades salvos")
	if counts.size() == 4:
		assert_eq(int(counts[0]), 10, "Upgrade 0 deve ter count 10")
		assert_eq(int(counts[1]), 5, "Upgrade 1 deve ter count 5")
	
	# Limpeza para não afetar o jogo do dev, embora o save persista
	var empty = {}
	AppSaveManager.save_game(empty)
