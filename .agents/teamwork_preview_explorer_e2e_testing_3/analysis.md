# E2E Test Runner and Suite Architecture Recommendation

This document outlines the architecture, layout, and test suite design for the headless End-to-End (E2E) testing framework in **Corrida Eleitoral de Brasílica**.

---

## 1. Executive Summary
We recommend a modular E2E test runner (`tests/E2ETestRunner.gd`) inheriting from `SceneTree`, designed for headless execution. The runner dynamically loads isolated test scripts, sandboxes save files, instantiates the main game scene in the root viewport, and runs **71 proposed test cases** across 4 tiers to guarantee 100% coverage of the game's core clicker, upgrades, prestige, fake news, LLM speech generation, and tug-of-war mechanics.

---

## 2. Review of the Existing Codebase and Layout
Based on our read-only investigation, the codebase is structured as follows:
- **`scenes/main/Game.tscn` / `Game.gd`**: Manages UI nodes (top bar, progress bar, buttons, lists) and game logic like enemy simulation, fake news timer, click handler, and win/loss states. It uses defensive assertions on `@onready` nodes to ensure layout integrity.
- **`scripts/managers/EconomyManager.gd`**: Handles the core math, passive discursos per second (DPS) calculation, buying upgrades, and triggering prestige. It manages save state internally by calling the save/load managers.
- **`scripts/utils/SaveManager.gd` (`AppSaveManager`)**: Saves/loads a dictionary representing game state to `user://savegame.save` in JSON format. It is a static utility class.
- **`scripts/utils/Logger.gd` (`AppLogger`)**: Provides static methods (`info`, `warning`, `error`) for structured console log outputs.
- **`tests/` directory**: Currently contains a basic `MicroTestRunner.gd` (inheriting from `Node`) and two unit tests (`TestEconomy.gd`, `TestSaveSystem.gd`).

### Key Codebase Observations for E2E Testing
1. **Static Helper Dependencies**: Since `AppSaveManager` and `AppLogger` use static methods, they do not require autoload node instantiation during headless tests, making them lightweight and easy to call.
2. **Autoload Globals**: Autoload configuration is present in `project.godot` (`Logger` and `SaveManager`), but the code calls the `class_name` bindings directly. If future autoloads are added, the headless runner must manually instantiate them in the custom `SceneTree` since autoloads are bypassed by the `-s` runner flag.
3. **Save State Side-Effects**: Running E2E tests will trigger `AppSaveManager.save_game()` which overwrites `user://savegame.save`. To protect developer saves, the runner must implement a backup and restore mechanism.
4. **Asynchronous Features**: Game events (passive income, enemy simulation, fake news timers, and the planned LLM client) are asynchronous and rely on `Timer` objects or network calls. The E2E tests must be run using `await` and frame/timer yielding to simulate user pacing.

---

## 3. Headless E2E Test Runner Architecture (`tests/E2ETestRunner.gd`)

### Why Inherit from `SceneTree`?
Running E2E tests via the `-s` console flag in Godot launches a script as a custom `MainLoop`/`SceneTree`.
- Inheriting from `SceneTree` gives the runner direct control over the execution lifecycle via `_initialize()` and `_finalize()`.
- It allows the runner to instantiate the UI scene, add it directly to the root viewport (`root`), trigger process frames, yield for timers, and terminate the engine with specific exit codes (`0` for success, `1` for failures) for CI/CD integration.

