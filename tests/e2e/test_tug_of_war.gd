extends "res://tests/e2e/BaseE2ETest.gd"

# Tier 1: Feature Coverage (5 tests)

func test_01_tow_initial_balance() -> void:
	# Clean init
	game.global_score_red = 50.0
	game.global_score_blue = 50.0
	game._update_tug_of_war()
	assert_eq(game.tug_of_war_bar.value, 50.0, "Tug-of-war bar shows 50% initially")

func test_02_tow_simulate_enemy_increases_blue() -> void:
	game.global_score_blue = 50.0
	game.economy_manager.discursos_por_segundo = 0.0
	# enemy power = 0.5 + 0.0 = 0.5
	game._simulate_enemy_faction()
	assert_eq(game.global_score_blue, 50.5, "Simulate enemy increases blue score")

func test_03_tow_update_tug_of_war_bar_value() -> void:
	game.global_score_red = 75.0
	game.global_score_blue = 25.0
	# red percent is 75 / 100 * 100 = 75%
	game._update_tug_of_war()
	assert_eq(game.tug_of_war_bar.value, 75.0, "Tug-of-war bar value updates correctly")

func test_04_tow_win_triggers_end_game() -> void:
	game.game_active = true
	game.global_score_red = 999.0
	game.global_score_blue = 1.0 # 999/1000 = 99.9%
	game._update_tug_of_war()
	assert_true(not game.game_active, "Win condition disables game loop")

func test_05_tow_loss_triggers_end_game() -> void:
	game.game_active = true
	game.global_score_red = 1.0
	game.global_score_blue = 999.0 # 1/1000 = 0.1%
	game._update_tug_of_war()
	assert_true(not game.game_active, "Loss condition disables game loop")

# Tier 2: Boundary & Corner Cases (5 tests)

func test_06_tow_restart_resets_scores() -> void:
	game.game_active = false
	game.global_score_red = 100.0
	game.global_score_blue = 0.0
	game._on_btn_restart_pressed()
	
	assert_true(game.game_active, "Restarting makes game active again")
	assert_eq(game.global_score_red, 50.0, "Restart resets red score to 50")
	assert_eq(game.global_score_blue, 50.0, "Restart resets blue score to 50")

func test_07_tow_exact_win_boundary() -> void:
	game.game_active = true
	game.global_score_red = 99.9
	game.global_score_blue = 0.1
	game._update_tug_of_war()
	assert_true(not game.game_active, "Exactly 99.9% red percent triggers win")

func test_08_tow_exact_loss_boundary() -> void:
	game.game_active = true
	game.global_score_red = 0.1
	game.global_score_blue = 99.9
	game._update_tug_of_war()
	assert_true(not game.game_active, "Exactly 0.1% red percent triggers loss")

func test_09_tow_division_by_zero_prevention() -> void:
	game.global_score_red = 0.0
	game.global_score_blue = 0.0
	game._update_tug_of_war()
	# Verify that no crash occurs and value stays at whatever it was (or doesn't throw)
	assert_true(game.tug_of_war_bar != null, "No division by zero crash occurred")

func test_10_tow_ui_panel_displays() -> void:
	# test win panel text
	game.game_active = true
	game._end_game(true)
	assert_true(game.end_game_panel.visible, "End game panel is visible on end game")
	assert_true(game.label_result.text.contains("VITÓRIA"), "Result label shows victory message")
	
	# test lose panel text
	game.game_active = true
	game._end_game(false)
	assert_true(game.label_result.text.contains("DERROTA"), "Result label shows defeat message")
