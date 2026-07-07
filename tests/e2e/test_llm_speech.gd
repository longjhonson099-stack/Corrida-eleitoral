extends "res://tests/e2e/BaseE2ETest.gd"

const MockLLMClass = preload("res://tests/mocks/MockLLMClient.gd")
var mock_llm: Node

func _enter_tree() -> void:
	# Add mock LLM client to the game
	mock_llm = MockLLMClass.new()
	mock_llm.name = "LocalLLMClient"
	game.add_child(mock_llm)
	game.llm_client = mock_llm
	game._connect_llm_client()

func _exit_tree() -> void:
	if is_instance_valid(mock_llm):
		mock_llm.queue_free()

# Tier 1: Feature Coverage (5 tests)

func test_01_llm_client_dynamic_swap() -> void:
	assert_true(game.llm_client == mock_llm, "Game.gd references the swapped mock LLM client")
	assert_true(mock_llm.speech_generated.is_connected(game._on_speech_generated), "speech_generated is connected")
	assert_true(mock_llm.generation_failed.is_connected(game._on_speech_generation_failed), "generation_failed is connected")

func test_02_llm_speech_generates_successfully() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	mock_llm.should_fail = false
	mock_llm.simulate_delay = 0.05
	
	game.generate_speech("Politica", "Falar sobre impostos.")
	
	# Verify thinking state is active initially
	assert_true(game.is_llm_thinking, "Game is in thinking state immediately after request")
	
	# Wait for simulated network delay (delay is 0.05, we wait 0.1)
	await get_tree().create_timer(0.1).timeout
	
	assert_true(not game.is_llm_thinking, "Game is no longer in thinking state after completion")
	assert_eq(game.last_generated_speech, "Mock Speech about Politica: Falar sobre impostos.", "Speech text is saved correctly")
	assert_eq(game.economy_manager.discursos, 50.0, "Successful speech generation awards 50.0 discursos")

func test_03_llm_speech_fails_gracefully() -> void:
	mock_llm.should_fail = true
	mock_llm.simulate_delay = 0.05
	game.last_generated_speech = ""
	game.llm_error_message = ""
	
	game.generate_speech("Economia", "Falar sobre inflacao.")
	
	await get_tree().create_timer(0.1).timeout
	
	assert_true(not game.is_llm_thinking, "Game thinking state is cleared after failure")
	assert_eq(game.last_generated_speech, "", "No speech text is generated on failure")
	assert_eq(game.llm_error_message, "Mock LLM failed to connect or timed out.", "Error message is recorded")

func test_04_llm_thinking_state_during_generation() -> void:
	mock_llm.simulate_delay = 0.2
	game.generate_speech("Saude", "Falar sobre hospitais.")
	
	# check halfway
	await get_tree().create_timer(0.1).timeout
	assert_true(game.is_llm_thinking, "Thinking state is true during ongoing generation")
	
	# Wait for completion
	await get_tree().create_timer(0.15).timeout
	assert_true(not game.is_llm_thinking, "Thinking state is false after generation finishes")

func test_05_llm_rewards_discursos() -> void:
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 3.0
	mock_llm.should_fail = false
	mock_llm.simulate_delay = 0.01
	
	game.generate_speech("Educacao", "Falar sobre escolas.")
	await get_tree().create_timer(0.05).timeout
	
	# 50.0 base * 3.0 prestige = 150.0 discursos
	assert_eq(game.economy_manager.discursos, 150.0, "Discursos reward scales with prestige multiplier (50 * 3.0 = 150)")

# Tier 2: Boundary & Corner Cases (5 tests)

func test_06_llm_speech_when_game_inactive() -> void:
	game.game_active = false
	game.is_llm_thinking = false
	mock_llm.simulate_delay = 0.01
	
	game.generate_speech("Topic", "Prompt")
	assert_true(not game.is_llm_thinking, "No speech request is processed if game is inactive")
	game.game_active = true

func test_07_llm_speech_multiple_overlapping_requests() -> void:
	# Start first request
	mock_llm.simulate_delay = 0.1
	game.economy_manager.discursos = 0.0
	game.economy_manager.prestige_multiplier = 1.0
	mock_llm.should_fail = false
	
	game.generate_speech("First", "Prompt 1")
	# Start second request immediately
	game.generate_speech("Second", "Prompt 2")
	
	await get_tree().create_timer(0.15).timeout
	
	# The mock client's second request overrides or finishes. Let's make sure it completed.
	assert_true(not game.is_llm_thinking, "Overlapping requests resolve and clear thinking state")
	assert_eq(game.last_generated_speech, "Mock Speech about Second: Prompt 2", "Second request response is kept")
	# Depending on implementation, overlapping requests might award twice or once. Since they are async,
	# they will both complete. Let's verify that the game didn't crash.
	assert_true(game.economy_manager.discursos >= 50.0, "Overlapping requests didn't crash and discursos were added")

func test_08_llm_speech_empty_prompt() -> void:
	mock_llm.should_fail = false
	mock_llm.simulate_delay = 0.01
	game.generate_speech("", "")
	await get_tree().create_timer(0.05).timeout
	assert_eq(game.last_generated_speech, "Mock Speech about : ", "Generates successfully even with empty topic/prompt")

func test_09_llm_speech_timeout_simulation() -> void:
	# Simulate a client that delays for a long time (e.g. 0.5s)
	mock_llm.simulate_delay = 0.5
	game.generate_speech("Demorado", "Esperando...")
	
	await get_tree().create_timer(0.2).timeout
	assert_true(game.is_llm_thinking, "Still thinking at 0.2s")
	
	await get_tree().create_timer(0.35).timeout
	assert_true(not game.is_llm_thinking, "Finishes thinking at 0.55s total")

func test_10_llm_speech_null_client() -> void:
	game.llm_client = null
	game.is_llm_thinking = false
	game.generate_speech("Topic", "Prompt")
	assert_true(not game.is_llm_thinking, "Calling generate_speech with null client keeps thinking state false and does not crash")
	# Restore mock client
	game.llm_client = mock_llm