### Proposed Code: `tests/E2ETestRunner.gd`
```gdscript
# tests/E2ETestRunner.gd
extends SceneTree

const GAME_SCENE_PATH = "res://scenes/main/Game.tscn"
const SAVE_FILE_PATH = "user://savegame.save"
const BACKUP_FILE_PATH = "user://savegame.save.backup"

var passed_tests: int = 0
var failed_tests: int = 0
var test_files: Array[String] = []

# Lifecycle Entry Point
func _initialize() -> void:
	print("\n==============================================")
	print("  INICIANDO SUÍTE DE TESTES E2E (HEADLESS)    ")
	print("==============================================")
	
	_backup_user_save()
	_discover_tests()
	await _run_all_tests()
	_restore_user_save()
	
	print("\n==============================================")
	print("  RESULTADOS DOS TESTES E2E:")
	print("  Passou: %d | Falhou: %d" % [passed_tests, failed_tests])
	print("==============================================")
	
	quit(1 if failed_tests > 0 else 0)

# Discover test scripts in tests/e2e/ directory
func _discover_tests() -> void:
	var path = "res://tests/e2e/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd"):
				test_files.append(path + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	test_files.sort()
	print("Testes encontrados: %d" % test_files.size())

# Sequentially execute discovered test files
func _run_all_tests() -> void:
	for file_path in test_files:
		var script = load(file_path)
		if not script:
			print("[ERROR] Falha ao carregar arquivo de teste: %s" % file_path)
			failed_tests += 1
			continue
			
		var test_instance = script.new()
		test_instance.runner = self
		
		# Retrieve all test methods on the test instance
		var methods = test_instance.get_method_list()
		for method in methods:
			if method.name.begins_with("test_"):
				await _run_test_case(test_instance, method.name)

# Isolates and executes a single test case
func _run_test_case(test_instance: Object, method_name: String) -> void:
	var test_name = "%s::%s" % [test_instance.get_script().get_path().get_file(), method_name]
	print("\nExecutando: %s" % test_name)
	
	# 1. Start with a clean save state
	_clear_save_file()
	
	# 2. Instantiate and mount Game Scene
	var game_scene = load(GAME_SCENE_PATH)
	if not game_scene:
		print("  [FAIL] Falha ao carregar a cena do jogo.")
		failed_tests += 1
		return
		
	var game = game_scene.instantiate() as Control
	root.add_child(game)
	
	# Wait for Game._ready()
	await process_frame
	
	# 3. Run the test case
	var callable = Callable(test_instance, method_name)
	var execution = callable.call(game)
	if execution is Signal:
		await execution # Wait for async test case to complete
		
	# 4. Clean up Game Instance
	root.remove_child(game)
	game.free()
	
	# Wait for completion of free operations
	await process_frame

# --- Save File Protection Utilities ---

func _backup_user_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_FILE_PATH, BACKUP_FILE_PATH)
			dir.remove(SAVE_FILE_PATH)
			print("[INFO] Save do desenvolvedor copiado e protegido.")

func _restore_user_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if FileAccess.file_exists(BACKUP_FILE_PATH):
			dir.copy(BACKUP_FILE_PATH, SAVE_FILE_PATH)
			dir.remove(BACKUP_FILE_PATH)
			print("[INFO] Save do desenvolvedor restaurado.")
		elif FileAccess.file_exists(SAVE_FILE_PATH):
			dir.remove(SAVE_FILE_PATH)

func _clear_save_file() -> void:
	var dir = DirAccess.open("user://")
	if dir and FileAccess.file_exists(SAVE_FILE_PATH):
		dir.remove(SAVE_FILE_PATH)

# --- Assertions ---

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % msg)
	else:
		failed_tests += 1
		print("  [FAIL] %s" % msg)

func assert_eq(actual, expected, msg: String) -> void:
	if typeof(actual) == TYPE_FLOAT and typeof(expected) == TYPE_FLOAT:
		if abs(actual - expected) < 0.001:
			passed_tests += 1
			print("  [PASS] %s" % msg)
		else:
			failed_tests += 1
			print("  [FAIL] %s - Recebeu %s, Esperava %s" % [msg, str(actual), str(expected)])
	elif actual == expected:
		passed_tests += 1
		print("  [PASS] %s" % msg)
	else:
		failed_tests += 1
		print("  [FAIL] %s - Recebeu %s, Esperava %s" % [msg, str(actual), str(expected)])
```

---

## 4. Test Suite Organization and Layout

We recommend placing E2E test files in `tests/e2e/` matching the feature names.
```
tests/
├── MicroTestRunner.gd
├── TestEconomy.gd
├── TestSaveSystem.gd
├── E2ETestRunner.gd              # Headless entry point SceneTree script
└── e2e/                          # New E2E Folder
    ├── test_manual_clicker.gd    # 10 cases
    ├── test_upgrades.gd          # 10 cases
    ├── test_prestige.gd          # 10 cases
    ├── test_fake_news.gd         # 10 cases
    ├── test_llm_generation.gd    # 10 cases
    ├── test_tug_of_war.gd        # 10 cases
    ├── test_cross_features.gd    # 6 cases (Tier 3)
    └── test_game_journeys.gd     # 5 cases (Tier 4)
```

### Standard Structure of a Test Script File
```gdscript
# tests/e2e/test_manual_clicker.gd
extends RefCounted

var runner # Populated by E2ETestRunner.gd

func test_click_gain(game: Game) -> void:
	var initial_discursos = game.economy_manager.discursos
	game._on_btn_generate_pressed()
	runner.assert_eq(game.economy_manager.discursos, initial_discursos + 1.0, "Manual click should increment discursos.")
```

