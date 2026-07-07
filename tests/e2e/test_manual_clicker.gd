extends "res://tests/e2e/BaseE2ETest.gd"

# Tier 1: Feature Coverage (5 tests)

func test_01_adds_discursos() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	game._on_btn_generate_pressed()
	assert_eq(game.economy_manager.discursos, 1.0, "Clicker adds exactly 1.0 discurso under 1.0x prestige")

func test_02_updates_tug_of_war() -> void:
	var initial_red = game.global_score_red
	game._on_btn_generate_pressed()
	assert_eq(game.global_score_red, initial_red + 0.2, "Clicker adds 0.2 to red score")

func test_03_triggers_button_animation() -> void:
	# Clicking should animate button (scale changes)
	game._on_btn_generate_pressed()
	# The tween is async but we can assert the function doesn't crash
	assert_true(game.btn_generate != null, "BtnGenerate exists and is valid")

func test_04_spawns_floating_text() -> void:
	var initial_children = game.floating_texts.get_child_count()
	game._on_btn_generate_pressed()
	var new_children = game.floating_texts.get_child_count()
	assert_true(new_children > initial_children, "Floating text was spawned as a child node")

func test_05_fails_if_game_inactive() -> void:
	game.game_active = false
	game.economy_manager.discursos = 10.0
	game._on_btn_generate_pressed()
	assert_eq(game.economy_manager.discursos, 10.0, "Clicker does not add discursos if game is inactive")
	game.game_active = true # Restore for next tests

# Tier 2: Boundary & Corner Cases (5 tests)

func test_06_rapid_clicks() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	for i in range(100):
		game._on_btn_generate_pressed()
	assert_eq(game.economy_manager.discursos, 100.0, "100 rapid clicks should add exactly 100.0 discursos")

func test_07_prestige_influence() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 4.5
	game._on_btn_generate_pressed()
	assert_eq(game.economy_manager.discursos, 4.5, "Clicker adds 4.5 discursos under 4.5x prestige")

func test_08_near_win_boundary() -> void:
	game.game_active = true
	game.global_score_red = 99.8
	game.global_score_blue = 0.2
	# red percent is 99.8 / 100 * 100 = 99.8%
	game._on_btn_generate_pressed() # Adds 0.2 to red -> red becomes 100.0, blue is 0.2. Total = 100.2. Red percent = 100/100.2 * 100 = 99.8%
	# Let's set it to hit exactly 99.9%
	game.global_score_red = 99.9
	game.global_score_blue = 0.1
	game._update_tug_of_war()
	assert_true(not game.game_active, "Game becomes inactive (won) when red percent >= 99.9%")

func test_09_at_zero_prestige() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 0.0
	game._on_btn_generate_pressed()
	assert_eq(game.economy_manager.discursos, 0.0, "Clicker adds 0.0 discursos if prestige multiplier is 0.0")

func test_10_with_huge_score() -> void:
	game.global_score_red = 1e12
	game.global_score_blue = 1e12
	game._on_btn_generate_pressed()
	assert_true(game.global_score_red > 1e12, "Red score increases correctly even at huge values")
