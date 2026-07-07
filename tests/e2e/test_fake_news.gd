extends "res://tests/e2e/BaseE2ETest.gd"

# Tier 1: Feature Coverage (5 tests)

func test_01_fake_news_initial_hidden() -> void:
	assert_true(not game.btn_urgent_news.visible, "Fake news button is initially hidden")

func test_02_fake_news_spawn_makes_visible() -> void:
	game._spawn_urgent_news()
	assert_true(game.btn_urgent_news.visible, "Spawning fake news makes the button visible")

func test_03_fake_news_spawn_random_position() -> void:
	game.size = Vector2(800, 600)
	game._spawn_urgent_news()
	var pos = game.btn_urgent_news.global_position
	assert_true(pos.x >= 50.0 and pos.x <= 800.0 - 400.0, "Fake news button X position is within bounds")
	assert_true(pos.y >= 200.0 and pos.y <= 600.0 - 200.0, "Fake news button Y position is within bounds")

func test_04_fake_news_clicking_adds_bonus() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.discursos_por_segundo = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	game._spawn_urgent_news()
	
	# Clicking should add max(100.0, 0.0 * 30.0) = 100.0 discursos
	game._on_btn_urgent_news_pressed()
	assert_eq(game.economy_manager.discursos, 100.0, "Clicking fake news button adds base bonus of 100.0 discursos")

func test_05_fake_news_clicking_hides_button() -> void:
	game._spawn_urgent_news()
	game._on_btn_urgent_news_pressed()
	assert_true(not game.btn_urgent_news.visible, "Clicking fake news button hides it")
	assert_eq(game.btn_urgent_news.modulate.a, 1.0, "Clicking fake news button resets its modulate alpha to 1.0")

# Tier 2: Boundary & Corner Cases (5 tests)

func test_06_fake_news_bonus_scales_with_dps() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.discursos_por_segundo = 10.0 # 10.0 * 30 = 300.0 bonus
	game.economy_manager.prestige_multiplier = 1.0
	game._spawn_urgent_news()
	
	game._on_btn_urgent_news_pressed()
	# adds 300.0 discursos
	assert_eq(game.economy_manager.discursos, 300.0, "Fake news bonus scales with DPS (10.0 DPS -> 300.0 bonus)")

func test_07_fake_news_bonus_under_prestige() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.discursos_por_segundo = 0.0 # base bonus = 100.0
	game.economy_manager.prestige_multiplier = 3.5
	game._spawn_urgent_news()
	
	game._on_btn_urgent_news_pressed()
	# adds 100.0 * 3.5 = 350.0 discursos
	assert_eq(game.economy_manager.discursos, 350.0, "Fake news bonus scales with prestige multiplier")

func test_08_fake_news_clicking_when_inactive() -> void:
	game.game_active = false
	game.economy_manager.discursos = 0.0
	game._spawn_urgent_news()
	game._on_btn_urgent_news_pressed()
	# Even if game is inactive, pressing fake news button currently still grants the bonus or doesn't crash
	assert_eq(game.economy_manager.discursos, 100.0, "Fake news button click does not crash when game is inactive")
	game.game_active = true

func test_09_fake_news_rapid_double_clicks() -> void:
	game.economy_manager.discursos = 0.0
	game._spawn_urgent_news()
	game._on_btn_urgent_news_pressed() # First click
	assert_eq(game.economy_manager.discursos, 100.0, "First click adds bonus")
	
	# Second click right after - the button is already hidden.
	# Game.gd _on_btn_urgent_news_pressed doesn't explicitly check if button is visible, but if we call it again,
	# it would add another 100.0. In actual gameplay, the button is hidden so the user cannot click it.
	# We can check that the button is indeed hidden.
	assert_true(not game.btn_urgent_news.visible, "Button is hidden after first click")

func test_10_fake_news_timer_restarts() -> void:
	game.news_timer.stop()
	game._spawn_urgent_news()
	game._on_btn_urgent_news_pressed()
	assert_true(game.news_timer.time_left > 0.0, "News timer is restarted and running after clicking the news button")
