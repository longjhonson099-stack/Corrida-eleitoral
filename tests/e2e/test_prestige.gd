extends "res://tests/e2e/BaseE2ETest.gd"

# Tier 1: Feature Coverage (5 tests)

func test_01_prestige_resets_discursos() -> void:
	game.economy_manager.discursos = 1000.0
	game.economy_manager.reset_for_prestige()
	assert_eq(game.economy_manager.discursos, 0.0, "Prestige resets discursos count to 0")

func test_02_prestige_resets_upgrades_counts() -> void:
	game.economy_manager.upgrades[0].count = 5
	game.economy_manager.upgrades[1].count = 3
	game.economy_manager.reset_for_prestige()
	assert_eq(game.economy_manager.upgrades[0].count, 0, "Prestige resets upgrade 0 count to 0")
	assert_eq(game.economy_manager.upgrades[1].count, 0, "Prestige resets upgrade 1 count to 0")

func test_03_prestige_increases_multiplier() -> void:
	game.economy_manager.prestige_multiplier = 1.0
	game.economy_manager.reset_for_prestige()
	assert_eq(game.economy_manager.prestige_multiplier, 1.5, "Prestige increases multiplier by 0.5")

func test_04_prestige_emits_signals() -> void:
	var signal_received = false
	var received_mult = 0.0
	game.economy_manager.prestige_changed.connect(func(mult):
		signal_received = true
		received_mult = mult
	)
	game.economy_manager.reset_for_prestige()
	assert_true(signal_received, "Prestige emits prestige_changed signal")
	assert_eq(received_mult, game.economy_manager.prestige_multiplier, "Signal passes correct new multiplier")

func test_05_prestige_saves_state() -> void:
	game.economy_manager.prestige_multiplier = 2.0
	game.economy_manager.reset_for_prestige() # increases to 2.5
	var saved_data = AppSaveManager.load_game()
	assert_eq(float(saved_data.get("prestige_multiplier", 0.0)), 2.5, "Prestige saves new multiplier to disk")

# Tier 2: Boundary & Corner Cases (5 tests)

func test_06_prestige_with_high_multiplier() -> void:
	game.economy_manager.prestige_multiplier = 50.0
	game.economy_manager.reset_for_prestige()
	assert_eq(game.economy_manager.prestige_multiplier, 50.5, "Prestige increments high multiplier correctly")

func test_07_prestige_recalculates_dps_correctly() -> void:
	game.economy_manager.upgrades[0].count = 10
	game.economy_manager.reset_for_prestige()
	assert_eq(game.economy_manager.discursos_por_segundo, 0.0, "Prestige resets discursos por segundo to 0.0")

func test_08_prestige_ui_label_updates() -> void:
	game.economy_manager.prestige_multiplier = 1.0
	# Calling reset will emit prestige_changed which updates the label
	game.economy_manager.reset_for_prestige()
	var expected_text = "Multiplicador de Fanatismo: 1.5x"
	assert_eq(game.label_prestige.text, expected_text, "Prestige updates the UI label text")

func test_09_prestige_preserves_score_in_economy() -> void:
	game.global_score_red = 60.0
	game.economy_manager.reset_for_prestige()
	assert_eq(game.global_score_red, 60.0, "Direct economy prestige does not reset game scores")

func test_10_multiple_consecutive_runs() -> void:
	game.economy_manager.prestige_multiplier = 1.0
	game.economy_manager.reset_for_prestige() # 1.5
	game.economy_manager.reset_for_prestige() # 2.0
	game.economy_manager.reset_for_prestige() # 2.5
	game.economy_manager.reset_for_prestige() # 3.0
	assert_eq(game.economy_manager.prestige_multiplier, 3.0, "Multiple prestige resets increment multiplier linearly")