---

## 5. Proposed Test Cases (71 Cases Total)

The test cases are divided into 4 Tiers, targeting 6 core features:

### Tier 1: Feature Coverage (30 Cases)
Verifies happy-path execution of individual features.

| Case ID | Feature | Title | Objective | Expected Outcome |
|---|---|---|---|---|
| **TC-MC-01** | Manual Clicker | Basic Discursos Increment | Click `BtnGenerate`. | `economy_manager.discursos` increments by `1.0`. |
| **TC-MC-02** | Manual Clicker | Score Boost | Click `BtnGenerate`. | `global_score_red` increases by `0.2`. |
| **TC-MC-03** | Manual Clicker | Bar Value Shift | Click `BtnGenerate`. | `tug_of_war_bar.value` moves dynamically. |
| **TC-MC-04** | Manual Clicker | Spawn Floating Text | Click `BtnGenerate`. | A child Label appears under `FloatingTexts` with `+1.0`. |
| **TC-MC-05** | Manual Clicker | Click Juiciness Animation | Click `BtnGenerate`. | `BtnGenerate.scale` momentarily changes (tweened). |
| **TC-UP-01** | Upgrades | Verify Upgrade List UI | Count children under `UpgradesList` on startup. | Exactly 4 upgrade buttons matching Economy database are created. |
| **TC-UP-02** | Upgrades | Match Button Texts | Inspect first button text on initial setup. | Text matches formatting "Tia do Zap (Nível 0)..." |
| **TC-UP-03** | Upgrades | Button Affordability State | Set discursos balance to `5.0`. | Button 0 is disabled since cost is `10`. |
| **TC-UP-04** | Upgrades | Button Affordability Unlock | Set discursos balance to `10.0`. | Button 0 becomes enabled (`disabled = false`). |
| **TC-UP-05** | Upgrades | Process Upgrade Purchase | Click Button 0 when affordable. | Discursos balance decreases by `10.0`, level increments to 1. |
| **TC-PR-01** | Prestige | Prestige Multiplier Progression | Call `economy_manager.reset_for_prestige()`. | `prestige_multiplier` increments by `0.5`. |
| **TC-PR-02** | Prestige | Prestige Discursos Reset | Set discursos to `5000.0` then trigger prestige. | Discursos count resets to `0.0`. |
| **TC-PR-03** | Prestige | Prestige Upgrade Reset | Buy several upgrades, then trigger prestige. | All upgrade levels in `economy_manager.upgrades` reset to `0`. |
| **TC-PR-04** | Prestige | Prestige Signal Emission | Hook signals, trigger prestige. | `prestige_changed` is emitted with the new multiplier. |
| **TC-PR-05** | Prestige | Prestige State Persistence | Trigger prestige, reload game economy. | Loaded data retains the new prestige multiplier. |
| **TC-FN-01** | Fake News | Spawn Timer Initialization | Check `news_timer` status on game ready. | Timer is active, `one_shot` is true, duration between 20s and 40s. |
| **TC-FN-02** | Fake News | Position Containment | Call `_spawn_urgent_news()`. | `BtnUrgentNews` global coordinates are inside visible viewport bounds. |
| **TC-FN-03** | Fake News | Despawn Timer Alpha Fade | Wait after spawning news without clicking. | `BtnUrgentNews` modulate alpha fades to `0.0` over 3.0s. |
| **TC-FN-04** | Fake News | Click News Bonus | Set passive DPS to `100.0`, spawn and click urgent news. | Added discursos equals `100.0 * 30.0 = 3000.0`. |
| **TC-FN-05** | Fake News | Post-Click Cycle Restart | Click active urgent news. | Button hides and `news_timer` resets and starts. |
| **TC-LL-01** | LLM Speech | Non-Blocking Generation | Trigger async speech generation. | Game loop does not lock up; other UI elements remain responsive. |
| **TC-LL-02** | LLM Speech | Success Signal Hook | Mock success on LLM Client. | `speech_generated(text)` signal triggers. |
| **TC-LL-03** | LLM Speech | Failure Signal Hook | Mock connection failure on LLM Client. | `generation_failed(msg)` signal triggers. |
| **TC-LL-04** | LLM Speech | UI Text Update | Emit `speech_generated` with custom string. | UI text box renders the generated speech string. |
| **TC-LL-05** | LLM Speech | Loading Feedback State | Trigger LLM generation. | Main generation button is disabled/shows "Pensando..." state. |
| **TC-TW-01** | Tug of War | Calculation Integrity | Set red score to `60` and blue to `40`. | Tug-of-war progress value reads exactly `60.0`. |
| **TC-TW-02** | Tug of War | Victory State Transition | Force `global_score_red = 100.0` and blue to `0.0`. | `_end_game(true)` is called; victory panel shows. |
| **TC-TW-03** | Tug of War | Defeat State Transition | Force `global_score_red = 0.0` and blue to `100.0`. | `_end_game(false)` is called; defeat panel shows. |
| **TC-TW-04** | Tug of War | Passive Enemy Growth | Let 1.0s pass with DPS = 0. | `global_score_blue` increments by `0.5` via simulation tick. |
| **TC-TW-05** | Tug of War | Restart Button Behavior | Click Restart on EndGamePanel. | Game state becomes active; scores reset to `50/50`. |

