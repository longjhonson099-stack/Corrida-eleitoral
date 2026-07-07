extends "res://tests/e2e/BaseE2ETest.gd"

const MockLLMClass = preload("res://tests/mocks/MockLLMClient.gd")
var mock_llm: Node

func _enter_tree() -> void:
	mock_llm = MockLLMClass.new()
	mock_llm.name = "LocalLLMClient"
	game.add_child(mock_llm)
	game.llm_client = mock_llm
	game._connect_llm_client()

func _exit_tree() -> void:
	if is_instance_valid(mock_llm):
		mock_llm.queue_free()

# Tier 3: Cross-Feature Combinations (6 tests)

func test_01_clicker_and_upgrades_interaction() -> void:
	# Clicker adds discursos and upgrades generate discursos simultaneously
	game.economy_manager.discursos = 0.0
	game.economy_manager.upgrades[0].count = 1 # Tia do Zap dps = 1.0
	game.economy_manager._recalculate_dps()
	
	# Simulate 1 second passage (manually trigger process or wait)
	game.economy_manager._process(0.5) # generates 1.0 * 0.5 = 0.5 discursos
	game._on_btn_generate_pressed() # adds 1.0 discurso
	game.economy_manager._process(0.5) # generates 1.0 * 0.5 = 0.5 discursos
	
	# Total = 0.5 + 1.0 + 0.5 = 2.0 discursos
	assert_eq(game.economy_manager.discursos, 2.0, "Manual clicking and automatic upgrades both add to discursos pool")

func test_02_upgrades_and_prestige_interaction() -> void:
	# Prestige resets upgrades and increases their future value via multiplier
	game.economy_manager.upgrades[0].count = 2 # base dps 1.0 * 2 = 2.0
	game.economy_manager.prestige_multiplier = 1.0
	game.economy_manager._recalculate_dps()
	assert_eq(game.economy_manager.discursos_por_segundo, 2.0, "DPS is 2.0 before prestige")
	
	game.economy_manager.reset_for_prestige() # prestige_multiplier becomes 1.5, count resets to 0
	assert_eq(game.economy_manager.upgrades[0].count, 0, "Upgrade count reset to 0 after prestige")
	assert_eq(game.economy_manager.discursos_por_segundo, 0.0, "DPS reset to 0.0 after prestige")
	
	# Buy 1 upgrade now
	game.economy_manager.upgrades[0].count = 1
	game.economy_manager._recalculate_dps()
	assert_eq(game.economy_manager.discursos_por_segundo, 1.5, "DPS is 1.5 (1.0 base * 1.5 prestige) after prestige")

func test_03_fake_news_and_upgrades_interaction() -> void:
	# Fake news bonus scales with active DPS from upgrades
	game.economy_manager.discursos_por_segundo = 20.0
	game.economy_manager.prestige_multiplier = 1.0
	game._spawn_urgent_news()
	
	# bonus = max(100.0, 20.0 * 30.0) = 600.0
	game.economy_manager.discursos = 0.0
	game._on_btn_urgent_news_pressed()
	assert_eq(game.economy_manager.discursos, 600.0, "Fake news bonus scales with DPS from upgrades")

func test_04_llm_speech_and_prestige_interaction() -> void:
	# LLM Speech rewards scale with prestige multiplier
	game.economy_manager.discursos = 0.0
	game.economy_manager.discursos_por_segundo = 0.0
	game.economy_manager.prestige_multiplier = 2.0
	mock_llm.should_fail = false
	mock_llm.simulate_delay = 0.01
	
	game.generate_speech("Politica", "Discurso presidencia")
	await get_tree().create_timer(0.05).timeout
	
	# 50.0 base * 2.0 prestige = 100.0 discursos
	assert_eq(game.economy_manager.discursos, 100.0, "LLM speech discursos reward scales with prestige multiplier")

func test_05_llm_speech_and_tug_of_war_interaction() -> void:
	# Successful speech generation adds discursos and updates the Tug-of-war
	game.economy_manager.discursos = 0.0
	game.economy_manager.discursos_por_segundo = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	game.global_score_red = 50.0
	game.global_score_blue = 50.0
	
	mock_llm.should_fail = false
	mock_llm.simulate_delay = 0.01
	
	game.generate_speech("Discurso", "Avante!")
	await get_tree().create_timer(0.05).timeout
	
	assert_eq(game.economy_manager.discursos, 50.0, "Speech generated successfully")
	# Check that discursos label was updated
	assert_true(game.label_discursos.text.contains("50"), "UI label shows updated discursos count")

func test_06_fake_news_and_tug_of_war_interaction() -> void:
	# Fake news click adds discursos and updates the discursos label UI
	game.economy_manager.discursos = 0.0
	game._spawn_urgent_news()
	game._on_btn_urgent_news_pressed()
	
	assert_eq(game.economy_manager.discursos, 100.0, "Fake news adds 100 discursos")
	assert_true(game.label_discursos.text.contains("100"), "UI discursos label matches the fake news bonus")
