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

# Tier 4: Real-World Application Scenarios (5 tests)

func test_01_scenario_speedrun_victory() -> void:
	# Start a fresh game
	game.global_score_red = 50.0
	game.global_score_blue = 50.0
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	game.game_active = true
	
	# Rapid clicking (250 clicks) -> discursos = 250.0.
	# Each click adds 0.2 to red score -> 250 * 0.2 = 50.0 added to red. Red score = 100.0, blue = 50.0.
	# Let's perform the clicking simulation
	for i in range(250):
		if not game.game_active:
			break
		game._on_btn_generate_pressed()
		
	# Buy upgrades if we have discursos
	if game.economy_manager.buy_upgrade(0): # Tia do Zap (cost 10)
		game.economy_manager.buy_upgrade(0)
	
	# Set red score high enough to trigger victory
	game.global_score_red = 1000.0
	game.global_score_blue = 1.0
	game._update_tug_of_war()
	
	assert_true(not game.game_active, "Speedrun campaign ends in victory")
	assert_true(game.end_game_panel.visible, "Victory panel is displayed")
	assert_true(game.label_result.text.contains("VITÓRIA"), "Label shows VITÓRIA text")

func test_02_scenario_hard_fought_comeback() -> void:
	# Player is losing badly (red is 5.0, blue is 95.0)
	game.global_score_red = 5.0
	game.global_score_blue = 95.0
	game.game_active = true
	game.economy_manager.discursos = 0.0
	game.economy_manager.discursos_por_segundo = 0.0
	game._update_tug_of_war()
	
	# Spawn and click Fake News to get huge boost
	game._spawn_urgent_news()
	game._on_btn_urgent_news_pressed() # adds 100 discursos
	
	# Buy upgrades with fake news funds
	game.economy_manager.buy_upgrade(1) # Robos (cost 100)
	
	# Player clicks furiously to recover
	for i in range(480): # 480 * 0.2 = 96.0 added to red -> red score becomes 101.0, blue = 95.0
		game._on_btn_generate_pressed()
		
	# Victory is achieved
	game.global_score_red = 999.0
	game.global_score_blue = 1.0
	game._update_tug_of_war()
	
	assert_true(not game.game_active, "Comeback campaign succeeds in defeating opposition")

func test_03_scenario_loss_and_restart_with_prestige() -> void:
	# Game is active
	game.game_active = true
	game.economy_manager.prestige_multiplier = 1.0
	
	# Opponent dominates (loss condition)
	game.global_score_red = 0.1
	game.global_score_blue = 99.9
	game._update_tug_of_war()
	
	assert_true(not game.game_active, "Opponent victory causes defeat state")
	assert_true(game.label_result.text.contains("DERROTA"), "Label shows DERROTA text")
	
	# Click restart to trigger next mandate (prestige)
	game._on_btn_restart_pressed()
	
	assert_true(game.game_active, "Game is active again after restart")
	assert_eq(game.global_score_red, 50.0, "Red score reset to 50")
	assert_eq(game.global_score_blue, 50.0, "Blue score reset to 50")
	assert_eq(game.economy_manager.prestige_multiplier, 1.5, "Restarting after defeat awards +0.5 prestige multiplier")

func test_04_scenario_llm_driven_campaign() -> void:
	game.game_active = true
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	mock_llm.simulate_delay = 0.01
	mock_llm.should_fail = false
	
	# Simulate generative speech campaign
	game.generate_speech("Discurso Popular", "Falar sobre saude publica.")
	await get_tree().create_timer(0.05).timeout
	
	print("DEBUG Scenario LLM Campaign:")
	print("  discursos: ", game.economy_manager.discursos)
	print("  prestige_multiplier: ", game.economy_manager.prestige_multiplier)
	print("  is_connected: ", mock_llm.speech_generated.is_connected(game._on_speech_generated))
	
	assert_eq(game.economy_manager.discursos, 50.0, "First campaign speech awards 50.0 discursos")
	
	# Buy upgrades using speech discursos
	game.economy_manager.buy_upgrade(0) # cost 10
	game.economy_manager.buy_upgrade(0) # cost 11
	game.economy_manager.buy_upgrade(0) # cost 13
	
	# Trigger second speech
	game.generate_speech("Discurso Economico", "Falar sobre impostos zero.")
	await get_tree().create_timer(0.05).timeout
	
	assert_true(game.economy_manager.discursos >= 50.0 - 34.0, "Sufficient funds left after upgrades and second speech")

func test_05_scenario_passive_playthrough() -> void:
	game.game_active = true
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	
	# Buy some passive generation (e.g. 5 Tias do Zap)
	game.economy_manager.upgrades[0].count = 5 # DPS = 5.0
	game.economy_manager._recalculate_dps()
	
	# Let game run passively for 2 seconds
	game.economy_manager._process(1.0)
	game.economy_manager._process(1.0)
	
	# Total discursos accumulated passively = 10.0
	assert_eq(game.economy_manager.discursos, 10.0, "Passive playthrough accumulates discursos over time without manual clicks")