---

### Tier 2: Boundary & Corner Cases (30 Cases)
Tests edge conditions, math limits, and unexpected behaviors.

| Case ID | Feature | Title | Objective | Expected Outcome |
|---|---|---|---|---|
| **TC-MC-06** | Manual Clicker | Input Blocking post Game Over | Set `game_active = false`, click `BtnGenerate`. | Discursos are not added, scores do not change. |
| **TC-MC-07** | Manual Clicker | High-Frequency Input Stability | Click `BtnGenerate` 100 times in 1 frame. | No engine crashes, value is mathematically correct. |
| **TC-MC-08** | Manual Clicker | Extreme Multiplier Precision | Set prestige multiplier to `1000.5`, click. | Value added is exactly `1000.5` without float truncation errors. |
| **TC-MC-09** | Manual Clicker | Sub-zero Multiplier Guard | Inject negative prestige multiplier. | Multiplier defaults to `1.0` or logs warning; balance does not drop. |
| **TC-MC-10** | Manual Clicker | Floating Text Overflow Guard | Spawn 200 click texts rapidly. | Memory is cleared; old text objects are freed. |
| **TC-UP-06** | Upgrades | Purchase at Exact Limit | Set discursos to cost of upgrade, click buy. | Upgrade bought; balance drops to exactly `0.0`. |
| **TC-UP-07** | Upgrades | Level 100+ Cost Overflow | Upgrade index 3 up to Level 100. | Costs calculate correctly using floats, avoiding variable integer overflow. |
| **TC-UP-08** | Upgrades | OOB Index Purchase Protection | Call `buy_upgrade(-1)` and `buy_upgrade(99)`. | Returns `false` safely; error logged, no crash. |
| **TC-UP-09** | Upgrades | Compound DPS Math Accuracy | Buy upgrades 0, 1, 2, 3 sequentially. | Combined DPS matches individual sum exactly. |
| **TC-UP-10** | Upgrades | State Reload Button Match | Save game with un-affordable upgrades, reload. | Buttons are immediately disabled upon reload. |
| **TC-PR-06** | Prestige | Prestige at Zero Discursos | Trigger prestige with `discursos = 0.0`. | Prestige proceeds; multiplier increases. |
| **TC-PR-07** | Prestige | Massive Prestige Multiplier Cap | Prestige 200 times. | Multiplier calculates to `101.0x` without UI truncation. |
| **TC-PR-08** | Prestige | Active Tween Safety | Trigger prestige while button click Tweens run. | SceneTree cleans up tweens safely; no runtime exceptions. |
| **TC-PR-09** | Prestige | Prestige Save Error Recovery | Corrupt disk write during prestige. | Returns error, game does not crash. |
| **TC-PR-10** | Prestige | Prestige with No Upgrades Purchased | Trigger prestige with 0 upgrades level. | Reset works, count stays 0, multiplier increases. |
| **TC-FN-06** | Fake News | Block Spawn post Game Over | Set `game_active = false` and force news timer timeout. | Urgent news button remains hidden. |
| **TC-FN-07** | Fake News | Extreme Viewport Scale Guard | Resize screen to 10x10. | Urgent news button clamps within valid visible pixels. |
| **TC-FN-08** | Fake News | Timer Stack Mitigation | Let fake news timeout, trigger consecutive timer. | Only one Timer runs; no double spawns. |
| **TC-FN-09** | Fake News | Late-Frame Intercept | Press urgent news button during the last frame of fade. | Click is successfully intercepted, bonus given. |
| **TC-FN-10** | Fake News | Zero DPS Baseline | Set DPS to 0.0, click urgent news. | Earns exactly the minimum fallback bonus of `100.0`. |
| **TC-LL-06** | LLM Speech | Ollama Timeout Switch | Simulate Ollama API freeze > 5s. | Client cancels request, falls back to offline template. |
| **TC-LL-07** | LLM Speech | Ollama Server 500 Error | Simulate server error HTTP code 500. | Emits `generation_failed` and falls back gracefully. |
| **TC-LL-08** | LLM Speech | Ollama Malformed JSON Response | Mock corrupted JSON response string. | Parsing failure is captured; falls back without crash. |
| **TC-LL-09** | LLM Speech | Double Generation Throttling | Request generation while one is actively running. | Request is ignored or queued; thread remains safe. |
| **TC-LL-10** | LLM Speech | Empty Subject Exception Guard | Send empty topic/prompt. | Client processes request with default fallback template. |
| **TC-TW-06** | Tug of War | Division by Zero Protection | Force scores red = 0.0 and blue = 0.0. | Progress bar handles state safely (renders 50%). |
| **TC-TW-07** | Tug of War | Synchronous Frame Collision | Trigger Red win click and Blue decay tick same frame. | Tug of War resolves winning state cleanly. |
| **TC-TW-08** | Tug of War | Out of Bounds Score Clamp | Force `global_score_red = 1e8`. | Tug of War progress bar clamps value to 100%. |
| **TC-TW-09** | Tug of War | Game Over Panel Interaction Block | Attempt to focus Restart when game is active. | Panel button is hidden and unreachable. |
| **TC-TW-10** | Tug of War | Zero Score Decay Stop | Set `game_active = false`. | Simulation timer ticks no longer modify blue score. |

---

### Tier 3: Cross-Feature Combinations (6 Cases)
Tests interactions between two or more features.

- **TC-CR-01: Save/Load State Integrity across Prestige**
  - *Objective*: Buy upgrades, prestige once (multiplier = 1.5), buy more upgrades, save game, and restart/reload.
  - *Expected Outcome*: Loaded state correctly retains the 1.5x prestige multiplier, the post-prestige upgrades, and computes the correct passive DPS.
- **TC-CR-02: Fake News Bonus Scaling with Prestige**
  - *Objective*: Attain passive DPS = 100. Prestige once (multiplier = 1.5, actual passive DPS = 150). Spawn fake news button and click it.
  - *Expected Outcome*: Fake news baseline calculation is `150 * 30 = 4500`. Added to discursos as `4500 * 1.5 = 6750` inside `add_discursos()`, proving correct compounding of features.
- **TC-CR-03: Manual Clicker during Async LLM Speech Generation**
  - *Objective*: Trigger speech generation (async). While "Pensando..." state is active, click `BtnGenerate` rapidly 20 times.
  - *Expected Outcome*: Manual clicks are registered successfully without delaying or freezing the async speech generation response.
- **TC-CR-04: Prestige Reset during Active Fake News Spawn**
  - *Objective*: Wait for fake news button to spawn on UI. Immediately trigger prestige reset.
  - *Expected Outcome*: The active fake news button is cleaned up/hidden instantly, preventing the player from clicking it post-prestige to gain a massive headstart.
- **TC-CR-05: Passive DPS Victory vs Enemy Score Simulation**
  - *Objective*: Purchase high-tier upgrades (e.g. Vazamento de Dossiê) to gain high passive DPS. Let the game run without clicking.
  - *Expected Outcome*: Passive red score increase (`dps * delta * 0.05`) exceeds the passive enemy power increase (`0.5 + dps * 0.04`), pushing tug-of-war to 100% and winning the game.
- **TC-CR-06: LLM Speech Failure Fallback UI Integration**
  - *Objective*: Trigger speech generation. Mock an Ollama failure to force fallback.
  - *Expected Outcome*: UI transitions out of the "thinking" state, displays the offline procedurally generated speech, and awards the baseline victory points to red score.

---

### Tier 4: Real-World Application Scenarios (5 Cases)
End-to-end player journeys modeling complete play sessions.

- **TC-JW-01: The "Aggressive Speedrunner" Journey**
  - *Objective*: Play session modeling rapid clicker play. Simulates a player clicking 5 times per second, buying upgrades optimally, clicking fake news immediately, and achieving victory (red_percent >= 99.9) in under 60 simulated seconds.
  - *Expected Outcome*: Victory is reached, `EndGamePanel` is displayed with victory message, and game loop stops safely.
- **TC-JW-02: The "Idle Defeat" Journey**
  - *Objective*: Play session modeling an inactive player. Instantiates the game and waits, performing zero interactions.
  - *Expected Outcome*: The enemy faction's passive decay ticks push the blue score to victory, triggering `_end_game(false)` and displaying the defeat panel.
- **TC-JW-03: The "Prestige Loop" Progression Journey**
  - *Objective*: Play session modeling progression. Clicks and buys 10 Zap upgrades, prestiges, and runs another short clicker loop to reach 10 upgrades again.
  - *Expected Outcome*: The second loop runs faster (verified by lower total frame count to reach 10 upgrades) due to the 1.5x prestige multiplier.
- **TC-JW-04: The "Save & Restore Session Recovery" Journey**
  - *Objective*: Simulates game interruption. Player clicks, buys upgrades, lets discursos accrue, triggers an autosave, destroys the game instance, instantiates a new game instance, and waits.
  - *Expected Outcome*: Game resumes from the exact state, and passive income generates correct balances based on elapsed delta.
- **TC-JW-05: The "Adversarial LLM Network Fluctuation" Journey**
  - *Objective*: Simulates playing during bad network. Player repeatedly requests speech generation. The LLM Client experiences a success, a timeout, and a server error sequentially.
  - *Expected Outcome*: The game handles the API fluctuations transparently: successful generation shows API text; timeout/error show fallbacks. No UI locks or crashes occur.

---

## 6. Mocking Strategy for the Planned LLM Client

To test the planned `LocalLLMClient` features in E2E tests before Ollama is integrated (and during headless tests in CI/CD without access to Ollama), we propose a **Mocking Client** strategy.

### Proposed Mock Interface
Create a mock subclass or override script (`tests/mocks/MockLLMClient.gd`) that extends `LocalLLMClient` or mimics its interface, allowing E2E tests to trigger simulated responses on demand.

```gdscript
# tests/mocks/MockLLMClient.gd
extends Node
# Mimics res://scripts/managers/LocalLLMClient.gd

signal speech_generated(text: String)
signal generation_failed(error_msg: String)

var mock_mode: String = "success" # "success", "fail", "timeout"
var mock_delay: float = 0.1

func generate_speech_async(topic: String, prompt: String) -> void:
	# Simulate network/thread delay
	await get_tree().create_timer(mock_delay).timeout
	
	match mock_mode:
		"success":
			var mock_speech = "Satirical speech about %s: Fake news is the new truth!" % topic
			speech_generated.emit(mock_speech)
		"fail":
			generation_failed.emit("HTTP Error 500: Internal Server Error")
		"timeout":
			# Delay exceeds 5.0 seconds timeout limit
			await get_tree().create_timer(6.0).timeout
			generation_failed.emit("Connection timed out after 5 seconds")
```

### Swapping the Client in E2E Tests
In E2E test cases, tests can locate the active `LocalLLMClient` node on the `Game` scene and replace it with the mock node:
```gdscript
func test_llm_success(game: Game) -> void:
	# 1. Instantiate Mock Client
	var mock_client = load("res://tests/mocks/MockLLMClient.gd").new()
	mock_client.mock_mode = "success"
	mock_client.mock_delay = 0.2
	
	# 2. Swap real node with mock
	var real_client = game.get_node("LocalLLMClient")
	game.remove_child(real_client)
	real_client.queue_free()
	
	mock_client.name = "LocalLLMClient"
	game.add_child(mock_client)
	
	# 3. Simulate UI trigger
	game.btn_generate_speech.pressed.emit()
	
	# Verify thinking UI is shown
	runner.assert_true(game.btn_generate_speech.disabled, "Speech button should be disabled during generation.")
	
	# 4. Wait for generation to complete
	await mock_client.speech_generated
	
	# Verify output
	runner.assert_eq(game.label_speech_box.text, "Satirical speech about... [etc]", "UI should render mock speech.")
```

---

## 7. Execution and Handoff Instructions

### How to Run the E2E Test Suite Headless
Run the following command from the project root:
```powershell
C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd
```

### Verification Method
1. The test runner will backup `user://savegame.save` if it exists.
2. For each discovered file under `tests/e2e/test_*.gd`, it instantiates the game, executes the assertions, and tears down the instance.
3. Once completed, it restores the developer's backup save file.
4. Output will be logged directly to the command line console, exiting with code `0` if all tests pass or `1` if any fail.
